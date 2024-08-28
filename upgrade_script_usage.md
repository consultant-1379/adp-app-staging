# Common upgrade script manual testing guide

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

This testing guide explain how the new common upgrade script can be used for manual testing.

## Upgrade script

- Steps can be executed separately, with the`--steps` flag
- Multiple steps can also be executed serially, use`--help` to see executable actions

## Test environment

We used Product CI clusters for testing. Please book these in advance by sending email to EEA4 Product CI <PDLEEA4PRO@pdl.internal.ericsson.com> including the JIRA ticket number what you're working on. After your booking is confirmed Product CI team the cluster will have the relevant ticket's ID as label in Jenkins and you can start the environment setup. To install a baseline on the cluster first use the clean up and then the create baseline jenkins jobs:

- [Cleanup][3]:
  **CLUSTER_LABEL**: Set by the ProdCI team
  **DESIRED_CLUSTER_LABEL**: Same as the **CLUSTER_LABEL**
- [Baseline install][4]:
  **CLUSTER_LABEL**: Set by the ProdCI team
  **CUSTOM_CLUSTER_LABEL**: Same as the **CLUSTER_LABEL**

At finish:

- EEA baseline was successfully installed on the given cluster

## Docker registry install

[Container registry ADP component.][1]

1. Set variables:

   ```
   REGISTRY_USERNAME=<<REGISTRY_USERNAME>>
   REGISTRY_PASSWORD=<<REGISTRY_PASSWORD>>
   REGISTRY_NS=<<REGISTRY_NAMESPACE>>
   DOCKER_USERNAME=<<ARM_USERNAME>>
   DOCKER_PASSWORD=<<ARM_PASSWORD>>
   DOCKER_PASSWORD_SERO=<<SERO_PASSWORD>>
   ```

1. Create users secret:
   `htpasswd -cBb htpasswd $REGISTRY_USERNAME $REGISTRY_PASSWORD`
1. Create namespace:
   `kubectl create namespace $REGISTRY_NS`
1. Create credentials:

   ```
   echo '{
     "auths": {
       "armdocker.rnd.ericsson.se": {
         "Username": "'$DOCKER_USERNAME'",
         "Password": "'$DOCKER_PASSWORD'",
         "Email": null
       },
       "selidocker.seli.gic.ericsson.se": {
         "Username": "'$DOCKER_USERNAME'",
         "Password": "'$DOCKER_PASSWORD'",
         "Email": null
       },
       "serodocker.sero.gic.ericsson.se": {
         "Username": "'$DOCKER_USERNAME'",
         "Password": "'$DOCKER_PASSWORD_SERO'",
         "Email": null
       },
       "selndocker.mo.sw.ericsson.se": {
         "Username": "'$DOCKER_USERNAME'",
         "Password": "'$DOCKER_PASSWORD_SERO'",
         "Email": null
       }
     }
   }' | kubectl create secret generic arm-pullsecret \
       --namespace $REGISTRY_NS \
       --from-file=.dockerconfigjson=/dev/stdin \
       --type=kubernetes.io/dockerconfigjson
   ```

1. Create secret
   `kubectl create secret generic registry-secret --from-file=htpasswd=./htpasswd -n $REGISTRY_NS`
1. Install registry

   ```
   helm install \
     registry https://arm.sero.gic.ericsson.se/artifactory/proj-adp-container-registry-released-helm/eric-lcm-container-registry/eric-lcm-container-registry-7.7.0+27.tgz \
     --namespace $REGISTRY_NS \
     --atomic \
     --set registry.users.secret=registry-secret \
     --set global.security.tls.enabled=false \
     --set imageCredentials.pullSecret=arm-pullsecret \
     --set persistence.persistentVolumeClaim.size=100Gi \
     --set persistence.persistentVolumeClaim.storageClassName=network-block
   ```

1. Edit insecure-registries:
   `vi /etc/docker/daemon.json`
   Add the registry to this line:
   { "insecure-registries" : [ **"eric-lcm-container-registry-registry.REGISTRY_NS.svc.cluster.local"**] }
   Then restart docker:
   `systemctl restart docker`
1. Check access of the created registry

```
docker login eric-lcm-container-registry-registry.$REGISTRY_NS.svc.cluster.local
```

```
curl -X GET -k http://eric-lcm-container-registry-registry.$REGISTRY_NS.svc.cluster.local/v2/_catalog -u $REGISTRY_USERNAME | json_pp`
```

```
curl -X GET -k http://eric-lcm-container-registry-registry.$REGISTRY_NS.svc.cluster.local/v2/proj-adp-certificate-management-released/eric-sec-certm/eric-sec-certm/tags/list -u $REGISTRY_USERNAME
```

At finish:

- A docker registry was installed on the cluster.

## Load docker registry

1. Create a folder to prepare the values files in it:`mkdir upgradeFolder cd upgradeFolder/`
1. Install wget and download the latest csar package from:`zipper install wget`
   Check the latest CSAR package [here][2].
   `wget https://arm.seli.gic.ericsson.se/artifactory/proj-eea-internal-generic-local/csar-package-4.6.1-84-hd217f2c.csar --user <<SIGNUM>> --ask-password`
