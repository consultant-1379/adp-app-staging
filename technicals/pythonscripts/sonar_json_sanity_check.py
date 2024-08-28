#!/usr/bin/env python3
import os
import json
import argparse
import jsonschema

PARSER = argparse.ArgumentParser()
PARSER.add_argument('-c', '--chartname', help='Chart name')
PARSER.add_argument('-cv', '--chartversion', help='Chart version.')
PARSER.add_argument('-t', '--jsontemplates', help='Path to json file templates.')
PARSER.add_argument('-m', '--mincoverage', help='Minimum value for test coverage.')
PARSER.add_argument('-r', '--reportfilename', help='Report file name')
ARGS = PARSER.parse_args()
# python3 sonar.py -c 'dummy' -cv '1_1' -t 'templates/' -m 70
try:
    CHART_NAME = ARGS.chartname
    CHART_VERSION = ARGS.chartversion
    JSON_TEMPLATES = ARGS.jsontemplates
    MIN_COVERAGE = ARGS.mincoverage

    ERROR = ""

    if CHART_NAME is None:
        raise Exception('Error: CHART_NAME is missing!')

    elif CHART_VERSION is None:
        raise Exception('Error: CHART_VERSION is missing!')

    elif MIN_COVERAGE is None:
        raise Exception('Error: MIN_COVERAGE is missing!')

    REPORT_FILE_NAME = ARGS.reportfilename or (CHART_NAME + "_" + CHART_VERSION + '_sonarqube_report.json')
    if not os.path.exists(REPORT_FILE_NAME):
        raise Exception(f'Error: REPORT_FILE_NAME: {REPORT_FILE_NAME} does not exists!')

except Exception as err:
    raise Exception(err)


def openFiles():
    f = open(REPORT_FILE_NAME)
    jsonData = json.load(f)
    f.close()
    path = JSON_TEMPLATES + 'sonarqube_schema.json'
    print(path)
    schemaFile = open(path, 'r')
    print(schemaFile)
    schema = json.load(schemaFile)
    return jsonData, schema


def validateSchema(jsonData, schema):
    try:
        jsonschema.validate(jsonData, schema)
    except jsonschema.exceptions.ValidationError as err:
        raise Exception(err.message)

    print(jsonData)
    print("Given JSON data is Valid")


def main():
    # Opening JSON file
    jsonData, schema = openFiles()
    # validate schema
    validateSchema(jsonData, schema)
    # Validate coverageA
    for json_dict in jsonData['projectStatus']['conditions']:
        if json_dict['metricKey'] == 'coverage':
            try:
                percent = float(json_dict['actualValue'])
                percent_min = float(MIN_COVERAGE)
            except ValueError as err:
                raise Exception(err)
            if percent < percent_min:
                raise Exception('Coverage percent value: '+str(percent)+' less then required :'+MIN_COVERAGE)
            else:
                print('Coverage percent value: '+str(percent)+' reach the required :'+MIN_COVERAGE)


if __name__ == "__main__":
    main()
