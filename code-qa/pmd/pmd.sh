#!/bin/bash

# PMD - An extensible cross-language static code analyzer.
# https://pmd.github.io/
#
# This is wrapper for PMD installed in /opt/pmd
#    - 4 arguments are expected FORMAT FILE|FOLDER LANGUAGE RULESET
#
# stanislav.kaleta@ericsson.com

BINPMD=/opt/pmd/bin/run.sh
MYPWD=$PWD
#FLDBASE=$(echo "$0" | rev | cut --complement -d / -f 1 | rev )
FLDBASE=$(dirname "$0")

usage() {
    echo "usage: $0 format file language rules

supported formats:
csv
emacs
html
ideaj
summaryhtml
text
textcolor
textpad
vbhtml
xml
xslt
yahtml

supported languages/filetypes:
java
ecmascript
JavaScript
jsp
plsql
vm
xml
xsl

supported rulesets:
basic
braces
clone
codesize
comments
controversial
coupling
design
empty
finalizers
imports
j2ee
javabeans
junit
logging-jakarta-commons
logging-java
metrics
migrating
migrating_to_13
migrating_to_14
migrating_to_15
migrating_to_junit4
naming
optimizations
strictexception
strings
sunsecure
typeresolution
unnecessary
unusedcode
(android is not supported)
"
    exit 0
}

[ "_$1" == "_" ] && usage
[ "_$2" == "_" ] && usage
[ "_$3" == "_" ] && usage
[ "_$4" == "_" ] && usage

FORMAT=$1
FILE=$2
LANGUAGE=$3
RULESET=$4

cd "$FLDBASE" || exit
command -v "$BINPMD" >/dev/null 2>&1
pmd_exists=$?

if [ ${pmd_exists} -ne 0 ]; then
  echo "PMD is not installed on this computer! ($(hostname))"
  cd "$MYPWD" || exit
  exit 0
else
#  status=0
  if [ "_$RULESET" == "_ALL" ]; then
    RULESET="$( tr "\\n" "," < pmd-rulesets.txt | sed -e 's|,$||g' )"
  fi

  RULESETNEW=$(echo "$RULESET"| sed -e "s|^|$LANGUAGE-|g" -e "s|,|,$LANGUAGE-|g")
#  echo "\"$BINPMD\" pmd -d \"$FILE\" -f "$FORMAT" -R $RULESET"

  cd "$MYPWD" || exit

  echo "Running PMD ..."
  echo " please use comments for feedback: https://eteamspace.internal.ericsson.com/display/ECISE/CLT+-+PMD+-+Java+Source+code+analyzer+rule+set"
  echo "RULESETs=$RULESETNEW"
  "$BINPMD" pmd -d "$FILE" -f "$FORMAT" -R "$RULESETNEW" 2>&1
  result=$?
fi

echo "result=$result"
cd "$MYPWD" || exit
#exit $result
exit 0
