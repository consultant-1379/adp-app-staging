#!/bin/bash
#set -o errexit
set -x

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --commitid) commitid="$2"; shift ;;
        --changeid) changeid="$2"; shift ;;
        --refspec) refspec="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# If you supply more than one parameter, the priority is as follows:
# 1. refspec
# 2. changeid
# 3. commitid

if [ -n "${refspec}" ]; then
    changenumber=$(echo "$refspec" | awk -F'/' '{print $4}')
    commitid=$(ssh -o StrictHostKeyChecking=no -p "${GERRIT_PORT}" "${GERRIT_HOST}" gerrit query --current-patch-set "$changenumber" | grep revision: | awk '{print $2}' | awk 'NR < 2')
else
    if [ -n "${changeid}" ]; then
        commitid=$(ssh -o StrictHostKeyChecking=no -p "${GERRIT_PORT}" "${GERRIT_HOST}" gerrit query --current-patch-set "$changeid" | grep revision: | awk '{print $2}')
    fi
fi

echo "CommitID: $commitid"

output=$(ssh -o StrictHostKeyChecking=no -p "${GERRIT_PORT}" "${GERRIT_HOST}" gerrit review --rebase "$commitid" 2>&1)
readarray -t arr <<< "$output"
echo "${arr[0]}"

retval=1
if [[ $output == *"Change is already up to date."* ]]; then
    retval=0
fi
if [[ $output == *"Change is already based on the latest patch set of the dependent change."* ]]; then
    retval=0
fi
if [[ $output == "" ]]; then
    retval=0
fi

exit $retval
