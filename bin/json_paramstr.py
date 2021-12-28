#! /usr/bin/env python

import json

# Def: json -> str "--key value --key2 value2 ..."
def json_paramstr(json_file, prefix="--"):
    jdata = open(json_file).read()
    params = json.loads(jdata)
    
    for i in params:
        print(prefix + i + " " + params[i], end=' ')

# Def: json, dict -> json (add new dictionary to json file)
def add_json_params(json_file, new_dict):
    jdata = open(json_file).read()
    params = json.loads(jdata)

    for i in new_dict:
        params[i] = new_dict[i]
    
    with open(json_file, 'w') as outfile:
        json.dump(params, outfile)

# Def: json, json -> json (add 2nd json to 1st json file)
def merge_json_params(json_file, json_file2):
    jdata = open(json_file).read()
    params = json.loads(jdata)

    jdata2 = open(json_file2).read()
    params2 = json.loads(jdata2)
    
    for i in params22:
        params[i] = params2[i]
    
    with open(json_file, 'w') as outfile:
        json.dump(params, outfile)

# Def: dict -> json
def dict_json(new_dict, json_file = "newparams.json"):
    with open(json_file, 'w') as outfile:
        json.dump(new_dict, outfile)

def main():
    json_paramstr('config.json')
    new_dict = {"fred":"george", "new":"bar"}
    add_json_params('config.json', new_dict)
    dict_json(new_dict)
    
if __name__ == '__main__':
    main()
