#!/bin/bash
# Description: Adapter trimming and quality filtering for ATAC-seq using Trimmomatic
# Workflow: Part 02 - sfATAC-seq preprocessing

# ========== Configuration ==========
RAW_DIR="./data/rawdata"                    # Raw FASTQ files
OUT_DIR="./results/trimmed"                  # Trimmed output directory
LOG_DIR="./logs/trim_logs"                   # Trimming log directory
TRIMMOMATIC_JAR="/path/to/trimmomatic.jar"   # User must update this path
ADAPTERS="/path/to/adapters/TruSeq3-PE.fa"   # User must update this path
THREADS=10

# Check for required files
if [ ! -f "$TRIMMOMATIC_JAR" ]; then
    echo "Error: Trimmomatic JAR not found at $TRIMMOMATIC_JAR"
    exit 1
fi

if [ ! -f "$ADAPTERS" ]; then
    echo "Error: Adapter file not found at $ADAPTERS"
    exit 1
fi

# Create output directories
mkdir -p "${OUT_DIR}" "${LOG_DIR}"

# ========== Batch Processing ==========
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Trimmomatic for ATAC-seq..."
echo "------------------------------------------------"

for r1 in "${RAW_DIR}"/*_1.fq.gz; do
    # Safety check for file existence
    [ -e "$r1" ] || continue
    
    # Extract base name (e.g., sample_1.fq.gz -> sample)
    base=$(basename "${r1}" _1.fq.gz)
    r2="${RAW_DIR}/${base}_2.fq.gz"
    
    # Verify both read files exist
    if [ ! -f "$r2" ]; then
        echo "Warning: Paired read $r2 not found. Skipping ${base}."
        continue
    fi
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Trimming sample: ${base}"
    
    # Run Trimmomatic
    java -jar "${TRIMMOMATIC_JAR}" PE \
        -threads ${THREADS} \
        -phred33 \
        "${r1}" \
        "${r2}" \
        -trimlog "${LOG_DIR}/${base}.log" \
        -baseout "${OUT_DIR}/${base}.fq.gz" \
        ILLUMINACLIP:"${ADAPTERS}:2:30:10:1:true" \
        LEADING:3 \
        TRAILING:3 \
        SLIDINGWINDOW:4:15 \
        MINLEN:36 > "${OUT_DIR}/${base}.trim.log" 2>&1
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Finished: ${base}"
    echo "------------------------------------------------"
done

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Trimming complete."
echo "Trimmed files: ${OUT_DIR}"
echo "Log files: ${LOG_DIR}"