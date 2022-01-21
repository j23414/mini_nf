#! /usr/bin/env nextflow

nextflow.enable.dsl=2

// === Import reusable modules
include { aws_s3_cp as download_sequences; 
          aws_s3_cp as download_metadata;
          download_lat_longs } from "./modules/downloads.nf"

include { extract_omicron_metadata; 
          get_omicron_strain_names; 
          extract_omicron_sequences;
          filter_meta  } from "./modules/metadata_filter.nf"

include { cat_files as join_ref_meta;
          cat_fasta as join_ref_fasta } from "./modules/unix.nf"

include {dataset_get as download_nextclade_dataset } from "./modules/nextclade.nf"

include {index as create_index;
         filter as exclude_outliers;
         tree ; refine ; ancestral;
         ancestral as ancestral_unmasked;
         export } from "./modules/augur.nf"

include { nextalign as nextclade;
          nextalign as nextclade_after_mask } from "./modules/nextalign.nf"

//include { subsample_meta;
//          mask; 
//          translate;
//          translate as translate_unmasked;
//          recency } from "./modules/wrap_bin.nf"

// === Create specialized processes for this workflow
process pull_ncov_simplest {
  publishDir "${params.outdir}/Downloads", mode: 'copy'
  output: path("ncov-simplest-main")
  script:
  """
  #! /usr/bin/env bash
  wget -O main.zip https://github.com/corneliusroemer/ncov-simplest/archive/refs/heads/main.zip
  unzip main.zip
  """
}

process mk_ncov_simplest_channels {
  publishDir "${params.outdir}/Downloads/subset"
  input: path(simplest_dir)
  output: tuple val("ncov_simplest"),\
    path("ncov-simplest-main/data/pop.csv"),\
    path("ncov-simplest-main/data/root_meta.tsv"),\
    path("ncov-simplest-main/data/reference_seq.fasta"),\
    path("ncov-simplest-main/data/annotation.gff"),\
    path("ncov-simplest-main/data/exclude_tree_build.txt"),\
    path("ncov-simplest-main/data"),\
    path("ncov-simplest-main/scripts") // Huh, could also connect code here
  script:
  """
  """
}

process get_build_specific_channels {
  publishDir "${params.outdir}/Downloads/subset"
  input: tuple val(build), path(data_dir), val(filename)
  output: tuple val("${build}"), path("${data_dir}/${build}/${filename}")
  script:
  """
  """
}

// == Try wrapping ncov-simplest scripts here (latest version from the repo)
//include { subsample_meta;
//          mask; 
//          translate;
//          translate as translate_unmasked;
//          recency } from "./modules/wrap_bin.nf"

process subsample_meta {
  publishDir "${params.outdir}/${build}", mode: 'copy'
  input: tuple val(build), path(metadata), path(population), path(scripts_dir)
  output: tuple val(build), path("metadata_subsampled.tsv")
  script: 
  """
  python ${scripts_dir}/subsample.py \
    --population ${population} \
    --input-metadata ${metadata} \
    --output-metadata metadata_subsampled.tsv
  """
}

