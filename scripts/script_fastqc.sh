#!/bin/bash

#First we have to download the software, we can do from the website or using this command:

#$ wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.12.1.zip

#We have to decompress the file and grant execution permissions:

#$ unzip fastqc_v0.12.1.zim $ cd FastQC/ $ chmod u+x fastqc

#We verufy that FastQC works correctly with this help command:

#$ ./Fastqc -h

#Now lets create a directory where we will store the results of FastQC

mkdir -p /C:/TFM/GitHub/bombus_pascuorum_metagenomics/data/fastqc_results

#Lets execute FastQC specifying every possible extensions of FastQ files

fastqc -o /C:/TFM/GitHub/bombus_pascuorum_metagenomics/data/fastqc_results /C:/TFM/GitHub/bombus_pascuroum_metagenomics/data/raw_fastq/*.{fastq,fastq.gz,fq,fq.gz}

#Now lets work with MultiQC

#We create the directory where we will store the results of MultiQC

mkdir /C:/TFM/GitHub/data/multiqc_results

#And last, we use MultiQC in the directory of FastQC results and we save in a new directory

multiqc -o /C:/TFM/GitHub/data/multiqc_results /C:/TFM/GitHub/data/fastqc_results
