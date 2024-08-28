#!/usr/bin/env python3
import json
import argparse
import jsonschema

PARSER = argparse.ArgumentParser()
PARSER.add_argument('-c', '--chartname', help='Chart name')
PARSER.add_argument('-cv', '--chartversion', help='Chart version.')
PARSER.add_argument('-t', '--jsontemplate', help='Path to json file template.')
ARGS = PARSER.parse_args()

try:
    CHART_NAME = ARGS.chartname
    CHART_VERSION = ARGS.chartversion
    JSON_TEMPLATE = ARGS.jsontemplate

    ERROR = ""

    if CHART_NAME is None:
        raise Exception('Error: CHART_NAME is missing!')

    elif CHART_VERSION is None:
        raise Exception('Error: CHART_VERSION is missing!')

    if JSON_TEMPLATE is None:
        raise Exception('Error: JSON_TEMPLATE is missing!')

except Exception as err:
    raise Exception(err)


def openFiles():
    f = open('health_api.json')
    jsonData = json.load(f)
    f.close()
    path = JSON_TEMPLATE
    schemaFile = open(path, 'r')
    schema = json.load(schemaFile)
    return jsonData, schema


def validateSchema(jsonData, schema):
    try:
        jsonschema.validate(jsonData, schema)
    except jsonschema.exceptions.ValidationError as err:
        print(f"Error: Given {CHART_NAME}_{CHART_VERSION}_health_api.json is Invalid!")
        raise Exception(err.message)
    print(f"Given {CHART_NAME}_{CHART_VERSION}_health_api.json is Valid!")


def main():
    # Opening JSON file
    jsonData, schema = openFiles()
    # Validate schema
    validateSchema(jsonData, schema)


if __name__ == "__main__":
    main()
