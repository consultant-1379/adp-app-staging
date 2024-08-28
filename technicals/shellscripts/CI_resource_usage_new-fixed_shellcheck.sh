#!/bin/bash
#==================================================================================================================
#                                      REV
#==================================================================================================================
#2021-11-11 First draft
#2022-08-11 Fixes
#2022-08-16 remove unused column

#==================================================================================================================
#                                      PARAMETERS
#==================================================================================================================
#--------------------------------------
# ENVIRONMENT RELATED VARIBLES
#--------------------------------------
logstash_bin="/usr/share/logstash/bin/logstash"
elastic_server="seliics02376:9200"
# debug printouts
debug="false"
# collect json files
json_debug="false"
auto_confirm="false"

#--------------------------------------
# PROCESSING RELATED VARIBLES
#--------------------------------------
# persist to elastics
persist="true"
# namespace_filter
namespace_filter=".*"
# simple query resolution
step=1
# rate query resolution, recommended value: configured scrape_interval*2
rate_step=60

#==================================================================================================================
#                                      FUNCTIONS
#==================================================================================================================

function create_header_and_json_metrics {
#---------------------------------------------------------------------------------------------------------
#                               Generate Header and Json metric list
#---------------------------------------------------------------------------------------------------------
unset json_metrics

for counter in "${report_metrics[@]}"
do
json_metrics="${json_metrics}.${counter},"
done

# HEADER
echo "${json_metrics}clusterName,buildId" >  "${report_csv}"
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
# Standalone Prometheus metrics
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
#  _NOTE_ kube_pod_container_resource_limits_<request>_<unit>s
#  _NOTE_ kube_pod_container_resource_requests<request>_<unit>s
#  - kube_pod_container_resource_limits_cpu_cores  (= kube_pod_container_resource_limits{unit=core,request=cpu}
#  - kube_pod_container_resource_limits_memory_bytes  (= kube_pod_container_resource_limits{unit=byte,request=memory}
#  - kube_pod_container_resource_requests_cpu_cores  (= kube_pod_container_resource_requests{unit=core,request=cpu}
#  - kube_pod_container_resource_requests_memory_bytes  (= kube_pod_container_resource_requests{unit=byte,request=memory}
#  - kube_pod_container_status_running
#  - kube_pod_container_status_ready
#  - kube_pod_container_status_terminated
#  - kube_pod_container_status_waiting
#  - kube_pod_container_status_terminated_reason
#  - kube_pod_container_status_restarts_total
#  - container_memory_failcnt
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
echo " INFO  [$(date '+%m/%d %H:%M:%S')] Collect kube_pod_container_info metrics"

# FILE
report_csv="${output_dir}/container_info${tag}.csv"
debug_json="${output_dir}/container_info${tag}.json"
debug_json2="${output_dir}/container_info${tag}_2.json"
debug_json3="${output_dir}/container_info${tag}_3.json"
debug_json4="${output_dir}/container_info${tag}_4.json"

# METRICS
prometheus_metrics_group_one=(kube_pod_container_resource_limits kube_pod_container_resource_requests kube_pod_container_info)
prometheus_metrics_group_two=(kube_pod_container_status_running kube_pod_container_status_ready kube_pod_container_status_terminated kube_pod_container_status_waiting)
report_metrics=(pod namespace microservice container node image image_id kube_pod_container_status_restarts_total container_memory_failcnt container_cpu_cfs_throttled_seconds_total max_memory_workingset_per_limit max_memory_workingset_per_request max_memory_usage_per_limit max_memory_usage_per_request max_memory_usage min_memory_usage max_memory_working_set min_memory_working_set max_cpu_usage min_cpu_usage max_cpu_usage_per_limit max_cpu_usage_per_request ts kube_pod_container_resource_limits_cpu_cores kube_pod_container_resource_limits_memory_bytes kube_pod_container_resource_requests_cpu_cores kube_pod_container_resource_requests_memory_bytes "${prometheus_metrics_group_two[@]}" kube_pod_container_status_terminated_reason)

# HEADER and json_metrics variable
create_header_and_json_metrics

# DATA

(for counter in "${prometheus_metrics_group_one[@]}"
do
curl -s \
--data-urlencode 'query='"${counter}"'{namespace=~"'"${namespace_filter}"'"}' \
--data-urlencode 'start='"${start_ts}"'' \
--data-urlencode 'end='"${end_ts}"'' \
--data-urlencode 'step='"${step}"'s' \
http://"${pm_server_ccd}"/api/v1/query_range \
| jq -r \
'[.data.result[] | {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, image: .metric.image, image_id: .metric.image_id, resource: .metric.resource, unit: .metric.unit, tsvalue: .values[0]} | { namespace, pod, container, image, image_id, "'"${counter}"'_\(.resource)_\(.unit)s": .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]'
done;

for counter in "${prometheus_metrics_group_two[@]}"
do
curl -s \
--data-urlencode 'query='"${counter}"'{namespace=~"'"${namespace_filter}"'"}' \
--data-urlencode 'start='"${start_ts}"'' \
--data-urlencode 'end='"${end_ts}"'' \
--data-urlencode 'step='"${step}"'s' \
http://"${pm_server_ccd}"/api/v1/query_range \
| jq -r \
'[.data.result[] | {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, tsvalue: .values[-1]} | { namespace, pod, container, image, image_id, "'"${counter}"'": .tsvalue[1]|tonumber}  | with_entries(select( .value != null ))]'
done;

curl -s \
--data-urlencode 'query=kube_pod_container_status_terminated_reason{namespace=~"'"${namespace_filter}"'"} ==1' \
--data-urlencode 'start='"${start_ts}"'' \
--data-urlencode 'end='"${end_ts}"'' \
--data-urlencode 'step='"${step}"'s' \
http://"${pm_server_ccd}"/api/v1/query_range \
| jq -r '[.data.result[]| {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, kube_pod_container_status_terminated_reason: .metric.reason }]';

curl -s \
--data-urlencode 'query=kube_pod_container_status_restarts_total{namespace=~"'"${namespace_filter}"'"}' \
--data-urlencode 'start='"${start_ts}"'' \
--data-urlencode 'end='"${end_ts}"'' \
--data-urlencode 'step='"${step}"'s' \
http://"${pm_server_ccd}"/api/v1/query_range \
| jq -r '[.data.result[]| {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, "kube_pod_container_status_restarts_total": ((.values|max[1]|tonumber) - (.values|min[1]|tonumber)) }]';

curl -s \
--data-urlencode 'query=container_memory_failcnt{container!~"POD|",image!="",namespace=~"'"${namespace_filter}"'"}' \
--data-urlencode 'start='"${start_ts}"'' \
--data-urlencode 'end='"${end_ts}"'' \
--data-urlencode 'step='"${step}"'s' \
http://"${pm_server_ccd}"/api/v1/query_range \
| jq -r '[.data.result[]| {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, node: .metric.instance, "container_memory_failcnt": ((.values|max[1]|tonumber) - (.values|min[1]|tonumber)) }]';

curl -s \
--data-urlencode 'query=container_memory_usage_bytes{container!~"POD|",image!="",namespace=~"'"${namespace_filter}"'"}' \
--data-urlencode 'start='"${start_ts}"'' \
--data-urlencode 'end='"${end_ts}"'' \
--data-urlencode 'step='"${step}"'s' \
http://"${pm_server_ccd}"/api/v1/query_range \
| jq -r '[.data.result[]| {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, node: .metric.instance, "max_memory_usage": ([.values[][1]|tonumber]|max), "min_memory_usage": ([.values[][1]|tonumber]|min) }]';

curl -s \
--data-urlencode 'query=container_memory_working_set_bytes{container!~"POD|",image!="",namespace=~"'"${namespace_filter}"'"}' \
--data-urlencode 'start='"${start_ts}"'' \
--data-urlencode 'end='"${end_ts}"'' \
--data-urlencode 'step='"${step}"'s' \
http://"${pm_server_ccd}"/api/v1/query_range \
| jq -r '[.data.result[]| {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, node: .metric.instance, "max_memory_working_set": ([.values[][1]|tonumber]|max), "min_memory_working_set": ([.values[][1]|tonumber]|min)}]';

curl -s \
--data-urlencode 'query=round(rate(container_cpu_usage_seconds_total{container!~"POD|",image!="",namespace=~"'"${namespace_filter}"'"}['${rate_step}'s]),0.001)' \
--data-urlencode 'start='"${start_ts}"'' \
--data-urlencode 'end='"${end_ts}"'' \
--data-urlencode 'step='"${step}"'s' \
http://"${pm_server_ccd}"/api/v1/query_range \
| jq -r '[.data.result[]| {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, node: .metric.instance, "max_cpu_usage": ([.values[][1]|tonumber]|max), "min_cpu_usage": ([.values[][1]|tonumber]|min)}]' ) \
| jq -r -s \
--argjson microservice "${microservice_argjson}" \
'map(.[]) | group_by (.pod, .namespace, .container)[] | add | .microservice += $microservice[(.namespace + "_" + .pod)] | if (.max_memory_usage == null or .kube_pod_container_resource_limits_memory_bytes == null or .kube_pod_container_resource_limits_memory_bytes == 0 ) then .max_memory_usage_per_limit += "0" else .max_memory_usage_per_limit += (.max_memory_usage / .kube_pod_container_resource_limits_memory_bytes * 100 | round / 100) end | if (.max_memory_working_set == null or .kube_pod_container_resource_limits_memory_bytes == null or .kube_pod_container_resource_limits_memory_bytes == 0 ) then .max_memory_workingset_per_limit += "0" else .max_memory_workingset_per_limit += (.max_memory_working_set / .kube_pod_container_resource_limits_memory_bytes * 100 | round / 100) end | if (.max_cpu_usage == null or .kube_pod_container_resource_limits_cpu_cores == null or .kube_pod_container_resource_limits_cpu_cores == 0 ) then .max_cpu_usage_per_limit += "0" else .max_cpu_usage_per_limit += (.max_cpu_usage / .kube_pod_container_resource_limits_cpu_cores * 100 | round / 100)  end | if (.max_memory_usage == null or .kube_pod_container_resource_requests_memory_bytes == null or .kube_pod_container_resource_requests_memory_bytes == 0 ) then .max_memory_usage_per_request += "0" else .max_memory_usage_per_request += (.max_memory_usage / .kube_pod_container_resource_requests_memory_bytes * 100 | round / 100) end | if (.max_memory_working_set == null or .kube_pod_container_resource_requests_memory_bytes == null or .kube_pod_container_resource_requests_memory_bytes == 0 ) then .max_memory_workingset_per_request += "0" else .max_memory_workingset_per_request += (.max_memory_working_set / .kube_pod_container_resource_requests_memory_bytes * 100 | round / 100) end | if (.max_cpu_usage == null or .kube_pod_container_resource_requests_cpu_cores == null or .kube_pod_container_resource_requests_cpu_cores == 0 ) then .max_cpu_usage_per_request += "0" else .max_cpu_usage_per_request += ( .max_cpu_usage / .kube_pod_container_resource_requests_cpu_cores * 100 | round / 100 )  end | .ts += "'"${start_ts}"'" | ['"${json_metrics}"' "'"${cluster_config}"'", "'"${build_start_time}"'"] | @csv' | sed -e 's/\"//g' >> "${report_csv}"

# PERSIST
if [ "$1" == "true" ]
then
persist	"${report_csv}" ci_kube_pod_container_info
fi

# DEBUG
if [ "${json_debug}" == "true" ]
then

echo " DEBUG [$(date '+%m/%d %H:%M:%S')] ${debug_json}"

for counter in "${prometheus_metrics_group_one[@]}"
do
curl -s \
--data-urlencode 'query='"${counter}"'{namespace=~"'"${namespace_filter}"'"}' \
--data-urlencode 'start='"${start_ts}"'' \
--data-urlencode 'end='"${end_ts}"'' \
--data-urlencode 'step='"${step}"'s' \
http://"${pm_server_ccd}"/api/v1/query_range \
| jq -r \
'[.data.result[] | {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, image: .metric.image, image_id: .metric.image_id, resource: .metric.resource, unit: .metric.unit, tsvalue: .values[0]} | { namespace, pod, container, image, image_id, "'"${counter}"'_\(.resource)_\(.unit)s": .tsvalue[1]|tonumber} | with_entries(select( .value != null ))]'
done >> "${debug_json}"

echo " DEBUG [$(date '+%m/%d %H:%M:%S')] ${debug_json2}"

for counter in "${prometheus_metrics_group_two[@]}"
do
curl -s \
--data-urlencode 'query='"${counter}"'{namespace=~"'"${namespace_filter}"'"}' \
--data-urlencode 'start='"${start_ts}"'' \
--data-urlencode 'end='"${end_ts}"'' \
--data-urlencode 'step='"${step}"'s' \
http://"${pm_server_ccd}"/api/v1/query_range \
| jq -r \
'[.data.result[] | {namespace: .metric.namespace, pod: .metric.pod, container: .metric.container, tsvalue: .values[-1]} | { namespace, pod, container, image, image_id, "'"${counter}"'": .tsvalue[1]|tonumber}  | with_entries(select( .value != null ))]'
done > "${debug_json2}"

curl -s \
--data-urlencode 'query=container_memory_usage_bytes{container!~"POD|",image!="",namespace=~"'"${namespace_filter}"'"}' \
--data-urlencode 'start='"${start_ts}"'' \
--data-urlencode 'end='"${end_ts}"'' \
--data-urlencode 'step='"${step}"'s' \
http://"${pm_server_ccd}"/api/v1/query_range \
| jq -r '[.data.result[]| {"\(.metric.namespace)_\(.metric.pod)_\(.metric.container)": ([.values[][1]|tonumber]|max) }] | sort | add' > "${debug_json3}"

curl -s \
--data-urlencode 'query=container_memory_working_set_bytes{container!~"POD|",image!="",namespace=~"'"${namespace_filter}"'"}' \
--data-urlencode 'start='"${start_ts}"'' \
--data-urlencode 'end='"${end_ts}"'' \
--data-urlencode 'step='"${step}"'s' \
http://"${pm_server_ccd}"/api/v1/query_range \
| jq -r '[.data.result[]| {"\(.metric.namespace)_\(.metric.pod)_\(.metric.container)": ([.values[][1]|tonumber]|max) }] | sort | add' > "${debug_json4}"

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
# Report metrics group
#  - node
#  - ts = start_time
#  - kube_node_status_capacity_cpu_cores = kube_node_status_capacity{resource="cpu", unit="core"}
#  - kube_node_status_capacity_pods_integers = kube_node_status_capacity{resource="pods", unit="integer"} (rename to kube_node_status_capacity_pods with sed in the report header)
#  - kube_node_status_capacity_memory_bytes = kube_node_status_capacity{resource="memory", unit="byte"}
#  - kube_node_status_allocatable_cpu_cores = kube_node_status_allocatable{resource="cpu", unit="core"}
#  - kube_node_status_allocatable_pods_integers = kube_node_status_allocatable{resource="pods", unit="integer"} (rename to kube_node_status_capacity_pods with sed in the header)
#  - kube_node_status_allocatable_memory_bytes = kube_node_status_allocatable{resource="memory", unit="byte"}
#  - container_runtime_version  (kube_node_info)
#  - kernel_version             (kube_node_info)
#  - kubelet_version            (kube_node_info)
#  - kubeproxy_version          (kube_node_info)
#  - os_image                   (kube_node_info)
#  - role                       (kube_node_role)
#  - label_ccd_version          (kube_node_labels)
#
#---------------------------------------------------------------------------------------------------------
echo " INFO  [$(date '+%m/%d %H:%M:%S')] Collect node_info metrics"

# FILES
report_csv="${output_dir}/node_info${tag}.csv"
debug_json="${output_dir}/node_info${tag}.json"
debug_json2="${output_dir}/node_info2${tag}.json"

# METRICS
prometheus_metrics_group_one=(kube_node_info kube_node_role kube_node_labels)
prometheus_metrics_group_two=(kube_node_status_capacity kube_node_status_allocatable)

report_metrics=(node ts kube_node_status_capacity_cpu_cores kube_node_status_capacity_pods_integers kube_node_status_capacity_memory_bytes kube_node_status_allocatable_cpu_cores kube_node_status_allocatable_pods_integers kube_node_status_allocatable_memory_bytes container_runtime_version kernel_version kubelet_version kubeproxy_version os_image role label_ccd_version)

# HEADER and json_metrics variable
create_header_and_json_metrics

# DATA
(for counter in "${prometheus_metrics_group_one[@]}"
do
curl -s \
--data-urlencode 'query='"${counter}"'' \
--data-urlencode 'start='"${start_ts}"'' \
http://"${pm_server_ccd}"/api/v1/query \
| jq -r \
'[.data.result[].metric | with_entries(select( .value != null ))]'
done;
for counter in "${prometheus_metrics_group_two[@]}"
do
curl -s \
--data-urlencode 'query='"${counter}"'' \
--data-urlencode 'start='"${start_ts}"'' \
http://"${pm_server_ccd}"/api/v1/query \
| jq -r \
'[.data.result[] | {node: .metric.node, "'"${counter}"'_\(.metric.resource)_\(.metric.unit)s": .value[1]} |  with_entries(select( .value != null ))]'
done) \
| jq -r -s 'map(.[]) | group_by (.node)[] | add | .ts += "'"${start_ts}"'" | ['"${json_metrics}"' "'"${cluster_config}"'", "'"${build_start_time}"'"] | @csv' \
| sed -e 's/\"//g' >> "${report_csv}"

# DIRTY SOLUTION TO KEEP ORIGINAL NAMES IN ELASTICS/GRAFANA
# Replace kube_node_status_capacity_pods_integers with kube_node_status_capacity_pods
sed -i 's/kube_node_status_capacity_pods_integers/kube_node_status_capacity_pods/g' "${report_csv}"
# Replace kube_node_status_allocatable_pods_integers with kube_node_status_allocatable_pods
sed -i 's/kube_node_status_allocatable_pods_integers/kube_node_status_allocatable_pods/g' "${report_csv}"

# PERSIST
if [ "$1" == "true" ]
then
persist	"${report_csv}" ci_node_info
fi

# DEBUG
if [ "${json_debug}" == "true" ]
then

echo " DEBUG [$(date '+%m/%d %H:%M:%S')] ${debug_json}"

for counter in "${prometheus_metrics_group_one[@]}"
do
curl -s \
--data-urlencode 'query='"${counter}"'' \
--data-urlencode 'start='"${start_ts}"'' \
http://"${pm_server_ccd}"/api/v1/query \
| jq -r \
'[.data.result[] | {node: .metric.node, (.metric.__name__): .value[1]} |  with_entries(select( .value != null ))]'
done > "${debug_json}"

echo " DEBUG [$(date '+%m/%d %H:%M:%S')] ${debug_json2}"

for counter in "${prometheus_metrics_group_two[@]}"
do
curl -s \
--data-urlencode 'query='"${counter}"'' \
--data-urlencode 'start='"${start_ts}"'' \
http://"${pm_server_ccd}"/api/v1/query \
| jq -r \
'[.data.result[] | {node: .metric.node, "'"${counter}"'_\(.metric.resource)_\(.metric.unit)s": .value[1]} |  with_entries(select( .value != null ))]'
done > "${debug_json2}"

fi
}

