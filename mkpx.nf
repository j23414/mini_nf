#! /usr/bin/env nextflow
// USAGE: nextflow run mkpx.nf -resume

nextflow.enable.dsl=2

// params.sequences="data/sequences.fasta"
// params.metadata="data/metadata.tsv"

/* Import generalized processes */
include { parse; filter2 as filter; mask; tree; refine; ancestral; translate; traits; export_mkpx as export } from './modules/augur.nf'
include { nextalign_run as align } from './modules/nextalign.nf'
include {lapis_mkpx} from './modules/lapis.nf'

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
  // [/Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/sequences.fasta, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/outbreak.fasta, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/metadata.tsv, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/auspice_config.json, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/colors.tsv, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/description.md, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/exclude.txt, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/genemap.gff, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/lat_longs.tsv, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/mask.bed, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/reference.fasta, /Users/jenchang/github/j23414/mini_nf/work/db/bacc2018cfb08428669fe6f75a73b8/reference.gb]
  lapis_ch = lapis_mkpx()

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

  //todo: link vipr here to pull new data
  //todo: link ncbi here to pull and merge new data

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
  | combine(channel.of(" --timetree --root min_dev --clock-rate 5e-6 --clock-std-dev 3e-6 --coalescent opt --date-inference marginal --clock-filter-iqd 10"))
  | refine
//  | view

  refine_tree_ch = refine.out | map {n -> [n.get(0), n.get(1)]}
  branch_lengths_ch = refine.out | map {n -> [n.get(0), n.get(2)]}

  refine_tree_ch
  | join(mask.out)
  | combine(channel.of(" --inference joint "))
  | ancestral

  refine_tree_ch
  | join(ancestral.out)
  | combine(refg_ch)
  | translate

  refine_tree_ch
  | combine(met_ch) 
  | combine(channel.of(" --columns country --confidence --sampling-bias-correction 3 "))
  | traits

  nodedata_ch = branch_lengths_ch
  | join(ancestral.out)
  | join(translate.out)
  | join(traits.out)
  | map{ n -> [n.get(0), [n.get(1), n.get(2), n.get(3), n.get(4)]]}

  refine_tree_ch
  | combine(met_ch)
  | join(nodedata_ch)
  | combine(col_ch) 
  | combine(ll_ch) 
  | combine(des_ch)
  | combine(ausp_ch)
  | combine(channel.of(" --include-root-sequence "))
  | export
  | view

// (nextstrain) mini_nf % nextflow run mkpx.nf -resume                       
// N E X T F L O W  ~  version 21.10.6
// Launching `mkpx.nf` [drunk_wright] - revision: e3a149cd32
// [97/4c7cf1] process > mkpx_files    [100%] 1 of 1, cached: 1 ✔
// [97/4c7cf1] process > mkpx_files    [100%] 1 of 1, cached: 1 ✔
// [6b/74e1b9] process > filter (1)    [100%] 1 of 1, cached: 1 ✔
// [c1/399c2d] process > align (1)     [100%] 1 of 1, cached: 1 ✔
// [71/7cf467] process > mask (1)      [100%] 1 of 1, cached: 1 ✔
// [27/f449fd] process > tree (1)      [100%] 1 of 1, cached: 1 ✔
// [45/f89cac] process > refine (1)    [100%] 1 of 1, cached: 1 ✔
// [b8/14eb4a] process > ancestral (1) [100%] 1 of 1, cached: 1 ✔
// [8d/918179] process > translate (1) [100%] 1 of 1, cached: 1 ✔
// [40/abeac5] process > traits (1)    [100%] 1 of 1, cached: 1 ✔
// [1c/c2ea56] process > export (1)    [100%] 1 of 1, cached: 1 ✔
// [mkpx, /Users/jenchang/github/j23414/mini_nf/work/1c/c2ea56636a82e3f4ade0e564f646d0/auspice]


// nextstrain view results/mkpx/auspice
}

// [db/bacc20] process > mkpx_files [100%] 1 of 1 ✔
