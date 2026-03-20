### Single-follicle multi-omics reveals convergent and divergent mechanisms of human hair graying

Single-follicle RNA-seq (sfRNA-seq) and ATAC-seq (sfATAC-seq) of 181 human hair follicles reveals that hair graying is driven by multiple independent mechanisms, with melanin pathways downregulated across all gray follicles and distinct pathways (oxidative stress, p53) altered in specific gray subgroups. GSTP1 is identified as a key regulator of melanogenesis.

### Repository Structure
```
├── 01sfRNA-seq/
│   ├── 01_sfRNA_fastqc.sh
│   ├── 02_sfRNA_trimming.sh
│   ├── 03_sfRNA_alignment.sh
│   ├── 04_sfRNA_quant.sh
│   ├── 05_sfRNA-seq.Rmd
│   └── data/
│       ├── pathway_gene_sets.csv
│       └── rna_group.csv
│
├── 02sfATAC-seq/
│   ├── 01_fastqc.sh
│   ├── 02_trim_atacseq.sh
│   ├── 03_align_atacseq.sh
│   ├── 04_process_atacseq.sh
│   ├── 05_peakcalling_atacseq.sh
│   ├── 06_merge_peaks.sh
│   ├── 07_sfATAC-seq.Rmd
│   ├── 08_motif.sh
│   └── data/
│       ├── atac_group.csv
│       ├── frip.tsv
│       └── resources/
│           ├── hg38.chrom.sizes
│           └── hg38-blacklist.v2.bed
│
├── 03sfOmics_integration/
│   └── sf_omics_integration.Rmd
│
├── 04scRNA-seq/
│   ├── 1_cellranger_count.sh
│   └── 2_scRNA-seq.Rmd
│
├── 05GSTP1_validation/
│   ├── 01_bulk_fastqc.sh
│   ├── 02_bulk_trimming.sh
│   ├── 03_bulk_alignment.sh
│   ├── 04_bulk_quant.sh
│   ├── 05_mouse_gstp1_alignment.sh
│   ├── 06_GSTP1_validation.Rmd
│   └── data/
│       ├── mouseGstp1_RPM.csv
│       └── resources/
│           ├── mouse_Gstp1.fa
│           └── pathway_gene_sets.csv
│
└── environment.yml
```

### Usage
# 1. Clone and setup
git clone https://github.com/Lycorisradiata777/hair-graying.git
cd hair-graying
conda env create -f environment.yml
conda activate hair_omics

# 2. Update paths in shell scripts (see individual scripts for details)
# 3. Run preprocessing scripts in numerical order within each module
# 4. Knit Rmd files for downstream analysis

### Data
The raw sequence data of human sample have been deposited in the Genome Sequence Archive in BIG Data Center, under accession numbers HRA015148 and HRA015056. 
The single cell RNA-seq data of mice has been deposited in Genome Sequence Archive in BIG Data Center under accession number CRA034666. 
Bulk RNA-seq data of GSTP1 knockdown/overexpression/control groups (functional validation) has been deposited in Genome Sequence Archive in BIG Data Center under accession number HRA017261.

### Citation
[To be added upon publication]

### License
MIT
