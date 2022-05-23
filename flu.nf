#! /usr/bin/env nextflow

nextflow.enable.dsl=2

workflow {
  lineage=["H1N1","H3N2","H3N1"]
  segments=['HA','NA','PB2','PB1','PA','NP','M','NS']
  time=['2yr','3mo','6mo']

  channel.of(lineage)
   | flatten
   | combine(channel.of(segments)| flatten)
   | combine(channel.of(time)| flatten)
   | view
}

// N E X T F L O W  ~  version 21.10.6
// Launching `flu.nf` [cranky_brattain] - revision: ed7605c29b
// [H1N1, HA, 2yr]
// [H1N1, HA, 3mo]
// [H1N1, HA, 6mo]
// [H1N1, NA, 2yr]
// [H1N1, NA, 3mo]
// [H1N1, NA, 6mo]
// [H1N1, PB2, 2yr]
// [H1N1, PB2, 3mo]
// [H1N1, PB2, 6mo]
// ...