#!/bin/bash

ADP_APP_GIT_REPO=$(git rev-parse --show-toplevel)
FLAKE8_CONFIG="$(dirname "$0")/resources/flake8_config.ini"
command -v flake8 >/dev/null 2>&1
flake8_exists=$?

if [ ${flake8_exists} -ne 0 ]; then
  echo "Flake8 is not installed on this computer! ($(hostname))"
  exit 1
else
  status=0
  # Select only Added, Copied, Modified, Renamed, and Type changed files
  files=$(git diff-tree --no-commit-id --name-only -r HEAD --diff-filter=ACMRT )

  for file in ${files}
  do
    echo "Execute pre_flake8 for ${file}"
    ISPY=0
    shebang=$(head -n 1 "$file" | grep -e '^#!.*/python.*$')
    if [ ! "_$shebang" == "_" ]; then
      ISPY=1
    fi
    extpy=$(echo "$file"| sed -e 's|^.*\.py$||g' -e 's|^.*\.PY$||g')
    if [ "_$extpy" == "_" ]; then
      ISPY=1
    fi


    full_path="${ADP_APP_GIT_REPO}/${file}"
    if [ "_$ISPY" == "_1" ]; then
      echo "flake8:$ISPY:$file"
      flake8 --config="${FLAKE8_CONFIG}" "${full_path}" || status=1
    fi
  done
  exit $status
fi
