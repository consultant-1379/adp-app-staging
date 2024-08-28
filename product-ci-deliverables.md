# Product CI deliverables

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Product CI Deliverables

+ What is the content of the deliverable?
+ How the data is collected ?
+ Where is it delivered ?
+ What is the format ?
+ Who is the end user ?
+ Ticket number where the deliverable was created ?

### 3PP List as CSV (3pp_list.csv)

+ This file contains all the EEA microservice 3pp related data which is delivered with the microservice versions, detailed [here](https://eteamspace.internal.ericsson.com/display/ECISE/Requirements+for+microservice+level+CI#RequirementsformicroservicelevelCI-2PPsand3PPs)
+ It is created by downloading the 3pp_list.json files delivered with each microservice versions, which is checked at sanity check, and merging these files into the 3pplist.csv with csarutils.fetchAndProcess3ppListJsonsToCsv() method in ci shared librarys
+ On product ci, adp-app-staging/pipelines/eea_application_staging/eea_application_staging_publish_baseline.Jenkinsfile and adp-app-staging/pipelines/eea_product_release_loop/eea_product_release.Jenkinsfile , from here, the file is uploaded next to the csar package, to the [drop artifactory](https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-generic-local) and the [release artifactory](https://arm.seli.gic.ericsson.se/artifactory/proj-eea-released-generic-local)
+ Format :

```
line1, header :
imageName, imageNumber, 3ppName, 3ppVersion, versionCAX/numberCAX, isPrimary, requiredByPrimaries

from line 2 example :
System Overview Spotfire Analysis, CXU 101 1008, Tibco Spotfire Server, 12.0.0, 14/CAX1056966, true,
System Overview Spotfire Analysis, CXU 101 1008, Python-PostgreSQL Database Adapter, 2.9.3, 22/CAX1057108, true,
...
```

+ Release handling team
+ [EEAEPP-79803](https://eteamproject.internal.ericsson.com/browse/EEAEPP-79803)

### Text file with CCD related informations (ccd_information.txt)

This file contains following information about the cluster:

+ CCD version
+ k8s server version
+ OS version
+ Rook version
+ Ceph version
+ Ceph health information

The file is uploaded to cluster logs [reports ARM repo](https://arm.seli.gic.ericsson.se//artifactory/proj-eea-reports-generic-local/clusterlogs/<build_name>-<build_number>).

```
example file content:

ccdVersion: 2.28.0
k8sServerVer: v1.29.1
OSVersion: SUSE Linux Enterprise Server 15 SP5
rookVersion: v1.13.7
cephVersion: 18.2.2
cephHealth: HEALTH_OK (muted: POOL_NO_REDUNDANCY)
...
```

### Text file with all the microservices details with ProductNumber, ProductName, baseOSVersion etc.. (content.txt)

+ This file contains all the EEA microservice data which is delivered with the ProductNumber, ProductName, baseOSVersion
+ It is created by downloading the existing content.txt file from the artifactory then in the cbos_verify new data is getting appended which is baseOSVersion and reuploading the same content.txt again.
+ On product ci, adp-app-staging/technicals/eea_cbos_verify.Jenkinsfile, from here, the file is uploaded next to the artifactory, to the [drop artifactory](https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-generic-local)
+ Format :

```
line1, header :
artifactory/DropOrReleaseName:ImageNumber 'ProductName' 'ProductNumber' 'baseOSVersion'

example :
armdocker.rnd.ericsson.se/proj-adp-eric-data-object-storage-mn-released/eric-data-object-storage-mn-init:2.0.0-73 'Object Storage MN Init Container Image' 'CXC 174 2824' '5.8.0-21'
...
```

+ Security Team
+ [EEAEPP-79756](https://eteamproject.internal.ericsson.com/browse/EEAEPP-79756)

### CBOS age report (html and json)

+ These files contains output of CBOS age tool from ADP, showing the age of CBOS at micorservices of EEA IHC
+ It's created by the ADP [CBOS age tool](https://eteamspace.internal.ericsson.com/display/ACD/CBO+age+Tool).
+ These files are uploaded to [reports ARM repo](https://arm.epk.ericsson.se/artifactory/proj-eea-reports-generic-local/eea4/).
+ Format: Defines by the external tool.

```
...
```

+ Security Team
+ [EEAEPP-79756](https://eteamproject.internal.ericsson.com/browse/EEAEPP-79756)

## Log files

+ What is the content of the log ?
+ How the data is collected ?
+ Where is it uploaded ?
+ What is the format ?
+ Ticket number where the log was created ?

### Helm config value files archive

+ Contains the helm config value files archived into a single tar.
+ Config yaml files collected from the file list parameter helm uses upon install and upgrade tasks.
+ These files are uploaded to cluster logs [reports ARM repo](https://arm.seli.gic.ericsson.se//artifactory/proj-eea-reports-generic-local/clusterlogs/).
+ Format: tar.gz archive named `install-configvalues.tar.gz`, `service-upgrade-configvalues.tar.gz` or `config-upgrade-configvalues.tar.gz` containing the configs in the original file structure:

```
example:
>tar -t -f install-configvalues.tar.gz
custom_environment_values.yaml
dataflow-configuration/refdata-values.yaml
dataflow-configuration/correlator-values.yaml
dataflow-configuration/aggregator-values.yaml
dataflow-configuration/db-loader-values.yaml
dataflow-configuration/db-manager-values.yaml
dataflow-configuration/dashboard-values.yaml
custom_dimensioning_values.yaml
custom_deployment_values.yaml
```

+ For supporting debugging we save the applied helm values from cluster after install as well, to the helm_values_after_product_install_eric_eea_ns.yaml.gz , e.g.: [helm_values_after_product_install_eric_eea_ns.yaml.gz](https://arm.seli.gic.ericsson.se//artifactory/proj-eea-reports-generic-local/clusterlogs/eea-application-staging-nx1-9446/helm_values_after_product_install_eric_eea_ns.yaml.gz)

+ [EEAEPP-82114](https://eteamproject.internal.ericsson.com/browse/EEAEPP-82114)

+ [EEAEPP-83334](https://eteamproject.internal.ericsson.com/browse/EEAEPP-83334)

Cover next pipelines:

+ [eea-common-product-upgrade](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-common-product-upgrade/)
+ [eea-application-staging-product-baseline-install](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-product-baseline-install/)
+ [eea-application-staging-nx1](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-nx1/)
+ [eea-application-staging-batch](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-batch/)
+ [eea-adp-staging-adp-nx1-loop](https://seliius27190.seli.gic.ericsson.se:8443/view/EEA%20ADP%20Staging%20View/job/eea-adp-staging-adp-nx1-loop/)
+ [eea-product-ci-meta-baseline-loop-test](https://seliius27190.seli.gic.ericsson.se:8443/view/EEA%20Product%20CI%20Meta-baseline%20loop%20View/job/eea-product-ci-meta-baseline-loop-test/)

### License Manager log

+ NELS related License Manager license keys data (license ids, license types etc)
+ Collected during cluster log collection from pod `eric-eea-license-data-document-database-pg` with psql querying the `eea-lm` database
+ It is uploaded to cluster logs [reports ARM repo](https://arm.seli.gic.ericsson.se//artifactory/proj-eea-reports-generic-local/clusterlogs/)
+ Format: Defines by the external tool (psql). Example:

```
 id  |   product_type   |  license_id  | license_type |   key_start   |   key_stop    | capacity | cumulative_period_start | cumulative_period_length | grace_period | grow_only |        description         | last_update_time | customer_id | swlt_id
-----+------------------+--------------+--------------+---------------+---------------+----------+-------------------------+--------------------------+--------------+-----------+----------------------------+------------------+-------------+---------
 642 | Expert_Analytics | FAT1024238/1 |            2 | 1675206000000 | 1681250400000 |   200000 |                       0 |                        8 |              | f         | Expert Analytics MBB       |    1687970607452 |             |
 643 | Expert_Analytics | FAT1024238/1 |            2 | 1681250400000 | 1690927200000 |   100000 |                       0 |                        8 |              | f         | Expert Analytics MBB       |    1687970607452 |             |
 ...
```

+ [EEAEPP-82560](https://eteamproject.internal.ericsson.com/browse/EEAEPP-82560)

### Collect Kafka topic message at log collection phase

+ [EEAEPP-87947](https://eteamproject.internal.ericsson.com/browse/EEAEPP-87947)
+ [collect_kafka_topic_message.sh usage](https://gerrit.ericsson.se/plugins/gitiles/EEA/eea4-utils/+/master/docker/eric-eea-utils/README.md#collect_kafka_topic_message_sh)
+ These files are uploaded to cluster logs [reports ARM repo](https://arm.seli.gic.ericsson.se//artifactory/proj-eea-reports-generic-local/clusterlogs/).
+ Format: tar.gz example archive named `eric-eea-ns_eric-eea-fm-eric-data-message-bus-kf-_AdpAlarmStateIndication.tgz` containing the collect Kafka topic message:

```
example:
>tar -t -f eric-eea-ns_eric-eea-fm-eric-data-message-bus-kf-_AdpAlarmStateIndication.tgz
eric-eea-ns_eric-eea-fm-eric-data-message-bus-kf-_AdpAlarmStateIndication/
eric-eea-ns_eric-eea-fm-eric-data-message-bus-kf-_AdpAlarmStateIndication/eric-eea-ns_eric-eea-fm-eric-data-message-bus-kf-0_AdpAlarmStateIndication.log
eric-eea-ns_eric-eea-fm-eric-data-message-bus-kf-_AdpAlarmStateIndication/eric-eea-ns_eric-eea-fm-eric-data-message-bus-kf-1_AdpAlarmStateIndication.log
eric-eea-ns_eric-eea-fm-eric-data-message-bus-kf-_AdpAlarmStateIndication/eric-eea-ns_eric-eea-fm-eric-data-message-bus-kf-2_AdpAlarmStateIndication.log
```

### Collect coredumps at log collection phase

+ Coredump file that is automatically generated by the Linux kernel after a program crashes. The core dump file contains the state of the program's memory at the time of the crash
+ Coredumps are collected with the [coredumps_collect.sh](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/scripts/coredumps_collect.sh)
+ These files are uploaded to cluster logs [reports ARM repo](https://arm.seli.gic.ericsson.se//artifactory/proj-eea-reports-generic-local/clusterlogs/)
+ In case if there are coredumps, the `coredumps.tar.xz` / `systemd_coredump.tar.xz` packages will be generated. If the there are no coredumps, it will be shown in the log

```
Mon 18 Dec 2023 09:58:09 PM CET: Script started.
Mon 18 Dec 2023 09:58:09 PM CET: Directory '/var/lib/systemd/coredump/' is empty. No files to archive.
Mon 18 Dec 2023 09:58:09 PM CET: Archiving completed. Folder 'coredump_log_archive' is created and contains the appropriate archive(s).
Mon 18 Dec 2023 09:58:09 PM CET: Script finished.
```

+ [EEAEPP-87679](https://eteamproject.internal.ericsson.com/browse/EEAEPP-87679)

### Collect CCD data at log collection phase

Collected CCD node logs:

+ ip a s
+ ip r s
+ docker images
+ docker ps -a
+ crictl images
+ crictl ps -a
+ df -h
+ etcdctl3  alarm list

Collected kubectl logs:

+ kubectl get --raw='/readyz?verbose'
+ kubectl get pods -n kube-system
+ kubectl get all --all-namespaces

```
archive ezample:

$ tar tf ccd_node_logs-20240213-103006.tgz
ccd_node_logs/
ccd_node_logs/dl380x4236e01_crictl_images
ccd_node_logs/dl380x4236e01_crictl_ps_a
ccd_node_logs/dl380x4236e01_df_h
ccd_node_logs/dl380x4236e01_docker_images
ccd_node_logs/dl380x4236e01_docker_ps_a
ccd_node_logs/dl380x4236e01_etcdctl3_alarm_list
ccd_node_logs/dl380x4236e01_ip_addresses
ccd_node_logs/dl380x4236e01_ip_routes
ccd_node_logs/dl380x4236e01_ssh_connection_succeeded
ccd_node_logs/dl380x4236e02_crictl_images
ccd_node_logs/dl380x4236e02_crictl_ps_a
ccd_node_logs/dl380x4236e02_df_h
ccd_node_logs/dl380x4236e02_docker_images
ccd_node_logs/dl380x4236e02_docker_ps_a
ccd_node_logs/dl380x4236e02_etcdctl3_alarm_list
ccd_node_logs/dl380x4236e02_ip_addresses
ccd_node_logs/dl380x4236e02_ip_routes
ccd_node_logs/dl380x4236e02_ssh_connection_succeeded
ccd_node_logs/get_all_namespaces
ccd_node_logs/get_pods_kube_system
ccd_node_logs/get_raw_readyz?verboze
ccd_node_logs/seliics01643e01_crictl_images
ccd_node_logs/seliics01643e01_crictl_ps_a
ccd_node_logs/seliics01643e01_df_h
ccd_node_logs/seliics01643e01_docker_images
ccd_node_logs/seliics01643e01_docker_ps_a
ccd_node_logs/seliics01643e01_etcdctl3_alarm_list
ccd_node_logs/seliics01643e01_ip_addresses
ccd_node_logs/seliics01643e01_ip_routes
ccd_node_logs/seliics01643e01_ssh_connection_succeeded

```

### Collect log files in cluster-cleanup

+ All archiveArtifacts log files of cluster-cleanup
+ Log files are collected from `/artifact/` link of Jenkins job
+ The log files uploaded to cluster logs [reports ARM repo](https://arm.seli.gic.ericsson.se//artifactory/proj-eea-reports-generic-local/clusterlogs/) as a single tar.gz file.
+ Format: tar.gz file archive named `collected-artifacts.tgz` containing all artifactory archived files of cluster-cleanup:

```
example:
>tar -t -f collected-artifacts.tar.gz
./
./archive/
./archive/check-namespaces-not-exist.log
./archive/cleanup-pvcs-eric-eea-ns.log
./archive/cleanup_eea_namespace.log
./archive/cleanup_utf_namespace.log
./archive/crd-cleanup.log
./archive/delete-meta-baseline-install-configmap.log
./archive/delete-product-baseline-install-configmap.log
./archive/k8s-cleanup-containerd-registry.log
./archive/k8s-cleanup-local-registry.log
./archive/log_collector_cleanup.log
./archive/log_collector_spotfire_cleanup.log
./archive/logs_eric-eea-ns_2023-09-13-22-11-28.tgz
./archive/logs_spotfire-platform_2024-03-26-09-00-08.tgz
./archive/post_cleanup.log
./archive/rook_ceph_status_before_cleanup.log
./archive/stuck-pods-eric-crd-ns.txt
./archive/stuck-pods-eric-eea-ns.txt
./archive/stuck-pods-utf-service.txt
./archive/stuck-pvcs-eric-crd-ns.txt
./archive/stuck-pvcs-eric-eea-ns.txt
./archive/stuck-pvcs-utf-service.txt
```

+ [EEAEPP-87378](https://eteamproject.internal.ericsson.com/browse/EEAEPP-87378)

### Collect robot tests log files in Prod CI pipelines

By default Prod CI pipelines contains only decisive Robot test execution stage, except eea-product-ci-meta-baseline-loop-test where both decisive and non-decisive stage is being executed.

A list of all robot related logs:

+ stage_Decisive_robot_Tests.log - console output logs from the "Decisive robot Tests" stage
+ stage_Non_decisive_robot_Tests.log - console output logs from the "Non_decisive robot Tests" stage
+ decisive-eea-robot.log - bob logs from the "Decisive robot Tests" stage
+ non_decisive-eea-robot.log - bob logs from the "Non_decisive robot Tests" stage
+ decisive-eea-robot-reports-"date"_"time".tar.gz - report's archive generated by decisive robot tests. Example decisive-eea-robot-reports-20240521_1332.tar.gz
+ non_decisive-eea-robot-reports-"date"_"time".tar.gz - report's archive generated by non_decisive robot tests. Example non_decisive-eea-robot-reports-20240521_1337.tar.gz

Example content/structure of the decisive/non_decisive report's archives:

```
tar -tf decisive-eea-robot-reports-20240516_1933.tar.gz 
decisive-eea-robot-reports/
decisive-eea-robot-reports/pabot_results/
decisive-eea-robot-reports/pabot_results/0/
decisive-eea-robot-reports/pabot_results/0/robot_stdout.out
decisive-eea-robot-reports/pabot_results/0/robot_stderr.out
decisive-eea-robot-reports/pabot_results/0/output.xml
decisive-eea-robot-reports/pabot_results/1/
decisive-eea-robot-reports/pabot_results/1/robot_stdout.out
decisive-eea-robot-reports/pabot_results/1/robot_stderr.out
decisive-eea-robot-reports/pabot_results/1/output.xml
decisive-eea-robot-reports/pabot_results/2/
decisive-eea-robot-reports/pabot_results/2/robot_stdout.out
decisive-eea-robot-reports/pabot_results/2/robot_stderr.out
decisive-eea-robot-reports/pabot_results/2/output.xml
decisive-eea-robot-reports/pabot_results/3/
decisive-eea-robot-reports/pabot_results/3/robot_stdout.out
decisive-eea-robot-reports/pabot_results/3/robot_stderr.out
decisive-eea-robot-reports/pabot_results/3/output.xml
decisive-eea-robot-reports/pabot_results/4/
decisive-eea-robot-reports/pabot_results/4/robot_stdout.out
decisive-eea-robot-reports/pabot_results/4/robot_stderr.out
decisive-eea-robot-reports/pabot_results/4/output.xml
decisive-eea-robot-reports/pabot_results/5/
decisive-eea-robot-reports/pabot_results/5/robot_stdout.out
decisive-eea-robot-reports/pabot_results/5/robot_stderr.out
decisive-eea-robot-reports/pabot_results/5/output.xml
decisive-eea-robot-reports/pabot_results/6/
decisive-eea-robot-reports/pabot_results/6/robot_stdout.out
decisive-eea-robot-reports/pabot_results/6/robot_stderr.out
decisive-eea-robot-reports/pabot_results/6/output.xml
decisive-eea-robot-reports/output.xml
decisive-eea-robot-reports/log.html
decisive-eea-robot-reports/report.html
```
