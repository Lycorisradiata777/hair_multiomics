#!/bin/bash
# Description: Quality Control for ATAC-seq data using FastQC and MultiQC
# Workflow: Part 02 - sfATAC-seq preprocessing

# ========== Configuration ==========
RAW_DIR="./data/rawdata"              # Raw FASTQ files (consistent with GSTP1/sfRNA)
QC_DIR="./results/qc"                  # FastQC output directory
MULTIQC_DIR="./results/multiqc"        # MultiQC report directory
THREADS=4

# Create output directories
mkdir -p "${QC_DIR}/raw" "${MULTIQC_DIR}"

# ========== 1. QC on Raw Data ==========
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running FastQC on ATAC-seq raw data..."
echo "------------------------------------------------"
fastqc -t ${THREADS} \
       -o "${QC_DIR}/raw" \
       ${RAW_DIR}/*.gz 2> "${QC_DIR}/raw/fastqc.log"

# Set locale for MultiQC
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# ========== 2. MultiQC Summary ==========
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Generating MultiQC report..."
multiqc "${QC_DIR}/raw" \
        -o "${MULTIQC_DIR}" \
        -n atac_seq_qc_report.html 2> "${MULTIQC_DIR}/multiqc.log"

echo "------------------------------------------------"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] QC process complete."
echo "Individual reports: ${QC_DIR}/raw"
echo "Summary report: ${MULTIQC_DIR}/atac_seq_qc_report.html"