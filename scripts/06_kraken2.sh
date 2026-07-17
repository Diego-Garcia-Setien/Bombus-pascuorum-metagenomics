#!/bin/bash
#SBATCH --job-name=06_kraken2
#SBATCH --error=logs/%x-%A_%a.err
#SBATCH --output=logs/%x-%A_%a.out
#SBATCH --partition=general
#SBATCH --qos=regular
#SBATCH --cpus-per-task=8
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=02:00:00
#SBATCH --mem=120000
#SBATCH --array=1-93%25

set -euo pipefail

#################################
# Cargar software
#################################
module load Miniforge3/24.11.3-2
conda activate /scratch/lchueca/conda-env/kraken2

CPU=$SLURM_CPUS_PER_TASK

######################################
# Script: kraken2_taxonomy.sh
#
# Obtener la taxonomía de las secuencias no alineadas
# con el genoma del hospedador obtenidas mediante bowtie2
######################################

WORKDIR=$(pwd)
INPUT_DIR="$WORKDIR/data/03.MicrobiomeReads"
KRAKEN_OUT="$WORKDIR/data/05.MicrobiotaTaxonomy"
BRACKEN_OUT="$WORKDIR/data/05.BrackenTaxonomy"
DATABASE="/data/lchueca/databases/kraken_std"	# Here place kraken2 database

mkdir -p "$KRAKEN_OUT"
mkdir -p "$BRACKEN_OUT"
mkdir -p logs

###############################################################################
# Detect sample automatically (one subdirectory per sample, same layout
# as 01_quality_check.sh / 02_fastp.sh / 05_host_depletion.sh)
###############################################################################

cd "$INPUT_DIR"

SAMPLE=$(find . -mindepth 1 -maxdepth 1 -type d | sort | sed -n "${SLURM_ARRAY_TASK_ID}p")
SAMPLE=${SAMPLE#./}

if [[ -z "$SAMPLE" ]]; then
    echo "ERROR: Sample not found."
    exit 1
fi

SAMPLE_DIR="$INPUT_DIR/$SAMPLE"

R1=$(find "$SAMPLE_DIR" -maxdepth 1 -name "*_microbiome_R1.fastq.gz" | head -1 || true)
R2=$(find "$SAMPLE_DIR" -maxdepth 1 -name "*_microbiome_R2.fastq.gz" | head -1 || true)

if [[ -z "$R1" || -z "$R2" ]]; then
    echo "ERROR: FASTQ files not found."
    echo "$SAMPLE_DIR"
    exit 1
fi

echo
echo "=========================================="
echo "Sample: $SAMPLE"
echo "=========================================="
echo

# Procesando la muestra con kraken2

# Las secuencias clasificadas o no clasificadas se pueden 
# enviar a un archivo para su posterior procesamiento, utilizando los interruptores --classified-out y, 
#respectivamente.--unclassified-out


kraken2 --db "$DATABASE" \
      --threads "$CPU" --paired --minimum-hit-groups 2 \
      --output "$KRAKEN_OUT/${SAMPLE}.kraken2.out" \
      --report "$KRAKEN_OUT/${SAMPLE}.kraken2.report" \
      --gzip-compressed "$R1" "$R2"


echo "Clasificación taxonómica de $SAMPLE terminada"

# Vamos a usar Bracken, que es un programa complementario de Kraken2, 
# Sirve para estimar la abundancia en un solo nivel taxonómico

bracken -d "$DATABASE" -i "$KRAKEN_OUT/${SAMPLE}.kraken2.report" \
      -o "$BRACKEN_OUT/${SAMPLE}.bracken_output" -w "$BRACKEN_OUT/${SAMPLE}.bracken.kreport" -l S \
      -t "$CPU"

