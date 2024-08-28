#!/usr/bin/env python3
import argparse
import yaml
import logging
from html.parser import HTMLParser
import re
import numbers


class getResources(HTMLParser):
    def __init__(self, attr, attr_value, exclude):
        HTMLParser.__init__(self)
        self.attr = attr
        self.attr_value = attr_value
        self.to_exclude = exclude
        self.tag_counter = 0
        self.to_add = 1
        self.value_to_add = ''
        self.output = {}

    def handle_starttag(self, tag, attrs):
        if tag != 'span' and tag != 'a':
            return
        if self.tag_counter:
            self.tag_counter += 1
            return
        # ignore excluded clusters
        for name, value in attrs:
            for exclude in self.to_exclude:
                if name == 'href' and exclude in value:
                    logging.info('Cluster ' + value + ' exluded from the output')
                    self.to_add = 0
                    break
        for name, value in attrs:
            if (name == self.attr and value in self.attr_value and self.to_add != 0):
                self.value_to_add = value
                break
            else:
                return
        self.tag_counter = 1

    def handle_endtag(self, tag):
        if tag == 'span' and self.tag_counter:
            self.tag_counter -= 1

    def handle_data(self, data):
        # skip non numeric data
        if self.tag_counter and is_numeric(data):
            data = int(data) if data.isdigit() else float(data)
            # skip 0 or negative data
            if data > 0:
                if self.value_to_add not in self.output:
                    # if resource value not yet exists --> set that to min value
                    logging.info(f"{self.value_to_add} {data}")
                    self.output[self.value_to_add] = data
                else:
                    # if resource value less then existing one --> overwrite the min value
                    current_minimal_value = self.output.get(self.value_to_add)
                    if data < current_minimal_value:
                        logging.info(f"{self.value_to_add} {str(data)} less than {current_minimal_value}")
                        self.output[self.value_to_add] = data

    def get_result(self):
        return self.output


def is_numeric(string: str) -> bool:
    try:
        float(string)
        return True
    except ValueError:
        return False


# Parse html to get info about ProdCI clusters capacity
def calculate_html(attr, attr_value, exclude, html):
    html_parser = getResources(attr, attr_value, exclude)
    html_parser.feed(html)
    return html_parser.get_result()


# Get cpu/memory values from dimtool output
def get_dimtool_values(dt_yaml, resource):
    try:
        if 'requests' in dt_yaml:
            yield dt_yaml['requests'][resource]
    except Exception as e:
        logging.warn(resource + ' not found in {}'.format(dt_yaml))
        logging.warn('Please check if the content of the values file generated by dimtool is correct')
        raise e
    for key, value in dt_yaml.items():
        if isinstance(value, dict):
            for i in get_dimtool_values(value, resource):
                yield i


def getBinaryMultiples(binary_units):
    """
    Get binary multiples by binary units string
    https://en.wikipedia.org/wiki/Byte#Multiple-byte_units
    https://kubernetes.io/docs/reference/kubernetes-api/common-definitions/quantity/
    """
    if binary_units in ['Ki', 'KiB']:
        return 2**10
    elif binary_units in ['K', 'KB']:
        return 10**3
    elif binary_units in ['Mi', 'MiB']:
        return 2**20
    elif binary_units in ['M', 'MB']:
        return 10**6
    elif binary_units in ['Gi', 'GiB']:
        return 2**30
    elif binary_units in ['G', 'GB']:
        return 10**9
    elif binary_units in ['Ti', 'TiB']:
        return 2**40
    elif binary_units in ['T', 'TB']:
        return 10**12
    elif binary_units in ['Pi', 'PiB']:
        return 2**50
    elif binary_units in ['P', 'PB']:
        return 10**15
    else:
        raise Exception(f"The binary_units \"{binary_units}\" is unknown")


# Calculate values from get_dimtool_values()
def calculate_dimtool(dt_yaml, resources):
    output = {}
    for resource in resources:
        values_sum = 0
        for value in get_dimtool_values(dt_yaml, resource):
            if isinstance(value, numbers.Number) or (isinstance(value, str) and value.strip().replace(".", "").isnumeric()):
                value = float(value)
            else:
                splitted_value = re.split(r'(\d+(\.\d+)?)', value)
                if (len(splitted_value) == 4 and splitted_value[1].isdigit()):
                    numeric_value = float(splitted_value[1])
                    binary_units = splitted_value[3].strip()
                    try:
                        value = numeric_value * getBinaryMultiples(binary_units)
                    except Exception as e:
                        raise Exception(f"Exception during getBinaryMultiples: {e} \n value from yaml: {value}")
                else:
                    raise Exception(f"The value ({value}) is not digit or number with Binary Multiples. e.g.: '5.51Gi'")
            values_sum += value
        if 'memory' in resource.lower():
            output[resource] = values_sum/1024/1024/1024
        else:
            output[resource] = values_sum
    return output


# Compare outputs from calculate_html() and calculate_dimtool()
def compare_outputs(calculated_html, calculated_dimtool):
    exit_code = 0
    for key, value in calculated_html.items():
        if 'cpu' in key.lower() and float(value) < calculated_dimtool['cpu']:
            logging.error(key + ' ' + str(value) + ' less than {}'.format(calculated_dimtool['cpu']))
            exit_code += 10
        elif 'memory' in key.lower() and float(value) < calculated_dimtool['memory']:
            logging.error(key + ' ' + str(value) + ' less than {}'.format(calculated_dimtool['memory']))
            exit_code += 20
    exit(exit_code)


def get_args():
    args_parser = argparse.ArgumentParser(
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description='''\
This script compares free resources from the Product_CI_cluster_infos HTML page with dimtool requests to verify that ProductCI has enough capacity.
As an output, we can get different exit codes:
0 - ProductCI has enough resources
10 - Not enough CPU resources in ProductCI
20 - Not enough Memory resources in ProductCI
30 - Not enough CPU and Memory resources in ProductCI'''
    )
    args_parser.add_argument('-ih', '--input_html',
                             required=False, default='Output.html', help='Path of the html input file')
    args_parser.add_argument('-id', '--input_dimtool',
                             required=False, default='values.yaml', help='Path to the values.yaml generated by the dimtool')
    args_parser.add_argument('-x', '--exclude',
                             required=False, nargs='*', default=['null'], help='Cluster or list of clusters to exclude. Eg.: cluster_productci_appdashboard cluster_productci_2452')
    arguments = args_parser.parse_args()
    return arguments


def main():
    logging.basicConfig(format='[%(asctime)s] %(funcName)-30s %(levelname)-10s  %(message)s', level=logging.INFO)
    args = get_args()
    # cluster-info resources collector
    with open(args.input_html) as f:
        html = f.read()
    attr = 'id'
    attr_value = ['FreeCPU', 'FreeMemory[GB]']
    calculated_html = calculate_html(attr, attr_value, args.exclude, html)
    logging.info('Minimal resources found in ' + args.input_html + ' ' + format(calculated_html))

    # Dimtool output calculator
    with open(args.input_dimtool) as f:
        dt_yaml = yaml.safe_load(f)
    resources = ['cpu', 'memory']
    calculated_dimtool = calculate_dimtool(dt_yaml, resources)
    logging.info('Calculated resources from the dimtool output: {}'.format(calculated_dimtool))

    # Compare outputs
    compare_outputs(calculated_html, calculated_dimtool)


if __name__ == '__main__':
    main()
