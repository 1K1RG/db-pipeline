# 1K1RG Pipeline

Currently supports VCF-to-HDF5 conversion only.

## Prerequisite

Any conda distribution: Miniforge, Anaconda, Miniconda, or whatever your
cluster already provides. On an HPC, this is usually a module that you have to
load in every new shell session before using it.

For example:

```sh
module load anaconda
```

The commands below use `mamba`. Swap in `conda` if that is all you have.

## Initial Setup

1 . Create the environment

```sh
mamba env create -f environment.yml
```

2. Make a `config.env` based on `config.env.example`

```sh
cp config.env.example config.env
```

Then edit config.env

## Running

Make sure the environment is activated first.

```sh
mamba activate 1k1rg-pipeline
```

### With Slurm

```sh
sbatch --mail-user "YOUR_EMAIL" main.slurm
```

### Without Slurm

```sh
bash main.slurm
```