function persist {
#---------------------------------------------------------------------------------------------------------
# Persist CSV to Elastics
# $1 CSV
# $2 index name
#---------------------------------------------------------------------------------------------------------
if [ -f "$1" ]
then
if [ "$(wc -l "$1" | awk '{print $1}')" -gt 1 ]
then
echo " INFO  [$(date '+%m/%d %H:%M:%S')] Persist to elastics $(basename "$1") -> index: $2"
export index="$2"
export server="${elastic_server}"
if [ "${debug}" == "true" ]
then
${logstash_bin} -f "${output_dir}"/ci_logstash.conf --pipeline.workers 1 --path.settings /etc/logstash < "$1"
else
${logstash_bin} -f "${output_dir}"/ci_logstash.conf --pipeline.workers 1 --path.settings /etc/logstash < "$1" | grep "\[ERROR\]"
fi
else
echo " WARN  [$(date '+%m/%d %H:%M:%S')] Skip elastics $(basename "$1"), file is empty"
fi
else
echo " WARN  [$(date '+%m/%d %H:%M:%S')] Skip elastics $(basename "$1"), file is missing"
fi
}

function create_microservice_argjson {
#---------------------------------------------------------------------------------------------------------
# Create namespace_pod - microservice reference json
#
#   if label_app_kubernetes_io_name exists: <namespace>_<pod>: <label_app_kubernetes_io_name>
#   if label_app_kubernetes_io_name does not exist but label_app exists: <namespace>_<pod>: <label_app>
#   if label_app_kubernetes_io_name and label_app do not exist: <namespace>_<pod>: no_label_<namespace>_<pod>
#---------------------------------------------------------------------------------------------------------
echo " INFO  [$(date '+%m/%d %H:%M:%S')] Create Microservice argjson"

microservice_argjson=$( (curl -s \
--data-urlencode 'query=kube_pod_labels{label_app_kubernetes_io_name!=""}' \
--data-urlencode 'start='$((start_ts-300))'' \
--data-urlencode 'end='"${end_ts}"'' \
--data-urlencode 'step='"${step}"'s' \
http://"${pm_server_ccd}"/api/v1/query_range \
| jq  -r '[.data.result[].metric | {"\(.namespace)_\(.pod)": .label_app_kubernetes_io_name}]';
curl -s \
--data-urlencode 'query=kube_pod_labels{label_app_kubernetes_io_name="", label_app!=""}' \
--data-urlencode 'start='$((start_ts-300))'' \
--data-urlencode 'end='"${end_ts}"'' \
--data-urlencode 'step='"${step}"'s' \
http://"${pm_server_ccd}"/api/v1/query_range \
| jq  -r '[.data.result[].metric | {"\(.namespace)_\(.pod)": .label_app}]';
curl -s \
--data-urlencode 'query=kube_pod_labels{label_app_kubernetes_io_name="", label_app=""}' \
--data-urlencode 'start='$((start_ts-300))'' \
--data-urlencode 'end='"${end_ts}"'' \
--data-urlencode 'step='"${step}"'s' \
http://"${pm_server_ccd}"/api/v1/query_range \
| jq  -r '[.data.result[].metric | {"\(.namespace)_\(.pod)": ("no_label_" + .namespace + "_" + .pod)}]') \
| jq -r -s 'map(.[]) | add')

if [ "${json_debug}" == "true" ]
then
echo " DEBUG [$(date '+%m/%d %H:%M:%S')] Create microservice${tag}.json"

(curl -s \
--data-urlencode 'query=kube_pod_labels{label_app_kubernetes_io_name!=""}' \
--data-urlencode 'start='$((start_ts-300))'' \
--data-urlencode 'end='"${end_ts}"'' \
--data-urlencode 'step='"${step}"'s' \
http://"${pm_server_ccd}"/api/v1/query_range \
| jq  -r '[.data.result[].metric | {"\(.namespace)_\(.pod)": .label_app_kubernetes_io_name}]';
curl -s \
--data-urlencode 'query=kube_pod_labels{label_app_kubernetes_io_name="", label_app!=""}' \
--data-urlencode 'start='$((start_ts-300))'' \
--data-urlencode 'end='"${end_ts}"'' \
--data-urlencode 'step='"${step}"'s' \
http://"${pm_server_ccd}"/api/v1/query_range \
| jq  -r '[.data.result[].metric | {"\(.namespace)_\(.pod)": .label_app}]';
curl -s \
--data-urlencode 'query=kube_pod_labels{label_app_kubernetes_io_name="", label_app=""}' \
--data-urlencode 'start='$((start_ts-300))'' \
--data-urlencode 'end='"${end_ts}"'' \
--data-urlencode 'step='"${step}"'s' \
http://"${pm_server_ccd}"/api/v1/query_range \
| jq  -r '[.data.result[].metric | {"\(.namespace)_\(.pod)": ("no_label_" + .namespace + "_" + .pod)}]') \
| jq -r -s 'map(.[]) | add' > "${output_dir}"/microservice"${tag}".json

fi
}

