# Cluster reinstall

## Cluster reinstall with cluster-reinstall job

Clusters can be reinstalled with <https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-reinstall/>

## Cluster reinstall (legacy)

This is the legacy (manual) way of reinstalling clusters, that is left here to help understanding the steps. **The preferred way to reinstall clusters is with the reinstall job, please use that!**

### 1. Change label

* Change **cluster label** to different as bob-ci . e.g: **reinstall**
* Use the [lockable-resource-label-change](https://seliius27190.seli.gic.ericsson.se:8443/job/lockable-resource-label-change/) job to change the label
* CLUSTER_NAME parameter according to [lockable-resources](https://seliius27190.seli.gic.ericsson.se:8443/lockable-resources/)

### 2. Start ECCD reinstall

* with the rv-cdd-install Jenkins job: <https://seliius27190.seli.gic.ericsson.se:8443/job/rv-ccd-install/>
* CLUSTER_NAME parameter according to from the [clusterinfo page](https://seliius27190.seli.gic.ericsson.se:8443/job/EEA4-cluster-info-collector/Product_5fCI_5fcluster_5finfos/)

```
CLUSTER_NAME: cluster_productci_2696_10G
CCD_VERSION: 2.23.0
ROOK_VERSION: 1.9.10
MAX_PODS: 200
```

* Also, comment the link of the install job under the ticket.

### 3. Apply jenkins service account user RBAC to cluster

You can find the control plane for the given cluster here: <https://seliius27190.seli.gic.ericsson.se:8443/job/EEA4-cluster-info-collector/Product_5fCI_5fcluster_5finfos/>

Please checkout the adp-app-staging repo, and copy `jenkins_rbac.yml` and `jenkins_secret.yml` to the control plane.

```
cd adp-app-staging/cluster_tools
scp jenkins_rbac.yml root@seliics02696e01:
scp jenkins_secret.yml root@seliics02696e01:
ssh seliics02696e01
[root@seliics02696e01] kubectl apply -f jenkins_rbac.yml
[root@seliics02696e01] kubectl apply -f jenkins_secret.yml
```

### 4. Create Kubernetes config with Jenkins user credential

Please execute the next command on the control plane

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

### 5. Save Kubernetes config and upload to EEA4 Jenkins and EEA4 Test Jenkins

* In Jenkins: Manage jenkins > Manage Credentials > *find the cluster* > *right click on the secret name (last column)* > Update (or use the links below)
* Do this in both [prod](https://seliius27190.seli.gic.ericsson.se:8443/manage/credentials/)- and [test Jenkins](https://seliius27102.seli.gic.ericsson.se:8443/manage/credentials/)

### 6. Please validate the cluster installation

* Run [cluster-validate job](https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-validate/), Where you set [Jenkins lockable resource name of the cluster](https://seliius27190.seli.gic.ericsson.se:8443/lockable-resources/) (eg: kubeconfig-seliics02696_10G) into the CLUSTER parameter

* Also, comment the link of jor validation job under your ticket.

### 7. Upload the information about cluster to dashboard

* Check if the cluster is Product CI

* Upload the cluster name to [dashboard](http://10.223.227.167:61616/swagger-ui/index.html#/cluster-controller/getClusterResources)
