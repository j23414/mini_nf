#! /usr/bin/env nextflow

nextflow.enable.dsl=2

// Merge sequences, the merge metadata is a bit different
// process cat {
//     input: tuple val(output_file), path(input_files) // Pass in multiple files as tuple
//     output: path("${output_file}")
//     script:
//     """
//     cat ${input_files} > ${output_file}
//     """
// }

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