function create_logstash_config {

echo "
input {
stdin {}
}

filter {
csv {
separator => \",\"
autodetect_column_names => true
convert => {
\"kube_pod_container_status_restarts_total\" => \"integer\"
\"kube_pod_container_resource_limits_memory_bytes\" => \"integer\"
\"kube_pod_container_resource_requests_memory_bytes\" => \"integer\"
\"kube_pod_container_resource_limits_cpu_cores\" => \"float\"
\"kube_pod_container_resource_requests_cpu_cores\" => \"float\"
\"container_memory_failcnt\" => \"integer\"
\"kube_node_status_capacity_cpu_cores\" => \"integer\"
\"kube_node_status_capacity_pods\" => \"integer\"
\"kube_node_status_capacity_memory_bytes\" => \"integer\"
\"kube_node_status_allocatable_cpu_cores\" => \"integer\"
\"kube_node_status_allocatable_pods\" => \"integer\"
\"kube_node_status_allocatable_memory_bytes\" => \"integer\"
\"max_memory_usage\" => \"integer\"
\"min_memory_usage\" => \"integer\"
\"max_memory_working_set\" => \"integer\"
\"min_memory_working_set\" => \"integer\"
\"max_cpu_usage\" => \"float\"
\"min_cpu_usage\" => \"float\"
\"max_cpu_usage_per_limit\" => \"float\"
\"max_cpu_usage_per_request\" => \"float\"
\"max_memory_usage_per_limit\" => \"float\"
\"max_memory_usage_per_request\" => \"float\"
\"max_memory_workingset_per_limit\" => \"float\"
\"max_memory_workingset_per_request\" => \"float\"
}
}

date {
match => [ \"ts\", \"UNIX\" ]
target => \"Timestamp\"

}
mutate {
remove_field => \"@timestamp\"
remove_field => \"@version\"
remove_field => \"message\"
remove_field => \"path\"
remove_field => \"host\"
remove_field => \"ts\"
}
}

output {
elasticsearch {
hosts => \"http://\${server}\"
index => \"\${index}\"
}
}" > "${output_dir}"/ci_logstash.conf

}

function description {
#---------------------------------------------------------------------------------------------------------
#                                        Description
#---------------------------------------------------------------------------------------------------------
echo "
Usage:
$0 -s <start_time[epoch]> -e <end_time[epoch]> -c <cluster_config> -b <build_start_time>

Mandatory:
-s <start_ts[epoch]>
-e <end_ts[epoch]>
-c <cluster_name>
-b <build_id>
-p <ccd_pm_server_ip:port> or <ccd_vic_server_ip:port>/select/0/prometheus

Optional:
-o <output_directory>            directory will be created if does not exist
-d <elastic_server>              default (seliics02376)
-y                               auto confirm
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
while getopts "s:e:c:o:d:p:b:ljyv" flag
do
case "$flag" in
s) start_ts=$OPTARG;;
e) end_ts=$OPTARG;;
c) cluster_config=$OPTARG;;
o) output_dir=$OPTARG;;
d) elastic_server=$OPTARG;;
p) pm_server_ccd=$OPTARG;;
b) build_start_time=$OPTARG
tag="_$OPTARG";;
l) persist="false";;
j) json_debug="true";;
v) debug="true";;
y) auto_confirm="true";;
*) description;;
esac
done
shift "$(OPTIND - 1)"

