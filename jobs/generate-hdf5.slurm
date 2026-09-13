#!/usr/bin/env bash

#SBATCH --job-name 1k1rg-generate-hdf5
#SBATCH --output logs/1k1rg-generate-hdf5-%j.out
#SBATCH --error logs/1k1rg-generate-hdf5-%j.error
#SBATCH --cpus-per-task 2
#SBATCH --mem 2G
#SBATCH --partition batch
#SBATCH --qos batch_default
#SBATCH --mail-type ALL

set -euo pipefail

source ./utils.sh

readonly CONFIG_FILE=./config/generate-hdf5.env

validate_config() {
  require_config_vars "$CONFIG_FILE" INPUT_VCF

  if [[ ! -f "$INPUT_VCF" ]]; then
    die "INPUT_VCF $INPUT_VCF not found"
  fi

  require_config_vars "$CONFIG_FILE" OUTPUT_HDF5_NAME
}

load_conda_module() {
  if [[ -z ${CONDA_MODULE:-} ]]; then
    return
  fi

  if ! command -v module &>/dev/null; then
    die "CONDA_MODULE is set to $CONDA_MODULE but no module command was found"
  fi

  if ! module load "$CONDA_MODULE"; then
    die "Failed to load module $CONDA_MODULE"
  fi
}

create_env() {
  local name=$1

  local env_manager
  if ! env_manager=$(find_env_manager); then
    die "Neither mamba nor conda was found; set CONDA_MODULE if needed"
  fi

  local environments
  if ! environments=$("$env_manager" env list); then
    die "Failed to list environments with $env_manager"
  fi

  local environment_exists=$(
    awk -v name="$name" '$1 == name { print "true"; exit }' <<<"$environments"
  )
  if [[ $environment_exists == true ]]; then
    return
  fi

  if ! "$env_manager" env create -f environment.yml; then
    die "Failed to create environment $name"
  fi
}

find_env_manager() {
  if command -v mamba &>/dev/null; then
    echo mamba
  elif command -v conda &>/dev/null; then
    echo conda
  else
    return 1
  fi
}

initialize_conda() {
  local shell_hook

  if ! command -v conda &>/dev/null; then
    die "Conda is required to activate environments in this shell"
  fi

  if ! shell_hook=$(conda shell.bash hook); then
    die "Failed to initialize Conda for this shell"
  fi

  if ! eval "$shell_hook"; then
    die "Failed to initialize Conda for this shell"
  fi
}

activate_env() {
  local env_name=$(
    awk '/^name:/ { sub(/^name:[[:space:]]*/, ""); print; exit }' \
      environment.yml
  )
  if [[ -z $env_name ]]; then
    die "Could not read the environment name"
  fi

  if [[ ${CONDA_DEFAULT_ENV:-} == "$env_name" ]]; then
    log "Environment $env_name is already active"
    return
  fi

  load_conda_module
  create_env "$env_name"
  initialize_conda

  if ! conda activate "$env_name"; then
    die "Failed to activate environment $env_name"
  fi

  log "Activated environment $env_name"
}

run_vcftomatrix() {
  log "Starting VCF-to-matrix conversion"
  bash src/vcftomatrix.sh "$INPUT_VCF" "output/matrix/$OUTPUT_HDF5_NAME"
  log "Completed VCF-to-matrix conversion"
}

run_matrixtohdf5() {
  log "Starting matrix-to-HDF5 conversion"
  mkdir -p build

  (
    cd build
    bash ../src/build-loadmatrix.sh ../src/loadmatrix_SNP-annot.cpp >/dev/null
  )

  bash src/make_HDF_dataset.sh \
    "output/matrix/$OUTPUT_HDF5_NAME" \
    "$OUTPUT_HDF5_NAME" \
    output \
    build/loadmatrix_geno
  log "Completed matrix-to-HDF5 conversion"
}

load_config "$CONFIG_FILE"
validate_config
activate_env
run_vcftomatrix
run_matrixtohdf5
