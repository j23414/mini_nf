#! /usr/bin/env nextflow
// USAGE: nextflow run mkpx_ingest.nf -resume

nextflow.enable.dsl=2

params.outdir="results"

import org.yaml.snakeyaml.Yaml
def load_snakemake_yaml(filepath) {
  config_map = [:]
  new Yaml().load(new FileInputStream(new File(filepath))).each { k, v -> config_map[k]=v}
  return(config_map)
}

//https://github.com/nextstrain/monkeypox/tree/master/ingest/config .

process get_monkeypox_ingest_configs {
  publishDir "${params.outdir}"
  output: tuple path("config/config.yaml"), path("source-data")
  script:
  """
  wget -O master.zip https://github.com/nextstrain/monkeypox/archive/refs/heads/master.zip
  unzip master.zip
  mv monkeypox-master/ingest/config .
  mv monkeypox-master/ingest/source-data .
  """
}

process fetch_from_genbank {
  publishDir "${params.outdir}/data"
  output: path("genbank.ndjson")
  script:
  """
  wget https://raw.githubusercontent.com/nextstrain/monkeypox/master/ingest/bin/fetch-from-genbank
  wget https://raw.githubusercontent.com/nextstrain/monkeypox/master/ingest/bin/csv-to-ndjson
  wget https://raw.githubusercontent.com/nextstrain/monkeypox/master/ingest/bin/genbank-url

  chmod 755 csv-to-ndjson
  chmod 755 genbank-url

  bash fetch-from-genbank > genbank.ndjson
  """
}

// capture all sources if needed later
// https://github.com/nextstrain/monkeypox/blob/0efd08263569d3fdf3ccd061434827782d948bc4/ingest/workflow/snakemake_rules/fetch_sequences.smk#L25

process fetch_general_geolocation_rules {
  publishDir "${params.outdir}/data", pattern: "general-geolocation-rules.tsv"
  input: tuple val(config_map), path(source_data)
  output: tuple val(config_map), path(source_data), path("general-geolocation-rules.tsv")
  script:
  """
  curl ${config_map['transform']['geolocation_rules_url']} > general-geolocation-rules.tsv
  """
}

process concat_geolocation_rules {
  publishDir "${params.outdir}/data", pattern: "all-geolocation-rules.tsv"
  input: tuple val(config_map), path(source_data), path(general_geolocation_rules)
  output: tuple val(config_map), path(source_data), path("all-geolocation-rules.tsv")
  script:
  """
  cat ${general_geolocation_rules} ${config_map['transform']['local_geolocation_rules']} >> all-geolocation-rules.tsv
  """
}

