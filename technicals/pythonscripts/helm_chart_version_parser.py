#!/usr/bin/python3

import yaml
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('-p', '--path', required=True, help='Helm Chart yaml path')
args = parser.parse_args()


with open(args.path) as file:
    chart_yaml = yaml.load(file, Loader=yaml.Loader)
    print(chart_yaml['version'])
