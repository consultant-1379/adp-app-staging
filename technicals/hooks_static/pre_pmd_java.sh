#!/bin/bash

FLD_GIT_REPO=$(git rev-parse --show-toplevel)
# Select only Added, Copied, Modified, Renamed, and Type changed files
FILES=$(git diff-tree --no-commit-id --name-only -r HEAD --diff-filter=ACMRT | grep "\\.java$")

if ! command -v "$FLD_GIT_REPO/code-qa/pmd/pmd.sh" >/dev/null 2>&1; then
  echo "pmd.sh is not installed on this computer! ($(hostname))"
  exit 0
else
  status=0
  if [ -n "${FILES}" ]; then
    for file in ${FILES}; do
      echo "Execute pre_pmd_java for ${file}"
#      full_path="${FLD_GIT_REPO}/${file}"
      "$FLD_GIT_REPO/code-qa/pmd/pmd.sh" text "${file}" java ALL | uniq || status=1
    done
  fi
#  exit $status
  echo "status=$status"
  exit 0
fi
