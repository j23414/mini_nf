#! /usr/bin/env Nextflow
/* Temporary file to document steps from the ncov tutorial, also test generalizability of modules */
// https://docs.nextstrain.org/projects/ncov/en/latest/
// https://nextstrain.atlassian.net/wiki/spaces/NEXTSTRAIN/pages/139427848/nCoV+tutorial+brainstorming

nextflow.enable.dsl=2

include { aws_s3_cp as download_metadata;
          aws_s3_cp as download_alignment } from "./modules/downloads.nf"

include {xz_fasttree as fasttree} from "./modules/fasttree.nf"

process summarize_metadata {
  publishDir "${params.outdir}/00_CreateContext", mode: 'copy'
  input: path(metadata_tsv_xz)
  output: path("${metadata_tsv_xz.simpleName}_summary.txt")
  script:
  """
  xzcat ${metadata_tsv_xz} |\
    tsv-select -H -f Nextstrain_clade |\
    grep -v -e "Nextstrain_clade" -e "^\$" |\
    sort | \
    uniq -c > ${metadata_tsv_xz.simpleName}_summary.txt
  """
}

workflow {
  /* Step 1 - identify contextual sequences from public data */
  // Took a while to find the public dataset: https://docs.nextstrain.org/projects/ncov/en/latest/reference/remote_inputs.html
  metadata_ch = 
    channel.of(
      "global_metadata.tsv.xz","s3://nextstrain-data/files/ncov/open/global/metadata.tsv.xz",
      "metadata.tsv.gz","s3://nextstrain-data/files/ncov/open/metadata.tsv.gz")
    .collate(2)
    | download_metadata
  // Preferentially use xz over gz, but then will need `xzcat` or `gzcat` commands in steps... hmm, will need to think.
  metadata_ch 
    | summarize_metadata

  // Wait a second, number of sequences seems low
  // Yup, subsampled: https://docs.nextstrain.org/projects/ncov/en/latest/reference/remote_inputs.html
  alignment_ch =
    channel.of("aligned.fasta.xz","s3://nextstrain-data/files/ncov/open/global/aligned.fasta.xz")
    .collate(2)
    | download_alignment
//    | fasttree

  /* Step 2 - pick some focal sequences? (washington state, same as tutorial, I think) */

  /* Step 3 - Generate basic build.yaml file */

  /* Step 4 - fetch ncov */

  /* Step 5 - run */
  
  /* Step 6 - view */
}