#!/usr/bin/env bash

declare -a microservices
microservices=( "eric-eea-fh-rest2kafka-proxy-drop" "eric-eea-analytical-processing-database-drop" "eric-eea-db-manager-drop" "eric-csm-parser-drop" "eric-csm-st-drop" "eric-eea-stream-aggregator-drop" "eric-eea-correlator-drop" "eric-eea-db-loader-drop" "eric-eea-stream-exporter-drop" )

echo "**Table of contents:**"
echo "<!-- START doctoc -->"
echo "..."
echo "END doctoc -->"
echo ""
echo "## EEA microservices status in EEA Product CI"
echo ""
echo "| EEA microservice | Status |"
echo "|------------ | ------------- | ------------- |"
for ms in "${microservices[@]}"
do
   result=$(spin pipeline executions list -i be1e2288-295f-47eb-a1cf-48ba4b2fdb96 | jq '.[] | select(.trigger.parentExecution.name | contains ("")) | {parent: .trigger.parentExecution.name, status: .status}' | tail -n 2 | head -n 1 | awk -F':' '{print $2}')
   if [[ "$result" == " \"TERMINAL\"" ]]; then
       echo "| $ms | FAILURE |"
   else
       echo "| $ms | SUCCESS |"
   fi
done
