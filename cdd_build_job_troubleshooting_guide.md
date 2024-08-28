# CDD package build job troubleshooting guide

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## WARNING

DEPRECATED: From EEA 4.9 we are using the EEA Deployer!!!

## Introduction

This document is intended to collect all the information for troubleshooting the cdd package build failures

## Description of the problem

The eea-cdd-build-cdd-package job is failed and [eric-eea-ci-meta-helm-chart](https://gerrit.ericsson.se/plugins/gitiles/EEA/project-meta-baseline/+/master/eric-eea-ci-meta-helm-chart/)  has not been updated, which can cause a mismatch between the current product version of the [eric-eea-int-helm-chart in cnint](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/eric-eea-int-helm-chart/) and the PRODUCT_VERSION in the [upgrade.sh or deploy.sh](https://gerrit.ericsson.se/plugins/gitiles/EEA/cdd/+/master/product/source/pipeline_package/swdp-cdd/product/scripts/)

After troubleshooting why the eea-cdd-build-cdd-package job failed and fixing it do the following steps.

### Remedy

1. Fix the issue which caused the failure
2. Re-execute the eea-cdd-build-cdd-package job
3. Check if
   1. it is successful now
   2. it triggers the metabaseline loop
   3. the new version from the cdd package has been uploaded to the arm
   4. the new cdd package version is updated in the metabaseline helm chart

## How to verify that the weekly version uplift was successful

Check the followings:

1. The [eea-product-release-time-based-new-version](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-release-time-based-new-version/) job created the commits for each repository with the proper version and each commit is merged.
2. The PRODUCT_VERSION in [upgrade.sh or deploy.sh](https://gerrit.ericsson.se/plugins/gitiles/EEA/cdd/+/master/product/source/pipeline_package/swdp-cdd/product/scripts/) has been updated and in sync with the version of the [eric-eea-int-helm-chart in cnint](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/eric-eea-int-helm-chart/)
3. new swdp-cdd or eea-deployer package has been build after that the PRODUCT_VERSION has been updated in the deployer script and uploaded to the [arm repo](https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-generic-local/)
4. The version of the [eric-eea-cdd helm chart](https://gerrit.ericsson.se/plugins/gitiles/EEA/cdd/+/master/helm/eric-eea-cdd) has been updated in the [eric-eea-ci-meta-helm-chart](https://gerrit.ericsson.se/plugins/gitiles/EEA/project-meta-baseline/+/master/eric-eea-ci-meta-helm-chart/) and it is the same as the swdp-cdd or eea-deployer package has.
