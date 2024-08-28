#!/bin/bash
set -x

git diff --name-only HEAD HEAD~1 > changed_files.txt
grep -E "ruleset2.0.yaml|bob-rulesets/" < changed_files.txt
ruleset_changed=$?
if [ 0 -eq $ruleset_changed ]; then
    grep -v -E "ruleset2.0.yaml|bob-rulesets/" < changed_files.txt
    other_file_changed=$?
    if [ 1 -eq $other_file_changed ]; then
        echo "Only the ruleset2.0.yaml or bob-rulesets/* file was changed, OK"
        exit 0
    else
        echo "If the ruleset2.0.yaml or bob-rulesets/* are changed in the patchset, changes to other files are not allowed. Please split the commit."
        exit 2
    fi
else
    echo "ruleset2.0.yaml or bob-rulesets/* weren't changed, OK"
    exit 0
fi
