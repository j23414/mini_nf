#! /usr/bin/env python

import sys
import json

if len(sys.argv) > 1:
    val = ""
    key = ""
    myparams = {}
    for t in sys.argv:
        if t.startswith("--"):
            if (len(key)>0):
                myparams[key]=val.strip()
            
            key = t
            val = ""
        else:
            val = val + " " + t

    if (len(val)>0):
        myparams[key]=val.strip()
    
    print(myparams)
    with open('tmp_params.json', 'w') as outfile:
        json.dump(myparams, outfile, indent=2)    
