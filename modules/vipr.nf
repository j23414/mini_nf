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

/* todo: generalize this */
process vipr_fetch_zika {
  publishDir "${params.outdir}/downloads", mode: 'copy'
  input: val(filename)
  output: path("${filename}")
  script:
  """
  #! /usr/bin/env bash
  # todo: split out rest query into params
  curl "https://www.viprbrc.org/brc/api/sequence?datatype=genome&family=flavi&species=Zika%20virus&fromyear=2013&minlength=5000&metadata=genbank,strainname,segment,date,host,country,genotype,species&output=fasta" \
   | tr '-' '_' \
   | tr ' ' '_' \
   | sed 's:N/A:NA:g' \
   > ${filename}
  """
}

process vipr_fetch_rsv {
  publishDir "${params.outdir}/downloads", mode: 'copy'
  input: val(filename)
  output: path("${filename}")
  script:
  """
  #! /usr/bin/env bash

  # === Split out into parameters for generalizability
  # todo: move these to process inputs
  FAMILY=pneumoviridae
  VIRUS="Respiratory%20syncytial%20virus"
  #MINLEN=5000 #<= maybe
  METADATA="genbank,strainname,segment,date,host,country,genotype,species"
  
  #URL="https://www.viprbrc.org/brc/api/sequence?datatype=genome&family=\${FAMILY}&\${VIRUS}&minlength=\${MINLEN}&metadata=\${METADATA}&output=fasta"
  URL="https://www.viprbrc.org/brc/api/sequence?datatype=genome&family=\${FAMILY}&\${VIRUS}&metadata=\${METADATA}&output=fasta"
  echo \${URL}
  curl \${URL} \
      | tr '-' '_' \
      | tr ' ' '_' \
      | sed 's:N/A:NA:g' \
      > ${filename}
  """
}

