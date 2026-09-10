#!/usr/bin/env bash

#SBATCH --job-name 1k1rg-load-db
#SBATCH --output logs/1k1rg-load-db-%j.out
#SBATCH --error logs/1k1rg-load-db-%j.error
#SBATCH --cpus-per-task 2
#SBATCH --mem 2G
#SBATCH --partition batch
#SBATCH --qos batch_default
#SBATCH --mail-type ALL

set -euo pipefail

readonly CONFIG_FILE=./config/load-db.env

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

die() {
  log "Error: $1" >&2
  exit 1
}

load_config() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    die "Configuration file $CONFIG_FILE not found"
  fi

  if ! source "$CONFIG_FILE"; then
    die "Configuration file $CONFIG_FILE failed to load"
  fi
}

validate_config() {
  local variable
  for variable in \
    POSTGRES_HOST \
    POSTGRES_PORT \
    POSTGRES_DB_NAME \
    POSTGRES_USER \
    POSTGRES_PASSWORD \
    REF_NAME \
    VARIETY_SET \
    SNP_SET \
    HDF5_FILE; do
    if [[ -z ${!variable:-} ]]; then
      die "$variable is not set in $CONFIG_FILE"
    fi
  done
}

create_db() {
  log "Starting database init"

  sudo -u postgres psql <<SQL
    DROP DATABASE IF EXISTS $POSTGRES_DB_NAME;
    DROP USER IF EXISTS $POSTGRES_USER;
    CREATE DATABASE $POSTGRES_DB_NAME;
    CREATE USER $POSTGRES_USER WITH PASSWORD '$POSTGRES_PASSWORD';
    GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB_NAME TO $POSTGRES_USER;
    \c $POSTGRES_DB_NAME
    GRANT ALL ON SCHEMA public TO $POSTGRES_USER;
SQL

  log "Completed database init"
}

load_chado_dump() {
  log "Starting Chado init"

  if ! command -v psql &>/dev/null; then
    die "psql was not found in the active environment"
  fi

  if ! PGPASSWORD="$POSTGRES_PASSWORD" psql \
    -h "$POSTGRES_HOST" \
    -p "$POSTGRES_PORT" \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB_NAME" \
    --no-password \
    --no-psqlrc \
    --set ON_ERROR_STOP=1 \
    --single-transaction \
    -f "src/chado_dump.sql" \
    >/dev/null; then
    die "Failed to restore Chado database dump"
  fi

  log "Completed Chado init"
}

load_ref() {
  if [[ -z ${REF_GFF:-} ]]; then
    log "Skipping reference genome load: REF_GFF is not set"
    return
  fi

  log "Starting reference genome load"

  if ! PGHOST="$POSTGRES_HOST" \
    PGPORT="$POSTGRES_PORT" \
    PGDATABASE="$POSTGRES_DB_NAME" \
    PGUSER="$POSTGRES_USER" \
    PGPASSWORD="$POSTGRES_PASSWORD" \
    bash src/loadReferenceGenome.sh \
    -i "$REF_GFF" \
    -o "$REF_NAME" \
    -n "$REF_NAME"; then
    die "Failed to load reference genome"
  fi

  log "Completed reference genome load"
}

load_samples() {
  log "Starting sample dataset load"

  # SNP Seek appends "_trans" to data_location when it looks for the transposed
  # HDF5 file, so data_location must not carry that suffix.
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
    "$VARIETY_SET" \
    "$SNP_SET" \
    output/matrix/sample_list.txt \
    output/matrix/pos.txt \
    "$REF_NAME" \
    "$data_location"; then
    die "Failed to load sample dataset"
  fi

  log "Completed sample dataset load"
}

load_config
validate_config
create_db
load_chado_dump
load_ref
load_samples
