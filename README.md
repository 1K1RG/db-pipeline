# 1K1RG Pipeline

Converts a VCF into HDF5, then loads the result into a Chado database.

The stages run in order. DB loading reads files that VCF to HDF5 writes under
`output/`.

Run both stages from the repository root; all paths are relative to it.

## VCF to HDF5

### Prerequisites

- Any conda distribution: Miniforge, Anaconda, Miniconda, or whatever your
  cluster already provides. An HPC may already have this as a module.

### Setup

```sh
cp config.vcf-to-hdf5.env.example config.vcf-to-hdf5.env
```

Then edit `config.vcf-to-hdf5.env`.

### Running

With Slurm:

```sh
sbatch --mail-user "YOUR_EMAIL" vcf-to-hdf5.slurm
```

Without Slurm:

```sh
bash vcf-to-hdf5.slurm
```

### Output

- `output/matrix/mat_vcf.txt`, `output/matrix/pos.txt`, and
  `output/matrix/sample_list.txt`
- `output/<OUTPUT_HDF5_NAME>_transp.h5`

## DB Loading

### Prerequisites

- A completed VCF to HDF5 run.
- PostgreSQL, with `psql` available and `sudo` access to the `postgres` role.

### Setup

```sh
cp config.db-loading.env.example config.db-loading.env
```

Then edit `config.db-loading.env`. 

### Running

With Slurm:

```sh
sbatch --mail-user "YOUR_EMAIL" db-loading.slurm
```

Without Slurm:

```sh
bash db-loading.slurm
```
