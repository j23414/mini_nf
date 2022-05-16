#! /usr/bin/env python

# FROM: https://github.com/blab/rsv_adaptive_evo/blob/master/rsv_step0/data/extract_gene_fastas.ipynb

from hashlib import algorithms_guaranteed
import re
import json
import json
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from Bio import SeqIO
from Bio.Seq import Seq
from Bio.SeqRecord import SeqRecord
from Bio import AlignIO
from Bio.SeqFeature import SeqFeature, FeatureLocation
import sys
import argparse

# === input
def parse_args():
  parser = argparse.ArgumentParser(
    description = "Pull out a particular gene fasta"
  )
  parser.add_argument(
    "--subtype",
    help = "A or B",
    required = True
  )
  parser.add_argument(
    "--gene",
    help = "F or G",
    required = True
  )
  parser.add_argument(
    "--reference",
    help = "rsv_reference.gb",
    required = True
  )
  parser.add_argument(
    "--data_file",
    help = "rsv_subtype_genome.fasta",
    required = False
  )
  parser.add_argument(
    "--aligned_file",
    help = "rsv_subtype_aln.fasta",
    required = False
  )
  return parser.parse_args()

# === function
def write_gene_fastas(subtype, gene, data_file = '', aligned_file = '', reference='results/downloads/rsv_reference.gb'):
  if(len(data_file) < 1 ):
    data_file = f'results/00_PrepData/rsv_{subtype}_genome.fasta'
  if(len(aligned_file) < 1):
    aligned_file = f'../results/aligned_{subtype}.fasta'
  #find location of genes
  for record in SeqIO.parse(open(reference,"r"), "genbank"):
    for feature in record.features:
      if feature.type == 'CDS':
        if feature.qualifiers['gene'] == [gene]:
          gene_location = feature.location
  
  # alignment file only has accession number associated with a sequence
  # need full id (including location and date, etc)
  # get this from original data/rsv_X.fasta file
  accession_to_id = {}
  
  with open(data_file, 'r') as handle:
    for virus in SeqIO.parse(handle, 'fasta'):
      accession_to_id[virus.id.split('|')[0]] = virus.id
  
  # read in alignment file to find sequence of the specified gene    
  #aligned_file = f'../results/aligned_{subtype}.fasta'
  
  # for each virus in the alignment file, save new entry with only the sequence of the specified gene
  gene_records = []
          
  with open(aligned_file, 'r') as handle:
    for virus in SeqIO.parse(handle, 'fasta'):
      gene_seq = gene_location.extract(virus.seq)

      gene_records.append(SeqRecord(gene_seq, id=accession_to_id[virus.id], 
                                    description=accession_to_id[virus.id]))
          
  SeqIO.write(gene_records, f'rsv_{subtype}_{gene}.fasta', "fasta")

def loop_rsv_genes():
  subtypes = ['A', 'B', 'all']
  genes = ['F', 'G']
  
  for s in subtypes:
    for g in genes:
      write_gene_fastas(s, g)

def main():
  args = parse_args()
  subtype = args.subtype
  gene = args.gene
  data_file = args.data_file 
  aligned_file = args.aligned_file
  reference = args.reference
  write_gene_fastas(subtype, gene, data_file, aligned_file, reference)

if __name__ == "__main__":
  main()