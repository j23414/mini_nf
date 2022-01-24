#! /usr/bin/env Nextflow
/* Temporary file to document steps from the ncov tutorial, also test generalizability of modules */
// https://docs.nextstrain.org/projects/ncov/en/latest/
// https://nextstrain.atlassian.net/wiki/spaces/NEXTSTRAIN/pages/139427848/nCoV+tutorial+brainstorming

nextflow.enable.dsl=2

include { aws_s3_cp } from "./modules/downloads.nf"

workflow {
  /* Step 1 - identify contextual sequences from public data */
  // Took a while to find the public dataset: https://docs.nextstrain.org/projects/ncov/en/latest/reference/remote_inputs.html
  metadata_ch = 
    channel.of("metadata.tsv.gz","s3://nextstrain-data/files/ncov/open/global/metadata.tsv.xz")
    .collate(2)
    | aws_s3_cp

  /* Step 2 - pick some focal sequences? (washington state, same as tutorial, I think) */

  /* Step 3 - Generate basic build.yaml file */

  /* Step 4 - fetch ncov */

  /* Step 5 - run */
  
  /* Step 6 - view */
}