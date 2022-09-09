#! /usr/bin/env bash
# AUTH: Jennifer Chang
# DATE: 2022/01/26

# input.fasta
INPUT=$1

blastn \
    -db nt \
    -query $INPUT \
    -outfmt 6 \
    -num_alignments 5 \
    -out blast_out.txt \
    -remote
