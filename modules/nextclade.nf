#! /usr/bin/env nextflow

nextflow.enable.dsl=2

// Process for each subcommand (nextclade -h)

// Given a dataset name, return nextclade dataset folder
process dataset_get {
  publishDir "${params.outdir}/01_Nextclade", mode: 'copy'
  input: val(dataset_name)
  output: path("${dataset_name}")
  script:
  """
  ${nextclade_app} dataset get \
    --name '${dataset_name}' \
    --output-dir '${dataset_name}'
  """
  stub:
  """
  mkdir ${dataset_name}
  """
}

// Given a dataset and a query, return a folder of clades
process nextclade_run {  // run is nextflow reserved word
  publishDir "${params.outdir}/01_Nextclade", mode: 'copy'
  input: tuple path(dataset), path(query)
  output: path("${query.simpleName}_clades")  
  script:
  """
  ${nextclade_app} run \
    --input-fasta ${query} \
    --input-dataset ${dataset} \
    --output-dir ${query.simpleName}_clades
  """
  stub:
  """
  mkdir ${query.simpleName}_clades
  touch ${query.simpleName}_clades/clades.txt
  """
}

// Subworkflow specific for pulling sars-cov-2 datasets and query
workflow nextclade_sars_cov_2 {
  take:
    query_ch
  main:
    channel.of('sars-cov-2') | dataset_get | combine(query_ch) | nextclade_run
  emit:
    nextclade_run.out
}

// Subworkflow for any virus
workflow nextclade {
  take:
    dataset_ch
    query_ch
  main:
    dataset_ch | get_dataset | combine(query_ch) | nextclade_run
  emit:
    nextclade_run.out
}
