#!/bin/bash
# Description: ATAC-seq read alignment using Bowtie2
# Workflow: Part 02 - sfATAC-seq preprocessing

# ========== Configuration ==========
TRIMMED_DIR="./results/trimmed"              # Input from trim_atacseq.sh
ALIGN_DIR="./results/alignment"               # Main alignment directory
BAM_DIR="${ALIGN_DIR}/bam"                    # BAM files subdirectory
LOG_DIR="${ALIGN_DIR}/logs"                    # Log files directory
BOWTIE2_INDEX="/path/to/bowtie2index/GRCh38"  # User must update this path
THREADS=20

# ========== Initialization ==========
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Bowtie2 alignment for ATAC-seq..."
echo "------------------------------------------------"

# Check if Bowtie2 index exists
if [ ! -f "${BOWTIE2_INDEX}.1.bt2" ] && [ ! -f "${BOWTIE2_INDEX}.1.bt2l" ]; then
    echo "Error: Bowtie2 index not found at ${BOWTIE2_INDEX}"
    exit 1
fi

# Create output directories
mkdir -p "${BAM_DIR}" "${LOG_DIR}"

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
    
    # Run Bowtie2 alignment and pipe to samtools sort
    bowtie2 -p ${THREADS} \
        --very-sensitive \
        -X 2000 \
        -x "${BOWTIE2_INDEX}" \
        -1 "${r1}" \
        -2 "${r2}" \
        2> "${LOG_DIR}/${base}.bowtie2.log" | \
        samtools sort -O bam -@ ${THREADS} -o "${BAM_DIR}/${base}.bam" -
    
    # Check if alignment was successful
    if [ $? -eq 0 ] && [ -f "${BAM_DIR}/${base}.bam" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Finished alignment: ${base}"
    else
        echo "Error: Alignment failed for ${base}"
        continue
    fi
    
    echo "------------------------------------------------"
done

# ========== Post-Processing ==========
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Processing BAM files..."

for bam in "${BAM_DIR}"/*.bam; do
    [ -e "$bam" ] || continue
    
    base=$(basename "${bam}" .bam)
    
    echo "Indexing: ${base}"
    samtools index "${bam}" 2>> "${LOG_DIR}/indexing.log"
    
    echo "Generating metrics: ${base}"
    samtools flagstat "${bam}" > "${LOG_DIR}/${base}.flagstat.txt"
    samtools stats "${bam}" > "${LOG_DIR}/${base}.stats.txt"
    
    echo "------------------------------------------------"
done

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Alignment complete."
echo "BAM files: ${BAM_DIR}"
echo "Log files: ${LOG_DIR}"
echo "Metrics: ${LOG_DIR}"