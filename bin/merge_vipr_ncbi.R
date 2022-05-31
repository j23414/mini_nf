#! /usr/bin/env Rscript

library(tidyverse)
library(magrittr)

# === Inputs
VIPR_FILE="vipr.tsv"
NCBI_FILE="ncbi.csv"

vipr <- readr::read_delim(VIPR_FILE, delim="\t")
ncbi <- readr::read_delim(NCBI_FILE, delim=",")

(names(vipr) = gsub(" ","_", names(vipr)))

# === same column names, could also melt
fncols <- function(data, cname) {
  add <- cname[!cname %in% names(data)]
  if (length(add) != 0) data[add] <- NA
  data
}

# specific renaming
cncbi <- ncbi %>% 
  fncols(., names(vipr)) %>%
  mutate(
    genbank=Accession,
    strain=Isolate %>% gsub(" ", "_", .),
    segment=Segment,
    date=Collection_Date,
    host=Host %>% gsub("Homo sapiens","Human", .),
    country=Country,
    genotype=Genotype,
    species=Species,
    length=Length
  )

format_date <- function(vc, delim="/"){
  if (grepl(delim, vc)) {
    vc_temp <- vc %>%
      stringr::str_split(., delim, simplify = T) %>%
      as.vector(.) 
    if(length(vc_temp)==3){
      vc <- vc_temp %>% 
        { c(.[3], .[1], .[2]) } %>%
        paste(., collapse = "-", sep = "")
    }
    if(length(vc_temp)==2){
      vc <- vc_temp %>% 
        { c(.[2], .[1] ) } %>%
        paste(., collapse = "-", sep = "")
    }

    return(vc)
  }
  return(vc)
}


cvipr <- vipr %>% 
  fncols(., names(ncbi)) %>%
  group_by(GenBank_Accession) %>%
  mutate(
    genbank=GenBank_Accession,
    strain=Strain_Name %>% gsub(" ", "_",.),
    segment="",
    date=Collection_Date %>% gsub("-N/A-", "", .) %>% format_date(., delim="/"),
    host=Host,
    country=Country,
    genotype=Pango_Genome_Lineage %>% gsub("-N/A-","", .),
    species=Virus_Species,
    length=Sequence_Length
  ) %>%
  ungroup(.)

# head(cvipr$date)

# === Functions

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

#cdata <- data %>% select(c("genbank", "strain", "segment", "date", "host", "Isolation_Source", "country","Geo_Location", "genotype", "species", "length", "SRA_Accession","GenBank_Title"))

all = rbind(cvipr, cncbi) %>%
  group_by(genbank) %>%
  summarize(
    strain=strain %>% uniqMerge(.),
    segment=segment %>% uniqMerge(.),
    date=date %>% uniqMerge(.),
    host=host %>% uniqMerge(.),
    Isolation_Source = Isolation_Source %>% uniqMerge(.),
    country = country %>% uniqMerge(.),
    Geo_Location = Geo_Location %>% uniqMerge(.),
    genotype = genotype %>% uniqMerge(.),
    species = species %>% uniqMerge(.),
    length = length %>% uniqMerge(.),
    SRA_Accession = SRA_Accession %>% uniqMerge(.),
    GenBank_Title = GenBank_Title %>% uniqMerge(.),
    check=grepl(",", strain), # flag vague strain names
    LEN=as.numeric(length)
  )

readr::write_delim(all, "vipr_ncbi.tsv", delim="\t")
writexl::write_xlsx(all, "vipr_ncbi.xlsx")
