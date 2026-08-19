#!/usr/bin/env bash

#SBATCH --job-name 1k1rg-db-pipeline
#SBATCH --output logs/1k1rg-db-pipeline-%j.out
#SBATCH --error logs/1k1rg-db-pipeline-%j.error
#SBATCH --cpus-per-task 16
#SBATCH --mem 64G
#SBATCH --partition batch
#SBATCH --qos batch_default
#SBATCH --mail-type ALL

set -euo pipefail

readonly CONFIG_FILE=./config.env

die() {
  echo "Error: $1" >&2
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
  if [[ -z ${INPUT_VCF:-} ]]; then
    die "INPUT_VCF is not set in $CONFIG_FILE"
  fi

  if [[ ! -f "$INPUT_VCF" ]]; then
    die "INPUT_VCF $INPUT_VCF not found"
  fi
}

run_vcftomatrix() {
  bash src/vcftomatrix.sh "$INPUT_VCF" output/matrix
}

run_matrixtohdf5() {
  mkdir -p build

  (
    cd build
    bash ../src/build-loadmatrix.sh ../src/loadmatrix_SNP-annot.cpp
  )
}

load_config
validate_config
run_vcftomatrix
run_matrixtohdf5
