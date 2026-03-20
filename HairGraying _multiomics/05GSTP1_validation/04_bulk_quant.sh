#!/bin/bash
# Description: Gene expression quantification using featureCounts
# Workflow: Part 05 - Bulk RNA-seq analysis (GSTP1 Validation)

# ========== Configuration ==========
THREADS=20
GTF_FILE="/path/to/gtf/file.gtf"          # Must be updated by user
BAM_DIR="./results/alignment"
OUT_DIR="./results/counts"
RAW_COUNTS="${OUT_DIR}/rawcounts.txt"
ANNOTATED_COUNTS="${OUT_DIR}/bulk_counts_matrix.tsv"

# Create output directory
mkdir -p "${OUT_DIR}"

# Check for GTF file
if [ ! -f "$GTF_FILE" ]; then
    echo "Error: GTF file not found at $GTF_FILE"
    exit 1
fi

# ========== 1. Run featureCounts ==========
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting featureCounts..."

# -p: paired-end reads
# -t exon -g gene_id: count reads mapping to exons and summarize at gene level
featureCounts \
    -T ${THREADS} \
    -p \
    -t exon \
    -g gene_id \
    -a "${GTF_FILE}" \
    -o "${RAW_COUNTS}" \
    "${BAM_DIR}"/*.Aligned.sortedByCoord.out.bam

# Check if featureCounts finished successfully
if [ $? -ne 0 ]; then
    echo "Error: featureCounts failed to complete."
    exit 1
fi

# ========== 2. Annotation & Matrix Cleaning ==========
# This step maps Gene IDs to Gene Symbols and cleans up sample names (header)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Annotating counts and cleaning header..."

awk -F '\t' -v OFS='\t' '
    # Process GTF file (first file in input) to build gene_id -> gene_name map
    NR==FNR && /gene_id ".*".*gene_name "/ {
        match($0, /gene_id "([^"]+)"/, gid)
        match($0, /gene_name "([^"]+)"/, gname)
        if (gid[1] != "" && gname[1] != "")
            gene_map[gid[1]] = gname[1]
        next
    }

    # Process rawcounts file (second file in input)
    NR > FNR {
        if ($0 ~ /^#/) next
        
        # Handle the header row
        if (!header_done) {
            header_done = 1
            printf "Geneid\tSYMBOL\tLength"
            # Loop through sample columns starting from the 7th
            for (i = 7; i <= NF; i++) {
                n = split($i, a, "/")
                sample = a[n]
                # Remove the long STAR suffix to get clean sample names
                sub(/\.Aligned\.sortedByCoord\.out\.bam$/, "", sample)
                printf "\t%s", sample
            }
            print ""
            next
        }

        # Handle data rows
        gene_id = $1
        symbol = gene_map[gene_id]

        # Version-agnostic matching for Ensembl IDs (e.g., ENSG000001.1 -> ENSG000001)
        if (symbol == "") {
            gene_no_ver = gene_id
            sub(/\.[0-9]+$/, "", gene_no_ver)
            symbol = gene_map[gene_no_ver]
            if (symbol == "") symbol = "NA"
        }

        printf "%s\t%s\t%s", gene_id, symbol, $6
        for (i = 7; i <= NF; i++) printf "\t%s", $i
        print ""
    }
' <(zcat -f "${GTF_FILE}") "${RAW_COUNTS}" > "${ANNOTATED_COUNTS}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Quantification complete."
echo "Clean matrix saved to: ${ANNOTATED_COUNTS}"