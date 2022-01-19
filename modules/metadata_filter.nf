#! /usr/bin/env nextflow

nextflow.enable.dsl=2

/* Move the rest of these processes into different module files later */
process extract_omicron_metadata { // same as filter_meta, but with a gzcat command
  publishDir "${params.outdir}/Omicron", mode: 'copy'
  input: path(metadata)
  output: path("metadata_omicron.tsv")
  script:
  """
  #! /usr/bin/env bash
  gzcat ${metadata} | \
  tsv-filter -H --str-in-fld Nextstrain_clade:Omicron > metadata_omicron.tsv
  """
}

process get_omicron_strain_names {
  publishDir "${params.outdir}/Omicron", mode: 'copy'
  input: path(metadata)
  output: path("omicron_strain_names.txt")
  script:
  """
  #! /usr/bin/env bash
  tsv-select -H -f strain ${metadata} > omicron_strain_names.txt
  """
}

// Filter by list of strain names
process extract_omicron_sequences {
  publishDir "${params.outdir}/Omicron", mode: 'copy'
  input: tuple path(strain_names), path(sequences)
  output: path("gisaid.fasta.gz")
  script:
  """
  xzcat ${sequences} | \
  seqkit grep -f ${strain_names} -o gisaid.fasta.gz
  """
}

// Filter by nextstrain_clade
process filter_meta {
  publishDir "${params.outdir}/${build}", mode: 'copy'
  input: tuple val(build), path(metadata)
  output: tuple val("${build}"), path("metadata_filtered.tsv")
  script:
  """
  #! /usr/bin/env bash
  tsv-filter -H --str-in-fld Nextstrain_clade:${build} ${metadata} > metadata_filtered.tsv
  """
}