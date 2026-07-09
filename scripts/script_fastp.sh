#!/bin/bash

#SBATCH --job-name=bp_fastp_results_tfm
#SBATCH --error=logs/%x-%j.err
#SBATCH --output=logs/%x-%j.out
#SBATCH --partition=general
#SBATCH --qos=regular
#SBATCH --cpus-per-task=8
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=01:00:00
#SBATCH --mem=12000

#######################################
# Load software
#######################################

module load Miniforge3/24.11.3-2

conda activate /scratch/lchueca/conda-env/fastp

CPU=8

#Data

WORKDIR=$(pwd)

INPUT_DIR="$WORKDIR/data/raw_data"
OUTPUT_DIR="$WORKDIR/data/fastp_results"
#FAILED=

#Creamos la carpeta para guardar los resultados de fastp

mkdir -p ./data/fastp_results

#Creamos también la carpeta donde se guardaran las lecturas que no superan los filtros

mkdir -p ./data/fastp_failed

#Vamos a utilizar fastp
#Tenemos que trabajar con los archivos forward y reverse
#Primero buscamos los archivos forward

cd "$INPUT_DIR"

for fwd in *_1.fq.gz; do
	
	#Asegurar que el archivo existe
	[ -e "$fwd" ] || continue

	#Identificar el archivo reverse correspondiente (_2.fastq.gz)
	rev="${fwd/_1.fq.gz/_2.fq.gz}"

	#Cambiamos el nombre corto y limpio para la muestra resultante
	base=$(basename "$fwd" _1.fq.gz)

	echo "Procesando muestra: $base"
	echo " -> [R1]: $fwd"
	echo " -> [R2]: $rev"

	#Ejecutamos fastp emparejado
	fastp \
		--thread "$CPU" \
		-i "$fwd" \
		-I "$rev" \
		-o "/scratch/lchueca/bombus_pascuorum_metagenomics/data/fastp_results/${base}_clean_R1.fq.gz" \
		-O "/scratch/lchueca/bombus_pascuorum_metagenomics/data/fastp_results/${base}_clean_R2.fq.gz" \
		--detect_adapter_for_pe \
		--trim_poly_g \
		--trim_poly_x \
		--cut_front 10 \
		--cut_tail \
		--qualified_quality_phred 33 \
		--html "/scratch/lchueca/bombus_pascuorum_metagenomics/data/fastp_results/${base}_report.html" \
		--json "/scratch/lchueca/bombus_pascuorum_metagenomics/data/fastp_results/${base}_report.json" \
		--failed_out "/scratch/lchueca/bombus_pascuorum_metagenomics/data/fastp_failed/${base}_failed.fq.gz"
done
