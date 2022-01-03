#! /usr/bin/env nextflow

nextflow.enable.dsl=2

process nextstrain_build {
  label 'nextstrain'
  publishDir "${params.outdir}", mode: 'copy'
  input: path(input_dir)
  output: tuple path("${input_dir}/auspice"), path("${input_dir}/results")
  script:
  """
  PROC=`nproc`
  ${nextstrain_app} build --cpus \${PROC} --native ${input_dir}
  """
  stub:
  """
  mkdir -p ${input_dir}/results
  mkdir -p ${input_dir}/auspice
  touch ${input_dir}/results/something.txt
  touch ${input_dir}/auspice/something.txt
  """
}

// TODO: take input channel create Snakefile and build.yml for nextstrain build
// process write_Snakefile { }
// process write_buildyml { }