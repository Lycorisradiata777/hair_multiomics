#!/bin/bash
# Description: HOMER motif analysis on ATAC-seq peaks
# Workflow: Part 02 - sfATAC-seq downstream analysis
# Usage: ./run_homer_motif.sh <pc_group>
# Example: ./run_homer_motif.sh 1P  (for PC1_positive)
#          ./run_homer_motif.sh 1N  (for PC1_negative)

set -euo pipefail

# ========== Configuration ==========
OUTROOT="./results/motif_analysis"
HOMER_GENOME="hg38"
BED_ROOT="./results/tables/rgreat_input"
BG_BED="./results/tables/rgreat_input/background_all_peaks.bed"  # Background peaks
THREADS=10
SIZE="given"             # "given" or fixed window size like "500"
LENS="8,10,12"

# ========== Input Validation ==========
if [ $# -ne 1 ]; then
    echo "Error: Please provide PC+group (e.g., 1P for PC1_positive, 1N for PC1_negative)"
    exit 1
fi

token="$1"

# Parse input
pc=$(echo "${token}" | grep -oE '[0-9]+')
grp_raw=$(echo "${token}" | sed -E 's/^[0-9]+//;s/ //g' | tr '[:lower:]' '[:upper:]')

if [[ "${grp_raw}" =~ ^P(OSITIVE)?$ ]]; then
    grp="positive"
elif [[ "${grp_raw}" =~ ^N(EGATIVE)?$ ]]; then
    grp="negative"
else
    echo "Error: Cannot parse group. Use P for positive or N for negative (e.g., 1P, 2N)"
    exit 1
fi

# ========== Check Input Files ==========
query_bed="${BED_ROOT}/PC${pc}_${grp}_query.bed"
if [ ! -f "${query_bed}" ]; then
    echo "Error: Input BED file not found: ${query_bed}"
    exit 1
fi

if [ ! -f "${BG_BED}" ]; then
    echo "Warning: Background BED file not found: ${BG_BED}"
    echo "Running with default background"
    BG_BED=""
fi

# ========== Output Directory ==========
OUTDIR="${OUTROOT}/PC${pc}_${grp}_homer"
mkdir -p "${OUTDIR}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting HOMER motif analysis"
echo "------------------------------------------------"
echo "Input: ${query_bed}"
echo "Output: ${OUTDIR}"
echo "------------------------------------------------"

# ========== Run findMotifsGenome.pl ==========
if [ -n "${BG_BED}" ]; then
    echo "Running with custom background: ${BG_BED}"
    findMotifsGenome.pl "${query_bed}" "${HOMER_GENOME}" "${OUTDIR}" \
        -size "${SIZE}" -len ${LENS} -bg "${BG_BED}" \
        -p ${THREADS} -mask -bits 2> "${OUTDIR}/homer.log"
else
    echo "Running with default background"
    findMotifsGenome.pl "${query_bed}" "${HOMER_GENOME}" "${OUTDIR}" \
        -size "${SIZE}" -len ${LENS} \
        -p ${THREADS} -mask -bits 2> "${OUTDIR}/homer.log"
fi

# ========== Count Motif Hits ==========
HOMER_HR="${OUTDIR}/homerResults"
if [ ! -d "${HOMER_HR}" ]; then
    echo "Error: homerResults directory not found"
    exit 1
fi

COUNTS_OUT="${OUTDIR}/motif_peak_counts.tsv"
echo -e "motif\thits" > "${COUNTS_OUT}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Counting motif hits..."

for m in "${HOMER_HR}"/*.motif; do
    [ -f "$m" ] || continue
    
    # Extract motif name
    motif_name=$(grep -m1 "^>" "$m" | sed 's/^>//;s/[[:space:]].*$//')
    [ -z "${motif_name}" ] && motif_name=$(basename "$m")
    
    # Count hits in query peaks
    anno_bed="${OUTDIR}/$(basename "${m%.motif}").sites.bed"
    annotatePeaks.pl "${query_bed}" "${HOMER_GENOME}" -m "$m" \
        -size "${SIZE}" -motif -cpu ${THREADS} \
        -mbed "${anno_bed}" > /dev/null 2>&1 || true
    
    hits=$([ -s "${anno_bed}" ] && wc -l < "${anno_bed}" || echo 0)
    echo -e "${motif_name}\t${hits}" >> "${COUNTS_OUT}"
done

echo "------------------------------------------------"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Analysis completed!"
echo "Results: ${OUTDIR}"
echo "Motif hit counts: ${COUNTS_OUT}"
echo "------------------------------------------------"