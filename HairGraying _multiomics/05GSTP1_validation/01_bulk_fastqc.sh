#!/bin/bash
# Description: Quality Control for Bulk RNA-seq (GSTP1 Validation)
# Workflow: Part 05 - Bulk RNA-seq analysis

# ========== Configuration ==========
# Now using local data structure within the module folder
RAW_DIR="./data/rawdata"
OUT_DIR="./results/fastqc"

# Ensure directories exist
if [ ! -d "$RAW_DIR" ]; then
    echo "Error: Raw data directory $RAW_DIR not found."
    exit 1
fi
mkdir -p "${OUT_DIR}"

# ========== 1. Run FastQC ==========
echo "------------------------------------------------"
echo "Running FastQC for quality control..."
fastqc -t 8 -o "${OUT_DIR}" "${RAW_DIR}"/*.fq.gz

# ========== 2. Process QC Metrics ==========
echo "Extracting QC data for summary table..."
# Using -oq for quiet overwrite
for z in "${OUT_DIR}"/*_fastqc.zip; do
    unzip -oq "$z" '*/fastqc_data.txt' -d "${OUT_DIR}/"
done

# ========== 3. Generate Summary Table ==========
echo "Summarizing Q30 and GC content..."
SUMMARY_TABLE="${OUT_DIR}/bulk_qc_summary.tsv"
echo -e "sample\ttotal_reads\tGC_percent\tQ30_percent" > "$SUMMARY_TABLE"

declare -A total_reads_map
declare -A gc_sum_map
declare -A q30_reads_map

for f in "${OUT_DIR}"/*/fastqc_data.txt; do
    # Parsing sample names
    sample=$(basename "$(dirname "$f")" | sed 's/_fastqc//' | sed -E 's/_[12]$//')
    total=$(grep '^Total Sequences' "$f" | awk '{print $3}')
    gc=$(grep '^%GC' "$f" | awk '{print $2}')

    # Summing up Q30 reads
    q30=$(awk '
        BEGIN{flag=0}
        /^>>Per sequence quality scores/{flag=1; next}
        /^>>END_MODULE/{flag=0}
        flag && $1>=30 {sum+=$2}
        END{print sum+0}
    ' "$f")

    # Aggregating values
    total_reads_map[$sample]=$(( ${total_reads_map[$sample]:-0} + total ))
    gc_sum_map[$sample]=$(awk -v prev="${gc_sum_map[$sample]:-0}" -v gc="$gc" -v t="$total" 'BEGIN{print prev + gc*t}')
    q30_reads_map[$sample]=$(( ${q30_reads_map[$sample]:-0} + q30 ))
done

# Output final results
for s in "${!total_reads_map[@]}"; do
    t=${total_reads_map[$s]}
    gc_avg=$(awk -v sum="${gc_sum_map[$s]}" -v t="$t" 'BEGIN{printf "%.2f", sum/t}')
    q30_pct=$(awk -v q30="${q30_reads_map[$s]}" -v t="$t" 'BEGIN{printf "%.2f", (q30/t)*100}')
    echo -e "${s}\t${t}\t${gc_avg}\t${q30_pct}" >> "$SUMMARY_TABLE"
done

echo "------------------------------------------------"
echo "Analysis complete. Summary saved to: $SUMMARY_TABLE"