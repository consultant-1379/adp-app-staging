zypper  --quiet install -y bind-utils

echo '| Cluster name | Role                      |   Hostname      |   IP address   | CPU |  MEM  | HDD                                                                                        |'
echo '|--------------|---------------------------|-----------------|----------------|-----|-------|--------------------------------------------------------------------------------------------|'


control_plane_node_names=$(kubectl get nodes | grep control-plane | awk '{print $1}')
arr_control_plane_node_names=($control_plane_node_names)
cluster_name=$(echo ${arr_control_plane_node_names[0]} | sed 's/e01//')
for control_plane_node_name in $control_plane_node_names
do
  control_plane_node_ip=$(kubectl describe node $control_plane_node_name | grep 'Addresses' -A 2 | awk '/InternalIP: / {IP=$2} END {print IP}')
  control_plane_node_cpu_core=$(kubectl describe node $control_plane_node_name | grep 'Capacity:' -A 1 |  awk -F'[^0-9]*' '/cpu: / {cpu_core=$2} END {print cpu_core}')
  control_plane_node_mem=$(kubectl describe node $control_plane_node_name | grep 'Capacity:' -A 5 |  awk -F'[^0-9]*' '/memory: / {memory=$2} { round_mem=sprintf("%.1f", (memory/1024/1024))} END { print round_mem}')
  control_plane_disks=$(fdisk -l | grep '/dev/sd[a-z]:' | awk -F'[/ ]' '{print $4" "$5 $6}' | sort  | tr -d '\n' | sed 's/,$//')
  printf '| %-13s| control-plane             | %-16s| %-15s| %-4s| %-6s| %-91s|\n' "$cluster_name" "$control_plane_node_name" "$control_plane_node_ip" "$control_plane_node_cpu_core" "$control_plane_node_mem" "$control_plane_disks"
done

worker_node_names=$(kubectl get nodes | grep worker | awk '{print $1}')
for worker_node_name in $worker_node_names
do
  #echo $worker_node_name
  worker_node_ip=$(kubectl describe node $worker_node_name | grep 'Addresses' -A 2 | awk '/InternalIP: / {IP=$2} END {print IP}')
  #echo $node_ip
  worker_node_cpu_core=$(kubectl describe node $worker_node_name | grep 'Capacity:' -A 1 |  awk -F'[^0-9]*' '/cpu: / {cpu_core=$2} END {print cpu_core}')
  #echo $node_cpu_core
  worker_node_mem=$(kubectl describe node $worker_node_name | grep 'Capacity:' -A 5 |  awk -F'[^0-9]*' '/memory: / {memory=$2} { round_mem=sprintf("%.1f", (memory/1024/1024))} END { print round_mem}')
  #echo $node_mem
  worker_node_disks=$(ssh root@$worker_node_ip "fdisk -l |grep '/dev/sd[a-z]:' | awk -F'[/ ]' '{print \$4 \$5 \$6}' | sort  | tr -d '\n' | sed 's/,$//'")
  #echo $worker_node_disks
  if [ -z ${worker_vip_id+x} ]
  then
    worker_vip_id=$(ssh root@$worker_node_ip "cat /etc/keepalived/keepalived.conf | awk -F'[^0-9]*' '/virtual_router_id / {vr_id=\$2} END {print vr_id}'")
    extra_ips=$(ssh root@$worker_node_ip "cat /etc/keepalived/keepalived.conf | awk '/virtual_ipaddress {/,/}/ {print}' | grep -E -o  '([0-9]{1,3}[\.]){3}[0-9]{1,3}'")
    printf '| VRID:%-8s| worker                    | %-16s| %-15s| %-4s| %-6s| %-91s|\n' "$worker_vip_id" "$worker_node_name" "$worker_node_ip" "$worker_node_cpu_core" "$worker_node_mem" "$worker_node_disks"
  else
    printf '|              | worker                    | %-16s| %-15s| %-4s| %-6s| %-91s|\n' "$worker_node_name" "$worker_node_ip" "$worker_node_cpu_core" "$worker_node_mem" "$worker_node_disks"
  fi

done

extra_ip_functions=('Traffic Ingestion Network' 'Traffic Ingestion Network' 'Traffic Ingestion Network' 'Analytics Data Network' 'Reference Data Network' 'OAM Network' 'OAM Network' 'for additional uses'  )

for extra_ip in $extra_ips
do
  extra_hostname=$(nslookup $extra_ip | grep name | awk -F'= ' '{print $2}' | awk -F'.' '{print $1}')
  extra_ip_function=${extra_ip_functions[0]}
  printf '|              | %-26s| %-16s| %-15s|     |       |                                                                                            |\n' "$extra_ip_function" "$extra_hostname" "$extra_ip"
  extra_ip_functions_size=$(echo ${#extra_ip_functions[@]})
  if [ "$extra_ip_functions_size" -gt "1" ]
  then
    extra_ip_functions=("${extra_ip_functions[@]:1}")
  fi
done
