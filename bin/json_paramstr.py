#! /usr/bin/env python

import sys
import json
 
def json_paramstr(json_file, prefix="--"):
    """ Def: json -> str "--key value --key2 value2 ..."
    """
    jdata = open(json_file).read()
    params = json.loads(jdata)
    
    for i in params:
        print(prefix + i + " '" + params[i] + "'", end=' ')
 
def add_json_params(json_file, new_dict):
    """ Def: json, dict -> json (add new dictionary to json file)
    """
    jdata = open(json_file).read()
    params = json.loads(jdata)

    for i in new_dict:
        params[i] = new_dict[i]
    
    with open(json_file, 'w') as outfile:
        json.dump(params, outfile, indent=2)

def merge_json_params(json_file, json_file2):
    """ Def: json, json -> json (add 2nd json to 1st json file)
    """
    jdata = open(json_file).read()
    params = json.loads(jdata)

    jdata2 = open(json_file2).read()
    params2 = json.loads(jdata2)
    
    for i in params2:
        params[i] = params2[i]
    
    with open(json_file, 'w') as outfile:
        json.dump(params, outfile, indent=2)

def dict_json(new_dict, json_file = "newparams.json"):
    """ Def: dict -> json
    """
    with open(json_file, 'w') as outfile:
        json.dump(new_dict, outfile, indent=2)

def main():
    merge_json_params(sys.argv[1], sys.argv[2])
    json_paramstr(sys.argv[1], prefix="")
    
if __name__ == '__main__':
    main()
