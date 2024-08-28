#!/bin/bash

set -x

YAMLPATH=$1
LOADBALANCER_IP=$2
EXITCODE=0

if [ -z "$YAMLPATH" ]; then
  echo "ERROR: YAMLPATH is not defined"
  EXITCODE=1
fi

if [ -z "$LOADBALANCER_IP" ]; then
  echo "ERROR: LOADBALANCER_IP is not defined"
  EXITCODE=1
fi

KUBEAPIRULES=$(
# shellcheck disable=SC2086
  for endpoint in $(kubectl -n default get endpoints kubernetes | tail -n+2 | awk "{print \$2}" | tr "," " "); do
    ip="$(echo $endpoint | cut -d: -f1)";
# shellcheck disable=SC2028
    if [ "${#ip}" -ne 0 ]; then echo -n "      - ipBlock:\n          cidr: $ip/32\n"; fi
  done
)

# shellcheck disable=SC2028
MXEAPIRULES="      - ipBlock:\n          cidr: ${LOADBALANCER_IP}/32"


sed -i "s#KUBEAPIRULES#\n${KUBEAPIRULES}#" "${YAMLPATH}"
sed -i "s#MXEAPIRULES#\n${MXEAPIRULES}#" "${YAMLPATH}"

if [ "${#KUBEAPIRULES}" -lt 40 ]; then
  echo "ERROR: KUBEAPIRULES seems empty: ${#KUBEAPIRULES}"
  EXITCODE=1
fi

if [ "${#MXEAPIRULES}" -lt 40 ]; then
  echo "ERROR: MXEAPIRULES seems empty: {MXEAPIRULES}"
  EXITCODE=1
fi

echo YAMLPATH: "${YAMLPATH}"

# shellcheck disable=SC2002
if [ "$(cat "${YAMLPATH}" | grep -c KUBEAPIRULES)" -ne 0 ]; then
  echo "ERROR: sed KUBEAPIRULES failed"
  EXITCODE=1
fi

# shellcheck disable=SC2002
if [ "$(cat "${YAMLPATH}" | grep -c MXEAPIRULES)" -ne 0 ]; then
  echo "ERROR: sed MXEAPIRULES failed"
  EXITCODE=1
fi

exit "$EXITCODE"
