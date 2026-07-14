#!/bin/bash
#SBATCH --job-name=bp_kraken2_tfm
#SBATCH --error=logs/%x-%A_%a.err
#SBATCH --output=logs/%x-%A_%a.out
#SBATCH --partition=general
#SBATCH --qos=regular
#SBATCH --cpus-per-task=8
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=01:00:00
#SBATCH --mem=12000
#SBATCH --array=1-93%93

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
INPUT_DATA="$WORKDIR/data/microbiota_reads"
OUTPUT_DATA="$WORKDIR/data/microbiota_taxonomy"
SAMPLE_LIST="$WORKDIR/data/samples.txt"
DATABASE="$WORKDIR/data/kraken_std"

mkdir -p "$OUTPUT_DATA"
mkdir -p logs

# Selecciona la muestra correspondiente a esta tarea del array
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLE_LIST")

R1="$INPUT_DATA/${SAMPLE}_microbiota_1.fastq.gz"
R2="$INPUT_DATA/${SAMPLE}_microbiota_2.fastq.gz"

if [[ ! -f "$R1" || ! -f "$R2" ]]; then
  echo "ERROR: no se encuentran los fastq de $SAMPLE" >&2
  exit 1
fi

# Procesando la muestra con kraken2

# Las secuencias clasificadas o no clasificadas se pueden enviar a un archivo para su posterior procesamiento, utilizando los interruptores --classified-out y , respectivamente.--unclassified-out


kraken2 --db "$DATABASE" --threads "$CPU" --paired --minimum-hit-groups 4 --output "$OUTPUT_DATA/${SAMPLE}.kraken2.out" --report "$OUTPUT_DATA/${SAMPLE}.kraken2.report" "$R1" "$R2" --gzip-compressed


echo "Clasificación taxonómica de $SAMPLE terminada"

# Vamos a usar Bracken, que es un programa complementario de Kraken2, 
# Sirve para estimar la abundancia en un solo nivel taxonómico

#################################
# Cargar software
#################################
conda activate /scratch/lchueca/conda-env/bracken


KRAKEN2_DATA="$WORKDIR/data/microbiota_taxonomy"
BRACKEN_DATA="$WORKDIR/data/bracken_taxonomy"



mkdir -p "$BRACKEN_DATA"

bracken -d "$DATABASE" -i "$OUTPUT_DATA/${SAMPLE}.kraken2.report" -o "$BRACKEN_DATA/${SAMPLE}.bracken_output" -w "$BRACKEN_DATA/${SAMPLE}.bracken.kreport" -r 150 -l S -t 10
