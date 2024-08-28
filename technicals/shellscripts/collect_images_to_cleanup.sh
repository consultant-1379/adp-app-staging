#!/usr/bin/env bash

set -e
if [[ $# -lt 4 || $# -gt 5 ]]
  then
    echo "Usage: ./generate_image_list.sh <username> <password> <registry_url> <output filename> [<numberof images, default=1000>]"
    echo "Example 1: ./generate_image_list.sh admin Password123 k8s-registry.eccd.local images_to_remove.txt"
    echo "Example 2: ./generate_image_list.sh admin Password123 k8s-registry.eccd.local images_to_remove.txt 200"
    exit 1
fi

USER=$1
PASSWD=$2
REGISTRYURL=$3
OUTPUTFILE=$4
IMAGES=$5

get_images (){
  if [[ -z $IMAGES ]]
  then
    IMAGES=1000
  fi
  for image in $(curl  -X GET -u "${USER}":"${PASSWD}" -H "Accept: application/json" https://"${REGISTRYURL}"/v2/_catalog?n="${IMAGES}" |jq  -r '.[]' |tr -d '[]",'); do
    for tag in $(curl  -X GET -u "${USER}":"${PASSWD}" -H "Accept: application/json" https://"${REGISTRYURL}"/v2/"${image}"/tags/list |jq .tags| tr -d ',["]\n'); do
      if [[ $tag != 'null' ]]
      then
        image_list+="$image:$tag,"
      fi
    done
  done
}

format_image_list (){
  image_list=$(echo "${image_list}" |tr -d '\n'|rev |cut -c2- |rev)
  echo "{\"username\": \"${USER}\", \"password\": \"${PASSWD}\", \"images\": [\"$image_list\"], \"registry_url\": \"${REGISTRYURL}\"}" > "${OUTPUTFILE}"
}

get_images
format_image_list
