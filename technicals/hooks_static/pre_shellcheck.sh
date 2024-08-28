#!/bin/bash

ADP_APP_GIT_REPO=$(git rev-parse --show-toplevel|sed -e 's|^/cygdrive/c/|/|g')
# Select only Added, Copied, Modified, Renamed, and Type changed files
FILES=$(git diff-tree --no-commit-id --name-only -r HEAD --diff-filter=ACMRT)
SHEBANG_PATTERN="^#![[:space:]]*(/usr)?(/bin/env[[:space:]]*)?((/usr)?/bin/|)(sh|bash|ksh|pdksh)([[:space:]]*|$)"

export SHELLCHECK_OPTS="-e SC1090 -e SC1091"

if ! command -v shellcheck >/dev/null 2>&1; then
    echo "ShellCheck is not installed on this computer! ($(hostname))"
    exit 1
else
    status=0
    #TODO  shellcheck maybe disable=SC2236
    if [ -n "${FILES}" ]; then
    #    ^-- SC2236: Use -n instead of ! -z.
        for file in ${FILES}; do
            echo "Execute pre_shellcheck for ${file}"
            if file "${file}" | grep -qw text; then
                first_line="$(head -n 1 "${file}")"
                if [[ $first_line =~ $SHEBANG_PATTERN ]]; then
                    full_path="${ADP_APP_GIT_REPO}/${file}"
                    shellcheck --color=always "${full_path}" || status=1
                fi
            fi
        done
    fi
    exit ${status}
fi
