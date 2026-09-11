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

source ./utils.sh

readonly DB_CONFIG_FILE=./config/database.env
readonly REF_CONFIG_FILE=${1:-./config/load-reference.env}

validate_arguments() {
  if (($# > 1)); then
    die "Usage: $0 [reference-config]"
  fi
}

validate_config() {
  require_config_vars "$DB_CONFIG_FILE" \
    POSTGRES_HOST \
    POSTGRES_PORT \
    POSTGRES_DB_NAME \
    POSTGRES_USER \
    POSTGRES_PASSWORD

  require_config_vars \
    "$REF_CONFIG_FILE" \
    REF_GFF \
    REF_OUTPUT_PREFIX \
    REF_NAME

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
