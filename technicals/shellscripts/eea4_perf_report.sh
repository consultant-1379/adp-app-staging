#!/bin/bash
#==================================================================================================================
#                                      REV
#==================================================================================================================
#2021-10-06 add CCD to node_info
#2021-10-07 microservices
#2021-10-07 add microservice to java_lang_memory function
#2021-10-11 java microservice fixed, save sript params
#2021-10-12 container level aggregation
#2021-10-20 image!="" added
#2021-10-29 container_memory: add "container_memory_failures_total" and rate group
#2021-10-29 add max_memory_workingset_per_limit and max_memory_usage_per_limit and to kube_pod_container_info
#2021-11-16 add fic contianer_cpu round, add releaseId to aggregated indexes
#2021-11-19 add comment to aggregated data
#2021-11-19 container label removed from container_netowrk
#2021-11-24 elastic_server contains port also
#2021-11-24 kube_container_info enhancement
#2021-11-29 add releaseId to kafka_info
#2021-12-03 besr metrics support
#2021-12-05 offsetchange for leader (replication not included) collect_kafka_info
#2021-12-09 New: collect_container_restart
#2021-12-20 label_aggregator_type
#2021-12-21 add new correlator metrics (rate)
#2021-12-21 add releaseId to csm and correlator metrics
#2021-12-21 add enrich_and_persist_csv function
#2021-12-21 enrich_and_persist_csv - vertica
#2022-01-03 enrich_and_persist_csv - refdat
#2022-01-03 persist build info
#2022-01-10 SUM on node level
#2022-01-11 EEARVA-13577 reason added to kube_container_info
#2022-01-13 add validation aggregation to node_network
#2022-03-04 metric_group option
#2022-03-25 vertica
#2022-03-26 eric-eea-db-loader-kafka-connect
#2022-04-24 build_data sep
#2022-04-26 MAJOR UPDATE: kube_pod_container_resource_(limits/requests)_(cpu_cores/memory_bytes) -> kube_pod_container_resource_(limits/requests){unit=,resource=}
#2022-04-28 Add releaseId to build_info
#2022-05-24 MAJOR UPDATE: kube_node_status_capacity_(cpu_cores/memory_bytes/pods) -> kube_node_status_capacity{unit=,resource=}
#                         kube_node_status_allocatable_(cpu_cores/memory_bytes/pods) -> kube_node_status_allocatable{unit=,resource=}
#2022-05-24 Add NFVI cluster
#2022-07-05 build_info fileds fixes
#2022-07-12 persist error/critical counts
#2022-07-12 Add collect_eea_logs_doc_number function
#2022-07-19 Add rook and ceph version to build_info
#2022-07-26 Exclude curator container
#2022-10-02 Remove label_aggregator_type condition from uservice argjason createon
#2022-10-02 default value of traffic_length_sec is NA
#2022-10-24 stream-aggregator uService imp.
#2022-12-07 add drop_sec parameter
#2023-02-28 add new parameters to build info
#2023-04-03 kafka_topics_v2 with throughput
#2023-06-02 add tool_chart_version and update cl477 clsuter config
#2023-06-15 save DATAFLOW_YAML

#==================================================================================================================
#                                      INFO
#==================================================================================================================
#---------------------------------
#    TODO
#---------------------------------
# - container_fs_ atnezni kivalogatni
# - node_filesystem TBD


#---------------------------------
#    HINTS
#---------------------------------

# HELP: ((.values|max[1]|tonumber) --> find max ts (last element) and take the index=1 (value)
# HELP: [.values[][1]|tonumber]|min) --> extract array, take index=1 (value), convert to number and find the min
# HELP: array[0] first element
# HELP: array[-1] last element
# HELP jq custom name {"\(.namespace)_\(.pod)": .label_app_kubernetes_io_name}



#PROM query
# sum (node_network_info{operstate="up",device!~"cali.*"}) by (device)
# sum (kube_pod_info)
# sum (kube_pod_info) by (node)
# sum (kube_pod_status_phase) by (phase)

# round in jq
#((.cpu_number - .idle) *10 | round /10)

#Grafana
# SI base quantity is 1000, units are B, kB, MB, GB, TB, PB, EB, ZB, YB
# IEC base quantity is 1024, units are B, KiB, MiB, GiB, TiB, PiB, EiB, ZiB, YiB
# SI vs EIC: https://www.drupal.org/project/drupal/issues/1114538
# doc["kbmemused"].value-doc["kbbuffers"].value-doc["kbcached"].value
# doc["node_disk_read_time_seconds_total"].value/doc["node_disk_reads_completed_total"].value*1000000
# doc["node_disk_write_time_seconds_total"].value/doc["node_disk_writes_completed_total"].value*1000000
# doc["TopicPartitionNumber"].value*doc["ReplicationFactor"].value

#Elastics
# mapping check by index: curl http://localhost:9200/prometheus_node_network/_mappings

#Node disk
# https://docs.signalfx.com/en/latest/integrations/agent/monitors/prometheus-node.html
# https://www.robustperception.io/mapping-iostat-to-the-node-exporters-node_disk_-metrics
# https://brian-candler.medium.com/interpreting-prometheus-metrics-for-linux-disk-i-o-utilization-4db53dfedcfc

#POD-container
# https://stackoverflow.com/questions/63020184/difference-between-kubernetes-metrics-metrics-resource-v1alpha1-and-metrics
# https://docs.signalfx.com/en/latest/integrations/agent/monitors/kubelet-stats.html#pause-containers
# https://www.ianlewis.org/en/almighty-pause-container

#==================================================================================================================
#                                      PARAMETERS
#==================================================================================================================
#--------------------------------------
# ENVIRONMENT RELATED VARIBLES
#--------------------------------------
# logstash config
logstash_config="/root/Scripts/logstash/eea4_metrics.conf"
# perf base dir
perf_logs_dir="PLEASE_SET/performance/logs"
# save script parameters to this file
script_param_file="/tmp/script.parameters"
# elastic server
elastic_server="seliics02376:9200"
# debug printouts
debug="false"
# collect json files
json_debug="false"
auto_confirm="false"
# traffic length (120mins?)
traffic_length_sec=0
processing_timeout_sec=2400

# Logstash etc files dir
logstash_etc_files_dir="NOT_SET"

#--------------------------------------
# PROCESSING RELATED VARIBLES
#--------------------------------------
# persist to elastics
persist="true"
# enable aggregation
enable_aggregation="true"
# namespace_filter
namespace_filter=".*"
# Drop <drop_sec> sec from the end of the given period
drop_sec=0
# simple query resolution
step=60
# rate query resolution
rate_step=60
# selected metric groups will be precessed
group_of_metrics="build,k8s,java,node,kafka,besr,database,csv,elastics"

#==================================================================================================================
#                                      FUNCTIONS
#==================================================================================================================

function load_cluster_config {
#---------------------------------------------------------------------------------------------------------
# Load cluster_config
# - set pm_server_ccd
# - set interface filter
# - set disk filter
# - load node_interface_argjson
# - load node_disk_argjson
#---------------------------------------------------------------------------------------------------------

case ${cluster_config} in
	#------------------------------------------
	#   CLUSTER_477
	#------------------------------------------
	cluster_477 | rv-CL477| 477)
		node_traffic_interface="p1p2"
		node_oam_interface="em1"
		node_interface_filter="em1|p1p2"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="rv-CL477"
        master="10.196.121.128"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"em1\": \"oam\",
		  \"p1p2\": \"traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		  \"sdd\": \"data\",
		  \"sde\": \"data\",
		  \"sdf\": \"data\",
		  \"sdg\": \"data\",
		  \"sdh\": \"data\",
		  \"sdi\": \"data\"
		}"
		;;

	#------------------------------------------
	#   CLUSTER_409
	#------------------------------------------
	cluster_409 | rv-CL409| 409)
		node_traffic_interface="eth2"
		node_oam_interface="eth0"
		node_interface_filter="eth0|eth2"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="rv-CL409"
        master="10.196.123.234"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"eth0\": \"oam\",
		  \"eth2\": \"traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		  \"sdd\": \"data\",
		  \"sde\": \"data\",
		  \"sdf\": \"data\",
		  \"sdg\": \"data\",
		  \"sdh\": \"data\",
		  \"sdi\": \"data\"
		}"
		;;

	#------------------------------------------
	#   CNIS_141
	#------------------------------------------
	cnis_141 | CNIS_141 | N141)
		node_traffic_interface="bond_data"
		node_oam_interface="app_ecfe_om"
		node_interface_filter="bond_data|app_ecfe_om|bond_storage"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="CNIS_141"
		pm_server_ccd="127.0.0.1:4142/select/0/prometheus"
		pm_server_eea="127.0.0.1:4141"
		data_search_engine_eea="127.0.0.1:4143"
		node_interface_argjson="
		{
		  \"app_ecfe_om\": \"oam\",
		  \"bond_data\": \"traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		  \"sdd\": \"data\",
		  \"sde\": \"data\",
		  \"sdf\": \"data\",
		  \"sdg\": \"data\",
		  \"sdh\": \"data\",
		  \"sdi\": \"data\"
		}"
		;;


	#------------------------------------------
	#   NFVI
	#------------------------------------------
	nfvi_ccd10 | NFVI_CCD10)
		# csm-media pool
		node_traffic_interface="eth2"
		node_oam_interface="eth0"
		node_interface_filter="eth.*"
		node_disk="vd.*"
		node_data_disk="vd[b-z]"
		cluster_config="NFVI_CCD10"
		director="eccd@10.221.183.189"
		pm_server_ccd="`ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no ${director} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}`:4770/select/0/prometheus"
		pm_server_eea="`ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no ${director} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}`:4771"
		data_search_engine_eea="`ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no ${director} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}`:4772"
		node_interface_argjson="
		{
		  \"eth0\": \"internal\",
		  \"eth1\": \"worker_oam\",
		  \"eth2\": \"csm-media\",
		  \"eth3\": \"spotfire-media\",
		  \"eth4\": \"iccr_media\",
		  \"eth5\": \"ccd_manila\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		}"
		;;

	#------------------------------------------
	#   CLUSTER_415
	#------------------------------------------
	cluster_415 | rv-CL415| 415)
		node_traffic_interface="ens192"
		node_oam_interface="ens192"
		node_interface_filter="ens192"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="rv-CL415"
		master_vip="10.196.123.129"
		worker_vip="10.196.123.130"
		pm_server_ccd="${worker_vip}:4773/select/0/prometheus"
		pm_server_eea="${worker_vip}:4771"
		data_search_engine_eea="${worker_vip}:4772"
		node_interface_argjson="
		{
		  \"ens192\": \"oam_and_traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		  \"sdd\": \"data\",
		  \"sde\": \"data\",
		  \"sdf\": \"data\",
		  \"sdg\": \"data\",
		  \"sdh\": \"data\",
		  \"sdi\": \"data\"
		}"
		;;

	#------------------------------------------
	#   CLUSTER_416
	#------------------------------------------
	cluster_416 | rv-CL416| 416)
		node_traffic_interface="eth1"
		node_oam_interface="eth0"
		node_interface_filter="eth*"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="rv-CL416"
		worker_vip="10.196.124.141"
		pm_server_ccd="${worker_vip}:4770/select/0/prometheus"
		pm_server_eea="${worker_vip}:4771"
		data_search_engine_eea="${worker_vip}:4772"
		node_interface_argjson="
		{
		  \"eth0\": \"oam_and_traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		  \"sdd\": \"data\",
		  \"sde\": \"data\",
		  \"sdf\": \"data\",
		  \"sdg\": \"data\",
		  \"sdh\": \"data\",
		  \"sdi\": \"data\"
		}"
		;;

	#------------------------------------------
	#   CLUSTER_420
	#------------------------------------------
	cluster_420 | rv-CL420| 420)
		node_traffic_interface="p1p2"
		node_oam_interface="em1"
		node_interface_filter="em1|p1p2"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="rv-CL420"
        master="10.196.121.62"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"em1\": \"oam\",
		  \"p1p2\": \"traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		  \"sdd\": \"data\",
		  \"sde\": \"data\",
		  \"sdf\": \"data\",
		  \"sdg\": \"data\",
		  \"sdh\": \"data\",
		  \"sdi\": \"data\"
		}"
		;;

	#------------------------------------------
	#   CLUSTER_499  IF update needed
	#------------------------------------------
	cluster_499 | rv-CL499| 499)
		node_traffic_interface="eth1"
		node_oam_interface="eth0"
		node_interface_filter="eth0|eth1"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="rv-CL499"
       	        master="10.196.121.226"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"eth0\": \"oam\",
		  \"eth1\": \"traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		  \"sdd\": \"data\",
		  \"sde\": \"data\",
		  \"sdf\": \"data\",
		  \"sdg\": \"data\",
		  \"sdh\": \"data\",
		  \"sdi\": \"data\"
		}"
		;;

	#------------------------------------------
	#   CLUSTER_411
	#------------------------------------------
	cluster_411 | rv-CL411| 411)
		node_traffic_interface="eth1"
		node_oam_interface="ens192"
		node_interface_filter="ens192|eth1"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="rv-CL411"
		worker_vip="10.196.123.241"
		pm_server_ccd="${worker_vip}:4770/select/0/prometheus"
		pm_server_eea="${worker_vip}:4771"
		data_search_engine_eea="${worker_vip}:4772"
		node_interface_argjson="
		{
		  \"ens192\": \"oam\",
		  \"eth1\": \"traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		  \"sdd\": \"data\",
		  \"sde\": \"data\",
		  \"sdf\": \"data\",
		  \"sdg\": \"data\",
		  \"sdh\": \"data\",
		  \"sdi\": \"data\"
		}"
		;;

	#------------------------------------------
	#   CLUSTER_410
	#------------------------------------------
	cluster_410 | rv-CL410| 410)
		node_traffic_interface="ens192"
		node_oam_interface="ens192"
		node_interface_filter="ens192"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="rv-CL410"
		worker_vip="10.196.123.227"
		pm_server_ccd="${worker_vip}:4770/select/0/prometheus"
		pm_server_eea="${worker_vip}:4771"
		data_search_engine_eea="${worker_vip}:4772"
		node_interface_argjson="
		{
		  \"ens192\": \"oam_and_traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		  \"sdd\": \"data\",
		  \"sde\": \"data\",
		  \"sdf\": \"data\",
		  \"sdg\": \"data\",
		  \"sdh\": \"data\",
		  \"sdi\": \"data\"
		}"
		;;

	#------------------------------------------
	#   insights-seliics04520
	#------------------------------------------
	insights-seliics04520 | 4520)
		node_traffic_interface="eth2"
		node_oam_interface="eth0"
		node_interface_filter="eth1|eth2"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="insights-seliics04520"
		worker_vip="10.196.123.118"
		pm_server_ccd="${worker_vip}:4770/select/0/prometheus"
		pm_server_eea="${worker_vip}:4771"
		data_search_engine_eea="${worker_vip}:4772"
		node_interface_argjson="
		{
		  \"eth0\": \"oam\",
		  \"eth2\": \"traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		  \"sdd\": \"data\",
		  \"sde\": \"data\",
		  \"sdf\": \"data\",
		  \"sdg\": \"data\",
		  \"sdh\": \"data\",
		  \"sdi\": \"data\",
		  \"sdj\": \"data\",
		  \"sdk\": \"data\"
		}"
		;;

	#------------------------------------------
	#   kubeconfig-seliics02452
	#------------------------------------------
	cluster_seliics02452 | kubeconfig-seliics02452| 2452)
		node_traffic_interface="eth1|p1p2"
		node_oam_interface="ens192"
		node_interface_filter="ens192|eth1|p1p2"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="kubeconfig-seliics02452"
        master="10.196.123.23"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"ens192\": \"oam\",
		  \"p1p2\": \"traffic\",
		  \"eth1\": \"traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		  \"sdd\": \"data\",
		  \"sde\": \"data\",
		  \"sdf\": \"data\",
		  \"sdg\": \"data\"
		}"
		;;

	#------------------------------------------
	#   kubeconfig-seliics02681
	#------------------------------------------
	cluster_seliics02681 | kubeconfig-seliics02681| 2681)
		node_traffic_interface="eth1|eth2|eth4|eth6"
		node_oam_interface="ens192"
		node_interface_filter="ens192|eth1|eth2|eth4|eth6"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="kubeconfig-seliics02681"
        master="10.196.122.177"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"ens192\": \"oam\",
		  \"eth1\": \"traffic\",
		  \"eth2\": \"traffic\",
		  \"eth4\": \"traffic\",
		  \"eth6\": \"traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		  \"sdd\": \"data\",
		  \"sde\": \"data\",
		  \"sdf\": \"data\",
		  \"sdg\": \"data\",
		  \"sdh\": \"data\",
		  \"sdi\": \"data\"

		}"
		;;

	#------------------------------------------
	#   kubeconfig-seliics02683_10G
	#------------------------------------------
	cluster_seliics02683_10G | kubeconfig-seliics02683-10G| 2683_10G)
		node_traffic_interface="eth0"
		node_oam_interface="eth0"
		node_interface_filter="eth0"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="kubeconfig-seliics02683-10G"
        master="10.196.122.145"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"eth0\": \"oam_and_traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		  \"sdd\": \"data\",
		  \"sde\": \"data\",
		  \"sdf\": \"data\",
		  \"sdg\": \"data\",
		  \"sdh\": \"data\",
		  \"sdi\": \"data\",
		  \"sdj\": \"data\",
		  \"sdk\": \"data\",
		  \"sdl\": \"data\",
		  \"sdm\": \"data\",
		  \"sdn\": \"data\"

		}"
		;;

	#------------------------------------------
	#   kubeconfig-seliics02696_10G
	#------------------------------------------
	cluster_seliics02696_10G | kubeconfig-seliics02696-10G| 2696_10G)
		node_traffic_interface="eth0"
		node_oam_interface="eth0"
		node_interface_filter="eth0"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="kubeconfig-seliics02696-10G"
        master="10.196.125.5"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"eth0\": \"oam_and_traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		  \"sdd\": \"data\",
		  \"sde\": \"data\",
		  \"sdf\": \"data\",
		  \"sdg\": \"data\",
		  \"sdh\": \"data\",
		  \"sdi\": \"data\",
		  \"sdj\": \"data\",
		  \"sdk\": \"data\",
		  \"sdl\": \"data\",
		  \"sdm\": \"data\",
		  \"sdn\": \"data\"

		}"
		;;


	#------------------------------------------
	#   kubeconfig-seliics03116
	#------------------------------------------
	cluster_seliics03116 | kubeconfig-seliics03116| 3116)
		node_traffic_interface="eth1|p1p2"
		node_oam_interface="eth0"
		node_interface_filter="eth0|eth1|p1p2"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="kubeconfig-seliics03116"
        master="10.196.125.77"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"eth0\": \"oam\",
		  \"p1p2\": \"traffic\",
		  \"eth1\": \"traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		  \"sdd\": \"data\",
		  \"sde\": \"data\",
		  \"sdf\": \"data\",
		  \"sdg\": \"data\"
		}"
		;;

	#------------------------------------------
	#   kubeconfig-seliics03117
	#------------------------------------------
	cluster_seliics03117 | kubeconfig-seliics03117| 3117)
		node_traffic_interface="eth1|p1p2"
		node_oam_interface="eth0"
		node_interface_filter="eth0|eth1|p1p2"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="kubeconfig-seliics03117"
        master="10.196.125.118"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"eth0\": \"oam\",
		  \"p1p2\": \"traffic\",
		  \"eth1\": \"traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		  \"sdd\": \"data\",
		  \"sde\": \"data\",
		  \"sdf\": \"data\",
		  \"sdg\": \"data\",
		  \"sdh\": \"data\",
		  \"sdi\": \"data\",
		  \"sdj\": \"data\",
		  \"sdk\": \"data\",
		  \"sdl\": \"data\",
		  \"sdm\": \"data\"

		}"
		;;

	#------------------------------------------
	#   kubeconfig-seliics03125
	#------------------------------------------
	cluster_seliics03125 | kubeconfig-seliics03125| 3125)
		node_traffic_interface="eth1|p1p2"
		node_oam_interface="ens192"
		node_interface_filter="ens192|eth1|p1p2"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="kubeconfig-seliics03125"
        master="10.196.125.87"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"ens192\": \"oam\",
		  \"p1p2\": \"traffic\",
		  \"eth1\": \"traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		  \"sdd\": \"data\",
		  \"sde\": \"data\",
		  \"sdf\": \"data\",
		  \"sdg\": \"data\",
		  \"sdh\": \"data\",
		  \"sdi\": \"data\",
		  \"sdj\": \"data\",
		  \"sdk\": \"data\",
		  \"sdl\": \"data\",
		  \"sdn\": \"data\",
		  \"sdm\": \"data\"
		}"
		;;

	#------------------------------------------
	#   kubeconfig-seliics04493_10G
	#------------------------------------------
	cluster_seliics04493_10G | kubeconfig-seliics04493-10G| 4493_10G)
		node_traffic_interface="eth0"
		node_oam_interface="eth0"
		node_interface_filter="eth0"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="kubeconfig-seliics04493-10G"
        master="10.196.124.164"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"eth0\": \"oam_and_traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		  \"sdd\": \"data\",
		  \"sde\": \"data\",
		  \"sdf\": \"data\",
		  \"sdg\": \"data\",
		  \"sdh\": \"data\",
		  \"sdi\": \"data\",
		  \"sdj\": \"data\",
		  \"sdk\": \"data\",
		  \"sdl\": \"data\",
		  \"sdm\": \"data\",
		  \"sdn\": \"data\"

		}"
		;;

	#------------------------------------------
	#   kubeconfig-seliics04510
	#------------------------------------------
	cluster_seliics04510 | kubeconfig-seliics04510| 4510)
		node_traffic_interface="eth1|eth2"
		node_oam_interface="ens192"
		node_interface_filter="ens192|eth1|eth2"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="kubeconfig-seliics04510"
        master="10.196.122.166"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"ens192\": \"oam\",
		  \"eth1\": \"traffic\",
		  \"eth2\": \"traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		  \"sdd\": \"data\",
		  \"sde\": \"data\",
		  \"sdf\": \"data\",
		  \"sdg\": \"data\",
		  \"sdh\": \"data\",
		  \"sdi\": \"data\",
		  \"sdj\": \"data\"
		}"
		;;

	#------------------------------------------
	#   kubeconfig-seliics04513
	#------------------------------------------
	cluster_seliics04513 | kubeconfig-seliics04513| 4513)
		node_traffic_interface="eth1|eth2"
		node_oam_interface="ens192"
		node_interface_filter="ens192|eth1|eth2"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="kubeconfig-seliics04513"
        master="10.196.122.181"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"ens192\": \"oam\",
		  \"eth1\": \"traffic\",
		  \"eth2\": \"traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		  \"sdd\": \"data\",
		  \"sde\": \"data\",
		  \"sdf\": \"data\",
		  \"sdg\": \"data\",
		  \"sdh\": \"data\",
		  \"sdi\": \"data\",
		  \"sdj\": \"data\"
		}"
		;;


	#------------------------------------------
	#   kubeconfig-seliics04534
	#------------------------------------------
	cluster_seliics04534 | kubeconfig-seliics04534| 4534)
		node_traffic_interface="eth1|eth2"
		node_oam_interface="ens192"
		node_interface_filter="ens192|eth1|eth2"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="kubeconfig-seliics04534"
        master="10.196.120.52"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"em1\": \"oam\",
		  \"eth1\": \"traffic\",
		  \"eth2\": \"traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		  \"sdd\": \"data\",
		  \"sde\": \"data\",
		  \"sdf\": \"data\",
		  \"sdg\": \"data\",
		  \"sdh\": \"data\"
		}"
		;;

	#------------------------------------------
	#   kubeconfig-seliics04535
	#------------------------------------------
	cluster_seliics04535 | kubeconfig-seliics04535| 4535)
		node_traffic_interface="eth1|eth2"
		node_oam_interface="ens192"
		node_interface_filter="ens192|eth1|eth2"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="kubeconfig-seliics04535"
        master="10.196.121.46"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"em1\": \"oam\",
		  \"eth1\": \"traffic\",
		  \"eth2\": \"traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		  \"sdd\": \"data\",
		  \"sde\": \"data\",
		  \"sdf\": \"data\",
		  \"sdg\": \"data\",
		  \"sdh\": \"data\",
		  \"sdh\": \"data\",
		  \"sdi\": \"data\",
		  \"sdj\": \"data\",
		  \"sdk\": \"data\",
		  \"sdl\": \"data\"
		}"
		;;
	#------------------------------------------
	#   kubeconfig-seliics04041
	#------------------------------------------
	cluster_productci_4041 | kubeconfig-seliics04041| 4041)
		node_traffic_interface="eth0"
		node_oam_interface="eth0"
		node_interface_filter="eth0"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="kubeconfig-seliics04041"
        master="10.196.123.229"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"eth0\": \"oam_and_traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		}"
		;;
	#------------------------------------------
	#   kubeconfig-seliics04493
	#------------------------------------------
	cluster_productci_4493 | kubeconfig-seliics04493| 4493)
		node_traffic_interface="eth0"
		node_oam_interface="eth0"
		node_interface_filter="eth0"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="kubeconfig-seliics04493"
        master="10.196.124.164"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"eth0\": \"oam_and_traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		}"
		;;
	#------------------------------------------
	#   kubeconfig-seliics04501
	#------------------------------------------
	cluster_productci_4501 | kubeconfig-seliics04501| 4501)
		node_traffic_interface="eth0"
		node_oam_interface="eth0"
		node_interface_filter="eth0"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="kubeconfig-seliics04501"
        master="10.196.123.239"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"eth0\": \"oam_and_traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		}"
		;;
	#------------------------------------------
	#   kubeconfig-seliics04503
	#------------------------------------------
	cluster_productci_4503 | kubeconfig-seliics04503| 4503)
		node_traffic_interface="eth0"
		node_oam_interface="eth0"
		node_interface_filter="eth0"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="kubeconfig-seliics04503"
        master="10.196.123.249"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"eth0\": \"oam_and_traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		}"
		;;
	#------------------------------------------
	#   kubeconfig-seliics04510
	#------------------------------------------
	cluster_productci_4510 | kubeconfig-seliics04510| 4510)
		node_traffic_interface="eth0"
		node_oam_interface="eth0"
		node_interface_filter="eth0"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="kubeconfig-seliics04510"
        master="10.196.122.166"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"eth0\": \"oam_and_traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		}"
		;;
	#------------------------------------------
	#   kubeconfig-seliics04513
	#------------------------------------------
	cluster_productci_4513 | kubeconfig-seliics04513| 4513)
		node_traffic_interface="eth0"
		node_oam_interface="eth0"
		node_interface_filter="eth0"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="kubeconfig-seliics04513"
        master="10.196.122.181"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"eth0\": \"oam_and_traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		}"
		;;
	#------------------------------------------
	#   kubeconfig-seliics04511
	#------------------------------------------
	cluster_productci_4511 | kubeconfig-seliics04511| 4511)
		node_traffic_interface="eth0"
		node_oam_interface="eth0"
		node_interface_filter="eth0"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="kubeconfig-seliics04511"
        master="10.196.122.148"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"eth0\": \"oam_and_traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		}"
		;;
	#------------------------------------------
	#   kubeconfig-seliics04516
	#------------------------------------------
	cluster_productci_4516 | kubeconfig-seliics04516| 4516)
		node_traffic_interface="eth0"
		node_oam_interface="eth0"
		node_interface_filter="eth0"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="kubeconfig-seliics04516"
        master="10.196.121.188"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"eth0\": \"oam_and_traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		}"
		;;
	#------------------------------------------
	#   kubeconfig-seliics04518
	#------------------------------------------
	cluster_productci_4518 | kubeconfig-seliics04518| 4518)
		node_traffic_interface="eth0"
		node_oam_interface="eth0"
		node_interface_filter="eth0"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="kubeconfig-seliics04518"
        master="10.196.121.186"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"eth0\": \"oam_and_traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		}"
		;;
	#------------------------------------------
	#   kubeconfig-seliics04532
	#------------------------------------------
	cluster_productci_4532 | kubeconfig-seliics04532| 4532)
		node_traffic_interface="eth0"
		node_oam_interface="eth0"
		node_interface_filter="eth0"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="kubeconfig-seliics04532"
        master="10.196.124.120"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"eth0\": \"oam_and_traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		}"
		;;
	#------------------------------------------
	#   kubeconfig-seliics04536
	#------------------------------------------
	cluster_productci_4536 | kubeconfig-seliics04536| 4536)
		node_traffic_interface="eth0"
		node_oam_interface="eth0"
		node_interface_filter="eth0"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="kubeconfig-seliics04536"
        master="10.196.122.109"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"eth0\": \"oam_and_traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		}"
		;;
	#------------------------------------------
	#   kubeconfig-seliics04539
	#------------------------------------------
	cluster_productci_4539 | kubeconfig-seliics04539| 4539)
		node_traffic_interface="eth0"
		node_oam_interface="eth0"
		node_interface_filter="eth0"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="kubeconfig-seliics04539"
        master="10.196.124.80"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"eth0\": \"oam_and_traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		}"
		;;

	#------------------------------------------
	#   kubeconfig-seliics07837
	#------------------------------------------
	cluster_productci_7837 | kubeconfig-seliics07837| 7837)
		node_traffic_interface="eth0"
		node_oam_interface="eth0"
		node_interface_filter="eth0"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="kubeconfig-seliics07837"
        master="10.196.120.137"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"eth0\": \"oam_and_traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		}"
		;;
	#------------------------------------------
	#   kubeconfig-seliics07839
	#------------------------------------------
	cluster_productci_7839 | kubeconfig-seliics07839| 7839)
		node_traffic_interface="eth0"
		node_oam_interface="eth0"
		node_interface_filter="eth0"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="kubeconfig-seliics07839"
        master="10.196.120.204"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"eth0\": \"oam_and_traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		}"
		;;
	#------------------------------------------
	#   kubeconfig-seliics07841
	#------------------------------------------
	cluster_productci_7841 | kubeconfig-seliics07841| 7841)
		node_traffic_interface="eth0"
		node_oam_interface="eth0"
		node_interface_filter="eth0"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="kubeconfig-seliics07841"
        master="10.196.120.209"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"eth0\": \"oam_and_traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		}"
		;;
	#------------------------------------------
	#   kubeconfig-seliics07843
	#------------------------------------------
	cluster_productci_7843 | kubeconfig-seliics07843| 7843)
		node_traffic_interface="eth0"
		node_oam_interface="eth0"
		node_interface_filter="eth0"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="kubeconfig-seliics07843"
        master="10.196.120.215"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"eth0\": \"oam_and_traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		}"
		;;
	#------------------------------------------
	#   kubeconfig-seliics07845
	#------------------------------------------
	cluster_productci_7845 | kubeconfig-seliics07845| 7845)
		node_traffic_interface="eth0"
		node_oam_interface="eth0"
		node_interface_filter="eth0"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="kubeconfig-seliics07845"
        master="10.196.123.225"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"eth0\": \"oam_and_traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		}"
		;;
	#------------------------------------------
	#   kubeconfig-seliics07847
	#------------------------------------------
	cluster_productci_7847 | kubeconfig-seliics07847| 7847)
		node_traffic_interface="eth0"
		node_oam_interface="eth0"
		node_interface_filter="eth0"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="kubeconfig-seliics07847"
        master="10.196.124.158"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"eth0\": \"oam_and_traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		}"
		;;
	#------------------------------------------
	#   kubeconfig-seliics07849
	#------------------------------------------
	cluster_productci_7849 | kubeconfig-seliics07849| 7849)
		node_traffic_interface="eth0"
		node_oam_interface="eth0"
		node_interface_filter="eth0"
		node_disk="sd.*"
		node_data_disk="sd[b-z]"
		cluster_config="kubeconfig-seliics07849"
        master="10.196.124.8"
		pm_server_ccd="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-victoria-metrics-cluster-vmselect-lb -n monitoring -o jsonpath={.status.loadBalancer.ingress[0].ip}):4770/select/0/prometheus"
		pm_server_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-pm-server-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4771"
		data_search_engine_eea="$(sshpass -p EvaiKiO1 ssh -q -o "UserKnownHostsFile=/dev/null" -o StrictHostKeyChecking=no root@${master} kubectl get svc/eric-data-search-engine-lb -n eric-eea-ns -o jsonpath={.status.loadBalancer.ingress[0].ip}):4772"
		node_interface_argjson="
		{
		  \"eth0\": \"oam_and_traffic\"
		}"
		node_disk_argjson="
		{
		  \"sda\": \"os\",
		  \"sdb\": \"data\",
		  \"sdc\": \"data\",
		}"
		;;
	#------------------------------------------
	#   NOT_SUPPORTED
	#------------------------------------------
	*)
	echo -e "\n ${cluster_config} is not supported as cluster_config!\n"
	exit 1
		;;
