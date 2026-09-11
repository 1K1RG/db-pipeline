#!/usr/bin/env bash

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

require_config_vars() {
  local config_file=$1
  shift

  local variable
  for variable in "$@"; do
    if [[ -z ${!variable:-} ]]; then
      die "$variable is not set in $config_file"
    fi
  done
}
