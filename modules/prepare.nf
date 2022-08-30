#! /usr/bin/env nextflow
// prepare.smk

nextflow.enable.dsl=2

process download {
  publishDir "${params.outdir}/data"
  input: tuple val(sequences_url), val(metadata_url)
  output: tuple path("sequences.fasta.xz"), path("metadata.tsv.gz")
  script:
  """
  curl -fsSL --compressed ${sequences_url} --output sequences.fasta.xz
  curl -fsSL --compressed ${metadata_url} --output metadata.tsv.gz
  """
}

process decompress {
  publishDir "${params.outdir}/data"
  input: tuple val(sequences), val(metadata)
  output: tuple path("sequences.fasta"), path("metadata.tsv")
  script:
  """
  gzip --decompress --stdout ${metadata} > metadata.tsv
  xz --decompress --stdout ${sequences} > sequences.fasta
  """
}
