#!/bin/bash
# Description: Adapter trimming and quality filtering for sfRNA-seq using Trimmomatic
# Workflow: Part 01 - sfRNA-seq preprocessing

# ========== Configuration ==========
RAW_DIR="./data/rawdata"                    # Raw FASTQ files
OUT_DIR="./results/trimmed"                   # Trimmed output directory
TRIMMOMATIC_JAR="/path/to/trimmomatic.jar"    # User must update this path
ADAPTERS="/path/to/adapters/TruSeq3-PE.fa"    # User must update this path
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

# Create output directory
mkdir -p "${OUT_DIR}"

# ========== Batch Processing ==========
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Trimmomatic for sfRNA-seq..."
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
echo "Output files: ${OUT_DIR}"