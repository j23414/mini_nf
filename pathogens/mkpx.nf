#! /usr/bin/env nextflow
// USAGE: nextflow run mkpx.nf -resume
nextflow.enable.dsl=2
import org.yaml.snakeyaml.Yaml
def load_snakemake_yaml(filepath) {
  config_map = [:]
  new Yaml().load(new FileInputStream(new File(filepath))).each { k, v -> config_map[k]=v}
  return(config_map)
}

params.data_source = false

/* Import generalized processes */
include { download; decompress} from "../modules/prepare.nf"
include { download_sequences_via_lapis; download_metadata_via_lapis } from '../modules/lapis.nf'

// === Option 1: Wrap whole build in one process

process build_monkeypox {
  publishDir "${params.outdir}", mode: 'copy'
  output: tuple path("monkeypox-master/results"), path("monkeypox-master/auspice"), path("monkeypox-master/*.logs")
  script:
  """
  wget -O master.zip https://github.com/nextstrain/monkeypox/archive/refs/heads/master.zip
  unzip master.zip
  cd monkeypox-master
  nextstrain build --cpus 1 . --configfile config/config_mpxv.yaml
  #nextstrain build --cpus 1 . --configfile config/config_hmpxv1.yaml
  """
}

// === Option 2: Modularize into multiple processes

process get_monkeypox_configs {
  publishDir "${params.outdir}"
  output: tuple path("config"), path("config/config_*.yaml")
  script:
  """
  wget -O master.zip https://github.com/nextstrain/monkeypox/archive/refs/heads/master.zip
  unzip master.zip
  mv monkeypox-master/config .
  """
}

process count_records {
  input: tuple path(sequences_fasta), path(metadata_tsv)
  output: stdout()
  script:
  """
  echo "Sequence records:" `grep -c ">" ${sequences_fasta} `
  echo "Metadata lines:" `cat ${metadata_tsv} | wc -l `
  """ 
}

process update_example_data {
  publishDir "${params.outdir}"
  input: tuple path(sequences), path(metadata)
  output: tuple path("example_data/sequences.fasta"), path("example_data/metadata.tsv")
  script:
  """
  mkdir example_data
  augur filter \
    --metadata ${metadata} \
    --metadata-id-columns accession \
    --sequences ${sequences} \
    --include-where strain=MK783032 strain=MK783030 \
    --group-by clade lineage \
    --subsample-max-sequences 50 \
    --subsample-seed 0 \
    --output-metadata example_data/metadata.tsv \
    --output-sequences example_data/sequences.fasta
  """
}

process wrangle_metadata {
  publishDir "$params.outdir/${config_map.build_name}/results"
  input: tuple val(config_map), path(metadata)
  output: tuple val(config_map), path("results/metadata.tsv")
  script:
  """
  mkdir -p results

  wget https://raw.githubusercontent.com/nextstrain/monkeypox/master/scripts/wrangle_metadata.py

  python3 wrangle_metadata.py \
    --metadata ${metadata} \
    --strain-id ${config_map.strain_id_field} \
    --output results/metadata.tsv
  """
}

process map_filter {
  publishDir "$params.outdir/${config_map.build_name}"
  input: tuple val(config_map), path(config), path(sequences), path(metadata)
  output: tuple val(config_map), path(config), path("${sequences.simpleName}_filtered.fasta"), path("${metadata.simpleName}_filtered.tsv")
  script:
  def filters = "${config_map.filters}" != "null" ? "${config_map.filters}" : ''
  """
  augur filter \
  --sequences ${sequences} \
  --metadata ${metadata} \
  --exclude ${config_map['exclude']} \
  --output-sequences ${sequences.simpleName}_filtered.fasta \
  --output-metadata ${metadata.simpleName}_filtered.tsv \
  --group-by ${config_map['group_by']} \
  --sequences-per-group ${config_map['sequences_per_group']} \
  --min-date ${config_map['min_date']} \
  --min-length ${config_map['min_length']} \
  --output-log filtered.log \
  $filters
  """
}

process map_separate_reverse_complement {
  publishDir "$params.outdir/${config_map.build_name}"
  input: tuple val(config_map), path(config), path(sequences), path(metadata)
  output: tuple val(config_map), path(config), path("${sequences.simpleName}_reversed.fasta"), path(metadata)
  script:
  """
  wget https://raw.githubusercontent.com/nextstrain/monkeypox/master/scripts/reverse_reversed_sequences.py

  python3 reverse_reversed_sequences.py \
    --metadata ${metadata} \
    --sequences ${sequences} \
    --output ${sequences.simpleName}_reversed.fasta
  """
}