1. Create upgrade.sh file with the content of the script `vi upgrade.sh`
1. Create the upgrade script file with the script content:`chmod +x upgrade.sh`
   Unzip the csar package:`unzip csar-package-4.6.1-84-hd217f2c.csar`
   Load the registry

```
./upgrade.sh --steps "load_utils_image_into_registry"
```

```
./upgrade.sh --steps "load_application_images_into_registry" \
             --docker-path /usr/bin/docker \
             --docker-registry-url eric-lcm-container-registry-registry.$REGISTRY_NS.svc.cluster.local
```

At finish:

- The docker registry is filled with images

## Prepare values files for EEA upgrade

For both the eea and mxe upgrade you will need a set of values files, which can be downloaded from your eea-application-staging-product-baseline-install build

1. Download values files from [here](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-product-baseline-install/YOUR_BUILD_NUMBER/artifact/helm_values_eea-application-staging-product-baseline-install_YOUR_BUILD_NUMBER.tar.gz)
1. Unpack the helm values files (the same values files can be used for MXE upgrade, just enable eric-log-shipper)`tar xzvf helm_values_eea-application-staging-product-baseline-install_<<YOUR_BUILD_NUMBER>>.tar.gz`
1. Copy the needed values files to the cluster, where the upgrade is executed. The script.sh, the unpacked CSAR package and the helm-values folder have to be in the same directory.
1. List values files and create the values-files-list.txt
   For both EEA and MXE upgrade you will need a folder filled with the values files downloaded from the jenkins build. If the folders are created and filled, then you will have to create a **values-files-list.txt** which contains the names of the values files separated by lines.
   If you have the same values files for both EEA and MXE upgrade then the same **values-files-list.txt** can be used for both cases.
   Otherwise you have to create a separate **values-files-list.txt** both for EEA and MXE upgrades. For the **values-files-list.txt** files you have to place them under the helm-values folder and it only has to contain the files names without the absolut path prefix. the  *Note: Since there are 4 different upgrade in the script (EEA SW, MXE SW, EEA CONF, MXE CONF) there are 4 corresponding flag for each values folder (--path-to-eea-software-upgrade-files, --path-to-mxe-software-upgrade-files, --path-to-eea-configuration-upgrade-files, --path-to-mxe-configuration-upgrade-files). Passing the corresponding `--path-to-*-upgrade-files` and `--values-files-list` values are mandatory when running commands that uses them.*
   Example:

```
./upgrade.sh --eea-software-upgrade \
             --docker-registry-url eric-lcm-container-registry-registry.$REGISTRY_NS.svc.cluster.local \
             --kubectl-path /usr/local/bin/kubectl \
             --helm-path /usr/local/bin/helm \
             --path-to-eea-software-upgrade-files ./helm-values-eea \
             --path-to-sep-upgrade-values-files ./helm-values-sep \
             --values-files-list values-files-list-eea.txt
```

```
./upgrade.sh --mxe-software-upgrade \
             --docker-registry-url eric-lcm-container-registry-registry.$REGISTRY_NS.svc.cluster.local \
             --kubectl-path /usr/local/bin/kubectl \
             --helm-path /usr/local/bin/helm \
             --path-to-mxe-software-upgrade-files ./helm-values-mxe \
             --path-to-sep-upgrade-values-files ./helm-values-sep \
             --values-files-list values-files-list-mxe.txt
```

1. Before you start the upgrade process you can validate the values-files and the values-files-list.txt with the following command:

```
./upgrade.sh --validate-custom-config-files \
--path-to-eea-software-upgrade-files ./helm-values-eea \
--values-files-list values-files-list-eea.txt
```

## 'One click' upgrade

The script is able to execute a 'One click' upgrade with the usage of the --full-upgrade flag. If this flag is added the script will execute all 4 different upgrade (EEA SW, EEA CONFIG, MXE SW, MXE CONF) one by one. In this case you you have to specify all 4 values folder with the corresponding flags (--path-to-eea-software-upgrade-files, --path-to-mxe-software-upgrade-files, --path-to-eea-configuration-upgrade-files, --path-to-mxe-configuration-upgrade-files) in this case all **values-files-list.txt** files have to be named the same way,after you can specify it with the **--values-files-list** flag.

Example:

