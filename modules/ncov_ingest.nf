#! /usr/bin/env nextflow

nextflow.enable.dsl=2

// NAME: gisaid ingest
// DESC: Given proper GISAID credentials, pull gisaid sequences and metadata
// WARN: This takes A LOT of disk space, nearly 1.5 TB so make sure you have sufficient memory
process gisaid_ingest {
  publishDir "${params.outdir}/downloads", mode:'symlink'
  input: tuple val(GISAID_API_ENDPOINT), val(GISAID_USERNAME_AND_PASSWORD)
  output: tuple path("gisaid_sequences.fasta"), path("gisaid_metadata.tsv"), path("gisaid_nextclade.tsv")
  script:
  """
  #! /usr/bin/env bash
  set -v

  # Set credentials
  export GISAID_API_ENDPOINT="${GISAID_API_ENDPOINT}"
  export GISAID_USERNAME_AND_PASSWORD="${GISAID_USERNAME_AND_PASSWORD}"
  ingest_git="https://github.com/nextstrain/ncov-ingest/archive/refs/heads/modularize_upload.zip"
  # todo: parameterize the memory, proc
  PROC=`nproc`
  memory=1500
  mem_mb=47000

  # Set up snakemake directory
  wget -O master.zip \${giturl}
  NCOV_INGEST_DIR=`unzip -Z1 master.zip | head -n1 | sed 's:/::g'`
  unzip master.zip

  # todo: link an optional cached nextclade_old.tsv file
  touch \${NCOV_INGEST_DIR}/data/gisaid/nextclade_old.tsv

  # Navigate to ncov-ingest directory, setup config variables
  cd \${NCOV_INGEST_DIR}
  declare -a config
  config+=(
    fetch_from_database=True
    trigger_rebuild=False
    keep_all_files=True
    s3_src="s3://nextstrain-ncov-private"
    s3_dst="s3://nextstrain-ncov-private/trial"
    upload_to_s3=False
  )

  # Start the build!
  nextstrain build \
  --native \
  --cpus \$PROC \
  --memory \${memory}GiB \
  --exec env \
  . \
    snakemake \
      --configfile config/gisaid.yaml \
      --config "\${config[@]}" \
      --cores \${PROC} \
      --resources mem_mb=\${mem_mb} \
      --printshellcmds
  
  cd ..
  find ${NCOV_INGEST_DIR}/data/.

  # === prepare output
  mv ${NCOV_INGEST_DIR}/data/gisaid/sequences.fasta gisaid_sequences.fasta
  mv ${NCOV_INGEST_DIR}/data/gisaid/metadata.tsv gisaid_metadata.tsv
  mv ${NCOV_INGEST_DIR}/data/gisaid/nextclade_old.tsv gisaid_nextclade.tsv
  if [ -f "${NCOV_INGEST_DIR}/data/gisaid/nextclade.tsv" ]
  then
    mv ${NCOV_INGEST_DIR}/data/gisaid/nextclade.tsv gisaid_nextclade.tsv
  fi
  """
}

// NAME: genbank ingest
// DESC: pull genbank sequences and metadata
// WARN: This takes A LOT of disk space, nearly 1.5 TB so make sure you have sufficient memory
process genbank_ingest {
  publishDir "${params.outdir}/downloads", mode:'symlink'
  output: tuple path("genbank_sequences.fasta"), path("genbank_metadata.tsv"), path("genbank_nextclade.tsv")
  script:
  """
  #! /usr/bin/env bash
  set -v

  # Set credentials
  ingest_git="https://github.com/nextstrain/ncov-ingest/archive/refs/heads/modularize_upload.zip"
  # todo: parameterize the proc, memory, ...
  PROC=`nproc`
  memory=1500
  mem_mb=47000

  # Set up snakemake directory
  wget -O master.zip \${giturl}
  NCOV_INGEST_DIR=`unzip -Z1 master.zip | head -n1 | sed 's:/::g'`
  unzip master.zip

  # todo: link an optional cached nextclade_old.tsv file
  touch \${NCOV_INGEST_DIR}/data/genbank/nextclade_old.tsv

  # Navigate to ncov-ingest directory, setup config variables
  cd \${NCOV_INGEST_DIR}
  declare -a config
  config+=(
    fetch_from_database=True
    trigger_rebuild=False
    keep_all_files=True
    s3_src="s3://nextstrain-data/files/ncov/open"
    s3_dst="s3://nextstrain-ncov-private/trial"
    upload_to_s3=False
  )

  # Start the build!
  nextstrain build \
  --native \
  --cpus \${PROC} \
  --memory \${memory}GiB \
  --exec env \
  . \
    snakemake \
      --configfile config/genbank.yaml \
      --config "\${config[@]}" \
      --cores \${PROC} \
      --resources mem_mb=${mem_mb} \
      --printshellcmds
  
  cd ..
  find ${NCOV_INGEST_DIR}/data/.

  # === prepare output
  mv ${NCOV_INGEST_DIR}/data/genbank/sequences.fasta genbank_sequences.fasta
  mv ${NCOV_INGEST_DIR}/data/genbank/metadata.tsv genbank_metadata.tsv
  mv ${NCOV_INGEST_DIR}/data/genbank/nextclade_old.tsv genbank_nextclade.tsv
  if [ -f "${NCOV_INGEST_DIR}/data/genbank/nextclade.tsv" ]
  then
    mv ${NCOV_INGEST_DIR}/data/genbank/nextclade.tsv genbank_nextclade.tsv
  fi
  """
}

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


