#!/bin/bash

REPO_PATH=${1}
# shellcheck disable=SC2086
mapfile -t array < ${WORKSPACE}/env_inject

echo "Checking the following jobs:"
printf "%s\n" "${array[@]}"

RESULT=0
for groovyFile in "${array[@]}"
do
    if [[ $groovyFile == *"groovy" ]]
    then
        # shellcheck disable=SC2086
        mapfile -t resultArray < <(grep "scriptPath" ${groovyFile} | awk -F"[']" '{print $2 }')
        for scriptPath in "${resultArray[@]}"
        do
            if ! test -f "${WORKSPACE}/${REPO_PATH}/${scriptPath}"
            then
                echo "Pipeline script for ${groovyFile} cannot be found at ${REPO_PATH}/${scriptPath}" >> err_inject
                RESULT=2
            fi
        done
    fi
done

exit ${RESULT}
