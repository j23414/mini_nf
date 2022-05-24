#! /usr/bin/env nextflow

nextflow.enable.dsl=2

// replace with https://www.nextflow.io/blog/2021/nextflow-sql-support.html

process create_db {
  publishDir "${params.outdir}/sqlite3db", mode: 'copy'
  input: val(dbname)
  output: path("$dbname.db")
  shell:
  """
  #! /usr/bin/env bash
  sqlite3 ${dbname}.db
  """
}

process dump_db {
  publishDir "${params.outdir}/sqlite3db"
  input: tuple path(sqldb), val(sqlname)
  output: path("${sqlname}.sql")
  shell:
  """
  #! /usr/bin/env bash
  sqlite3 ${sqldb} .dump > ${sqlname}.sql
  """
}

