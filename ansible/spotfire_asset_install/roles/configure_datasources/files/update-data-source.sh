#!/bin/bash

set -e

function display_help(){
  echo "Usage: $0 [option...] {client-id|client-secret|spotfire-server-url|db-connection-url|db-user dbadmin|db-password|library-path}" >&2
  echo
  echo -e "MANDATORY:"
  echo -e "   --client-id               Registered API client ID"
  echo -e "   --client-secret           Registered API client secret"
  echo -e "   --db-connection-url       JDBC connection URL"
  echo -e "   --spotfire-server-url     Spotfire server URL with protocol"
  echo -e "   --library-path            Ericsson's Data-Source connection file library path"
  echo -e "OPTIONAL:"
  echo -e "   --db-user                 JDBC connection user name"
  echo -e "   --db-password             JDBC connection user's password"
  echo -e "OPTION:"
  echo -e "   --help                    Prints help"
  echo
  exit 1
}

# source: https://stackoverflow.com/questions/1955505/parsing-json-with-unix-tools/26655887#26655887
# not using "jq" cause it's usually not part of default linux distro install
function parse_json() {
  echo "$1" |
    sed -e 's/[{}]/''/g' |
    sed -e 's/", "/'\",\"'/g' |
    sed -e 's/" ,"/'\",\"'/g' |
    sed -e 's/" , "/'\",\"'/g' |
    sed -e 's/","/'\"---SEPERATOR---\"'/g' |
    awk -F=':' -v RS='---SEPERATOR---' "\$1~/\"$2\"/ {print}" |
    sed -e "s/\"$2\"://" |
    tr -d "\n\t" |
    sed -e 's/\\"/"/g' |
    sed -e 's/\\\\/\\/g' |
    sed -e 's/^[ \t]*//g' |
    sed -e 's/^"//' -e 's/"$//'
}

MANDATORY_ARGS=("--client-id" "--client-secret" "--db-connection-url" "--spotfire-server-url" "--library-path")

ARGS=()
function margs_check {
  if [ $# -lt ${#MANDATORY_ARGS[@]} ]; then
    echo "Missing arguments:"
    echo "${MANDATORY_ARGS[@]}" "${ARGS[@]}" | tr ' ' '\n' | sort | uniq -u
    exit 1
  fi
}

while [[ "$#" -gt 0 ]]; do
  ARGS+=("$1")
  case $1 in
  --client-id)
    CLIENT_ID="$2"
    shift
    ;;
  --client-secret)
    CLIENT_SECRET="$2"
    shift
    ;;
  --db-connection-url)
    DB_CONNECTION_URL="$2"
    shift
    ;;
  --db-user)
    DB_USER="$2"
    shift
    ;;
  --db-password)
    DB_PASSWORD="$2"
    shift
    ;;
  --spotfire-server-url)
    SPOTFIRE_SERVER_URL="$2"
    shift
    ;;
  --library-path)
    LIBRARY_PATH="$2"
    shift
    ;;
  -h|--help)
    display_help
    ;;
  *)
    echo "Error: Unknown option: $1"
    exit 1
    ;;
  esac
  shift
done
margs_check "$CLIENT_ID" "$CLIENT_SECRET" "$SPOTFIRE_SERVER_URL" "$DB_CONNECTION_URL" "$DB_USER $DB_PASSWORD" "$LIBRARY_PATH"

echo "Client ID: $CLIENT_ID"
echo "Client Secret: $(echo "$CLIENT_SECRET" | sed -r 's/(.)\B/_/g')"
echo "Spotfire Server Url: $SPOTFIRE_SERVER_URL"
echo "DB Connection Url: $DB_CONNECTION_URL"
echo "DB User: $DB_USER"
echo "DB Password: $(echo "$DB_PASSWORD" | sed -r 's/(.)\B/_/g')"
echo "Library path: $LIBRARY_PATH"

HTTP_BASIC_AUTH=$(echo -n "${CLIENT_ID}:${CLIENT_SECRET}" | base64 -w 0)

## Get access token

TOKEN_RESPONSE=$(curl --fail --location --request POST "$SPOTFIRE_SERVER_URL/spotfire/oauth2/token" \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --header "Authorization: basic ${HTTP_BASIC_AUTH}" \
  --data-urlencode 'grant_type=client_credentials' \
  --data-urlencode 'scope= api.soap.information-model-service')

ACCESS_TOKEN=$(parse_json "$TOKEN_RESPONSE", access_token)

## Send xml envelop to change data source

curl --fail --location --request POST "$SPOTFIRE_SERVER_URL/spotfire/api/soap/InformationModelService" \
  --header "Authorization: Bearer $ACCESS_TOKEN" \
  --header 'Content-Type: application/xml' \
  --data "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:inf=\"http://spotfire.tibco.com/ws/pub/2014/05/informationmodel.xsd\">
   <soapenv:Header/>
   <soapenv:Body>
      <inf:updateDataSource>
         <path><![CDATA[$LIBRARY_PATH]]></path>
         <connectionUrl><![CDATA[$DB_CONNECTION_URL]]></connectionUrl>
         <user><![CDATA[$DB_USER]]></user>
         <password><![CDATA[$DB_PASSWORD]]></password>
      </inf:updateDataSource>
   </soapenv:Body>
</soapenv:Envelope>"
