#! /usr/bin/env nextflow
nextflow.enable.dsl=2

include {vipr_fetch} from "./modules/vipr.nf"
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

process fetch_fixes {
  output: tuple path("zika_strain_name_fix.tsv"), path("zika_date_fix.tsv"), path("zika_location_fix.tsv")
  shell:
  """
  #! /usr/bin/env bash
  #! /usr/bin/env bash
  wget -O master.zip https://github.com/nextstrain/fauna/archive/refs/heads/master.zip
  unzip master.zip
  mv fauna-master/source-data/zika* .
  """
}

process get_metadata {
  input: tuple path(fasta), val(filename)
  output: path("$filename")
  script: 
  """
  #! /usr/bin/env bash 
  echo "genbank,strain,date,host,country,genotype,species,len" \
    | tr ',' '\t' \
    > ${filename}
  smof stat -lq ${fasta} \
    | tr '|' '\t' \
    >> ${filename}
  """ 
}

process merge_metadata {
  input: tuple path(metadata_tsv), val(filename)
  output: tuple path("$filename"), path("${filename}.xlsx")
  script:
  """
  #! /usr/bin/env Rscript
  library(tidyverse)
  library(magrittr)

  data <- readr::read_delim("${metadata_tsv}", delim="\t")

  uniqMerge <- function(vc, delim = ",") {
    vc <- vc %>%
    na.omit(.) %>%
    unique(.) %>%
    paste(., collapse = delim, sep = "")
    if (grepl(delim, vc)) {
      vc <- vc %>%
        stringr::str_split(., delim, simplify = T) %>%
        as.vector(.) %>%
        unique(.) %>%
        paste(., collapse = delim, sep = "")
    }
    return(vc)
  }

  fixStrainNames <- function(name){
    new_name = gsub("Homo_Sapiens","Homo_sapiens", name) %>%
      #gsub("ZIKA/","", .) %>% 
      gsub("^PRVABC_59\$", "ZIKV/Homo_sapiens/PRI/PRVABC59/2015", .) %>%
      gsub("^PRVABC59\$", "ZIKV/Homo_sapiens/PRI/PRVABC59/2015", .) %>% 
      gsub("Zika_virus/H.sapiens-tc/Puerto_Rico/2015/PRVABC59", "ZIKV/Homo_sapiens/PRI/PRVABC59/2015", .)
    return(new_name)
  }


  cdata <- data %>%
    dplyr::mutate(
      strain = strain %>% fixStrainNames(.)
    ) %>%
    dplyr::group_by(strain) %>%
    dplyr::summarize(
      date = date %>% uniqMerge(.), 
      genbank = genbank %>% uniqMerge(.),
      host = host %>% uniqMerge(.),
      country = country %>% uniqMerge(.),
      genotype = genotype %>% uniqMerge(.),
      species = species %>% uniqMerge(.),
      len = len %>% uniqMerge(.),
      check = grepl(",", genbank)
    ) %>% 
    dplyr::select(c("date", "genbank", "strain","genotype", "host", "country", "len", "species","check"))

  readr::write_delim(cdata, "$filename", delim="\t")
  writexl::write_xlsx(cdata, "${filename}.xlsx")
  """
}

workflow {

  fixzika_ch=fetch_fixes ()
  fixzika_ch | view
  
  //ZIKA_EXAMPLE_PIPE() 
  channel.of("family=flavi&species=Zika%20virus&fromyear=2013&minlength=5000")           // vipr query
    | combine(channel.of("genbank,strainname,date,host,country,genotype,species")) // vipr metadata
    | combine(channel.of("vipr_zika.fasta"))
    | vipr_fetch
    | combine(channel.of("vipr_zika_metadata.tsv"))
    | get_metadata
    | combine(channel.of("zika_metadata.tsv"))
    | merge_metadata
//    | view

// (nextstrain) local % nextflow run ../mini_nf/zika.nf --outdir zika_results -resume
// N E X T F L O W  ~  version 21.10.6
// Launching `../mini_nf/zika.nf` [dreamy_mendel] - revision: bd62170581
// executor >  local (1)
// executor >  local (1)
// [ee/3ef744] process > vipr_fetch (1)     [100%] 1 of 1, cached: 1 ✔
// [23/ae87a0] process > get_metadata (1)   [100%] 1 of 1, cached: 1 ✔
// [ca/0b201e] process > merge_metadata (1) [100%] 1 of 1 ✔
// [/Users/jenchang/github/j23414/local/work/ca/0b201e484e3d2edd97d8f455bd931f/zika_metadata.tsv, /Users/jenchang/github/j23414/local/work/ca/0b201e484e3d2edd97d8f455bd931f/zika_metadata.tsv.xlsx]

// === Potentially problematic strains, or at least multiple genbanks
// 15098
// Natal_RGN
// PE243                 # <= conflicting dates (2015-05-13, 2017-06-29)
// PF13/251013-18
// PRVABC59
// S-542/Yucatan/2017
// SZ-WIV01
// ZIKV/Homo_sapiens/PAN/CDC-259249_V1-V3/2015
// ZJ03
}