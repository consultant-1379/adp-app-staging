#!/usr/bin/python3

import yaml
import argparse

PATTERN = (r'^(?P<MAJOR>[0-9]+)[.](?P<MINOR>[0-9]+)[.](?P<PATCH>[0-9]+)[-]?P<BUILD>[0-9]')

parser = argparse.ArgumentParser()
parser.add_argument('-p', '--path', required=True, help='Helm Chart yaml path')
parser.add_argument('-v', '--step_version', required=True, help='MAJOR, MINOR, PATCH or BUILD')
args = parser.parse_args()

'''
Increment Helm Chart version in Chart.yaml
MAJOR: 1.2.3-45 -> 2.0.0-1
MINOR: 1.2.3-45 -> 1.3.0-1
PATCH: 1.2.3-45 -> 1.2.4-1
BUILD: 1.2.3-45 -> 1.2.3-46
'''


def main():
    with open(args.path) as file:
        chart_yaml = yaml.full_load(file)
        version = chart_yaml['version']
        ver, build = str(version).split('-')
        major, minor, patch = str(ver).split('.')

        if args.step_version.lower() == "major":
            new_version = str(int(major) + 1) + '.0.0-1'
        elif args.step_version.lower() == "minor":
            new_version = major + '.' + str(int(minor) + 1) + '.0-1'
        elif args.step_version.lower() == "patch":
            new_version = major + '.' + minor + '.' + str(int(patch) + 1) + '-1'
        elif args.step_version.lower() == "build":
            new_version = ver + '-' + str(int(build) + 1)
        else:
            print('Invalid option')
            exit()

    chart_yaml['version'] = str(new_version)

    with open(args.path, 'w') as file:
        yaml.dump(chart_yaml, file)


if __name__ == "__main__":
    main()
