# Cluster deploy Spotfire platform

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Purpose

This job is intended to deploy K8S Spotfire platform on Product CI clusters, deploy static content to Spotfire and remove the Spotfire platform from clusters

## Jenkins jobs

+ Job name: [spotfire-asset-install-assign-label-wrapper](https://seliius27190.seli.gic.ericsson.se:8443/job/spotfire-asset-install-assign-label-wrapper/)
+ Job name: [spotfire-asset-install](https://seliius27190.seli.gic.ericsson.se:8443/job/spotfire-asset-install)

***Note*** spotfire-asset-install-assign-label-wrapper job has the same input parameters as spotfire-asset-install main pipeline. The main purpose of wrapper is to assign a special label for Jenkins build node to ensure leveraging only one build at the moment per build node. Wrapper has been created to prevent Gerrit problems on Jenkins master node during execution

## Parameters

+ `DRY_RUN` - This parameter is used to build the job (without running its full logic) in case of change in parameters
+ `AGANT_LABEL` - A special Jenkins agent's label that's assigned by [spotfire-asset-install-assign-label-wrapper](https://seliius27190.seli.gic.ericsson.se:8443/job/spotfire-asset-install-assign-label-wrapper/) job to ensure one build per Jenkins agent at the time
+ `CLUSTER_NAME` - cluster name to deploy spotfire platform on
+ `EEA4_NS_NAME` - K8S namespace where is EEA4 is deployed. By default, it's eric-eea-ns namespace
+ `OAM_POOL` - IP pool name where eric-ts-platform-haproxy service will get LoadBalancer IP. A default value is pool0
+ `SF_ASSET_VERSION` - Spotfire asset version refers to a directory on Jenkins agent node, where package is extracted to. By default, value is taken from [spotfire_platform.yml](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/spotfire_platform.yml) file in cnint repository. A different version can be given manually. All actual versions are published on [Current stable version sheet](https://eteamspace.internal.ericsson.com/pages/viewpage.action?spaceKey=ECISE&title=Current+stable+version+sheet) page
+ `STATIC_CONTENT_PKG` - Static content package version is taken automatically from [spotfire_platform.yml](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/spotfire_platform.yml) file in cnint repository. A different version can be given manually. All actual versions are published on [Current stable version sheet](https://eteamspace.internal.ericsson.com/pages/viewpage.action?spaceKey=ECISE&title=Current+stable+version+sheet) page
+ `CNINT_GERRIT_REFSPEC` - Gerrit refspec of the integration git repository, e.g.: refs/changes/87/4641487/1. It's empty by default
+ `ADP_APP_STAGING_GERRIT_REFSPEC` - Gerrit refspec of the adp-app-staging git repository, e.g.: refs/changes/45/45612345/1
+ `INSTALL_SPOTFIRE_PLATFORM` - boolean parameter. It has true value by default, and it's intended for Spotfire platform installation on chosen cluster. This step includes removing and deployment of static content to spotfire
+ `CLEANUP_SPOTFIRE` - boolean parameter. It has false value by default. This step removes spotfire platform from cluster without further installation. Cannot be used with `INSTALL_SPOTFIRE_PLATFORM` or `DEPLOY_STATIC_CONTENT` parameters at the same time
+ `DEPLOY_STATIC_CONTENT` - boolean parameter. It has false value by default. Installs a specified static content (SC) version. Can be used many times to upgrade existing SC version to a new one. Cannot be used with `INSTALL_SPOTFIRE_PLATFORM` or `CLEANUP_SPOTFIRE_PLATFORM` parameters simultaneously
+ `SETUP_TLS_AND_SSO` - boolean parameter. Set Up TLS connection between Spotfire and OLAP (Vertica) Database. Cannot be used with `INSTALL_SPOTFIRE_PLATFORM` or `CLEANUP_SPOTFIRE_PLATFORM` parameters simultaneously
+ `ENABLE_CAPACITY_REPORTER` - boolean parameter. Configure and enable capacity reporter. It's used together with SETUP_TLS_AND_SSO input parameter. Cannot be used with `INSTALL_SPOTFIRE_PLATFORM` or `CLEANUP_SPOTFIRE_PLATFORM` parameters simultaneously
+ `PREVIOUS_JOB_BUILD_ID` - Value is required if ENABLE_CAPACITY_REPORTER checkbox is selected. Value should be the build ID of the previous job, where the Spotfire platform was installed on the selected cluster. For example, 234
+ `ENABLE_OPTIONAL_FEATURES` - Required for development teams, but not for ProdCI executions. For details see the job parameter description.

## Stages

1. Cluster parameters check

   + `CLUSTER_NAME` must be specified
   + `INSTALL_SPOTFIRE_PLATFORM` and `CLEANUP_SPOTFIRE` cannot be chosen simultaneously as the deployment spotfire platform step contains cleanup one
   + `INSTALL_SPOTFIRE_PLATFORM` and `SETUP_TLS_AND_SSO` cannot be selected at the same time. As TLS connection should be configured when Spotfire platform is already installed
   + `CLEANUP_SPOTFIRE_PLATFORM` and `DEPLOY_STATIC_CONTENT` cannot be chosen at the same time
   + If `ENABLE_CAPACITY_REPORTER` was selected, the `PREVIOUS_JOB_BUILD_ID` input parameter should contain build ID of the previous Spotfire install build

2. Check if cluster is locked or reserved

   + This stage checks if cluster's lockable resource is locked properly if current build is called by upstream job. In case of manual start the appropriate lockable resource has to be reserved to avoid collisions with other installation pipelines

   ***Note*** This validation is only applicable for Product CI clusters (aka kubeconfig-seliics0...)

3. Checkout repos

   + inv_test repository checkout only from the master branch
   + cnint repository checkout from the master branch or from the refspec if `CNINT_GERRIT_REFSPEC` input parameter is given
   + adp-app-staging repository checkout from the master branch or from the refspec if `ADP_APP_STAGING_GERRIT_REFSPEC` input parameter is given

4. Jenkins Desc.

   + Set up current Jenkins build description

5. Prepare extra vars input file

   + Extracts essential versions from the [spotfire_platform.yml](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/spotfire_platform.yml) file, aka Spotfire platform version, Spotfire static content package version etc.
   + Prepares additional ansible variables
   + Writes ${CLUSTER_NAME}_extra_vars.yml file into build's workspace

6. Prepare WORK DIR

   + Copies all yaml and txt files from the previous Spotfire install build in current workspace

7. Spotfire Platform Cleanup

   + This stage deletes Spotfire platform from cluster without further installation, and it is run when the `CLEANUP_SPOTFIRE_PLATFORM` parameter is specified
   + It calls `sf-00-uninstall.yml` ansible playbook

8. Spotfire Platform Install

   + Installs Spotfire BI Visualization Platform in spotfire-platform namespace
   + Installs PostgreSQL DB & Vertica DB Data Source Templates
   + Imports the selected EEA4 Dashboard Data Source ZIP file
   + Trusts custom scripts and allow Ericsson brand styling
   + Deploys and start Web player and Python services
   + This step calls `sf-01-install-spotfire-asset.yml` ansible playbook from ${WORKSPACE}/adp-app-staging/ansible/spotfire_asset_install directory

9. Deploy Static content

   + This stage is run when the `DEPLOY_STATIC_CONTENT` parameter is checked
   + It calls the `sf-03-install_static_content.yml` ansible playbook from ${WORKSPACE}/adp-app-staging/ansible/spotfire_asset_install folder

10. Connect to EEA4 (Vertica + IAM)

    + Sets Up TLS Connection Between Spotfire and OLAP (Vertica) Database
    + Configures IAM in EEA namespace for Spotfire and create new Spotfire users in IAM
    + Enables IAM Authentication in Spotfire config
    + Calls the `sf-02-connect_to_eea.yml` ansible playbook from ${WORKSPACE}/adp-app-staging/ansible/spotfire_asset_install folder

11. Enable Capacity reporter

    + Configures and enable capacity reporter
    + Calls the `sf-04-enable-capacity-reporter.yml` ansible playbook from ${WORKSPACE}/adp-app-staging/ansible/spotfire_asset_install directory

12. Post actions

    + Send email to build user
    + Calls downstream [cleanup-jenkins-agent-label](https://seliius27190.seli.gic.ericsson.se:8443/job/cleanup-jenkins-agent-label/) job to remove previously assigned label from the Jenkins agent node
