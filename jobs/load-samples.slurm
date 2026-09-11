#!/usr/bin/env bash

#SBATCH --job-name 1k1rg-load-samples
#SBATCH --output logs/1k1rg-load-samples-%j.out
#SBATCH --error logs/1k1rg-load-samples-%j.error
#SBATCH --cpus-per-task 2
#SBATCH --mem 2G
#SBATCH --partition batch
#SBATCH --qos batch_default
#SBATCH --mail-type ALL

set -euo pipefail

readonly DB_CONFIG_FILE=./config/database.env
readonly SAMPLE_CONFIG_FILE=${1:-./config/load-samples.env}

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

die() {
  log "Error: $1" >&2
  exit 1
}

load_config() {
  local config_file=$1

  if [[ ! -f "$config_file" ]]; then
    die "Configuration file $config_file not found"
  fi

  if ! source "$config_file"; then
    die "Configuration file $config_file failed to load"
  fi
}

validate_arguments() {
  if (($# > 1)); then
    die "Usage: $0 [sample-config]"
  fi
}

validate_config() {
  local variable
  for variable in \
    POSTGRES_HOST \
    POSTGRES_PORT \
    POSTGRES_DB_NAME \
    POSTGRES_USER \
    POSTGRES_PASSWORD; do
    if [[ -z ${!variable:-} ]]; then
      die "$variable is not set in $DB_CONFIG_FILE"
    fi
  done

  for variable in \
    VARIETY_SET_NAME \
    SNP_SET_NAME \
    SAMPLE_FILE \
    POSITION_FILE \
    REF_NAME \
    HDF5_FILE; do
    if [[ -z ${!variable:-} ]]; then
      die "$variable is not set in $SAMPLE_CONFIG_FILE"
    fi
  done

  if [[ ! -f "$SAMPLE_FILE" ]]; then
    die "SAMPLE_FILE $SAMPLE_FILE not found"
  fi

  if [[ ! -f "$POSITION_FILE" ]]; then
    die "POSITION_FILE $POSITION_FILE not found"
  fi
}

load_samples() {
  log "Starting sample dataset load"

  # SNP Seek appends "_trans" when it locates the transposed HDF5 file.
  local data_location=$HDF5_FILE
  if [[ $data_location =~ ^(.*)_transp?(\.[^.]*)?$ ]]; then
    data_location="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
  fi

  if ! DB_HOST="$POSTGRES_HOST" \
    DB_PORT="$POSTGRES_PORT" \
    DB_NAME="$POSTGRES_DB_NAME" \
    DB_USER="$POSTGRES_USER" \
    DB_PASSWORD="$POSTGRES_PASSWORD" \
    bash src/uploadDataset.sh \
    "$VARIETY_SET_NAME" \
    "$SNP_SET_NAME" \
    "$SAMPLE_FILE" \
    "$POSITION_FILE" \
    "$REF_NAME" \
    "$data_location"; then
    die "Failed to load sample dataset"
  fi

  log "Completed sample dataset load"
}

validate_arguments "$@"
load_config "$DB_CONFIG_FILE"
load_config "$SAMPLE_CONFIG_FILE"
validate_config
load_samples
