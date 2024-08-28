# Troubleshooting guide for Product CI ELK cluster

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## A short description of the log transferring process from K8S clusters to ELK

Within the K8S cluster microservices produce logs sending them to a target, where the logging service can collect them.

Log shipper (aka filebeat) harvests logs from pods' stdout as well as from target paths, such as

```
- /var/log/pods/${data.kubernetes.container.id}/*-json.log
- /var/log/pods/${data.kubernetes.namespace}_${data.kubernetes.pod.name}_${data.kubernetes.pod.uid}/${data.kubernetes.container.name}/*.log
```

and then sends them to log transformer (aka logstash). It, in turn, transforms and filters logs and sends them to external Logstash using syslog protocol

Historically, log transformer cannot send logs directly to external Elasticsearch server but rather uses external Logstash service (seliics00311)

***Note:*** More detailed documentation is accessible on this [EEA4 Logging service](https://eth-wiki.rnd.ki.sw.ericsson.se/display/ECISE/EEA4+logging+service#EEA4loggingservice-Solutionproposal(s)) study page

### Troubleshooting ELK part from K8S cluster side

If logs from the certain cluster cannot reach external Elasticsearch server we have to look at log transformer configmap and check in the output section if there is an external Logstash host presented

* To get a list of log shipper/log transformer configmaps

```
kubectl get configmaps -n eric-eea-ns |grep -e eric-log*
```

Output:

```commandline
eric-log-shipper-cfg                                  1      47m
eric-log-transformer-cfg                              7      47m
eric-log-transformer-metrics-exporter-cfg             2      47m
```

* To look at log transformer's configmap

```
kubectl describe configmaps -n eric-eea-ns eric-log-transformer-cfg
```

There should be presented next lines

```
output {
   syslog {
     host => "10.61.197.98" #seliics00311
     port => 5014
```

All values to generate log shipper's and log transformer's configmaps are located in a [custom_environment_values.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/helm-values/custom_environment_values.yaml) file within cnint repository

```
eric-log-transformer:
  egress:
    syslog:
      enabled: true
      tls:
        enabled: true
      certificates:
        asymmetricKeyCertificateName: log-transformer-https-client
        trustedCertificateListName: log-transformer-external-ca
      remoteHosts:
        - host: 10.61.197.98  # seliics00311.ete.ka.sw.ericsson.se
          port: 5014
```

***Note***: Actually, there are 3 logstash servers: seliics00311, seliics00310, seliics00309 but syslog output plugin can use only one of them from the [official documentation](https://www.elastic.co/guide/en/logstash/5.5/plugins-outputs-syslog.html#plugins-outputs-syslog-host).
In case of failure the first logstash server it's possible to point another one changing a host value. There is a plan to change syslog output plugin to juggernaut output plugin (it lets to use more than one destination simultaneously) in the future

Also, there can be some environment/network issues between cluster and external ELK, so it's mandatory to analyze log transformer pod's logs  

* To get a list of log shipper/log transformer pods

```
kubectl get po -n eric-eea-ns | grep -e eric-log-*
```

Example output:

```
eric-log-shipper-hr9mf                                             1/1     Running     0             42m
eric-log-shipper-jbrtn                                             1/1     Running     0             42m
eric-log-shipper-xdm6m                                             1/1     Running     0             42m
eric-log-shipper-xvvht                                             1/1     Running     0             42m
eric-log-transformer-c4fd777dd-svdc5                               3/3     Running     0             42m
eric-log-transformer-c4fd777dd-w29kn                               3/3     Running     0             42m
```

* To analyze log transformer pod's

```
kubectl logs -n eric-eea-ns eric-log-transformer-c4fd777dd-svdc5 -c logtransformer |less
```

There we should look for connection issues to, e.g. 10.61.197.98 host

#### Troubleshooting ELK on bare metal servers part

If K8S cluster part works fine it's essential to check services on seliics00309, seliics00310, seliics00311 nodes

* At fist check if storage capacity is OK

```
df -h
```

Example output:

```
Filesystem                         Size  Used Avail Use% Mounted on
/dev/mapper/logstash-data          3.6T  1.9T  1.6T  55% /data/logstash
/dev/mapper/logstash-logs          9.8G  136M  9.1G   2% /data/logstash/logs
/dev/mapper/elasticsearch-data     3.0T  1.1T  1.9T  36% /data/elasticsearch
/dev/mapper/elasticsearch-logs      20G  1.8G   17G  10% /data/elasticsearch/logs
/dev/mapper/elasticsearch-repo      20G   19G     0  46% /data/elasticsearch/repo
/dev/mapper/VolGroup-lv_var        9.8G  3.4G  5.9G  37% /var
/dev/mapper/VolGroup-lv_var_log     15G   12G  2.6G  82% /var/log
```

In case of /dev/mapper/logstash-logs volume full there is a crontab task to clear old log archives

```
crontab -l
```

Output:

```
0 2 * * * /usr/bin/curator --config /etc/curator/curator.yml /etc/curator/action.yml
# Remove old logstash output files.
*/10 * * * * find /data/logstash/archive/ -type f -mtime +5 -exec rm -f {} \;
```

To remove old log archives it's possible to perform command manually from above task

```
find /data/logstash/archive/ -type f -mtime +5 -exec rm -f {} \;
```

Also, there is an ELK curator tool to manage indices, snapshots. Its configs are located in /etc/curator directory

```
ls -lh /etc/curator/
total 32K
-rw-r--r--   1 root root 2.6K Mar 16  2022 action.yml
-rw-r--r--   1 root root  437 Mar  9  2022 curator.yml
```

curator.yml - config file for the curator itself
action.yml - config file contains actions against indices or snapshots. Official documentation [here](https://www.elastic.co/guide/en/elasticsearch/client/curator/5.8/about.html)

## Useful ELK REST APIs

* Cluster health check

```
curl -k -u username https://seliics00310.ete.ka.sw.ericsson.se:9200/_cluster/health?pretty
```

Example output:

```
{
  "cluster_name" : "elasticsearch-eea4-ci",
  "status" : "yellow",
  "timed_out" : false,
  "number_of_nodes" : 3,
  "number_of_data_nodes" : 3,
  "active_primary_shards" : 239,
  "active_shards" : 381,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 100,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 79.20997920997921
}
```

Statuses

Green - all shards are allocated

Yellow - all primary shards are assigned, but one or more replica shards are unassigned. If a node in the cluster fails, some data could be unavailable until that node is repaired

Red - one or more primary shards are unassigned, so some data is unavailable. This can occur briefly during cluster startup as primary shards are assigned

* Get cluster statistics (stats API allows retrieve statistics from the cluster. The API returns basic index metrics (shard numbers, store size, memory usage) and information about the current nodes that form the cluster (number, roles, os, jvm versions, memory usage, cpu and installed plugins))

```
curl -s -k -u username https://seliics00310.ete.ka.sw.ericsson.se:9200/_cluster/stats?pretty
```

Example output:

```
{
  "_nodes" : {
    "total" : 3,
    "successful" : 3,
    "failed" : 0
  },
  "cluster_name" : "elasticsearch-eea4-ci",
  "cluster_uuid" : "iwhwml5uRMOwFWWuPVrI6A",
  "timestamp" : 1671458851283,
  "status" : "yellow",
  "indices" : {
    "count" : 117,
    "shards" : {
      "total" : 381,
    }
  }
...
}
```

* Get information about cluster nodes

```
curl -s -k -u username https://seliics00310.ete.ka.sw.ericsson.se:9200/_nodes
```

* List snapshots/repositories/indices

```
curl -s -k -u username https://seliics00310.ete.ka.sw.ericsson.se:9200/_cat/snapshots?pretty
curl -s -k -u username https://seliics00310.ete.ka.sw.ericsson.se:9200/_cat/repositories?v=true
curl -s -k -u username https://seliics00310.ete.ka.sw.ericsson.se:9200/_cat/indices
```

## Inventory for ELK cluster

ELK cluster nodes are listed at the [Product CI invenroty page](https://eteamspace.internal.ericsson.com/display/ECISE/EEA4+Product+CI+Inventory#EEA4ProductCIInventory-ELKnodes).

## Wiki about ELK service

[Wiki page](https://eteamspace.internal.ericsson.com/display/ECISE/ELK+%28aka+Elastic+stack%29+for+EEA4+CI) at Confluence.

## Configs of ELK services

### Elasticsearch

* seliics00309:/etc/elasticsearch/elasticsearch.yml
* seliics00310:/etc/elasticsearch/elasticsearch.yml
* seliics00311:/etc/elasticsearch/elasticsearch.yml

Actual Elasticsearch config templates:

* [elasticsearch.yml.j2](https://gerrit.ericsson.se/gitweb?p=EEA/adp-app-staging.git;a=blob;f=ansible/roles/elk/templates/elasticsearch.yml.j2;h=1d6fed6f75907068cff008263f66b1dc33c46c5e;hb=HEAD)
* [elasticsearch_tls.yml.j2](https://gerrit.ericsson.se/gitweb?p=EEA/adp-app-staging.git;a=blob;f=ELK-multinode-setup/roles/elk-hardening/templates/elasticsearch_tls.yml.j2;h=85ba46f165c73e025337fa0f0a3d48675300ec2c;hb=HEAD)

### Logstash

* seliics00311:/etc/logstash/logstash.yml
* seliics00311:/etc/logstash/conf.d/beats_to_elastic.conf
* seliics00311:/etc/logstash/conf.d/beats_to_elastic_nossl.conf
* seliics00311:/etc/logstash/conf.d/ci_payload_to_elastic.conf

Actual Logstash config templates:

* [logstash.yml.j2](https://gerrit.ericsson.se/gitweb?p=EEA/adp-app-staging.git;a=blob;f=ELK-multinode-setup/roles/elk-hardening/templates/logstash.yml.j2;h=8e4ce4861d2dd5fe2bfa9a83e79ffb8c8fc08b91;hb=HEAD)
* [beats_to_elastic.conf.j2](https://gerrit.ericsson.se/gitweb?p=EEA/adp-app-staging.git;a=blob;f=ELK-multinode-setup/roles/elk-hardening/templates/beats_to_elastic.conf.j2;h=a7e729bed56df9ea5b16a2d1eb31619e3c9d4445;hb=HEAD)
* [beats_to_elastic_nossl.conf.j2](https://gerrit.ericsson.se/gitweb?p=EEA/adp-app-staging.git;a=blob;f=ELK-multinode-setup/roles/elk-hardening/templates/beats_to_elastic_nossl.conf.j2;h=4b696f3d2ba610de4d23a0e3d41569aa64589e20;hb=HEAD)
* [ci_payload_to_elastic.conf.j2](https://gerrit.ericsson.se/gitweb?p=EEA/adp-app-staging.git;a=blob;f=ELK-multinode-setup/roles/elk-hardening/templates/ci_payload_to_elastic.conf.j2;h=c87501bdffa88557d4915a653530843413e9bd80;hb=HEAD)

### Kibana

* seliics00310:/etc/kibana/kibana.yml

An actual Kibana config template is [kibana.yml.j2](https://gerrit.ericsson.se/gitweb?p=EEA/adp-app-staging.git;a=blob;f=ELK-multinode-setup/roles/elk-hardening/templates/kibana_tls.yml.j2;h=fe5775162f8ae74a0c31a4f057eb1e43cdbed9ef;hb=HEAD)

### Grafana

* seliics00310:/etc/grafana/grafana.ini

## Logs of ELK services

### Elasticsearch

* seliics00309:/data/elasticsearch/logs
* seliics00310:/data/elasticsearch/logs
* seliics00311:/data/elasticsearch/logs

### Kibana

Kibana is being run on seliics00310 node. To get Kibana logs perform

```
less /var/log/messages
```

and leverage kibana keyword to filter out suitable logs as all log entries are marked by service name. Another possible variant

```
grep -irn kibana /var/log/messages |tail -300 |less
```

Getting Kibana logs by using the system journal

```
journalctl -u kibana.service --since today(yesterday)
```

### Logstash

Logstash is being run on seliics00311 node. To get Logstash logs perform

```
less /var/log/messages
```

and leverage logstash keyword to filter out suitable logs as all log entries are marked by service name. Another possible variant

```
grep -irn logstash /var/log/messages |tail -300 |less
```

Getting Logstash logs by using system journal

```
journalctl -u logstash.service --since today(yesterday)
```

There is another sort of Logstash logs that's located in /data/logstash/logs directory. It is internal service logs that are configured in the /etc/logstash/logstash.yml config to pay attention

```
path.logs: /data/logstash/logs
```

### Grafana

* seliics00310:/var/log/grafana

## Check status of ELK services

### Kibana

* systemctl status kibana

### Elasticsearch

* systemctl status elasticsearch

### Logstash

* systemctl status logstash

### Grafana

* systemctl status grafana-server

## Restart ELK services

* Kibana, Logstash, Grafana and Elasticsearch can be controlled with systemctl

## UTF test failures showing ELK problem

DS has some tests in UTF which verifies that syslog stored properly at central ELK, which simulates the syslog server of the customer.
Related scenarios are available at the [external_syslog_check feature file](https://gerrit.ericsson.se/plugins/gitiles/EEA/eea4-bbt/+/refs/heads/master/unified-test-framework/utf-e2e-parent/utf-e2e-steps-cucumber/src/main/resources/features/logging/external_syslog_check.feature).

Syslog is loaded to ELK via logstash service, so if these tests are failing we should check status of logstash and ELK. Failure of these services can be caused by running out of free disk space, however we have curator running at ELK service which cleans up old logs and logrotation is also configured for logs saved by logstash in file format at the nodes. These files are kept only for few days, while longer term log storage is at at ELK.

Also via [Kibana](https://seliics00310.ete.ka.sw.ericsson.se:5601/app/kibana/) it can be checked that do we have data at product_ci* indices, where the syslog should be stored.

## Checking available disk space at ELK clusters

Disk space alarms are sent by central Zabbix service from our ELK nodes, if usage of a disk partition is over 90%. Alarm is sent to [ELK alerts](https://teams.microsoft.com/l/channel/19%3a9ae1c4206a2a4c649ad1e4ba76fb5b7a%40thread.tacv2/ELK%2520alerts?groupId=bc9ea19b-97da-479d-903f-9b003bcba6a4&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f) MS Teams channel for Product CI team.

If this happens EEA4 Product CI driver should login to the affected node and remove old data from the relevant partition, then if needed restart the failed ELK services.

## Contact

If these steps are not enough to fix ELK services please contact [Bálint Juhász](mailto:balint.juhasz@ericsson.com) at RV team.
