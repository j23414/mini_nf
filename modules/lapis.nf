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

/* Neat scripts */
process plot_the_global_distribution_of_all_sequences {
  publishDir "${params.outdir}/lapis_output", mode: 'copy'
  output: path("plot.pdf") /* sequences.fasta, metadata.tsv */
  script:
  """
  #! /usr/bin/env bash
  # Could also swap this to an Rscript (#! /usr/bin/env Rscript)
  # Yeah this needs to be parameterized to pass in customized queries
  # Set up reasonable width, height
  # Or just move the ggplot to its own module
  # Or read in from the other processes
  ./plot-the-global-distribution-of-all-sequences.R
  """
}

// mkpx
// https://github.com/nextstrain/monkeypox/blob/lapis2/workflow/snakemake_rules/download_via_lapis.smk
process lapis_mkpx {
  output: tuple path("sequences.fasta"), path("metadata.tsv")
  script:
  """
  curl https://mpox-lapis.gen-spectrum.org/v1/sample/fasta --output sequences.fasta
  curl https://mpox-lapis.gen-spectrum.org/v1/sample/details?dataFormat=csv | \
    tr -d "\r" |
    sed -E 's/("([^"]*)")?,/\\2\\t/g' > metadata.tsv
  """
}

process download_sequences_via_lapis {
  publishDir "${params.outdir}/data"
  output: path("sequences.fasta")
  script:
  """
  curl https://mpox-lapis.genspectrum.org/v1/sample/fasta --output sequences.fasta
  """
}

process download_metadata_via_lapis {
  publishDir "${params.outdir}/data"
  output: path("metadata.tsv")
  script:
  """
  curl https://mpox-lapis.genspectrum.org/v1/sample/details?dataFormat=csv \
  | tr -d "\r" \
  | sed -E 's/("([^"]*)")?,/\\2\\t/g' \
  > metadata.tsv
  """
}
