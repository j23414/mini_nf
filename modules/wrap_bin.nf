#! /usr/bin/env nextflow

nextflow.enable.dsl=2

process batchfetchGB {
    input: path(gb_ids)
    output: path("${gb_ids.simpleName}.gb")
    script:
    """
    #! /usr/bin/env bash
    batchFetchGB.sh ${gb_ids} > ${gb_ids.simpleName}.gb
    """
    stub:
    """
    touch ${gb_ids.simpleName}.gb
    """
}
