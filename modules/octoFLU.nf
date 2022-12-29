#! /usr/bin/env nextflow

nextflow.enable.dsl=2

process run_octoFLU {
  publishDir "${params.outdir}/Downloads", mode: 'copy'
  input: path(input_fasta)
  output: path("octoFLU-master/${input_fasta}_output")
  script:
  """
  #! /usr/bin/env bash
  if which wget >/dev/null ; then
    download_cmd="wget -O"
  elif which curl >/dev/null ; then
    download_cmd="curl -fsSL --output"
  else
    echo "neither wget nor curl available"
    exit 1
  fi

  \$download_cmd octoFLU.zip https://github.com/flu-crew/octoFLU/archive/refs/heads/master.zip
  
  unzip octoFLU.zip
  mv ${input_fasta} octoFLU-master/.
  cd octoFLU-master
  bash octoFLU.sh ${input_fasta}
  """
}