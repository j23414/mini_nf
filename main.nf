#! /usr/bin/env nextflow
// import org.yaml.snakeyaml.Yaml // TODO: read native snakemake yaml
nextflow.enable.dsl=2

// Option 1: Wrap everything in one nextflow task
include { nextstrain_build } from './modules/nextstrain.nf'

// Option 2: Wrap individual modules in Nextflow
include { index; filter; align; tree; refine; ancestral; translate; traits; export } from './modules/augur.nf'
include { nextclade_sars_cov_2 as nextclade } from './modules/nextclade.nf'
include { nextalign } from './modules/nextalign.nf'
include { batchfetchGB as pull_genbanks ; gb_to_fna as convert_to_fasta; build_params} from './modules/wrap_bin.nf'
include { wget_url } from './modules/unix.nf'

workflow {
/* TODO: read native snakemake yaml
  if (params.yaml) {
    parameter_yaml = new FileInputStream(new File(params.yaml))
    new Yaml().load(parameter_yaml).each { k, v -> params[k] = v }
    params[sequences] = params.input.sequences ? "${params.input.sequences}" : "${params.sequence}"
  }
*/

  // == main
  // TODO: sub args passed as json/dict
  // TODO: allow skipping of steps (snakemake skips via named input)

  // ======== Data Fetch (aws/rest/eutils) =======================

  //  /* ========= Genbank -> Nextclade (works) ======= */
  //  gb_ch = Channel.fromPath(params.genbank_ids, checkIfExists:true)
  //  seq_ch = gb_ch | pull_genbanks | convert_to_fasta
  //  clades_ch  = seq_ch | nextclade
  
  //  /* ========= Nextstrain ======== */
  if (params.input_url) {  // Option 0?: pull data from url
    channel.of(params.input_url) |
      wget_url |
      nextstrain_build
  } else {
    if (params.input_dir) {  // Option 1: Fast wrapped route (default)
        channel.fromPath(params.input_dir, checkIfExists:true) |
          nextstrain_build
    } else {                // Option 2: Slow module route
      seq_ch = Channel.fromPath(params.sequences, checkIfExists:true)
      met_ch = Channel.fromPath(params.metadata, checkIfExists:true)
      exclude_ch = Channel.fromPath(params.exclude, checkIfExists:true)
      ref_ch = Channel.fromPath(params.reference, checkIfExists:true)
      colors_ch = Channel.fromPath(params.colors, checkIfExists:true)
      lat_longs_ch = Channel.fromPath(params.lat_longs, checkIfExists:true)
      auspice_config_ch = Channel.fromPath(params.auspice_config, checkIfExists:true)
  
      // Run pipeline (chain together processes and add other params on the way)
      seq_ch | index |                                       // INDEX
        combine(met_ch) | combine(exclude_ch) | filter |     // FILTER
        combine(ref_ch ) | align |                           // ALIGN
        tree |                                               // TREE
        combine(align.out) | combine(met_ch) | refine        // REFINE
      tree_ch = refine.out | map{n-> n.get(0)}
      bl_ch = refine.out | map{n-> n.get(1)}
      tree_ch | combine(align.out) | ancestral                // ANCESTRAL
      tree_ch | combine(ancestral.out) | combine(ref_ch) | translate  // TRANSLATE
      tree_ch | combine(met_ch) | traits                       // TRAITS
      tree_ch | combine(met_ch) | combine(bl_ch) | 
        combine(traits.out) | combine(ancestral.out) | combine(translate.out) | combine(colors_ch) | 
        combine(lat_longs_ch) | combine(auspice_config_ch) | export   // EXPORT
    }
  }
}