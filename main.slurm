#!/usr/bin/env bash

#SBATCH --job-name 1k1rg-db-pipeline
#SBATCH --output logs/1k1rg-db-pipeline-%j.out
#SBATCH --error logs/1k1rg-db-pipeline-%j.error
#SBATCH --cpus-per-task 16
#SBATCH --mem 64G
#SBATCH --partition batch
#SBATCH --qos batch_default
#SBATCH --mail-user
#SBATCH --mail-type ALL

source config.env
bash scripts/vcftomatrix.sh "$INPUT_VCF" output/matrix
