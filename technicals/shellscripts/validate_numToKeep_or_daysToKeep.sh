#!/usr/bin/env bash

validatedFile=$1

daysToKeepMaxValue=30
numToKeepMaxValue=60

if ! grep -q '\<daysToKeepStr\>\|\<numToKeepStr\>' "${validatedFile}"
then
  echo "daysToKeepStr or numToKeepStr is missing from file "
  exit 1
else
  if grep -q '\<daysToKeepStr\>' "${validatedFile}"
  then
    daysToKeepValue=$(grep '\<daysToKeepStr\>' "${validatedFile}" | awk -F'daysToKeepStr' '{print $2}'  | awk -F[\'\"] '{print $2}')
    if (( daysToKeepValue < 1 ))
    then
      echo "ERROR: daysToKeepValue:${daysToKeepValue}  lesser than 1"
      exit 1
    fi
    if (( daysToKeepValue > daysToKeepMaxValue ))
    then
      echo "ERROR: daysToKeepValue:${daysToKeepValue}  greater than ${daysToKeepMaxValue}"
      exit 1
    fi

  fi

  if grep -q '\<numToKeepStr\>' "${validatedFile}"
  then
    numToKeepValue=$(grep '\<numToKeepStr\>' "${validatedFile}" | awk -F'numToKeepStr' '{print $2}'  | awk -F[\'\"] '{print $2}')
    if (( numToKeepValue < 1 ))
    then
      echo "ERROR: numToKeepValue:${numToKeepValue} lesser than 1"
      exit 1
    fi
    if (( numToKeepValue > numToKeepMaxValue ))
    then
      echo "ERROR: numToKeepValue:${numToKeepValue} greater than ${numToKeepMaxValue}"
      exit 1
    fi

  fi
fi
exit 0
