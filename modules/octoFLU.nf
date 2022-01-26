#! /usr/bin/env nextflow

nextflow.enable.dsl=2

process run_octoFLU {
  publishDir "${params.outdir}/Downloads", mode: 'copy'
  input: path(input_fasta)
  output: path("octoFLU-master/${input_fasta}_output")
  script:
  """
  #! /usr/bin/env bash
  wget -O master.zip https://github.com/flu-crew/octoFLU/archive/refs/heads/master.zip
  unzip master.zip
  mv ${input_fasta} octoFLU-master/.
  cd octoFLU-master
  bash octoFLU.sh ${input_fasta}
  """
}