#! /usr/bin/env nextflow

nextflow.enable.dsl=2

process index {
    label 'nextstrain'
    input: path(sequences)
    output: tuple path("$sequences"), path("${sequences.simpleName}_index.tsv")
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

// TODO: split into filter with and without index files
process filter {
    label 'nextstrain'
    input: tuple path(sequences), path(sequence_index), path(metadata), path(exclude)
    output: path("${sequences.simpleName}_filtered.fasta")
    script:
    """
    ${augur_app} filter \
        --sequences ${sequences} \
        --sequence-index ${sequence_index} \
        --metadata ${metadata} \
        --exclude ${exclude} \
        --output ${sequences.simpleName}_filtered.fasta \
        --group-by country year month \
        --sequences-per-group 20 \
        --min-date 2012
    """
    stub:
    """
    touch "${sequences.simpleName}_filtered.fasta"
    """
}

process align {
    label 'nextstrain'
    input: tuple path(filtered), path(reference)
    output: path("${filtered.simpleName}_aligned.fasta")
    script:
    """
    ${augur_app} align \
        --sequences ${filtered} \
        --reference-sequence ${reference} \
        --output ${filtered.simpleName}_aligned.fasta \
        --fill-gaps
    """
    stub:
    """
    touch ${filtered.simpleName}_aligned.fasta
    """

}

process tree {
    label 'nextstrain'
    input: path(aligned)
    output: path("${aligned.simpleName}_raw.nwk")
    script:
    """
    ${augur_app} tree \
        --alignment ${aligned} \
        --output ${aligned.simpleName}_raw.nwk
    """
    stub:
    """
    touch ${aligned.simpleName}_raw.nwk
    """
}

process refine {
    label 'nextstrain'
    input: tuple path(tree_raw), path(aligned), path(metadata)
    output: tuple path("${tree_raw.simpleName.replace('_raw','')}.nwk"), path("${tree_raw.simpleName.replace('_raw','')}_branch_lengths.json")
    script:
    """
    ${augur_app} refine \
        --tree ${tree_raw} \
        --alignment ${aligned} \
        --metadata ${metadata} \
        --output-tree ${tree_raw.simpleName.replace('_raw','')}.nwk \
        --output-node-data ${tree_raw.simpleName.replace('_raw','')}_branch_lengths.json \
        --timetree \
        --coalescent opt \
        --date-confidence \
        --date-inference marginal \
        --clock-filter-iqd 4
    """
    stub:
    """
    touch ${tree_raw.simpleName.replace('_raw','')}.nwk ${tree_raw.simpleName.replace('_raw','')}_branch_lengths.json
    """
}

process ancestral {
    label 'nextstrain'
    input: tuple path(tree), path(aligned)
    output: path("${tree.simpleName}_nt_muts.json")
    script:
    """
    ${augur_app} ancestral \
        --tree ${tree} \
        --alignment ${aligned} \
        --output-node-data ${tree.simpleName}_nt_muts.json \
        --inference joint
    """
    stub:
    """
    touch ${tree.simpleName}_nt_muts.json
    """
}

process translate {
    label 'nextstrain'
    input: tuple path(tree), path(nt_muts), path(reference)
    output: path("${tree.simpleName}_aa_muts.json")
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

process traits {
    label 'nextstrain'
    input: tuple path(tree), path(metadata)
    output: path("${tree.simpleName}_traits.json")
    script:
    """
    ${augur_app} traits \
        --tree ${tree} \
        --metadata ${metadata} \
        --output ${tree.simpleName}_traits.json \
        --columns region country \
        --confidence
    """
    stub:
    """
    touch ${tree.simpleName}_traits.json
    """
}

// To make this general purpose, just take a collection of json files, don't split it out
process export {
    label 'nextstrain'
    publishDir("$params.outdir"), mode: 'copy'
    input: tuple path(tree), path(metadata), path(branch_lengths), \
      path(traits), path(nt_muts), path(aa_muts), path(colors), \
      path(lat_longs), path(auspice_config)
    output: path("auspice/${tree.simpleName}.json")
    script:
    """
    ${augur_app} export v2 \
        --tree ${tree} \
        --metadata ${metadata} \
        --node-data ${branch_lengths} \
                    ${traits} \
                    ${nt_muts} \
                    ${aa_muts} \
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