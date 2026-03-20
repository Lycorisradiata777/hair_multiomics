#!/bin/bash
# Description: Quality Control for sfRNA-seq data using FastQC and MultiQC
# Workflow: Part 01 - sfRNA-seq preprocessing

# ========== Configuration ==========
RAW_DIR="./data/rawdata"              # Raw FASTQ files (consistent with GSTP1)
TRIM_DIR="./results/trimmed"           # Output from trim_sfrna.sh
QC_DIR="./results/qc"                  # FastQC output directory
MULTIQC_DIR="./results/multiqc"        # MultiQC report directory
THREADS=10

# Create output directories
mkdir -p "${QC_DIR}/raw" "${QC_DIR}/trimmed" "${MULTIQC_DIR}"

# ========== 1. QC on Raw Data ==========
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running FastQC on raw data..."
echo "------------------------------------------------"
fastqc -t ${THREADS} \
       -o "${QC_DIR}/raw" \
       ${RAW_DIR}/*_1.fq.gz ${RAW_DIR}/*_2.fq.gz 2>/dev/null

# ========== 2. QC on Trimmed Data ==========
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running FastQC on trimmed data..."
fastqc -t ${THREADS} \
       -o "${QC_DIR}/trimmed" \
       ${TRIM_DIR}/*_1P.fq.gz ${TRIM_DIR}/*_2P.fq.gz 2>/dev/null

# ========== 3. MultiQC Summary ==========
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Generating MultiQC report..."
multiqc "${QC_DIR}" -o "${MULTIQC_DIR}" -n sfrna_qc_report.html >/dev/null 2>&1

echo "------------------------------------------------"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] QC process complete."
echo "Individual reports: ${QC_DIR}"
echo "Summary report: ${MULTIQC_DIR}/sfrna_qc_report.html"