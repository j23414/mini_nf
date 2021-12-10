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

process sanitize_metadata {
    input: path(metadata)
    output: tuple path("${metadata.simpleName}_sanitized.tsv.xz"), path()
    script:
    """
    sanitize_metadata.py \
      --metadata ${metadata} \
      --output ${metadata.simpleName}_sanitized.tsv.xz
    """
    stub:
    """
    cp ${metadata} ${metadata.simpleName}_sanitized.tsv.xz
    """
}

process sanitize_sequences {
    input: path(sequences)
    output: tuple path("${sequences.simpleName}_sanitized.fa.xz"), path()
    script:
    """
    sanitize_metadata.py \
      --metadata ${metadata} \
      --output ${metadata.simpleName}_sanitized.tsv.xz
    """
    stub:
    """
    cp ${sequences} ${sequences.simpleName}_sanitized.fa.xz
    """
}
