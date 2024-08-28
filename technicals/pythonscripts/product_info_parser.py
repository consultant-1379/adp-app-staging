#!/usr/bin/python3

import yaml
import sys

with open(sys.argv[1] + '/eric-product-info.yaml') as file:
    imageproperties = yaml.load(file, Loader=yaml.FullLoader)
    for imageKey in imageproperties['images']:
        print("%s:%s" % (imageproperties['images'][imageKey]['name'], imageproperties['images'][imageKey]['tag']))
