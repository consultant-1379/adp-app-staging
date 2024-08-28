# EEA4 Product CI performance data collection

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Description

The goal of the job is to collect performance data from cluster and send it to Central Elastic.
The sh script were developed by RV team.
This job should be triggered at the and of a validation on a cluster e.g from eea-application-staging-product-upgrade.

## Jenkins job

Job name: [collect-performance-data-from-cluster](https://seliius27190.seli.gic.ericsson.se:8443/job/collect-performance-data-from-cluster)
Triggers: No automatic triggers. The job triggered from the [cluster-logcollectior job](https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-logcollector/)

### Stages:

+ Checkout: checkout <https://eceagit@gerrit.ericsson.se/a/EEA/adp-app-staging>
+ Check params: Validate if CLUSTER, START_EPOCH, END_EPOCH parameters are specified
+ Prepare bob: prepare the bob instance in the job workspace (adp-app-staging repository)
+ Get port: get and save from the cluster the loadbalancer servive information with kubectl command, and parse the IP address and port
+ Set BUILD_NAME: set BUILD_NAME as SPINNAKER_TRIGGER + "_" + upStreamJob
+ Call eea4_perf_report.sh: call the data collecting shell script which is send the date to central Elastic with dockerized logstash
+ Add Grafana url: add Grafana url to job desription. The url point to Perf_EEA4_Resource dashboard and filter for the execution which run data was collected
+ Post stage: in case of failing sending notification to Teams channel

## Parameters

All parameters empty by default

+ 'CLUSTER' cluster resource id
+ 'START_EPOCH' The validation start epoch time in sec
+ 'END_EPOCH' The validation end epoch time in sec
+ 'SPINNAKER_TRIGGER' pinnaker pipeline triggering execution id
+ 'ADP_APP_STAGING_GERRIT_REFSPEC' you can set this different as master in case of when you want to test  modification on ./technicals/shellscripts/eea4_perf_report.sh

## The collector sh

This sh provided by RV team

Example for call the sh

```
./technicals/shellscripts/eea4_perf_report.sh -s 1698060948 -e 1698064152 -o /home/eceabuild/seliius27190/workspace/collect-performance-data-from-cluster/performance/logs -b _eea-product-prepare-upgrade-scheduler__111513 -c kubeconfig-seliics04534 -y
```

Parameters:

+ -s and -e the start end end epoch time in sec
+ -o output directory input for filebeat
+ -c cluster name (only for data filtering propose)
+ -b jenkins pipeline+build id something to identify the run (the parent job name and id, what called this actual job or can be incoming parameter (only for data filtering propose)
+ -y start automatically, not waiting

## The cluster config

For be able to download the data from victoria and prometheus we need to make configurations on our clusters. This config is part of the cluster install process.
Config for victoria:

Add kubernetes-service-eea-endpoints job_name to eric-victoria-metrics-vmagent configmap

```
kubectl edit configmaps -n monitoring eric-victoria-metrics-vmagent
```

Please put the next code part before  kind: ConfigMap

```
      - job_name: 'kubernetes-service-eea-endpoints'

        kubernetes_sd_configs:
          - role: endpoints
            namespaces:
              names:
              - etcd
              - ingress-nginx
              - k8s-registry
              - kube-node-lease
              - kube-public
              - kube-system
              - monitoring
              - ccd-logging
              - ccd-ingress

        relabel_configs:
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
            action: keep
            regex: true
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
            action: replace
            target_label: __scheme__
            regex: (http|HTTP)
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
            action: replace
            target_label: __metrics_path__
            regex: (.+)
          - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
            action: replace
            target_label: __address__
            regex: ([^:]+)(?::\d+)?;(\d+)
            replacement: $1:$2
          - action: labelmap
            regex: __meta_kubernetes_service_label_(.+)
          - source_labels: [__meta_kubernetes_namespace]
            action: replace
            target_label: kubernetes_namespace
          - source_labels: [__meta_kubernetes_service_name]
            action: replace
            target_label: kubernetes_name
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
            action: drop
            regex: (https|HTTPS)
          - source_labels: [__meta_kubernetes_endpoint_port_name]
            action: drop
            regex: (https|HTTPS|.*-tls|postgresql)
        metric_relabel_configs:
          - source_labels: [namespace]
            regex: 'eric-eea-ns'
            action: keep
          - source_labels: [device]
            regex: cali.+
            action: drop
```

Please make sure the eric-victoria-metrics-vmagent configmap change has been applied successfully.

The kubelet checks whether the mounted ConfigMap is fresh on every periodic sync. Auto-update is not real-time, it takes time but it updates the config map without restart.

Find "Successfully reloaded relabel configs" message in logs like this:

```
{"ts":"2023-01-24T19:08:38.483Z","level":"info","caller":"VictoriaMetrics/app/vmagent/remotewrite/remotewrite.go:164","msg":"Successfully reloaded relabel configs"}
```

Logs check:

```
victoria_metrics_agent_pod=$(kubectl get pods -n monitoring | grep 'eric-victoria-metrics-agent-' | awk '{print $1; exit}')
kubectl logs  -n monitoring $victoria_metrics_agent_pod --all-containers
```

Create Victoria Loadbalancer:

```
export ccd_monitoring_ns=monitoring
kubectl create service -n ${ccd_monitoring_ns} loadbalancer eric-victoria-metrics-cluster-vmselect-lb --tcp=4770:8481
kubectl patch service -n ${ccd_monitoring_ns} eric-victoria-metrics-cluster-vmselect-lb -p "{\"spec\": {\"selector\": {\"app\": \"vmselect\", \"app.kubernetes.io/instance\": \"eric-victoria-metrics-cluster\", \"app.kubernetes.io/name\": \"eric-victoria-metrics-cluster\"}}}"
export OAM_POOL=pool0
kubectl patch service -n ${ccd_monitoring_ns} eric-victoria-metrics-cluster-vmselect-lb -p "{\"metadata\": {\"annotations\": {\"metallb.universe.tf/allow-shared-ip\": \"rv-platform\"}}}"
kubectl patch service -n ${ccd_monitoring_ns} eric-victoria-metrics-cluster-vmselect-lb -p "{\"metadata\": {\"annotations\": {\"metallb.universe.tf/address-pool\": \"${OAM_POOL}\"}}}"
```

create-service-eric-pm-server-lb task in cnint/ruleset2.0.yaml

```
    - task: create-service-eric-pm-server-lb
      docker-image: k8-test
      docker-flags:
        - "--env KUBECONFIG=${env.KUBECONFIG}"
        - "--volume ${env.KUBECONFIG}:${env.KUBECONFIG}:ro"
      cmd:

        - kubectl get service -n ${env.K8_NAMESPACE} | grep eric-pm-server-lb | awk '{print $1}' > .bob/var.loadbalancer_exist
        - >
          bash -c '
          if [ "${var.loadbalancer_exist}" == "None" ];
            then
                echo "No eric-pm-server-lb, create it";
                kubectl create service -n ${env.K8_NAMESPACE} loadbalancer eric-pm-server-lb --tcp=4771:9090;
                kubectl patch service -n ${env.K8_NAMESPACE} eric-pm-server-lb -p "{\"spec\": {\"selector\": {\"app\": \"eric-pm-server\", \"component\": \"server\"}}}";
                kubectl patch service -n ${env.K8_NAMESPACE} eric-pm-server-lb -p "{\"metadata\": {\"annotations\": {\"metallb.universe.tf/allow-shared-ip\": \"${env.EEA_ALLOW_SHARED_IP}\"}}}";
                kubectl patch service -n ${env.K8_NAMESPACE} eric-pm-server-lb -p "{\"metadata\": {\"annotations\": {\"metallb.universe.tf/address-pool\": \"${env.OAM_POOL}\"}}}";
            fi'

```

create-service-eric-data-search-engine-lb in cnint/ruleset2.0.yaml

```
    - task: create-service-eric-data-search-engine-lb
      docker-image: k8-test
      docker-flags:
        - "--env KUBECONFIG=${env.KUBECONFIG}"
        - "--volume ${env.KUBECONFIG}:${env.KUBECONFIG}:ro"
      cmd:

        - kubectl get service -n ${env.K8_NAMESPACE} | grep eric-data-search-engine-lb | awk '{print $1}' > .bob/var.loadbalancer_exist
        - >
          bash -c '
          if [ "${var.loadbalancer_exist}" == "None" ];
            then
                echo "No eric-data-search-engine-lb, create it";
                kubectl create service -n ${env.K8_NAMESPACE} loadbalancer eric-data-search-engine-lb --tcp=4772:9200;
                kubectl patch service -n ${env.K8_NAMESPACE} eric-data-search-engine-lb -p "{\"spec\": {\"selector\": {\"app\": \"eric-data-search-engine\", \"component\": \"eric-data-search-engine\", \"role\": \"ingest\"}}}";
                kubectl patch service -n ${env.K8_NAMESPACE} eric-data-search-engine-lb -p "{\"metadata\": {\"annotations\": {\"metallb.universe.tf/address-pool\": \"${env.OAM_POOL}\"}}}";
                kubectl patch service -n ${env.K8_NAMESPACE} eric-data-search-engine-lb -p "{\"metadata\": {\"annotations\": {\"metallb.universe.tf/allow-shared-ip\": \"${env.EEA_ALLOW_SHARED_IP}\"}}}";
            fi'

```

## The logstash config

[config template for install](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/ELK-multinode-setup/roles/elk-hardening/templates/beats_to_elastic_nossl.conf.j2)

## Graphana dashboards

+ [Perf_EEA4_Resource](http://seliics00310.ete.ka.sw.ericsson.se:3000/d/rpUQspc4k/perf_eea4_resource?orgId=1)

### Dashboard source

+ [Perf_EEA4_Resource](./cluster_tools/perf_dashboard/Perf_EEA4_Resource-1697036709307.json)

### ELK

+ indecies: eea4_node_info and eea4_kube_pod_container_info
+ Retention policy : these are not rollover indecies, so curator not able to delete old documents from the indecies, we have to delete them throug API
cron :

 ```
0 2 * * * /opt/elk_maintenance/elk_cleanup.sh
 ```

the script:

 ```
#!/usr/bin/env bash

username_var=$(< /etc/curator/curator.yml grep username | awk -F': ' '{print $2}')
password_var=$(< /etc/curator/curator.yml grep password | awk -F': ' '{print $2}')
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
 ```

script path : technicals/shellscripts/elk_cleanup.sh
