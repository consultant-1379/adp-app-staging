# CSAR build

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## The CSAR build job

### Purpose

The csar-build pipeline's purpose is to create a CSAR build for every successfully tested integration helm chart version. The CSAR package itself is a tar file which contains all microservices, with a .csar extension. The scripts folder from the cnint repository is copied into the package, and also an optionally specified custom folder.
The job doesn't use any kubernetes clusters.

### Mechanism

The CSAR Spinnaker stage runs parallel with the Staging Batch stage in the eea-application-staging pipeline. This reduces pipeline length because the two stages don't depend on each other. In this stage, the csar-build job uploads the newly created package into the proj-eea-internal-generic-local artifactory repository. For this, the naming contains the new integration helm chart version, together with a hash, which is supplied by the Spinnaker pipeline.
When both CSAR and Staging Batch stages finish, the PublishBaseline stage will download this package, and re-upload it to the proj-eea-drop-generic-local repository, but now without the hash part.

If, for some reason, the Staging Batch fails, then the package won't be published to the drop repository (because the PublishBaseline stage wouldn't run). The integration helm chart version would not be increased. In this case, the next eea-application-staging pipeline will use the same integration helm chart version, but with a different hash, so a new CSAR package will be created and uploaded to the proj-eea-internal-generic-local repository, so including the hash ensures there will be no naming conflict in the artifactory.

For cases when the CSAR build must be restarted, and the csar-build would use the same hash, to avoid naming conflicts in artifactory (as there can be a previously uploaded package with the same name) a new stage was introduced. It's name is 'csar-check'. This checks the artifactory for previously uploaded package with the same name, and if it exists, it deletes it. This ensures naming conflicts are avoided in the 'csar-build' stage.

#### Issues with docker images

CSAR build works by packaging all microservice docker images into a file, and for this it needs to have all images pulled locally. But because the packaging can take a longer time, to ensure the images aren't removed during packaging (especially by the docker-cleanup job), the 'csar-build' and 'docker-cleanup' jobs are configured into a so called Concurrent Throttle Group. The group name in Jenkins is 'docker'. This effectively means docker-cleanup and csar-build can't run at the same time, and the job that was scheduled later in Jenkins will have to wait until the first finishes. Any mechanism that can possibly remove docker images must be put into the same Concurrent Throttle Group.

### Enabled/Disabled services support

The packaging script uses a helm chart to determine the services to include in the package, but the product requirements are that all services need to be included, not just those that are enabled in the integration helm chart.
The sidecar images could be on different level of the values.yaml file, that's why the simplest way to replace all the `enabled: false` with `enabled: true` in the extracted values.yaml.

To exclude something from the CSAR packages, a service needs to be registered in the csar_exception_list file in the cnint repository.
The csar-build job removes the services from the Chart.yaml which are in the csar_exception_list file and re-package the helm chart without them before the CSAR package build.

The additional_csar_values.yaml file in cnint repo is used to add any additional parameter which are needed for the csar build.
(E.g. something has been enabled in the values.yaml, but it brakes the csar build that's why it needs to disabled, then it should be done in this file as well.)
These three yaml files are supplied to the package creation script with the --values switch in a defined order(`--values values.yaml,additional_csar_values.yaml`).

### Csar package blacklist config

To exclude some file/directory from the csar package, the file/directory must be added to the `csar_blacklist` config in the EEA/cnint repository

Since the `cp` command does not support the `--exclude` or `--exclude-from` options, we must use `rsync` to copy files/directories, which will use `csar_blacklist`. Eg:

    rsync -av --exclude-from=${WORKSPACE}/cnint/csar_blacklist <source> <destination>

### Contents of the Scripts folder

The content of the Scripts folder in CSAR stands from the following:

* cnint/csar_exception_list
* content of cnint/csar-scripts folder
* eea4-utils image from the arm repo of the docker images
* MIB files from eric-fh-snmp-alarm-provider repo

#### MIB files from eric-fh-snmp-alarm-provider repo

The eric-fh-snmp-alarm-provider is part of the EEA4 product, and that ADP Generic Service version is stored in eric-eea-int-helm-chart/Chart.yaml.
During the csar-build we get eric-fh-snmp-alarm-provider version from eric-eea-int-helm-chart/Chart.yaml and checkout that version from [eric-fh-snmp-alarm-provider repo](https://gerrit.ericsson.se/#/admin/projects/pc/adp-gs-alarm-snmp-nbi) and copy src/api/ERICSSON-ALARM-MIB/*.mib files

All of the above contents are going to be copied to the csarworkdir/scripts folder and be placed in the Scripts folder of CSAR package.

### Contents of the Scripts/configurations/sep folder

The content of this folder in CSAR stands from the following:

* cnint/helm-values/sep_values.yaml

### Contents of the Scripts/cma folder

The content of this folder in CSAR stands from the following:

* cnint/helm-values/disable-cma-values.yaml

### CSAR package validation

After the CSAR build there is a validation step, which validates the built CSAR package, looking for the files, CRDs and images which are required for the CSAR package
