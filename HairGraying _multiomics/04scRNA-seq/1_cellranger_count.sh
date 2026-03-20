#!/bin/bash
# Description: Batch processing of scRNA-seq samples using Cell Ranger count
# Workflow: Part 04 - scRNA-seq validation

# ========== Configuration ==========
CELLRANGER="/path/to/cellranger"                    # Cell Ranger path
REFERENCE="/path/to/refdata-gex-GRCh38-2020-A"      # Reference genome path
BASE_DIR="scRNA-seq/data"                            # Base directory containing sample _outs folders
OUTPUT_DIR="scRNA-seq/results/cellranger"            # Output directory

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# ========== Sample List ==========
samples=("O1" "O2" "Y1" "Y2")

# ========== Batch Run Cell Ranger count ==========
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Cell Ranger count for all samples..."
echo "------------------------------------------------"

for sample in "${samples[@]}"; do
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Processing sample: ${sample}"
    
    # FASTQ file path
    FASTQ_DIR="${BASE_DIR}/${sample}_outs/fastq_output"
    
    # Check if FASTQ directory exists
    if [ ! -d "${FASTQ_DIR}" ]; then
        echo "Error: FASTQ directory not found: ${FASTQ_DIR}"
        continue
    fi
    
    # Run Cell Ranger count
    ${CELLRANGER} count \
        --id=${sample} \
        --transcriptome=${REFERENCE} \
        --fastqs=${FASTQ_DIR} \
        --sample=${sample} \
        --expect-cells=5000 \
        --localcores=16 \
        --localmem=64 \
        --output-dir="${OUTPUT_DIR}/${sample}" 2> "${OUTPUT_DIR}/${sample}.log"
    
    # Check if run was successful
    if [ $? -eq 0 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${sample} completed successfully"
        echo "Output: ${OUTPUT_DIR}/${sample}/outs/raw_feature_bc_matrix/"
    else
        echo "Error: ${sample} failed"
    fi
    
    echo "------------------------------------------------"
done

echo "[$(date '+%Y-%m-%d %H:%M:%S')] All samples processed!"