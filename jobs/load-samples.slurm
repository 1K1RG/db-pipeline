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

source ./utils.sh

readonly DB_CONFIG_FILE=./config/database.env
readonly SAMPLE_CONFIG_FILE=${1:-./config/load-samples.env}

validate_arguments() {
  if (($# > 1)); then
    die "Usage: $0 [sample-config]"
  fi
}

validate_config() {
  require_config_vars "$DB_CONFIG_FILE" \
    POSTGRES_HOST \
    POSTGRES_PORT \
    POSTGRES_DB_NAME \
    POSTGRES_USER \
    POSTGRES_PASSWORD

  require_config_vars "$SAMPLE_CONFIG_FILE" \
    VARIETY_SET_NAME \
    SNP_SET_NAME \
    REF_NAME \
    HDF5_FILE
}

load_samples() {
  log "Starting sample dataset load"

  # SNP Seek appends "_trans" when it locates the transposed HDF5 file.
  local data_location=$HDF5_FILE
  if [[ $data_location =~ ^(.*)_transp?(\.[^.]*)?$ ]]; then
    data_location="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
  fi

  local matrix_dir=output/matrix/${data_location%.*}
  local samples_file=$matrix_dir/sample_list.txt
  local positions_file=$matrix_dir/pos.txt

  if [[ ! -f "$samples_file" ]]; then
    die "$samples_file not found"
  fi

  if [[ ! -f "$positions_file" ]]; then
    die "$positions_file not found"
  fi

  if ! OUTPUT_DIR=output \
    DB_HOST="$POSTGRES_HOST" \
    DB_PORT="$POSTGRES_PORT" \
    DB_NAME="$POSTGRES_DB_NAME" \
    DB_USER="$POSTGRES_USER" \
    DB_PASSWORD="$POSTGRES_PASSWORD" \
    bash src/uploadDataset.sh \
    "$VARIETY_SET_NAME" \
    "$SNP_SET_NAME" \
    "$samples_file" \
    "$positions_file" \
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
