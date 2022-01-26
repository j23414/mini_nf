#! /usr/bin/env nextflow

nextflow.enable.dsl=2

params.query_fasta

include { run_octoFLU } from "./modules/octoFLU.nf"

workflow {
  channel.fromPath(params.query_fasta, checkIfExists:true) 
  | run_octoFLU
  | view
}