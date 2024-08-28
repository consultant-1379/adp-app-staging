#!/bin/bash
set -o errexit
set -x
# Parsing arguments

REPO_PATH=${1}
# shellcheck disable=SC2086
mapfile -t array < <( git diff-tree --no-commit-id --name-only -r HEAD --diff-filter=ACMRT -- pipelines/**/**  )

echo "${array[@]}"

function add_to_array(){
    local arr="$1"
    local value="$2"
    local element_not_exist='true'
    for element in "${!arr}";
    do
        if [[ $element == "$value" ]];
        then
            element_not_exist='false'
            break
        fi
    done
    if [[ $element_not_exist ]];
    then
        arr+=( "$value" )
    fi
    echo "${arr[@]}"
}


jobNames=""
for file in "${array[@]}"
do
    groovyList=""
    if  [[ $file == *"Jenkinsfile" ]]
    then
        # shellcheck disable=SC2086
        mapfile -t resultArray < <(cd ${REPO_PATH} && grep "${file}"  --include=\*.groovy -l -r ./jobs/)
        for element in "${resultArray[@]}"
        do
            echo "${element}"
             groovyList=$(add_to_array "${groovyList[@]}" "${element}")
        done
   fi

    for groovyFile in "${groovyList[@]}"
    do
        #if jobs name stored in enum second awk need  -F'[.name]' '{print $1 " " }'
        # shellcheck disable=SC2086
        mapfile -t names < <(cd ${REPO_PATH} && grep "pipelineJob" ${groovyFile} | awk  -F"[']" '{print $2 }')
        for name in "${names[@]}"
        do
            if [[ ! ${name} == "" ]]
            then
                if [[ ${jobNames} == "" ]]
                then
                    jobNames="${name}"
                else
                    jobNames="$(add_to_array "${jobNames[@]}" "${name}" )"
                fi
            fi
        done
    done
done

cat > env_inject << EOF
${jobNames[@]}
EOF

cat > env_inject_dsl << EOF
JOB_NAMES=${jobNames[@]}
EOF
