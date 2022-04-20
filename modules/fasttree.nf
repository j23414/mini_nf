#! /usr/bin/env nextflow

nextflow.enable.dsl=2

process mafft {
  publishDir "${params.outdir}/01_Alignment"  
  input: path(segment_fasta)
  output: path("*_aln.fna")  
  script:
  """
  #! /usr/bin/env bash
  mafft --auto ${segment_fasta} > ${segment_fasta.simpleName}_aln.fna
  """
  stub:
  """
  #! /usr/bin/env bash
  touch ${segment_fasta.simpleName}_aln.fna
  """
}

process fasttree {
  publishDir "${params.outdir}/02_Trees"
  input: path(aln_fna)
  output: path("*.tre")
  script:
  """
  #! /usr/bin/env bash
  fasttree -nt $aln_fna > ${aln_fna.simpleName}.tre
  """
}

process xz_fasttree {
  publishDir "${params.outdir}/02_Trees"
  input: path(aln_fna)
  output: path("*.tre")
  script:
  """
  #! /usr/bin/env bash
  xzcat ${aln_fna} | fasttree -nt > ${aln_fna.simpleName}.tre
  """
}