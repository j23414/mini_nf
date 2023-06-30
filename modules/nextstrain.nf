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

process deploy {
  label 'nextstrain'
  publishDir "${params.outdir}", mode: 'copy'
  input: tuple path(auspice), val(s3url)
  output: path("*.log")
  when: params.s3url
  script:
  """
  #! /usr/bin/env bash
  # https://docs.nextstrain.org/projects/cli/en/stable/commands/remote/upload/
  export AWS_ACCESS_KEY_ID=${params.aws_access_key_id}
  export AWS_SECRET_ACCESS_KEY=${params.aws_secret_access_key}

  ( nextstrain remote upload ${s3url} ${auspice}/*.json \
    || echo "No deployment credentials found" ) \
    &> deployment.log
  """
}

// https://github.com/nextstrain/ncov/blob/ce84df93c7774e092e16a55947a4756add80e615/workflow/wdl/tasks/nextstrain.wdl#L3-L142
process build {
  label 'nextstrain'
  publishDir "${params.outdir}", mode: 'copy'
  input: tuple path(pathogen_giturl), path(sequences), path(metadata), path(config)
  output: path("auspice")
  script:
  """
  #! /usr/bin/env bash
  # Example pathogen_giturl https://github.com/nextstrain/zika
  wget -O main.zip ${pathogen_giturl}
  INDIR=`unzip -Z1 main.zip | head -n1 | sed 's:/::g'`
  unzip main.zip

  cp ${sequences} \${INDIR}/.
  cp ${metadata} \${INDIR}/.

  nextstrain build \
    --cpus $task.cpus \
    --native \
    \$INDIR ${config} \

  mv \${INDIR}/auspice .
  """
}

// TODO: take input channel create Snakefile and build.yml for nextstrain build
// process write_Snakefile { }
// process write_buildyml { }