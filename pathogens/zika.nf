#! /usr/bin/env nextflow
// USAGE: nextflow run zika.nf -resume
nextflow.enable.dsl=2

//include { vipr_fetch } from "../modules/vipr.nf"
include { download; decompress } from "../modules/prepare.nf"
include { index; filter; align; tree; refine; ancestral; translate; traits } from '../modules/augur.nf'

// === Option 1: Wrap whole build in one process
process build_zika {
  publishDir "${params.outdir}", mode: 'copy'
  output: tuple path("zika-main/results"), path("zika-main/auspice"), path("zika-main/*.logs")
  script:
  """
  wget -O main.zip https://github.com/nextstrain/zika/archive/refs/heads/main.zip
  unzip main.zip
  cd zika-main
  nextstrain build .
  """
}

// === Option 2: Modularize into multiple processes
process get_zika_configs {
  publishDir "${params.outdir}/configs", mode: 'copy'
  output: tuple val("zika"), path("auspice_config.json"), path("colors.tsv"), path("description.md"), \
    path("dropped_strains.txt"), path("zika_reference.gb")
  script:
  """
  #! /usr/bin/env bash
  wget -O main.zip https://github.com/nextstrain/zika/archive/refs/heads/main.zip
  unzip main.zip
  mv zika-main/config/* .
  """
}

process count_records {
  input: tuple path(sequences_fasta_xz), path(metadata_tsv_gz)
  output: stdout()
  script:
  """
  echo "Sequence records:" `xz --decompress --stdout ${sequences_fasta_xz} | grep -c ">" `
  echo "Metadata lines:" `gzip --decompress --stdout ${metadata_tsv_gz}  | wc -l`
  """ 
}

process export {
  input: tuple val(build_name), path(tree), path(metadata), path(node_data_files), path(colors), path(auspice_config), path(description), val(args)
  output: tuple val("$build_name"), path("auspice")
  script:
  """
  augur export v2 \
  --tree ${tree} \
  --metadata ${metadata} \
  --node-data ${node_data_files} \
  --colors ${colors} \
  --auspice-config ${auspice_config} \
  --description ${description} \
  --output auspice/zika.json \
  ${args}

  """
}

workflow {
  //build_zika() | view

  channel.of(["https://data.nextstrain.org/files/zika/sequences.fasta.xz", "https://data.nextstrain.org/files/zika/metadata.tsv.gz"])
  | download
  | decompress

  download.out 
  | count_records
  | view

  sequences_ch = decompress.out | map {n -> n.get(0)}
  metadata_ch = decompress.out | map {n -> n.get(1)}

  get_zika_configs()
  build_ch = get_zika_configs.out | map {n -> n.get(0)}
  auspice_config_ch = get_zika_configs.out | map {n -> n.get(1)}
  colors_ch = get_zika_configs.out | map {n -> n.get(2)}
  description_ch = get_zika_configs.out | map {n -> n.get(3)}
  exclude_ch = get_zika_configs.out | map {n -> n.get(4)}
  reference_ch = get_zika_configs.out | map {n -> n.get(5)}

  build_ch
  | combine(sequences_ch)
  | combine(metadata_ch)
  | combine(exclude_ch)
  | combine(channel.of(" --group-by country year month --sequences-per-group 40 --min-date 2012 --min-length 5385 "))
  | filter
  | combine(reference_ch)
  | combine(channel.of(" --fill-gaps --remove-reference "))
  | align
  | combine(channel.of(""))
  | tree
  | combine(align.out | map { n -> n.get(1) })
  | combine(metadata_ch)
  | combine(channel.of(" --timetree --coalescent opt --date-confidence --date-inference marginal --clock-filter-iqd 4 "))
  | refine
  | view

  tree_ch = refine.out 
  | map { n -> [n.get(0), n.get(1)] }
    
  branch_length_ch = refine.out 
  | map{ n -> [n.get(0), n.get(2)] }

  tree_ch
  | combine(align.out | map {n -> n.get(1)})
  | combine(channel.of("--inference joint"))
  | ancestral

  tree_ch
  | combine(ancestral.out | map {n -> n.get(1)})
  | combine(reference_ch)
  | translate

  tree_ch
  | combine(metadata_ch)
  | combine(channel.of(" --columns region country --sampling-bias-correction 3 "))
  | traits

  node_data_ch = branch_length_ch
  | join(traits.out)
  | join(ancestral.out)
  | join(translate.out)
  | map {n -> [n.drop(1)]}
  | view

  tree_ch
  | combine(metadata_ch)
  | combine(node_data_ch)
  | combine(colors_ch)
  | combine(auspice_config_ch)
  | combine(description_ch)
  | combine(channel.of(" --include-root-sequence "))
  | view
  | export


}

