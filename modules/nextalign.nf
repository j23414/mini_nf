#! /usr/bin/env nextflow
/* You probably want to use nextclade */

nextflow.enable.dsl=2

//process nextalign {
//  publishDir "${params.outdir}/01_nextalign", mode: 'copy'
//  input: tuple path(sequences), path(reference), path(gff)
//  output: path("nextalign")
//  script:
//  """
//  #! /usr/bin/env bash
//  # Pull gene names from gff file
//  GENES=`cat ${gff} | awk -F'gene_name=' '{print \$2}' |grep -v "^\$"|tr '\n' ','|sed 's/,\$//g'`
//  ${nextalign_app} \
//    --sequences=${sequences} \
//    --reference=${reference} \
//    --genemap=${gff} \
//    --genes=\${GENES} \
//    --output-dir=nextalign/ \
//    --output-basename=${sequences.simpleName}
//  """
//  stub:
//  """
//  mkdir nextalign
//  touch nextalign/${sequences.simpleName}_aln.fasta
//  """
//}

process nextalign {
  publishDir "${params.outdir}/${build}", mode: 'copy'
  input: tuple val(build), path(sequences), path(reference), path(gff), val(output_basename)
  output: tuple val(build), path("nextclade/${output_basename}.aligned.fasta"), path("nextclade/${output_basename}.gene.*.fasta")
  script:
  """
  #! /usr/bin/env bash
  # Pull gene names from gff file
  GENES=`cat ${gff} | awk -F'gene_name=' '{print \$2}' |grep -v "^\$"|tr '\n' ','|sed 's/,\$//g'`
  ${nextalign_app} \
    --sequences=${sequences} \
    --reference=${reference} \
    --genemap=${gff} \
    --genes=\${GENES} \
    --output-dir nextclade \
    --output-basename ${output_basename}
  """
  stub:
  """
  mkdir nextalign
  touch nextalign/${sequences.simpleName}_aln.fasta
  """
}

process nextalign_run {
  publishDir "${params.outdir}/${build}", mode: 'copy'
  input: tuple val(build), path(sequences), path(reference), val(args)
  output: tuple val(build), path("aligned.fasta")
  script:
  """
  #! /usr/bin/env bash
  # Pull gene names from gff file
  ${nextalign_app} run \
    --sequences ${sequences} \
    --reference ${reference} \
    --output-fasta aligned.fasta \
    ${args}
  """
}


workflow nextalign_example_pipe {
  take:
    seq_ch
    ref_fa_ch
    gff_ch
  main:
    seq_ch | combine(ref_fa_ch) | combine(gff_ch) | nextalign 
  emit:
    nextalign.out
}