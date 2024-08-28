#!/bin/bash
set -o errexit
set -x
## forked by egertam @1587382261

script_name=$(basename "$(realpath "$0")")

CREATE="CREATE"
DELETE="DELETE"

declare -a ALLOWED_ACTIONS=("$CREATE" "$DELETE")

usage() {
    echo -e "\\n Usage: $script_name -> $1
            \\n Example of a correct script call: $script_name <BRANCH_NAME> <ACTION>
            \\n <BRANCH_NAME> - the branch name
            \\n <ACTION> - Possible values:
            \\n                           $CREATE - branch will be created
            \\n                           $DELETE - branch will be deleted"
}

# check number of positional parameters
[ $# -ne 2 ] && {
    usage "Mandatory attributes weren't sent!"
    exit 2
}

action=$2

# check if second parameter is correctly set
[[ "${ALLOWED_ACTIONS[*]}" == *"$action"* ]] || {
    usage "Input attributes weren't set correctly!"
    exit 2
}

# access parameters
repoName=$(basename "$(git rev-parse --show-toplevel)")
branchName=$1 # prod-ci-test
pushUrl="https://${ECEAGIT_TOKEN}@${GERRIT_HOST}/a/EEA/$repoName.git"

# check remote for branch
branchExists=$(git ls-remote --heads "$pushUrl" "$branchName" | wc -l)
if [ "$branchExists" -gt 0 ]
then
    echo Branch "$branchName" already exists in repo "$repoName"
     [[ "$action" == "$CREATE" ]] && exit 1
     # Delete test branch
     git push "$pushUrl" --delete "$branchName"
     exit 0
# branch not found, check local repository for last commit
elif [[ $(git log --format='%h' -n 1) ]]
then
    echo Branch "$branchName" does not exist in repo "$repoName"
    [[ "$action" == "$DELETE" ]] && exit 1
    # commit found
    baseCommit=$(git log --format='%h' -n 1 2>/dev/null)
    echo base commit is "$baseCommit"
    # Create test branch
    git push "$pushUrl" "$baseCommit:refs/heads/$branchName"
    exit 0
else
    # no commit found, bail out
    echo Could not find base commit: "$PWD" not a git repository?
    exit 1
fi