#! /usr/bin/env nextflow

nextflow.enable.dsl=2

// query = "family=flavi&species=Zika%20virus&fromyear=2013&minlength=5000"
// metadata = "genbank,strainname,segment,date,host,country,genotype,species"
process vipr_fetch {
  publishDir "${params.outdir}/downloads", mode: 'copy'
  input: tuple val(query), val(metadata), val(filename)
  output: path("${filename}")
  script:
  """
  #! /usr/bin/env bash
  URL="https://www.viprbrc.org/brc/api/sequence?datatype=genome&${query}&metadata=${metadata}&output=fasta"
  echo \$URL
  curl \$URL \
   | tr ' ' '_' \
   | sed 's:N/A:NA:g' \
   > ${filename}
  """
}
