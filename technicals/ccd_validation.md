# Test new version of CCD pipeline

This pipeline tests a new version of CCD by reinstalling the cluster with the proper CCD version and running a series of tests.

## Procedure of CCD testing

When new official version of CCD is released and verified at RV, or new combination of Rook and Ceph is validated at RV we have to execute this pipeline to verify that the new SW combination is stable enough for Product CI pipelines. For this at least 5 installs and 5 upgrades has to be executed without any unknown issue. At the end of this test Rook and Ceph related metrics should be checked at Grafana dashboard to be sure that the new SW combination has not caused degradation in cluster resource usage.

## Introduction of new CCD version to Product CI

After successful validation of a new CCD version to following steps are needed to introduce usage of this new version to Product CI pipelines:

+ if new rook/ceph version is introduced we need to check the [ceph alarms documentation](https://docs.ceph.com/en/quincy/rados/operations/health-checks/) and compare with the [regexps](https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master/vars/validateRookCephStatus.groovy) used at ceph health status check to be sure that the logic which moved the cluster to faulty status in case of critical issue remains proper.
  + Changelog for ceph is available [here](https://docs.ceph.com/en/latest/releases/#active-releases) to check changing alarms
+ all Product CI clusters has to be reinstalled with the new CCD version (this can take long time as we can't block deliveries with moving out many clusters from the pool)
+ kubectl and helm version used in the newly introduced CCD version has to be compared with the versions used at Docker images used by Product CI
  + images to be checked:
    + k8-test: armdocker.rnd.ericsson.se/proj-adp-cicd-drop/bob-py3kubehelmbuilder (kubectl and helm, maintained by ADP)
    + adp-release-auto: armdocker.rnd.ericsson.se/proj-adp-cicd-drop/bob-adp-release-auto (helm only, maintained by ADP)
    + adp-helm-chart-auto: armdocker.rnd.ericsson.se/proj-adp-cicd-drop/adp-int-helm-chart-auto (helm only, maintained by ADP)
    + ci-toolbox: armdocker.rnd.ericsson.se/proj-eea-drop/ci-toolbox (kubectl and helm, maintained by EEA)
    + eea4-utils-ci: armdocker.rnd.ericsson.se/proj-eea-drop/eric-eea-utils-ci (kubectl and helm, maintained by EEA)
    + eea-jenkins-docker: armdocker.rnd.ericsson.se/proj-eea-drop/eea-jenkins-docker (kubectl and helm, maintained by EEA Product CI Team)
    + eea-prod-ci-helper (kubectl and helm, maintained by EEA Product CI Team)
    + Besides docker images, jenkins build nodes have to follow the CCD versions (helm- and kubernetes python package versions are tracked in ansible jenkins_slave role [versions.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/ansible/roles/jenkins_slave/vars/versions.yml)).
  + if the versions don't match EEA Product CI team has to prepare commit to uplift kubectl and helm versions in these images (in case of EEA owned images) or change used versions of these tools updating bob rulesets (in case of ADP owned images). For this [eea-prod-ci-kubectl-and-helm-version-uplift](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-prod-ci-kubectl-and-helm-version-uplift/) job can be used. See [Documentation](https://eteamspace.internal.ericsson.com/display/ECISE/Uplift+Kubectl+and+helm+versions+in+Product+CI+repos).
  + if ADP owned image doesn't support the needed helm or kubectl ADP team has to be contacted via MS Teams group.

## Parameters

+ `DRY_RUN`: If true, the pipeline will only run in dry run mode.
+ `CLUSTER_NAME`: The name of the cluster to use for the test.
+ `CCD_VERSION`: The version of CCD to test.
+ `NUM_RUN`: The number of times to run the test pipeline.
+ `SKIP_INSTALL`: Use for skip Install test pipeline.
+ `SKIP_UPGRADE`: Use for skip Upgrade test pipeline.
+ `OS_INSTALL_METHOD`: The method to use for installing the OS on the cluster.
+ `INT_CHART_VERSION`: Initializes the latest version of the eric-eea-int-helm-chart.
+ `GERRIT_REFSPEC`: The Gerrit refspec to use for checking refspec of EEA/cnint repo.

## Stages

1. `Params DryRun check`: Checks if the `DRY_RUN` parameter is set. If it is, the pipeline will run in dry run mode.
2. `Run when run in Jenkins master`: Checks if the pipeline is running in the Jenkins master. If it is, the pipeline will run in dry run mode.
3. `Checkout cnint`: Checks out the cnint repository.
4. `Init latest version of eric-eea-int-helm-chart`: Initializes the latest version of the eric-eea-int-helm-chart.
5. `Prepare`: Prepares the environment for the test.
6. `Check free cluster`: Checks if the specified cluster is free. If it is, the cluster is locked for the duration of the test.
7. `Run cluster reinstall job`: Reinstalls the cluster with the specified CCD version.
8. `Run test pipeline`: Runs a series of tests on the new CCD installation.

## Test Pipelines

Includes next series of test:

### Install test

Run eea-application-staging-batch pipeline for install product on cluster with a new version of CCD: [eea-application-staging-batch](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-batch/)

#### Parameters

    * `INT_CHART_NAME`: Initializes integration chart name.
    * `INT_CHART_REPO`: Initializes integration chart [repo](https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/)
    * `INT_CHART_VERSION`: Initializes the latest version of the eric-eea-int-helm-chart.
    * `GERRIT_REFSPEC`: The Gerrit refspec to use for checking refspec of EEA/cnint repo.
    * `CLUSTER_LABEL`: Set proper cluster label "ccd_validation".
    * `SPOTFIRE_VM_RESOURCE_NAME`: Set the vm resource name parsed from values.yaml 'CI_BASE_02'.
    * `SKIP_COLLECT_LOG`: Set `true`, It is necessary to avoid running log collector job as it will change the label and the cluster with the installed version of CCD will be lost.
    * `SKIP_CLEANUP`: Set `true`, It is necessary to avoid running log clean up as it will change the label and the cluster with the installed version of CCD will be lost.

### Log collection after install

After Install runs Log Collector job which include cleanup: [cluster-logcollector](https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-logcollector/)

#### Parameters

    * `CLUSTER_NAME`: Set cluster with proper version of CCD.
    * `AFTER_CLEANUP_DESIRED_CLUSTER_LABEL`: Set proper cluster label "ccd_validation" after clean up.

### Baseline install

Next step run [eea-application-staging-product-baseline-install](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-product-baseline-install/)

#### Parameters

    * `CLUSTER_LABEL`: Set proper cluster label "ccd_validation".
    * `CUSTOM_CLUSTER_LABEL`: Set proper cluster label "ccd_validation" after running pipeline.
    * `SKIP_COLLECT_LOG`: Set `true`, It is necessary to avoid running log collector job as it will change the label and the cluster with the installed version of CCD will be lost.

### Upgrade test

After run [eea-common-product-upgrade](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-common-product-upgrade/)

#### Parameters

    * `INT_CHART_NAME_PRODUCT`: Initializes integration chart name.
    * `INT_CHART_REPO_PRODUCT`: Initializes integration chart [repo](https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/)
    * `INT_CHART_VERSION_PRODUCT`: Initializes the latest version of the eric-eea-int-helm-chart.
    * `GERRIT_REFSPEC`: The Gerrit refspec to use for checking refspec of EEA/cnint repo.
    * `SKIP_COLLECT_LOG`: Set `true`, It is necessary to avoid running log collector job as it will change the label and the cluster with the installed version of CCD will be lost.
    * `SKIP_CLEANUP`: Set `true`, It is necessary to avoid running log clean up as it will change the label and the cluster with the installed version of CCD will be lost.
    * `CUSTOM_CLUSTER_LABEL`: Set proper cluster label "ccd_validation" after running pipeline.
    * `UPGRADE_CLUSTER_LABEL`: Set proper cluster label "ccd_validation" during running pipeline.

### Log collection after upgrade

Final, runs Log Collector job which include cleanup: [cluster-logcollector](https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-logcollector/)

#### Parameters

    * `CLUSTER_NAME`: Set cluster with proper version of CCD.
    * `AFTER_CLEANUP_DESIRED_CLUSTER_LABEL`: Set proper cluster label "ccd_validation" after clean up.

## Notifications

When the pipeline finish, a notification will be sent to the appropriate Teams channels.

## Finale Clean Up

After tests runs Log Collector job to clean up the cluster and tag it `bob-ci` : [cluster-logcollector](https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-logcollector/)