esac
}

function create_header_and_json_metrics {
#---------------------------------------------------------------------------------------------------------
#                               Generate Header and Json metric list
#---------------------------------------------------------------------------------------------------------
	unset report_columns_group_one
	unset json_metrics

	for counter in ${report_metrics[@]}
	do
		report_columns_group_one="${report_columns_group_one}${counter},"
		json_metrics="${json_metrics}.${counter},"
	done

	json_metrics=`echo ${json_metrics} | sed -e 's/,$//'`

	# HEADER
    echo "${report_columns_group_one}clusterName,buildTime" >  ${report_csv}
}

function perform_aggregation {
#---------------------------------------------------------------------------------------------------------
#                                        AGGREGATION
# $1 input CSV (mandatory)
# $2 output CSV (optional, defaul value: ${aggregation_csv})
#
# FIX for output file"
# - $agg_avg_max: counters which will be aggregated (min and max) FIX for a CSV
# - $agg_summaries: these counters will summarized FIX for a CSV
# - $agg_dimensions: could be grouped by this columns FIX for a CSV
#
# FIX for only an aggragation:
# - $agg_tag: free text
# - $agg_groupby: counters will by grouped by based on this parameter
#
# COLUMNS in output file:
# [BASE COL1] tag = $aggregation_tag 				-> fill up with sed
# [BASE COL2] ts = $1 								-> fill up with sed
# [BASE COL3] duration = $2-$1 						-> fill up with sed
# [BASE COL4] cluster_config 						-> fill up with sed
# [BASE COL5] build_start_time	 					-> fill up with sed
# [BASE COL6] release_id		 					-> fill up with sed
# [DIMENSION COL`S] ${agg_dimensions}				-> fill up with group / or sed
# [SUMMARY COL`S] summary of ${agg_summaries}		-> fill up with group / or sed
# [COUNTERS COLS`S] AVG and MAX of ${agg_avg_max}	-> fill up with "mean" and "max"
#-------------------------------------------------------------------------------------------------------

	agg_input_csv="$1"

	if [ ! -z $2 ]
	then
		agg_output_csv="$2"
	else
		agg_output_csv="${aggregation_csv}"
	fi

	if [ "${debug}" == "true" ]
	then
		echo " DEBUG [`date '+%m/%d %H:%M:%S'`] AGG input CSV: ${agg_input_csv}"
		echo " DEBUG [`date '+%m/%d %H:%M:%S'`] AGG input CSV: ${agg_output_csv}"
	fi

	#--------------------------------------------------------
	# If agg_output_csv does not exist then generate header
	#--------------------------------------------------------

	if [ ! -f ${agg_output_csv} ]
	then
		#-------------------------------------------
		# Generate aggregation_csv_header
		#-------------------------------------------
		# BASE (added by sed in the last step)
		aggregation_csv_header="tag,ts,duration,clusterName,buildTime,releaseId,comment"

		# DIMENSIONS (added by datamash group_by or later with "agg" value if missing in the given datamash)
		for column in ${agg_dimensions[@]}
		do
			aggregation_csv_header=${aggregation_csv_header},${column}
		done

		# SUMMARIZED (added by datamash sum)
		for column in ${agg_summaries[@]}
		do
			aggregation_csv_header=${aggregation_csv_header},sum.${column}
		done

		# AVERAGE (added by datamash mean)
		for column in ${agg_avg_max[@]}
		do
			aggregation_csv_header=${aggregation_csv_header},avg.${column}
		done

		# MAXIMUM (added by datamash max)
		for column in ${agg_avg_max[@]}
		do
			aggregation_csv_header=${aggregation_csv_header},max.${column}
		done

		echo "${aggregation_csv_header}" > ${agg_output_csv}

		if [ "${debug}" == "true" ]
		then
			echo -en " DEBUG [`date '+%m/%d %H:%M:%S'`] agg_metrics: "
			cat  ${agg_output_csv}
		fi
	fi

	#--------------------------------------------------------
	# Find index for each agg_avg_max value from report header if any
	#--------------------------------------------------------
	if [ ${#agg_avg_max[@]} -gt 0 ]
	then
		unset agg_counter_indexes
		header_array=(`cat ${agg_input_csv} | head -1 | tr ',' ' '`)

		for counter in ${agg_avg_max[@]}
		do
			for (( b=0;b<${#header_array[@]};b++));
			do
				if [ "${counter}" == "${header_array[b]}" ]
				then
					agg_counter_indexes="${agg_counter_indexes},$((b+1))"
					break
				fi
			done
		done
		#remove leading ","
		agg_counter_indexes="${agg_counter_indexes:1}"

		if [ "${debug}" == "true" ]
		then
			echo " DEBUG [`date '+%m/%d %H:%M:%S'`] agg_metrics: ${agg_avg_max[@]}"
			echo " DEBUG [`date '+%m/%d %H:%M:%S'`] agg_metrics_indexes:${agg_counter_indexes}"
		fi
	fi
	#-----------------------------------------------------------
	# Find index for each agg_summaries value from report header if any
	#-----------------------------------------------------------
	if [ ${#agg_summaries[@]} -gt 0 ]
	then
		unset agg_summaries_indexes
		header_array=(`cat $1 | head -1 | tr ',' ' '`)

		for counter in ${agg_summaries[@]}
		do
			for (( b=0;b<${#header_array[@]};b++));
			do
				if [ "${counter}" == "${header_array[b]}" ]
				then
					agg_summaries_indexes="${agg_summaries_indexes},$((b+1))"
					break
				fi
			done
		done
		#remove leading ","
		agg_summaries_indexes="${agg_summaries_indexes:1}"

		if [ "${debug}" == "true" ]
		then
			echo " DEBUG [`date '+%m/%d %H:%M:%S'`] agg_summaries: ${agg_summaries[@]}"
			echo " DEBUG [`date '+%m/%d %H:%M:%S'`] agg_summaries_indexes:${agg_summaries_indexes}"
		fi
	fi
	#------------------------------------------------------------
	# Find index for each agg_groupby value from report header if any
	#------------------------------------------------------------
	if [ ${#agg_groupby[@]} -gt 0 ]
	then
		unset agg_groupby_indexes
		header_array=(`cat $1 | head -1 | tr ',' ' '`)

		for counter in ${agg_groupby[@]}
		do
			for (( b=0;b<${#header_array[@]};b++));
			do
				if [ "${counter}" == "${header_array[b]}" ]
				then
					agg_groupby_indexes="${agg_groupby_indexes},$((b+1))"
					break
				fi
			done
		done

		#remove leading ","
		agg_groupby_indexes="${agg_groupby_indexes:1}"

		if [ "${debug}" == "true" ]
		then
			echo " DEBUG [`date '+%m/%d %H:%M:%S'`] agg_groupby: ${agg_groupby[@]}"
			echo " DEBUG [`date '+%m/%d %H:%M:%S'`] agg_groupby_indexes:${agg_groupby_indexes}"
		fi
	fi

	#------------------------------------------------------------
	# Aggregation
	#------------------------------------------------------------

	# group_by + summary + AVG,MAX
	if [ ${#agg_groupby[@]} -gt 0 ] && [ ${#agg_summaries[@]} -gt 0 ] &&  [ ${#agg_avg_max[@]} -gt 0 ]
	then
		if [ "${debug}" == "true" ]
		then
			echo " DEBUG [`date '+%m/%d %H:%M:%S'`] Command: datamash -s -R 3 -t , --header-in -g ${agg_groupby_indexes} sum ${agg_summaries_indexes} mean ${agg_counter_indexes} max ${agg_counter_indexes}"
		fi
		agg_temp_result="`cat $1 | datamash -s -R 3 -t , --header-in -g ${agg_groupby_indexes} sum ${agg_summaries_indexes} mean ${agg_counter_indexes} max ${agg_counter_indexes} | sed -e 's/^/,/g'`"
	# group_by + AVG,MAX
	elif [ ${#agg_groupby[@]} -gt 0 ] && [ ${#agg_summaries[@]} -eq 0 ] &&  [ ${#agg_avg_max[@]} -gt 0 ]
	then

		if [ "${debug}" == "true" ]
		then
			echo " DEBUG [`date '+%m/%d %H:%M:%S'`] Command: datamash -s -R 3 -t , --header-in -g ${agg_groupby_indexes} mean ${agg_counter_indexes} max ${agg_counter_indexes}"
		fi
		agg_temp_result="`cat $1 | datamash -s -R 3 -t , --header-in -g ${agg_groupby_indexes} mean ${agg_counter_indexes} max ${agg_counter_indexes} | sed -e 's/^/,/g'`"
	# summary + AVG,MAX
	elif [ ${#agg_groupby[@]} -eq 0 ] && [ ${#agg_summaries[@]} -gt 0 ] &&  [ ${#agg_avg_max[@]} -gt 0 ]
	then
		if [ "${debug}" == "true" ]
		then
			echo " DEBUG [`date '+%m/%d %H:%M:%S'`] Command: datamash -s -R 3 -t , --header-in sum ${agg_summaries_indexes} mean ${agg_counter_indexes} max ${agg_counter_indexes}"
		fi
		agg_temp_result="`cat $1 | datamash -s -R 3 -t , --header-in sum ${agg_summaries_indexes} mean ${agg_counter_indexes} max ${agg_counter_indexes} | sed -e 's/^/,/g'`"
	# AVG,MAX
	elif [ ${#agg_groupby[@]} -eq 0 ] && [ ${#agg_summaries[@]} -eq 0 ] &&  [ ${#agg_avg_max[@]} -gt 0 ]
	then
		if [ "${debug}" == "true" ]
		then
			echo " DEBUG [`date '+%m/%d %H:%M:%S'`] Command: datamash -s -R 3 -t , --header-in mean ${agg_counter_indexes} max ${agg_counter_indexes}"
		fi
		agg_temp_result="`cat $1 | datamash -s -R 3 -t , --header-in mean ${agg_counter_indexes} max ${agg_counter_indexes} | sed -e 's/^/,/g'`"
	# group_by + summary
	elif [ ${#agg_groupby[@]} -gt 0 ] && [ ${#agg_summaries[@]} -gt 0 ] &&  [ ${#agg_avg_max[@]} -eq 0 ]
	then
		if [ "${debug}" == "true" ]
		then
			echo " DEBUG [`date '+%m/%d %H:%M:%S'`] Command: datamash -s -R 3 -t , --header-in -g ${agg_groupby_indexes} sum ${agg_summaries_indexes}"
		fi
		agg_temp_result="`cat $1 | datamash -s -R 3 -t , --header-in -g ${agg_groupby_indexes} sum ${agg_summaries_indexes} | sed -e 's/^/,/g'`"
	fi

	#---------------------------------------------------------------------------------------------------
	# Insert dummy value if a dimension was not used in the calculation just to keep the column`s order
	#---------------------------------------------------------------------------------------------------
	for (( i=0;i<${#agg_dimensions[@]};i++));
	do
		if [ -z "`echo ${agg_groupby[@]} | grep ${agg_dimensions[i]}`" ]
		then
			#column is not present in agg_groupby array then insert a dummy value
			agg_temp_result="`echo \"${agg_temp_result}\" | sed 's/,/,aggregated,/'$((i+1))''`"
		fi
	done

	#---------------------------------------------------------------------------------------------------
	# Enrich with tag, start_ts, duration, cluster_config, build_start_time, release_id, build_comment and store in CSV
	#---------------------------------------------------------------------------------------------------
	echo "${agg_temp_result}" | sed -e 's/^/'${agg_tag}','$start_ts','$(( $end_ts - $start_ts ))','${cluster_config}','${build_start_time}','${release_id}','${build_comment}'/g' >> ${agg_output_csv}
}

function collect_container_cpu {
#---------------------------------------------------------------------------------------------------------
# Prometheus metrics group #1 (simple, host=node)
#  - kube_pod_container_resource_limits{resource="cpu",unit="core"}
#  - kube_pod_container_resource_requests{resource="cpu",unit="core"}
#
# Prometheus metrics group #2 (rate, host=kubernetes_io_hostname)
#  - container_cpu_cfs_periods_total
#  - container_cpu_cfs_throttled_periods_total
#  - container_cpu_cfs_throttled_seconds_total
#  - container_cpu_system_seconds_total
#  - container_cpu_usage_seconds_total
#  - container_cpu_user_seconds_total
#
# Report metrics
#  - pod
#  - namespace
#  - microservice
#  - container
#  - node
#  - ts
#  - pod_phase
#  - kube_pod_container_resource_limits_cpu_cores       (kube_pod_container_resource_limits{resource="cpu"})
#  - kube_pod_container_resource_requests_cpu_cores     (kube_pod_container_resource_requests{resource="cpu"})
#  - container_cpu_cfs_periods_total
#  - container_cpu_cfs_throttled_periods_total
#  - container_cpu_cfs_throttled_seconds_total
#  - container_cpu_system_seconds_total
#  - container_cpu_usage_seconds_total
#  - container_cpu_user_seconds_total
#---------------------------------------------------------------------------------------------------------
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Collect container_cpu metrics"

# FILES
report_csv="${output_dir}/container_cpu${tag}.csv"
uservice_report_csv="${output_dir}/uservice_cpu${tag}.csv"
aggregation_csv="${output_dir}/agg_uservice_cpu${tag}.csv"
debug_json="${output_dir}/container_cpu${tag}.json"

# METRICS
prometheus_metrics_group_one=(kube_pod_container_resource_limits kube_pod_container_resource_requests)
prometheus_metrics_group_two=(container_cpu_cfs_periods_total container_cpu_cfs_throttled_periods_total container_cpu_cfs_throttled_seconds_total container_cpu_system_seconds_total container_cpu_user_seconds_total container_cpu_usage_seconds_total)
report_metrics=(pod namespace microservice container node ts pod_phase kube_pod_container_resource_limits_cpu_cores kube_pod_container_resource_requests_cpu_cores ${prometheus_metrics_group_two[@]})

# HEADER and json_metrics variable
create_header_and_json_metrics

# DATA
(for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query='${counter}'{resource="cpu",unit="core",container!~"POD|curator|",namespace=~"'${namespace_filter}'"}' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r \
'[.data.result[] | {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, node: .metric.node, tsvalue: .values[]} | { namespace, pod, container, node, ts: .tsvalue[0], "'${counter}'_cpu_cores": .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]'
done;
for counter in ${prometheus_metrics_group_two[@]}
do
curl -s \
--data-urlencode 'query=round(rate('${counter}'{container!~"POD|curator|",image!="",namespace=~"'${namespace_filter}'"}['${rate_step}'s]),0.001)' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${rate_step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r \
'[.data.result[] | {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, node: .metric.kubernetes_io_hostname, tsvalue: .values[]} | { namespace, pod, container, node, ts: .tsvalue[0], "'${counter}'": .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]'
done) \
| jq -r -s \
--argjson microservice "`echo ${microservice_argjson}`" \
--slurpfile pod_phase ${temp_pod_phase_ref_json_file} \
'map(.[]) | group_by(.ts, .namespace, .pod, .container)[] | add | .microservice += $microservice[(.namespace + "_" + .pod)] | .pod_phase += $pod_phase[0][(.namespace + "_" + .pod + "_" + (.ts|tostring))] | ['${json_metrics}',"'${cluster_config}'", "'${build_start_time}'" ] | @csv' \
| sed -e 's/\"//g' >>  ${report_csv}

# STREAM-AGGREGATOR uSERVICE update
sed -i 's/\(eric-eea-stream-aggregator-operator-[^-]*-[^-]*,eric-eea-ns\),eric-eea-stream-aggregator,\(.*\)$/\1,eric-eea-stream-aggregator-operator,\2/g; s/\(eric-eea-stream-aggregator-[^,]*-driver\),eric-eea-ns,eric-eea-stream-aggregator,\(.*\)$/\1,eric-eea-ns,\1,\2/g; s/\(eric-eea-stream-aggregator-.*\)\(-[^-]*-exec-[0-9]*\),eric-eea-ns,eric-eea-stream-aggregator,\(.*\)$/\1\2,eric-eea-ns,\1,\3/g' ${report_csv}

# uSERVICE
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Calculate uservice_cpu metrics"

# filter for running pods and header and replace empty values with 0 in CSV
grep "unning\|,namespace," ${report_csv} | sed -e 's/,,/,0,/g' -e 's/,,/,0,/g' > ${filtered_report_csv}

rm -f ${uservice_report_csv}

#Calculate MIN and MAX for each counter
agg_avg_max=()
#Grouped_by
agg_dimensions=(ts namespace microservice pod container)
#Will be summarized
agg_summaries=(kube_pod_container_resource_limits_cpu_cores kube_pod_container_resource_requests_cpu_cores container_cpu_usage_seconds_total container_cpu_cfs_throttled_seconds_total)
agg_tag="sum_microservice"
agg_groupby=(ts namespace microservice)
perform_aggregation ${filtered_report_csv} ${uservice_report_csv}
#remove sum. from the headers
sed -i 's/,sum\./,/g' ${uservice_report_csv}

# AGGREGATION
if [ "$2" == "true" ]
then
	echo " INFO  [`date '+%m/%d %H:%M:%S'`] Aggregate uservice_cpu metrics"

	# remove old aggregation
	rm -rf ${aggregation_csv}

	#Calculate MIN and MAX for each counter
	agg_avg_max=(kube_pod_container_resource_limits_cpu_cores kube_pod_container_resource_requests_cpu_cores container_cpu_cfs_throttled_seconds_total container_cpu_usage_seconds_total)
	#Grouped_by
	agg_dimensions=(namespace microservice pod container)
	#Will be summarized
	agg_summaries=()

	#-----------------------------------------------------------------------------
	# !! agg_groupby has to be the subset of agg_dimensions, strict order
	#-----------------------------------------------------------------------------

	#Aggregation #1
	agg_tag="per_microservice"
	agg_groupby=(namespace microservice)
	perform_aggregation ${uservice_report_csv}

	#Aggregation #2
	agg_tag="per_container"
	agg_groupby=(namespace microservice pod container)
	perform_aggregation ${filtered_report_csv}

fi

# PERSIST
if [ "$1" == "true" ]
then
	persist ${report_csv} eea4_container_cpu
	#persist ${uservice_report_csv} eea4_uservice_cpu
	persist ${aggregation_csv} eea4_aggregated_container_cpu
fi

# DEBUG
if [ "${json_debug}" == "true" ]
then
	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json}"

for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query='${counter}'{resource="cpu",unit="core",container!~"POD|",namespace=~"'${namespace_filter}'"}' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r \
'[.data.result[] | {ns: .metric.namespace, pod: .metric.pod, cont: .metric.container, host: .metric.node, tsvalue: .values[]} | { ns, pod, cont, host, ts: .tsvalue[0], "'${counter}'_cpu_cores": .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]'
done > ${debug_json}

for counter in ${prometheus_metrics_group_two[@]}
do
curl -s \
--data-urlencode 'query=round(rate('${counter}'{container!~"POD|",namespace=~"'${namespace_filter}'"}['${rate_step}'s]),0.001)' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${rate_step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r \
'[.data.result[] | {ns: .metric.namespace, pod: .metric.pod, cont: .metric.container, host: .metric.kubernetes_io_hostname, tsvalue: .values[]} | { ns, pod, cont, host, ts: .tsvalue[0], "'${counter}'": .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]'
done >> ${debug_json}
fi
}

function collect_container_memory {
#---------------------------------------------------------------------------------------------------------
# Prometheus metrics group #1 (simple, host=node)
#  - kube_pod_container_resource_limits
#  - kube_pod_container_resource_requests
#
# Prometheus metrics group #2(simple, host=kubernetes_io_hostname)
#  - container_memory_cache
#  - container_memory_max_usage_bytes
#  - container_memory_rss
#  - container_memory_swap
#  - container_memory_usage_bytes
#  - container_memory_working_set_bytes
#
# Prometheus metrics group #3(rate, host=kubernetes_io_hostname)
#  - container_memory_failcnt
#  - container_memory_failures_total
#  - container_memory_mapped_file

#
# Report metrics
#  - pod
#  - namespace
#  - microservice
#  - container
#  - node
#  - ts
#  - pod_phase
#  - kube_pod_container_resource_limits_memory_bytes
#  - kube_pod_container_resource_requests_memory_bytes
#  - container_memory_cache
#  - container_memory_failcnt
#  - container_memory_failures_total
#  - container_memory_mapped_file
#  - container_memory_max_usage_bytes
#  - container_memory_rss
#  - container_memory_swap
#  - container_memory_usage_bytes
#  - container_memory_working_set_bytes
#
#---------------------------------------------------------------------------------------------------------
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Collect container_memory metrics"

# FILES
report_csv="${output_dir}/container_memory${tag}.csv"
uservice_report_csv="${output_dir}/uservice_memory${tag}.csv"
aggregation_csv="${output_dir}/agg_uservice_memory${tag}.csv"
debug_json="${output_dir}/container_memory${tag}.json"

# METRICS
prometheus_metrics_group_one=(kube_pod_container_resource_limits kube_pod_container_resource_requests)
prometheus_metrics_group_two=(container_memory_cache container_memory_max_usage_bytes container_memory_rss container_memory_swap container_memory_usage_bytes container_memory_working_set_bytes)
prometheus_metrics_group_three=(container_memory_failcnt container_memory_failures_total container_memory_mapped_file)
report_metrics=(pod namespace microservice container node ts pod_phase kube_pod_container_resource_limits_memory_bytes kube_pod_container_resource_requests_memory_bytes ${prometheus_metrics_group_two[@]} ${prometheus_metrics_group_three[@]})

# HEADER and json_metrics variable
create_header_and_json_metrics

# DATA
(for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query='${counter}'{resource="memory",unit="byte",container!~"POD|",namespace=~"'${namespace_filter}'"}' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r \
'[.data.result[] | {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, node: .metric.node, tsvalue: .values[]} | { namespace, pod, container, node, ts: .tsvalue[0], "'${counter}'_memory_bytes": .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]'
done;
for counter in ${prometheus_metrics_group_two[@]}
do
curl -s \
--data-urlencode 'query='${counter}'{container!~"POD|",image!="",namespace=~"'${namespace_filter}'"}' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r \
'[.data.result[] | {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, node: .metric.kubernetes_io_hostname, tsvalue: .values[]} | { namespace, pod, container, node, ts: .tsvalue[0], "'${counter}'": .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]'
done;
for counter in ${prometheus_metrics_group_three[@]}
do
curl -s \
--data-urlencode 'query=round(rate('${counter}'{container!~"POD|",image!="",namespace=~"'${namespace_filter}'"}['${rate_step}'s]),0.1)' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r \
'[.data.result[] | {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, node: .metric.kubernetes_io_hostname, tsvalue: .values[]} | { namespace, pod, container, node, ts: .tsvalue[0], "'${counter}'": .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]'
done) \
| jq -r -s \
--argjson microservice "`echo ${microservice_argjson}`" \
--slurpfile pod_phase ${temp_pod_phase_ref_json_file} \
'map(.[]) | group_by(.ts, .namespace, .pod, .container)[] | add | .microservice += $microservice[(.namespace + "_" + .pod)] | .pod_phase += $pod_phase[0][(.namespace + "_" + .pod + "_" + (.ts|tostring))] | ['${json_metrics}',"'${cluster_config}'", "'${build_start_time}'" ] | @csv' \
| sed -e 's/\"//g' >>  ${report_csv}

# STREAM-AGGREGATOR uSERVICE update
sed -i 's/\(eric-eea-stream-aggregator-operator-[^-]*-[^-]*,eric-eea-ns\),eric-eea-stream-aggregator,\(.*\)$/\1,eric-eea-stream-aggregator-operator,\2/g; s/\(eric-eea-stream-aggregator-[^,]*-driver\),eric-eea-ns,eric-eea-stream-aggregator,\(.*\)$/\1,eric-eea-ns,\1,\2/g; s/\(eric-eea-stream-aggregator-.*\)\(-[^-]*-exec-[0-9]*\),eric-eea-ns,eric-eea-stream-aggregator,\(.*\)$/\1\2,eric-eea-ns,\1,\3/g' ${report_csv}

# uSERVICE
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Calculate uservice_memory metrics"

# filter for running pods and header and replace empty values with 0 in CSV
grep "unning\|,namespace," ${report_csv} | sed -e 's/,,/,0,/g' -e 's/,,/,0,/g' > ${filtered_report_csv}

rm -f ${uservice_report_csv}

#Calculate MIN and MAX for each counter
agg_avg_max=()
#Grouped_by
agg_dimensions=(ts namespace microservice pod container)
#Will be summarized
agg_summaries=(kube_pod_container_resource_limits_memory_bytes kube_pod_container_resource_requests_memory_bytes container_memory_working_set_bytes container_memory_cache)
agg_tag="sum_microservice"
agg_groupby=(ts namespace microservice)
perform_aggregation ${filtered_report_csv} ${uservice_report_csv}
#remove sum. from the headers
sed -i 's/,sum\./,/g' ${uservice_report_csv}

# AGGREGATION
if [ "$2" == "true" ]
then
	echo " INFO  [`date '+%m/%d %H:%M:%S'`] Aggregate uservice_memory metrics"

	# remove old aggregation
	rm -rf ${aggregation_csv}

	#Calculate MIN and MAX for each counter
	agg_avg_max=(kube_pod_container_resource_limits_memory_bytes kube_pod_container_resource_requests_memory_bytes container_memory_working_set_bytes container_memory_cache)
	#Grouped_by
	agg_dimensions=(namespace microservice pod container)
	#Will be summarized
	agg_summaries=()

	#-----------------------------------------------------------------------------
	# !! agg_groupby has to be the subset of agg_dimensions, strict order
	#-----------------------------------------------------------------------------

	# Aggregation #1
	agg_tag="per_microservice"
	agg_groupby=(namespace microservice)
	perform_aggregation ${uservice_report_csv}

	# Aggregation #2
	agg_tag="per_container"
	agg_groupby=(namespace microservice pod container)
	perform_aggregation ${filtered_report_csv}
fi

# PERSIST
if [ "$1" == "true" ]
then
	persist ${report_csv} eea4_container_memory
	#persist ${uservice_report_csv} eea4_uservice_memory
	persist ${aggregation_csv} eea4_aggregated_container_memory
fi

# DEBUG
if [ "${json_debug}" == "true" ]
then
	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json}"

for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query='${counter}'{resource="memory",unit="byte",container!~"POD|",namespace=~"'${namespace_filter}'"}' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r \
'[.data.result[] | {ns: .metric.namespace, pod: .metric.pod, cont: .metric.container, host: .metric.node, tsvalue: .values[]} | { ns, pod, cont, host, ts: .tsvalue[0], "'${counter}'_memory_bytes": .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]'
done > ${debug_json}

for counter in ${prometheus_metrics_group_two[@]}
do
curl -s \
--data-urlencode 'query='${counter}'{container!~"POD|",namespace=~"'${namespace_filter}'"}' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r \
'[.data.result[] | {ns: .metric.namespace, pod: .metric.pod, cont: .metric.container, host: .metric.kubernetes_io_hostname, tsvalue: .values[]} | { ns, pod, cont, host, ts: .tsvalue[0], "'${counter}'": .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]'
done >> ${debug_json}
fi
}

function collect_container_network {
#---------------------------------------------------------------------------------------------------------
# Prometheus metrics group #1 (rate)
#  - container_network_receive_bytes_total
#  - container_network_receive_errors_total
#  - container_network_receive_packets_dropped_total
#  - container_network_receive_packets_total
#  - container_network_transmit_bytes_total
#  - container_network_transmit_errors_total
#  - container_network_transmit_packets_dropped_total
#  - container_network_transmit_packets_total
#
# Report metrics
#  - pod
#  - namespace
#  - microservice
#  - node
#  - ts
#  - pod_phase
#  - container_network_receive_bytes_total
#  - container_network_receive_errors_total
#  - container_network_receive_packets_dropped_total
#  - container_network_receive_packets_total
#  - container_network_transmit_bytes_total
#  - container_network_transmit_errors_total
#  - container_network_transmit_packets_dropped_total
#  - container_network_transmit_packets_total
#
# sum_by:
#   pod
#   namespace
#   kubernetes_io_hostname
#
# NOTE: only POD level, container label removed
# CCD 2.19.1   container="POD" filter removed since this label is removed
#---------------------------------------------------------------------------------------------------------
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Collect container_network metrics"


report_csv="${output_dir}/container_network${tag}.csv"
uservice_report_csv="${output_dir}/uservice_network${tag}.csv"
aggregation_csv="${output_dir}/agg_uservice_network${tag}.csv"
debug_json="${output_dir}/container_network${tag}.json"

# METRICS
prometheus_metrics_group_one=(container_network_receive_bytes_total container_network_receive_errors_total container_network_receive_packets_dropped_total container_network_receive_packets_total container_network_transmit_bytes_total container_network_transmit_errors_total container_network_transmit_packets_dropped_total container_network_transmit_packets_total)
report_metrics=(pod namespace microservice node ts pod_phase ${prometheus_metrics_group_one[@]})

# HEADER and json_metrics variable
create_header_and_json_metrics

# DATA
for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query=round(sum by (pod,namespace,kubernetes_io_hostname) (rate('${counter}'{namespace=~"'${namespace_filter}'"}['${rate_step}'s])),1)' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${rate_step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r \
'[.data.result[] | {namespace: .metric.namespace, pod: .metric.pod, node: .metric.kubernetes_io_hostname, tsvalue: .values[]} | { namespace, pod, node, ts: .tsvalue[0], "'${counter}'": .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]'
done \
| jq -r -s \
--argjson microservice "`echo ${microservice_argjson}`" \
--slurpfile pod_phase ${temp_pod_phase_ref_json_file} \
'map(.[]) | group_by(.ts, .namespace, .pod, .node)[] | add | .microservice += $microservice[(.namespace + "_" + .pod)] | .pod_phase += $pod_phase[0][(.namespace + "_" + .pod + "_" + (.ts|tostring))] | ['${json_metrics}', "'${cluster_config}'", "'${build_start_time}'"] | @csv' \
| sed -e 's/\"//g' >> ${report_csv}

# STREAM-AGGREGATOR uSERVICE update
sed -i 's/\(eric-eea-stream-aggregator-operator-[^-]*-[^-]*,eric-eea-ns\),eric-eea-stream-aggregator,\(.*\)$/\1,eric-eea-stream-aggregator-operator,\2/g; s/\(eric-eea-stream-aggregator-[^,]*-driver\),eric-eea-ns,eric-eea-stream-aggregator,\(.*\)$/\1,eric-eea-ns,\1,\2/g; s/\(eric-eea-stream-aggregator-.*\)\(-[^-]*-exec-[0-9]*\),eric-eea-ns,eric-eea-stream-aggregator,\(.*\)$/\1\2,eric-eea-ns,\1,\3/g' ${report_csv}

# uSERVICE
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Calculate uservice_network metrics"

rm -f ${uservice_report_csv}

# filter for running pods and headerin and replace empty values with 0 in CSV
grep "unning\|,namespace," ${report_csv} | sed -e 's/,,/,0,/g' -e 's/,,/,0,/g' > ${filtered_report_csv}

#Calculate MIN and MAX for each counter
agg_avg_max=()
#Grouped_by
agg_dimensions=(ts namespace microservice)
#Will be summarized
agg_summaries=(${prometheus_metrics_group_one[@]})
agg_tag="sum_microservice"
agg_groupby=(ts namespace microservice)
perform_aggregation ${filtered_report_csv} ${uservice_report_csv}
#remove sum. from the headers
sed -i 's/,sum\./,/g' ${uservice_report_csv}

# AGGREGATION
if [ "$2" == "true" ]
then
	echo " INFO  [`date '+%m/%d %H:%M:%S'`] Aggregate uservice_network metrics"

	# remove old aggregation
	rm -rf ${aggregation_csv}

	#Calculate MIN and MAX for each counter
	agg_avg_max=(${prometheus_metrics_group_one[@]})
	#Grouped_by
	agg_dimensions=(namespace microservice)
	#Will be summarized
	agg_summaries=()

	#-----------------------------------------------------------------------------
	# !! agg_groupby has to be the subset of agg_dimensions, strict order
	#-----------------------------------------------------------------------------

	# Aggregation #1
	agg_tag="per_microservice"
	agg_groupby=(namespace microservice)
	perform_aggregation ${uservice_report_csv}

fi

# PERSIST
if [ "$1" == "true" ]
then
	persist ${report_csv} eea4_container_network
	#persist ${uservice_report_csv} eea4_uservice_network
	persist ${aggregation_csv} eea4_aggregated_container_network
fi
# DEBUG
if [ "${json_debug}" == "true" ]
then
	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json}"

for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query=round(sum by (pod,namespace,kubernetes_io_hostname) (rate('${counter}'{namespace=~"'${namespace_filter}'"}['${rate_step}'s])),1)' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${rate_step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r \
'[.data.result[] | {ns: .metric.namespace, pod: .metric.pod, host: .metric.kubernetes_io_hostname, tsvalue: .values[]} | { ns, pod, host, ts: .tsvalue[0], "'${counter}'": .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]'
done > ${debug_json}
fi
}

function collect_container_fs {
#---------------------------------------------------------------------------------------------------------
# Prometheus metrics group #1
#   - container_fs_inodes_free
#   - container_fs_usage_bytes
#   - container_fs_limit_bytes
#   - container_fs_io_current
#
# Prometheus metrics group #2 (rate)
#  - container_fs_inodes_total
#  - container_fs_io_time_seconds_total
#  - container_fs_io_time_weighted_seconds_total
#  - container_fs_read_seconds_total
#  - container_fs_reads_bytes_total
#  - container_fs_reads_merged_total
#  - container_fs_reads_total
#  - container_fs_sector_reads_total
#  - container_fs_sector_writes_total
#  - container_fs_write_seconds_total
#  - container_fs_writes_bytes_total
#  - container_fs_writes_merged_total
#  - container_fs_writes_total
#
# Report metrics
#   - pod
#   - namespace
#   - microservice
#   - container
#   - node
#   - ts
#   - pod_phase
#   - container_fs_inodes_free
#   - container_fs_usage_bytes
#   - container_fs_limit_bytes
#   - container_fs_io_current
#   - container_fs_inodes_total
#   - container_fs_io_time_seconds_total
#   - container_fs_io_time_weighted_seconds_total
#   - container_fs_read_seconds_total
#   - container_fs_reads_bytes_total
#   - container_fs_reads_merged_total
#   - container_fs_reads_total
#   - container_fs_sector_reads_total
#   - container_fs_sector_writes_total
#   - container_fs_write_seconds_total
#   - container_fs_writes_bytes_total
#   - container_fs_writes_merged_total
#   - container_fs_writes_total
# sum_by:
#   pod
#   container
#   namespace
#   kubernetes_io_hostname
#--------------------------------------------------------------------------------------------------------
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Collect container_fs metrics"

# FILES
report_csv="${output_dir}/container_fs${tag}.csv"
uservice_report_csv="${output_dir}/uservice_fs${tag}.csv"
aggregation_csv="${output_dir}/agg_uservice_fs${tag}.csv"
debug_json="${output_dir}/container_fs${tag}.json"

# METRICS
prometheus_metrics_group_one=(container_fs_inodes_free container_fs_usage_bytes container_fs_limit_bytes container_fs_io_current)
prometheus_metrics_group_two=(container_fs_inodes_total container_fs_io_time_seconds_total container_fs_io_time_weighted_seconds_total container_fs_read_seconds_total container_fs_reads_bytes_total container_fs_reads_merged_total container_fs_reads_total container_fs_sector_reads_total container_fs_sector_writes_total container_fs_write_seconds_total container_fs_writes_bytes_total container_fs_writes_merged_total container_fs_writes_total)
report_metrics=(pod namespace microservice container node ts pod_phase ${prometheus_metrics_group_one[@]} ${prometheus_metrics_group_two[@]})

# HEADER and json_metrics variable
create_header_and_json_metrics

# DATA
(for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query=sum by (pod,namespace,container,kubernetes_io_hostname) ('${counter}'{container!~"POD|",image!="",namespace=~"'${namespace_filter}'"})' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r \
'[.data.result[] | {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, node: .metric.kubernetes_io_hostname, tsvalue: .values[]} | { namespace, pod, container, node, ts: .tsvalue[0], "'${counter}'": .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]'
done;
for counter in ${prometheus_metrics_group_two[@]}
do
curl -s \
--data-urlencode 'query=round(sum by (pod,namespace,container,kubernetes_io_hostname) (rate('${counter}'{container!~"POD|",namespace=~"'${namespace_filter}'"}['${rate_step}'s])),0.1)' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${rate_step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r \
'[.data.result[] | {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, node: .metric.kubernetes_io_hostname, tsvalue: .values[]} | { namespace, pod, container, node, ts: .tsvalue[0], "'${counter}'": .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]'
done) \
| jq -r -s \
--argjson microservice "`echo ${microservice_argjson}`" \
--slurpfile pod_phase ${temp_pod_phase_ref_json_file} \
'map(.[]) | group_by(.ts, .namespace, .pod, .container, .node)[] | add | .microservice += $microservice[(.namespace + "_" + .pod)] | .pod_phase += $pod_phase[0][(.namespace + "_" + .pod + "_" + (.ts|tostring))] | ['${json_metrics}', "'${cluster_config}'", "'${build_start_time}'"] | @csv' \
| sed -e 's/\"//g' >> ${report_csv}

# STREAM-AGGREGATOR uSERVICE update
sed -i 's/\(eric-eea-stream-aggregator-operator-[^-]*-[^-]*,eric-eea-ns\),eric-eea-stream-aggregator,\(.*\)$/\1,eric-eea-stream-aggregator-operator,\2/g; s/\(eric-eea-stream-aggregator-[^,]*-driver\),eric-eea-ns,eric-eea-stream-aggregator,\(.*\)$/\1,eric-eea-ns,\1,\2/g; s/\(eric-eea-stream-aggregator-.*\)\(-[^-]*-exec-[0-9]*\),eric-eea-ns,eric-eea-stream-aggregator,\(.*\)$/\1\2,eric-eea-ns,\1,\3/g' ${report_csv}


# uSERVICE
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Calculate uservice_fs metrics"

rm -f ${uservice_report_csv}

# filter for running pods and headerin and replace empty values with 0 in CSV
grep "unning\|,namespace," ${report_csv} | sed -e 's/,,/,0,/g' -e 's/,,/,0,/g' > ${filtered_report_csv}

#Calculate MIN and MAX for each counter
agg_avg_max=()
#Grouped_by
agg_dimensions=(ts namespace microservice)
#Will be summarized
agg_summaries=(container_fs_reads_bytes_total container_fs_writes_bytes_total container_fs_usage_bytes)
agg_tag="sum_microservice"
agg_groupby=(ts namespace microservice)
perform_aggregation ${filtered_report_csv} ${uservice_report_csv}
#remove sum. from the headers
sed -i 's/,sum\./,/g' ${uservice_report_csv}

# AGGREGATION
if [ "$2" == "true" ]
then
	echo " INFO  [`date '+%m/%d %H:%M:%S'`] Aggregate uservice_fs metrics"

	# remove old aggregation
	rm -rf ${aggregation_csv}

	#Calculate MIN and MAX for each counter
	agg_avg_max=(container_fs_reads_bytes_total container_fs_writes_bytes_total container_fs_usage_bytes)
	#Grouped_by
	agg_dimensions=(namespace microservice)
	#Will be summarized
	agg_summaries=()

	#-----------------------------------------------------------------------------
	# !! agg_groupby has to be the subset of agg_dimensions, strict order
	#-----------------------------------------------------------------------------

	# Aggregation #1
	agg_tag="per_microservice"
	agg_groupby=(namespace microservice)
	perform_aggregation ${uservice_report_csv}
fi

# PERSIST
if [ "$1" == "true" ]
then
	persist ${report_csv} eea4_container_fs
	#persist ${uservice_report_csv} eea4_uservice_fs
	persist ${aggregation_csv} eea4_aggregated_container_fs
fi

# DEBUG
if [ "${json_debug}" == "true" ]
then
	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json}"

for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query=sum by (pod,namespace,container,kubernetes_io_hostname) ('${counter}'{container!="",namespace=~"'${namespace_filter}'"})' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r \
'[.data.result[] | {ns: .metric.namespace, pod: .metric.pod, cont: .metric.container, host: .metric.kubernetes_io_hostname, tsvalue: .values[]} | { ns, pod, cont, host, ts: .tsvalue[0], "'${counter}'": .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]'
done > ${debug_json}

for counter in ${prometheus_metrics_group_two[@]}
do
curl -s \
	--data-urlencode 'query=round(sum by (pod,namespace,container,kubernetes_io_hostname) (rate('${counter}'{container!="",namespace=~"'${namespace_filter}'"}['${rate_step}'s])),0.1)' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${rate_step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r \
'[.data.result[] | {ns: .metric.namespace, pod: .metric.pod, cont: .metric.container, host: .metric.kubernetes_io_hostname, tsvalue: .values[]} | { ns, pod, cont, host, ts: .tsvalue[0], "'${counter}'": .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]'
done >> ${debug_json}

fi
}

function collect_container_restart {
#---------------------------------------------------------------------------------------------------------
# Prometheus metrics group #1
#   - kube_pod_container_status_restarts_total
#
# Report metrics
#   - pod
#   - namespace
#   - microservice
#   - container
#   - ts
#   - kube_pod_container_status_restarts_total
#--------------------------------------------------------------------------------------------------------
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Collect container_restart metrics"

# FILES
report_csv="${output_dir}/container_restart${tag}.csv"
debug_json="${output_dir}/container_restart${tag}.json"

# METRICS
prometheus_metrics_group_one=(kube_pod_container_status_restarts_total)
report_metrics=(pod namespace microservice container ts ${prometheus_metrics_group_one[@]} ${prometheus_metrics_group_two[@]})

# HEADER and json_metrics variable
create_header_and_json_metrics

# DATA
(for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query='${counter}'{container!~"POD|",namespace=~"'${namespace_filter}'"}' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r \
'[.data.result[] | {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, tsvalue: .values[]} | { namespace, pod, container, ts: .tsvalue[0], "'${counter}'": .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]'
done) \
| jq -r -s \
--argjson microservice "`echo ${microservice_argjson}`" \
'map(.[]) | group_by(.ts, .namespace, .pod, .container)[] | add | .microservice += $microservice[(.namespace + "_" + .pod)] | ['${json_metrics}', "'${cluster_config}'", "'${build_start_time}'"] | @csv' \
| sed -e 's/\"//g' >> ${report_csv}

# STREAM-AGGREGATOR uSERVICE update
sed -i 's/\(eric-eea-stream-aggregator-operator-[^-]*-[^-]*,eric-eea-ns\),eric-eea-stream-aggregator,\(.*\)$/\1,eric-eea-stream-aggregator-operator,\2/g; s/\(eric-eea-stream-aggregator-[^,]*-driver\),eric-eea-ns,eric-eea-stream-aggregator,\(.*\)$/\1,eric-eea-ns,\1,\2/g; s/\(eric-eea-stream-aggregator-.*\)\(-[^-]*-exec-[0-9]*\),eric-eea-ns,eric-eea-stream-aggregator,\(.*\)$/\1\2,eric-eea-ns,\1,\3/g' ${report_csv}

# PERSIST
if [ "$1" == "true" ]
then
	persist ${report_csv} eea4_container_restart
fi

# DEBUG
if [ "${json_debug}" == "true" ]
then
	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json}"

for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query='${counter}'{container!~"POD|",namespace=~"'${namespace_filter}'"})' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r \
'[.data.result[] | {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, tsvalue: .values[]} | { namespace, pod, container, ts: .tsvalue[0], "'${counter}'": .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]'
done > ${debug_json}

fi
}

function collect_pod_filesystem {
#---------------------------------------------------------------------------------------------------------
# Prometheus metrics group #1
#  - node_filesystem_size_bytes
#  - node_filesystem_avail_bytes
#
# Report metrics
#  - ts
#  - node
#  - role
#  - disk
#  - mountpoint
#  - fstype
#  - node_filesystem_size_bytes
#  - node_filesystem_avail_bytes
#  - node_filesystem_used_bytes  CALCULATED = node_filesystem_size_bytes - node_filesystem_avail_bytes
#
# mountpoint: /var/lib/kubelet/pods/11159a02-3c65-49cd-a8da-ba879e60ced5/volumes/kubernetes.io~csi/pvc-2162b03c-4a35-4fe4-a352-27f6229cf295/mount
# mountpoint: /var/lib/kubelet/pods/<pod`s_uid>/volumes/kubernetes.io~csi/<volumename>/mount
#
# kube_pod_info: pod <-> uid
# kube_persistentvolumeclaim_info: volumename <-> persistentvolumeclaim
#---------------------------------------------------------------------------------------------------------
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Collect node_filesystem metrics"

# FILES
report_csv="${output_dir}/pod_filesystem${tag}.csv"
debug_json="${output_dir}/pod_filesystem${tag}.json"

# METRICS
prometheus_metrics_group_one=(node_filesystem_size_bytes node_filesystem_avail_bytes)
report_metrics=(node ts disk mountpoint fstype ${prometheus_metrics_group_one[@]} node_filesystem_used_bytes)

# HEADER and json_metrics variable
create_header_and_json_metrics

# DATA
for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query='${counter}'{fstype!="tmpfs",mountpoint=~"/var/lib/kubelet/pods/.*"}' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${rate_step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r \
--argjson node_name "`echo ${node_name_argjson}`" \
'[.data.result[] | {node: $node_name[(.metric.instance)], fstype: .metric.fstype, mountpoint: .metric.mountpoint, disk: .metric.device, tsvalue: .values[]} | { node, fstype, mountpoint, disk, ts: .tsvalue[0], "'${counter}'": (.tsvalue[1]|tonumber)} |  with_entries(select( .value != null ))]'
done | jq -r -s \
--argjson node_role "`echo ${node_role_argjson}`" \
'map(.[]) | group_by (.disk, .ts, .node, .fstype, .mountpoint)[] | add | .role += $node_role[(.node)] | .node_filesystem_used_bytes += .node_filesystem_size_bytes - .node_filesystem_avail_bytes| ['${json_metrics}', "'${cluster_config}'", "'${build_start_time}'"] | @csv' \
| sed -e 's/\"//g' >> ${report_csv}

# PERSIST
if [ "$1" == "true" ]
then
	persist	${report_csv} eea4_pod_filesystem
fi

# DEBUG
if [ "${json_debug}" == "true" ]
then
	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json}"

for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query='${counter}'{device=~"'${node_disk}'"}' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${rate_step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r '[.data.result[] | {instance: .metric.instance, fstype: .metric.fstype, mountpoint: .metric.mountpoint, device: .metric.device, tsvalue: .values[]} | { instance, fstype, mountpoint, device, ts: .tsvalue[0], "'${counter}'": (.tsvalue[1]|tonumber)} |  with_entries(select( .value != null ))]'
done > ${debug_json}
fi
}

function collect_java_memory {
#---------------------------------------------------------------------------------------------------------
# PM_SERVER_EEA (added to CCD to keep data between runs)
#
# Prometheus metrics group #1 = Report metrics group #1
#  - java_lang_Memory_NonHeapMemoryUsage_used
#  - java_lang_Memory_HeapMemoryUsage_used
#  - java_lang_Memory_HeapMemoryUsage_max
#  - java_lang_Memory_HeapMemoryUsage_init
#
# Report metrics
#  - ts
#  - namespace
#  - pod
#  - app
#  - microservice
#  - java_lang_Memory_NonHeapMemoryUsage_used
#  - java_lang_Memory_NonHeapMemoryUsage_used
#  - java_lang_Memory_HeapMemoryUsage_used
#  - java_lang_Memory_HeapMemoryUsage_max
#  - java_lang_Memory_HeapMemoryUsage_init
#
#---------------------------------------------------------------------------------------------------------
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Collect java_lang_memory metrics"

# FILES
report_csv="${output_dir}/java_memory${tag}.csv"
#aggregation_csv="${output_dir}/agg_java_memory${tag}.csv"
debug_json="${output_dir}/java_memory${tag}.json"

# METRICS
prometheus_metrics_group_one=(java_lang_Memory_NonHeapMemoryUsage_used java_lang_Memory_HeapMemoryUsage_used java_lang_Memory_HeapMemoryUsage_max java_lang_Memory_HeapMemoryUsage_init)
report_metrics=(pod namespace app microservice ts ${prometheus_metrics_group_one[@]})

# HEADER and json_metrics variable
create_header_and_json_metrics

# DATA
for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query='${counter}'{kubernetes_namespace=~"'${namespace_filter}'"}' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r \
'[.data.result[] | {namespace: .metric.kubernetes_namespace, app: .metric.app, pod: .metric.kubernetes_pod_name, tsvalue: .values[]} | { namespace, pod, app, ts: .tsvalue[0], "'${counter}'": .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]'
done \
| jq -r -s \
--argjson microservice "`echo ${microservice_argjson}`" \
'map(.[]) | group_by(.ts, .namespace, .pod, .app)[] | add | .microservice += $microservice[(.namespace + "_" + .pod)] | ['${json_metrics}', "'${cluster_config}'", "'${build_start_time}'" ] | @csv' \
| sed -e 's/\"//g' >>  ${report_csv}

# PERSIST
if [ "$1" == "true" ]
then
	persist	${report_csv} eea4_java_lang_memory
fi

# DEBUG
if [ "${json_debug}" == "true" ]
then
	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json}"

for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query='${counter}'{kubernetes_namespace=~"'${namespace_filter}'"}' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r \
'[.data.result[] | {ns: .metric.kubernetes_namespace, app: .metric.app, pod: .metric.kubernetes_pod_name, tsvalue: .values[]} | { ns, pod, app, ts: .tsvalue[0], "'${counter}'": .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]'
done > ${debug_json}
fi
}

function collect_kube_pod_container_info {
#---------------------------------------------------------------------------------------------------------
#
# Prometheus metrics group #1
#  - kube_pod_container_resource_limits
#  - kube_pod_container_resource_requests
#  - kube_pod_container_info
#
# Prometheus metrics group #2
#  - kube_pod_container_status_running
#  - kube_pod_container_status_ready
#  - kube_pod_container_status_terminated
#  - kube_pod_container_status_waiting
#
# +
#  - kube_pod_container_status_restarts_total
#  - container_memory_failcnt
#  - container_memory_usage_bytes
#  - container_memory_working_set_bytes
#  - container_cpu_usage_seconds_total
#  - kube_pod_container_status_terminated_reason
#
# Report metrics
#  - ts
#  - pod			(kube_pod_container_info)
#  - namespace		(kube_pod_container_info)
#  - container		(kube_pod_container_info)
#  - image			(kube_pod_container_info)
#  - image_id		(kube_pod_container_info)
#  - microservice	 --> enriched data
#  - ReleaseId	 --> enriched data

#  _NOTE_ kube_pod_container_resource_limits_<request>_<unit>s
#  _NOTE_ kube_pod_container_resource_requests<request>_<unit>s
#  - kube_pod_container_resource_limits_cpu_cores  (= kube_pod_container_resource_limits{unit=core,request=cpu}
#  - kube_pod_container_resource_limits_memory_bytes  (= kube_pod_container_resource_limits{unit=byte,request=memory}
#  - kube_pod_container_resource_requests_cpu_cores
#  - kube_pod_container_resource_requests_memory_bytes

#  - kube_pod_container_status_running
#  - kube_pod_container_status_ready
#  - kube_pod_container_status_terminated
#  - kube_pod_container_status_waiting
#  - kube_pod_container_status_terminated_reason
#
#  - kube_pod_container_status_restarts_total
#  - container_memory_failcnt
#  - container_cpu_cfs_throttled_seconds_total
#
#  - max_memory_usage  (container_memory_usage_bytes)
#  - min_memory_usage  (container_memory_usage_bytes)
#  - max_memory_working_set  (container_memory_working_set_bytes)
#  - min_memory_working_set  (container_memory_working_set_bytes)
#  - max_cpu_usage  (container_cpu_usage_seconds_total)
#  - min_cpu_usage  (container_cpu_usage_seconds_total)
#
#  - max_cpu_usage_per_limit   --> enriched data = max_cpu_usage / kube_pod_container_resource_limits_cpu_cores
#  - max_cpu_usage_per_request   --> enriched data = max_cpu_usage / kube_pod_container_resource_requests_cpu_cores
#
#  - max_memory_usage_per_limit  --> enriched data = max_memory_usage / kube_pod_container_resource_limits_memory_bytes
#  - max_memory_usage_per_request   --> enriched data = max_memory_usage / kube_pod_container_resource_requests_memory_bytes
#
#  - max_memory_workingset_per_limit  --> enriched data = max_memory_working_set / kube_pod_container_resource_limits_memory_bytes
#  - max_memory_workingset_per_request   --> enriched data = max_memory_working_set / kube_pod_container_resource_requests_memory_bytes
#
#---------------------------------------------------------------------------------------------------------
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Collect kube_pod_container_info metrics"

# FILE
report_csv="${output_dir}/container_info${tag}.csv"
debug_json="${output_dir}/container_info${tag}_group1.json"
debug_json2="${output_dir}/container_info${tag}_group2.json"
debug_json3="${output_dir}/container_info${tag}_restart.json"
debug_json4="${output_dir}/container_info${tag}_failcnt.json"
debug_json5="${output_dir}/container_info${tag}_mem_usage.json"
debug_json6="${output_dir}/container_info${tag}_mem_workingset.json"
debug_json7="${output_dir}/container_info${tag}_cpu_usage.json"

# METRICS
prometheus_metrics_group_one=(kube_pod_container_resource_limits kube_pod_container_resource_requests kube_pod_container_info)
prometheus_metrics_group_two=(kube_pod_container_status_running kube_pod_container_status_ready kube_pod_container_status_terminated kube_pod_container_status_waiting)
report_metrics=(pod namespace microservice container node image image_id kube_pod_container_status_restarts_total container_memory_failcnt container_cpu_cfs_throttled_seconds_total max_memory_workingset_per_limit max_memory_workingset_per_request max_memory_usage_per_limit max_memory_usage_per_request max_memory_usage min_memory_usage max_memory_working_set min_memory_working_set max_cpu_usage min_cpu_usage max_cpu_usage_per_limit max_cpu_usage_per_request ts kube_pod_container_resource_limits_cpu_cores kube_pod_container_resource_limits_memory_bytes kube_pod_container_resource_requests_cpu_cores kube_pod_container_resource_requests_memory_bytes ${prometheus_metrics_group_two[@]} kube_pod_container_status_terminated_reason releaseId)

# HEADER and json_metrics variable
create_header_and_json_metrics

# DATA

# HELP: ((.values|max[1]|tonumber) --> find max ts (last element) and take the index=1 (value)
# HELP: [.values[][1]|tonumber]|min) --> extract array, take index=1 (value), convert to number and find the min
# HELP: array[0] first element, array[-1] last element

(for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query='${counter}'{namespace=~"'${namespace_filter}'"}' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r \
'[.data.result[] | {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, image: .metric.image, image_id: .metric.image_id, resource: .metric.resource, unit: .metric.unit, tsvalue: .values[0]} | { namespace, pod, container, image, image_id, "'${counter}'_\(.resource)_\(.unit)s": .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]'
done;

for counter in ${prometheus_metrics_group_two[@]}
do
curl -s \
--data-urlencode 'query='${counter}'{namespace=~"'${namespace_filter}'"}' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r \
'[.data.result[] | {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, tsvalue: .values[-1]} | { namespace, pod, container, image, image_id, "'${counter}'": .tsvalue[1]|tonumber}  | with_entries(select( .value != null ))]'
done;

curl -s \
--data-urlencode 'query=kube_pod_container_status_terminated_reason{namespace=~"'${namespace_filter}'"} ==1' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r '[.data.result[]| {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, kube_pod_container_status_terminated_reason: .metric.reason }]';

curl -s \
--data-urlencode 'query=kube_pod_container_status_restarts_total{namespace=~"'${namespace_filter}'"}' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r '[.data.result[]| {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, "kube_pod_container_status_restarts_total": ((.values|max[1]|tonumber) - (.values|min[1]|tonumber)) }]';

curl -s \
--data-urlencode 'query=container_memory_failcnt{container!~"POD|",image!="",namespace=~"'${namespace_filter}'"}' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r '[.data.result[]| {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, node: .metric.instance, "container_memory_failcnt": ((.values|max[1]|tonumber) - (.values|min[1]|tonumber)) }]';

curl -s \
--data-urlencode 'query=container_memory_usage_bytes{container!~"POD|",image!="",namespace=~"'${namespace_filter}'"}' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r '[.data.result[]| {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, node: .metric.instance, "max_memory_usage": ([.values[][1]|tonumber]|max), "min_memory_usage": ([.values[][1]|tonumber]|min) }]';

curl -s \
--data-urlencode 'query=container_memory_working_set_bytes{container!~"POD|",image!="",namespace=~"'${namespace_filter}'"}' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r '[.data.result[]| {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, node: .metric.instance, "max_memory_working_set": ([.values[][1]|tonumber]|max), "min_memory_working_set": ([.values[][1]|tonumber]|min)}]';

curl -s \
--data-urlencode 'query=container_cpu_cfs_throttled_seconds_total{container!~"POD|",image!="",namespace=~"'${namespace_filter}'"}' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r '[.data.result[]| {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, node: .metric.instance, "container_cpu_cfs_throttled_seconds_total": (((.values|max[1]|tonumber) - (.values|min[1]|tonumber)) * 100 | round / 100)}]';

curl -s \
--data-urlencode 'query=round(rate(container_cpu_usage_seconds_total{container!~"POD|",image!="",namespace=~"'${namespace_filter}'"}['${rate_step}'s]),0.001)' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r '[.data.result[]| {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, node: .metric.instance, "max_cpu_usage": ([.values[][1]|tonumber]|max), "min_cpu_usage": ([.values[][1]|tonumber]|min)}]' ) \
| jq -r -s \
--argjson microservice "`echo ${microservice_argjson}`" \
'map(.[]) | group_by (.pod, .namespace, .container)[] | add | .microservice += $microservice[(.namespace + "_" + .pod)] | if (.max_memory_usage == null or .kube_pod_container_resource_limits_memory_bytes == null or .kube_pod_container_resource_limits_memory_bytes == 0 ) then .max_memory_usage_per_limit += "0" else .max_memory_usage_per_limit += (.max_memory_usage / .kube_pod_container_resource_limits_memory_bytes * 100 | round / 100) end | if (.max_memory_working_set == null or .kube_pod_container_resource_limits_memory_bytes == null or .kube_pod_container_resource_limits_memory_bytes == 0 ) then .max_memory_workingset_per_limit += "0" else .max_memory_workingset_per_limit += (.max_memory_working_set / .kube_pod_container_resource_limits_memory_bytes * 100 | round / 100) end | if (.max_cpu_usage == null or .kube_pod_container_resource_limits_cpu_cores == null or .kube_pod_container_resource_limits_cpu_cores == 0 ) then .max_cpu_usage_per_limit += "0" else .max_cpu_usage_per_limit += (.max_cpu_usage / .kube_pod_container_resource_limits_cpu_cores * 100 | round / 100)  end | if (.max_memory_usage == null or .kube_pod_container_resource_requests_memory_bytes == null or .kube_pod_container_resource_requests_memory_bytes == 0 ) then .max_memory_usage_per_request += "0" else .max_memory_usage_per_request += (.max_memory_usage / .kube_pod_container_resource_requests_memory_bytes * 100 | round / 100) end | if (.max_memory_working_set == null or .kube_pod_container_resource_requests_memory_bytes == null or .kube_pod_container_resource_requests_memory_bytes == 0 ) then .max_memory_workingset_per_request += "0" else .max_memory_workingset_per_request += (.max_memory_working_set / .kube_pod_container_resource_requests_memory_bytes * 100 | round / 100) end | if (.max_cpu_usage == null or .kube_pod_container_resource_requests_cpu_cores == null or .kube_pod_container_resource_requests_cpu_cores == 0 ) then .max_cpu_usage_per_request += "0" else .max_cpu_usage_per_request += ( .max_cpu_usage / .kube_pod_container_resource_requests_cpu_cores * 100 | round / 100 )  end | .ts += "'$start_ts'" | .releaseId += "'${release_id}'" | ['${json_metrics}', "'${cluster_config}'", "'${build_start_time}'"] | @csv' | sed -e 's/\"//g' >> ${report_csv}

# STREAM-AGGREGATOR uSERVICE update
sed -i 's/\(eric-eea-stream-aggregator-operator-[^-]*-[^-]*,eric-eea-ns\),eric-eea-stream-aggregator,\(.*\)$/\1,eric-eea-stream-aggregator-operator,\2/g; s/\(eric-eea-stream-aggregator-[^,]*-driver\),eric-eea-ns,eric-eea-stream-aggregator,\(.*\)$/\1,eric-eea-ns,\1,\2/g; s/\(eric-eea-stream-aggregator-.*\)\(-[^-]*-exec-[0-9]*\),eric-eea-ns,eric-eea-stream-aggregator,\(.*\)$/\1\2,eric-eea-ns,\1,\3/g' ${report_csv}

# PERSIST
if [ "$1" == "true" ]
then
	persist	${report_csv} eea4_kube_pod_container_info
fi

# DEBUG
if [ "${json_debug}" == "true" ]
then

	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json}"

for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query='${counter}'{namespace=~"'${namespace_filter}'"}' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r \
'[.data.result[] | {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, image: .metric.image, image_id: .metric.image_id, tsvalue: .values[0]} | { namespace, pod, container, image, image_id, "'${counter}'_\(.resource)_\(.unit)s": .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]'
done > ${debug_json}

	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json2}"

for counter in ${prometheus_metrics_group_two[@]}
do
curl -s \
--data-urlencode 'query='${counter}'{namespace=~"'${namespace_filter}'"}' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r \
'[.data.result[] | {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, tsvalue: .values[-1]} | { namespace, pod, container, image, image_id, "'${counter}'": .tsvalue[1]|tonumber}  | with_entries(select( .value != null ))]'
done >> ${debug_json2}

	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json3}"

curl -s \
--data-urlencode 'query=kube_pod_container_status_restarts_total{namespace=~"'${namespace_filter}'"}' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r '[.data.result[]| {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, "kube_pod_container_status_restarts_total": ((.values|max[1]|tonumber) - (.values|min[1]|tonumber)) }]' > ${debug_json3}

	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json4}"

curl -s \
--data-urlencode 'query=container_memory_failcnt{container!~"POD|",image!="",namespace=~"'${namespace_filter}'"}' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r '[.data.result[]| {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, node: .metric.instance, "container_memory_failcnt": ((.values|max[1]|tonumber) - (.values|min[1]|tonumber)) }]' > ${debug_json4}

	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json5}"

curl -s \
--data-urlencode 'query=container_memory_usage_bytes{container!~"POD|",image!="",namespace=~"'${namespace_filter}'"}' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r '[.data.result[]| {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, node: .metric.instance, "max_memory_usage": ([.values[][1]|tonumber]|max), "min_memory_usage": ([.values[][1]|tonumber]|min) }]' > ${debug_json5}

	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json6}"

curl -s \
--data-urlencode 'query=container_memory_working_set_bytes{container!~"POD|",image!="",namespace=~"'${namespace_filter}'"}' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r '[.data.result[]| {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, node: .metric.instance, "max_memory_working_set": ([.values[][1]|tonumber]|max), "min_memory_working_set": ([.values[][1]|tonumber]|min)}]' > ${debug_json6}

	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json7}"

curl -s \
--data-urlencode 'query=round(rate(container_cpu_usage_seconds_total{container!~"POD|",image!="",namespace=~"'${namespace_filter}'"}['${rate_step}'s]),0.001)' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r '[.data.result[]| {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, node: .metric.instance, "max_cpu_usage": ([.values[][1]|tonumber]|max), "min_cpu_usage": ([.values[][1]|tonumber]|min)}]' > ${debug_json7}

fi
}

function collect_node_cpu {
#---------------------------------------------------------------------------------------------------------
# Prometheus metrics group #1 (rate)
#  - node_cpu_seconds_total
#
# Report metrics
#  - ts
#  - node
#  - role
#  - cpu_number  --> reference data
#  - user: The time spent in userland
#  - system: The time spent in the kernel
#  - iowait: Time spent waiting for I/O
#  - idle: Time the CPU had nothing to do
#  - nice:
#  - used: CALCULATED cpu_number-idle
#  - high_loaded_cpu:  CALCULATED count cores with high load (>80%) per hosts
#
# https://www.robustperception.io/understanding-machine-cpu-usage
# https://docs.signalfx.com/en/latest/integrations/agent/monitors/prometheus-node.html
#---------------------------------------------------------------------------------------------------------
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Collect node_cpu metrics"

# FILES
report_csv="${output_dir}/node_cpu${tag}.csv"
preaggregated_report_csv="${output_dir}/preagg_node_cpu${tag}.csv"
aggregation_csv="${output_dir}/agg_node_cpu${tag}.csv"
debug_json="${output_dir}/node_cpu${tag}.json"
debug_json2="${output_dir}/node_cpu${tag}2.json"

# METRICS
prometheus_metrics_group_one="node_cpu_seconds_total"
report_metrics=(ts node role cpu_number user system iowait idle nice used high_loaded_cpu)

# HEADER and json_metrics variable
create_header_and_json_metrics

# DATA
# instance:cpu_number enrichment data
cpu_number_argjson=`curl -s \
--data-urlencode 'query=count(count('${prometheus_metrics_group_one}') by (cpu,instance)) by (instance)' \
--data-urlencode 'time='$start_ts'' http://${pm_server_ccd}/api/v1/query \
| jq -r '[.data.result[] | {"\(.metric.instance)": (.value[1])} ]| add'`

(curl -s \
--data-urlencode 'query=round(sum by (mode,instance) (rate('${prometheus_metrics_group_one}'['${rate_step}'s])),0.1)' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${rate_step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r \
--argjson cpu_number "`echo ${cpu_number_argjson}`" \
--argjson node_name "`echo ${node_name_argjson}`" \
'[.data.result[] | {mode: .metric.mode, node: $node_name[(.metric.instance)], cpu_number: $cpu_number[(.metric.instance)]|tonumber, tsvalue: .values[]} | { node, cpu_number, mode, ts: .tsvalue[0], value:  .tsvalue[1]|tonumber} | { node, cpu_number, ts, (.mode): .value} | with_entries(select( .value != null ))]';
curl -s \
--data-urlencode 'query=count (rate('${prometheus_metrics_group_one}'{mode="idle"}['${rate_step}'s]) < 0.20) by (instance)' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${rate_step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r \
--argjson node_name "`echo ${node_name_argjson}`" \
'[.data.result[] | {node: $node_name[(.metric.instance)], tsvalue: .values[]} | { node, ts: .tsvalue[0], high_loaded_cpu: .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]') \
| jq -r -s \
--argjson node_role "`echo ${node_role_argjson}`" \
'map(.[]) | group_by (.ts, .node)[] | add | .role += $node_role[(.node)] | .used += ((.cpu_number - .idle) *10 | round /10) | ['${json_metrics}', "'${cluster_config}'", "'${build_start_time}'"] | @csv' \
| sed -e 's/\"//g' >> ${report_csv}

# AGGREGATION
if [ "$2" == "true" ]
then
	echo " INFO  [`date '+%m/%d %H:%M:%S'`] Aggregate node_cpu metrics"

	# CLEANUP
	rm -f ${preaggregated_report_csv}
	rm -f ${aggregation_csv}

	# COMMON PARAMETERS
	# Calculate AVG and MAX values
	agg_avg_max=(user system iowait idle nice used cpu_number)
	# Could by grouped_by
	agg_dimensions=(node role)

	# EXECUTE PRE-AGGREGATION
	# Calculate SUM for each counter
	agg_summaries=()
	agg_tag="per_node_preagg"
	agg_groupby=(node role)
	perform_aggregation ${report_csv} ${preaggregated_report_csv}
	# In the next the the script uses the avg values, but the avg. prefix has to be removed due to the nameing convension
	sed -i 's/,avg\./,/g' ${preaggregated_report_csv}

	# EXECUTE AGGREGATION
	agg_summaries=(user system iowait idle nice used cpu_number)
	#----------------------------------------------------------------------------
	# !! agg_groupby has to be the subset of agg_dimensions, strict order
	#-----------------------------------------------------------------------------

	# Aggregation #1
	agg_tag="per_node"
	agg_groupby=(node role)
	perform_aggregation ${preaggregated_report_csv}

	# Aggregation #2
	agg_tag="per_role"
	agg_groupby=(role)
	perform_aggregation ${preaggregated_report_csv}

	#Aggregation #3
	agg_tag="overall"
	agg_groupby=()
	perform_aggregation ${preaggregated_report_csv}
fi

# PERSIST
if [ "$1" == "true" ]
then
	persist	${report_csv} eea4_node_cpu
	persist	${aggregation_csv} eea4_aggregated_node_cpu
fi

# DEBUG
if [ "${json_debug}" == "true" ]
then
	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json}"
	curl -s --data-urlencode 'query=count(count(node_cpu_seconds_total) by (cpu,instance)) by (instance)' --data-urlencode 'time='$start_ts'' http://${pm_server_ccd}/api/v1/query | jq -r '[.data.result[] | {"\(.metric.instance)": (.value[1])} ]| add' > ${debug_json}

	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json2}"
	set -x
curl -s \
--data-urlencode 'query=sum by (mode,instance,__name__) (rate(node_cpu_seconds_total['${rate_step}'s]))' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${rate_step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r .  > ${debug_json2}
	set +x
fi
}

function collect_node_memory {
#---------------------------------------------------------------------------------------------------------
# Prometheus metrics group #1
#  - node_memory_Buffers_bytes
#  - node_memory_Cached_bytes
#  - node_memory_MemFree_bytes
#  - node_memory_MemTotal_bytes
#  - node_memory_Slab_bytes
#  - node_memory_PageTables_bytes
#  - node_memory_SwapCached_bytes
#
# Report metrics
#  - ts
#  - node
#  - role
#  - node_memory_Buffers_bytes
#  - node_memory_Cached_bytes
#  - node_memory_MemFree_bytes
#  - node_memory_MemTotal_bytes
#  - node_memory_Slab_bytes
#  - node_memory_PageTables_bytes
#  - node_memory_SwapCached_bytes
#  - node_memory_AppUsedTotal_bytes CALCULATED = node_memory_MemTotal_bytes - node_memory_MemFree_bytes - node_memory_Cached_bytes - node_memory_Buffers_bytes - node_memory_Slab_bytes - node_memory_PageTables_bytes - node_memory_SwapCached_bytes
#
#---------------------------------------------------------------------------------------------------------
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Collect node_memory metrics"

# FILES
report_csv="${output_dir}/node_memory${tag}.csv"
preaggregated_report_csv="${output_dir}/preagg_node_memory${tag}.csv"
aggregation_csv="${output_dir}/agg_node_memory${tag}.csv"
debug_json="${output_dir}/node_memory${tag}.json"

# METRICS
prometheus_metrics_group_one=(node_memory_Buffers_bytes node_memory_Cached_bytes node_memory_MemFree_bytes node_memory_MemTotal_bytes node_memory_Slab_bytes node_memory_PageTables_bytes node_memory_SwapCached_bytes)
report_metrics=(ts node role ${prometheus_metrics_group_one[@]} node_memory_AppUsedTotal_bytes)

# HEADER and json_metrics variable
create_header_and_json_metrics

# DATA
for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query='${counter}'' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r \
--argjson node_name "`echo ${node_name_argjson}`" \
'[.data.result[] | {node: $node_name[(.metric.instance)], tsvalue: .values[]} | { node, ts: .tsvalue[0], "'${counter}'": .tsvalue[1]|tonumber} |  with_entries(select( .value != null ))]'
done | jq -r -s \
--argjson node_role "`echo ${node_role_argjson}`" \
'map(.[]) | group_by (.ts, .node)[] | add | .role += $node_role[(.node)] | .node_memory_AppUsedTotal_bytes += .node_memory_MemTotal_bytes - .node_memory_MemFree_bytes - .node_memory_Cached_bytes - .node_memory_Buffers_bytes - .node_memory_Slab_bytes - .node_memory_PageTables_bytes - .node_memory_SwapCached_bytes | ['${json_metrics}',"'${cluster_config}'", "'${build_start_time}'"] | @csv' \
| sed -e 's/\"//g' >> ${report_csv}

# AGGREGATION
if [ "$2" == "true" ]
then
	echo " INFO  [`date '+%m/%d %H:%M:%S'`] Aggregate node_memory metrics"

	# CLEANUP
	rm -f ${preaggregated_report_csv}
	rm -f ${aggregation_csv}

	# COMMON PARAMETERS
	# Calculate AVG and MAX values
	agg_avg_max=(node_memory_Cached_bytes node_memory_Slab_bytes node_memory_AppUsedTotal_bytes)
	# Could by grouped_by
	agg_dimensions=(node role)

	# EXECUTE PRE-AGGREGATION
	# Calculate SUM for each counter
	agg_summaries=()
	agg_tag="per_node_preagg"
	agg_groupby=(node role)
	perform_aggregation ${report_csv} ${preaggregated_report_csv}
	# In the next the the script uses the avg values, but the avg. prefix has to be removed due to the nameing convension
	sed -i 's/,avg\./,/g' ${preaggregated_report_csv}

	# EXECUTE AGGREGATION
	agg_summaries=(node_memory_Cached_bytes node_memory_Slab_bytes node_memory_AppUsedTotal_bytes)
	#-----------------------------------------------------------------------------
	# !! agg_groupby has to be the subset of agg_dimensions, strict order
	#-----------------------------------------------------------------------------

	# Aggregation #1
	agg_tag="per_node"
	agg_groupby=(node role)
	perform_aggregation ${preaggregated_report_csv}

	# Aggregation #2
	agg_tag="per_role"
	agg_groupby=(role)
	perform_aggregation ${preaggregated_report_csv}

	# Aggregation #3
	agg_tag="overall"
	agg_groupby=()
	perform_aggregation ${preaggregated_report_csv}

fi

# PERSIST
if [ "$1" == "true" ]
then
	persist	${report_csv} eea4_node_memory
	persist	${aggregation_csv} eea4_aggregated_node_memory
fi

# DEBUG
if [ "${json_debug}" == "true" ]
then
	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json}"

for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query='${counter}'' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r '[.data.result[] | {metric: .metric.__name__, instance: .metric.instance, tsvalue: .values[]} | { instance, ts: .tsvalue[0], (.metric): .tsvalue[1]|tonumber} |  with_entries(select( .value != null ))]'
done > ${debug_json}
fi
}

function collect_node_network {
#---------------------------------------------------------------------------------------------------------
# Prometheus metrics group #1 (rate)
#  - node_network_receive_bytes_total
#  - node_network_receive_drop_total
#  - node_network_receive_errs_total
#  - node_network_receive_packets_total
#  - node_network_transmit_bytes_total
#  - node_network_transmit_drop_total
#  - node_network_transmit_errs_total
#  - node_network_transmit_packets_total
#
# Report metrics
#  - ts
#  - node
#  - role
#  - interface
#  - interface_type
#  - node_network_receive_bytes_total
#  - node_network_receive_drop_total
#  - node_network_receive_errs_total
#  - node_network_receive_packets_total
#  - node_network_transmit_bytes_total
#  - node_network_transmit_drop_total
#  - node_network_transmit_errs_total
#  - node_network_transmit_packets_total
#
# FILTER: {device="<node_interface_filter>"}
#---------------------------------------------------------------------------------------------------------
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Collect node_network metrics"

# FILES
report_csv="${output_dir}/node_network${tag}.csv"
preaggregated_report_csv="${output_dir}/preagg_node_network${tag}.csv"
validation_report_csv="${output_dir}/validation_node_network${tag}.csv"
aggregation_csv="${output_dir}/agg_node_network${tag}.csv"
debug_json="${output_dir}/node_network${tag}.json"

# METRICS
prometheus_metrics_group_one=(node_network_receive_bytes_total node_network_receive_drop_total node_network_receive_errs_total node_network_receive_packets_total node_network_transmit_bytes_total node_network_transmit_drop_total node_network_transmit_errs_total node_network_transmit_packets_total)
report_metrics=(ts node role interface interface_type ${prometheus_metrics_group_one[@]})

# HEADER and json_metrics variable
create_header_and_json_metrics

# DATA
for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query=round(rate('${counter}'{device=~"'${node_interface_filter}'"}['${rate_step}'s]),0.1)' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${rate_step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r \
--argjson node_name "`echo ${node_name_argjson}`" \
'[.data.result[] | {node: $node_name[(.metric.instance)], interface: .metric.device, tsvalue: .values[]} | { node, interface, ts: .tsvalue[0], "'${counter}'": (.tsvalue[1]|tonumber)} |  with_entries(select( .value != null ))]'
done | jq -r -s \
--argjson node_role "`echo ${node_role_argjson}`" \
--argjson node_interface_type "`echo ${node_interface_argjson}`" \
'map(.[]) | group_by (.interface, .ts, .node)[] | add | .role += $node_role[(.node)] | .interface_type += $node_interface_type[(.interface)] | ['${json_metrics}', "'${cluster_config}'", "'${build_start_time}'"] | @csv' \
| sed -e 's/\"//g' >> ${report_csv}

# AGGREGATION
if [ "$2" == "true" ]
then
	echo " INFO  [`date '+%m/%d %H:%M:%S'`] Aggregate node_network metrics"

	# CLEANUP
	rm -f ${preaggregated_report_csv}
	rm -f ${aggregation_csv}
	rm -f ${validation_report_csv}

	# COMMON PARAMETERS FOR PRE-AGGREGATION & AGGREGATION
	agg_avg_max=(${prometheus_metrics_group_one[@]})
	agg_dimensions=(node role interface_type)

	#--------------------------
	# EXECUTE PRE-AGGREGATION
	#--------------------------
	agg_summaries=()
	agg_tag="per_node_preagg"
	agg_groupby=(node role interface_type)
	perform_aggregation ${report_csv} ${preaggregated_report_csv}
	# In the next the the script uses the avg values, but the avg. prefix has to be removed due to the nameing convension
	sed -i 's/,avg\./,/g' ${preaggregated_report_csv}

	#---------------------
	# EXECUTE AGGREGATION
	#---------------------
	agg_summaries=(${prometheus_metrics_group_one[@]})

	# Aggregation #1
	agg_tag="per_node"
	agg_groupby=(node role interface_type)
	perform_aggregation ${preaggregated_report_csv}

	# Aggregation #2
	agg_tag="per_role"
	agg_groupby=(role interface_type)
	perform_aggregation ${preaggregated_report_csv}

	#Aggregation #3
	agg_tag="overall"
	agg_groupby=(interface_type)
	perform_aggregation ${preaggregated_report_csv}

	#---------------------------
	# PREPAR CSV FOR VALIDATION
	#---------------------------
	agg_dimensions=(node interface_type)
	agg_summaries=(node_network_receive_drop_total node_network_transmit_drop_total)
	agg_avg_max=(node_network_receive_bytes_total node_network_transmit_bytes_total)
	agg_tag="per_node_validation"
	agg_groupby=(node interface_type)
	perform_aggregation ${report_csv} ${validation_report_csv}

fi

# PERSIST
if [ "$1" == "true" ]
then
	persist	${report_csv} eea4_node_network
	persist	${aggregation_csv} eea4_aggregated_node_network
fi

# DEBUG
if [ "${json_debug}" == "true" ]
then
	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json}"

for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query=rate('${counter}'{device=~"'${node_interface_filter}'"}['${rate_step}'s])' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${rate_step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r '[.data.result[] | {instance: .metric.instance, device: .metric.device, tsvalue: .values[]} | { instance, device, ts: .tsvalue[0], "'${counter}'": (.tsvalue[1]|tonumber)} |  with_entries(select( .value != null ))]'
done > ${debug_json}
fi
}

function collect_node_disk {
#---------------------------------------------------------------------------------------------------------
# Prometheus metrics group #1 (rate) =
#  - node_disk_io_time_seconds_total
#  - node_disk_read_bytes_total
#  - node_disk_read_time_seconds_total
#  - node_disk_write_time_seconds_total
#  - node_disk_written_bytes_total
#  - node_disk_reads_completed_total
#  - node_disk_writes_completed_total
#  - node_disk_io_time_weighted_seconds_total
#
# Report metrics
#  - ts
#  - node
#  - role
#  - disk
#  - disk_type
#  - node_disk_io_time_seconds_total
#  - node_disk_read_bytes_total
#  - node_disk_read_time_seconds_total
#  - node_disk_write_time_seconds_total
#  - node_disk_written_bytes_total
#  - node_disk_reads_completed_total --> iops
#  - node_disk_writes_completed_total --> iops
#  - node_disk_io_time_weighted_seconds_total  --> average queue size = aqu-sz#
#
# FILTER: {device="<node_disk>"}
#---------------------------------------------------------------------------------------------------------
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Collect node_disk metrics"

# FILES
report_csv="${output_dir}/node_disk${tag}.csv"
preaggregated_report_csv="${output_dir}/preagg_node_disk${tag}.csv"
validation_report_csv="${output_dir}/validation_node_disk${tag}.csv"
aggregation_csv="${output_dir}/agg_node_disk${tag}.csv"
debug_json="${output_dir}/node_disk${tag}.json"

# METRICS
prometheus_metrics_group_one=(node_disk_io_time_seconds_total node_disk_read_bytes_total node_disk_read_time_seconds_total node_disk_write_time_seconds_total node_disk_written_bytes_total node_disk_reads_completed_total node_disk_writes_completed_total node_disk_io_time_weighted_seconds_total)
report_metrics=(ts node role disk disk_type ${prometheus_metrics_group_one[@]})

# HEADER and json_metrics variable
create_header_and_json_metrics

# DATA
for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query=round(rate('${counter}'{device=~"'${node_disk}'"}['${rate_step}'s]),0.001)' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${rate_step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r \
--argjson node_name "`echo ${node_name_argjson}`" \
'[.data.result[] | {node: $node_name[(.metric.instance)], disk: .metric.device, tsvalue: .values[]} | { node, disk, ts: .tsvalue[0], "'${counter}'": (.tsvalue[1]|tonumber)} |  with_entries(select( .value != null ))]'
done | jq -r -s \
--argjson node_role "`echo ${node_role_argjson}`" \
--argjson node_disk_type "`echo ${node_disk_argjson}`" \
'map(.[]) | group_by (.disk, .ts, .node)[] | add | .role += $node_role[(.node)] | .disk_type += $node_disk_type[(.disk)] | ['${json_metrics}', "'${cluster_config}'", "'${build_start_time}'"] | @csv' \
| sed -e 's/\"//g' >> ${report_csv}

# AGGREGATION
if [ "$2" == "true" ]
then
	echo " INFO  [`date '+%m/%d %H:%M:%S'`] Aggregate node_disk metrics"

	# CLEANUP
	rm -f ${preaggregated_report_csv}
	rm -f ${aggregation_csv}
	rm -f ${validation_report_csv}

	# COMMON PARAMETERS
	agg_avg_max=(${prometheus_metrics_group_one[@]})
	# Could by grouped_by
	agg_dimensions=(node role disk_type)

	#---------------------------
	# EXECUTE PRE-AGGREGATION
	#---------------------------
	agg_summaries=()
	agg_tag="per_node_preagg"
	agg_groupby=(node role disk_type)
	perform_aggregation ${report_csv} ${preaggregated_report_csv}
	# In the next the the script uses the avg values, but the avg. prefix has to be removed due to the nameing convension
	sed -i 's/,avg\./,/g' ${preaggregated_report_csv}

	#---------------------
	# EXECUTE AGGREGATION
	#---------------------
	agg_summaries=(${prometheus_metrics_group_one[@]})

	# Aggregation #1
	agg_tag="per_node"
	agg_groupby=(node role disk_type)
	perform_aggregation ${preaggregated_report_csv}

	# Aggregation #2
	agg_tag="per_role"
	agg_groupby=(role disk_type)
	perform_aggregation ${preaggregated_report_csv}

	# Aggregation #3
	agg_tag="overall"
	agg_groupby=(disk_type)
	perform_aggregation ${preaggregated_report_csv}

	#---------------------------
	# PREPAR CSV FOR VALIDATION
	#---------------------------
	agg_summaries=()
	agg_dimensions=(node disk)
	agg_avg_max=(node_disk_io_time_seconds_total)
	agg_tag="per_node_validation"
	agg_groupby=(node disk)
	perform_aggregation ${report_csv} ${validation_report_csv}

fi

# PERSIST
if [ "$1" == "true" ]
then
	persist	${report_csv} eea4_node_disk
	persist	${aggregation_csv} eea4_aggregated_node_disk
fi

# DEBUG
if [ "${json_debug}" == "true" ]
then
	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json}"

for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query=rate('${counter}'{device=~"'${node_disk}'"}['${rate_step}'s])' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${rate_step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r '[.data.result[] | {instance: .metric.instance, device: .metric.device, tsvalue: .values[]} | { instance, device, ts: .tsvalue[0], "'${counter}'": (.tsvalue[1]|tonumber)} |  with_entries(select( .value != null ))]'
done > ${debug_json}
fi
}

function collect_node_info {
#---------------------------------------------------------------------------------------------------------
# Prometheus metrics group #1
#  - kube_node_info
#  - kube_node_role
#  - kube_node_labels
#
# Prometheus metrics group #2
#  - kube_node_status_capacity
#  - kube_node_status_allocatable
#
# Prometheus metrics group #3
#  - node_disk_io_time_seconds_total
#
# Prometheus metrics group #4
#  - node_network_speed_bytes
#
# Report metrics group
#  - node
#  - ts = start_time
#  - data_disks (count node_disk_io_time_seconds_total{node_data_disk="sd[b-z]"} by instance)
#  - kube_node_status_capacity_cpu_cores = kube_node_status_capacity{resource="cpu", unit="core"}
#  - !! kube_node_status_capacity_pods_integers (rename to kube_node_status_capacity_pods with sed in the header) = kube_node_status_capacity{resource="pods", unit="integer"}
#  - kube_node_status_capacity_memory_bytes = kube_node_status_capacity{resource="memory", unit="byte"}
#  - kube_node_status_allocatable_cpu_cores = kube_node_status_allocatable{resource="cpu", unit="core"}
#  - !! kube_node_status_allocatable_pods_integers (rename to kube_node_status_capacity_pods with sed in the header) = kube_node_status_allocatable{resource="pods", unit="integer"}
#  - kube_node_status_allocatable_memory_bytes = kube_node_status_allocatable{resource="memory", unit="byte"}
#  - container_runtime_version 	(kube_node_info)
#  - kernel_version 			(kube_node_info)
#  - kubelet_version 			(kube_node_info)
#  - kubeproxy_version 			(kube_node_info)
#  - os_image					(kube_node_info)
#  - role 						(kube_node_role)
#  - label_ccd_version			(kube_node_labels)
#  - traffic_device_speed		(node_network_speed_bytes)
#  - traffic_device_name		(node_network_speed_bytes)
#  - oam_device_speed			(node_network_speed_bytes)
#  - oam_device_name			(node_network_speed_bytes)
#  - releaseId
#  #- traffic_max_rx_throughput	(node_network_receive_bytes_total)
#  #- traffic_max_tx_throughput	(node_network_transmit_bytes_total)
#  #- traffic_max_rx_usage		--> enriched data = traffic_max_rx_throughput / traffic_device_speed
#  #- traffic_max_tx_usage		--> enriched data = traffic_max_tx_throughput / traffic_device_speed
#
#---------------------------------------------------------------------------------------------------------
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Collect node_info metrics"

# FILES
report_csv="${output_dir}/node_info${tag}.csv"
debug_json="${output_dir}/node_info${tag}.json"
debug_json2="${output_dir}/node_info2${tag}.json"
debug_json3="${output_dir}/node_info3${tag}.json"
debug_json4="${output_dir}/node_info4${tag}.json"

# METRICS
prometheus_metrics_group_one=(kube_node_info kube_node_role kube_node_labels)
prometheus_metrics_group_two=(kube_node_status_capacity kube_node_status_allocatable)
prometheus_metrics_group_three="node_disk_io_time_seconds_total"
prometheus_metrics_group_four="node_network_speed_bytes"

#report_metrics=(node ts data_disks ${prometheus_metrics_group_two[@]} container_runtime_version kernel_version kubelet_version kubeproxy_version os_image role label_ccd_version traffic_device_speed traffic_device_name traffic_max_rx_throughput traffic_max_tx_throughput traffic_max_rx_usage traffic_max_tx_usage)
report_metrics=(node ts data_disks kube_node_status_capacity_cpu_cores kube_node_status_capacity_pods_integers kube_node_status_capacity_memory_bytes kube_node_status_allocatable_cpu_cores kube_node_status_allocatable_pods_integers kube_node_status_allocatable_memory_bytes container_runtime_version kernel_version kubelet_version kubeproxy_version os_image role label_ccd_version traffic_device_speed traffic_device_name oam_device_speed oam_device_name releaseId)

# HEADER and json_metrics variable
create_header_and_json_metrics

# DATA
(for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query='${counter}'' \
--data-urlencode 'time='$start_ts'' \
http://${pm_server_ccd}/api/v1/query \
| jq -r \
'[.data.result[].metric | with_entries(select( .value != null ))]'
done;
for counter in ${prometheus_metrics_group_two[@]}
do
curl -s \
--data-urlencode 'query='${counter}'' \
--data-urlencode 'time='$start_ts'' \
http://${pm_server_ccd}/api/v1/query \
| jq -r \
'[.data.result[] | {node: .metric.node, "'${counter}'_\(.metric.resource)_\(.metric.unit)s": .value[1]} |  with_entries(select( .value != null ))]'
done;

curl -s \
--data-urlencode 'query=count ('${prometheus_metrics_group_three}'{device=~"'${node_data_disk}'"}) by (instance)' \
--data-urlencode 'time='$end_ts'' \
http://${pm_server_ccd}/api/v1/query \
| jq -r \
--argjson node_name "`echo ${node_name_argjson}`" \
'[.data.result[] | {node: $node_name[(.metric.instance)], data_disks: (.value[1]|tonumber)} | with_entries(select( .value != null ))]';

curl -s \
--data-urlencode 'query='${prometheus_metrics_group_four}'{device=~"'${node_oam_interface}'"}' \
--data-urlencode 'time='$end_ts'' \
http://${pm_server_ccd}/api/v1/query \
| jq -r \
--argjson node_name "`echo ${node_name_argjson}`" \
'[.data.result[] | {node: $node_name[(.metric.instance)], oam_device_name: .metric.device, oam_device_speed: (.value[1]|tonumber)} | with_entries(select( .value != null ))]';

curl -s \
--data-urlencode 'query='${prometheus_metrics_group_four}'{device=~"'${node_traffic_interface}'"}' \
--data-urlencode 'time='$end_ts'' \
http://${pm_server_ccd}/api/v1/query \
| jq -r \
--argjson node_name "`echo ${node_name_argjson}`" \
'[.data.result[] | {node: $node_name[(.metric.instance)], traffic_device_name:.metric.device, traffic_device_speed: (.value[1]|tonumber)} | with_entries(select( .value != null ))]') \
| jq -r -s 'map(.[]) | group_by (.node)[] | add | .releaseId += "'${release_id}'" | .ts += "'$start_ts'" | ['${json_metrics}', "'${cluster_config}'", "'${build_start_time}'"] | @csv' \
| sed -e 's/\"//g' >> ${report_csv}

# DIRTY SOLUTION TO KEEP ORIGINAL NAMES IN ELASTICS/GRAFANA
# Replace kube_node_status_capacity_pods_integers with kube_node_status_capacity_pods
sed -i 's/kube_node_status_capacity_pods_integers/kube_node_status_capacity_pods/g' ${report_csv}
# Replace kube_node_status_allocatable_pods_integers with kube_node_status_allocatable_pods
sed -i 's/kube_node_status_allocatable_pods_integers/kube_node_status_allocatable_pods/g' ${report_csv}

# SOME QUERY FOR NETWORK VALIDATION, BUT A SPECIAL AGGREGATION WILL PROVIDE THE DATA FOR IT
#curl -s \
#--data-urlencode 'query=round(rate(node_network_receive_bytes_total{device="'${node_traffic_interface}'"}['${rate_step}'s]),0.1)' \
#--data-urlencode 'start='$start_ts'' \
#--data-urlencode 'end='$end_ts'' \
#--data-urlencode 'step='${rate_step}'s' \
#http://${pm_server_ccd}/api/v1/query_range \
#| jq -r \
#--argjson node_name "`echo ${node_name_argjson}`" \
#'[.data.result[] | {node: $node_name[(.metric.instance)], "traffic_max_rx_throughput": ([.values[][1]|tonumber]|max)} |  with_entries(select( .value != null ))]';
#
#curl -s \
#--data-urlencode 'query=round(rate(node_network_transmit_bytes_total{device="'${node_traffic_interface}'"}['${rate_step}'s]),0.1)' \
#--data-urlencode 'start='$start_ts'' \
#--data-urlencode 'end='$end_ts'' \
#--data-urlencode 'step='${rate_step}'s' \
#http://${pm_server_ccd}/api/v1/query_range \
#| jq -r \
#--argjson node_name "`echo ${node_name_argjson}`" \
#'[.data.result[] | {node: $node_name[(.metric.instance)], "traffic_max_tx_throughput": ([.values[][1]|tonumber]|max)} |  with_entries(select( .value != null ))]';

#| jq -r -s 'map(.[]) | group_by (.node)[] | add | if (.traffic_max_rx_throughput == null or .traffic_device_speed == null or .traffic_device_speed == 0 ) then .traffic_max_rx_usage += "0" else .traffic_max_rx_usage += (.traffic_max_rx_throughput / .traffic_device_speed * 1000 | round / 1000) end | if (.traffic_max_tx_throughput == null or .traffic_device_speed == null or .traffic_device_speed == 0 ) then .traffic_max_tx_usage += "0" else .traffic_max_tx_usage += (.traffic_max_tx_throughput / .traffic_device_speed * 1000 | round / 1000) end | .ts += "'$start_ts'" | ['${json_metrics}', "'${cluster_config}'", "'${build_start_time}'"] | @csv'

# PERSIST
if [ "$1" == "true" ]
then
	persist	${report_csv} eea4_node_info
fi

# DEBUG
if [ "${json_debug}" == "true" ]
then
	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json}"
	curl -s --data-urlencode 'query=kube_node_info' --data-urlencode 'time='$start_ts'' http://${pm_server_ccd}/api/v1/query | jq -r . > ${debug_json}

	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json2}"
	curl -s --data-urlencode 'query=kube_node_role' --data-urlencode 'time='$start_ts'' http://${pm_server_ccd}/api/v1/query | jq -r . > ${debug_json2}

	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json3}"
for counter in ${prometheus_metrics_group_two[@]}
do
curl -s \
--data-urlencode 'query='${counter}'' \
--data-urlencode 'time='$start_ts'' \
http://${pm_server_ccd}/api/v1/query \
| jq -r \
'[.data.result[] | {node: .metric.node, "'${counter}'_\(.metric.resource)_\(.metric.unit)s": .value[1]} |  with_entries(select( .value != null ))]'
done > ${debug_json3}

	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json4}"

curl -s \
--data-urlencode 'query=count ('${prometheus_metrics_group_three}'{device=~"'${node_data_disk}'"}) by (instance)' \
--data-urlencode 'time='$end_ts'' \
http://${pm_server_ccd}/api/v1/query \
| jq -r \
--argjson node_name "`echo ${node_name_argjson}`" \
'[.data.result[] | {node: $node_name[(.metric.instance)], data_disks: (.value[1]|tonumber)} | with_entries(select( .value != null ))]' > ${debug_json4}

fi
}

function collect_kafka_broker {
#---------------------------------------------------------------------------------------------------------
#
# Prometheus metrics group #1 TO BE REMOVED
#  - kafka_server_ReplicaManager_Value
# Prometheus metrics group #2 (rate)
#  - kafka_server_BrokerTopicMetrics_Count
# Report metrics
#  - pod
#  - namespace
#  - app
#  - ts
#  - AtMinIsrPartitionCount 	(kafka_server_ReplicaManager_Value) TO BE REMOVED
#  - LeaderCount 				(kafka_server_ReplicaManager_Value) TO BE REMOVED
#  - PartitionCount 			(kafka_server_ReplicaManager_Value) TO BE REMOVED
#  - UnderMinIsrPartitionCount 	(kafka_server_ReplicaManager_Value) TO BE REMOVED
#  - ReplicationBytesInPerSec 	(kafka_server_BrokerTopicMetrics_Count)
#  - ReplicationBytesOutPerSec 	(kafka_server_BrokerTopicMetrics_Count)
#  - BytesOutPerSec 			(kafka_server_BrokerTopicMetrics_Count)
#  - BytesInPerSec 				(kafka_server_BrokerTopicMetrics_Count)
#  - MessagesInPerSec 			(kafka_server_BrokerTopicMetrics_Count)
#  - BytesRejectedPerSec 		(kafka_server_BrokerTopicMetrics_Count)
#
# NOTE: (Isr: In-Sync Replica)
#---------------------------------------------------------------------------------------------------------
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Collect kafka_server metrics"

# FILES
report_csv="${output_dir}/kafka_broker${tag}.csv"
aggregation_csv="${output_dir}/agg_kafka_broker${tag}.csv"
debug_json="${output_dir}/kafka_broker${tag}.json"

# METRICS
#prometheus_metrics_group_one=(kafka_server_ReplicaManager_Value)
prometheus_metrics_group_two=(kafka_server_BrokerTopicMetrics_Count)
#report_metrics=(pod namespace app ts AtMinIsrPartitionCount LeaderCount PartitionCount UnderMinIsrPartitionCount ReplicationBytesInPerSec ReplicationBytesOutPerSec BytesOutPerSec BytesInPerSec MessagesInPerSec BytesRejectedPerSec)
report_metrics=(pod namespace app ts ReplicationBytesInPerSec ReplicationBytesOutPerSec BytesOutPerSec BytesInPerSec MessagesInPerSec BytesRejectedPerSec)

# HEADER and json_metrics variable
create_header_and_json_metrics

# DATA
#(curl -s \
#--data-urlencode 'query='${prometheus_metrics_group_one}'{kubernetes_namespace=~"'${namespace_filter}'"}' \
#--data-urlencode 'start='$start_ts'' \
#--data-urlencode 'end='$end_ts'' \
#--data-urlencode 'step='${step}'s' \
#http://${pm_server_eea}/api/v1/query_range \
#| jq -r \
#'[.data.result[] | {namespace: .metric.kubernetes_namespace, pod: .metric.kubernetes_pod_name, app: .metric.app, name: .metric.name, tsvalue: .values[]} | { namespace, pod, app, ts: .tsvalue[0], (.name): .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]';
(curl -s \
--data-urlencode 'query=round(rate('${prometheus_metrics_group_two}'{topic="",kubernetes_namespace=~"'${namespace_filter}'"}['${rate_step}'s]),0.1)' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${rate_step}'s' \
http://${pm_server_eea}/api/v1/query_range \
| jq -r \
'[.data.result[] | {namespace: .metric.kubernetes_namespace, pod: .metric.kubernetes_pod_name, app: .metric.app, name: .metric.name,tsvalue: .values[]} | { namespace, pod, app, ts: .tsvalue[0], (.name): .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]') \
| jq -r -s \
'map(.[]) | group_by(.ts, .namespace, .pod, .app)[] | add | ['${json_metrics}', "'${cluster_config}'", "'${build_start_time}'"] | @csv' \
| sed -e 's/\"//g' >> ${report_csv}

# PERSIST
if [ "$1" == "true" ]
then
	persist	${report_csv} eea4_kafka_broker
fi

# DEBUG
if [ "${json_debug}" == "true" ]
then
	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json}"
#curl -s \
#--data-urlencode 'query=kafka_server_ReplicaManager_Value{kubernetes_namespace=~"'${namespace_filter}'"}' \
#--data-urlencode 'start='$start_ts'' \
#--data-urlencode 'end='$end_ts'' \
#--data-urlencode 'step='${step}'s' \
#http://${pm_server_eea}/api/v1/query_range \
#| jq -r .  > ${debug_json}

curl -s \
--data-urlencode 'query=round(rate(kafka_server_BrokerTopicMetrics_Count{topic="",kubernetes_namespace=~"'${namespace_filter}'"}['${rate_step}'s]),0.1)' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${rate_step}'s' \
http://${pm_server_eea}/api/v1/query_range \
| jq -r . >> ${debug_json}

fi
}

function collect_kafka_topics {
#---------------------------------------------------------------------------------------------------------
#
# Prometheus metrics group #1
#  - kafka_log_Log_Value
# Report metrics
#  - pod
#  - namespace
#  - app
#  - topic
#  - ts
#  - NumLogSegments
#  - Size
#  - Size_rate (rate)
#  - LogEndOffset
#  - LogEndOffset_rate (rate)
#---------------------------------------------------------------------------------------------------------
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Collect kafka_topics metrics"

# FILES
report_csv="${output_dir}/kafka_topics${tag}.csv"
aggregation_csv="${output_dir}/agg_kafka_topics${tag}.csv"
debug_json="${output_dir}/kafka_topics${tag}.json"
debug_json2="${output_dir}/kafka_topics2${tag}.json"

# METRICS
prometheus_metrics_group_one=(kafka_log_Log_Value)
report_metrics=(pod namespace app topic ts NumLogSegments Size Size_rate LogEndOffset LogEndOffset_rate)

# HEADER and json_metrics variable
create_header_and_json_metrics

# DATA
(curl -s \
--data-urlencode 'query=sum ('${prometheus_metrics_group_one}'{name=~"LogEndOffset|NumLogSegments|Size",kubernetes_namespace=~"'${namespace_filter}'"}) by (kubernetes_namespace,app,kubernetes_pod_name,topic,name)' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_eea}/api/v1/query_range \
| jq -r \
'[.data.result[] | {namespace: .metric.kubernetes_namespace, pod: .metric.kubernetes_pod_name, app: .metric.app, topic: .metric.topic, name: .metric.name, tsvalue: .values[]} | { namespace, pod, app, topic, ts: .tsvalue[0], (.name): .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]';
curl -s \
--data-urlencode 'query=round(sum (rate('${prometheus_metrics_group_one}'{name=~"LogEndOffset|Size",kubernetes_namespace=~"'${namespace_filter}'"}['${rate_step}'s])) by (kubernetes_namespace,app,kubernetes_pod_name,topic,name),0.1)' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${rate_step}'s' \
http://${pm_server_eea}/api/v1/query_range \
| jq -r \
'[.data.result[] | {namespace: .metric.kubernetes_namespace, pod: .metric.kubernetes_pod_name, app: .metric.app, topic: .metric.topic, name: (.metric.name + "_rate"), tsvalue: .values[]} | { namespace, pod, app, topic, ts: .tsvalue[0], (.name): .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]') \
| jq -r -s \
'map(.[]) | group_by(.ts, .namespace, .pod, .app, .topic)[] | add | ['${json_metrics}', "'${cluster_config}'", "'${build_start_time}'"] | @csv' \
| sed -e 's/\"//g' >> ${report_csv}

## CHANGE 5min TOPIC NAMES
#pt5m_topics=(`grep -o "[^,]*pt5m" ${report_csv} | sort | uniq`)
#
#for topic in ${pt5m_topics[@]}
#do
#        old_name=`echo $topic | sed -e 's/aggr-//g' -e 's/-/_/g' -e 's/pt5m/5min/g'`
##        echo "$topic - $old_name"
#        sed -i "s/${topic}/${old_name}/g" ${report_csv}
#done


# PERSIST
if [ "$1" == "true" ]
then
	persist	${report_csv} eea4_kafka_topics
fi

# DEBUG
if [ "${json_debug}" == "true" ]
then
	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json}"
curl -s \
--data-urlencode 'query=kafka_log_Log_Value{name=~"NumLogSegments|Size",kubernetes_namespace=~"'${namespace_filter}'"}' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_eea}/api/v1/query_range \
| jq -r \
'[.data.result[] | {ns: .metric.kubernetes_namespace, pod: .metric.kubernetes_pod_name, app: .metric.app, topic: .metric.topic, name: .metric.name, tsvalue: .values[]} | { ns, pod, app, topic, ts: .tsvalue[0], (.name): .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]'  > ${debug_json}

	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json2}"
curl -s \
--data-urlencode 'query=round(rate(kafka_log_Log_Value{name="LogEndOffset",kubernetes_namespace=~"'${namespace_filter}'"}['${rate_step}'s]),0.1)' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${rate_step}'s' \
http://${pm_server_eea}/api/v1/query_range \
| jq -r \
'[.data.result[] | {ns: .metric.kubernetes_namespace, pod: .metric.kubernetes_pod_name, app: .metric.app, topic: .metric.topic, name: .metric.name, tsvalue: .values[]} | { ns, pod, app, topic, ts: .tsvalue[0], (.name): .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]'   > ${debug_json2}
fi
}

function collect_kafka_topics_v2 {
#---------------------------------------------------------------------------------------------------------
#
# Prometheus metrics group #1
#  - kafka_log_Log_Value
# Report metrics
#  - pod
#  - namespace
#  - app
#  - topic
#  - ts
#  - NumLogSegments
#  - Size
#  - Size_rate (rate)
#  - LogEndOffset
#  - LogEndOffset_rate (rate)
#  - BytesOutPerSec 			(kafka_server_BrokerTopicMetrics_Count)
#  - BytesInPerSec 				(kafka_server_BrokerTopicMetrics_Count)
#  - MessagesInPerSec 			(kafka_server_BrokerTopicMetrics_Count)
#---------------------------------------------------------------------------------------------------------
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Collect kafka_topics_v2 metrics"

# FILES
report_csv="${output_dir}/kafka_topics${tag}.csv"
aggregation_csv="${output_dir}/agg_kafka_topics${tag}.csv"
debug_json="${output_dir}/kafka_topics${tag}.json"
debug_json2="${output_dir}/kafka_topics2${tag}.json"
debug_json3="${output_dir}/kafka_topics3${tag}.json"

# METRICS
prometheus_metrics_group_one=(kafka_log_Log_Value)
prometheus_metrics_group_two=(kafka_server_BrokerTopicMetrics_Count)
report_metrics=(pod namespace app topic ts NumLogSegments Size Size_rate LogEndOffset LogEndOffset_rate BytesOutPerSec BytesInPerSec MessagesInPerSec)

# HEADER and json_metrics variable
create_header_and_json_metrics

# DATA
(curl -s \
--data-urlencode 'query=sum ('${prometheus_metrics_group_one}'{name=~"LogEndOffset|NumLogSegments|Size",kubernetes_namespace=~"'${namespace_filter}'"}) by (kubernetes_namespace,app,kubernetes_pod_name,topic,name)' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_eea}/api/v1/query_range \
| jq -r \
'[.data.result[] | {namespace: .metric.kubernetes_namespace, pod: .metric.kubernetes_pod_name, app: .metric.app, topic: .metric.topic, name: .metric.name, tsvalue: .values[]} | { namespace, pod, app, topic, ts: .tsvalue[0], (.name): .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]';
curl -s \
--data-urlencode 'query=round(sum (rate('${prometheus_metrics_group_one}'{name=~"LogEndOffset|Size",kubernetes_namespace=~"'${namespace_filter}'"}['${rate_step}'s])) by (kubernetes_namespace,app,kubernetes_pod_name,topic,name),0.1)' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${rate_step}'s' \
http://${pm_server_eea}/api/v1/query_range \
| jq -r \
'[.data.result[] | {namespace: .metric.kubernetes_namespace, pod: .metric.kubernetes_pod_name, app: .metric.app, topic: .metric.topic, name: (.metric.name + "_rate"), tsvalue: .values[]} | { namespace, pod, app, topic, ts: .tsvalue[0], (.name): .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]';
curl -s \
--data-urlencode 'query=round(sum (rate('${prometheus_metrics_group_two}'{name=~"BytesOutPerSec|BytesInPerSec|MessagesInPerSec",kubernetes_namespace=~"'${namespace_filter}'"}['${rate_step}'s])) by (kubernetes_namespace,app,kubernetes_pod_name,topic,name),0.1)' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${rate_step}'s' \
http://${pm_server_eea}/api/v1/query_range \
| jq -r \
'[.data.result[] | {namespace: .metric.kubernetes_namespace, pod: .metric.kubernetes_pod_name, app: .metric.app, topic: .metric.topic, name: .metric.name, tsvalue: .values[]} | { namespace, pod, app, topic, ts: .tsvalue[0], (.name): .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]') \
| jq -r -s \
'map(.[]) | group_by(.ts, .namespace, .pod, .app, .topic)[] | add | ['${json_metrics}', "'${cluster_config}'", "'${build_start_time}'"] | @csv' \
| sed -e 's/\"//g' >> ${report_csv}

# PERSIST
if [ "$1" == "true" ]
then
	persist	${report_csv} eea4_kafka_topics_v2
fi

# DEBUG
if [ "${json_debug}" == "true" ]
then
	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json}"
curl -s \
--data-urlencode 'query=kafka_log_Log_Value{name=~"NumLogSegments|Size",kubernetes_namespace=~"'${namespace_filter}'"}' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_eea}/api/v1/query_range \
| jq -r \
'[.data.result[] | {ns: .metric.kubernetes_namespace, pod: .metric.kubernetes_pod_name, app: .metric.app, topic: .metric.topic, name: .metric.name, tsvalue: .values[]} | { ns, pod, app, topic, ts: .tsvalue[0], (.name): .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]'  > ${debug_json}

	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json2}"
curl -s \
--data-urlencode 'query=round(rate(kafka_log_Log_Value{name="LogEndOffset",kubernetes_namespace=~"'${namespace_filter}'"}['${rate_step}'s]),0.1)' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${rate_step}'s' \
http://${pm_server_eea}/api/v1/query_range \
| jq -r \
'[.data.result[] | {ns: .metric.kubernetes_namespace, pod: .metric.kubernetes_pod_name, app: .metric.app, topic: .metric.topic, name: .metric.name, tsvalue: .values[]} | { ns, pod, app, topic, ts: .tsvalue[0], (.name): .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]'   > ${debug_json2}

	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json3}"
curl -s \
--data-urlencode 'query=round(sum (rate('${prometheus_metrics_group_two}'{name=~"BytesOutPerSec|BytesInPerSec|MessagesInPerSec",kubernetes_namespace=~"'${namespace_filter}'"}['${rate_step}'s])) by (kubernetes_namespace,app,kubernetes_pod_name,topic,name),0.1)' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${rate_step}'s' \
http://${pm_server_eea}/api/v1/query_range \
| jq -r \
'[.data.result[] | {namespace: .metric.kubernetes_namespace, pod: .metric.kubernetes_pod_name, app: .metric.app, topic: .metric.topic, name: .metric.name, tsvalue: .values[]} | { namespace, pod, app, topic, ts: .tsvalue[0], (.name): .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]'

fi
}

function collect_kafka_info {
#---------------------------------------------------------------------------------------------------------
#
# Report metrics group #1
#  - SizeChange  = sum (kafka_log_Log_Value{name=~"Size",kubernetes_namespace=~"'${namespace_filter}'"}) by (kubernetes_namespace,app,kubernetes_pod_name,topic,name) @end -@start INVALID DUE TO RETENTION
#  - OffsetChange = sum (kafka_log_Log_Value{name="LogEndOffset",kubernetes_namespace=~"'${namespace_filter}'"}) by (kubernetes_namespace,app,kubernetes_pod_name,topic,name) @end -@start  REPLICATION INCLUEDED
#  - SizeChangeLeader  = sum (max (kafka_log_Log_Value{name=~"LogEndOffset|Size",kubernetes_namespace=~"'${namespace_filter}'"}) by (kubernetes_namespace,topic,partition,app,name)) by (kubernetes_namespace,topic,app,name)' @end_time COULD BE INVALID DUE TO RETENTION, IT IS VALID IN CASE ONLY WHERE RETENTION IS MORE THAN 2HOUR
#  - OffsetChangeLeader = sum (max (kafka_log_Log_Value{name=~"LogEndOffset|Size",kubernetes_namespace=~"'${namespace_filter}'"}) by (kubernetes_namespace,topic,partition,app,name)) by (kubernetes_namespace,topic,app,name)' @end_time
#  - ReplicationFactor = max (kafka_cluster_Partition_Value{name="ReplicasCount"}) by (topic)
#  - TopicPartitionNumber = count (count (kafka_log_Log_Value) by (partition,topic)) by (topic)
#  - ts
#  - namespace
#  - app
#  - topic
#  - releaseId
#---------------------------------------------------------------------------------------------------------
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Collect kafka_info metrics"

# FILES
report_csv="${output_dir}/kafka_info${tag}.csv"
debug_json="${output_dir}/kafka_info${tag}.json"
debug_json2="${output_dir}/kafka_info2${tag}.json"
debug_json3="${output_dir}/kafka_info3${tag}.json"
debug_json4="${output_dir}/kafka_info4${tag}.json"

# METRICS
report_metrics=(ts namespace app topic SizeChange OffsetChange OffsetChangeLeader SizeChangeLeader ReplicationFactor TopicPartitionNumber releaseId)

# HEADER and json_metrics variable
create_header_and_json_metrics

# DATA
# topic:replication_factor enrichment data
replication_factor_argjson=`curl -s \
--data-urlencode 'query=max (kafka_cluster_Partition_Value{name="ReplicasCount",kubernetes_namespace=~"'${namespace_filter}'"}) by (topic)' \
--data-urlencode 'time='$end_ts'' \
http://${pm_server_eea}/api/v1/query \
| jq -r '[.data.result[] | {"\(.metric.topic)": (.value[1])} ]| add'`
# topic:topic_partition_number enrichment data
topic_partition_number_argjson=`curl -s \
--data-urlencode 'query=count (count (kafka_log_Log_Value{kubernetes_namespace=~"'${namespace_filter}'"}) by (partition,topic)) by (topic)' \
--data-urlencode 'time='$end_ts'' \
http://${pm_server_eea}/api/v1/query \
| jq -r '[.data.result[] | {"\(.metric.topic)": (.value[1])} ]| add'`

(curl -s \
--data-urlencode 'query=sum (kafka_log_Log_Value{name=~"LogEndOffset|Size",kubernetes_namespace=~"'${namespace_filter}'"}) by (kubernetes_namespace,app,topic,name)' \
--data-urlencode 'time='$end_ts'' \
http://${pm_server_eea}/api/v1/query \
| jq -r \
'[.data.result[] | {namespace: .metric.kubernetes_namespace, app: .metric.app, topic: .metric.topic, "\(.metric.name)_end": (.value[1]|tonumber)} | with_entries(select( .value != null ))]';
curl -s \
--data-urlencode 'query=sum (max (kafka_log_Log_Value{name=~"LogEndOffset|Size",kubernetes_namespace=~"'${namespace_filter}'"}) by (kubernetes_namespace,topic,partition,app,name)) by (kubernetes_namespace,topic,app,name)' \
--data-urlencode 'time='$end_ts'' \
http://${pm_server_eea}/api/v1/query \
| jq -r \
'[.data.result[] | {namespace: .metric.kubernetes_namespace, app: .metric.app, topic: .metric.topic, "\(.metric.name)_leader_end": (.value[1]|tonumber)} | with_entries(select( .value != null ))]') \
| jq -r -s \
--argjson replication_factor "`echo ${replication_factor_argjson}`" \
--argjson topic_partition_number "`echo ${topic_partition_number_argjson}`" \
'map(.[]) | group_by(.namespace, .app, .topic)[] | add | .ReplicationFactor += $replication_factor[(.topic)] | .TopicPartitionNumber += $topic_partition_number[(.topic)] | .OffsetChange += .LogEndOffset_end | .SizeChange += .Size_end | .OffsetChangeLeader += .LogEndOffset_leader_end | .SizeChangeLeader += .Size_leader_end | .ts += "'$start_ts'" | .releaseId += "'${release_id}'" | ['${json_metrics}', "'${cluster_config}'", "'${build_start_time}'"] | @csv' \
| sed -e 's/\"//g' >> ${report_csv}

## CHANGE 5min TOPIC NAMES
#pt5m_topics=(`grep -o "[^,]*pt5m" ${report_csv} | sort | uniq`)
#
#for topic in ${pt5m_topics[@]}
#do
#        old_name=`echo $topic | sed -e 's/aggr-//g' -e 's/-/_/g' -e 's/pt5m/5min/g'`
##        echo "$topic - $old_name"
#        sed -i "s/${topic}/${old_name}/g" ${report_csv}
#done

# PERSIST
if [ "$1" == "true" ]
then
	persist	${report_csv} eea4_kafka_info
fi

# DEBUG
if [ "${json_debug}" == "true" ]
then
	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json}"
	curl -s --data-urlencode 'query=max (kafka_cluster_Partition_Value{name="ReplicasCount"}) by (topic)' --data-urlencode 'time='$end_ts'' http://${pm_server_eea}/api/v1/query | jq -r '[.data.result[] | {"\(.metric.topic)": (.value[1])} ]| add' > ${debug_json}

	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json2}"
	curl -s --data-urlencode 'query=count (count (kafka_log_Log_Value) by (partition,topic)) by (topic)' --data-urlencode 'time='$end_ts'' http://${pm_server_eea}/api/v1/query | jq -r '[.data.result[] | {"\(.metric.topic)": (.value[1])} ]| add' > ${debug_json2}

	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json3}"
	curl -s --data-urlencode 'query=sum (kafka_log_Log_Value{name=~"LogEndOffset|Size",kubernetes_namespace=~"'${namespace_filter}'"}) by (kubernetes_namespace,app,topic,name)' --data-urlencode 'time='$end_ts'' http://${pm_server_eea}/api/v1/query | jq -r . > ${debug_json3}

	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json4}"
	curl -s --data-urlencode 'query=sum (kafka_log_Log_Value{name=~"LogEndOffset|Size",kubernetes_namespace=~"'${namespace_filter}'"}) by (kubernetes_namespace,app,topic,name)' --data-urlencode 'time='$start_ts'' http://${pm_server_eea}/api/v1/query | jq -r . > ${debug_json4}
fi
}

function collect_csm_stat {
#---------------------------------------------------------------------------------------------------------
# PM_SERVER_EEA (cant be added to CCD due to secure job)
#
# Prometheus metrics group #1
#  - csm_latency_ms_count
#  - csm_received_event_count
#  - csm_received_bytes
#  - csm_sent_event_count
#  - csm_sent_bytes
#  - csm_processed_event_count
#  - csm_event_unused_count
#  - csm_event_drop_count
#
# Prometheus metrics group #2 - rate
#  - csm_received_event_count
#  - csm_received_bytes
#  - csm_sent_event_count
#  - csm_sent_bytes
#  - csm_processed_event_count
#  - csm_event_unused_count
#  - csm_event_drop_count

# Report metrics
#  - ts
#  - releaseId
#  - app
#  - processtype
#  - kubernetes_namespace
#  - kubernetes_pod_name
#  - csm_latency_ms_count
#  - csm_received_event_count
#  - csm_received_event_count_rate  (rate)
#  - csm_received_bytes
#  - csm_received_bytes_rate  (rate)
#  - csm_sent_event_count
#  - csm_sent_event_count_rate (rate)
#  - csm_sent_bytes
#  - csm_sent_bytes_rate (rate)
#  - csm_processed_event_count
#  - csm_processed_event_count_rate  (rate)
#  - csm_event_unused_count
#  - csm_event_unused_count_rate  (rate)
#  - csm_event_drop_count
#  - csm_event_drop_count_rate  (rate)
#
#---------------------------------------------------------------------------------------------------------
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Collect CSM metrics"

# FILES
report_csv="${output_dir}/csm_stat${tag}.csv"
debug_json="${output_dir}/csm_stat${tag}.json"

# METRICS
prometheus_metrics_group_one=(csm_latency_ms_count csm_received_event_count csm_received_bytes csm_sent_event_count csm_sent_bytes csm_processed_event_count csm_event_unused_count csm_event_drop_count)
prometheus_metrics_group_two=(csm_received_event_count csm_received_bytes csm_sent_event_count csm_sent_bytes csm_processed_event_count csm_event_unused_count csm_event_drop_count)
report_metrics=(app namespace pod processtype ts ${prometheus_metrics_group_one[@]} csm_received_event_count_rate csm_received_bytes_rate csm_sent_event_count_rate csm_sent_bytes_rate csm_processed_event_count_rate csm_event_unused_count_rate csm_event_drop_count_rate releaseId)

# HEADER and json_metrics variable
create_header_and_json_metrics

# DATA
(for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query='${counter}'{kubernetes_namespace=~"'${namespace_filter}'"}' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_eea}/api/v1/query_range \
| jq -r \
'[.data.result[] | {app: .metric.app, namespace: .metric.kubernetes_namespace, pod: .metric.kubernetes_pod_name, processtype: .metric.processtype, tsvalue: .values[]} | { app, namespace, pod, processtype, ts: .tsvalue[0], "'${counter}'": .tsvalue[1]|tonumber} |  with_entries(select( .value != null ))]'
done;
for counter in ${prometheus_metrics_group_two[@]}
do
curl -s \
--data-urlencode 'query=rate('${counter}'{kubernetes_namespace=~"'${namespace_filter}'"}['${rate_step}'s])' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_eea}/api/v1/query_range \
| jq -r \
'[.data.result[] | {app: .metric.app, namespace: .metric.kubernetes_namespace, pod: .metric.kubernetes_pod_name, processtype: .metric.processtype, tsvalue: .values[]} | { app, namespace, pod, processtype, ts: .tsvalue[0], "'${counter}'_rate": .tsvalue[1]|tonumber} |  with_entries(select( .value != null ))]'
done) \
| jq -r -s \
'map(.[]) | group_by (.app, .namespace, .pod, .processtype, .ts)[] | add | .releaseId += "'${release_id}'" | ['${json_metrics}',"'${cluster_config}'", "'${build_start_time}'"] | @csv' \
| sed -e 's/\"//g' >> ${report_csv}

# PERSIST
if [ "$1" == "true" ]
then
	persist	${report_csv} eea4_csm_stat
fi

# DEBUG
if [ "${json_debug}" == "true" ]
then
	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json}"

for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query='${counter}'' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_eea}/api/v1/query_range \
| jq -r \
'[.data.result[] | {pod: .kubernetes_pod_name, tsvalue: .values[]} | { pod, ts: .tsvalue[0], "'${counter}'": .tsvalue[1]|tonumber} |  with_entries(select( .value != null ))]'
done | jq . > ${debug_json}
fi
}

function collect_correlator_stat {
#---------------------------------------------------------------------------------------------------------
# PM_SERVER_EEA (cant be added to CCD due to secure job)
#
# Prometheus metrics group #1
#  - oss_correlator_cloud_latency
#  - oss_correlator_processed_event_rate
#  - oss_correlator_received_event_rate
#  - oss_correlator_dropped_events_total
#  - oss_correlator_unused_events_total
#  - oss_correlator_processed_events_total
#  - oss_correlator_received_bytes_total
#  - oss_correlator_received_events_total
#  - oss_correlator_sent_bytes_total
#  - oss_correlator_sent_events_total
#
# Report metrics
#  - ts
#  - releaseId
#  - app
#  - processtype
#  - kubernetes_namespace
#  - kubernetes_pod_name
#  - oss_correlator_cloud_latency
#  - oss_correlator_processed_event_rate
#  - oss_correlator_processed_events_total
#  - oss_correlator_dropped_events_total
#  - oss_correlator_dropped_events_total_rate  (rate)
#  - oss_correlator_unused_events_total
#  - oss_correlator_unused_events_total_rate  (rate)
#  - oss_correlator_received_events_total
#  - oss_correlator_received_event_rate
#  - oss_correlator_received_bytes_total
#  - oss_correlator_received_bytes_total_rate  (rate)
#  - oss_correlator_sent_bytes_total
#  - oss_correlator_sent_bytes_total_rate  (rate)
#  - oss_correlator_sent_events_total
#  - oss_correlator_sent_events_total_rate  (rate)
#
# Round to 1 -> integer
#
# UNUSED BUT SHOULD BE
#oss_correlator_incident_bytes_default"
#oss_correlator_incident_event_avg_size_default"
#oss_correlator_incident_event_max_size_default"
#oss_correlator_incident_event_min_size_default"
#oss_correlator_kpi_bytes_default"
#oss_correlator_kpi_event_avg_size_default"
#oss_correlator_kpi_event_max_size_default"
#oss_correlator_kpi_event_min_size_default"
#---------------------------------------------------------------------------------------------------------
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Collect Correlator metrics"

# FILES
report_csv="${output_dir}/correlator_stat${tag}.csv"
debug_json="${output_dir}/correlator_stat${tag}.json"

# METRICS
prometheus_metrics_group_one=(oss_correlator_cloud_latency oss_correlator_processed_event_rate oss_correlator_received_event_rate oss_correlator_dropped_events_total oss_correlator_unused_events_total oss_correlator_processed_events_total oss_correlator_received_bytes_total oss_correlator_received_events_total oss_correlator_sent_bytes_total oss_correlator_sent_events_total)
prometheus_metrics_group_two=(oss_correlator_dropped_events_total oss_correlator_unused_events_total oss_correlator_received_bytes_total oss_correlator_sent_bytes_total oss_correlator_sent_events_total)
report_metrics=(app namespace pod processtype ts releaseId ${prometheus_metrics_group_one[@]} oss_correlator_dropped_events_total_rate oss_correlator_unused_events_total_rate oss_correlator_received_bytes_total_rate oss_correlator_sent_bytes_total_rate oss_correlator_sent_events_total_rate)

# HEADER and json_metrics variable
create_header_and_json_metrics

# DATA
#kubernetes_namespace
(for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query=round('${counter}'{kubernetes_namespace=~"'${namespace_filter}'"},1)' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_eea}/api/v1/query_range \
| jq -r \
'[.data.result[] | {app: .metric.app, namespace: .metric.kubernetes_namespace, pod: .metric.kubernetes_pod_name, processtype: .metric.processtype, tsvalue: .values[]} | { app, namespace, pod, processtype, ts: .tsvalue[0], "'${counter}'": .tsvalue[1]|tonumber} |  with_entries(select( .value != null ))]'
done;
for counter in ${prometheus_metrics_group_two[@]}
do
curl -s \
--data-urlencode 'query=rate('${counter}'{kubernetes_namespace=~"'${namespace_filter}'"}['${rate_step}'s])' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_eea}/api/v1/query_range \
| jq -r \
'[.data.result[] | {app: .metric.app, namespace: .metric.kubernetes_namespace, pod: .metric.kubernetes_pod_name, processtype: .metric.processtype, tsvalue: .values[]} | { app, namespace, pod, processtype, ts: .tsvalue[0], "'${counter}'_rate": .tsvalue[1]|tonumber} |  with_entries(select( .value != null ))]'
done) | jq -r -s \
'map(.[]) | group_by (.app, .namespace, .pod, .processtype, .ts)[] | add | .releaseId += "'${release_id}'" | ['${json_metrics}',"'${cluster_config}'", "'${build_start_time}'"] | @csv' \
| sed -e 's/\"//g' >> ${report_csv}

# PERSIST
if [ "$1" == "true" ]
then
	persist	${report_csv} eea4_correlator_stat
fi

# DEBUG
if [ "${json_debug}" == "true" ]
then
	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json}"

for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query='${counter}'' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_eea}/api/v1/query_range \
| jq -r \
'[.data.result[] | {processtype: .processtype, tsvalue: .values[]} | { processtype, ts: .tsvalue[0], "'${counter}'": .tsvalue[1]|tonumber} |  with_entries(select( .value != null ))]'
done | jq . > ${debug_json}
fi
}

function collect_vertica_requests {
#---------------------------------------------------------------------------------------------------------
# PM_SERVER_EEA
#
# Prometheus metrics group #1
#  - eea_eric_eea_analytical_processing_database_TCP_requests_duration_milliseconds    {{node}} - {{ request_type }}

# Prometheus metrics group #2
#  - eea_eric_eea_analytical_processing_database_TCP_requests_count
#  - eea_eric_eea_analytical_processing_database_TCP_requests_errors_count

# Report metrics
#  - ts
#  - releaseId
#  - node
#  - duration_ms_LOAD (eea_eric_eea_analytical_processing_database_TCP_requests_duration_milliseconds)
#  - duration_ms_QUERY (eea_eric_eea_analytical_processing_database_TCP_requests_duration_milliseconds)
#  - duration_ms_SET (eea_eric_eea_analytical_processing_database_TCP_requests_duration_milliseconds)
#  - duration_ms_TRANSACTION (eea_eric_eea_analytical_processing_database_TCP_requests_duration_milliseconds)
#  - duration_ms_UTILITY (eea_eric_eea_analytical_processing_database_TCP_requests_duration_milliseconds)
#  - eea_eric_eea_analytical_processing_database_TCP_requests_count
#  - eea_eric_eea_analytical_processing_database_TCP_requests_errors_count
#---------------------------------------------------------------------------------------------------------
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Collect Vertica Requests metrics"

# FILES
report_csv="${output_dir}/vertica_requests${tag}.csv"
debug_json="${output_dir}/vertica_requests${tag}_group1.json"
debug_json2="${output_dir}/vertica_requests${tag}_group2.json"

# METRICS
prometheus_metrics_group_one=(eea_eric_eea_analytical_processing_database_TCP_requests_duration_milliseconds)
prometheus_metrics_group_two=(eea_eric_eea_analytical_processing_database_TCP_requests_count eea_eric_eea_analytical_processing_database_TCP_requests_errors_count)
report_metrics=(node ts ${prometheus_metrics_group_two[@]} duration_ms_LOAD duration_ms_QUERY duration_ms_SET duration_ms_TRANSACTION duration_ms_UTILITY releaseId)

# HEADER and json_metrics variable
create_header_and_json_metrics

# DATA
(for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query='${counter}'' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_eea}/api/v1/query_range \
| jq -r \
'[.data.result[] | {node: .metric.node, req_type: .metric.request_type, tsvalue: .values[]} | { node, ts: .tsvalue[0], "duration_ms_\(.req_type)": .tsvalue[1]|tonumber} |  with_entries(select( .value != null ))]'
done;
for counter in ${prometheus_metrics_group_two[@]}
do
curl -s \
--data-urlencode 'query='${counter}'' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_eea}/api/v1/query_range \
| jq -r \
'[.data.result[] | {node: .metric.node, tsvalue: .values[]} | { node, ts: .tsvalue[0], "'${counter}'": .tsvalue[1]|tonumber} |  with_entries(select( .value != null ))]'
done) \
| jq -r -s \
'map(.[]) | group_by (.node, .ts)[] | add | .releaseId += "'${release_id}'" | ['${json_metrics}',"'${cluster_config}'", "'${build_start_time}'"] | @csv' \
| sed -e 's/\"//g' >> ${report_csv}

# PERSIST
if [ "$1" == "true" ]
then
	persist	${report_csv} eea4_vertica_requests
fi

# DEBUG
if [ "${json_debug}" == "true" ]
then
	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json}"

for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query='${counter}'' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_eea}/api/v1/query_range \
| jq -r \
'[.data.result[] | {node: .metric.node, req_type: .metric.request_type, tsvalue: .values[]} | { node, ts: .tsvalue[0], "duration_\(.req_type)": .tsvalue[1]|tonumber} |  with_entries(select( .value != null ))]'
done | jq . > ${debug_json}

for counter in ${prometheus_metrics_group_two[@]}
do
curl -s \
--data-urlencode 'query='${counter}'' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_eea}/api/v1/query_range \
| jq -r \
'[.data.result[] | {node: .metric.node, tsvalue: .values[]} | { node, ts: .tsvalue[0], "'${counter}'": .tsvalue[1]|tonumber} |  with_entries(select( .value != null ))]'
done | jq . > ${debug_json2}
fi
}

function collect_vertica_data_size {
#---------------------------------------------------------------------------------------------------------
# PM_SERVER_EEA

# Prometheus metrics group #1
# - eea_eric_eea_analytical_processing_database_TCP_raw_data_size_bytes
# - eea_eric_eea_analytical_processing_database_TCP_compressed_data_size_bytes

# Report metrics
#  - ts
#  - releaseId
#  - table
#  - eea_eric_eea_analytical_processing_database_TCP_raw_data_size_bytes
#  - eea_eric_eea_analytical_processing_database_TCP_compressed_data_size_bytes
#---------------------------------------------------------------------------------------------------------
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Collect Vertica DataSize metrics"

# FILES
report_csv="${output_dir}/vertica_datasize${tag}.csv"
debug_json="${output_dir}/vertica_datasize${tag}_group1.json"

# METRICS
prometheus_metrics_group_one=(eea_eric_eea_analytical_processing_database_TCP_raw_data_size_bytes eea_eric_eea_analytical_processing_database_TCP_compressed_data_size_bytes)
report_metrics=(table ts ${prometheus_metrics_group_one[@]} releaseId)

# HEADER and json_metrics variable
create_header_and_json_metrics

# DATA
(for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query='${counter}'' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_eea}/api/v1/query_range \
| jq -r \
'[.data.result[] | {table: .metric.table, tsvalue: .values[]} | { table, ts: .tsvalue[0], "'${counter}'": .tsvalue[1]|tonumber} |  with_entries(select( .value != null ))]'
done) \
| jq -r -s \
'map(.[]) | group_by (.table, .ts)[] | add | .releaseId += "'${release_id}'" | ['${json_metrics}',"'${cluster_config}'", "'${build_start_time}'"] | @csv' \
| sed -e 's/\"//g' >> ${report_csv}

# PERSIST
if [ "$1" == "true" ]
then
	persist	${report_csv} eea4_vertica_datasize
fi

# DEBUG
if [ "${json_debug}" == "true" ]
then
	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json}"

for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query='${counter}'' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_eea}/api/v1/query_range \
| jq -r \
'[.data.result[] | {table: .metric.table, tsvalue: .values[]} | { table, ts: .tsvalue[0], "'${counter}'": .tsvalue[1]|tonumber} |  with_entries(select( .value != null ))]'
done | jq . > ${debug_json}
fi
}

function collect_kafka_connect {
#---------------------------------------------------------------------------------------------------------
# PM_SERVER_EEA

# Prometheus metrics group #1
# - kafka_connect_sink_task_sink_record_read_rate
# - kafka_connect_sink_task_sink_record_send_rate

# Prometheus metrics group #2
# - kafka_connect_sink_task_sink_record_read_total (last ts)
# - kafka_connect_sink_task_sink_record_send_total (last ts)

# Report metrics
#  - ts
#  - releaseId
#  - kafka_connect_sink_task_sink_record_read_rate
#  - kafka_connect_sink_task_sink_record_read_total
#  - kafka_connect_sink_task_sink_record_send_rate
#  - kafka_connect_sink_task_sink_record_send_total
#---------------------------------------------------------------------------------------------------------
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Collect DB Loader Kafka_connect metrics"

# FILES
report_csv="${output_dir}/kafka_connect${tag}.csv"
debug_json2="${output_dir}/kafka_connect${tag}_group1.json"
debug_json2="${output_dir}/kafka_connect${tag}_group2.json"

# METRICS
prometheus_metrics_group_one=(kafka_connect_sink_task_sink_record_read_rate kafka_connect_sink_task_sink_record_send_rate)
prometheus_metrics_group_two=(kafka_connect_sink_task_sink_record_read_total kafka_connect_sink_task_sink_record_send_total)
report_metrics=(connector kubernetes_pod_name ts ${prometheus_metrics_group_one[@]} ${prometheus_metrics_group_two[@]} releaseId)

# HEADER and json_metrics variable
create_header_and_json_metrics

# DATA
(for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query='${counter}'' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_eea}/api/v1/query_range \
| jq -r \
'[.data.result[] | {connector: .metric.connector, kubernetes_pod_name: .metric.kubernetes_pod_name, tsvalue: .values[]} | { connector, kubernetes_pod_name, ts: .tsvalue[0], "'${counter}'": .tsvalue[1]|tonumber} |  with_entries(select( .value != null ))]'
done;
for counter in ${prometheus_metrics_group_two[@]}
do
curl -s \
--data-urlencode 'query='${counter}'' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_eea}/api/v1/query_range \
| jq -r \
'[.data.result[] | {connector: .metric.connector, kubernetes_pod_name: .metric.kubernetes_pod_name, tsvalue: .values[-1]} | { connector, kubernetes_pod_name, ts: .tsvalue[0], "'${counter}'": .tsvalue[1]|tonumber} |  with_entries(select( .value != null ))]'
done) \
| jq -r -s \
'map(.[]) | group_by (.connector, .kubernetes_pod_name, .ts)[] | add | .releaseId += "'${release_id}'" | ['${json_metrics}',"'${cluster_config}'", "'${build_start_time}'"] | @csv' \
| sed -e 's/\"//g' >> ${report_csv}

# PERSIST
if [ "$1" == "true" ]
then
	persist	${report_csv} eea4_kafka_connect
fi

# DEBUG
if [ "${json_debug}" == "true" ]
then
	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ${debug_json}"

for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query='${counter}'' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_eea}/api/v1/query_range \
| jq -r \
'[.data.result[] | {connector: .metric.connector, kubernetes_pod_name: .metric.kubernetes_pod_name, tsvalue: .values[]} | { connector, kubernetes_pod_name, ts: .tsvalue[0], "'${counter}'": .tsvalue[1]|tonumber} |  with_entries(select( .value != null ))]'
done | jq . > ${debug_json}

for counter in ${prometheus_metrics_group_one[@]}
do
curl -s \
--data-urlencode 'query='${counter}'' \
--data-urlencode 'start='$start_ts'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_eea}/api/v1/query_range \
| jq -r \
'[.data.result[] | {connector: .metric.connector, kubernetes_pod_name: .metric.kubernetes_pod_name, tsvalue: .values[-1]} | { connector, kubernetes_pod_name, ts: .tsvalue[0], "'${counter}'": .tsvalue[1]|tonumber} |  with_entries(select( .value != null ))]'
done | jq . > ${debug_json2}
fi
}

function enrich_and_persist_csv {
#---------------------------------------------------------------------------------------------------------
# Persist CSV to Elastics
# $1 CSV
# $2 index name
#
# ADD:
# clusterName - ${cluster_config}
# buildTime - ${build_start_time}
# releaseId - ${release_id}
#
#---------------------------------------------------------------------------------------------------------
report_csv="${output_dir}/temp.csv"
index=$2

echo " INFO  [`date '+%m/%d %H:%M:%S'`] Enrich $1"

if [ -f $1 ]
then
	# expand the header
	head -1 $1 | sed -e 's/$/,ts,clusterName,buildTime,releaseId/g' > ${report_csv}
	# expand the data
	tail -n +2 $1 | sed -e 's/$/,'${start_ts}','${cluster_config}','${build_start_time}','${release_id}'/g' >> ${report_csv}

	persist	${report_csv} ${index}

	rm -f ${report_csv}
else
	echo " WARN  [`date '+%m/%d %H:%M:%S'`] $1 does not exist"
fi
}

function collect_build_info {
#---------------------------------------------------------------------------------------------------------
# Persist build info to Elastics
#---------------------------------------------------------------------------------------------------------
# FILES
report_csv="${output_dir}/build_info${tag}.csv"

# source config file
if [ -f ${running_parameters} ]
then
	jenkins_job_url=`grep JENKINS_JOB_URL ${running_parameters} | awk '{print $2}'`
	ci_branch=`grep CI_AND_EEA_BRANCH ${running_parameters} | awk '{print $2}'`
	dataset=`grep "^DATASET" ${running_parameters} | awk '{print $2}'`
	custom_file_version=`grep "^CUSTOM_FILE_VERSION:" ${running_parameters} | awk '{print $2}'`
	resource_config=`grep "^RESOURCE_CONFIG:" ${running_parameters} | awk '{print $2}'`
	start_traffic=`grep START_TRAFFIC: ${running_parameters} | awk '{print $2}'`
	sep_version=`grep SEP_VERSION ${running_parameters} | awk '{print $2}'`
	rook_version=`grep ROOK_VERSION ${running_parameters} | awk '{print $2}'`
	ceph_version=`grep CEPH_VERSION ${running_parameters} | awk '{print $2}'`
	replay_speed=`grep REPLAY_SPEED ${running_parameters} | awk '{print $2}'`
	tool_chart_version=`grep TOOLS_CHART_VERSION ${running_parameters} | awk '{print $2}'`
	dataflow_yamls=`grep DATAFLOW_YAMLS ${running_parameters} | awk '{print $2}'`
else
	jenkins_job_url="dummy"
	ci_branch="NA"
	dataset="NA"
	custom_file_version="NA"
	resource_config="NA"
	start_traffic="false"
	sep_version="NA"
	rook_version="NA"
	ceph_version="NA"
	replay_speed="NA"
	tool_chart_version="NA"
	dataflow_yamls="NA"
fi

echo "ts,clusterName,buildTime,releaseId,start_ts,end_ts,traffic_length,output_dir,comment,duration,jenkins_job_link,sep_version,rook_version,ceph_version,custom_file_version,resource_config,ci_branch,dataset,replay_speed,start_traffic,tool_chart_version,dataflow_yamls" > ${report_csv}
echo "${start_ts},${cluster_config},${build_start_time},${release_id},${start_ts},${end_ts},${traffic_length_sec},${output_dir},${build_comment},$(( $end_ts - $start_ts )),${jenkins_job_url},${sep_version},${rook_version},${ceph_version},${custom_file_version},${resource_config},${ci_branch},${dataset},${replay_speed},${start_traffic},${tool_chart_version},${dataflow_yamls}" >> ${report_csv}

# PERSIST
if [ "$1" == "true" ]
then
	persist	${report_csv} eea4_build_info
fi

}

function persist {
#---------------------------------------------------------------------------------------------------------
# Persist CSV to Elastics
# $1 CSV
# $2 index name
#---------------------------------------------------------------------------------------------------------
if [ -f $1 ]
then
	if [ `wc -l $1 | awk '{print $1}'` -gt 1 ]
	then
		echo " INFO  [`date '+%m/%d %H:%M:%S'`] Persist to elastics `basename $1` -> index: $2"
		export index="$2"
		export server="${elastic_server}"
    export logstash_log_dir="${perf_logs_dir}/logstash"
    export logstash_input_file="${1}"
    mkdir -p "${logstash_log_dir}"
    set -x
    docker run -e logstash_config="${logstash_config}" -e index="${index}" -e logstash_input_file="${logstash_input_file}" -e perf_logs_dir="${perf_logs_dir}"  --rm --volume "${logstash_config}":"${logstash_config}":ro  --volume "${logstash_log_dir}":/data:rw --volume "${logstash_etc_files_dir}":/etc/logstash:rw --volume "${perf_logs_dir}":"${perf_logs_dir}":rw --workdir "${perf_logs_dir}" armdocker.rnd.ericsson.se/dockerhub-ericsson-remote/logstash:8.9.2 bash -c  """ logstash -f "\${logstash_config}" --pipeline.workers 1 --path.settings /etc/logstash/ < "\${logstash_input_file}"  """
    set +x
	else
		echo " WARN  [`date '+%m/%d %H:%M:%S'`] Skip elastics `basename $1`, file is empty"
	fi
else
	echo " WARN  [`date '+%m/%d %H:%M:%S'`] Skip elastics `basename $1`, file is missing"
fi
}

function find_end_time {
#---------------------------------------------------------------------------------------------------------
# Find end of data processing and save as $end_ts by checking offset of 5min kafka topics
#---------------------------------------------------------------------------------------------------------

if [ "${debug}" == "true" ]
then
	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] start ts: $start_ts `date -d @${start_ts}`"
	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] traffic stopped: $((start_ts + traffic_length_sec)) `date -d @$((start_ts + traffic_length_sec))`"
	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] traffic+processing_timeout: $((start_ts + traffic_length_sec + processing_timeout_sec)) `date -d @$((start_ts + traffic_length_sec + processing_timeout_sec))`"
