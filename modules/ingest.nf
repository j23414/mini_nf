#! /usr/bin/env nextflow

nextflow.enable.dsl=2

process fetch_from_genbank {
  publishDir "results/ingest/fetch_from_genbank", mode: 'copy'
  input: val(ncbi_taxon_id)
  output: path("genbank_${ncbi_taxon_id}.ndjson")
  script:
  """
  #! /usr/bin/env bash

  # (1) Pick wget or curl
  if which wget >/dev/null ; then
    download_cmd="wget -O"
  elif which curl >/dev/null ; then
    download_cmd="curl -fsSL --output"
  else
    echo "neither wget nor curl available"
    exit 1
  fi

  # (2) Pull needed scripts
  mkdir bin
  \$download_cmd bin/genbank-url https://raw.githubusercontent.com/nextstrain/dengue/ingest/ingest/bin/genbank-url
  \$download_cmd bin/fetch-from-genbank https://raw.githubusercontent.com/nextstrain/dengue/ingest/ingest/bin/fetch-from-genbank
  \$download_cmd bin/csv-to-ndjson https://raw.githubusercontent.com/nextstrain/monkeypox/master/ingest/bin/csv-to-ndjson

  chmod +x bin/*

  # (3) Fetch data
  bin/fetch-from-genbank $ncbi_taxon_id > genbank_${ncbi_taxon_id}.ndjson
  """
}

process fetch_general_geolocation_rules {
  publishDir "results/ingest/fetch_general_geolocation_rules", mode: 'copy'
  output: path("general_geolocation_rules.tsv")
  script:
  """
  #! /usr/bin/env bash

  # (1) Pick wget or curl
  if which wget >/dev/null ; then
    download_cmd="wget -O"
  elif which curl >/dev/null ; then
    download_cmd="curl -fsSL --output"
  else
    echo "neither wget nor curl available"
    exit 1
  fi

  # (2) Pull geolocation rules
  \$download_cmd general_geolocation_rules.tsv https://raw.githubusercontent.com/nextstrain/ncov-ingest/master/source-data/gisaid_geoLocationRules.tsv
  """
}

// Deconstruct the transform rule (Only for debug mode, otherwise this will create > 5x copies of the ndjson)
process transform_field_names {
  publishDir "results/ingest/transform_field_names", mode: 'copy'
  input: tuple path(ndjson), val(field_map)
  output: path("${ndjson.simpleName}_tfn.ndjson")
  script:
  """
  #! /usr/bin/env bash

    # (1) Pick wget or curl
  if which wget >/dev/null ; then
    download_cmd="wget -O"
  elif which curl >/dev/null ; then
    download_cmd="curl -fsSL --output"
  else
    echo "neither wget nor curl available"
    exit 1
  fi

  # (2) Pull needed scripts
  mkdir bin
  \$download_cmd bin/transform-field-names https://raw.githubusercontent.com/nextstrain/monkeypox/master/ingest/bin/transform-field-names
  chmod +x bin/*

  # (3) Transform field names
  cat ${ndjson} \
  | ./bin/transform-field-names \
    --field-map $field_map \
  > ${ndjson.simpleName}_tfn.ndjson
  """
}

process transform_string_fields {
  publishDir "results/ingest/transform_string_fields", mode: 'copy'
  input: path(ndjson)
  output: path("${ndjson.simpleName}_tsf.ndjson")
  script:
  """
  #! /usr/bin/env bash

  # (1) Pick wget or curl
  if which wget >/dev/null ; then
    download_cmd="wget -O"
  elif which curl >/dev/null ; then
    download_cmd="curl -fsSL --output"
  else
    echo "neither wget nor curl available"
    exit 1
  fi

  # (2) Pull needed scripts
  mkdir bin
  \$download_cmd bin/transform-string-fields https://raw.githubusercontent.com/nextstrain/monkeypox/master/ingest/bin/transform-string-fields
  chmod +x bin/*

  # (3) Transform string fields
  cat ${ndjson} \
  | ./bin/transform-string-fields --normalize \
  > ${ndjson.simpleName}_tsf.ndjson
  """
}

