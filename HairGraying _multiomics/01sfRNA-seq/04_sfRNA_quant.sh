#!/bin/bash
# Description: Gene expression quantification using featureCounts for sfRNA-seq
# Workflow: Part 01 - sfRNA-seq preprocessing

# ========== Configuration ==========
BAM_DIR="./results/alignment/bam"              # Input BAM files from align_sfrna.sh
COUNT_DIR="./results/counts"                    # Output directory for count matrices
GTF_FILE="/path/to/genes.gtf"                   # User must update this path
THREADS=20

# ========== Initialization ==========
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting featureCounts for sfRNA-seq..."
echo "------------------------------------------------"

# Check if GTF file exists
if [ ! -f "$GTF_FILE" ]; then
    echo "Error: GTF file not found at $GTF_FILE"
    exit 1
fi

# Check if BAM files exist
bam_count=$(ls "${BAM_DIR}"/*.bam 2>/dev/null | wc -l)
if [ "$bam_count" -eq 0 ]; then
    echo "Error: No BAM files found in ${BAM_DIR}"
    exit 1
fi

# Create output directory
mkdir -p "${COUNT_DIR}"

# ========== Run featureCounts ==========
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Processing ${bam_count} BAM files..."
echo "Output: ${COUNT_DIR}/rawcounts.txt"

featureCounts \
    -T ${THREADS} \
    -p \
    -t exon \
    -g gene_id \
    -a "${GTF_FILE}" \
    -o "${COUNT_DIR}/rawcounts.txt" \
    "${BAM_DIR}"/*.bam 2> "${COUNT_DIR}/featureCounts.log"

# Check if featureCounts completed successfully
if [ $? -eq 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] featureCounts completed successfully."
    
    # Generate summary (optional, similar to GSTP1's annotation step)
    echo "Summary of counts:"
    echo "- Raw counts: ${COUNT_DIR}/rawcounts.txt"
    echo "- Log file: ${COUNT_DIR}/featureCounts.log"
    
    # Basic count statistics
    total_features=$(tail -n +2 "${COUNT_DIR}/rawcounts.txt" | wc -l)
    echo "- Total features quantified: ${total_features}"
else
    echo "Error: featureCounts failed. Check ${COUNT_DIR}/featureCounts.log"
    exit 1
fi

echo "------------------------------------------------"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Counting complete."
echo "Output directory: ${COUNT_DIR}"