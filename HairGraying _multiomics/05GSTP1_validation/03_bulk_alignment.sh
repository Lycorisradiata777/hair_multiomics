#!/bin/bash
# Description: RNA-seq read alignment using STAR (2-pass mode)
# Workflow: Part 05 - Bulk RNA-seq analysis (GSTP1 Validation)

# ========== Configuration ==========
INPUT_DIR="./results/trimmed"
GENOME_DIR="/path/to/STAR/index" # Critical: Users must update this to their STAR index path
OUTPUT_DIR="./results/alignment"
LOG_DIR="${OUTPUT_DIR}/logs"
THREADS=10

# Create output directories
mkdir -p "${OUTPUT_DIR}"
mkdir -p "${LOG_DIR}"

# Check if STAR index exists
if [ ! -d "$GENOME_DIR" ]; then
    echo "Error: STAR genome index not found at $GENOME_DIR"
    echo "Please update the GENOME_DIR path in the script."
    exit 1
fi

# ========== Batch Alignment ==========
# Updated pattern to match the output from 02_bulk_trimming.sh
for file in "${INPUT_DIR}"/*_trimmed_1P.fq.gz
do
    # Safety check if files exist
    [ -e "$file" ] || continue
    
    # Extract original sample name (removes the _trimmed_1P.fq.gz suffix)
    base=$(basename "${file}" _trimmed_1P.fq.gz)
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Aligning sample: ${base}"
    
    # Run STAR Alignment
    # Input files are matched based on the trimming script's naming convention
    STAR \
        --runThreadN ${THREADS} \
        --runMode alignReads \
        --genomeDir "${GENOME_DIR}" \
        --readFilesCommand zcat \
        --readFilesIn "${INPUT_DIR}/${base}_trimmed_1P.fq.gz" "${INPUT_DIR}/${base}_trimmed_2P.fq.gz" \
        --outFileNamePrefix "${OUTPUT_DIR}/${base}." \
        --outSAMtype BAM SortedByCoordinate \
        --outSAMstrandField intronMotif \
        --outFilterIntronMotifs RemoveNoncanonical \
        --outSAMattrRGline ID:"${base}" SM:"${base}" LB:lib1 PL:ILLUMINA \
        --outStd Log \
        --outReadsUnmapped Fastx \
        --twopassMode Basic \
        2> "${LOG_DIR}/${base}.log"

    # Indexing the BAM file
    # STAR output name format: [Prefix]Aligned.sortedByCoord.out.bam
    BAM_FILE="${OUTPUT_DIR}/${base}.Aligned.sortedByCoord.out.bam"
    if [ -f "$BAM_FILE" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Indexing BAM: ${base}"
        samtools index "$BAM_FILE"
    fi

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Finished: ${base}"
    echo "------------------------------------------------"
done

# ========== Generate Alignment Summary ==========
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Generating alignment metrics summary..."
SUMMARY_CSV="${OUTPUT_DIR}/bulk_alignment_summary.csv"
echo "Sample,Total_Reads,Unique_Mapped,Multi_Mapped,Unmapped,Mapping_Rate_Pct" > "$SUMMARY_CSV"

for logfile in "${LOG_DIR}"/*.log
do
    [ -e "$logfile" ] || continue
    
    sample=$(basename "${logfile}" .log)
    
    # Extract key metrics from the log file
    total_reads=$(grep "Number of input reads" "${logfile}" | awk '{print $6}')
    unique_mapped=$(grep "Uniquely mapped reads number" "${logfile}" | awk '{print $6}')
    multi_mapped=$(grep "Number of reads mapped to multiple loci" "${logfile}" | awk '{print $9}')
    unmapped=$(grep "Number of reads unmapped: too short" "${logfile}" | awk '{print $7}')
    mapping_rate=$(grep "Uniquely mapped reads %" "${logfile}" | awk '{print $6}' | sed 's/%//')
    
    echo "${sample},${total_reads},${unique_mapped},${multi_mapped},${unmapped},${mapping_rate}" >> "$SUMMARY_CSV"
done

echo "------------------------------------------------"
echo "Alignment process complete."
echo "Summary table saved to: $SUMMARY_CSV"