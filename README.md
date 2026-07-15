# Bombus_pascuorum_metagenomics

A workflow for Genome Resolved Metagenomics from the gut of *Bombus pascuorum* bumblebee 🐝

bombus_pascuorum_metagenomics/
│
├── data/
│   ├── 01.RawReads/                       # raw fastq files, one subdir per sample
│   │   └── <sample>/
│   │       ├── <sample>_fw.fastq.gz
│   │       └── <sample>_rv.fastq.gz
│   │
│   ├── 02.CleanReads/                     # output of 02_fastp.sh
│   │   └── <sample>/
│   │       ├── <sample>_fw.fastq.gz
│   │       └── <sample>_rv.fastq.gz
│   │
│   ├── 03.HostReads/                      # output of 05_host_depletion.sh (host-mapped reads)
│   │   └── <sample>/...
│   │
│   ├── 03.MicrobiomeReads/                # output of 05_host_depletion.sh (non-host reads)
│   │   └── <sample>/...
│   │
│   ├── 03_Mapping.Stats/                  # alignment statistics from 05_host_depletion.sh
│   │   ├── logs_alignment/
│   │   ├── mapping_summary/
│   │   └── ...
│   │
│   ├── 06.MicrobiotaTaxonomy/             # output of 06_kraken2.sh (Kraken2)
│   │   └── <sample>/...
│   │
│   ├── 06.BrackenTaxonomy/                # output of 06_kraken2.sh (Bracken)
│   │   └── <sample>/...
│   │
│   ├── QC/
│   │   ├── 01.FastQC_MultiQC/             # output of 01_quality_check.sh
│   │   ├── 03_FastQC_MultiQC/             # output of 03_qulity_check_fastp.sh (FastQC on 02.CleanReads)
│   │   └── 03_Fastp_MultiQC/              # output of 03_qulity_check_fastp.sh (MultiQC on fastp + FastQC)
│   │
│   └── references/                        # output of 04_build_host_index.sh (Bowtie2 index, B. pascuorum)
│
├── scripts/                               # all pipeline .sh scripts, submitted via SLURM
│   ├── 01_quality_check.sh
│   ├── 02_fastp.sh
│   ├── 03_qulity_check_fastp.sh
│   ├── 04_build_host_index.sh
│   ├── 05_host_depletion.sh
│   └── 06_kraken2.sh
│
└── logs/                                  # SLURM .out/.err files (one pair per job/script)
