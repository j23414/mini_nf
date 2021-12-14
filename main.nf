#! /usr/bin/env nextflow
// import org.yaml.snakeyaml.Yaml

nextflow.enable.dsl=2

// Wrap everything in nextflow
include { run_nextstrain } from './modules/nextstrain.nf'

// Wrap individual modules in Nextflow
include { index; filter; align; tree; refine; ancestral; translate; traits; export } from './modules/augur.nf'
include { nextclade_sars_cov_2 as nextclade } from './modules/nextclade.nf'
include { nextalign } from './modules/nextalign.nf'
include { batchfetchGB as pull_genbanks ; gb_to_fna as convert_to_fasta} from './modules/wrap_bin.nf'

workflow {
/* TODO: read native snakemake yaml
  if (params.yaml) {
    parameter_yaml = new FileInputStream(new File(params.yaml))
    new Yaml().load(parameter_yaml).each { k, v -> params[k] = v }
    params[sequences] = params.input.sequences ? "${params.input.sequences}" : "${params.sequence}"
  }
*/

  // Define input channels (could auto detect if input is gisaid auspice json file)
  gb_ch = Channel.fromPath(params.genbank_ids, checkIfExists:true)
  seq_ch = gb_ch | pull_genbanks | convert_to_fasta
//   seq_ch = Channel.fromPath(params.sequences, checkIfExists:true)
//   met_ch = Channel.fromPath(params.metadata, checkIfExists:true)
//   exclude_ch = Channel.fromPath(params.exclude, checkIfExists:true)
//   ref_ch = Channel.fromPath(params.reference, checkIfExists:true)
//   colors_ch = Channel.fromPath(params.colors, checkIfExists:true)
//   lat_longs_ch = Channel.fromPath(params.lat_longs, checkIfExists:true)
//   auspice_config_ch = Channel.fromPath(params.auspice_config, checkIfExists:true)
// 
// 
  // == main
  // TODO: sub args passed as json/dict
  // TODO: allow skipping of steps (snakemake skips via named input)

  // ======== Data Fetch (aws/rest/eutils) =======================


  // =========== Nextalign (works but probably should use nextclade)
  // gff_ch = Channel.fromPath(params.gff, checkIfExists:true)
  // ref_fa_ch = Channel.fromPath(params.ref_fa, checkIfExists:true)
  // seq_ch | combine(ref_fa_ch) | combine(gff_ch) | nextalign 

//  /* ========= Nextclade (works) ======= */
  clades_ch  = seq_ch | nextclade
//
//  /* ========= Nextstrain (modules work) ======== */
//  if (params.wrap) {  // Fast wrapped route
//    seq_ch | run_nextstrain
//  } else {           // Slow module route
//    // Run pipeline (chain together processes and add other params on the way)
//    seq_ch | index |                                       // INDEX
//      combine(met_ch) | combine(exclude_ch) | filter |     // FILTER
//      combine(ref_ch ) | align |                           // ALIGN
//      tree |                                               // TREE
//      combine(align.out) | combine(met_ch) | refine        // REFINE
//    tree_ch = refine.out | map{n-> n.get(0)}
//    bl_ch = refine.out | map{n-> n.get(1)}
//    tree_ch | combine(align.out) | ancestral                // ANCESTRAL
//    tree_ch | combine(ancestral.out) | combine(ref_ch) | translate  // TRANSLATE
//    tree_ch | combine(met_ch) | traits                       // TRAITS
//    tree_ch | combine(met_ch) | combine(bl_ch) | 
//      combine(traits.out) | combine(ancestral.out) | combine(translate.out) | combine(colors_ch) | 
//      combine(lat_longs_ch) | combine(auspice_config_ch) | export   // EXPORT
//  }
}