# verify mandatory parameters
if [ -z "${start_ts}" ] || [ -z "${end_ts}" ] || [ -z "${build_start_time}" ] || [ -z "${cluster_config}" ] || [ -z "${pm_server_ccd}" ]
then
echo -e " ERROR [$(date '+%m/%d %H:%M:%S')] At least one of the mandatory parameter is missing!\n"
description
fi

# output_dir
if [ -z "${output_dir}" ]
then
output_dir="/tmp/${cluster_config}/${build_start_time}"
fi

echo "
______________________________________________________________________________________________________________________

CLUSTER_CONFIG: ${cluster_config}

CCD_METRIC_SERVER: ${pm_server_ccd}
START: ${start_ts} - $(date -d @"${start_ts}" '+%m/%d %H:%M:%S')
END:   ${end_ts} - $(date -d @"${end_ts}" '+%m/%d %H:%M:%S')
OUTPUT: ${output_dir}
Build_id: ${build_start_time}
Elastics: ${elastic_server}
______________________________________________________________________________________________________________________
"
if [ "${auto_confirm}" == "false" ]
then
echo -e " Press any key\n"
read -r
fi

#--------------------------------------
#    Init
#--------------------------------------

# create ouptut_dir
mkdir -p "${output_dir}"
chmod 777 -R "${output_dir}"

#--------------------------------------
#    Create logstash config
#--------------------------------------
create_logstash_config

#--------------------------------------
#    Create reference JSONs
#--------------------------------------
create_microservice_argjson

#--------------------------------------------------------------------------------------
#    Collect metrics,aggregate and persist
#--------------------------------------------------------------------------------------

collect_node_info ${persist}
collect_kube_pod_container_info ${persist}
echo -e "\n INFO  [$(date '+%m/%d %H:%M:%S')] Done\n"

#--------------------------------------
#    Cleanup
#--------------------------------------
