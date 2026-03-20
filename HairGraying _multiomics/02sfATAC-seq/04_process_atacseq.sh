#!/bin/bash
# Description: ATAC-seq post-alignment processing: QC filtering, duplicate removal, mitochondrial removal, BW/BED conversion
# Workflow: Part 02 - sfATAC-seq preprocessing

# ========== Configuration ==========
ALIGN_DIR="./results/alignment/bam"          # Input BAM files from align_atacseq.sh
PROCESS_DIR="./results/processed"             # Main processed output directory
FILTER_DIR="${PROCESS_DIR}/filtered"          # Filtered BAM files by step
BW_DIR="${PROCESS_DIR}/bigwig"                # BigWig files
BED_DIR="${PROCESS_DIR}/bed"                   # BED files
LOG_DIR="./logs/process_logs"                  # Processing logs
THREADS=20
GENOME_SIZE=2913022398  # Effective genome size for hg38

# ========== Initialization ==========
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting ATAC-seq post-alignment processing..."
echo "------------------------------------------------"

# Create output directories
mkdir -p "${FILTER_DIR}/QF"    # Quality filtered (q30)
mkdir -p "${FILTER_DIR}/DF"    # Duplicate filtered
mkdir -p "${FILTER_DIR}/FF"    # Final filtered (no chrM)
mkdir -p "${BW_DIR}" "${BED_DIR}" "${LOG_DIR}"

# Check if input BAM files exist
bam_count=$(ls "${ALIGN_DIR}"/*.bam 2>/dev/null | wc -l)
if [ "$bam_count" -eq 0 ]; then
    echo "Error: No BAM files found in ${ALIGN_DIR}"
    exit 1
fi

# ========== Step 1: Quality Filtering (-q 30, -F 1804) ==========
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Step 1: Quality filtering (MAPQ >= 30)..."
for bam in "${ALIGN_DIR}"/*.bam; do
    [ -e "$bam" ] || continue
    base=$(basename "$bam" .bam)
    echo "Filtering: ${base}"
    
    samtools view -@ ${THREADS} -b -q 30 -F 1804 "$bam" \
        -o "${FILTER_DIR}/QF/${base}.qf.bam" 2>> "${LOG_DIR}/${base}.qf.log"
done

# ========== Step 2: Sort and Index Quality-Filtered BAMs ==========
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Step 2: Sorting and indexing..."
for qf_bam in "${FILTER_DIR}/QF"/*.qf.bam; do
    [ -e "$qf_bam" ] || continue
    base=$(basename "$qf_bam" .qf.bam)
    echo "Sorting: ${base}"
    
    samtools sort -@ ${THREADS} "$qf_bam" -o "${FILTER_DIR}/QF/${base}.sorted.bam" \
        2>> "${LOG_DIR}/${base}.sort.log"
    samtools index "${FILTER_DIR}/QF/${base}.sorted.bam" \
        2>> "${LOG_DIR}/${base}.index.log"
done

# ========== Step 3: Remove PCR Duplicates ==========
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Step 3: Removing PCR duplicates..."
for sorted_bam in "${FILTER_DIR}/QF"/*.sorted.bam; do
    [ -e "$sorted_bam" ] || continue
    base=$(basename "$sorted_bam" .sorted.bam)
    echo "Deduplicating: ${base}"
    
    sambamba markdup -r -t ${THREADS} \
        "$sorted_bam" "${FILTER_DIR}/DF/${base}.df.bam" \
        2>> "${LOG_DIR}/${base}.dedup.log"
done

# ========== Step 4: Remove Mitochondrial Reads ==========
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Step 4: Removing mitochondrial reads (chrM)..."
for df_bam in "${FILTER_DIR}/DF"/*.df.bam; do
    [ -e "$df_bam" ] || continue
    base=$(basename "$df_bam" .df.bam)
    echo "Removing chrM: ${base}"
    
    # Filter out chrM and index
    samtools view -h "$df_bam" | grep -v chrM | \
        samtools view -bS -o "${FILTER_DIR}/FF/${base}.ff.bam" \
        2>> "${LOG_DIR}/${base}.chrM.log"
    samtools index "${FILTER_DIR}/FF/${base}.ff.bam" \
        2>> "${LOG_DIR}/${base}.ff_index.log"
done

# ========== Step 5: Convert to BigWig Format ==========
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Step 5: Converting to BigWig..."
for ff_bam in "${FILTER_DIR}/FF"/*.ff.bam; do
    [ -e "$ff_bam" ] || continue
    base=$(basename "$ff_bam" .ff.bam)
    echo "Creating BigWig: ${base}"
    
    bamCoverage --bam "$ff_bam" \
        -o "${BW_DIR}/${base}.bw" \
        --binSize 10 \
        --normalizeUsing RPGC \
        --effectiveGenomeSize ${GENOME_SIZE} \
        --extendReads \
        2>> "${LOG_DIR}/${base}.bw.log"
done

# ========== Step 6: Convert to BED Format ==========
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Step 6: Converting to BED..."
for ff_bam in "${FILTER_DIR}/FF"/*.ff.bam; do
    [ -e "$ff_bam" ] || continue
    base=$(basename "$ff_bam" .ff.bam)
    echo "Creating BED: ${base}"
    
    bedtools bamtobed -i "$ff_bam" > "${BED_DIR}/${base}.bed" \
        2>> "${LOG_DIR}/${base}.bed.log"
done

# ========== Summary ==========
echo "------------------------------------------------"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Processing complete."
echo "Quality filtered BAMs: ${FILTER_DIR}/QF/"
echo "Deduplicated BAMs: ${FILTER_DIR}/DF/"
echo "Final filtered BAMs (no chrM): ${FILTER_DIR}/FF/"
echo "BigWig files: ${BW_DIR}"
echo "BED files: ${BED_DIR}"
echo "Log files: ${LOG_DIR}"