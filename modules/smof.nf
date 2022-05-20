#! /usr/bin/env nextflow

nextflow.enable.dsl=2

process grep {
  input: tuple path(sequence_fasta), val(query), val(filename)
  output: path("${filename}")
  script:
  """
  smof grep ${query} ${sequence_fasta} > ${filename}
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

process head {
  input: tuple path(sequence_fasta), val(count), val(filename)
  output: path("${filename}")
  script:
  """
  smof head -n ${count} ${sequence_fasta} > ${filename}
  """
}

process stat_length {
  input: tuple path(sequence_fasta), val(filename)
  output: path("${filename}") // tsv file
  script:
  """
  smof stat -lq ${sequence_fasta} > ${filename}
  """
}