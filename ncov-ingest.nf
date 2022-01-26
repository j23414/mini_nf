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

// Fetch from s3, but should include fetch new
process fetch_from_biosample {
  publishDir "${params.outdir}/Downloads", mode: 'copy'
  input: path(scripts)
  output: path("data/biosample.ndjson.xz")
  script:
  """
  #bash ${scripts}/fetch-from-biosample
  mkdir data
  bash ${scripts}/download-from-s3 s3://nextstrain-data/files/ncov/open/biosample.ndjson.xz data/biosample.ndjson.xz
  """
}

workflow NCOV_INGEST_PIPE {
  main:
    ncov_ingest_ch = pull_ncov_ingest
    bin_ch = ncov_ingest_ch | map { n -> n.get(1) }
    out_ch = bin_ch | fetch_from_biosample | view

  emit:
    out_ch
}

workflow {
  NCOV_INGEST_PIPE()
}