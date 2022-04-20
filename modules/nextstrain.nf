#! /usr/bin/env nextflow

nextflow.enable.dsl=2

process nextstrain_build {
  label 'nextstrain'
  publishDir "${params.outdir}", mode: 'copy'
  input: path(input_dir)
  output: tuple path("auspice"), path("results")
  script:
  """
  PROC=`nproc`
  ${nextstrain_app} build --cpus \${PROC} --native ${input_dir}
  mv ${input_dir}/auspice .
  mv ${input_dir}/results .
  """
  stub:
  """
  mkdir -p results
  mkdir -p auspice
  touch results/something.txt
  touch auspice/something.txt
  """
}

/* https://docs.nextstrain.org/projects/cli/en/stable/commands/remote/download/ */
process remote_download {
  label 'nextstrain'
  publishDir "${params.outdir}/Downloads", mode: 'copy'
  input: val(s3url)
  output: tuple path("*")
  script: 
  """
  #! /usr/bin/env bash
  ${nextstrain.app} remote download ${s3url}
  """
  stub:
  """
  touch downloadedfile.txt
  """
}

// TODO: take input channel create Snakefile and build.yml for nextstrain build
// process write_Snakefile { }
// process write_buildyml { }