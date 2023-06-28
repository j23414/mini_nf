#! /usr/bin/env nextflow
nextflow.enable.dsl=2

include {AUGUR_DEFAULTS} from "./modules/augur.nf"
include {deploy as nextstrain_deploy} from "./modules/nextstrain.nf"

workflow {
      sequences_ch = Channel.fromPath(params.sequences, checkIfExists:true)
      metadata_ch = Channel.fromPath(params.metadata, checkIfExists:true)
      exclude_ch = Channel.fromPath(params.exclude, checkIfExists:true)
      ref_ch = Channel.fromPath(params.reference, checkIfExists:true)
      colors_ch = Channel.fromPath(params.colors, checkIfExists:true)
      lat_longs_ch = Channel.fromPath(params.lat_longs, checkIfExists:true)
      auspice_config_ch = Channel.fromPath(params.auspice_config, checkIfExists:true)
      build_ch = channel.of("default-build")

      s3url_ch = Channel.from(params.s3url)

      auguroutput_ch = AUGUR_DEFAULTS (
        build_ch, 
        sequences_ch, 
        metadata_ch, 
        exclude_ch, 
        ref_ch, 
        colors_ch, 
        lat_longs_ch, 
        auspice_config_ch
      )

      auguroutput_ch 
      | map { n -> n.get(1) } // get "auspice" folder
      | combine(s3url_ch)
      | nextstrain_deploy

}
