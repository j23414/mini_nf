#! /usr/bin/env nextflow

nextflow.enable.dsl=2

process batchfetchGB {
    publishDir "${params.outdir}/00_PrepData", mode: 'copy'
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

process gb_to_fna {
    publishDir "${params.outdir}/00_PrepData", mode: 'copy'
    input: path(gb)
    output: path("${gb.simpleName}.fna")
    script:
    """
    #! /usr/bin/env bash
    procGenbank.pl ${gb} > ${gb.simpleName}.fna
    """
    stub:
    """
    touch ${gb.simpleName}.fna
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

process build_params {
  executor 'local'
  input: tuple val(param_str), val(newparam_str)
  output: stdout()
  script:
  """
  #! /usr/bin/env bash
  arg_json.py ${param_str}
  mv tmp_params.json old.json
  arg_json.py ${newparam_str}
  mv tmp_params.json new.json
  json_paramstr.py old.json new.json
  """
}
