#! /usr/bin/env nextflow

nextflow.enable.dsl=2

process pull_ncov_ingest {
  publishDir "${params.outdir}/Downloads", mode: 'copy'

  output: tuple path("ncov-ingest-master"), \
          path("ncov-ingest-master/bin"), \
          path("ncov-ingest-master/lib"),\
          path("ncov-ingest-master/data")
  
  script:
  """
  #! /usr/bin/env bash
  wget -O master.zip https://github.com/nextstrain/ncov-ingest/archive/refs/heads/master.zip
  unzip master.zip
  """
}

// Fetch from s3, but should include fetch new
// rules: download_main_ndjson, download_biosample
// s3://nextstrain-data/files/ncov/open/biosample.ndjson.xz,
// s3://nextstrain-data/files/ncov/open/genbank.ndjson.xz,
// s3://nextstrain-ncov-private/gisaid.ndjson.xz
process download_s3 {
  publishDir "${params.outdir}/Downloads", mode: 'copy'
  input: tuple val(s3_address), path(scripts)
  output: path("*.xz") // Hope this catches everything.
  script:
  """
  OUTFILE=`echo "${s3_address}" | sed 's:.*/::g'`
  bash ${scripts}/download-from-s3 \
    s3://nextstrain-data/files/ncov/open/biosample.ndjson.xz \
    \${OUTFILE}
  """
}

process transform_biosample {
  publishDir "${params.outdir}/data/genbank", mode: 'copy'
  input: tuple path(biosample_ndjson), path(scripts), path(libs)
  output: path("${biosample_ndjson.simpleName}.tsv")
  script:
  """
  python ${scripts}/transform-biosample \
    ${biosample_ndjson} \
    --output ${biosample_ndjson.simpleName}.tsv
  """
}

workflow NCOV_INGEST_PIPE {
  main:
    // Fetch ncov-ingest repo and bin folder
    ncov_ingest_ch = pull_ncov_ingest()
    bin_ch = ncov_ingest_ch | map { n -> n.get(1) }
    lib_ch = ncov_ingest_ch | map { n -> n.get(2) } // Wow, need this for util errors

    // Fetch biosample, genbank, gisaid
    channel.of(
        "s3://nextstrain-data/files/ncov/open/biosample.ndjson.xz",
        "s3://nextstrain-data/files/ncov/open/genbank.ndjson.xz",
        "s3://nextstrain-ncov-private/gisaid.ndjson.xz")
      | combine(bin_ch)
      | download_s3
      | view

    out_ch = 
      download_s3.out
      | filter({ it =~ /biosample/})
      | combine(bin_ch)
      | combine(lib_ch)
      | transform_biosample

  emit:
    out_ch
}

workflow {
  NCOV_INGEST_PIPE()
}