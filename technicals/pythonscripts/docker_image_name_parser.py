#!/usr/bin/python3

import yaml

with open('image_properties.yaml') as file:
    imageproperties = yaml.load_all(file, Loader=yaml.FullLoader)
    for nametag in imageproperties:
        if nametag is not None and 'images' in nametag:
            for image in nametag['images']:
                print("%s:%s" % (nametag['images'][image]['name'], nametag['images'][image]['tag']))
