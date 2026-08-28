# 1K1RG Pipeline

Currently supports VCF-to-HDF5 conversion only.

## Prerequisite

Any conda distribution: Miniforge, Anaconda, Miniconda, or whatever your
cluster already provides. An HPC may already have this as a module.

## Initial Setup

Make a `config.env` based on `config.env.example`

```sh
cp config.env.example config.env
```

Then edit `config.env`.

## Running

### With Slurm

```sh
sbatch --mail-user "YOUR_EMAIL" main.slurm
```

### Without Slurm

```sh
bash main.slurm
```
