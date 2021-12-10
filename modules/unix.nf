#! /usr/bin/env nextflow

nextflow.enable.dsl=2

// Merge sequences, the merge metadata is a bit different
// process cat {
//     input: tuple val(output_file), path(input_files) // Pass in multiple files as tuple
//     output: path("${output_file}")
//     script:
//     """
//     cat ${input_files} > ${output_file}
//     """
// }