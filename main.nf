#! /usr/bin/env nextflow

nextflow.enable.dsl=2

include { run_nextstrain } from './modules/run_all.nf'

workflow {
  print("Hello World")
}