process map_align {
  publishDir "$params.outdir/${config_map.build_name}"
  input: tuple val(config_map), path(config), path(sequences), path(metadata)
  output: tuple val(config_map), path(config), path("${sequences.simpleName}_aligned.fasta"), path(metadata), path("${sequences.simpleName}_insertions.fasta")
  script:
  """
  nextalign run \
  --jobs `nproc` \
  --genemap ${config_map['genemap']} \
  --reference ${config_map['reference']} \
  --max-indel ${config_map['max_indel']} \
  --seed-spacing ${config_map['seed_spacing']} \
  --retry-reverse-complement \
  --output-fasta - \
  --output-insertions ${sequences.simpleName}_insertions.fasta \
  ${sequences} | seqkit seq -i > ${sequences.simpleName}_aligned.fasta
  """
}

process map_mask {
  publishDir "$params.outdir/${config_map.build_name}"
  input: tuple val(config_map), path(config), path(aligned), path(metadata)
  output: tuple val(config_map), path(config), path("${aligned.simpleName}_masked.fasta"), path(metadata)
  script:
  """
  augur mask \
  --sequences ${aligned} \
  --mask ${config_map['mask']['maskfile']} \
  --mask-from-beginning ${config_map['mask']['from_beginning']} \
  --mask-from-end ${config_map['mask']['from_end']} \
  --output ${aligned.simpleName}_masked.fasta
  """
}

process map_tree {
  publishDir "$params.outdir/${config_map.build_name}"
  input: tuple val(config_map), path(config), path(alignment), path(metadata)
  output: tuple val(config_map), path(config), path(alignment), path(metadata), path("tree_raw.nwk")
  script:
  """
  augur tree \
  --alignment ${alignment} \
  --output tree_raw.nwk \
  --nthreads `nproc`
  """
}

process map_refine {
  publishDir "$params.outdir/${config_map.build_name}"
  input: tuple val(config_map), path(config), path(alignment), path(metadata), path(tree_raw)
  output: tuple val(config_map), path(config), path(alignment), path(metadata), path("tree.nwk"), path("branch_lengths.json")
  script:
  def coalescent = "opt"
  def date_inference = "marginal"
  def clock_filter_iqd = 0
  def clock_rate = "${config_map.clock_rate}" != "null" ? " --clock-rate ${config_map.clock_rate}" : ''
  def clock_std_dev = "${config_map.clock_std_dev}" != "null" ? " --clock-std-dev ${config_map.clock_std_dev}" : ''
  """
  augur refine \
  --tree ${tree_raw} \
  --alignment ${alignment} \
  --metadata ${metadata} \
  --output-tree tree.nwk \
  --timetree \
  --root ${config_map['root']} \
  --precision 3 \
  --keep-polytomies \
  ${clock_rate} \
  ${clock_std_dev} \
  --output-node-data branch_lengths.json \
  --coalescent ${coalescent} \
  --date-inference ${date_inference} \
  --date-confidence \
  --clock-filter-iqd ${clock_filter_iqd}
  """
}

process map_ancestral {
  publishDir "$params.outdir/${config_map.build_name}"
  input: tuple val(config_map), path(config), path(alignment), path(metadata), path(tree), \
    path(branch_lengths)
  output: tuple val(config_map), path(config), path(alignment), path(metadata), path(tree), \
    path(branch_lengths), path("nt_muts.json")
  script:
  def inference="joint"
  """
  augur ancestral \
  --tree ${tree} \
  --alignment ${alignment} \
  --output-node-data nt_muts.json \
  --inference ${inference}
  """
}

process map_translate {
  publishDir "$params.outdir/${config_map.build_name}"
  input: tuple val(config_map), path(config), path(alignment), path(metadata), path(tree), path(branch_lengths), path(nt_muts)
  output: tuple val(config_map), path(config), path(alignment), path(metadata), path(tree), \
    path(branch_lengths), path(nt_muts), path("aa_muts.json")
  script:
  """
  augur translate \
  --tree ${tree} \
  --ancestral-sequences ${nt_muts} \
  --reference-sequence ${config_map['genemap']} \
  --output aa_muts.json
  """
}

