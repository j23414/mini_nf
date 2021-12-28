#! /usr/bin/env python

import json

def json_paramstr(json_file, prefix="--"):
    jdata = open(json_file).read()
    params = json.loads(jdata)
    
    for i in params:
        print(prefix + i + " " + params[i], end=' ')

def main():
    json_paramstr('config.json')

if __name__ == '__main__':
    main()
