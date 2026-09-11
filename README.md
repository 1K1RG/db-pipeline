# 1K1RG Pipeline

The pipeline provides four independently runnable jobs:

1. Generate an HDF5 dataset from a VCF - `jobs/generate-hdf5.slurm`.
2. Create the database and load the Chado schema -
   `jobs/init-database.slurm`.
3. Load a reference genome - `jobs/load-reference.slurm`.
4. Load a sample dataset - `jobs/load-samples.slurm`.

Run all jobs from the repository root because their paths are relative to that
directory. Each job works with Slurm or as a regular Bash script.

**Why This Repo Exists**

The files in `src/` contain the original implementation of the conversion and
loading steps. They are intentionally kept as close to their original form as
practical. Although they can be called directly, their interfaces rely on
positional arguments and assumptions that are not always clear to a user.

The scripts in `jobs/` are the supported pipeline entry points. They are thin
wrappers around the `src/` scripts that provide:

- named settings in configuration files that can be saved and reused across
  runs, instead of unexplained positional arguments;
- Slurm job and resource settings;
- validation of configuration and input files before work begins; and
- clearer error handling and orchestration of the underlying steps.

Bugs in the original scripts are fixed where needed, but broader changes are
kept in the wrappers so that the legacy implementation remains recognizable.

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
