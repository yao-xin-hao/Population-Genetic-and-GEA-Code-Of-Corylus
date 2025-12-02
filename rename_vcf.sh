#!/usr/bin/env bash
# =====================================================
# Rename CHROM, POS, and ID columns in VCF file.
# CHROM -> Chr1
# POS   -> sequential (1 ... n)
# ID    -> SNP1, SNP2, SNP3, ...
# =====================================================

if [ $# -lt 2 ]; then
    echo "Usage: $0 input.vcf.gz output.vcf.gz"
    exit 1
fi

IN=$1
OUT=$2

echo "🔁 Renaming CHROM, POS, and ID columns ..."
zcat "$IN" | \
awk 'BEGIN{OFS="\t"} /^##/{print; next} /^#CHROM/{print; n=0; next} {n++; $1="Chr1"; $2=n; print}' | \
bgzip > "$OUT"

echo "🔧 Creating index ..."
bcftools index "$OUT"

echo "✅ Done! Saved as $OUT"
