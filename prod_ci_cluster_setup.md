# Product CI cluster setup

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

***NOTE:***
This reference was created for CCD 2.19 release, currently used for CCD 2.22 as well.
The install procedure for ESXi cluster is based on [CCD 2.19 Life Cycle Management on Pre-Provisioned Servers](https://cpistore.internal.ericsson.com/elex?LI=EN/LZN%20792%200009/1%20R22B).

The Product CI cluster setup based on [RV cluster install solution](https://eteamspace.internal.ericsson.com/display/EEAInV/04+EEA4+Cluster+Installation+Descriptions)

## Automated cluster reinstall

We can now (re)install a Product CI cluster with [cluster-reinstall](https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-reinstall/) Jenkins job that includes all steps that were previously done manually and described in the following section.

## CCD Install and remain manual steps

We can (re)install Product CI cluster with [CCD Install Jenkins job](https://seliius27190.seli.gic.ericsson.se:8443/job/rv-ccd-install/) and with few further manual steps.
Please follow these steps:

+ Change cluster label to another than 'bob-ci' with [lockable-resource-label-change](https://seliius27190.seli.gic.ericsson.se:8443/job/lockable-resource-label-change/), e.g. use (re)install Jira ticket number as the cluster label
+ Execute [CCD Install Jenkins job](https://seliius27190.seli.gic.ericsson.se:8443/job/rv-ccd-install/)
+ Apply jenkins service account user RBAC to cluster, e.g. for seliics04535 cluster:

```
git clone https://<<User-Id>>@gerrit.ericsson.se/a/EEA/adp-app-staging
cd adp-app-staging/cluster_tools
scp jenkins_rbac.yml root@seliics04535e01:
scp jenkins_secret.yml root@seliics04535e01:
ssh root@seliics04535e01
[root@seliics04535e01] kubectl apply -f jenkins_rbac.yml
[root@seliics04535e01] kubectl apply -f jenkins_secret.yml
```

+ Create Kubernetes config with Jenkins user credential:

```
cp .kube/config "${HOSTNAME}_kube.config"
sed -i 's/kubernetes-admin/jenkins/g' "${HOSTNAME}_kube.config"
sed -i 's/^.*client-key-data:.*//g' "${HOSTNAME}_kube.config"
jenkins_token=$(kubectl -n default get secret $(kubectl -n default get serviceaccount/jenkins -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}'| base64 --decode)
sed -i "s/client-certificate-data:.*/token: ${jenkins_token}/g" "${HOSTNAME}_kube.config"
default_if_ip=$(default_if=$(ip route list | awk '/^default/ {print $5}'); ip addr show "$default_if" | grep 'inet ' | grep 'brd' | awk '{print $2}' | cut -f1 -d'/')
sed -i "s/nodelocal-api.eccd.local/${default_if_ip}/g" "${HOSTNAME}_kube.config"
sed -i '/^$/d' "${HOSTNAME}_kube.config"
```

+ Add kubernetes-service-eea-endpoints job_name to eric-victoria-metrics-vmagent configmap:

```
kubectl edit configmaps -n monitoring eric-victoria-metrics-vmagent
```

Put the next code part before `kind: ConfigMap` line:

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

+ Save Kubernetes config and upload to both [EEA4 Jenkins](https://seliius27190.seli.gic.ericsson.se:8443/credentials/) and [EEA4 Test Jenkins](https://seliius27102.seli.gic.ericsson.se:8443/credentials/)
+ Create Victoria Loadbalancer

```
export ccd_monitoring_ns=monitoring
kubectl create service -n ${ccd_monitoring_ns} loadbalancer eric-victoria-metrics-cluster-vmselect-lb --tcp=4770:8481
kubectl patch service -n ${ccd_monitoring_ns} eric-victoria-metrics-cluster-vmselect-lb -p '{"spec": {"selector": {"app": "vmselect", "app.kubernetes.io/instance": "eric-victoria-metrics-cluster", "app.kubernetes.io/name": "eric-victoria-metrics-cluster"}}}'
export OAM_POOL=pool0
kubectl patch service -n ${ccd_monitoring_ns} eric-victoria-metrics-cluster-vmselect-lb -p '{"metadata": {"annotations": {"metallb.universe.tf/allow-shared-ip": "rv-platform"}}}'
kubectl patch service -n ${ccd_monitoring_ns} eric-victoria-metrics-cluster-vmselect-lb -p '{"metadata": {"annotations": {"metallb.universe.tf/address-pool": "'"${OAM_POOL}"'"}}}'
```

+ Validate the cluster installation with [cluster-validate](https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-validate/) run, specifying the correct CLUSTER parameter, e.g. set it to kubeconfig-seliics04535

## Prerequisite

Please make sure you have the latest Network Interface firmwares.
You can download HP firmware upgrade tools from: [HP Support Center](https://support.hpe.com/connect/s/?language=en_US) and
Dell the newest BIOS version from: [Dell Support Center](https://www.dell.com/support/home/en-us?app=products&lwp=rt),
but it better to send a request to ENV Team on email <pdlceaenvc@pdl.internal.ericsson.com>

***NOTE*** In order to figure out a FQDN or IP address of Integrated Dell Remote Access Controller (iDRAC) it's necessary to connect
to EEA Admin node (a hostname you can find [here](https://eteamspace.internal.ericsson.com/pages/viewpage.action?spaceKey=ECISE&title=EEA4+Product+CI+Inventory#EEA4ProductCIInventory-Jenkinsservers)
via ssh and fulfill nslookup \<hostname\>-sc command, e.g.:

```
nslookup seliics03117-sc
```

The output should look like below:

```
nslookup seliics03117-sc
Server:         150.132.95.20
Address:        150.132.95.20#53

Name:   seliics03117-sc.ete.ka.sw.ericsson.se
Address: 10.216.191.244
```

The field Name holds FQDN of the suitable iDRAC that let us connect to GUI via https and get useful information such as BIOS version, server model, power state etc.
Eventually, on Dell Support Center site it's possible to know the latest BIOS version by putting server model in search field

## Miminal setup

One master node and 4 worker is the minimum requirement for a cluster setup.
You can mix the ESXi VMs and bare-metals in one EEA4 cluster.

If you have less servers for a one cluster you can create 3 VMs (1 master and 2 worker) on 1 ESXi and 2 workers on bare-metals.

## ESXi

### ESXi resources

+ for ESXi software is necessary reserve 8 vCore and 32 GB memory and 1 storage
+ for master node need to reserve 8 vCore and 32 GB memory and 1 storage
+ for workers you can split the remaining resources
+ OS hard disk size is 600 GB

### Networking

Necessary create Virtual Switches and Port Groups for 10Gbps, 25Gbps nic

### VM creation

+ Memory: Reserve all guest memory (All locked)
+ Hard disk: Thick provisioned, eagerly zeroed
+ VM Option -> Boot Options -> Firmware -> Choose which firmware should be used to boot the virtual machine: BIOS
+ two network interface 1 Gbps and 25 Gbps or 10 Gbps

The ESXi VM creation hard disk 'Thick provisioned, eagerly zeroed' setup is really slow.
My suggestion is first time you create the ESXi VM just with OS disk and when the OS install works properly you can add the data disks for VM.

## VRID (Virtual Router ID) is needed for EEA4 cluster

You can run it on a host where keepalived service (e.g. on existing k8s worker node) is running (or the interface is in promiscuous mode)

```
timeout 20s tcpdump -nni eth0 vrrp > used_vrrp_ids.txt
cat used_vrrp_ids.txt | awk -F',' '{ print $3 }' | sort | uniq
```

If tcpdump utility doesn't exist on the node, it should be installed by zypper package manager because of SUSE Linux 15 OS

```
zypper install tcpdump
```

The selected VRID please put into [cluster_info.yml](https://gerrit.ericsson.se/plugins/gitiles/EEA/inv_test/+/master/eea4/cluster_inventories/cluster_productci_4535/cluster_info.yml#18)
file as a value for worker field, see the example below:

```
vrrp_id:
  master:
  worker: <A unique VRID number>
```

***Note*** For those situations when cluster consist of two or more master nodes it's necessary to fill in master field with a unique VRID number as well!!!

### VRRP ID usage in EEA4

Before you will start use a new VRRP ID please check current usage and extend the table with your choice:
[VRRP ID - Virtual Router ID](https://eteamspace.internal.ericsson.com/display/ECISE/VRRP+ID+-+Virtual+Router+ID)

***Note*** It is necessary to make sure that the VRRP ID unique between our received above list and table content. It's crucial not to use the same IDs for
two different clusters!!!

## Ansible inventory

It is necessary to create an ansible inventory for EEA4 cluster installation. E.g. (CCD 2.19.X compatible):
<https://gerrit.ericsson.se/#/c/10996007/>

## Install steps

You can do the EEA4 installation from an Admin node.

### Admin node installation guide:

[RV Admin node install guide](https://gerrit.ericsson.se/plugins/gitiles/EEA/inv_test/+/master/eea4/install/eea4-admin-node-install.md)

### EEA4 cluster installation guide:

[RV EEA4 cluster installation guide](https://gerrit.ericsson.se/plugins/gitiles/EEA/inv_test/+/master/eea4/install/CCD-installation.md)

### RV_CCD_install Jenkins job

You can do the cluster install with [RV_CCD_install job](https://seliius27190.seli.gic.ericsson.se:8443/job/rv-ccd-install/)

Please set the MAX_PODS parameter to 200

#### You can check connections in data interface, after OS install and configure-additional-interfaces.yml execution

Get data interface name on master node

```
ip a | grep 172.16  | awk '{ print $NF }'
```

Get data interface IP on worker nodes

```
ip a | grep 172.16 | awk -F' ' '{print $2}' | awk -F'/' '{print $1}'
```

Ping another host in data interface

```
ping -I <DATA_IF_NAME> <ANOTHER_NODE_DATA_IP>
```

### Cleanup rook-ceph-status logs

This is part of the RV_CCD_intall Jenkins job. This is a separate [playbook](https://gerrit.ericsson.se/plugins/gitiles/EEA/inv_test/+/refs/heads/master/eea4/install/helper-playbooks/ci-rook-ceph-status-cleanup.yml) that will run if `cleanup_rook_ceph_status_files: true`

Playbook steps:

1. Get cluster number
1. Mount productci NFS
1. Find rook-ceph-status logfile based on the cluster number
1. Archive and remove logfile found in the previous stage
1. Umount productci NFS

## Add eric-eea-ns namespace check by pm-server-ccd-external

The pm-server-ccd-external is deliverd by CCD.

This Prometheus instance exists during the cluster life-time, so we can use this for Product CI metrics collector.

### Extend all namespace list with eric-eea-ns

```
kubectl edit configmaps -n monitoring eric-pm-server-ccd-external -o yaml
```

### Apply configmaps change with scale

```
kubectl scale statefulsets  eric-pm-server-external -n monitoring --replicas=0
kubectl scale statefulsets  eric-pm-server-external -n monitoring --replicas=1
```

### Replicas check

```
kubectl get pods -n monitoring | grep eric-pm-server-external-0
```

### ssh key change between Jenkins slave and cluster master node

Please connect with eceabuild user into Jenkins slave e.g: [selieea0032](https://seliius27190.seli.gic.ericsson.se:8443/computer/selieea0032/) and execute this command:

```
ssh-copy-id -i .ssh/id_rsa.pub root@seliics02681e01
```

### Jenkins service account

When you have an installed EEA4 cluster please add the Jenkins service account, the ci-machinery clusterrole, and the clusterrole-binding between them.

#### Jenkins rbac file location

You can found the latest secreted version in gerrit [jenkins_rbac.yml](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/cluster_tools/jenkins_rbac.yml)

If you dont already have it, the up-to-date config can be extracted from an already configured cluster with commands below:

```
kubectl apply -f jenkins.yml
```

How to get jenkins user rbac

```
(kubectl neat get -- clusterrole ci-machinery -o yaml | sed '/^$/d' - ; echo '---' ; kubectl neat get -- serviceaccount jenkins -o yaml | sed -e '/secrets:/,+1d' - | sed '/^$/d' - ; echo '---' ;  kubectl neat get -- clusterrolebinding ci-entitlement -o yaml| sed '/^$/d' - )
```

Once the Jenkins service account is created, create a kubeconfig file using the token of the jenkins user.

You can do it by copying the admin kubeconfig from `/root/.kube/config` on the master node, and then replacing the admin user certs with the Jenkins serviceaccount token using the key "token:"

```
kubectl -n default get secret $(kubectl -n default get serviceaccount/jenkins -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}'| base64 --decode
```

Please do not forget replace the server:  with master node IP address
E.g.:

```
<     server: https://nodelocal-api.eccd.local:6443
---
>     server: https://10.196.120.52:6443
```

You can do the .kube/config copying like this:

```
cp .kube/config "${HOSTNAME}_kube.config"
sed -i 's/kubernetes-admin/jenkins/g' "${HOSTNAME}_kube.config"
sed -i 's/^ *client-key-data:.*//g' "${HOSTNAME}_kube.config"
jenkins_token=$(kubectl -n default get secret $(kubectl -n default get serviceaccount/jenkins -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}'| base64 --decode)
sed -i "s/client-certificate-data:.*/token: ${jenkins_token}/g" "${HOSTNAME}_kube.config"
default_if_ip=$(default_if=$(ip route list | awk '/^default/ {print $5}'); ip addr show "$default_if" | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/')
sed -i "s/nodelocal-api.eccd.local/${default_if_ip}/g" "${HOSTNAME}_kube.config"
sed -i '/^$/d' "${HOSTNAME}_kube.config"
```

Then please upload this config into Product CI [Jenkins](https://seliius27190.seli.gic.ericsson.se:8443/credentials/) and [Test Jenkins](https://seliius27102.seli.gic.ericsson.se:8443/credentials/) servers

### Grafana

The Grafana dashborads are imported from [inv_test repo](https://gerrit.ericsson.se/plugins/gitiles/EEA/inv_test/+/master/eea4/grafana_dashboards/) by the RV [post-install-steps-rv.yml](https://gerrit.ericsson.se/plugins/gitiles/EEA/inv_test/+/master/eea4/install/helper-playbooks/post-install-steps-rv.yml)

Add anonymous view to the configuration:

```
kubectl edit configmaps grafana -n eea4-monitoring
```

```
[auth.anonymous]
enabled = true
```

#### Central Grafana Perf_EEA4_Resource

We have central Grafana dashboard and there [Perf_EEA4_Resource](http://seliics00310.ete.ka.sw.ericsson.se:3000/d/rpUQspc4k/perf_eea4_resource?orgId=1) dashboard

When we have a new cluster than we have to add it to the [eea4_perf_report.sh](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/technicals/shellscripts/eea4_perf_report.sh).
Example: [https://gerrit.ericsson.se/#/c/18289749/2/technicals/shellscripts/eea4_perf_report.sh]

Know issue: this script doesn't fullfill for shellcheck requiremnts, therefore we have to commit with manual Verified +1

### The link to the video guides:

<https://ericsson-my.sharepoint.com/:f:/p/fruzsina_anna_kocsis/Emkcw7On_pZPkCe2JOMM5zUBfB4LkZVqyaMlD5KROGLjcw?e=3n89Pb>

### The CCD confluence is here

<https://confluence.lmera.ericsson.se/pages/viewpage.action?spaceKey=CPFE&title=RELEASES>

### More guides:

<https://eteamspace.internal.ericsson.com/display/EEAInV/Rook+ceph+for+cephfs> (rook for file storage only)
<https://eteamspace.internal.ericsson.com/display/EEAInV/Rook+Ceph+Online+Installation> (rook for single storage backend)
<https://eteamspace.internal.ericsson.com/display/EEAInV/How+to+add+monitoring+to+Rook-ceph> (metric scraping for rook)
<https://eteamspace.internal.ericsson.com/display/EEAInV/How+to+deploy+Grafana+and+integrate+to+PM+Server> (Grafana install)

### Careful with these, they’re for 2.11 so they’re not entirely up to date, but they contain a lot of automation:

<https://eteamspace.internal.ericsson.com/pages/viewpage.action?pageId=82990519> (CCD install)
<https://eteamspace.internal.ericsson.com/display/~eblakov/Scale-out+CCD+cluster> (CCD scaleout)
<https://eteamspace.internal.ericsson.com/display/~eblakov/CCD+Monitoring+PoC> (Grafana install)

### Grafana alert configuration:

<https://grafana.com/docs/grafana/latest/alerting/create-alerts/>

### ADP/EEA helm charts:

<https://arm.sero.gic.ericsson.se/artifactory/proj-adp-gs-all-helm/>
<https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm-local>

### MXE certificates

At EEA4 deployments the cluster's own coreDNS is used as DNS server.
Therefore we can use same certificates (both the external CA and MXE certificates) in all clusters from [eea4-certs folder](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/eric-eea-int-helm-chart-ci/static/eea4-certs/)
These are valid till 2033-07-23
