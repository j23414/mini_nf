#! /usr/bin/env python
"""
Generate URL to download all NCBI Taxa sequences and their curated metadata
from GenBank via NCBI Virus.

The URL this program builds is based on the URL constructed with

    https://github.com/nextstrain/ncov-ingest/blob/2a5f255329ee5bdf0cabc8b8827a700c92becbe4/bin/genbank-url
    https://github.com/nextstrain/dengue/blob/8f606958fed4d5a22f1a2021083374e33710b55c/ingest/bin/genbank-url

and observing the network activity at

    https://www.ncbi.nlm.nih.gov/labs/virus/vssi/#/virus?SeqType_s=Nucleotide&VirusLineage_ss=Dengue%20virus,%20taxid:12637&SLen_i=5000%20TO%201000000
"""
from urllib.parse import urlencode
import sys
import argparse

def parse_args():
    parser = argparse.ArgumentParser(
        description = "Take a viral NCBI Taxon ID, return list of Genbank IDs and some metadata"
    )
    parser.add_argument(
        "--taxonid",
        help = "NCBI Taxon ID.",
        required = True
    )
    return parser.parse_args()

def build_query_url(ncbi_id:str):
    endpoint = "https://www.ncbi.nlm.nih.gov/genomes/VirusVariation/vvsearch2/"
    params = {
        # Search criteria
        'fq': [
            '{!tag=SeqType_s}SeqType_s:("Nucleotide")', # Nucleotide sequences (as opposed to protein)
            f'VirusLineageId_ss:({ncbi_id})',  # NCBI Taxon id
            f'Division_s:("VRL")',
            '{!tag=SLen_i}SLen_i:([5000 TO 15000])', # gt then 5K
            # '{!tag=UpdateDate_dt}UpdateDate_dt:([add a date range here])', # only fetch any updated entries in last X months
        ],
    
        # Unclear, but seems necessary.
        'q': '*:*',
    
        # Response format
        'cmd': 'download',
        'dlfmt': 'csv',
        'fl': ','.join(
            ':'.join(names) for names in [
                # Pairs of (output column name, source data field).
                ('genbank_accession',       'id'),
                ('updated_date',            'UpdateDate_dt'),
                ('length',                  'SLen_i'),
            ]
        ),
    
        # Stable sort with GenBank accessions.
        # Columns are source data fields, not our output columns.
        'sort': 'id asc',
    
        # Not required but include email parameter to be nice.
        #'email': 'someone@fredhutch.org',
    }
    query = urlencode(params, doseq = True, encoding = "utf-8")
    
    print(f"{endpoint}?{query}")

def main():
    args = parse_args()
    build_query_url(args.taxonid)

if __name__ == "__main__":
    main()