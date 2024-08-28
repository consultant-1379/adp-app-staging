#!/usr/bin/env python3
import json
import argparse
import jsonschema
import requests
import os

PARSER = argparse.ArgumentParser()
PARSER.add_argument('-u', '--username', help='ARM username if $ARM_USERNAME not set.')
PARSER.add_argument('-p', '--apikey', help='ARM API key if $ARM_API_KEY not set.')
PARSER.add_argument('-c', '--chartname', help='Chart name')
PARSER.add_argument('-cv', '--chartversion', help='Chart version.')
PARSER.add_argument('-t', '--jsontemplates', help='Path to json file templates.')
PARSER.add_argument('-ni', '--nointegrationlevel', help='Microservices without integration test reports.')
PARSER.add_argument('-nc', '--nocomponentlevel', help='Microservices without component test reports.')
PARSER.add_argument('-nu', '--noupgradelevel', help='Microservices without upgrade test reports.')
ARGS = PARSER.parse_args()

# python3 sonar.py -c 'dummy' -cv '1_1' -t 'templates/' -m 70

try:
    USERNAME = os.getenv('ARM_USERNAME', ARGS.username)
    API_KEY = os.getenv('ARM_API_KEY', ARGS.apikey)
    CHART_NAME = ARGS.chartname
    CHART_VERSION = ARGS.chartversion
    JSON_TEMPLATES = ARGS.jsontemplates
    NO_INTEGRATION_LEVEL = ARGS.nointegrationlevel
    NO_COMPONENT_LEVEL = ARGS.nocomponentlevel
    NO_UPGRADE_LEVEL = ARGS.noupgradelevel

    ERROR = ""
    if USERNAME is None:
        raise Exception('Error: USERNAME is missing!')

    if API_KEY is None:
        raise Exception('Error: API_KEY is missing!')

    if CHART_NAME is None:
        raise Exception('Error: CHART_NAME is missing!')

    elif CHART_VERSION is None:
        raise Exception('Error: CHART_VERSION is missing!')

except Exception as err:
    raise Exception(err)


def openFiles():
    f = open(CHART_NAME + "_" + CHART_VERSION + '_test_results.json')
    jsonData = json.load(f)
    f.close()
    path = JSON_TEMPLATES + 'test_report.json'
    print(path)
    schemaFile = open(path, 'r')
    print(schemaFile)
    schema = json.load(schemaFile)
    return jsonData, schema


def validateSchema(jsonData, schema):
    try:
        jsonschema.validate(jsonData, schema)
    except jsonschema.exceptions.ValidationError as err:
        print("Error: Given JSON data is Invalid!")
        raise Exception(err.message)

    print(jsonData)
    print("Given JSON data is Valid!")


def compareTestLevelsWithoutLevels(optionalTestLevels):
    with open(JSON_TEMPLATES + 'test_report.json', "r") as schemacontent:
        testreport = json.load(schemacontent)
        for examples in testreport['examples']:
            print("examples:", examples)
            for schematestlevels in examples['artifactsKey']:
                print("testLevelTypes:", schematestlevels['testLevel'])
                testLevelTypes = schematestlevels['testLevel'].split('|')
                print(testLevelTypes)

    with open(CHART_NAME + "_" + CHART_VERSION + '_test_results.json', "r") as content:
        testresult = json.load(content)
        for testlevels in testresult['artifactsKey']:
            print("testLevel:", testlevels['testLevel'])
            reportTestLevels = testlevels['testLevel']
            if reportTestLevels in testLevelTypes:
                print("OK")
                testLevelTypes.remove(reportTestLevels)
        missingTestLevel = [""]
        message = ""
        for testLevelType in testLevelTypes:
            if testLevelType not in optionalTestLevels:
                missingTestLevel.append(testLevelType)
                print(*missingTestLevel)
        if len(missingTestLevel) != 1:
            raise Exception('Error: Test level: "' + message.join(map(str, missingTestLevel)) + '" is missing!')


def validateURL():
    with open(CHART_NAME + "_" + CHART_VERSION + '_test_results.json', "r") as urlcontent:
        testresult = json.load(urlcontent)
        for artifacturl in testresult['artifactsKey']:
            print("Artifact URL:", artifacturl['artifactLink'])
            r = requests.get(artifacturl['artifactLink'], auth=(USERNAME, API_KEY))
            if r.status_code < 400:
                print("Valid Artifact URL!")
            else:
                raise Exception('Error: Invalid Artifact URL!')


def main():
    # Opening JSON file
    jsonData, schema = openFiles()
    # Validate schema
    validateSchema(jsonData, schema)
    optionalTestLevels = ['contract']

    if NO_INTEGRATION_LEVEL is not None and NO_COMPONENT_LEVEL is None:
        optionalTestLevels.append('integration')

    if NO_COMPONENT_LEVEL is not None and NO_INTEGRATION_LEVEL is None:
        optionalTestLevels.append('component')

    if NO_UPGRADE_LEVEL is not None:
        optionalTestLevels.append('upgrade')

    compareTestLevelsWithoutLevels(optionalTestLevels)

    validateURL()


if __name__ == "__main__":
    main()
