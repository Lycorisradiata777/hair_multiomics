#!/bin/bash
# Description: sfRNA-seq read alignment using STAR
# Workflow: Part 01 - sfRNA-seq preprocessing

# ========== Configuration ==========
TRIMMED_DIR="./results/trimmed"                # Input from trim_sfrna.sh
ALIGN_DIR="./results/alignment"                 # Main alignment directory
BAM_DIR="${ALIGN_DIR}/bam"                      # BAM files subdirectory
GENOME_DIR="/path/to/star_index"                # User must update this path
THREADS=10

# ========== Initialization ==========
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting STAR alignment for sfRNA-seq..."
echo "------------------------------------------------"

# Check if STAR index exists
if [ ! -d "$GENOME_DIR" ]; then
    echo "Error: STAR genome index not found at $GENOME_DIR"
    exit 1
fi

# Create output directories
mkdir -p "${BAM_DIR}"

# ========== Batch Alignment ==========
for r1 in "${TRIMMED_DIR}"/*_1P.fq.gz; do
    # Safety check
    [ -e "$r1" ] || continue
    
    # Extract base name (e.g., sample_1P.fq.gz -> sample)
    base=$(basename "${r1}" _1P.fq.gz)
    r2="${TRIMMED_DIR}/${base}_2P.fq.gz"
    
    # Verify paired file exists
    if [ ! -f "$r2" ]; then
        echo "Warning: Paired file $r2 not found. Skipping ${base}."
        continue
    fi
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Aligning sample: ${base}"
    
    # Run STAR alignment
    STAR \
        --runThreadN ${THREADS} \
        --runMode alignReads \
        --genomeDir "${GENOME_DIR}" \
        --readFilesCommand zcat \
        --readFilesIn "${r1}" "${r2}" \
        --outFileNamePrefix "${ALIGN_DIR}/${base}." \
        --outSAMtype BAM SortedByCoordinate \
        --outSAMunmapped Within \
        --outSAMattributes Standard \
        2> "${ALIGN_DIR}/${base}.star.log"
    
    # Move and rename BAM file
    if [ -f "${ALIGN_DIR}/${base}.Aligned.sortedByCoord.out.bam" ]; then
        mv "${ALIGN_DIR}/${base}.Aligned.sortedByCoord.out.bam" "${BAM_DIR}/${base}.bam"
    else
        echo "Error: BAM file not generated for ${base}"
        continue
    fi
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Finished alignment: ${base}"
    echo "------------------------------------------------"
done

# ========== Indexing ==========
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Indexing BAM files..."

for bam in "${BAM_DIR}"/*.bam; do
    [ -e "$bam" ] || continue
    
    base=$(basename "${bam}" .bam)
    echo "Indexing: ${base}"
    samtools index "${bam}" 2>> "${BAM_DIR}/indexing.log"
done

echo "------------------------------------------------"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Alignment complete."
echo "BAM files: ${BAM_DIR}"
echo "Log files: ${ALIGN_DIR}"