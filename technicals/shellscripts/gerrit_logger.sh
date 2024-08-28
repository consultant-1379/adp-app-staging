#!/usr/bin/env bash
set -x

PATCHSET=$1
BUILD_URL=$2
echo "Gerrit patchset revision: $PATCHSET, build url: $BUILD_URL"
#MESSAGE="Please check ${BUILD_URL}, you have warnings"
#shall we use the latest patchset or not
if [ $# -ne 3 ]; then
  MESSAGE="Please check ${BUILD_URL}, you have warnings"
else
  MESSAGE="This is test commit message for test-seed job!"
fi
if [[ "$PATCHSET" == *,* ]]
then
    git_id=$PATCHSET
    echo "Git_id: $git_id"
else
    git_id=$(ssh -p "${GERRIT_PORT}" "${GERRIT_HOST}" gerrit query --current-patch-set \""${PATCHSET}"\" | grep revision | awk '{print $2}')
    echo "Git_id from ssh: $git_id"
fi
if [ x"$git_id" == "x" ]
then
    echo "There is no valid gerrit change found, exiting ..."
    #exit 1
fi
ssh -p "${GERRIT_PORT}" "${GERRIT_HOST}" gerrit review --message \""${MESSAGE}"\" --notify OWNER "$git_id"