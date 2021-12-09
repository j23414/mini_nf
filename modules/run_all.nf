#! /usr/bin/env nextflow

nextflow.enable.dsl=2

process run_nextstrain { 
  input: path(infile)
  output: path("${infile.simpleName}_out.txt")
  script:
  """
  nextstrain -h &> ${infile.simpleName}_out.txt
  """
  stub:
  """
  touch ${infile.simpleName}_out.txt
  """
}