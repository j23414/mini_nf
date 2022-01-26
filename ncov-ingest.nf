#! /usr/bin/env nextflow

nextflow.enable.dsl=2

process pull_ncov_ingest {
  publishDir "${params.outdir}/Downloads", mode: 'copy'
  output: tuple path("ncov-ingest-master"), path("ncov-ingest-master/bin"), path("ncov-ingest-master/data")
  script:
  """
  #! /usr/bin/env bash
  wget -O master.zip https://github.com/nextstrain/ncov-ingest/archive/refs/heads/master.zip
  unzip master.zip
  """
}

workflow NCOV_INGEST_PIPE {
  main:
    out_ch = pull_ncov_ingest | view

  emit:
    out_ch
}

workflow {
  NCOV_INGEST_PIPE()
}