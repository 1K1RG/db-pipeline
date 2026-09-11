# 1K1RG Pipeline

Converts a VCF into HDF5 and loads reference and sample data into a Chado
database.

The pipeline provides four independently runnable jobs:

1. Generate an HDF5 dataset from a VCF with `jobs/generate-hdf5.slurm`.

2. Create the database and load the Chado schema with
   `jobs/init-database.slurm`.

3. Load a reference genome with `jobs/load-reference.slurm`.

   This requires an initialized database.

4. Load a sample dataset with `jobs/load-samples.slurm`.

   This requires a generated HDF5 dataset and its reference genome. Run it
   separately for each dataset.

Run all jobs from the repository root because their paths are relative to that
directory. Each job works with Slurm or as a regular Bash script.

## Generate HDF5

### Prerequisites

- Any conda distribution: Miniforge, Anaconda, Miniconda, or whatever your
  cluster already provides. An HPC may already have this as a module.

### Setup

If it does not already exist, create `config/generate-hdf5.env` based on
`config/generate-hdf5.env.example`:

```sh
cp config/generate-hdf5.env.example config/generate-hdf5.env
```

Then edit `config/generate-hdf5.env`.

### Running

With Slurm:

```sh
sbatch --mail-user "YOUR_EMAIL" jobs/generate-hdf5.slurm
```

Without Slurm:

```sh
bash jobs/generate-hdf5.slurm
```

### Output

- `output/matrix/mat_vcf.txt`, `output/matrix/pos.txt`, and
  `output/matrix/sample_list.txt`
- `output/<OUTPUT_HDF5_NAME>_transp.h5`

## Initialize Database

### Prerequisites

- PostgreSQL, with `psql` available and `sudo` access to the `postgres` role.

### Setup

If it does not already exist, create `config/database.env` based on
`config/database.env.example`:

```sh
cp config/database.env.example config/database.env
```

Then edit `config/database.env`. The reference and sample jobs use this same
database configuration.

### Running

With Slurm:

```sh
sbatch --mail-user "YOUR_EMAIL" jobs/init-database.slurm
```

Without Slurm:

```sh
bash jobs/init-database.slurm
```

## Load Reference Genome

### Prerequisites

- A completed Initialize Database run.
- A reference genome GFF file.

### Setup

If it does not already exist, create `config/load-reference.env` based on
`config/load-reference.env.example`:

```sh
cp config/load-reference.env.example config/load-reference.env
```

Then edit `config/load-reference.env`.

### Running

With Slurm:

```sh
sbatch --mail-user "YOUR_EMAIL" jobs/load-reference.slurm
```

Without Slurm:

```sh
bash jobs/load-reference.slurm
```

To use a different reference configuration, pass its path to the job:

```sh
sbatch jobs/load-reference.slurm config/my-reference.env
```

## Load Samples

### Prerequisites

- A completed Generate HDF5 run for the dataset.
- A completed Initialize Database run.
- The dataset's reference genome loaded in the database.

### Setup

If it does not already exist, create `config/load-samples.env` based on
`config/load-samples.env.example`:

```sh
cp config/load-samples.env.example config/load-samples.env
```

Then edit `config/load-samples.env`.

### Running

With Slurm:

```sh
sbatch --mail-user "YOUR_EMAIL" jobs/load-samples.slurm
```

Without Slurm:

```sh
bash jobs/load-samples.slurm
```

For repeated loads, create a separate configuration based on
`config/load-samples.env.example` for each dataset and pass its path to the
job:

```sh
cp config/load-samples.env.example config/my-dataset.env
sbatch jobs/load-samples.slurm config/my-dataset.env
```
