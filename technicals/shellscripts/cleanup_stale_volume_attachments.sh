#!/usr/bin/env bash

SCRIPT_NAME=$(basename "$(realpath "$0")")

usage(){
  echo -e "
  Usage of the ${SCRIPT_NAME} script:
    \\n Example of a correct script call: $0 [[--k8_namespace|-k] <k8_namespace>] [--help|-h]
    \\n <K8_NAMESPACE> - kubernetes namespace where EEA4 product installed. Example: eric-eea-ns
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


if [[ -z $K8_NAMESPACE ]]
then
  echo "$(date) - Missing a mandatory argument: k8_namespace"
  usage
  exit 1
fi

checkIfNameSpaceExists() {
  k8sNameSpace=$1

  if [[ $(kubectl get ns |grep "${k8sNameSpace}" |awk '{print $1}') == "eric-eea-ns" ]]; then
    echo "The ${k8sNameSpace} namespace exists. Skip checking"
    exit 1
  fi
}

checkIfNameSpaceExists "$K8_NAMESPACE"

declare -a vaArray=()
declare -a pvArray=()

for va in $(kubectl get volumeattachments.storage.k8s.io -o custom-columns=:.metadata.name --no-headers)
do
  persistentVolume=$(kubectl get volumeattachments "$va" -o jsonpath='{.spec.source.persistentVolumeName}{"\n"}' 2> /dev/null)
  podName=$(kubectl get pv "$persistentVolume" -o jsonpath='{.spec.claimRef.name}{"\n"}' 2> /dev/null)
  podNameSpace=$(kubectl get pv "$persistentVolume" -o jsonpath='{.spec.claimRef.namespace}{"\n"}' 2> /dev/null)
  if [[ -n ${podName} ]]; then
    echo "A persistent volume belongs to the $va volume attachment is $persistentVolume"
    echo "A pod name claimed above $persistentVolume persistent volume is $podName"
    echo "A namespace of the pod $podName is $podNameSpace"
    # Check if pod's namespace is eric-eea-ns
    if [[ $podNameSpace != "$K8_NAMESPACE" ]]; then
      echo "The pod $podName doesn't belong to the $K8_NAMESPACE namespace. Skip checking the $va volume attachment"
      echo "======================================================="
      echo ""
    else
      # Check if pod doesn't exists. In this cas we can remove current volume attachment and persistent volume
      if kubectl -n "$K8_NAMESPACE" get po "$podName" 2> /dev/null; then
        echo "The pod $podName which owns the persistent volume $persistentVolume exists. Skip checking the $va volume attachment"
        echo "======================================================="
        echo ""
      else
        echo "The pod $podName which owned the persistent volume $persistentVolume does not exist. Removing the volume attachment $va and persistent volume $persistentVolume spawned by this pod"
        vaArray+=("${va}")
        pvArray+=("${persistentVolume}")
        echo "kubectl delete volumeattachments $va --grace-period=0 --force"
        kubectl delete volumeattachments "$va" --grace-period=0 --force 2> /dev/null
        echo "kubectl delete pv $persistentVolume --grace-period=0 --force"
        kubectl delete pv "$persistentVolume" --grace-period=0 --force 2> /dev/null
        echo "======================================================="
        echo ""
      fi
    fi
  elif ! kubectl get pv "$persistentVolume" 2> /dev/null; then
      echo "A persistent volume $persistentVolume not found. Removing the volume attachment $va and persistent volume $persistentVolume"
      kubectl delete volumeattachments "$va" --grace-period=0 --force 2> /dev/null
      kubectl delete pv "$persistentVolume" --grace-period=0 --force 2> /dev/null
      vaArray+=("${va}")
      pvArray+=("${persistentVolume}")
      echo "======================================================="
      echo ""
  fi
done

vaArrayLength=${#vaArray[@]}

if [[ ${vaArrayLength} -gt 0 ]]; then
  echo ""
  echo "Removed stale volume attachments: "
  for va in ${vaArray[*]}
  do
    echo "$va"
  done
  echo ""
  echo "Removed stale persistent volumes: "
  for pv in ${pvArray[*]}
  do
    echo "$pv"
  done
fi