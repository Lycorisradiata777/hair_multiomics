#!/bin/bash
# Description: Merge ATAC-seq peaks and generate count matrix (summit ±500bp union)
# Workflow: Part 02 - sfATAC-seq preprocessing

# ========== Configuration ==========
SUMMITS_DIR="./results/peakcalling"              # Input from peakcalling_atacseq.sh
BAM_DIR="./results/processed/filtered/FF"        # Input final filtered BAM files
OUTPUT_DIR="./results/merged_peaks"               # Merged peaks output directory
BLACKLIST="/path/to/hg38-blacklist.v2.bed"       # User must update this path
CHROMSIZES="/path/to/hg38.chrom.sizes"           # User must update this path
THREADS=8

# ========== Initialization ==========
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting ATAC-seq peak merging..."
echo "------------------------------------------------"

# Check required files
if [ ! -f "$CHROMSIZES" ]; then
    echo "Error: Chromosome sizes file not found at $CHROMSIZES"
    exit 1
fi
if [ ! -f "$BLACKLIST" ]; then
    echo "Error: Blacklist file not found at $BLACKLIST"
    exit 1
fi

# Create output directory
mkdir -p "${OUTPUT_DIR}"
cd "${OUTPUT_DIR}"

# ========== Find Summit Files ==========
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Locating summit files..."
find "${SUMMITS_DIR}" -name "*_summits.bed" | sort > summits.list

if [ ! -s summits.list ]; then
    echo "Error: No summit files found in ${SUMMITS_DIR}"
    exit 1
fi
echo "Found $(wc -l < summits.list) summit files"

# ========== Create Summit ±500bp Union Peaks ==========
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Creating summit ±500bp union peaks..."
> all_summits_slop500.bed

while read -r summit_file; do
    base=$(basename "$summit_file" _summits.bed)
    bedtools slop -b 500 -g "${CHROMSIZES}" -i "${summit_file}" \
        | bedtools subtract -A -a - -b "${BLACKLIST}" \
        >> all_summits_slop500.bed
done < summits.list

# Sort and merge overlapping regions
bedtools sort -i all_summits_slop500.bed \
    | bedtools merge -i - \
    > peakset_summit_union_500.bed

echo "Generated $(wc -l < peakset_summit_union_500.bed) merged peaks"

# ========== Convert to SAF Format ==========
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Converting peaks to SAF format..."
awk 'BEGIN{OFS="\t"; print "GeneID","Chr","Start","End","Strand"} 
    {id="peak"NR; chr=$1; start=$2+1; end=$3; print id,chr,start,end,"."}' \
    peakset_summit_union_500.bed > peakset_summit_union_500.saf

# ========== Count Reads in Peaks ==========
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Counting reads in merged peaks..."
bam_files=("${BAM_DIR}"/*.ff.bam)

# Check if BAM files exist
if [ ${#bam_files[@]} -eq 0 ]; then
    echo "Error: No BAM files found in ${BAM_DIR}"
    exit 1
fi

featureCounts -T ${THREADS} -p -B -C \
    -a peakset_summit_union_500.saf \
    -F SAF \
    -o peak_counts.txt \
    "${bam_files[@]}" 2> featureCounts.log

# ========== Format Output ==========
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Formatting count matrix..."
grep -v '^#' peak_counts.txt \
    | awk 'NR>1{printf "%s\t%s\t%s\t%s", $2,$3,$4,$1; for(i=7;i<=NF;i++) printf "\t"$i; printf "\n"}' \
    > raw_atac_counts.tsv

# Add header
header=$(head -1 peak_counts.txt | cut -f7- | tr '\t' '\n' | xargs | tr ' ' '\t')
sed -i "1ichr\tstart\tend\tpeak_id\t${header}" raw_atac_counts.tsv

# ========== Summary ==========
echo "------------------------------------------------"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Peak merging complete."
echo "Merged peaks: ${OUTPUT_DIR}/peakset_summit_union_500.bed"
echo "SAF format: ${OUTPUT_DIR}/peakset_summit_union_500.saf"
echo "Count matrix: ${OUTPUT_DIR}/raw_atac_counts.tsv"
echo "FeatureCounts log: ${OUTPUT_DIR}/featureCounts.log"