```
./upgrade.sh --full-upgrade \
--docker-registry-url eric-lcm-container-registry-registry.$REGISTRY_NS.svc.cluster.local \
--kubectl-path /usr/local/bin/kubectl \
--helm-path /usr/local/bin/helm \
--path-to-custom-values-files ./helm-values-sep \
--path-to-eea-software-upgrade-files ./helm-values-eea-sw \
--path-to-mxe-software-upgrade-files ./helm-values-mxe-sw \
--path-to-eea-configuration-upgrade-files ./helm-values-eea-conf \
--path-to-mxe-configuration-upgrade-files ./helm-values-mxe-conf \
--path-to-sep-upgrade-values-files ./helm-values-sep \
--values-files-list values-files-list.txt
```

At finish:

- Values files was copied to the master node in the workspace directory.
- 1-1 folder created for both eea and mxe upgrades
- A values files list is created for both folders (if the names of the files are the same, 1 values list file can be used for both operation)

## Upgrade script steps

```
./upgrade.sh --steps "load_utils_image_into_registry"
```

```
./upgrade.sh --steps "load_application_images_into_registry" \
  --docker-path /usr/bin/docker \
  --docker-registry-url eric-lcm-container-registry-registry.$REGISTRY_NS.svc.cluster.local
```

```
./upgrade.sh --steps "collect_and_validate_custom_config_files" \
--path-to-custom-values-files ./helm-values-eea \
--values-files-list values-files-list-eea.txt
```

```
./upgrade.sh --steps "upgrade_crds" \
--kubectl-path /usr/local/bin/kubectl \
--helm-path /usr/local/bin/helm \
--docker-registry-url eric-lcm-container-registry-registry.$REGISTRY_NS.svc.cluster.local \
--image-pullsecret-name registry-secret \
--crd-namespace eric-crd-ns
```

```
./upgrade.sh --steps "upgrade_sep" \
--sep-helm-releasename eric-cs-storage-encryption-provider \
--path-to-custom-values-files $PWD/custom_config \
--sep-values-file helm-values/sep_values.yaml \
--environment-values-file helm-values/custom_environment_values.yaml
```

```
./upgrade.sh --steps upgrade_tls_proxies \
--tls-proxy-upgrade-bootstrap-file regional1-tlsproxy-boot.values.yaml \
--tls-proxy-upgrade-broker-files regional1-tlsproxy-b0.values.yaml,regional1-tlsproxy-b1.values.yaml,regional1-tlsproxy-b2.values.yaml \
--path-to-custom-values-files $PWD/custom_config
```

```
./upgrade.sh --steps patch_kafka_for_tls_proxy \
--tls-proxy-kafka-statefulset-patch-file patch-statefulset-eric-data-message-bus-kf.yaml \
--tls-proxy-kafka-service-patch-file patch-service-eric-data-message-bus-kf-client.yaml \
--tls-proxy-base-name-override eric-eea-regional1-tlsproxy \
--path-to-custom-values-files $PWD/custom_config
```

```
./upgrade.sh --eea-software-upgrade \
--docker-registry-url eric-lcm-container-registry-registry.$REGISTRY_NS.svc.cluster.local \
--kubectl-path /usr/local/bin/kubectl \
--helm-path /usr/local/bin/helm \
--path-to-eea-software-upgrade-files ./helm-values-eea \
--path-to-sep-upgrade-values-files ./helm-values-sep \
--values-files-list values-files-list-eea.txt
```

```
./upgrade.sh --mxe-software-upgrade  \
--docker-registry-url eric-lcm-container-registry-registry.$REGISTRY_NS.svc.cluster.local \
--kubectl-path /usr/local/bin/kubectl \
--helm-path /usr/local/bin/helm \
--path-to-mxe-software-upgrade-files ./helm-values-mxe \
--values-files-list values-files-list-mxe.txt
```

```
./upgrade.sh --eea-configuration-upgrade  \
--docker-registry-url eric-lcm-container-registry-registry.$REGISTRY_NS.svc.cluster.local \
--kubectl-path /usr/local/bin/kubectl \
--helm-path /usr/local/bin/helm \
--path-to-eea-configuration-upgrade-files ./helm-values-eea \
--values-files-list values-files-list-eea.txt
```

```
./upgrade.sh --mxe-configuration-upgrade  \
--docker-registry-url eric-lcm-container-registry-registry.$REGISTRY_NS.svc.cluster.local \
--kubectl-path /usr/local/bin/kubectl \
--helm-path /usr/local/bin/helm \
--path-to-mxe-configuration-upgrade-files ./helm-values-mxe \
--values-files-list values-files-list-mxe.txt
```

*Note:*
*- we should stay in the workspace directory, where CSAR was unpacked*
*- kube config file path is configurable, it is $HOME/.kube/config by default*
*- location of the csar pacakage can be defined with the --path-to-csar-package flag*

[1]: https://adp.ericsson.se/marketplace/container-registry/documentation/7.8.0/dpi/service-user-guide
[2]: https://arm.seli.gic.ericsson.se/artifactory/proj-eea-internal-generic-local/
[3]: https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-cleanup/build?delay=0sec
[4]: https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-product-baseline-install/build?delay=0sec
