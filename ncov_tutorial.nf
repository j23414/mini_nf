#! /usr/bin/env Nextflow
/* Temporary file to document steps from the ncov tutorial, also test generalizability of modules */

nextflow.enable.dsl=2

workflow {
  channel.of("Hello") | view
}