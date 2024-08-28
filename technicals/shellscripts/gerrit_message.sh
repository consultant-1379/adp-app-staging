#!/bin/bash
#set -o errexit

refspec=$1
message=$2

changenumber=$(echo "$refspec" | awk -F'/' '{print $4}')
commitid=$(ssh -o StrictHostKeyChecking=no -p "${GERRIT_PORT}" "${GERRIT_HOST}" gerrit query --current-patch-set "$changenumber" | grep revision: | awk '{print $2}' | awk 'NR < 2')

ssh -o StrictHostKeyChecking=no -p "${GERRIT_PORT}" "${GERRIT_HOST}" gerrit review --message "'$message'" "$commitid"