process transform_strain_names {
  publishDir "results/ingest/transform_strain_names", mode: 'copy'
  input: tuple path(ndjson), val(strain_regex), val(strain_backup_fields)
  output: path("${ndjson.simpleName}_tsn.ndjson")
  script:
  """
  #! /usr/bin/env bash

  # (1) Pick wget or curl
  if which wget >/dev/null ; then
    download_cmd="wget -O"
  elif which curl >/dev/null ; then
    download_cmd="curl -fsSL --output"
  else
    echo "neither wget nor curl available"
    exit 1
  fi

  # (2) Pull needed scripts
  mkdir bin
  \$download_cmd bin/transform-strain-names https://raw.githubusercontent.com/nextstrain/monkeypox/master/ingest/bin/transform-strain-names
  chmod +x bin/*

  # (3) Transform strain names
  cat ${ndjson} \
  | ./bin/transform-strain-names \
    --strain-regex ${strain_regex} \
    --backup-fields ${strain_backup_fields} \
  > ${ndjson.simpleName}_tsn.ndjson
  """
}

process transform_date_fields {
  publishDir "results/ingest/transform_date_fields", mode: 'copy'
  input: tuple path(ndjson), val(date_fields), val(expected_date_formats)
  output: path("${ndjson.simpleName}_tdf.ndjson")
  script:
  """
  #! /usr/bin/env bash

  # (1) Pick wget or curl
  if which wget >/dev/null ; then
    download_cmd="wget -O"
  elif which curl >/dev/null ; then
    download_cmd="curl -fsSL --output"
  else
    echo "neither wget nor curl available"
    exit 1
  fi

  # (2) Pull needed scripts
  mkdir bin
  \$download_cmd bin/transform-date-fields https://raw.githubusercontent.com/nextstrain/monkeypox/master/ingest/bin/transform-date-fields
  chmod +x bin/*

  # (3) Transform date fields
  cat ${ndjson} \
  | ./bin/transform-date-fields \
    --date-fields ${date_fields} \
    --expected-date-formats ${expected_date_formats} \
  > ${ndjson.simpleName}_tdf.ndjson
  """
}

process transform_genbank_location {
  publishDir "results/ingest/transform_genbank_location", mode: 'copy'
  input: path(ndjson)
  output: path("${ndjson.simpleName}_tgl.ndjson")
  script:
  """
  #! /usr/bin/env bash

  # (1) Pick wget or curl
  if which wget >/dev/null ; then
    download_cmd="wget -O"
  elif which curl >/dev/null ; then
    download_cmd="curl -fsSL --output"
  else
    echo "neither wget nor curl available"
    exit 1
  fi

  # (2) Pull needed scripts
  mkdir bin
  \$download_cmd bin/transform-genbank-location https://raw.githubusercontent.com/nextstrain/monkeypox/master/ingest/bin/transform-genbank-location
  chmod +x bin/*

  # (3) Transform genbank locations
  cat ${ndjson} \
  | ./bin/transform-genbank-location \
  > ${ndjson.simpleName}_tgl.ndjson
  """
}

process transform_string_fields2 {
  publishDir "results/ingest/transform_string_fields2", mode: 'copy'
  input: tuple path(ndjson), val(titlecase_fields), val(articles), val(abbreviations)
  output: path("${ndjson.simpleName}_tsf.ndjson")
  script:
  """
  #! /usr/bin/env bash

  # (1) Pick wget or curl
  if which wget >/dev/null ; then
    download_cmd="wget -O"
  elif which curl >/dev/null ; then
    download_cmd="curl -fsSL --output"
  else
    echo "neither wget nor curl available"
    exit 1
  fi

  # (2) Pull needed scripts
  mkdir bin
  \$download_cmd bin/transform-string-fields https://raw.githubusercontent.com/nextstrain/monkeypox/master/ingest/bin/transform-string-fields 
  chmod +x bin/*

  # (3) Transform string fields
  cat ${ndjson} \
  | ./bin/transform-string-fields \
    --titlecase-fields ${titlecase_fields} \
    --articles ${articles} \
    --abbreviations ${abbreviations} \
  > ${ndjson.simpleName}_tsf.ndjson
  """
}