fi

end_ts=$((start_ts + traffic_length_sec))
result_string="Data processing hasnt been finished within $((processing_timeout_sec / 60))min"

while [ ${end_ts} -lt $((start_ts + traffic_length_sec + processing_timeout_sec)) ]
do
	offsets_now=`curl -s \
	--data-urlencode 'query=sum (kafka_log_Log_Value{name="LogEndOffset",kubernetes_namespace="eric-eea-ns",topic=~".*_5min|.*-pt5m"}) by (topic)' \
	--data-urlencode 'time='${end_ts}'' \
	http://${pm_server_eea}/api/v1/query \
	| jq -r '[.data.result[] | {(.metric.topic): (.value[1])}] | add' | sed -e 's/\"//g' -e 's/,//g' | grep -v "\{" | grep -v "\}" | sort`

	offsets_later=`curl -s \
	--data-urlencode 'query=sum (kafka_log_Log_Value{name="LogEndOffset",kubernetes_namespace="eric-eea-ns",topic=~".*_5min|.*-pt5m"}) by (topic)' \
	--data-urlencode 'time='$((end_ts + 600))'' \
	http://${pm_server_eea}/api/v1/query \
	| jq -r '[.data.result[] | {(.metric.topic): (.value[1])}] | add' | sed -e 's/\"//g' -e 's/,//g'| grep -v "\{" | grep -v "\}" | sort`

	if [ "${debug}" == "true" ]
	then
		echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ------------NOW: `date -d @${end_ts}`------------"
		echo "${offsets_now}"
		echo " DEBUG [`date '+%m/%d %H:%M:%S'`] ------------NOW+10min: `date -d @$((end_ts + 600))`------------"
		echo "${offsets_later}"
		echo
	fi

	if [ "${offsets_now}" == "${offsets_later}" ]
	then
		result_string="Data processing was successfully finished at ${end_ts}"
		break

	else
		end_ts=$((end_ts + 60))
	fi
