#!/usr/bin/env bash

set -o errexit -o nounset
shopt -s failglob
set -x

script_name=$(basename "$(realpath "$0")")

declare -a WARNING_ONLY=()
declare -a ALL_REPOSITORIES=( "technicals/hooks_static/pre_*" "technicals/hooks/pre_*" )

# Number of mandatory arguments.
margs=2
# Number of sent arguments.
arguments="$#"

USAGE_MESSAGE="
\\n Usage: $script_name -> Mandatory attributes weren't sent!
\\n Example: adp-app-staging/technicals/shellscripts/run_verify_hooks.sh <GERRIT_PATCHSET_REVISION> <BUILD_URL> [WORKSPACE] [technicals/hooks/pre_*]
\\n Note: Number of optional arguments is arbitrary!"

usage() {
    echo -e "$USAGE_MESSAGE"
}

margs_check() {
if [ "$arguments" -lt "$margs" ]; then
  usage
  exit 1
fi
}

margs_check

GERRIT_PATCHSET_REVISION="$1"
BUILD_URL="$2"
declare -a TARGET_REPOSITORIES=()

WORKSPACE=""
shift 2
while (( "$#" )); do
  if [ -z "$WORKSPACE" ]; then
    WORKSPACE="$1/"
    shift
  fi
  TARGET_REPOSITORIES[${#TARGET_REPOSITORIES[@]}]="$WORKSPACE$1"
  shift
done

if [ ${#TARGET_REPOSITORIES[@]} -eq 0 ]; then
  TARGET_REPOSITORIES=("${ALL_REPOSITORIES[*]}")
  cd adp-app-staging
else
  if [ -d "cnint" ]; then
    cd cnint
  else
    cd eea4-rv
  fi
fi

RESULT=0
WARRNING=false

for repository in "${TARGET_REPOSITORIES[@]}"; do
  for hook in $repository; do
    echo -e "[Running] $hook"
    if ! "$hook"; then
      hook_name=$(basename "$hook")
      if [[ "${WARNING_ONLY[*]}" == *"$hook_name"* ]]; then
        echo "WARNING: $hook_name failed!"
        if [ "$WARRNING" = false ] ; then
          "$WORKSPACE"technicals/shellscripts/gerrit_logger.sh "$GERRIT_PATCHSET_REVISION" "$BUILD_URL"
        fi
        WARRNING=true
      else
        RESULT=1
        echo "ERROR: $hook_name failed!"
      fi
    fi
  done
done

echo "$script_name: result = $RESULT"

exit "$RESULT"
