#! /usr/bin/env nextflow
nextflow.enable.dsl=2

include { index; filter; align; tree; refine; ancestral; translate; traits; export } from './modules/augur.nf'

process pull_zika {
  publishDir "${params.outdir}/Downloads", mode: 'copy'
  output: path("zika-tutorial-master")
  script:
  """
  #! /usr/bin/env bash
  wget -O master.zip https://github.com/nextstrain/zika-tutorial/archive/refs/heads/master.zip
  unzip master.zip
  """
}

process mk_zika_channels {
  publishDir "${params.outdir}/Downloads/subset"
  input: path(zika_dir)
  output: tuple val("zika"),\
    path("zika-tutorial-master/data/sequences.fasta"),\
    path("zika-tutorial-master/data/metadata.tsv"),\
    path("zika-tutorial-master/config/dropped_strains.txt"),\
    path("zika-tutorial-master/config/zika_outgroup.gb"),\
    path("zika-tutorial-master/config/colors.tsv"),\
    path("zika-tutorial-master/config/lat_longs.tsv"),\
    path("zika-tutorial-master/config/auspice_config.json")
  script:
  """
  """
}

workflow ZIKA_EXAMPLE_PIPE {
  main:
    // Pull nextstrain/zika-tutorial repo and files
    pull_zika | mk_zika_channels

    // Connect channels
    build_ch = mk_zika_channels.out | map {n -> n.get(0)}
    sequences_ch = mk_zika_channels.out | map {n -> n.get(1)}
    metadata_ch = mk_zika_channels.out | map {n -> n.get(2)}
    exclude_ch = mk_zika_channels.out | map {n -> n.get(3)}
    ref_ch = mk_zika_channels.out | map {n -> n.get(4)}
    colors_ch = mk_zika_channels.out | map {n -> n.get(5)}
    lat_longs_ch = mk_zika_channels.out | map {n -> n.get(6)}
    auspice_config_ch = mk_zika_channels.out | map {n -> n.get(7)}

    build_ch
    | combine(sequences_ch)
    | index
    | combine(metadata_ch)
    | combine(exclude_ch)
    | combine(channel.of("--group-by country year month --sequences-per-group 20 --min-date 2012"))
    | filter
    | combine(ref_ch)
    | combine(channel.of("--fill-gaps"))
    | align
    | combine(channel.of(""))
    | tree
    | join(align.out)
    | combine(metadata_ch)
    | combine(channel.of("--timetree --coalescent opt --date-confidence --date-inference marginal --clock-filter-iqd 4"))
    | refine

    tree_ch = refine.out 
      | map { n-> [n.get(0), n.get(1)] }
    
    branch_length_ch = refine.out 
      | map{ n-> [n.get(0), n.get(2)] }
    
    tree_ch
      | join(align.out) 
      | combine(channel.of("--inference joint"))
      | ancestral
    
    tree_ch 
      | join(ancestral.out) 
      | combine(ref_ch) 
      | translate
    
    tree_ch
      | combine(metadata_ch) 
      | combine(channel.of("--columns region country --confidence"))
      | traits
  
    node_data_ch = branch_length_ch
      | join(traits.out)
      | join(ancestral.out)
      | join(translate.out)
      | map {n -> [n.drop(1)]}
    
    tree_ch
      | combine(metadata_ch)
      | combine(node_data_ch)
      | combine(colors_ch) 
      | combine(lat_longs_ch) 
      | combine(auspice_config_ch)
      | export

  emit:
    export.out
}

workflow {
  ZIKA_EXAMPLE_PIPE()
}