#!/bin/bash

#Indexación de un genoma/ secuencia de referencia

$ bowtie2-build bombus_pascuorum_genome.fasta bp_index

#Alineación de un genoma/ secuancia indexada

$ bowtie2 --no-unal -p n -x bp_index -1 reads_1.fastq -2 reads_2.fastq -S output.sam

#-- no-unal es opcional, es para indicar que las lecturas que no se alineen con el genoma de referencia no se escribiram en la sam salida.

#-p es el número (n) de procesadores/hilos utilizados.

#-x es el índice del genoma.

#-1 es el/los archivos que contiene(n) lectura de pareja 1 
#-2 es el/los archivos que contiene(n) lectura de pareja 2

#indicamos que el formato de salida es .sam
