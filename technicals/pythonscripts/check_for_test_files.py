import json
from json import JSONDecodeError
import os
import requests
import argparse
import sys
from time import sleep
import pprint

test_reports = ()


PARSER = argparse.ArgumentParser()
PARSER.add_argument('-u', '--username', help='ARM username if $ARM_USERNAME not set.')
PARSER.add_argument('-p', '--apikey', help='ARM API key if $ARM_API_KEY not set.')
PARSER.add_argument('-url', '--armurl', help='ARM url.')
PARSER.add_argument('-c', '--chartname', help='Chart name')
PARSER.add_argument('-cv', '--chartversion', help='Chart version.')
PARSER.add_argument('-mr', '--armrepository', help='ARM repository.')
PARSER.add_argument('-t', '--jsontemplates', help='Path to json file templates.')
PARSER.add_argument('-fl', '--configfile', help='Config file.')
ARGS = PARSER.parse_args()


try:
    USERNAME = os.getenv('ARM_USERNAME', ARGS.username)
    API_KEY = os.getenv('ARM_API_KEY', ARGS.apikey)
    URL = ARGS.armurl
    CHART_NAME = ARGS.chartname
    CHART_VERSION = ARGS.chartversion
    REPOSITORY = ARGS.armrepository
    build_url = '%s/api/search/aql' % (URL)
    JSON_TEMPLATES = ARGS.jsontemplates
    CONFIG_FILE = ARGS.configfile

    ERROR = False

    def printing_error(arg):
        global ERROR
        ERROR = True
        print(f"Error: {arg} is missing!")

    if USERNAME is None:
        printing_error("USERNAME")

    if API_KEY is None:
        printing_error("API_KEY")

    if URL is None:
        printing_error("URL")

    if CHART_NAME is None:
        printing_error("CHART_NAME")

    if CHART_VERSION is None:
        printing_error("CHART_VERSION")

    if REPOSITORY is None:
        printing_error("REPOSITORY")

    if CONFIG_FILE is None:
        printing_error("CONFIG_FILE")

    if ERROR:
        sys.exit(1)


except Exception as err:
    sys.exit(err)


def get_name_and_path():
    path = f'{CHART_NAME}'
    name = f'{CHART_NAME}_{CHART_VERSION}'
    return path, name


def prepare_load():
    path, name = get_name_and_path()
    test = map(lambda x: name + x, test_reports)
    add_files = list(map(lambda x: '{"name":{"$eq":"' + str(x) + '"}}', test))
    payload = 'items.find({"repo": {"$eq":"' \
              + REPOSITORY + '"},"path": {"$match" : "' \
              + path + '"},"$or": [' \
              + str(', '.join(add_files)) + ']})'
    return payload


def pre_process_json(f):
    out = {}
    nested_tree = []

    def flatten(x, name=None, j=0):
        if type(x) is dict:
            nested_tree.append((x.keys(), j))
            for a in x:
                val = '.'.join((name, a)) if name else a
                flatten(x[a], val, j)
        elif type(x) is list:
            j = j + 1
            for (i, a) in enumerate(x):
                flatten(a, name + f'[{str(i)}]', j)
        else:
            out[name] = x if x else ""
    flatten(f)
    return out, nested_tree


def compare(dict1, dict2):
    _, nested_tree1 = pre_process_json(dict1)
    _, nested_tree2 = pre_process_json(dict2)
    diff = []

    def check_for_detail(dict_key):
        lst = list(filter(lambda x: x if x[1] == dict_key[1] else None, nested_tree1))[0]
        str = f"The key/s found is: {set(dict_key[0])}"
        str = str + f"\nThe key/s at depth {dict_key[1]} should look like this: {set(lst[0])}"
        template = set(lst[0]) - set(dict_key[0])
        if (len(template) == 0):
            return
        arm_data = set(dict_key[0]) - set(lst[0])
        arm_data = arm_data if len(arm_data) else "missing!"
        str = str + f"\nTEMPLATE: {template}\nARM DATA: {arm_data}\n"
        diff.append(str)

    for dict_key in nested_tree2:
        if dict_key not in nested_tree1:
            check_for_detail(dict_key)
    return True if len(diff) else False, diff


