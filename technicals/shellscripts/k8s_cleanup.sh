#!/bin/bash
# shellcheck disable=SC2086,SC2046,SC2125

set -x

SCRIPT_NAME=$(basename "$(realpath "$0")")

usage(){
  echo -e "
  Usage of the ${SCRIPT_NAME} script:
    \\n Example of a correct script call: $0 [[--k8_namespace|-k] <k8_namespace>] [--help|-h]
    \\n <K8_NAMESPACE> - kubernetes namespace where EEA4 core product installed. Example: eric-eea-ns
  "
}

while [ $# -gt 0 ]; do
  case "$1" in
    --k8_namespace*|-k*)
      if [[ "$1" != *=* ]]; then shift; fi # Value is next arg if no `=`
      K8_NAMESPACE="${1#*=}"
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      >&2 printf "Error: Invalid argument\\n"
      exit 1
      ;;
  esac
  shift
done

SEP_CHART_NAME=eric-cs-storage-encryption-provider
SEP_POD_NAME=eric-cs-storage-encryption-provider
AGGREGATOR_DRIVER=eric-eea-stream-aggregator-.*-driver
AGGREGATOR_PROCESSOR_CONFIG=processorconfigs.streamaggregator.eea.ericsson.com
CHART_TIMEOUT=2000s;
POD_TIMEOUT=600s;

helm version;

if [[ $(kubectl get ns | grep -c $K8_NAMESPACE) -ne 1 ]]; then
  echo "No $K8_NAMESPACE namespace..."
  exit 0;
fi

if [[ $(kubectl --namespace $K8_NAMESPACE get pod | grep -c $AGGREGATOR_DRIVER) -gt 0 ]]; then
  KUBE_EDITOR="sed -i 's/isActive: true/isActive: false/g'" kubectl --namespace $K8_NAMESPACE edit $AGGREGATOR_PROCESSOR_CONFIG;
  kubectl --namespace $K8_NAMESPACE wait pod $(kubectl --namespace $K8_NAMESPACE get pod | grep $AGGREGATOR_DRIVER | awk '{print $1}') --for=delete --timeout=$POD_TIMEOUT;
else
  echo "No $AGGREGATOR_DRIVER pods found in $K8_NAMESPACE namespace. No action"
fi

helm --namespace $K8_NAMESPACE uninstall eric-mxe --debug --timeout=$CHART_TIMEOUT;
helm --namespace $K8_NAMESPACE uninstall eric-eea --debug --timeout=$CHART_TIMEOUT;
helm --namespace $K8_NAMESPACE uninstall dep-eric-eea-ns --debug --timeout=$CHART_TIMEOUT;

kubectl --namespace $K8_NAMESPACE delete cronworkflow $(kubectl --namespace $K8_NAMESPACE get cronworkflow | grep -i aio | awk '{print $1}');
kubectl --namespace $K8_NAMESPACE delete deploy $(kubectl --namespace $K8_NAMESPACE get deploy | grep -i aio | awk '{print $1}');
kubectl --namespace $K8_NAMESPACE delete pod $(kubectl --namespace $K8_NAMESPACE get pod | grep -i "Completed\|Error\|NotReady" | awk '{print $1}');

kubectl --namespace $K8_NAMESPACE wait pod $(kubectl --namespace $K8_NAMESPACE get pod | grep sep-mt | awk '{print $1}') --for=delete --timeout=$POD_TIMEOUT;
helm --namespace $K8_NAMESPACE uninstall $(helm --namespace $K8_NAMESPACE list | grep $SEP_CHART_NAME | awk '{print $1}') --debug --timeout=$CHART_TIMEOUT;
kubectl --namespace $K8_NAMESPACE wait pod $(kubectl --namespace $K8_NAMESPACE get pod | grep $SEP_POD_NAME | awk '{print $1}') --for=delete --timeout=$POD_TIMEOUT;

kubectl --namespace $K8_NAMESPACE delete pvc --all;

kubectl delete namespace $K8_NAMESPACE;
kubectl wait namespace $K8_NAMESPACE --for=delete --timeout=$POD_TIMEOUT;