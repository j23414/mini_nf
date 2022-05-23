#! /usr/bin/env nextflow
// USAGE: nextflow run mkpx.nf -resume

nextflow.enable.dsl=2

// params.sequences="data/sequences.fasta"
// params.metadata="data/metadata.tsv"

/* Import generalized processes */
include { parse; index; filter2 as filter; mask; tree; refine; ancestral; translate; traits; export_rsv as export } from './modules/augur.nf'
//include { mafft } from './modules/fasttree.nf'

include { nextalign_run as align } from './modules/nextalign.nf'

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
  //mkpx_ch | view

  seq_ch = mkpx_ch | map{ n -> n.get(0) }
  // add a merge
  met_ch = mkpx_ch | map{ n -> n.get(2) }
  ausp_ch = mkpx_ch | map{ n -> n.get(3) }
  col_ch = mkpx_ch | map{ n -> n.get(4) }
  des_ch = mkpx_ch | map{ n -> n.get(5) }
  exc_ch = mkpx_ch | map{ n -> n.get(6) }
  gm_ch = mkpx_ch | map{ n -> n.get(7) }
  ll_ch = mkpx_ch | map{ n -> n.get(8) }
  mask_ch = mkpx_ch | map{ n -> n.get(9) }
  reff_ch = mkpx_ch | map{ n -> n.get(10) }
  refg_ch = mkpx_ch | map{ n -> n.get(11) }

  channel.of("mkpx")
  | combine(seq_ch)
  | combine(met_ch)
  | combine(exc_ch)
  | combine(channel.of(" --group-by country year --sequences-per-group 1000 --min-date 1950 --min-length 10000 "))
  | filter
  | combine(reff_ch)
  | combine(channel.of(" --jobs 1 --max-indel 10000 --nuc-seed-spacing 1000 ")) // seed-spacing
  | align
  | combine(mask_ch)
  | combine(channel.of(" --mask-from-beginning 1500 --mask-from-end 1000 "))
  | mask
  | combine(channel.of(""))
  | tree
  | join(mask.out)
  | combine(met_ch)
  | combine(channel.of(" --timetree --root min_dev --clock-rate 5e-6 --clock-std-dev 3e-6 --coalescenct opt --date-inference marginal --clock-filter-iqd 10"))
//  | refine
  | view
}

// [db/bacc20] process > mkpx_files [100%] 1 of 1 ✔
// [/Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/sequences.fasta, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/outbreak.fasta, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/metadata.tsv, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/auspice_config.json, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/colors.tsv, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/description.md, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/exclude.txt, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/genemap.gff, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/lat_longs.tsv, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/mask.bed, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/reference.fasta, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/reference.gb]

// nextalign run -v \
//  --sequences=sequences_filtered.fasta \
//  --reference=reference.fasta \
//  --output-fasta=aligned.fasta \
//  --jobs 1 \
//  --max-indel 10000 \
//  --seed-spacing 1000