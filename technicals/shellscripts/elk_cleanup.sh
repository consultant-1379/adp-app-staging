#!/usr/bin/env bash

username_var=$(< /etc/curator/curator.yml grep username | awk -F': ' '{print $2}')
password_var=$(< /etc/curator/curator.yml grep password | awk -F': ' '{print $2}')
curl -k -sS -X POST -H 'content-type:application/json' -u "${username_var}:${password_var}" 'https://seliics00310.ete.ka.sw.ericsson.se:9200/ci_kube_pod_container_info/_delete_by_query' -d '
{
  "query": {
    "range" : {
      "@timestamp": {
        "lte": "now-30d"
      }
    }
  }
}'
curl -k -sS -X POST -H 'content-type:application/json' -u "${username_var}:${password_var}" 'https://seliics00310.ete.ka.sw.ericsson.se:9200/ci_node_info/_delete_by_query' -d '
{
  "query": {
    "range" : {
      "@timestamp": {
        "lte": "now-30d"
      }
    }
  }
}'
curl -k -sS -X GET  -H 'content-type:application/json' -u "${username_var}:${password_var}" 'https://seliics00310.ete.ka.sw.ericsson.se:9200/eea4_kube_pod_container_info/_count'
curl -k -sS -X POST -H 'content-type:application/json' -u "${username_var}:${password_var}" 'https://seliics00310.ete.ka.sw.ericsson.se:9200/eea4_kube_pod_container_info/_delete_by_query' -d '
{
  "query": {
    "range" : {
      "@timestamp": {
        "lte": "now-30d"
      }
    }
  }
}'
curl -k -sS -X GET  -H 'content-type:application/json' -u "${username_var}:${password_var}" 'https://seliics00310.ete.ka.sw.ericsson.se:9200/eea4_kube_pod_container_info/_count'
curl -k -sS -X GET  -H 'content-type:application/json' -u "${username_var}:${password_var}" 'https://seliics00310.ete.ka.sw.ericsson.se:9200/eea4_node_info/_count'
curl -k -sS -X POST -H 'content-type:application/json' -u "${username_var}:${password_var}" 'https://seliics00310.ete.ka.sw.ericsson.se:9200/eea4_node_info/_delete_by_query' -d '
{
  "query": {
    "range" : {
      "@timestamp": {
        "lte": "now-30d"
      }
    }
  }
}'
curl -k -sS -X GET  -H 'content-type:application/json' -u "${username_var}:${password_var}" 'https://seliics00310.ete.ka.sw.ericsson.se:9200/eea4_node_info/_count'
