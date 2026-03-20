#!/bin/bash
# Description: ATAC-seq peak calling with MACS2 (BAMPE mode for paired-end data)
# Workflow: Part 02 - sfATAC-seq preprocessing

# ========== Configuration ==========
FILTERED_DIR="./results/processed/filtered/FF"   # Input final filtered BAM files (no chrM)
PEAK_DIR="./results/peakcalling"                  # Peak calling output directory
LOG_DIR="./logs/peakcalling_logs"                  # Peak calling logs
GENOME="hs"                                        # Human genome size (hs for hg38)
FDR=0.05                                           # FDR cutoff for peak calling
THREADS=4                                          # MACS2 threads

# ========== Initialization ==========
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting MACS2 peak calling for ATAC-seq..."
echo "------------------------------------------------"

# Check if input BAM files exist
bam_count=$(ls "${FILTERED_DIR}"/*.ff.bam 2>/dev/null | wc -l)
if [ "$bam_count" -eq 0 ]; then
    echo "Error: No BAM files found in ${FILTERED_DIR}"
    exit 1
fi

# Create output directories
mkdir -p "${PEAK_DIR}" "${LOG_DIR}"

# ========== Peak Calling ==========
for bam in "${FILTERED_DIR}"/*.ff.bam; do
    [ -e "$bam" ] || continue
    base=$(basename "$bam" .ff.bam)
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Calling peaks for: ${base}"
    
    # Run MACS2 peak calling
    macs2 callpeak \
        -f BAMPE \
        -t "$bam" \
        -n "${base}" \
        -g "${GENOME}" \
        --nomodel \
        -q "${FDR}" \
        --outdir "${PEAK_DIR}" \
        2> "${LOG_DIR}/${base}.macs2.log"
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Finished: ${base}"
    echo "------------------------------------------------"
done

# ========== Summary ==========
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Peak calling complete."
echo "Peak files: ${PEAK_DIR}"
echo "Log files: ${LOG_DIR}"
echo ""
echo "Output files per sample:"
echo "  - ${PEAK_DIR}/{sample}_peaks.xls      # Tabular peak data"
echo "  - ${PEAK_DIR}/{sample}_peaks.narrowPeak  # NarrowPeak format"
echo "  - ${PEAK_DIR}/{sample}_summits.bed    # Peak summits"