process transform_authors {
  publishDir "results/ingest/transform_authors", mode: 'copy'
  input: tuple path(ndjson), val(authors_field), val(authors_default_value), val(abbr_authors_field)
  output: path("${ndjson.simpleName}_ta.ndjson")
  script:
  """
  #! /usr/bin/env bash

  # (1) Pick wget or curl
  if which wget >/dev/null ; then
    download_cmd="wget -O"
  elif which curl >/dev/null ; then
    download_cmd="curl -fsSL --output"
  else
    echo "neither wget nor curl available"
    exit 1
  fi

  # (2) Pull needed scripts
  mkdir bin
  \$download_cmd bin/transform-authors https://raw.githubusercontent.com/nextstrain/monkeypox/master/ingest/bin/transform-authors 
  chmod +x bin/*

  # (3) Transform authors
  cat ${ndjson} \
  | ./bin/transform-authors \
    --authors-field ${authors_field} \
    --default-value ${authors_default_value} \
    --abbr-authors-field ${abbr_authors_field} \
  > ${ndjson.simpleName}_ta.ndjson
  """
}

process apply_geolocation_rules {
  publishDir "results/ingest/apply_geolocation_rules", mode: 'copy'
  input: tuple path(ndjson), path(all_geolocation_rules)
  output: path("${ndjson.simpleName}_agr.ndjson")
  script:
  """
  #! /usr/bin/env bash

  # (1) Pick wget or curl
  if which wget >/dev/null ; then
    download_cmd="wget -O"
  elif which curl >/dev/null ; then
    download_cmd="curl -fsSL --output"
  else
    echo "neither wget nor curl available"
    exit 1
  fi

  # (2) Pull needed scripts
  mkdir bin
  \$download_cmd bin/apply-geolocation-rules https://raw.githubusercontent.com/nextstrain/monkeypox/master/ingest/bin/apply-geolocation-rules
  chmod +x bin/*

  # (3) Transform geolocations
  cat ${ndjson} \
  | ./bin/apply-geolocation-rules \
    --geolocation-rules ${all_geolocation_rules} \
  > ${ndjson.simpleName}_agr.ndjson
  """
}

process merge_user_metadata {
  publishDir "results/ingest/merge_user_metadata", mode: 'copy'
  input: tuple path(ndjson), val(annotations), val(annotations_id)
  output: path("${ndjson.simpleName}_mum.ndjson")
  script:
  """
  #! /usr/bin/env bash

  # (1) Pick wget or curl
  if which wget >/dev/null ; then
    download_cmd="wget -O"
  elif which curl >/dev/null ; then
    download_cmd="curl -fsSL --output"
  else
    echo "neither wget nor curl available"
    exit 1
  fi

  # (2) Pull needed scripts
  mkdir bin
  \$download_cmd bin/merge-user-metadata https://raw.githubusercontent.com/nextstrain/monkeypox/master/ingest/bin/merge-user-metadata 
  chmod +x bin/*

  # (2.b) Pull annotations
  \$download_cmd annotations.tsv ${annotations}

  # (3) Transform by merging user metadata
  cat ${ndjson} \
  | ./bin/merge-user-metadata \
    --annotations annotations.tsv \
    --id-field ${annotations_id} \
  > ${ndjson.simpleName}_mum.ndjson
  """
}

