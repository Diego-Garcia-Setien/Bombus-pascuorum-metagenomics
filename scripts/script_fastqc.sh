#!/bin/bash

#Slurms commands

#SBATCH --job-name=bp_fastqc_results_tfm
#SBATCH --error=logs/%x-%j.err
#SBATCH --output=logs/%x-%j.out
#SBATCH --partition=general
#SBATCH --qos=regular
#SBATCH --cpus-per-task=8
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=01:00:00
#SBATCH --mem=12000


#First we have to download the software, we can do from the website or using this command:

#$ wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.12.1.zip

#We have to decompress the file and grant execution permissions:

#$ unzip fastqc_v0.12.1.zim $ cd FastQC/ $ chmod u+x fastqc

#We verufy that FastQC works correctly with this help command:

#$ ./Fastqc -h

#########################################
# Script: script_fastqc.sh
#
# Description:
# 	Quality control check on raw sequence
#
# Input:
# 	data/raw_data/raw_data_fastq
#
# Output
# 	data/fastqc_results
#
#
#########################################
#
# Exit immediately if a command fails, an undefined variable is used, or a pipe fails:

set -euo pipefail

#########################################
# Load software
#########################################

module load Miniforge3/24.22.3-2

conda activate /scratch/lchueca/conda-env/fastqc

#########################################
# Settings
#########################################

CPU=8

#########################################
# Directories
# #######################################

WORKDIR=$(pwd)

# For Fastqc

INPUT_DIR="$WORKDIR/data/raw_data/raw_data_fastq"
OUTPUT_DIR="$WORKDIR/data/fastqc_results"

# For Multiqc

INPUT_DIR2="$WORKDIR/data/fastqc_results"
OUTPUT_DIR2="$WORKDIR/data/multiqc_results"


#Now lets create a directory where we will store the results of FastQC

mkdir -p "$OUTPUT_DIR"

#Lets execute FastQC specifying every possible extensions of FastQ files

fastqc -t "$CPU" -o "$OUTPUT_DIR" "$INPUT_DIR"/*.{fastq,fastq.gz,fq,fq.gz}

conda activate /scratch/lchueca/conda-env/multiqc

#We create the directory where we will store the results of MultiQC

mkdir -p "$OUTPUT_DIR2"

#And last, we use MultiQC in the directory of FastQC results and we save in a new directory

multiqc -o "$OUTPUT_DIR2" "$INPUT_DIR2"