process map_traits {
  publishDir "$params.outdir/${config_map.build_name}"
  input: tuple val(config_map), path(config), path(alignment), path(metadata), path(tree), \
    path(branch_lengths), path(nt_muts), path(aa_muts)
  output: tuple val(config_map), path(config), path(alignment), path(metadata), path(tree), \
    path(branch_lengths), path(nt_muts), path(aa_muts), path("traits.json")
  script:
  def columns = "country"
  def sampling_bias_correction = 3
  """
  augur traits \
  --tree ${tree} \
  --metadata ${metadata} \
  --output traits.json \
  --columns ${columns} \
  --confidence \
  --sampling-bias-correction ${sampling_bias_correction}
  """
}

process map_clades {
  publishDir "$params.outdir/${config_map.build_name}"
  input: tuple val(config_map), path(config), path(alignment), path(metadata), path(tree), \
    path(branch_lengths), path(nt_muts), path(aa_muts), path(traits)
  output: tuple val(config_map), path(config), path(alignment), path(metadata), path(tree), \
    path(branch_lengths), path(nt_muts), path(aa_muts), path(traits), path("clades_raw.json")
  script:
  """
  augur clades \
  --tree ${tree} \
  --mutations ${nt_muts} ${aa_muts} \
  --clades ${config_map['clades']} \
  --output-node-data clades_raw.json 2>&1 | tee clades_${config_map['build_name']}.txt
  """
}

process map_rename_clades {
  publishDir "$params.outdir/${config_map.build_name}"
  input: tuple val(config_map), path(config), path(alignment), path(metadata), path(tree), \
    path(branch_lengths), path(nt_muts), path(aa_muts), path(traits), path(clades_raw)
  output: tuple val(config_map), path(config), path(alignment), path(metadata), path(tree), \
    path(branch_lengths), path(nt_muts), path(aa_muts), path(traits), path("clades.json")
  script:
  """
  wget https://raw.githubusercontent.com/nextstrain/monkeypox/master/scripts/clades_renaming.py

  python clades_renaming.py \
  --input-node-data ${clades_raw} \
  --output-node-data clades.json
  """
}

process map_mutational_context {
  publishDir "$params.outdir/${config_map.build_name}"
  input: tuple val(config_map), path(config), path(alignment), path(metadata), path(tree), \
    path(branch_lengths), path(nt_muts), path(aa_muts), path(traits), path(clades)
  output: tuple val(config_map), path(config), path(alignment), path(metadata), path(tree), \
    path(branch_lengths), path(nt_muts), path(aa_muts), path(traits), path(clades), path("mutation_context.json")
  script:
  """
  wget https://raw.githubusercontent.com/nextstrain/monkeypox/master/scripts/mutation_context.py

  python3 mutation_context.py \
  --tree ${tree} \
  --mutations ${nt_muts} \
  --output mutation_context.json
  """
}

process map_remove_time {
  publishDir "$params.outdir/${config_map.build_name}"
  input: tuple val(config_map), path(config), path(alignment), path(metadata), path(tree), \
    path(branch_lengths), path(nt_muts), path(aa_muts), path(traits), path(clades), path(mutation_context) 
  output: tuple val(config_map), path(config), path(alignment), path(metadata), path(tree), \
    path("branch_lengths_no_time.json"), path(nt_muts), path(aa_muts), path(traits), path(clades), path(mutation_context)
  script:
  """
  wget https://raw.githubusercontent.com/nextstrain/monkeypox/master/scripts/remove_timeinfo.py

  python3 remove_timeinfo.py \
  --input-node-data ${branch_lengths} \
  --output-node-data branch_lengths_no_time.json
  """
}

process map_recency {
  publishDir "$params.outdir/${config_map.build_name}"
  input: tuple val(config_map), path(config), path(alignment), path(metadata), path(tree), \
    path(branch_lengths), path(nt_muts), path(aa_muts), path(traits), path(clades), path(mutation_context) 
  output: tuple val(config_map), path(config), path(alignment), path(metadata), path(tree), \
    path(branch_lengths), path(nt_muts), path(aa_muts), path(traits), path(clades), path(mutation_context), path("recency.json")
  script:
  """
  wget https://raw.githubusercontent.com/nextstrain/monkeypox/master/scripts/construct-recency-from-submission-date.py

  python3 construct-recency-from-submission-date.py \
  --metadata ${metadata} \
  --output recency.json 2>&1
  """
}

