#!/usr/bin/env bash

SCHEMA_REGISTRY_INT_CERT_NAME="eric-data-loader-eric-schema-registry-sr-client-cert"
MESSAGE_BUS_KF_INT_CERT_NAME="eric-data-loader-eric-data-message-bus-kf-client-cert"
KAFKA_TLS_SECRET_NAME="kafka-tls-data-loader-cert"
KAFKA_TLS_JAVA_DATA_LOADER_CERT="kafka-tls-java-data-loader-cert"

SCRIPT_NAME=$(basename "$(realpath "$0")")

usage(){
  echo -e "
  Usage of the ${SCRIPT_NAME} script:
    \\n Example of a correct script call: $0 [[--k8_namespace|-k] <k8_namespace>] [[--utf_namespace|-u] <utf_namespace>] [[--manifest_files_path|-m] <manifest_files_path> [--help|-h]
    \\n <K8_NAMESPACE> - kubernetes namespace where EEA4 product installed. Example: eric-eea-nsS
    \\n <UTF_NAMESPACE> - kubernetes namespace where UTF installed. Example: utf-service
    \\n <PATH_TO_MANIFEST_FILES> - path to yaml files to create internal certificates for ebm2kafka tool. Example: adp-app-staging-full-checkout/cluster_tools
  "
}

while [ $# -gt 0 ]; do
  case "$1" in
    --k8_namespace*|-k*)
      if [[ "$1" != *=* ]]; then shift; fi # Value is next arg if no `=`
      K8_NAMESPACE="${1#*=}"
      ;;
    --utf_namespace*|-u*)
      if [[ "$1" != *=* ]]; then shift; fi
      UTF_NAMESPACE="${1#*=}"
      ;;
    --manifest_files_path*|-m*)
      if [[ "$1" != *=* ]]; then shift; fi
      PATH_TO_MANIFEST_FILES="${1#*=}"
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

if [[ -z $K8_NAMESPACE || -z $UTF_NAMESPACE || -z $PATH_TO_MANIFEST_FILES ]]
then
  echo "$(date) - Missing mandatory arguments: k8_namespace, utf_namespace and manifest_files_path"
  usage
  exit 1
fi

INT_CERT_KF_MANIFEST_FILENAME="${PATH_TO_MANIFEST_FILES}/eric-data-loader-kf-IntCert.yaml"
INT_CERT_SR_MANIFEST_FILENAME="${PATH_TO_MANIFEST_FILES}/eric-data-loader-sr-IntCert.yaml"

checkIfResourceExisted(){
  k8sNameSpace=$1
  resourceType=$2
  resourceName=$3

  kubectl get "${resourceType}" -n "${k8sNameSpace}" "${resourceName}"
  getResourceName=$(kubectl get "${resourceType}" -n "${k8sNameSpace}" "${resourceName}" |awk 'NR > 1 {print $1}')

  if [[ -n "${getResourceName}" && "${getResourceName}" == "${resourceName}" ]]; then
    echo "The ${resourceName} ${resourceType} is existed"
  else
    echo "The ${resourceName} ${resourceType} is not existed"
    exit 1
  fi

}

echo "Creating internal certificates for schema registry and kafka"
kubectl apply -f "${INT_CERT_SR_MANIFEST_FILENAME}"
kubectl apply -f "${INT_CERT_KF_MANIFEST_FILENAME}"
echo ""

echo "Check if internal secrets for schema registry and kafka have been created"
echo ""
sleep 5
checkIfResourceExisted "${K8_NAMESPACE}" "secret" "${SCHEMA_REGISTRY_INT_CERT_NAME}"
echo ""
checkIfResourceExisted "${K8_NAMESPACE}" "secret" "${MESSAGE_BUS_KF_INT_CERT_NAME}"
echo ""

echo "Patch kafka tls secret ${KAFKA_TLS_SECRET_NAME}"
echo ""
kubectl patch secret -n "${UTF_NAMESPACE}" kafka-tls-data-loader-cert -p "{ \"data\": $(kubectl get secret -n "${K8_NAMESPACE}" eric-data-loader-eric-schema-registry-sr-client-cert -o jsonpath='{ .data }' | jq . | sed -e 's/"tls\./"sr-client./')}"
kubectl patch secret -n "${UTF_NAMESPACE}" kafka-tls-data-loader-cert -p "{ \"data\": { \"cacertbundle.pem\": \"$(kubectl get secret -n "${K8_NAMESPACE}" eric-sec-sip-tls-trusted-root-cert -o jsonpath='{.data.cacertbundle\.pem}')\"}}"

echo "Getting key and certificate from ${MESSAGE_BUS_KF_INT_CERT_NAME} secret"
echo ""
kubectl get secret -n "${K8_NAMESPACE}" "${MESSAGE_BUS_KF_INT_CERT_NAME}" -o jsonpath='{.data.tls\.crt}' | base64 -d > kafka_tls.crt
kubectl get secret -n "${K8_NAMESPACE}" "${MESSAGE_BUS_KF_INT_CERT_NAME}" -o jsonpath='{.data.tls\.key}' | base64 -d > kafka_tls.key

echo "Creating p12 keystore from key and certificate of ${MESSAGE_BUS_KF_INT_CERT_NAME} secret"
echo ""
openssl pkcs12 -export -inkey kafka_tls.key -in kafka_tls.crt -out kafka-keystore.p12 -name kafka_key -passout pass:kafkatools

echo "Add to ${KAFKA_TLS_SECRET_NAME} secret p12 keystore"
echo ""
kubectl patch secret -n "${UTF_NAMESPACE}" "${KAFKA_TLS_JAVA_DATA_LOADER_CERT}" -p "{ \"data\": { \"kafka-keystore.p12\": \"$(base64 -w0 kafka-keystore.p12)\"}}"
echo ""
kubectl describe secret -n "${UTF_NAMESPACE}" "${KAFKA_TLS_JAVA_DATA_LOADER_CERT}"
echo ""
