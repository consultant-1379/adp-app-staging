#!/bin/bash
set -o errexit
set -x

CHANGE=$(git diff-tree --no-commit-id --name-only -r HEAD --diff-filter=ACMRT)
echo "$CHANGE"
for file in $CHANGE; do
    if [[ $file == *.Jenkinsfile ]]
    then
        ssh -p 38239 localhost declarative-linter < "$file"
        #wget --no-check-certificate https://sekalx395.epk.ericsson.se:8443/jnlpJars/jenkins-cli.jar
        #java -jar jenkins-cli.jar -noCertificateCheck -auth @/home/eceaproj/secret_file.txt -s  https://sekalx395.epk.ericsson.se:8443/ declarative-linter < "$file"
    fi
done
