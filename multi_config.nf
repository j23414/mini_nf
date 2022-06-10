#! /usr/bin/env nextflow

nextflow.enable.dsl=2

/* define inputs */
params.configfiles="*.yaml"
params.sequences="*.fasta"
params.metadatas="*.tsv"
params.repo_git="https://github.com/nextstrain/monkeypox.git"

/* parallelized process */
process nextstrain_build {
  input: path(config_file), path(sequences), path(metadatas), val(repo_git)
  output: path("${config_file.baseName}")
  script:
  """
  #! /usr/bin/env bash
  git clone ${repo_git} ${config_file.baseName}
  cd ${config_file.baseName}
  mv ${sequences} ${config_file.baseName}/.
  mv ${metadatas} ${config_file.baseName}/.
  nextstrain build \
    --docker \
    --image=nextstrain/base:branch-nextalign-v2 \
    --cpus 1 \
    . \
    --configfile ${config_file}
  """
}

/* main workflow */
workflow {
  configfiles_ch = channel.fromPath(params.configfiles)
  sequences_ch = channel.fromPath(params.sequences)
  metadatas_ch = channel.fromPath(params.metadatas)

  configfiles_ch
  | view // Should have multiple configs
  | combine(sequences_ch) // all sequence files
  | combine(metadatas_ch) // all metadata files
  | combine(channel.of(params.repo_git) // pick a snakemake workflow
  | nextstrain_build
  | view  // Path to final build/auspice

}