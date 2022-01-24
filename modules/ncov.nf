#! /usr/bin/env nextflow
// Desc: Keep this consistent with https://github.com/j23414/mini_wdl/blob/main/workflow.wdl

nextflow.enable.dsl=2

process mk_buildconfig {
  input: tuple val(buildname), path(sequences_fasta), path(metadata_tsv)
  output: path("build.yaml")
  script:
  """
  cat << EOF > build.yaml
  inputs:
  - name: ${buildname}
    metadata: ${metadata_tsv}
    sequences: ${sequence_fasta}
  - name: references
    metadata: data/references_metadata.tsv
    sequences: data/references_sequences.fasta
  EOF
  """
}

// Actually, this could be more general
process nextstrain_build {
  input: tuple path(build_yaml), val(giturl)
  output: path("auspice")
  script:
  """
  # Pull ncov, zika or similar repository
  wget -O master.zip ${giturl}
  INDIR=`unzip -Z1 master.zip | head -n1 | sed 's:/::g'`
  unzip master.zip  
  
  # Max out the number of threads
  PROC=`nproc`  
  # Run nextstrain
  "${nextstrain_app}" build \
    --cpus \$PROC \
    --native \$INDIR ~{"--configfile " + build_yaml}

  # TODO: add this back later --memory memory
    
  # Prepare output
  mv \$INDIR/auspice .
#  zip -r auspice.zip auspice
  """
}