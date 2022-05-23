#! /usr/bin/env nextflow
// USAGE: nextflow run mkpx.nf -resume

nextflow.enable.dsl=2

// params.sequences="data/sequences.fasta"
// params.metadata="data/metadata.tsv"

/* Import generalized processes */
include { parse; index; filter2 as filter; align; tree; refine; ancestral; translate; traits; export_rsv as export } from './modules/augur.nf'
include { mafft } from './modules/fasttree.nf'

/* Bespoke processes */

process mkpx_files {
  publishDir "${params.outdir}/configs"
  output: tuple path("sequences.fasta"), path("outbreak.fasta"), path("metadata.tsv"), path("auspice_config.json"), path("colors.tsv"), path("description.md"), path("exclude.txt"), path("genemap.gff"), path("lat_longs.tsv"), path("mask.bed"), path("reference.fasta"), path("reference.gb")
  script:
  """
  wget -O master.zip https://github.com/nextstrain/monkeypox/archive/refs/heads/master.zip
  unzip master.zip
  mv monkeypox-master/config/* .
  mv monkeypox-master/example_data/* .
  """
}

/* Main workflow */
workflow {
  mkpx_ch = mkpx_files()

  mkpx_ch | view
}

// [db/bacc20] process > mkpx_files [100%] 1 of 1 ✔
// [/Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/sequences.fasta, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/outbreak.fasta, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/metadata.tsv, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/auspice_config.json, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/colors.tsv, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/description.md, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/exclude.txt, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/genemap.gff, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/lat_longs.tsv, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/mask.bed, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/reference.fasta, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/reference.gb]