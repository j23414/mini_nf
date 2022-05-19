#! /usr/bin/env Rscript

library(tidyverse)
library(magrittr)
library(writexl)

data <- readr::read_delim(
  "temp.txt", 
  delim="\t", 
  col_names = c("genbank", "strain", "segment", "date", "host", "country", "genotype", "species","length"))

uniqMerge <- function(vc) {
  vc <- vc %>%
    na.omit(.) %>%
    unique(.) %>%
    paste(., collapse = ";", sep = "")
  if (grepl(",", vc)) {
    vc <- vc %>%
      stringr::str_split(., ";", simplify = T) %>%
      as.vector(.) %>%
      unique(.) %>%
      paste(., collapse = ";", sep = "")
  }
  return(vc)
}

cdata <- data %>%
  select(c("genbank", "strain", "date", "host", "country", "genotype", "species", "length")) %>%
  mutate(
    date=gsub("_","-",date),
    date=case_when(str_length(date)<5 ~ paste(date, "-XX-XX", sep=""),
                   str_length(date)<8 ~ paste(date, "-XX", sep=""),
                   1==1 ~ date),
    genotype=case_when(str_length(genotype)>0 ~ genotype,
                       grepl("RSVA", strain) ~ "A",
                       grepl("RSVB", strain) ~ "B",
                       grepl("RSV_A", strain) ~ "A",
                       grepl("RSV_B", strain) ~ "B",
                       grepl("/A$", strain) ~ "A",
                       grepl("/B$", strain) ~ "B")
  )%>%
  group_by(strain) %>%
  mutate(
    date = date %>% uniqMerge(.),
    genbank = genbank %>% uniqMerge(.),
    host=host %>% uniqMerge(.),
    country=country %>% uniqMerge(.),
    genotype=genotype %>% uniqMerge(.),
    species=species %>% uniqMerge(.),
    length=length %>% uniqMerge(.)
  )%>%
  select(c("date", "genbank", "strain", "host", "country", "genotype", "species", "length"))

readr::write_delim(cdata, "metadata.tsv", delim="\t")

writexl::write_xlsx(cdata, "rsv.xlsx")