// ===================== SCRAP AFTER THIS
// workflow {
//  fixzika_ch=fetch_fixes ()
//  fixzika_ch | view
//  
//  //ZIKA_EXAMPLE_PIPE() 
//  channel.of("family=flavi&species=Zika%20virus&fromyear=2013&minlength=5000")           // vipr query
//    | combine(channel.of("genbank,strainname,date,host,country,genotype,species")) // vipr metadata
//    | combine(channel.of("vipr_zika.fasta"))
//    | vipr_fetch
//    | combine(channel.of("vipr_zika_metadata.tsv"))
//    | get_metadata
//    | combine(channel.of("zika_metadata.tsv"))
//    | merge_metadata
//    | view
// }
//workflow ZIKA_EXAMPLE_PIPE {
//  main:
//    // Pull nextstrain/zika-tutorial repo and files
//    pull_zika | mk_zika_channels
//
//    // Connect channels
//    build_ch = mk_zika_channels.out | map {n -> n.get(0)}
//    sequences_ch = mk_zika_channels.out | map {n -> n.get(1)}
//    metadata_ch = mk_zika_channels.out | map {n -> n.get(2)}
//    exclude_ch = mk_zika_channels.out | map {n -> n.get(3)}
//    ref_ch = mk_zika_channels.out | map {n -> n.get(4)}
//    colors_ch = mk_zika_channels.out | map {n -> n.get(5)}
//    lat_longs_ch = mk_zika_channels.out | map {n -> n.get(6)}
//    auspice_config_ch = mk_zika_channels.out | map {n -> n.get(7)}
//
//    build_ch
//    | combine(sequences_ch)
//    | index
//    | combine(metadata_ch)
//    | combine(exclude_ch)
//    | combine(channel.of("--group-by country year month --sequences-per-group 20 --min-date 2012"))
//    | filter
//    | combine(ref_ch)
//    | combine(channel.of("--fill-gaps"))
//    | align
//    | combine(channel.of(""))
//    | tree
//    | join(align.out)
//    | combine(metadata_ch)
//    | combine(channel.of("--timetree --coalescent opt --date-confidence --date-inference marginal --clock-filter-iqd 4"))
//    | refine
//
//    tree_ch = refine.out 
//      | map { n-> [n.get(0), n.get(1)] }
//    
//    branch_length_ch = refine.out 
//      | map{ n-> [n.get(0), n.get(2)] }
//    
//    tree_ch
//      | join(align.out) 
//      | combine(channel.of("--inference joint"))
//      | ancestral
//    
//    tree_ch 
//      | join(ancestral.out) 
//      | combine(ref_ch) 
//      | translate
//    
//    tree_ch
//      | combine(metadata_ch) 
//      | combine(channel.of("--columns region country --confidence"))
//      | traits
//  
//    node_data_ch = branch_length_ch
//      | join(traits.out)
//      | join(ancestral.out)
//      | join(translate.out)
//      | map {n -> [n.drop(1)]}
//    
//    tree_ch
//      | combine(metadata_ch)
//      | combine(node_data_ch)
//      | combine(colors_ch) 
//      | combine(lat_longs_ch) 
//      | combine(auspice_config_ch)
//      | export
//
//  emit:
//    export.out
//}
//
//process fetch_fixes {
//  output: tuple path("zika_strain_name_fix.tsv"), path("zika_date_fix.tsv"), path("zika_location_fix.tsv")
//  shell:
//  """
//  #! /usr/bin/env bash
//  #! /usr/bin/env bash
//  wget -O master.zip https://github.com/nextstrain/fauna/archive/refs/heads/master.zip
//  unzip master.zip
//  mv fauna-master/source-data/zika* .
//  """
//}
//
//process get_metadata {
//  input: tuple path(fasta), val(filename)
//  output: path("$filename")
//  script: 
//  """
//  #! /usr/bin/env bash 
//  echo "genbank,strain,date,host,country,genotype,species,len" \
//    | tr ',' '\t' \
//    > ${filename}
//  smof stat -lq ${fasta} \
//    | tr '|' '\t' \
//    >> ${filename}
//  """ 
//}
//
//process merge_metadata {
//  input: tuple path(metadata_tsv), val(filename)
//  output: tuple path("$filename"), path("${filename}.xlsx")
//  script:
//  """
//  #! /usr/bin/env Rscript
//  library(tidyverse)
//  library(magrittr)
//
//  data <- readr::read_delim("${metadata_tsv}", delim="\t")
//
//  uniqMerge <- function(vc, delim = ",") {
//    vc <- vc %>%
//    na.omit(.) %>%
//    unique(.) %>%
//    paste(., collapse = delim, sep = "")
//    if (grepl(delim, vc)) {
//      vc <- vc %>%
//        stringr::str_split(., delim, simplify = T) %>%
//        as.vector(.) %>%
//        unique(.) %>%
//        paste(., collapse = delim, sep = "")
//    }
//    return(vc)
//  }
//
//  fixStrainNames <- function(name){
//    new_name = gsub("Homo_Sapiens","Homo_sapiens", name) %>%
//      #gsub("ZIKA/","", .) %>% 
//      gsub("^PRVABC_59\$", "ZIKV/Homo_sapiens/PRI/PRVABC59/2015", .) %>%
//      gsub("^PRVABC59\$", "ZIKV/Homo_sapiens/PRI/PRVABC59/2015", .) %>% 
//      gsub("Zika_virus/H.sapiens-tc/Puerto_Rico/2015/PRVABC59", "ZIKV/Homo_sapiens/PRI/PRVABC59/2015", .)
//    return(new_name)
//  }
//
//
//  cdata <- data %>%
//    dplyr::mutate(
//      strain = strain %>% fixStrainNames(.)
//    ) %>%
//    dplyr::group_by(strain) %>%
//    dplyr::summarize(
//      date = date %>% uniqMerge(.), 
//      genbank = genbank %>% uniqMerge(.),
//      host = host %>% uniqMerge(.),
//      country = country %>% uniqMerge(.),
//      genotype = genotype %>% uniqMerge(.),
//      species = species %>% uniqMerge(.),
//      len = len %>% uniqMerge(.),
//      check = grepl(",", genbank)
//    ) %>% 
//    dplyr::select(c("date", "genbank", "strain","genotype", "host", "country", "len", "species","check"))
//
//  readr::write_delim(cdata, "$filename", delim="\t")
//  writexl::write_xlsx(cdata, "${filename}.xlsx")
//  """
//}