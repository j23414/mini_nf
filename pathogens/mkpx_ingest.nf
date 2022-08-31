#! /usr/bin/env nextflow
// USAGE: nextflow run mkpx_ingest.nf -resume

nextflow.enable.dsl=2

import org.yaml.snakeyaml.Yaml
def load_snakemake_yaml(filepath) {
  config_map = [:]
  new Yaml().load(new FileInputStream(new File(filepath))).each { k, v -> config_map[k]=v}
  return(config_map)
}

//https://github.com/nextstrain/monkeypox/tree/master/ingest