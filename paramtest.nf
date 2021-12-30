#! /usr/bin/env nextflow
nextflow.enable.dsl=2

include { build_params} from './modules/wrap_bin.nf'

workflow {
  old_ch=channel.of("--hello world --one two three four")
  new_ch=channel.of("--three again see --hello globe")

  old_ch | combine(new_ch)| build_params | view
}