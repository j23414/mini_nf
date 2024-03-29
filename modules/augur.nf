#! /usr/bin/env nextflow

nextflow.enable.dsl=2

// fasta_fields="strain strain_name segment date host country subtype virus"
process parse {
  label 'nextstrain'
  publishDir "${params.outdir}/${build}", mode: 'copy'
  input: tuple val (build), path(fasta), val(fasta_fields)
  output: tuple path("sequences.fasta"), path("metadata.tsv")
  script:
  """
  #! /usr/bin/env bash
  ${augur_app} parse \
    --sequences ${fasta} \
    --output-sequences sequences.fasta \
    --output-metadata metadata.tsv \
    --fields ${fasta_fields}
  """
}

process index {
  label 'nextstrain'
  publishDir "${params.outdir}/${build}", mode: 'copy'
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
process filter_with_index {
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

process filter {
  label 'nextstrain'
  publishDir "${params.outdir}/${build}", mode: 'copy'
  input: tuple val(build), path(sequences), path(sequences_index), path(metadata), path(exclude), val(args)
  output: tuple val(build), path("${sequences.simpleName}_filtered.fasta")
  script:
  """
  ${augur_app} filter \
      --sequences ${sequences} \
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

// args = " --mask-from-beginning x --mask-from-end x "
process mask {
  label 'nextstrain'
  publishDir "${params.outdir}/${build}", mode: 'copy'
  input: tuple val(build), path(sequence), path(mask), val(args)
  output: tuple val(build), path("${sequence.simpleName}_masked.fasta")
  script:
  """
  ${augur_app} mask \
      --sequences ${sequence} \
      --mask ${mask} \
      --output ${sequence.simpleName}_masked.fasta \
      ${args}
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

// Input tuples should be replaced with Maps eventually
process tree_with_exclude {
  label 'nextstrain'
  publishDir "${params.outdir}/${build}", mode: 'copy'
  input: tuple val(build), path(aligned), val(args), path(exclude_sites)
  output: tuple val(build), path("${aligned.simpleName}_raw.nwk")
  script:
  """
  ${augur_app} tree \
      --alignment ${aligned} \
      --output ${aligned.simpleName}_raw.nwk \
      ${args} \
      --exclude-sites ${exclude_sites}
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
  input: tuple val(build), path(tree_raw), path(aligned), path(metadata), val(args)
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
  input: tuple val(build), path(tree), path(aligned), val(args)
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

process ancestral_rename {
    label 'nextstrain'
    publishDir "${params.outdir}/${build}", mode: 'copy'
    input: tuple val(build), path(tree), path(aligned), val(args), val(output_node_data)
    output: tuple val(build), path("${output_node_data}.json")
    script:
    """
    ${augur_app} ancestral \
        --tree ${tree} \
        --alignment ${aligned} \
        --output-node-data ${output_node_data}.json \
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

// node_data = ["nt_muts.json", "aa_muts.json", "traits.json"]
process export {
    label 'nextstrain'
    publishDir("${params.outdir}/${build}"), mode: 'copy'
    input: tuple val(build), path(tree), path(metadata), \
      path(node_data), \
      path(colors), \
      path(lat_longs), \
      path(auspice_config)
    output: tuple val(build), path("auspice")
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

process export_default_colors {
    label 'nextstrain'
    publishDir("${params.outdir}/auspice"), mode: 'copy'
    input: tuple val(build), path(tree), path(metadata), path(node_data), \
      path(lat_longs), path(auspice_config)
    output: tuple val("$build}"), path("${build}.json")
    script:
    """
    export AUGUR_RECURSION_LIMIT=10000;
    ${augur_app} export v2 \
        --tree ${tree} \
        --metadata ${metadata} \
        --node-data ${node_data} \
        --lat-longs ${lat_longs} \
        --auspice-config ${auspice_config} \
        --output auspice/${build}.json
    cp auspice/${build}.json .
    """
    stub:
    """
    mkdir auspice
    touch auspice/${tree.simpleName}.json
    """
}

/* need to get this general purpose */
process export_rsv {
    label 'nextstrain'
    publishDir("${params.outdir}/auspice"), mode: 'copy'
    input: tuple val(build), path(tree), path(metadata), path(node_data), \
      path(auspice_config), path(description), val(args)
    output: tuple val("${build}"), path("${build}.json")
    script:
    """
    export AUGUR_RECURSION_LIMIT=10000;
    ${augur_app} export v2 \
        --tree ${tree} \
        --metadata ${metadata} \
        --node-data ${node_data} \
        --auspice-config ${auspice_config} \
        --description ${description} \
        --output auspice/${build}.json \
        ${args}

    cp auspice/${build}.json .
    """
    stub:
    """
    mkdir auspice
    touch auspice/${tree.simpleName}.json
    """
}

// args = "--include-root-sequence"
process export_mkpx {
    label 'nextstrain'
    publishDir("${params.outdir}/${build}"), mode: 'copy'
    input: tuple val(build), path(tree), path(metadata), \
      path(node_data), \
      path(colors), \
      path(lat_longs), \
      path(description), \
      path(auspice_config), \
      val(args)
    output: tuple val(build), path("auspice")
    script:
    """
    ${augur_app} export v2 \
        --tree ${tree} \
        --metadata ${metadata} \
        --node-data ${node_data} \
        --colors ${colors} \
        --lat-longs ${lat_longs} \
        --description ${description} \
        --auspice-config ${auspice_config} \
        --output auspice/${tree.simpleName}.json \
        ${args}
    """
    stub:
    """
    mkdir auspice
    touch auspice/${tree.simpleName}.json
    """
}

// TODO: other Augur commands
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

// ==== Workflows
workflow AUGUR_DEFAULTS {
  take:
    build_ch
    sequences_ch
    metadata_ch
    exclude_ch
    ref_ch
    colors_ch
    lat_longs_ch
    auspice_config_ch

  main:
    build_ch
    | combine(sequences_ch)
    | index
    | combine(metadata_ch)
    | combine(exclude_ch)
    | combine(channel.of("--group-by country year month --sequences-per-group 20 --min-date 2012"))
    | filter
    | combine(ref_ch)
    | combine(channel.of("--fill-gaps"))
    | align
    | combine(channel.of(""))
    | tree
    | join(align.out)
    | combine(metadata_ch)
    | combine(channel.of("--timetree --coalescent opt --date-confidence --date-inference marginal --clock-filter-iqd 4"))
    | refine

  tree_ch = refine.out 
    | map { n-> [n.get(0), n.get(1)] }
  
  branch_length_ch = refine.out 
    | map{ n-> [n.get(0), n.get(2)] }
  
  tree_ch
    | join(align.out) 
    | combine(channel.of("--inference joint"))
    | ancestral
  
  tree_ch 
    | join(ancestral.out) 
    | combine(ref_ch) 
    | translate
  
  tree_ch
    | combine(metadata_ch) 
    | combine(channel.of("--columns region country --confidence"))
    | traits

  node_data_ch = branch_length_ch
    | join(traits.out)
    | join(ancestral.out)
    | join(translate.out)
    | map {n -> [n.drop(1)]}
  
  tree_ch
    | combine(metadata_ch)
    | combine(node_data_ch)
    | combine(colors_ch) 
    | combine(lat_longs_ch) 
    | combine(auspice_config_ch)
    | export

  emit:
    export.out
}