process ndjson_to_tsv_and_fasta {
  publishDir "results/ingest/ndjson_to_tsv_and_fasta", mode: 'copy'
  input: tuple path(ndjson), val(metadata_columns), val(id_field), val(sequence_field)
  output: tuple path("sequences.fasta"), path("raw_metadata.tsv")
  script:
  """
  #! /usr/bin/env bash

  # (1) Pick wget or curl
  if which wget >/dev/null ; then
    download_cmd="wget -O"
  elif which curl >/dev/null ; then
    download_cmd="curl -fsSL --output"
  else
    echo "neither wget nor curl available"
    exit 1
  fi

  # (2) Pull needed scripts
  mkdir bin
  \$download_cmd bin/ndjson-to-tsv-and-fasta https://raw.githubusercontent.com/nextstrain/monkeypox/master/ingest/bin/ndjson-to-tsv-and-fasta
  chmod +x bin/*

  # (3) Transform ndjson to tsv and fasta
  cat ${ndjson} \
  | ./bin/ndjson-to-tsv-and-fasta \
    --metadata-columns ${metadata_columns} \
    --metadata raw_metadata.tsv \
    --fasta sequences.fasta \
    --id-field ${id_field} \
    --sequence-field ${sequence_field}
  """
}

// === End Transform section

process post_process_metadata {
  publishDir "results/ingest/post_process_metadata", mode: 'copy'
  input: path(metadata)
  output: path("metadata.tsv")
  script:
  """
  #! /usr/bin/env bash

  # (1) Pick wget or curl
  if which wget >/dev/null ; then
    download_cmd="wget -O"
  elif which curl >/dev/null ; then
    download_cmd="curl -fsSL --output"
  else
    echo "neither wget nor curl available"
    exit 1
  fi

  # (2) Pull needed scripts
  mkdir bin
  \$download_cmd bin/post_process_metadata.py https://raw.githubusercontent.com/nextstrain/zika/2ae81db362fdeb5e832153dfaf2294fe971e638c/ingest/bin/post_process_metadata.py
  chmod +x bin/*

  # (3) Post process metadata
  ./bin/post_process_metadata.py --metadata ${metadata} --outfile metadata.tsv
  """
}

workflow {
  general_geolocation_rules_ch = fetch_general_geolocation_rules()

  fetch_from_genbank(186536) // Ebola NCBI TaxonID
  | combine(channel.of('collected=date submitted=date_submitted genbank_accession=accession submitting_organization=institution'))
  | transform_field_names
  | transform_string_fields
  | combine(channel.of('^.+\$')) // Escape dollarsigns in regex to bypass nextflow interpolation
  | combine(channel.of('accession'))
  | transform_strain_names
  | combine(channel.of('date date_submitted updated'))
  | combine(channel.of('%Y %Y-%m %Y-%m-%d %Y-%m-%dT%H:%M:%SZ'))
  | transform_date_fields
  | transform_genbank_location
  | combine(channel.of('region country division location'))
  | combine(channel.of('and d de del des di do en l la las le los nad of op sur the y'))
  | combine(channel.of('USA'))
  | transform_string_fields2
  | combine(channel.of('authors'))
  | combine(channel.of('?'))
  | combine(channel.of('abbr_authors'))
  | transform_authors
  | combine(general_geolocation_rules_ch)
  | apply_geolocation_rules
  | combine(channel.of('https://raw.githubusercontent.com/nextstrain/ebola/ingest/ingest/source-data/annotations.tsv')) // what the heck is this?
  | combine(channel.of('accession'))
  | merge_user_metadata
  | combine(channel.of('accession genbank_accession_rev strain strain_s viruslineage_ids date updated region country division location host date_submitted sra_accession abbr_authors reverse authors institution title publications'))
  | combine(channel.of('accession'))
  | combine(channel.of('sequence'))
  | ndjson_to_tsv_and_fasta
  | map { n -> n.get(1)}
  | post_process_metadata
  | view
}