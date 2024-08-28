import sys
import os
import argparse


PARSER = argparse.ArgumentParser()
PARSER.add_argument('-e', '--exception_list', help='CSAR exception list file')
PARSER.add_argument('-o', '--custom_yaml', help='Filename to output processed custom yaml file')
ARGS = PARSER.parse_args()

try:
    EXCEPTION_LIST_FILE = ARGS.exception_list
    CUSTOM_YAML = ARGS.custom_yaml

    ERROR = False

    def printing_error(arg):
        global ERROR
        ERROR = True
        print(f"Error: {arg} is missing!")

    if EXCEPTION_LIST_FILE is None:
        printing_error("EXCEPTION_LIST_FILE")

    if CUSTOM_YAML is None:
        printing_error("CUSTOM_YAML")

    if ERROR:
        sys.exit(1)

except Exception as err:
    sys.exit(err)


def main():
    my_file = open(EXCEPTION_LIST_FILE, "r")
    content = my_file.read()
    exception_list = content.splitlines()
    #  remove the output file if exists - i.e. from previous workspace if it was not deleted
    if os.path.exists(CUSTOM_YAML):
        os.remove(CUSTOM_YAML)
    for line in exception_list:
        with open(CUSTOM_YAML, 'a') as fileout:
            fileout.write(line + ':\n  enabled: false' '\n\n')


if __name__ == "__main__":
    main()
