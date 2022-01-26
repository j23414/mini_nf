#! /usr/bin/env nextflow

nextflow.enable.dsl=2

// query.fasta
params.query_fasta = false
params.genbank_ids = false

// == Import modules
include { nextclade_sars_cov_2 as nextclade } from './modules/nextclade.nf'
include {batchfetchGB as pull_genbanks ; gb_to_fna as convert_to_fasta} from "./modules/wrap_bin.nf"

// == Main workflow
workflow {
  if(params.query_fasta){
    seq_ch = channel.fromPath(params.query_fasta, checkIfExists:true)
  } else if (params.genbank_ids) {
    seq_ch = channel.fromPath(params.genbank_ids, checkIfExists:true)
     | pull_genbanks
     | convert_to_fasta
  }

  seq_ch
  | nextclade
  | view
}