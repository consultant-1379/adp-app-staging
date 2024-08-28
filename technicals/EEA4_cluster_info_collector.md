# EEA4 Product CI cluster information and validation job

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Description

Checks every ProductCI cluster statuses on occasion, currently every hour (time trigger comes from Jenkinsfile).

The job shows the result in Jenkins and sends an alarm for ProductCI Team when the following issues occur:

* worker in NotReady state
* rook-ceph in HEALTH_WARN state
* rook-ceph in HEALTH_ERR state

## Jenkins job for EEA4 Product CI cluster information and validation

Job name: [EEA4-cluster-info-collector](https://seliius27190.seli.gic.ericsson.se:8443/job/EEA4-cluster-info-collector)

Triggered by: cron @everyhour

Steps:

* Checkout adp-app-staging
* Checkout inv repo
* Collect cluster infos and check
  * Do the collection with [cluster_info_collector.py](https://gerrit.ericsson.se/plugins/gitiles/EEA/inv_test/+/master/eea4/scripts/cluster_info_collector/cluster_info_collector.py)
  * the [cluster_info_collector.py](https://gerrit.ericsson.se/plugins/gitiles/EEA/inv_test/+/master/eea4/scripts/cluster_info_collector/cluster_info_collector.py) use the [product_ci_config_eea4.yml](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/technicals/product_ci_config_eea4.yml) that describes which collection will be executed on kubernetes master node
* Check in the result files these keywords occurrences
  * NotReady
  * HEALTH_WARN
  * HEALTH_ERR
* If these keywords are present, the job sends an e-mail to [Product CI team](mailto:PDLEEA4PRO@pdl.internal.ericsson.com)
  * the waring e-mail contains the cluster name e.g. [cluster_productci_4513](https://gerrit.ericsson.se/plugins/gitiles/EEA/inv_test/+/master/eea4/cluster_inventories/cluster_productci_4513/)
  * you can find the cluster nodes information in cluster_inventories hosts files e.g. [cluster_productci_4513 hosts](https://gerrit.ericsson.se/plugins/gitiles/EEA/inv_test/+/master/eea4/cluster_inventories/cluster_productci_4513/hosts)