done
echo " INFO  [`date '+%m/%d %H:%M:%S'`] ${result_string}"

}

function count_errors_in_eea_logs {
#---------------------------------------------------------------------------------------------------------
# Count crital and error messages in elastic of EEA
#---------------------------------------------------------------------------------------------------------
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Collect eea error logs"

# FILES
report_csv="${output_dir}/eea_error_logs${tag}.csv"
details_csv="${output_dir}/eea_applog_error_messages${tag}.csv"
eea_logs_indexes=(eea-applog eea-auditlog adp-app-logs)

echo "index_name,error_log_count,critical_log_count,buildTime,releaseId,clusterName,ts" > ${report_csv}

for index in ${eea_logs_indexes[@]}
do
echo "${index},\
`curl -sS \
-X GET "${data_search_engine_eea}/${index}-*/_count" \
-H 'Content-Type: application/json' \
-d '{"query": {"bool": {"filter": [{"range": {"timestamp": {"gte": "'$start_ts'","lte": '$end_ts',"format": "epoch_second"}}},{"query_string": {"analyze_wildcard": true,"query": "severity.keyword:error"}}]}}}' \
| jq .count`,\
`curl -sS \
-X GET "${data_search_engine_eea}/${index}-*/_count" \
-H 'Content-Type: application/json' \
-d '{"query": {"bool": {"filter": [{"range": {"timestamp": {"gte": "'$start_ts'","lte": '$end_ts',"format": "epoch_second"}}},{"query_string": {"analyze_wildcard": true,"query": "severity.keyword:critical"}}]}}}' \
| jq .count`,${build_start_time},${release_id},${cluster_config},${start_ts}" >> ${report_csv}
done

echo "ALL,\
`curl -sS \
-X GET "${data_search_engine_eea}/*log*/_count" \
-H 'Content-Type: application/json' \
-d '{"query": {"bool": {"filter": [{"range": {"timestamp": {"gte": "'$start_ts'","lte": '$end_ts',"format": "epoch_second"}}},{"query_string": {"analyze_wildcard": true,"query": "severity.keyword:error"}}]}}}' \
| jq .count`,\
`curl -sS \
-X GET "${data_search_engine_eea}/*log*/_count" \
-H 'Content-Type: application/json' \
-d '{"query": {"bool": {"filter": [{"range": {"timestamp": {"gte": "'$start_ts'","lte": '$end_ts',"format": "epoch_second"}}},{"query_string": {"analyze_wildcard": true,"query": "severity.keyword:critical"}}]}}}' \
| jq .count`,${build_start_time},${release_id},${cluster_config},${start_ts}" >> ${report_csv}

# PERSIST
if [ "$1" == "true" ]
then
	persist	${report_csv} eea4_error_count
fi

#collect error and critical messages from eea-applog
curl -sS \
-X GET "${data_search_engine_eea}/eea-applog*/_search" \
-H 'Content-Type: application/json' \
-d '{"size": 10000,"query": {"bool": {"filter": [{"range": {"timestamp": {"gte": "'$start_ts'","lte": '$end_ts',"format": "epoch_second"}}},{"query_string": {"analyze_wildcard": true,"query": "severity.keyword:error OR severity.keyword:critical"}}]}}}' \
| jq '[.hits.hits[]| {"\(._source.timestamp) [\(._source.severity)] \(._id) \(._source.kubernetes.pod.name)": ._source.message}] | add' > ${details_csv}
}