process map_colors {
  publishDir "$params.outdir/${config_map.build_name}"
  input: tuple val(config_map), path(config), path(alignment), path(metadata), path(tree), \
    path(branch_lengths), path(nt_muts), path(aa_muts), path(traits), path(clades), path(mutation_context), path(recency)
  output: tuple val(config_map), path(config), path(alignment), path(metadata), path(tree), \
    path(branch_lengths), path(nt_muts), path(aa_muts), path(traits), path(clades), path(mutation_context), path(recency), \
    path("colors.tsv")
  script:
  def ordering = "config/color_ordering.tsv"
  def color_schemes = "config/color_schemes.tsv"
  """
  wget https://raw.githubusercontent.com/nextstrain/monkeypox/master/scripts/assign-colors.py

  python3 assign-colors.py \
  --ordering ${ordering} \
  --color-schemes ${color_schemes} \
  --output colors.tsv \
  --metadata ${metadata} 2>&1
  """
}

process map_export {
  publishDir "$params.outdir/${config_map.build_name}"
  input: tuple val(config_map), path(config), path(alignment), path(metadata), path(tree), \
    path(branch_lengths), path(nt_muts), path(aa_muts), path(traits), path(clades), path(mutation_context), path(recency), \
    path(colors)
  output: tuple val(config_map), path(config), path(metadata), path("raw_tree.json"), path("raw_tree_root-sequence.json")
  script:
  """
  augur export v2 \
  --tree ${tree} \
  --metadata ${metadata} \
  --node-data ${branch_lengths} ${nt_muts} ${aa_muts} ${traits} ${clades} ${mutation_context} ${recency} \
  --colors ${colors} \
  --lat-longs ${config_map['lat_longs']} \
  --description ${config_map['description']} \
  --auspice-config ${config_map['auspice_config']} \
  --include-root-sequence \
  --output raw_tree.json
  """
}

process map_final_strain_name {
  publishDir "$params.outdir/auspice/${config_map.build_name}", mode: 'copy'
  input: tuple val(config_map), path(config), path(metadata),  path(raw_tree), path(raw_root)
  output: tuple val(config_map), path(config), path(metadata),  path("tree.json"), path(raw_root)
  script:
  def display_strain_field = "${config_map.display_strain_field}" != "null" ? "${config_map.display_strain_field}" : 'strain'
  """
  wget https://raw.githubusercontent.com/nextstrain/monkeypox/master/scripts/set_final_strain_name.py

  python3 set_final_strain_name.py \
  --metadata ${metadata} \
  --input-auspice-json ${raw_tree} \
  --display-strain-name ${display_strain_field} \
  --output tree.json
  """
}

/* Main workflow */
workflow {
  // build_monkeypox() | view

  // 1) Pull data from Lapis or from data.nextstrain.org
  if (params.data_source == "lapis" ) {
    input_ch = download_sequences_via_lapis()
    | combine(download_metadata_via_lapis())
  } else {
    input_ch = channel.of(["https://data.nextstrain.org/files/workflows/monkeypox/sequences.fasta.xz", 
                "https://data.nextstrain.org/files/workflows/monkeypox/metadata.tsv.gz"])
    | download
    | decompress
  }

  input_ch
  | count_records
  | view

  sequences_ch = input_ch | map { n->n.get(0)}
  metadata_ch = input_ch | map { n->n.get(1)}

  // 2) Pull config files
  get_monkeypox_configs()
  config_dir_ch = get_monkeypox_configs.out | map {n -> n.get(0)}

  get_monkeypox_configs.out 
  | map {n -> n.get(1)}
  | flatten
  | map { n -> load_snakemake_yaml(n.toString()) }    // <= load config into a map
  | combine(metadata_ch)
  | wrangle_metadata
  | combine(sequences_ch)
  | combine(config_dir_ch)
  | map { n -> [n.get(0), n.get(3), n.get(2), n.get(1)]}
  | map_filter
  | map_separate_reverse_complement
  | map_align
  | map { n -> n.take(4) }
  | map_mask
  | map_tree
  | map_refine
  | map_ancestral
  | map_translate
  | map_traits
  | map_clades
  | map_rename_clades
  | map_mutational_context
  | map_remove_time
  | map_recency
  | map_colors
  | map_export
  | map_final_strain_name
  | view
}
