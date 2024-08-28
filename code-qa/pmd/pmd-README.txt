PMD - An extensible cross-language static code analyzer.

https://pmd.github.io/

https://sourceforge.net/projects/pmd/files/pmd/5.8.1/
https://github.com/pmd/pmd/tree/pmd/5.8.x


PMD is assumed to be installed in /opt as follows:
# cd /opt/
# unzip /root/pmd-bin-5.8.1.zip
# ln -s pmd-bin-5.8.1 pmd

###########################################################
Files description:
###########################################################
pmd.sh - wrapper to run PMD on folders or files
    4 arguments are expected FORMAT FILE|FOLDER LANGUAGE RULESETs

###########################################################
ci/hooks/pre-pmd-java
- uses pmd.sh for Select only Added, Copied, Modified, Renamed, and Type changed files


###########################################################
pmd-all-java.sh
- can be run from any folder in repo, creates reports about all the java files in repo

###########################################################
pmd-all-java-all-formats-all-rulesets-in-one-report.sh
pmd-all-java-all-formats-all-rulesets-in-one-report-2files-example.sh
pmd-all-java-all-formats-single-rulesets.sh
pmd-all-java-all-formats-single-rulesets-2files-example.sh
- examples of usage of PMD via pmd.sh
- the scripts create reports for java files in ans repo
- assumed to be run in folder ci/code-qa/pmd
###########################################################
pmd-test-all.sh
- runs 4 scripts above
- assumed to be run in folder ci/code-qa/pmd
- reports are zipped into /tmp


###########################################################
pmd-formats-ALL.txt
- supported report formats

###########################################################
pmd-formats.txt
- formats to be used by scripts: pmd-all-java-all-formats-all-rulesets-in-one-report.sh, etc.

###########################################################
pmd-rulesets-ALL.txt
- all PMD supported rulesets

###########################################################
pmd-rulesets.txt
- rulesets to be used by 4 scripts above

###########################################################
pmd-filetypes.txt
- list of supported files by PMD:
java
ecmascript
JavaScript
jsp
plsql
vm
xml
xsl
