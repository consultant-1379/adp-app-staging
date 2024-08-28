#!/usr/bin/env bash

script_name=$(basename "$(realpath "$0")")

help() {
    while [ $# -gt 0 ]
    do
        if [ "$1" = "-h" ] || [ "$1" = "--help" ]
        then
            cat <<EOM
========================================================================================================================
The $script_name creates a .csv file with release content.
It will be used by the Release Team for double check the release content.

The input parameter is the EEA helm chart .tgz file (the path to the EEA helm chart .tgz file).
       e.g.
       eric-eea-int-helm-chart-0.0.0-86.tgz (folder1/folder2/eric-eea-int-helm-chart-0.0.0-86.tgz)

The .csv file name will be created from the .tgz file name.
       e.g.
       .tgz file name = eric-eea-int-helm-chart-0.0.0-86.tgz
       .csv file name = eric-eea-int-helm-chart-0.0.0-86.csv

The .csv file will be created in the same folder as the .tgz file and will contain the following information:
- microservice name of each microservice contained in the EEA helm chart
- microservice version of each microservice contained in the EEA helm chart
       e.g.
       name: eric-adp-test-app
       version: 1.0.0-47
       name: eric-pm-server
       version: 2.4.0-3
       name: eric-fh-alarm-handler
       version: 4.0.0-17
========================================================================================================================
EOM
            exit 0
        fi
        shift
    done
}

help "$@"

usage() {
    echo -e "\\n Usage: $script_name
            \\n Example of a correct script call: $script_name <TGZ_FILE_PATH>
            \\n <TGZ_FILE_PATH> - path to the EEA helm chart .tgz file"
}

# Checks if input parameter is set.
[ $# -ne 1 ] && {
  usage
  exit 1
}

ERIC_EEA_INT_HELM_CHART=$1

# Checks if the .tgz file is set as input parameter.
if ! echo "$ERIC_EEA_INT_HELM_CHART" | grep -q ".*\.tgz$"; then
  usage
  exit 1
fi

# List of microservice Chart.yaml files.
MICROSERVICE_LIST=$(tar -tzf "$ERIC_EEA_INT_HELM_CHART" | grep -E "eric-eea-int-helm-chart/charts/.*/Chart.yaml")

# Creates a .csv file name from the .tgz file name.
CSV_FILE_NAME="${ERIC_EEA_INT_HELM_CHART/%tgz/csv}"

# Fills in the .csv file with the name and version of each microservice.
for file in ${MICROSERVICE_LIST};
 do
  while IFS= read -r line
   do
    echo "$line" | grep -oP "^(name|version):.*" >> "$CSV_FILE_NAME"
   done <"$file"
 done

exit 0