function collect_eea_logs_doc_number {
#---------------------------------------------------------------------------------------------------------
# Count document number for each service
#---------------------------------------------------------------------------------------------------------
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Collect eea logs document statistic"

# FILES
report_csv="${output_dir}/eea_logs_doc_count${tag}.csv"
eea_logs_indexes=(eea-applog eea-auditlog adp-app-logs)

echo "service,ts,doc_count,index_name,buildTime,releaseId,clusterName" > ${report_csv}

for index in ${eea_logs_indexes[@]}
do
curl -sS \
-X GET "${data_search_engine_eea}/${index}-*/_search" \
-H 'Content-Type: application/json' \
-d '{"size":0,"query":{"bool":{"filter":[{"range":{"timestamp":{"gte":"'$((start_ts-10800))'","lte":"'$end_ts'","format":"epoch_second"}}},{"query_string":{"analyze_wildcard":true,"query":"*"}}]}},"aggs":{"service_list":{"terms":{"field":"service_id.keyword","size":1000,"order":{"_key":"desc"},"min_doc_count":1},"aggs":{"timeseries":{"date_histogram":{"interval":"1m","field":"timestamp","min_doc_count":"1","extended_bounds":{"min":'$((start_ts-10800))'000,"max":'$end_ts'000},"format":"epoch_second"},"aggs":{}}}}}}' \
| jq -r '.aggregations.service_list.buckets[]|{service: .key, tsvalue: .timeseries.buckets[]} | [.service, .tsvalue.key_as_string, .tsvalue.doc_count, "'${index}'", "'${build_start_time}'", "'${release_id}'", "'${cluster_config}'"] | @csv' \
| sed -e 's/\"//g' >> ${report_csv}
done

# PERSIST
if [ "$1" == "true" ]
then
	persist	${report_csv} eea4_log_doc_number
fi

}

