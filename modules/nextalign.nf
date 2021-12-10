#! /usr/bin/env nextflow

nextflow.enable.dsl=2

process nextalign {
  publishDir "${params.outdir}/01_nextalign", mode: 'copy'
  input: tuple path(sequences), path(reference), path(gff)
  output: path("nextalign")
  script:
  """
  #! /usr/bin/env bash
  # Pull gene names from gff file
  GENES=`cat ${gff} | awk -F'gene_name=' '{print \$2}' |grep -v "^\$"|tr '\n' ','|sed 's/,\$//g'`
  ${nextalign_app} \
    --sequences=${sequences} \
    --reference=${reference} \
    --genemap=${gff} \
    --genes=\${GENES} \
    --output-dir=nextalign/ \
    --output-basename=${sequences.simpleName}
  """
  stub:
  """
  mkdir nextalign
  touch nextalign/${sequences.simpleName}_aln.fasta
  """
}