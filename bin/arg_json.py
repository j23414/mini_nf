#! /usr/bin/env python
# AUTH: Jennifer Chang
# DATE: 2021/12/30

import sys
import json

if len(sys.argv) > 1:
    val = ""
    key = ""
    myparams = {}
    for t in sys.argv:
        if t.startswith("-"):
            if (len(key)>0):
                myparams[key]=val.strip()
            
            key = t
            val = ""
        else:
            val = val + " " + t

    if (len(val)>0):
        myparams[key]=val.strip()
    
    with open('tmp_params.json', 'w') as outfile:
        json.dump(myparams, outfile, indent=2)    