function create_node_name_argjson {
#---------------------------------------------------------------------------------------------------------
# Create instance - node reference json
#---------------------------------------------------------------------------------------------------------
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Create Node name argjson"

node_name_argjson=`curl -s \
--data-urlencode 'query=node_uname_info' \
--data-urlencode 'time='${start_ts}'' \
http://${pm_server_ccd}/api/v1/query \
| jq -r '[.data.result[] | {(.metric.instance): (.metric.nodename)} ]| add'`

if [ "${json_debug}" == "true" ]
then

	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] Create node_name${tag}.json"
curl -s \
--data-urlencode 'query=node_uname_info' \
--data-urlencode 'time='${start_ts}'' \
http://${pm_server_ccd}/api/v1/query \
| jq -r '[.data.result[] | {(.metric.instance): (.metric.nodename)} ]| add' > ${output_dir}/node_name${tag}.json
fi
}

function create_node_role_argjson {
#---------------------------------------------------------------------------------------------------------
# Create node - role reference json
#---------------------------------------------------------------------------------------------------------
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Create Node role argjson"

node_role_argjson=`curl -s \
--data-urlencode 'query=kube_node_role' \
--data-urlencode 'time='${start_ts}'' \
http://${pm_server_ccd}/api/v1/query \
| jq -r '[.data.result[] | {(.metric.node): (.metric.role)} ]| add'`

if [ "${json_debug}" == "true" ]
then

	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] Create node_role${tag}.json"
