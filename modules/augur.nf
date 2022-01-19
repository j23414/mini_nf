#! /usr/bin/env nextflow

nextflow.enable.dsl=2

process index {
    label 'nextstrain'
    publishDir "${params.outdir}/${build}"
    input: tuple val(build), path(sequences)
    output: tuple val(build), path("$sequences"), path("${sequences.simpleName}_index.tsv")
    script:
    """
    #! /usr/bin/env bash
    ${augur_app} index \
      --sequences ${sequences} \
      --output ${sequences.simpleName}_index.tsv
    """
    stub:
    """
    touch ${sequences.simpleName}_index.tsv
    """
}

// args = "--group-by country year month --sequences-per-group 20 --min-date 2012"
process filter {
    label 'nextstrain'
    publishDir "${params.outdir}/${build}", mode: 'copy'
    input: tuple val(build), path(sequences), path(sequence_index), path(metadata), path(exclude), val(args)
    output: tuple val(build), path("${sequences.simpleName}_filtered.fasta")
    script:
    """
    ${augur_app} filter \
        --sequences ${sequences} \
        --sequence-index ${sequence_index} \
        --metadata ${metadata} \
        --exclude ${exclude} \
        --output ${sequences.simpleName}_filtered.fasta \
        ${args}
    """
    stub:
    """
    touch "${sequences.simpleName}_filtered.fasta"
    """
}

// args = "--fill-gaps"
process align {
    label 'nextstrain'
    publishDir "${params.outdir}/${build}", mode: 'copy'
    input: tuple val(build), path(filtered), path(reference), val(args)
    output: tuple val(build), path("${filtered.simpleName}_aligned.fasta")
    script:
    """
    ${augur_app} align \
        --sequences ${filtered} \
        --reference-sequence ${reference} \
        --output ${filtered.simpleName}_aligned.fasta \
        ${args}
    """
    stub:
    """
    touch ${filtered.simpleName}_aligned.fasta
    """

}

// args=""
process tree {
    label 'nextstrain'
    publishDir "${params.outdir}/${build}", mode: 'copy'
    input: tuple val(build), path(aligned), val(args)
    output: tuple val(build), path("${aligned.simpleName}_raw.nwk")
    script:
    """
    ${augur_app} tree \
        --alignment ${aligned} \
        --output ${aligned.simpleName}_raw.nwk \
        ${args}
    """
    stub:
    """
    touch ${aligned.simpleName}_raw.nwk
    """
}

// args= "--timetree --coalescent opt --date-confidence --date-inference marginal --clock-filter-iqd 4"
process refine {
    label 'nextstrain'
    publishDir "${params.outdir}/$build", mode: 'copy'
    input: tuple val(build), path(tree_raw), path(aligned), path(metadata)
    output: tuple val(build), path("${tree_raw.simpleName.replace('_raw','')}.nwk"), path("${tree_raw.simpleName.replace('_raw','')}_branch_lengths.json")
    script:
    """
    ${augur_app} refine \
        --tree ${tree_raw} \
        --alignment ${aligned} \
        --metadata ${metadata} \
        --output-tree ${tree_raw.simpleName.replace('_raw','')}.nwk \
        --output-node-data ${tree_raw.simpleName.replace('_raw','')}_branch_lengths.json \
        ${args}
    """
    stub:
    """
    touch ${tree_raw.simpleName.replace('_raw','')}.nwk ${tree_raw.simpleName.replace('_raw','')}_branch_lengths.json
    """
}

// args="--inference joint"
process ancestral {
    label 'nextstrain'
    publishDir "${params.outdir}/${build}", mode: 'copy'
    input: tuple val(build), path(tree), path(aligned)
    output: tuple val(build), path("${tree.simpleName}_nt_muts.json")
    script:
    """
    ${augur_app} ancestral \
        --tree ${tree} \
        --alignment ${aligned} \
        --output-node-data ${tree.simpleName}_nt_muts.json \
        ${args}
    """
    stub:
    """
    touch ${tree.simpleName}_nt_muts.json
    """
}

process translate {
    label 'nextstrain'
    publishDir "${params.outdir}/${build}", mode: 'copy'
    input: tuple val(build), path(tree), path(nt_muts), path(reference)
    output: tuple val(build), path("${tree.simpleName}_aa_muts.json")
    script:
    """
    ${augur_app} translate \
        --tree ${tree} \
        --ancestral-sequences ${nt_muts} \
        --reference-sequence ${reference} \
        --output-node-data ${tree.simpleName}_aa_muts.json
    """
    stub:
    """
    touch ${tree.simpleName}_aa_muts.json
    """

}

// args = "--columns region country --confidence"
process traits {
    label 'nextstrain'
    publishDir "${params.outdir}/${build}", mode: 'copy'
    input: tuple val(build), path(tree), path(metadata), val(args)
    output: tuple val(build), path("${tree.simpleName}_traits.json")
    script:
    """
    ${augur_app} traits \
        --tree ${tree} \
        --metadata ${metadata} \
        --output ${tree.simpleName}_traits.json \
        ${args}
    """
    stub:
    """
    touch ${tree.simpleName}_traits.json
    """
}

// To make this general purpose, just take a collection of json files, don't split it out
process export {
    label 'nextstrain'
    publishDir("$params.outdir/${build}"), mode: 'copy'
    input: tuple val(build), path(tree), path(metadata), \
      path(node_data), \
      path(colors), \
      path(lat_longs), \
      path(auspice_config)
    output: tuple val(build), path("auspice/${tree.simpleName}.json")
    script:
    """
    ${augur_app} export v2 \
        --tree ${tree} \
        --metadata ${metadata} \
        --node-data ${node_data} \
        --colors ${colors} \
        --lat-longs ${lat_longs} \
        --auspice-config ${auspice_config} \
        --output auspice/${tree.simpleName}.json
    """
    stub:
    """
    mkdir auspice
    touch auspice/${tree.simpleName}.json
    """
}

// TODO: other Augur commands
// process parse { }
// process mask { }
// process reconstruct-sequences { }
// process clade { }
// process sequence-traits { }
// process lbi { }
// process distance { }
// process titers { }
// process frequences { }
// process validate { }
// process import { }
// process sanitize {} ? :)