#!/usr/bin/env bash

#SBATCH --job-name 1k1rg-load-reference
#SBATCH --output logs/1k1rg-load-reference-%j.out
#SBATCH --error logs/1k1rg-load-reference-%j.error
#SBATCH --cpus-per-task 2
#SBATCH --mem 2G
#SBATCH --partition batch
#SBATCH --qos batch_default
#SBATCH --mail-type ALL

set -euo pipefail

readonly DB_CONFIG_FILE=./config/database.env
readonly REF_CONFIG_FILE=${1:-./config/load-reference.env}

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
    die "Usage: $0 [reference-config]"
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

  for variable in REF_GFF REF_OUTPUT_PREFIX REF_NAME; do
    if [[ -z ${!variable:-} ]]; then
      die "$variable is not set in $REF_CONFIG_FILE"
    fi
  done

  if [[ ! -f "$REF_GFF" ]]; then
    die "REF_GFF $REF_GFF not found"
  fi
}

load_reference() {
  log "Starting reference genome load"

  if ! PGHOST="$POSTGRES_HOST" \
    PGPORT="$POSTGRES_PORT" \
    PGDATABASE="$POSTGRES_DB_NAME" \
    PGUSER="$POSTGRES_USER" \
    PGPASSWORD="$POSTGRES_PASSWORD" \
    bash src/loadReferenceGenome.sh \
    -i "$REF_GFF" \
    -o "$REF_OUTPUT_PREFIX" \
    -n "$REF_NAME"; then
    die "Failed to load reference genome"
  fi

  log "Completed reference genome load"
}

validate_arguments "$@"
load_config "$DB_CONFIG_FILE"
load_config "$REF_CONFIG_FILE"
validate_config
load_reference