curl -s \
--data-urlencode 'query=kube_node_role' \
--data-urlencode 'time='${start_ts}'' \
http://${pm_server_ccd}/api/v1/query \
| jq -r '[.data.result[] | {(.metric.node): (.metric.role)} ]| add' > ${output_dir}/node_role${tag}.json

fi
}

function create_pod_phase_argjson {
#---------------------------------------------------------------------------------------------------------
# Create namespace_pod_ts - phase reference json
# Phase could be: Failed Pending Running Succeeded Unknown
# kubectl  < - >  phase
#  ------------------
# Evicted - Failed
# Completed - Succeeded
# Error - Failed
# ErrImageNeverPull - Pending  --> POD in pending state, but could be a running container in it eg. 2/3
# Running - Running
# <empty>
#---------------------------------------------------------------------------------------------------------
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Create Pod phase argjson"

curl -s \
--data-urlencode 'query=kube_pod_status_phase{namespace=~"'${namespace_filter}'"}==1' \
--data-urlencode 'start='$((start_ts-240))'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r '[.data.result[] | {ns_pod: "\(.metric.namespace)_\(.metric.pod)", phase: .metric.phase, tsvalue: .values[]} | {"\(.ns_pod)_\(.tsvalue[0])": (.phase)}] | add' > ${temp_pod_phase_ref_json_file}


if [ "${json_debug}" == "true" ]
then

	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] Create pod_phase${tag}.json"
