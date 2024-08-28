# CSAR based install

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Description

This job is responsible for testing EEA installation from CSAR package.
A CSAR package need to be built beforehand. The output of the CSAR build pipeline can be used as an input for the CSAR based install pipeline.
The jenkins job needs to be run on a separate jenkins slave as it cannot run parallel with the [csar-build](https://seliius27190.seli.gic.ericsson.se:8443/job/csar-build/) and the [docker-cleanup](https://seliius27190.seli.gic.ericsson.se:8443/job/docker-cleanup/) Jenkins jobs.
This job contains the same test scope as the batching loop.

+ Link for the [study](https://eth-wiki.rnd.ki.sw.ericsson.se/pages/viewpage.action?spaceKey=ECISE&title=EEAEPP-55915+Install+from+CSAR+package+in+Product+CI())
+ Link for the [ruleset file](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/bob-rulesets/csar_install.yaml)
+ Link for the [Jenkins job](https://seliius27190.seli.gic.ericsson.se:8443/job/csar-install/)

## Stages

+ Params DryRun check
+ Gerrit message
+ Checkout
+ Ruleset and eric-eea-int-helm-chart-ci change checkout
+ Prepare
+ Checkout adp-app-staging
+ Checkout offline_deploy_values.yaml
  + Get the [offline_deploy_values.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/eea4-rv/+blame/master/jenkins/custom-files/rv_custom_values/offline_deploy_values.yaml)
+ Get latest CSAR_VERSION
  + If the CSAR_VERSION parameter contains the 'latest' value, the latest version will be used from the [proj-eea-drop-generic-local](https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-generic-local/) ARM repo.
+ Init
+ Resource locking - utf deploy and K8S Install
  + Wait for cluster
  + Lock
    + log lock
    + Download CSAR package
      + The CSAR package which created by the CSAR build pipeline and downloaded from to the proj-eea-drop-generic-local arm repository, needs to be copied into the ${csar-workdir} folder
    + init vars
    + Extract tag push images
      + The CSAR package extraction and the docker load, tag and push command will be done directly on the jenkins slave as there is no benefit to use an intermediate docker container to execute these commands.
    + CRD Install
      + The CRDs will be installed using the install-crds.sh from the CSAR package
    + utf and data loader deploy-deploy
    + Wait spotfire resource
      + spotfire-restore
      + Initialize spotfire attributes
      + Wait for Spotfire
      + SEP Install
      + Install helper chart
        + The helperchart (eric-eea-int-helm-chart-ci) which had been installed with the eric-eea-int-helm-chart as a dependency chart will be separately installed not to limit the possibilities of this chart to install any images in the future which won't be packed in the CSAR package with the product.
      + K8s CSAR Based Install Test
        + During the installation the local-pullsecret will be used instead of the arm-pullsecret. The namespace cleanup before the install will be skipped as it will be done during the helperchart installation.
      + Load config cubes json to CM-Analytics
      + init UTF Test Variables
      + Execute Start Data loading
      + Execute Cucumber UTF Tests
      + Execute Stop  Data loading
+ post action
  + logcollector & cleanup
    + [cluster-cleanup]](<https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-cleanup/>) job will also execute the local registry cleanup if the local registry is not empty
