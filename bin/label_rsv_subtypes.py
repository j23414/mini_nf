#! /usr/bin/env python
# FROM: https://github.com/blab/rsv_adaptive_evo/blob/master/processing_scripts/label_rsv_subtypes.ipynb

# === pkg
import requests
import json
import pandas as pd
import numpy as np
from augur.utils import json_to_tree
from Bio import SeqIO
from Bio.Seq import Seq
from Bio.SeqRecord import SeqRecord
import sys
import argparse

# === inputs
def parse_args():
    parser = argparse.ArgumentParser(
        description = "Takes an auspice RSV json file, and splits into A and B fasta files"
    )
    parser.add_argument(
        "--tree_json",
        help = "The auspice rsv.json file.",
        required = True
    )
    parser.add_argument(
        "--data_file",
        help = "The rsv.fasta file",
        required = False
    )
    return parser.parse_args()

#read in tree
#tree_json_file = f'../rsv_step0/auspice/rsv.json'

# randomly chosen tips that are known to be Rsv-A or Rsv-B
#known_A = 'KY883566'
#known_B = 'KY883569'

def label_rsv_subtypes(tree_json_file, data_file, known_A='KY883566', known_B='KY883569'):
    with open(tree_json_file, 'r') as f:
        tree_json = json.load(f)
    tree = json_to_tree(tree_json)
    
    # === func
    # find the name of the node that is parent to all RSV-A (or all RSV-B) isolates
    for node in tree.find_clades(): # Hard coded?
        if node.name == known_B:
            node_path_B = tree.get_path(node)
            B_ancestral_node = node_path_B[1].name
        elif node.name == known_A:
            node_path_A = tree.get_path(node)
            A_ancestral_node = node_path_A[1].name
    
    # for each tip on the tree, find which subtype it belongs to
    # store this info in a dictionary with isolate accession ID as key and subtype as value
    subtype_dict = {}
    
    for node in tree.find_clades(terminal=True):
        node_path = tree.get_path(node)
        ancestral_node = node_path[1].name
        if ancestral_node == A_ancestral_node:
            subtype_dict[node.name] = 'A'
        elif ancestral_node == B_ancestral_node:
            subtype_dict[node.name] = 'B'
    
    # write a data file with all subtype A viruses and another with all subtype B
    with open(data_file, 'r') as handle:
        
        edited_records_A = []
        edited_records_B = []
        
        for virus in SeqIO.parse(handle, 'fasta'):
            accession = virus.id.split('|')[0]
            
            if accession in subtype_dict.keys():
            
                subtype = subtype_dict[accession]
    
                virus.id = '|'.join(virus.id.split('|')[0:6]) + f'|{subtype}|' + virus.id.split('|')[-1]
                virus.description = virus.id
                
                if subtype =='A':
                    edited_records_A.append(SeqRecord(virus.seq, id=virus.id, description=virus.description))
                elif subtype == 'B':
                    edited_records_B.append(SeqRecord(virus.seq, id=virus.id, description=virus.description))
    
        SeqIO.write(edited_records_A, 'rsv_A_genome.fasta', "fasta")
        SeqIO.write(edited_records_B, 'rsv_B_genome.fasta', "fasta")

# == main
def main():
    args = parse_args()
    tree_json_file = args.tree_json # f'results/auspice/rsv.json'
    data_file = args.data_file # 00_PrepData/rsv.fasta'
    label_rsv_subtypes(tree_json_file, data_file)

if __name__ == "__main__":
    main()