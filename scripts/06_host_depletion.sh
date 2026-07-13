#!/bin/bash

#SBATCH --job-name=06_host_depletion
#SBATCH --error=logs/%x-%A_%a.err
#SBATCH --output=logs/%x-%A_%a.out

#SBATCH --partition=general
#SBATCH --qos=regular
#SBATCH --cpus-per-task=20
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=03:00:00
#SBATCH --mem=24000
#SBATCH --array=1-93%40

###############################################################################
# Remove host reads while keeping BOTH host and microbiome reads
#
# Outputs:
#
#   data/
#      bam/
#      bam/*.bai
#
#      host_reads/
#
#      microbiome_reads/
#
#      logs_alignment/
#
#      mapping_summary/
#
###############################################################################

set -euo pipefail

module load Bowtie2/2.5.5-GCC-14.2.0
module load SAMtools/1.22-GCC-14.2.0

CPU_BOWTIE=12
CPU_SAMTOOLS=8

WORKDIR=$(pwd)

INPUT_DIR="$WORKDIR/data/fastp_results"

INDEX="$WORKDIR/data/references/BombusPasc"

SAMPLES="$WORKDIR/data/samples.txt"

BAM_DIR="$WORKDIR/data/bam"

HOST_DIR="$WORKDIR/data/host_reads"

MICRO_DIR="$WORKDIR/data/microbiome_reads"

ALIGN_DIR="$WORKDIR/data/logs_alignment"

SUMMARY_DIR="$WORKDIR/data/mapping_summary"

mkdir -p "$BAM_DIR"
mkdir -p "$HOST_DIR"
mkdir -p "$MICRO_DIR"
mkdir -p "$ALIGN_DIR"
mkdir -p "$SUMMARY_DIR"

########################################
# Get sample
########################################

SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLES")

echo
echo "======================================"
echo "Processing sample: $SAMPLE"
echo "======================================"
echo

R1="$INPUT_DIR/${SAMPLE}_1.fastq.gz"
R2="$INPUT_DIR/${SAMPLE}_2.fastq.gz"

########################################
# Alignment
########################################

bowtie2 \
    --very-sensitive \
    --threads "$CPU_BOWTIE" \
    --reorder \
    -x "$INDEX" \
    -1 "$R1" \
    -2 "$R2" \
    2> "$ALIGN_DIR/${SAMPLE}.bowtie2.log" |

samtools view \
    -@ "$CPU_SAMTOOLS" \
    -b - |

samtools sort \
    -@ "$CPU_SAMTOOLS" \
    -o "$BAM_DIR/${SAMPLE}.sorted.bam"

########################################
# Index BAM
########################################

samtools index \
    -@ "$CPU_SAMTOOLS" \
    "$BAM_DIR/${SAMPLE}.sorted.bam"

########################################
# Host reads
########################################

samtools fastq \
    -@ "$CPU_SAMTOOLS" \
    -f 2 \
    "$BAM_DIR/${SAMPLE}.sorted.bam" \
    -1 "$HOST_DIR/${SAMPLE}_host_R1.fastq.gz" \
    -2 "$HOST_DIR/${SAMPLE}_host_R2.fastq.gz" \
    -0 /dev/null \
    -s /dev/null \
    -n

########################################
# Microbiome reads
########################################

samtools fastq \
    -@ "$CPU_SAMTOOLS" \
    -f 12 \
    "$BAM_DIR/${SAMPLE}.sorted.bam" \
    -1 "$MICRO_DIR/${SAMPLE}_microbiome_R1.fastq.gz" \
    -2 "$MICRO_DIR/${SAMPLE}_microbiome_R2.fastq.gz" \
    -0 /dev/null \
    -s /dev/null \
    -n

########################################
# Mapping summary
########################################

TOTAL_READS=$(grep "reads; of these:" \
    "$ALIGN_DIR/${SAMPLE}.bowtie2.log" | awk '{print $1}')

HOST_READS=$(grep "aligned concordantly exactly 1 time" \
    "$ALIGN_DIR/${SAMPLE}.bowtie2.log" | awk '{sum+=$1} END {print sum}')

MULTI_READS=$(grep "aligned concordantly >1 times" \
    "$ALIGN_DIR/${SAMPLE}.bowtie2.log" | awk '{sum+=$1} END {print sum}')

HOST_READS=$((HOST_READS+MULTI_READS))

MICRO_READS=$((TOTAL_READS-HOST_READS))

HOST_PERCENT=$(awk "BEGIN {printf \"%.2f\",100*$HOST_READS/$TOTAL_READS}")

MICRO_PERCENT=$(awk "BEGIN {printf \"%.2f\",100*$MICRO_READS/$TOTAL_READS}")

echo -e "Sample\tTotal_pairs\tHost_pairs\tHost_percent\tMicrobiome_pairs\tMicrobiome_percent" \
> "$SUMMARY_DIR/${SAMPLE}.summary.tsv"

echo -e "${SAMPLE}\t${TOTAL_READS}\t${HOST_READS}\t${HOST_PERCENT}\t${MICRO_READS}\t${MICRO_PERCENT}" \
>> "$SUMMARY_DIR/${SAMPLE}.summary.tsv"

echo
echo "Finished $SAMPLE"
echo