curl -s \
--data-urlencode 'query=kube_pod_status_phase{namespace=~"'${namespace_filter}'"}==1' \
--data-urlencode 'start='$((start_ts-240))'' \
--data-urlencode 'end='$end_ts'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq -r '[.data.result[] | {ns_pod: "\(.metric.namespace)_\(.metric.pod)", phase: .metric.phase, tsvalue: .values[]} | {"\(.ns_pod)_\(.tsvalue[0])": (.phase)}] | add' > ${output_dir}/pod_phase${tag}.json

fi
}

function create_microservice_argjson {
#---------------------------------------------------------------------------------------------------------
# Create namespace_pod - microservice reference json
#
#  Prio: <namespace>_<pod>: <label>
#   1) label_app_kubernetes_io_name
#   2) label_app
#   3) none of them -> <namespace>_<pod>: no_label_<namespace>_<pod>
###   0) label_aggregator_type (just for stream_aggregator) overwrite the existing stream-aggregator labels
#---------------------------------------------------------------------------------------------------------
echo " INFO  [`date '+%m/%d %H:%M:%S'`] Create Microservice argjson"

microservice_argjson=`(curl -s \
--data-urlencode 'query=kube_pod_labels{label_app_kubernetes_io_name!=""}' \
--data-urlencode 'start='$((start_ts-300))'' \
--data-urlencode 'end='${end_ts}'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq  -r '[.data.result[].metric | {"\(.namespace)_\(.pod)": .label_app_kubernetes_io_name}]';
curl -s \
--data-urlencode 'query=kube_pod_labels{label_app_kubernetes_io_name="", label_app!=""}' \
--data-urlencode 'start='$((start_ts-300))'' \
--data-urlencode 'end='${end_ts}'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq  -r '[.data.result[].metric | {"\(.namespace)_\(.pod)": .label_app}]';
curl -s \
--data-urlencode 'query=kube_pod_labels{label_app_kubernetes_io_name="", label_app=""}' \
--data-urlencode 'start='$((start_ts-300))'' \
--data-urlencode 'end='${end_ts}'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq  -r '[.data.result[].metric | {"\(.namespace)_\(.pod)": ("no_label_" + .namespace + "_" + .pod)}]') \
| jq -r -s 'map(.[]) | add'`

#; \
#curl -s \
#--data-urlencode 'query=kube_pod_labels{label_aggregator_type!=""}' \
#--data-urlencode 'start='$((start_ts-300))'' \
#--data-urlencode 'end='${end_ts}'' \
#--data-urlencode 'step='${step}'s' \
#http://${pm_server_ccd}/api/v1/query_range \
#| jq  -r '[.data.result[].metric | {"\(.namespace)_\(.pod)": .label_aggregator_type}]'




if [ "${json_debug}" == "true" ]
then
	echo " DEBUG [`date '+%m/%d %H:%M:%S'`] Create microservice${tag}.json"

(curl -s \
--data-urlencode 'query=kube_pod_labels{label_app_kubernetes_io_name!=""}' \
--data-urlencode 'start='$((start_ts-300))'' \
--data-urlencode 'end='${end_ts}'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq  -r '[.data.result[].metric | {"\(.namespace)_\(.pod)": .label_app_kubernetes_io_name}]';
curl -s \
--data-urlencode 'query=kube_pod_labels{label_app_kubernetes_io_name="", label_app!=""}' \
--data-urlencode 'start='$((start_ts-300))'' \
--data-urlencode 'end='${end_ts}'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq  -r '[.data.result[].metric | {"\(.namespace)_\(.pod)": .label_app}]';
curl -s \
--data-urlencode 'query=kube_pod_labels{label_app_kubernetes_io_name="", label_app=""}' \
--data-urlencode 'start='$((start_ts-300))'' \
--data-urlencode 'end='${end_ts}'' \
--data-urlencode 'step='${step}'s' \
http://${pm_server_ccd}/api/v1/query_range \
| jq  -r '[.data.result[].metric | {"\(.namespace)_\(.pod)": ("no_label_" + .namespace + "_" + .pod)}]') \
| jq -r -s 'map(.[]) | add' > ${output_dir}/microservice${tag}.json

fi
}

function description {
#---------------------------------------------------------------------------------------------------------
#                                        Description
#---------------------------------------------------------------------------------------------------------
echo "
	Usage:
		$0 -s <start_time[epoch]> -e <end_time[epoch]> -c <cluster_config> -b <build_start_time>
		OR
		$0 -f config file

	Mandatory:
	-s <start_ts[epoch_sec]>
	-e <end_ts[epoch_sec]>
	-c <cluster_name>                this value will be included in the CSVs in a dedicated column
	-b <build_start_time>            this value will be included in the CSVs in a dedicated column

	Optional:
	-e <end_ts[epoch]>
	-o <output_directory>            directory will be created if does not exist
	-t <traffic_length_sec>          traffic length in sec
	-d <elastic_server_host:port>    default: seliics02376:9200
	-r <release_id>                  default: dummy, aggregated result will be grouped by this tag for perf report in grafana
	-m <\"comment\">                   comment, free text between \" \"
	-g <group_of_metrics>            comma separated list of selected metric groups without space. Groups: build,k8s,java,node,kafka,besr,database,csv,elastics (default: \"build,k8s,java,node,kafka,besr,database,csv,elastics\")
	-a                               disable aggregation
	-p                               disable persist
	-j                               save unformatted json outputs
	-v                               verbose

	Example:
		$0 -s 1620271080 -e 1620271280 -c cluster_477 -b 20210820_080000_EEA4.0.0-123
"
	exit 0

}

#===============================================================================================================================
#                                               MAIN
#===============================================================================================================================

#--------------------------------------
#    Read and verify parameters
#--------------------------------------
while getopts "s:e:c:o:t:f:g:d:b:r:i:m:pajyv" flag
do
  case "$flag" in
	s) start_ts=$OPTARG;;
	e) end_ts=$OPTARG;;
	c) cluster_config=$OPTARG;;
	o) output_dir=$OPTARG;;
	t) traffic_length_sec=$OPTARG;;
	f) config_file=$OPTARG;;
	g) group_of_metrics=$OPTARG;;
	d) elastic_server=$OPTARG;;
	b) build_start_time=$OPTARG
	   tag="_$OPTARG";;
	r) release_id=$OPTARG;;
	i) drop_sec=$OPTARG;;
	m) build_comment="$OPTARG";;
	p) persist="false";;
	a) enable_aggregation="false";;
	j) json_debug="true";;
	v) debug="true";;
	y) auto_confirm="true";;
	*) description;;
  esac
done
shift $(($OPTIND - 1))

echo

# source config file
if [ ! -z "${config_file}" ]
then
	if [ -f ${config_file} ]
	then
		echo " INFO  [`date '+%m/%d %H:%M:%S'`] Source ${config_file}"
		cluster_config=`grep -i cluster_config ${config_file} | awk '{print $2}'`
		start_ts=`grep -i start_ts ${config_file} | awk '{print $2}'`
		build_start_time=`grep -i build_start_time ${config_file} | awk '{print $2}'`
		traffic_length_sec=`grep -i traffic_length ${config_file} | awk '{print $2}'`
		release_id=`grep -i release_id ${config_file} | awk '{print $2}'`
	else
		echo " ERROR [`date '+%m/%d %H:%M:%S'`] ${config_file} is missing"
	fi
fi

# verify mandatory parameters
if [ -z "${start_ts}" ] || [ -z "${build_start_time}" ] || [ -z "${cluster_config}" ]
then
	echo -e " ERROR [`date '+%m/%d %H:%M:%S'`] At least one of the mandatory parameter is missing!\n"
	description
fi

# cluster_config
load_cluster_config ${cluster_config}

# find end of data processing by checking of .*5min/pt5m topics

if [ -z "${end_ts}" ] && [ "${traffic_length_sec}" -eq 0 ]
then
	echo " ERROR [`date '+%m/%d %H:%M:%S'`] end_ts or traffic_length_sec is not set"
	exit 1
fi

if [ -z "${end_ts}" ]&& [ ${traffic_length_sec} -gt 1 ]
then
	echo " INFO  [`date '+%m/%d %H:%M:%S'`] end_ts is not set, length of traffic is ${traffic_length_sec}, try to find the end of data processing..."
	find_end_time
# use current time if end_ts is "now"
elif [ "${end_ts}" == "now" ]
then
	end_ts=`date +%s`
fi

# output_dir
if [ -z "${output_dir}" ]
then
	output_dir="${perf_logs_dir}/${cluster_config}/${build_start_time}/metrics"
fi

# data_dir (vertica_tables_size.csv and other csv`s)
data_dir="${perf_logs_dir}/${cluster_config}/${build_start_time}/data"

# release_id
if [ -z "${release_id}" ]
then
	release_id="dummy"
fi

# comment
if [ -z "${build_comment}" ]
then
	build_comment="dummy"
fi

# Need repalce "," to "_" for csv
build_comment=`echo ${build_comment} | sed -e 's/,/_/g' -e 's/ /_/g'`

# Set running parameter file path
running_parameters="${perf_logs_dir}/${cluster_config}/${build_start_time}/running.parameters"

echo "
 ______________________________________________________________________________________________________________________

         CLUSTER_CONFIG: ${cluster_config}

         PM_SERVER_CCD: ${pm_server_ccd}
         PM_SERVER_EEA: ${pm_server_eea}
         ELASTICS_EEA: ${data_search_engine_eea}
         START: ${start_ts} - `date -d @${start_ts} '+%m/%d %H:%M:%S'`
         END:   ${end_ts}-${drop_sec} - `date -d @$((end_ts-drop_sec)) '+%m/%d %H:%M:%S'`
         OUTPUT: ${output_dir}

         BST: ${build_start_time}
         ReleaseId: ${release_id}
         Comment: ${build_comment}

         Duration: $((end_ts - start_ts)) sec
         Traffic : ${traffic_length_sec} sec

         Namespace filter: ${namespace_filter}
         Interface filter: ${node_interface_filter}
         Disk filter: ${node_disk}

         Metric_groups: ${group_of_metrics}
         Aggregation: ${enable_aggregation}
         Persist: ${persist}
         Elastic server: ${elastic_server}

         verbose: ${debug}
         create debug json: ${json_debug}
 ______________________________________________________________________________________________________________________
" | tee ${script_param_file}


if [ "${auto_confirm}" == "false" ]
then
	echo -e " Press any key\n"
	read
fi

#--------------------------------------
#    Init
#--------------------------------------

# Decrease the end_ts by drop_sec
end_ts=$((end_ts-drop_sec))

# create ouptut_dir
mkdir -p ${output_dir}
chmod 777 -R ${output_dir}
mv ${script_param_file} ${output_dir}
# pod-phase temp reference file
temp_pod_phase_ref_json_file=${output_dir}/ns_pod_ts-phase.json
filtered_report_csv=${output_dir}/filtered_report_csv

#--------------------------------------
#    Create reference JSONs
#--------------------------------------
create_microservice_argjson
create_node_name_argjson
create_node_role_argjson
create_pod_phase_argjson

#--------------------------------------------------------------------------------------
#    Collect metrics,aggregate and persist
#--------------------------------------------------------------------------------------
if [ ! -z `echo ${group_of_metrics} | grep -o build` ]
then
	# BUILD + running.parameters if exist
	collect_build_info ${persist}
fi

if [ ! -z `echo ${group_of_metrics} | grep -o k8s` ]
then
	# CONTAINER/POD LEVEL METRICS
	collect_container_cpu ${persist} ${enable_aggregation}
	collect_container_memory ${persist} ${enable_aggregation}
	collect_container_network ${persist} ${enable_aggregation}
	collect_container_fs ${persist} ${enable_aggregation}
	collect_container_restart ${persist}
	#collect_pod_filesystem ${persist} ${enable_aggregation}
	collect_kube_pod_container_info ${persist}
fi

if [ ! -z `echo ${group_of_metrics} | grep -o java` ]
then
	# JAVA
	collect_java_memory ${persist} ${enable_aggregation}
fi

if [ ! -z `echo ${group_of_metrics} | grep -o node` ]
then
	# NODE LEVEL METRICS
	collect_node_cpu ${persist} ${enable_aggregation}
	collect_node_memory ${persist} ${enable_aggregation}
	collect_node_network ${persist} ${enable_aggregation}
	collect_node_disk ${persist} ${enable_aggregation}
	collect_node_info ${persist}
fi

if [ ! -z `echo ${group_of_metrics} | grep -o kafka` ]
then
	# KAFKA
	collect_kafka_broker ${persist} ${enable_aggregation}
	collect_kafka_topics ${persist} ${enable_aggregation}
#	collect_kafka_topics_v2 ${persist} ${enable_aggregation}
	collect_kafka_info ${persist}
fi

if [ ! -z `echo ${group_of_metrics} | grep -o besr` ]
then
	# BESR
	collect_csm_stat ${persist}
	collect_correlator_stat ${persist}
fi

if [ ! -z `echo ${group_of_metrics} | grep -o database` ]
then
	# DBLoader and Vertica
#	collect_dbloader_stat ${persist}
	collect_vertica_requests ${persist}
#	collect_vertica_data_size ${persist}
	collect_kafka_connect ${persist}
fi

if [ ! -z `echo ${group_of_metrics} | grep -o elastics` ]
then
	# Count error and critail messages in EEA4 elastics
	count_errors_in_eea_logs ${persist}
	# Collect doc number for each service
#set -x
	collect_eea_logs_doc_number ${persist}
#set +x
fi

if [ ! -z `echo ${group_of_metrics} | grep -o csv` ] && [ "${persist}" == "true" ]
then
	# Persist standalone CSVs $1 csv $2 index
	enrich_and_persist_csv ${data_dir}/vertica_tables_size.csv eea4_vertica_tables
	enrich_and_persist_csv ${data_dir}/refdata_tables_size.csv eea4_refdata_tables
fi

echo -e "\n INFO  [`date '+%m/%d %H:%M:%S'`] Done\n"


#--------------------------------------
#    Cleanup
#--------------------------------------
rm -rf ${temp_pod_phase_ref_json_file}
rm -rf ${filtered_report_csv}
rm -rf ${script_param_file}