def get_content_and_compare(dict, json_name):
    print(f"\nChecking the structure of {json_name}....(IN PROGRESS)")
    path, name = get_name_and_path()
    name = f'{name}_{json_name}'
    url = f'{URL}/{REPOSITORY}/{path}/{name}'
    sleep(1)
    try:
        r = requests.get(url, auth=(USERNAME, API_KEY))
    except requests.exceptions.HTTPError as err:
        sys.exit(err.response.text)
    content = r.content.decode('utf8')
    try:
        dict_arm = json.loads(content)
    except JSONDecodeError as err:
        sys.exit(err)
    bool, diff = compare(dict, dict_arm)
    if bool:
        dict_arm, _ = pre_process_json(dict_arm)
        if 'errors[0].status' in dict_arm.keys() or 'errors[0].message' in dict_arm.keys():
            print(f"ERROR: {dict_arm}.")
            print("ERROR: Checking the structure is done....(NOT OK)\n")
        else:
            print(f"ERROR: The comparison failed!")
            for result in diff:
                print(result)
            print(f"ERROR: The whole structure should look like:\n")
            pprint.pprint(dict)
            print("\nERROR: Checking the structure is done....(NOT OK)")
        global ERROR
        ERROR = True
    else:
        print("Checking the structure is done....(OK)")
        return


def check_for_structure(structure_reports):
    for j_file in structure_reports:
        with open(JSON_TEMPLATES + j_file[1:]) as f:
            json_name = os.path.basename(f.name)
            dict1 = json.load(f)
        get_content_and_compare(dict1, json_name)


def search_for_files():
    print("Searching for files....(IN PROGRESS)")
    payload = prepare_load()
    sleep(1)
    try:
        r = requests.post(build_url, data=payload, auth=(USERNAME, API_KEY))
    except requests.exceptions.HTTPError as err:
        sys.exit(f"ERROR: {err.response.text}")
    content = r.content.decode('utf8').replace("'", '"')
    counted_files = json.loads(content)
    print(f"Counted: {counted_files['range']['total']}")
    print(f"Expected: {len(test_reports)}")
    if (counted_files['range']['total'] != len(test_reports)):
        existing_files = []
        _, name = get_name_and_path()
        files_concat = list(map(lambda x: name + x, test_reports))
        temporary_file, _ = pre_process_json(counted_files)
        for i in range(counted_files['range']['total']):
            existing_files.append(temporary_file[f'results[{i}].name'])
        print(f"ERROR: The following {', '.join(files_concat)} should be stored in the repository.")
        print(f"ERROR: File/s in the repository: {', '.join(existing_files)}.")
        print(f"ERROR: Missing file/s: {', '.join(list(set(files_concat) - set(existing_files)))}.")
        print("ERROR: Searching for files is done....(NOT OK)")
        global ERROR
        ERROR = True
    else:
        print("Searching for files is done....(OK)")
        return


def main():
    global test_reports
    it = iter("".join(c for c in CONFIG_FILE if c not in "()[] ").split(","))
    CONFIG_FILE_LIST = [(x, eval(y), eval(z)) for x, y, z in zip(it, it, it)]
    existance_check_filtered = filter(lambda x: x if x[1] else None, CONFIG_FILE_LIST)
    test_reports = list(zip(*existance_check_filtered))[0]
    structure_check_filtered = filter(lambda x: x if x[1] and x[2] else None, CONFIG_FILE_LIST)
    structure_reports = list(zip(*structure_check_filtered))[0]
    search_for_files()
    if len(structure_reports) > 0:
        check_for_structure(structure_reports)
    if ERROR:
        sys.exit(1)


if __name__ == "__main__":
    main()