// === Create importable workflow
workflow NCOV_SIMPLEST_PIPE {
  main:

    // Pull corneliusroemer/ncov-simplest repository
    pull_ncov_simplest | mk_ncov_simplest_channels 
  
    // Connect channels
    pop_ch = mk_ncov_simplest_channels.out | map { n -> n.get(1) }
    ref_ch = mk_ncov_simplest_channels.out | map { n -> n.get(2) }
    refseq_ch = mk_ncov_simplest_channels.out | map { n -> n.get(3) }
    genemap_ch = mk_ncov_simplest_channels.out | map { n -> n.get(4) }
    exclude_sites_ch = mk_ncov_simplest_channels.out | map { n -> n.get(5) }
    data_ch = mk_ncov_simplest_channels.out | map { n -> n.get(6) }
    scripts_ch = mk_ncov_simplest_channels.out | map { n -> n.get(7) }

    buildname_ch = channel.of("21K", "21L") 
    | combine(data_ch) 
    | combine(channel.of("exclude.txt", "mask_sites.txt", "auspice_config.json")) 
    | get_build_specific_channels

    exclude_ch = buildname_ch | filter({ it.get(1) =~ /exclude/})
    masksites_ch = buildname_ch | filter({ it.get(1) =~ /mask_sites/})
    auspice_cfg_ch = buildname_ch | filter({ it.get(1) =~ /auspice_config/})
  
    sars_ch = channel.of("sars-cov-2")
      | download_nextclade_dataset 
    latlong_ch = channel.of("https://raw.githubusercontent.com/nextstrain/ncov/master/defaults/lat_longs.tsv")
      | download_lat_longs
  
    // === Main Methods
    // Download sequence and metadata from aws s3
    sequences_ch = 
      channel.of("sequences.fasta.xz","s3://nextstrain-ncov-private/sequences.fasta.xz")
      .collate(2)
      | download_sequences
  
    metadata_ch = 
      channel.of("metadata.tsv.gz","s3://nextstrain-ncov-private/metadata.tsv.gz")
      .collate(2)
      | download_metadata
  
    // Omicron data channels
    omicron_ch = metadata_ch
      | extract_omicron_metadata    // omicron_meta_ch
      | get_omicron_strain_names
      | combine(sequences_ch)
      | extract_omicron_sequences   // omicron_seqs_ch
      | combine(channel.of("omicron")) | map { n -> [n.get(1), n.get(0)]}
      | create_index
  
    // Run builds in parallel
    builds_ch = channel.of("21K", "21L")
      | combine(extract_omicron_metadata.out)
      | filter_meta
      | combine(pop_ch)
      | combine(scripts_ch)
      | subsample_meta
      | combine(ref_ch)
      | join_ref_meta
      | join(exclude_ch)    // Exclude by build
      | combine(omicron_ch| map {n -> [n.get(1), n.get(2)]})
      | map {n -> [n.get(0), n.get(3), n.get(4), n.get(1), n.get(2)]}
      | combine(channel.of(""))
      | exclude_outliers
      | combine(refseq_ch)
      | join_ref_fasta
      | combine(sars_ch)
    //  | combine(channel.of("premask"))
    //  | nextclade
    //  | map { n -> [n.get(0), n.get(1)]}
    //  | join(masksites_ch)
    //  | mask
    //  | combine(sars_ch)
    //  | combine(channel.of("omicron"))
    //  | nextclade_after_mask
    //  | map { n -> [n.get(0), n.get(1)]}
    //  | combine(channel.of("-ninit 10 -n 4 -czb -ntmax 10 -nt AUTO")) // iqtree did not recognize  "-T AUTO "
    //  | combine(exclude_sites_ch)
    //  | tree
    //  | combine(channel.of("MN908947"))
    //  | join(mask.out)
    //  | join(join_ref_meta.out)
    //  | refine
  //
    //tree_ch = refine.out
    //  | map { n -> [n.get(0), n.get(1)]}
  //
    //branch_length_ch = refine.out
    //  | map { n -> [n.get(0), n.get(2)]}
    //
    //// === Generate node data (ancestral, translate, recency)
    //// Feat: Could combine mask & unmasked | ancestral
    //// Left separate for readability
    //tree_ch
    //  | join(mask.out)
    //  | combine(channel.of("--infer-ambiguous"))
    //  | combine(channel.of("nt_muts"))
    //  | ancestral
  //
    //unmasked_ch = nextclade.out
    //  | map { n -> [n.get(0), n.get(1)]}
  //
    //tree_ch
    //  | join(unmasked_ch)
    //  | combine(channel.of("--keep-ambiguous --keep-overhangs"))
    //  | combine(channel.of("nt_muts_unmasked"))
    //  | ancestral_unmasked
  //
    //nextclade_after_mask.out
    //  | map { n -> [n.get(0), n.get(2)]}
    //  | join(tree_ch)
  ////    | transpose // ["buildname", omicron.gene.XX.fasta, refined_tree.nwk]
    //  | combine(refseq_ch)
    //  | combine(genemap_ch)
    //  | combine(channel.of("aa_muts"))
    //  | translate // Hmm, I suspect this should happen for all genes
  //
    //nextclade.out
    //  | map { n -> [n.get(0), n.get(2)]}
    //  | join(tree_ch)
  ////    | transpose // ["buildname", omicron.gene.XX.fasta, refined_tree.nwk]
    //  | combine(refseq_ch)
    //  | combine(genemap_ch)
    //  | combine(channel.of("aa_muts_unmasked"))
    //  | translate_unmasked // Hmm, I suspect this should happen for all genes
    //
    //join_ref_meta.out
    //  | recency
    //
    //// combine all node data by build
    //node_data_ch = branch_length_ch
    //  | join(ancestral.out)
    //  | join(ancestral_unmasked.out)
    //  | join(translate.out)
    //  | join(translate_unmasked.out)
    //  | join(recency.out)
    //  | map {n -> [n.get(0), n.drop(1) ]}
  //
    //// Generate final json file for nextstrain view
    //tree_ch
    //  | join(join_ref_meta.out)
    //  | join(node_data_ch)
    //  | combine(latlong_ch)
    //  | join(auspice_cfg_ch)
    //  | export
  
  emit:
    pull_ncov_simplest.out
}

// Similar to the if __main__ in python, call the workflow
workflow {
  NCOV_SIMPLEST_PIPE()
}