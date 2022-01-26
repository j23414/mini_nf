#! /usr/bin/env nextflow

nextflow.enable.dsl=2

process pull_octoFLU{
  publishDir "${params.outdir}/Downloads", mode: 'copy'
  output: tuple path("octoFLU-master")
  script:
  """
  #! /usr/bin/env bash
  wget -O master.zip https://github.com/flu-crew/octoFLU/archive/refs/heads/master.zip
  unzip master.zip
  """
}