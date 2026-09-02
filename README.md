# 1K1RG Pipeline

Converts a VCF into HDF5, then loads the result into a Chado database.

The stages run in order. Load DB reads files that Generate HDF5 writes under
`output/`.

Run both stages from the repository root; all paths are relative to it.

## Generate HDF5

### Prerequisites

- Any conda distribution: Miniforge, Anaconda, Miniconda, or whatever your
  cluster already provides. An HPC may already have this as a module.

### Setup

```sh
cp config/generate-hdf5.env.example config/generate-hdf5.env
```

Then edit `config/generate-hdf5.env`.

### Running

With Slurm:

```sh
sbatch --mail-user "YOUR_EMAIL" generate-hdf5.slurm
```

Without Slurm:

```sh
bash generate-hdf5.slurm
```

### Output

- `output/matrix/mat_vcf.txt`, `output/matrix/pos.txt`, and
  `output/matrix/sample_list.txt`
- `output/<OUTPUT_HDF5_NAME>_transp.h5`

## Load DB

### Prerequisites

- A completed Generate HDF5 run.
- PostgreSQL, with `psql` available and `sudo` access to the `postgres` role.

### Setup

```sh
cp config/load-db.env.example config/load-db.env
```

Then edit `config/load-db.env`.

### Running

With Slurm:

```sh
sbatch --mail-user "YOUR_EMAIL" load-db.slurm
```

Without Slurm:

```sh
bash load-db.slurm
```
