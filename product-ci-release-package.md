# Creating a release package

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Steps required to release a package

* For each version of the EEA helm chart, the following files are created in the [drop repository](https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/eric-eea-int-helm-chart/):
  * eric-eea-int-helm-chart-**some-version**.tgz
  * eric-eea-int-helm-chart-**some-version**.tgz.md5
  * eric-eea-int-helm-chart-**some-version**.tgz.sha1
  * eric-eea-int-helm-chart-**some-version**.tgz.sha256

    **A remark:**
  * For a particular version of the EEA helm chart .tgz and .tgz.sha256 are mandatory to be downloaded. Other files are optional.

* Do the checksum validation. (Examples below)

* Double check release content.
  * The [**check\_release\_content.sh**](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/technicals/shellscripts/check_release_content.sh) creates a .csv for double checking the release content.
  * All the necessary information about how the script works can been seen by passing **--help** or **-h** parameter to the script.

## Examples

sha256 checksum

```
echo "$(cat eric-eea-int-helm-chart-some-version.tgz.sha256) eric-eea-int-helm-chart-some-version.tgz" | sha256sum -c
```

Expected result:

```
eric-eea-int-helm-chart-some-version.tgz: OK
```

Optional check: sha1 checksum

```
echo "$(cat eric-eea-int-helm-chart-some-version.tgz.sha1) eric-eea-int-helm-chart-some-version.tgz" | sha1sum -c
```

Expected result:

```
eric-eea-int-helm-chart-some-version.tgz: OK
```

Optional check: md5 checksum

```
echo "$(cat eric-eea-int-helm-chart-some-version.tgz.md5) eric-eea-int-helm-chart-some-version.tgz" | md5sum -c
```

Expected result:

```
eric-eea-int-helm-chart-some-version.tgz: OK
```

## Steps to manually create CSAR package

According to the [**How to create CSAR package**](https://confluence.lmera.ericsson.se/pages/viewpage.action?spaceKey=ACD&title=How+to+create+CSAR+package) the steps are the following:

### Prerequisite

* machine with big disk capacity (at least double compared to the image size sum in your integration chart)
* docker
* access to armdocker.rnd.ericsson.se

### Preparation

* Create working directory

```
mkdir -p csar-workdir/charts
mkdir -p csar-workdir/scripts
chmod -R 777 csar-workdir
cd csar-workdir
```

* Download the eric-eea-int-helm-chart-\<version\> into the charts folder

```
curl -u $USER https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm-local/eric-eea-int-helm-chart/eric-eea-int-helm-chart-<version>.tgz -o charts/eric-eea-int-helm-chart-<version>.tgz
```

* Extract the helm charts of the CRDs from the eea `eric-eea-int-helm-chart-<version>.tgz` into the charts folder

```
for crdhelm in $(tar tf  eric-eea-int-helm-chart-<version>.tgz | grep -E 'crd.*tgz'); do tar xf eric-eea-int-helm-chart-<version>.tgz $crdhelm --strip-components 4; done

```

* Download the latest version of [**tag_puch_images.sh**](https://gerrit.ericsson.se/#/c/8181361/1/tools/tag_push_images.sh) or an improved version of this script and [**install-crds.sh**](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/scripts/install-crds.sh) and any other scripts provided by the MicroService tribes into the scripts folder.

* Pull latest released version eric-am-package-manager (see repo for version)

```
docker pull armdocker.rnd.ericsson.se/proj-am/releases/eric-am-package-manager:<version>
```

* Download the latest run_package_manager.sh [**Gerrit**](https://gerrit.ericsson.se/plugins/gitiles/OSS/com.ericsson.orchestration.mgmt.packaging/am-package-manager/+/refs/heads/master/src/scripts/run_package_manager.sh)

* Check if the script refers to the same version of eric-am-package-manager that has been pulled. If necessary fix the version in the script in the following line:

```
image="armdocker.rnd.ericsson.se/proj-am/releases/eric-am-package-manager:2.0.40"
```

### Create CSAR package

```
./run_package_manager.sh <folder containing helm chart> <folder with docker login creds>  "--helm3 --helm-dir charts --script scripts --name <path for the csar package>/<csar package name provided by the Release team>"
```

Arguments:

```
* <folder containing helm chart(s)> the folder containing the helm chart(s) that will be used to generate the CSAR.
* <folder with docker login creds> the folder that contains the login to the docker registries, typically ‘~/.docker’.
* “<package-manager-arguments>” the package manager arguments to be passed to helm. Please Note: These arguments must be enclosed in inverted commas.
```

More details about the arguments: [**CSAR Packaging Tool**](https://gerrit.ericsson.se/plugins/gitiles/OSS/com.ericsson.orchestration.mgmt.packaging/am-package-manager/+/refs/heads/master/README.md)

### References

* [**How to create CSAR package**](https://confluence.lmera.ericsson.se/pages/viewpage.action?spaceKey=ACD&title=How+to+create+CSAR+package)
* [**Application Assembly Tools**](https://adp.ericsson.se/workinginadpframework/adp-enablers/application-assembly-tools)
* [**CSAR Packaging Tool**](https://gerrit.ericsson.se/plugins/gitiles/OSS/com.ericsson.orchestration.mgmt.packaging/am-package-manager/+/refs/heads/master/README.md)
