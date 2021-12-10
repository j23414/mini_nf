#! /usr/bin/env nextflow

nextflow.enable.dsl=2

// process nextalign {
//     script:
//     """
//     nextalign \
//       --sequences=sequences.fasta \
//       --reference=reference.fasta \
//       --genemap=genemap.gff \
//       --genes=E,M,N,ORF1a,ORF1b,ORF3a,ORF6,ORF7a,ORF7b,ORF8,ORF9b,S \
//       --output-dir=output/ \--output-basename=nextalign
//     """
// }