#!/usr/bin/env bash

#SBATCH --job-name 1k1rg-init-database
#SBATCH --output logs/1k1rg-init-database-%j.out
#SBATCH --error logs/1k1rg-init-database-%j.error
#SBATCH --cpus-per-task 2
#SBATCH --mem 2G
#SBATCH --partition batch
#SBATCH --qos batch_default
#SBATCH --mail-type ALL

set -euo pipefail

readonly CONFIG_FILE=./config/database.env

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
    POSTGRES_PASSWORD; do
    if [[ -z ${!variable:-} ]]; then
      die "$variable is not set in $CONFIG_FILE"
    fi
  done
}

create_database() {
  log "Starting database initialization"

  sudo -u postgres psql <<SQL
    DROP DATABASE IF EXISTS $POSTGRES_DB_NAME;
    DROP USER IF EXISTS $POSTGRES_USER;
    CREATE DATABASE $POSTGRES_DB_NAME;
    CREATE USER $POSTGRES_USER WITH PASSWORD '$POSTGRES_PASSWORD';
    GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB_NAME TO $POSTGRES_USER;
    \c $POSTGRES_DB_NAME
    GRANT ALL ON SCHEMA public TO $POSTGRES_USER;
SQL

  log "Completed database initialization"
}

load_chado_dump() {
  log "Starting Chado dump load"

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

  log "Completed Chado dump load"
}

load_config
validate_config
create_database
load_chado_dump
