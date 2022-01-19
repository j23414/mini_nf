#! /usr/bin/env nextflow

nextflow.enable.dsl=2

// Merge sequences, the merge metadata is a bit different
// process cat {
//     input: tuple val(output_file), path(input_files) // Pass in multiple files as tuple
//     output: path("${output_file}")
//     script:
//     """
//     cat ${input_files} > ${output_file}
//     """
// }

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

// Prefer xx over gz
process gz_to_xz {
  input: path(file_gz)
  output: path("${file_gz.simpleName}.xz")
  script:
  """
  #! /usr/bin/env bash
  ORIGSUM=\$(gzip -dc ${file_gz} | tee >(xz > ${file_gz.simpleName}.xz) | sha1sum )
  NEWSUM=\$(unxz -c ${file_xz} | sha1sum)
  """
}