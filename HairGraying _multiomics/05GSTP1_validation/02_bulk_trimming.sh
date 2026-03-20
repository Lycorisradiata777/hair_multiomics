#!/bin/bash
# Description: Adapter trimming and quality filtering using Trimmomatic
# Workflow: Part 05 - Bulk RNA-seq analysis (GSTP1 Validation)

# ========== Configuration ==========
RAW_DIR="./data/rawdata"
OUT_DIR="./results/trimmed"
# NOTE: Users should ensure 'trimmomatic' is in their PATH or specify the JAR path
ADAPTERS="/path/to/adapters/TruSeq3-PE.fa" 
THREADS=10

# Create output directory
mkdir -p "${OUT_DIR}"

# Check if adapter file exists
if [ ! -f "$ADAPTERS" ]; then
    echo "Warning: Adapter file not found at $ADAPTERS"
    echo "Please update the ADAPTERS path in the script."
fi

# ========== Batch Processing ==========
# Iterate through forward reads (assuming _1.fq.gz naming convention)
for file in "${RAW_DIR}"/*_1.fq.gz
do
    # Check if files exist to avoid loop errors
    [ -e "$file" ] || continue

    base=$(basename "${file}" _1.fq.gz)
    
    echo "------------------------------------------------"
    echo "Trimming sample: ${base}"
    echo "------------------------------------------------"
    
    # Run Trimmomatic (Assuming 'trimmomatic' command is available in environment)
    # If using JAR directly, use: java -jar /path/to/trimmomatic.jar PE ...
    trimmomatic PE \
        -threads ${THREADS} \
        -phred33 \
        "${RAW_DIR}/${base}_1.fq.gz" \
        "${RAW_DIR}/${base}_2.fq.gz" \
        -baseout "${OUT_DIR}/${base}_trimmed.fq.gz" \
        ILLUMINACLIP:${ADAPTERS}:2:30:10:1:true \
        LEADING:3 \
        TRAILING:3 \
        SLIDINGWINDOW:4:15 \
        MINLEN:36
    
    echo "Finished: ${base}"
done

echo "------------------------------------------------"
echo "All samples processed. Trimmed reads are in: ${OUT_DIR}"