#! /usr/bin/env nextflow

nextflow.enable.dsl=2

// Equivalent to "download_sequences" and "download_metadata"
// Bit dangerous, should only pull 3 per minute...
process aws_s3_cp {
  publishDir "${params.outdir}/downloads", mode: 'copy'
  input: tuple val(filename), val(s3url)
  output: path("${filename}")
  """
  #! /usr/bin/env bash
  aws s3 cp ${s3url} ${filename}
  """
}

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

// Shouldn't the sed commands pre-process the lat_long.tsv instead of here?
process download_lat_longs {
  publishDir "${params.outdir}/downloads", mode: 'copy'
  input: val(lat_url)
  output: path("lat_longs.tsv")
  script:
  """
  #! /usr/bin/env bash
  curl ${lat_url} | \
    sed "s/North Rhine Westphalia/North Rhine-Westphalia/g" | \
    sed "s/Baden-Wuerttemberg/Baden-Wurttemberg/g" \
    > lat_longs.tsv
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

// equivalent to join_ref_meta
process cat_files {
  publishDir "${params.outdir}/${build}", mode: 'copy'
  input: tuple val(build), path(f1), path(f2)
  output: tuple val(build), path("metadata.tsv")
  script:
  """
  cat ${f1} ${f2} > metadata.tsv
  """
}

// equivalent to join_ref_fasta, probably a way to combine with above...
process cat_fasta {
  publishDir "${params.outdir}/${build}", mode: 'copy'
  input: tuple val(build), path(f1), path(f2)
  output: tuple val(build), path("omicron.fasta")
  script:
  """
  cat ${f1} ${f2} > omicron.fasta
  """
}
