#!/bin/bash
set -o errexit
#set -x

# Requires Spin CLI set up, as it calls 'spin' to update configuration on Spinnaker.

arr=( "$@" )

echo "Trying to update pipelines from saved json configuration files..."
for PIPELINE_NAME in "${arr[@]}"
do
    echo "...updating $PIPELINE_NAME..."
    spin pipeline save -f "${PIPELINE_NAME}.json"
done
