#! /usr/bin/env nextflow

nextflow.enable.dsl=2

process grep {
  input: tuple val(query), path(sequence_fasta)
  output: path("${query}.fasta")
  script:
  """
  smof grep ${query} ${sequence_fasta} > ${query}.fasta
  """
}

process xz_grep {
  input: tuple val(query), path(sequence_fasta)
  output: path("${query}.fasta")
  script:
  """
  xzcat ${sequence_fasta} | smof grep ${query} > ${query}.fasta
  """
}