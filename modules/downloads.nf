#! /usr/bin/env nextflow

nextflow.enable.dsl=2

// Equivalent to "download_sequences" and "download_metadata"
// Bit dangerous, should only pull 3 per minute...
process aws_s3_cp {
  //executor.queueSize = 1
  pollInterval = '30 sec'
  publishDir "${params.outdir}/downloads", mode: 'copy'
  input: tuple val(filename), val(s3url)
  output: path("${filename}")
  script:
  """
  #! /usr/bin/env bash
  # TODO: derive filename from the s3url
  aws s3 cp ${s3url} ${filename}
  """
}

// Prefer https over s3 unless neeed something special about s3
process wget_file {
  publishDir "${params.outdir}/downloads", mode: 'copy'
  input: tuple val(filename), val(https_url)
  output: path("${filename}")
  script:
  """
  #! /usr/bin/env bash
  wget -O ${filename} ${https_url}
  """
}

// Shouldn't the sed commands pre-process the lat_long.tsv instead of here?
process download_lat_longs {
  publishDir "${params.outdir}/downloads", mode: 'copy'
  input: val(lat_url)
  output: path("lat_longs.tsv")
  script:
  """
  #! /usr/bin/env bash
  curl ${lat_url} | \
    sed "s/North Rhine Westphalia/North Rhine-Westphalia/g" | \
    sed "s/Baden-Wuerttemberg/Baden-Wurttemberg/g" \
    > lat_longs.tsv
  """
}

// https://github.com/nextstrain/zika-tutorial/archive/refs/heads/master.zip
process wget_url {
  publishDir "${params.outdir}", mode: "copy"
  input: val(url)
  output: path("zika-tutorial")
  script:
  """
  #! /usr/bin/env bash
  wget "${url}"
  unzip master.zip # There s probably a shorter way
  mv zika-tutorial-master zika-tutorial
  """
  stub:
  """
  mkdir zika-tutorial
  """
}

