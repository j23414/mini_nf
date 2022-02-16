#! /usr/bin/env nextflow

nextflow.enable.dsl=2

// from notes: https://github.com/j23414/merge_loc
process setup_folder {
  input: val(branch_name)         // mergeloc_jen
  output: path("${branch_name}")
  script:
  """
  #! /usr/bin/env bash
  mkdir ${branch_name}
  cd ${branch_name}
  git clone https://github.com/nextstrain/ncov-ingest.git
  git clone https://github.com/nextstrain/ncov.git
  cd ncov-ingest
  git branch ${branch_name}       # For gisaid/genbank_annotations.txt
  git checkout ${branch_name}
  cd ../ncov
  git branch ${branch_name}       # For defaults/colors lat_long.txt
  git checkout ${branch_name}

  # Pull existing s3 datasets
  nextstrain remote download s3://nextstrain-ncov-private/metadata.tsv.gz /dev/stdout | gunzip > data/downloaded_gisaid.tsv
  nextstrain remote download s3://nextstrain-data/files/ncov/open/metadata.tsv.gz /dev/stdout | gunzip > data/metadata_genbank.tsv
  """
}

process parse_additional_info {
  input: tuple path(setup_dir), path(slack_downloads_dir)
  output: tuple path("${setup_dir}"), path("${setup_dir}/ncov/scripts/curate_metadata/output_curate_metadata")
  script:
  """
  mv ${slack_downloads_dir} ncov/scripts/curate_metadata/inputs_new_sequences
  cd ncov
  python scripts/curate_metadata/parse_additional_info.py --auto 
  """
}

//python scripts/curate_metadata/curate_metadata.py  # <= problem is that this is interactive, hmm

// workflow Merge_LOC {
//   
// }


