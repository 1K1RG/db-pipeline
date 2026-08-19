#!/usr/bin/env bash

# https://github.com/1K1RG/1k1RG-Scripts/blob/main/conversion/vcftomatrix.sh

invcf=${1? Input VCF file }
pref=${2? Output dir}
mkdir -p $pref

bcftools query -f '%CHROM\t%POS\t%REF\t%ALT[\t%TGT]\n' $invcf |  tr "|" "/"  | \
 tr -d "/" | \
 sed "s:chr0\?::"  | \
 awk -v OFS="\t" '{$1 = $1 + 0; print $0}'  > ${pref}/mat_vcf.txt

cut -f1-4 $pref/mat_vcf.txt > $pref/pos.txt

bcftools view -o -   -h $invcf  |  grep CHR | tr "\t" "\n"  | tail -n+10 > $pref/sample_list.txt

