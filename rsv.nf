#! /usr/bin/env nextflow

nextflow.enable.dsl=2

/* include nf modules */

include { vipr_fetch_rsv } from './modules/vipr.nf'
include {format_downloaded_genomes; label_rsv_subtypes} from './modules/wrap_bin.nf'
include { parse; index; filter2 as filter; align; tree; refine; ancestral; translate; traits; export_rsv as export } from './modules/augur.nf'
include { mafft } from './modules/fasttree.nf'

/* include config files from repo */
/* dropped_strains.txt is empty */
process fetch_config_files {
  publishDir "${params.outdir}/downloads"
  output: tuple path("dropped_strains.txt"), path("rsv_reference.gb"), path("auspice_config.json"), path("description.md")
  script:
  """
  wget -O master.zip https://github.com/blab/rsv_adaptive_evo/archive/refs/heads/master.zip
  unzip master.zip
  mv rsv_adaptive_evo-master/rsv_step0/config/* .
  """
}

// process small_sample {
//   output: path("small.fasta")
//   script:
//   """
//   # Known A
//   smof grep KY883566 data/all_vipr_download.fasta > small.fasta
//   # Known B
//   smof grep KU950682 data/all_vipr_download.fasta >> small.fasta
//   smof grep LC474554 data/all_vipr_download.fasta >> small.fasta
//   smof filter -l 5000 data/all_vipr_download.fasta >> length.fasta
//   smof head -n 100 length.fasta >> small.fasta
//   """
// }

/* main method */
workflow {
  /*============== Step 0 ==================*/
  config_ch = fetch_config_files() 
  dropped_strains_ch = config_ch | map {n -> n.get(0)}
  reference_ch = config_ch | map {n -> n.get(1)}
  auspice_config_ch = config_ch | map {n -> n.get(2)}
  description_ch = config_ch | map {n -> n.get(3)}

  /* eventually fetch from api, instead of manual process */
  channel.of("vipr_download.fasta")
   | vipr_fetch_rsv
  /* read from param */
  // channel.fromPath("./data/vipr_download.fasta")
   | combine(channel.of("rsv.fasta"))
   | format_downloaded_genomes
   | map { n -> ["rsv", n]}
   | combine(channel.of("strain strain_name segment date host country subtype virus"))
   | parse
   | map { n -> ["rsv", n.get(0), n.get(1) ]}
   | combine(dropped_strains_ch)
   | combine(channel.of(" --group-by country year month --sequences-per-group 100 "))
   | filter
   | combine(reference_ch)
   | combine(channel.of(" --fill-gaps ")) // " --remove-reference "))
   | align
   | combine(channel.of("")) // empty args 
   | tree
   | join(align.out)
   | combine( parse.out | map {n-> n.get(1)} )
   | combine(channel.of(" --timetree --coalescent opt --date-confidence --date-inference marginal --clock-filter-iqd 4 "))
   | refine

  refine_tree_ch = refine.out | map {n -> [n.get(0), n.get(1)]}
  branch_lengths_ch = refine.out | map {n -> [n.get(0), n.get(2)]}

  refine_tree_ch
   | join(align.out)
   | combine(channel.of(" --inference joint "))
   | ancestral

  refine_tree_ch
   | join(ancestral.out)
   | combine(reference_ch)
   | translate

  nodedata_ch = branch_lengths_ch
   | join(ancestral.out)
   | join(translate.out)
   | map{ n -> [n.get(0), [n.get(1), n.get(2), n.get(3)]]}

  refine_tree_ch
   | combine(parse.out | map {n-> n.get(1)})
   | join(nodedata_ch)
   | combine(auspice_config_ch)
   | combine(description_ch)
   | combine(channel.of(" --include-root-sequence "))
   | export /*  nextstrain view results/auspice */

   // label_rsv_subtypes
   export.out
   | map { n -> n.get(1)}
   | combine( format_downloaded_genomes.out )
   | label_rsv_subtypes  // Splits input channels into A and B
   | flatten
   | mafft
   | combine(channel.of("F", "G")) // Split channel into two genes "F", and "G"
   | view

   // extract gene fastas



   /*============== Step 1 ==================*/
   /*============== Step 2 ==================*/
   /*============== Step 3 ==================*/

}