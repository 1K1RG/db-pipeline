#!/usr/bin/env bash

# Based on https://github.com/1K1RG/1k1RG-Scripts/blob/main/conversion/make_HDF_dataset.sh

indir=${1? Input directory with files pos.txt, sample_list.txt, and mat_vcf.txt}
proj=${2? Output HDF5 name, e.g. ricerp}
outdir=${3? Output directory}
loadmatrix=${4? Path to loadmatrix_geno}

n_snp=$(wc -l "$indir/pos.txt" | awk '{print $1}')
# n_sampl=$(wc -l "$indir/sample_list.txt" | awk '{print $1}')

m=1000
n=64

mkdir -p "$outdir"

"$loadmatrix" -m $m -n $n -r $n_snp \
  -i "$indir/mat_vcf.txt" \
  -o "$outdir/${proj}_transp.h5" \
  -t
