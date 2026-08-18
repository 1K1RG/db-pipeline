# 1K1RG Pipeline

Currently supports VCF-to-HDF5 conversion only.

## Prerequisites

- `bcftools`
- `curl`
- `g++`
- `make`

## Setup

Make a `config.env` based on `config.env.example` and edit it.

```sh
cp config.env.example config.env
```

## Running

### With Slurm

```sh
sbatch --mail-user "YOUR_EMAIL" main.slurm
```

### Without Slurm / In a local machine

```sh
bash main.slurm
```
