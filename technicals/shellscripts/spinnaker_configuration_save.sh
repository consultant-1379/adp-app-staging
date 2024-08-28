#!/bin/bash
set -o errexit
#set -x

# Requires Spin CLI set up, as it calls 'spin' to save configuration data.

CONFIG=${1}
APPLICATION_NAME="eea"
shift
arr=( "$@" )

echo "Trying to save pipeline configurations into json files."
for PIPELINE_NAME in "${arr[@]}"
do
    echo "...saving $PIPELINE_NAME..."
    spin pipeline get -a ${APPLICATION_NAME} -n "${PIPELINE_NAME}" --config "${CONFIG}" > "${PIPELINE_NAME}.json"
done
