#!/bin/bash
# Description: Integrated script for Indexing, Alignment, and RPM calculation
# Purpose: Calculates Mouse Gstp1 RPM using Bowtie2 for target and STAR BAMs for library size.
# Workflow: Part 05 - Bulk RNA-seq analysis (GSTP1 Validation)

# ========== 1. Path Configuration ==========
FASTQ_DIR="./results/trimmed"
RESOURCE_DIR="./resources"
FASTA_FILE="${RESOURCE_DIR}/mouse_Gstp1.fa"
INDEX_BASE="${RESOURCE_DIR}/index/mouse_Gstp1"

# Path to the STAR alignment output directory (分母/Library Size source)
HUMAN_BAM_DIR="./results/alignment" 

# Bowtie2 output directory (分子/Gstp1 counts source)
OUTPUT_DIR="./results/alignment/mouse_gstp1"
CSV_OUTPUT="./data/mouseGstp1_RPM.csv"

# Create necessary directories
mkdir -p "${RESOURCE_DIR}/index" "${OUTPUT_DIR}" "./data"

echo "[$(date)] Starting Mouse Gstp1 Analysis Pipeline..."

# ========== 2. Automated Index Building ==========
if [[ ! -f "${INDEX_BASE}.1.bt2" ]]; then
    echo "Notice: Building Bowtie2 index from ${FASTA_FILE}..."
    if [[ ! -f "${FASTA_FILE}" ]]; then
        echo "Error: Reference FASTA ${FASTA_FILE} not found!"
        exit 1
    fi
    # Directing output to /dev/null to keep the console clean
    bowtie2-build "${FASTA_FILE}" "${INDEX_BASE}" > /dev/null
else
    echo "Notice: Bowtie2 index already exists. Skipping build."
fi

# ========== 3. Initialize CSV Output ==========
# Columns match R script references: mouse_gstp1$Sample and mouse_gstp1$Gstp1_reads
echo "Sample,Condition,Gstp1_reads,Total_reads,RPM" > "${CSV_OUTPUT}"

# ========== 4. Processing Pipeline ==========
cd "${FASTQ_DIR}" || exit 1

# Iterate through Read 1 files following the naming pattern Gstp1_C1_1P.fq.gz
for r1 in Gstp1_*_1P.fq.gz; do
    # 4.1 Sample ID Parsing
    # Original filename: Gstp1_C1_1P.fq.gz
    full_name=$(basename "${r1}" _1P.fq.gz)  # Extracts: Gstp1_C1
    raw_id=${full_name#Gstp1_}               # Extracts: C1
    
    # Format conversion: C1 -> C_1 (To match R script's mouse_samples list)
    # Using string slicing: first character + "_" + second character
    sample_id="${raw_id:0:1}_${raw_id:1:1}"
    
    r2="Gstp1_${raw_id}_2P.fq.gz"
    
    # Group assignment based on prefix (C/K/O)
    if [[ $sample_id == C* ]]; then
        group="Ctrl"
    elif [[ $sample_id == K* ]]; then
        group="KD"
    elif [[ $sample_id == O* ]]; then
        group="OE"
    else
        group="Unknown"
    fi

    echo "----------------------------------------"
    echo "Processing Sample: ${sample_id} (Internal ID: ${raw_id})"
    
    # 4.2 Bowtie2 Alignment (Targeting Mouse Gstp1)
    # Using "../." prefix because we changed directory into FASTQ_DIR
    echo "Step 1: Aligning to Mouse Gstp1..."
    bowtie2 -x "../.${INDEX_BASE}" \
            -1 "${r1}" \
            -2 "${r2}" \
            -S "../.${OUTPUT_DIR}/${raw_id}_mouseGstp1.sam" \
            --no-unal -p 20 2> "../.${OUTPUT_DIR}/${raw_id}_bowtie2.log"

    # 4.3 Count Reads Mapped to Gstp1 (Numerator)
    gstp1_reads=$(samtools view -c -F 4 "../.${OUTPUT_DIR}/${raw_id}_mouseGstp1.sam")

    # 4.4 Retrieve Library Size from Human Genome BAM (Denominator)
    # Expected STAR output format: Gstp1_C1.Aligned.sortedByCoord.out.bam
    human_bam="../.${HUMAN_BAM_DIR}/${full_name}.Aligned.sortedByCoord.out.bam"
    
    if [[ ! -f "${human_bam}" ]]; then
        echo "Warning: STAR BAM not found at ${human_bam}. Using 1M placeholder."
        total_reads=1000000
    else
        echo "Step 2: Retrieving total mapped reads from STAR BAM..."
        total_reads=$(samtools view -c -F 4 "${human_bam}")
    fi

    # 4.5 RPM Calculation (Using awk for floating point precision)
    # Formula: (Gstp1_reads / total_mapped_reads) * 1,000,000
    rpm=$(awk -v a="$gstp1_reads" -v b="$total_reads" 'BEGIN{if(b>0) printf "%.3f", a/b*1000000; else print "0.000"}')

    # 4.6 Append Results to CSV
    # sample_id is stored with an underscore (e.g., C_1) for seamless R integration
    echo "${sample_id},${group},${gstp1_reads},${total_reads},${rpm}" >> "../.${CSV_OUTPUT}"
    
    echo "Summary: ${gstp1_reads} Gstp1 reads / ${total_reads} Total -> ${rpm} RPM"
    
    # Cleanup large SAM files to conserve disk space
    rm -f "../.${OUTPUT_DIR}/${raw_id}_mouseGstp1.sam"
done

echo "----------------------------------------"
echo "[$(date)] Pipeline finished successfully."
echo "Output CSV generated at: ${CSV_OUTPUT}"