process transform {
  publishDir "${params.outdir}/data", pattern: "sequences.fasta"
  publishDir "${params.outdir}/data", pattern: "metadata_raw.tsv"
  input: tuple val(config_map), path(source_data), path(all_geolocation_rules), path(sequences_ndjson)
  output: tuple val(config_map), path(source_data), path("sequences.fasta"), path("metadata_raw.tsv")
  script:
  def field_map = config_map['transform']['field_map']
  def strain_regex = config_map['transform']['strain_regex']
  def strain_backup_fields = config_map['transform']['strain_backup_fields']
  def date_fields = config_map['transform']['date_fields']
  def expected_date_formats = config_map['transform']['expected_date_formats']
  def articles = config_map['transform']['titlecase']['articles']
  def abbreviations = config_map['transform']['titlecase']['abbreviations']
  def titlecase_fields = config_map['transform']['titlecase']['fields']
  def authors_field = config_map['transform']['authors_field']
  def authors_default_value = config_map['transform']['authors_default_value']
  def abbr_authors_field = config_map['transform']['abbr_authors_field']
  def annotations = config_map['transform']['annotations']
  def annotations_id = config_map['transform']['annotations_id']
  def metadata_columns = config_map['transform']['metadata_columns']
  def id_field = config_map['transform']['id_field']
  def sequence_field = config_map['transform']['sequence_field']
  """
  wget https://raw.githubusercontent.com/nextstrain/monkeypox/master/ingest/bin/transform-field-names
  wget https://raw.githubusercontent.com/nextstrain/monkeypox/master/ingest/bin/transform-string-fields
  wget https://raw.githubusercontent.com/nextstrain/monkeypox/master/ingest/bin/transform-strain-names
  wget https://raw.githubusercontent.com/nextstrain/monkeypox/master/ingest/bin/transform-date-fields
  wget https://raw.githubusercontent.com/nextstrain/monkeypox/master/ingest/bin/transform-genbank-location
  wget https://raw.githubusercontent.com/nextstrain/monkeypox/master/ingest/bin/transform-authors
  wget https://raw.githubusercontent.com/nextstrain/monkeypox/master/ingest/bin/apply-geolocation-rules
  wget https://raw.githubusercontent.com/nextstrain/monkeypox/master/ingest/bin/merge-user-metadata
  wget https://raw.githubusercontent.com/nextstrain/monkeypox/master/ingest/bin/ndjson-to-tsv-and-fasta

  mkdir data

  # Turns out snakemake yaml reader doesn't quite format collections correctly
  clean_format() {
    echo \$1 | tr '[' ' ' | tr ']' ' ' | tr ',' ' '
  } 

  #set +v
  #(
  #echo field_map = `clean_format "${field_map}"`
  #echo strain_regex = ${strain_regex}
  #echo strain_backup_fields = ${strain_backup_fields}  
  #echo date_fields = ${date_fields}
  #echo expected_date_formats = ${expected_date_formats}
  #echo articles = ${articles}
  #echo abbreviations = ${abbreviations}
  #echo titlecase_fields = ${titlecase_fields}
  #echo authors_field = ${authors_field}
  #echo authors_default_value = ${authors_default_value}
  #echo abbr_authors_field = ${abbr_authors_field}
  #echo annotations = ${annotations} 
  #echo annotations_id = ${annotations_id} 
  #echo metadata_columns = ${metadata_columns}
  #echo id_field = ${id_field} 
  #echo sequence_field = ${sequence_field}
  #) &> fields.tsv

  (cat ${sequences_ndjson} \
    | python3 transform-field-names \
      --field-map `clean_format "${field_map}" ` \
    | python3 transform-string-fields --normalize \
    | python3 transform-strain-names \
      --strain-regex `clean_format "${strain_regex}" ` \
      --backup-fields `clean_format "${strain_backup_fields}" ` \
    | python3 transform-date-fields \
      --date-fields `clean_format "${date_fields}" ` \
      --expected-date-formats `clean_format "${expected_date_formats}" ` \
    | python3 transform-genbank-location \
    | python3 transform-string-fields \
      --titlecase-fields `clean_format "${titlecase_fields}" ` \
      --articles `clean_format "${articles}" ` \
      --abbreviations `clean_format "${abbreviations}" ` \
    | python3 transform-authors \
      --authors-field `clean_format "${authors_field}" ` \
      --default-value `clean_format "${authors_default_value}" ` \
      --abbr-authors-field `clean_format "${abbr_authors_field}" ` \
    | python3 apply-geolocation-rules \
      --geolocation-rules `clean_format "${all_geolocation_rules}" ` \
    | python3 merge-user-metadata \
        --annotations `clean_format "${annotations}" ` \
        --id-field `clean_format "${annotations_id}" ` \
    | python3 ndjson-to-tsv-and-fasta \
        --metadata-columns `clean_format "${metadata_columns}"` \
        --metadata metadata_raw.tsv \
        --id-field `clean_format "${id_field}" ` \
        --sequence-field `clean_format "${sequence_field}" `
  ) 2>> transform.txt

  mv data/* .
  """
}

process nextclade_dataset {
  publishDir "${params.outdir}/nextclade"
  input: val(dataset_name)
  output: path("*.zip")
  script:
  def filename = "${dataset_name.toLowerCase()}"
  """
  echo ${filename}
  nextclade dataset get \
    --name ${dataset_name} \
    --output-zip ${filename}.zip
  """
}

process nextclade_align {
  publishDir "${params.outdir}/data"
  input: tuple val(config_map), path(source_data), path(sequences), path(metadata), path(dataset)
  output: tuple val(config_map), path(source_data), path("alignment_aln.fasta"), path(metadata), path("insertions.csv"), path("translations.zip")
  script:
  """
  mkdir -p data/translations
  nextclade run \
    -D ${dataset} \
    -j `nproc` \
    --retry-reverse-complement \
    --output-fasta alignment_aln.fasta \
    --output-translations 'data/translations/{gene}.fasta' \
    --output-insertions insertions.csv \
    ${sequences}

  zip -rj translations.zip data/translations
  """
}

workflow {
  /* Fetch precomputed nextclade */
  channel.of("MPXV", "hMPXV")
  | nextclade_dataset

  /* Fetch all mkpx sequences from genbank */
  genbank_ch = fetch_from_genbank()

  /* Fetch mkpx workflow config and source-data files */
  get_monkeypox_ingest_configs()

  /* Start workflow */
  get_monkeypox_ingest_configs.out 
    | map { n -> [load_snakemake_yaml(n.get(0).toString()), n.get(1)] } 
    | fetch_general_geolocation_rules
    | concat_geolocation_rules
    | combine(genbank_ch)
    | transform
    | combine(nextclade_dataset.out)
    | nextclade_align
    | view


}

