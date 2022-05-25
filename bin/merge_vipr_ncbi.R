#! /usr/bin/env Rscript

library(tidyverse)
library(magrittr)

data<-readr::read_delim("vipr_metadata.tsv", delim="\t")

# cdata <- data %>%
#   mutate(
#     date = case_when(str_length(date) < 5 ~ paste(date,"-XX-XX", sep=""),
#                      str_length(date) < 8 ~ paste(date,"-XX", sep=""),
#                    1==1~ date),
#     genotype = case_when(str_length(genotype)>0 ~ genotype,
#                          grepl("RSVA", strain) ~ "A",
#                          grepl("RSVB", strain) ~ "B",
#                          grepl("RSV_A", strain) ~ "A",
#                          grepl("RSV_B", strain) ~ "B",
#                          grepl("/A$", strain) ~ "A",
#                          grepl("/B$", strain) ~ "B")
#   )
# readr::write_delim(cdata, "temp.txt", delim="\t")
# names(cdata)

ncbi <- readr::read_delim("ncbi.csv", delim=",")

cncbi <- ncbi %>%
  mutate(
    genbank=Accession,
    strain=Isolate,
    segment=Segment,
    date=Collection_Date,
    host=Host,
    country=Country,
    genotype=Genotype,
    species=Species,
    length=Length
  ) %>%
  select(c("genbank", "strain", "segment", "date", "host", "Isolation_Source", "country","Geo_Location", "genotype", "species", "length", "SRA_Accession","GenBank_Title"))


data$Isolation_Source=""
data$Geo_Location=""
data$SRA_Accession=""
data$GenBank_Title=""

cdata <- data %>% select(c("genbank", "strain", "segment", "date", "host", "Isolation_Source", "country","Geo_Location", "genotype", "species", "length", "SRA_Accession","GenBank_Title"))

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

all = rbind(cdata, cncbi) %>%
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
    check=grepl(",", strain) # flag vague strain names
  )

readr::write_delim(all, vipr_ncbi.tsv, delim="\t")
writexl::write_xlsx(all, "vipr_ncbi.xlsx")
