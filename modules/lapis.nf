#! /usr/bin/env nextflow
/* 6 end points */
/* FROM: https://lapis.cov-spectrum.org/#introduction */

nextflow.enable.dsl=2

// query = 'country=Switzerland&division=Geneva&pangoLineage=AY.1'
process details {
  publishDir "${params.outdir}/Downloads", mode: 'copy'
  input: tuple val(query), val(result_file)
  output: path("${result_file}") /* sequences.fasta, metadata.tsv */
  script:
  """
  curl "https://lapis.cov-spectrum.org/open/v1/sample/details?${query}" > ${results_file}
  """
}

process fasta {
  publishDir "${params.outdir}/Downloads", mode: 'copy'
  input: tuple val(query), val(result_file)
  output: path("${result_file}") /* sequences.fasta, metadata.tsv */
  script:
  """
  curl "https://lapis.cov-spectrum.org/open/v1/sample/fasta?${query}" > ${results_file}
  """
}

/* could also combine these into one process but oh well */

process aggregated {
  publishDir "${params.outdir}/Downloads", mode: 'copy'
  input: tuple val(query), val(result_file)
  output: path("${result_file}") /* sequences.fasta, metadata.tsv */
  script:
  """
  curl "https://lapis.cov-spectrum.org/open/v1/sample/aggregated?${query}" > ${results_file}
  """
}

process aa_mutations {
  publishDir "${params.outdir}/Downloads", mode: 'copy'
  input: tuple val(query), val(result_file)
  output: path("${result_file}") /* sequences.fasta, metadata.tsv */
  script:
  """
  curl "https://lapis.cov-spectrum.org/open/v1/sample/aa-mutations?${query}" > ${results_file}
  """
}

process nuc_mutations {
  publishDir "${params.outdir}/Downloads", mode: 'copy'
  input: tuple val(query), val(result_file)
  output: path("${result_file}") /* sequences.fasta, metadata.tsv */
  script:
  """
  curl "https://lapis.cov-spectrum.org/open/v1/sample/nuc-mutations?${query}" > ${results_file}
  """
}

process fasta_aligned {
  publishDir "${params.outdir}/Downloads", mode: 'copy'
  input: tuple val(query), val(result_file)
  output: path("${result_file}") /* sequences.fasta, metadata.tsv */
  script:
  """
  curl "https://lapis.cov-spectrum.org/open/v1/sample/fasta-aligned?${query}" > ${results_file}
  """
}
