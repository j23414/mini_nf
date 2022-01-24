#! /usr/bin/env nextflow
// SMOT = simple manipulation of trees 
// https://github.com/flu-crew/smot

nextflow.enable.dsl=2

process sample {
  input: path(tree)
  output: path("${tree.simpleName}-para-sample.tre")
  script:
  """
  smot sample para ${tree} \
    --scale=4 \
    --factor-by-capture="(focalstrain|reference)" \
    --min-tips=3 \
    --keep="focalstrain" \
    --seed=42 > ${tree.simpleName}-para-sample.tre
  """
}