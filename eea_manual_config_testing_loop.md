# Information about eea-manual-config-testing loop in Product CI

## Trigger job: [eea-config-testing-trigger](https://seliius27190.seli.gic.ericsson.se:8443/view/Manual%20config%20testing/job/eea-config-testing-trigger)

This job checks if the executor user is a member of [eea-manual-config-testing-executors](https://gerrit.ericsson.se/#/admin/groups/37754,members) gerrit group

* If not, then fails with `Not authorized executor` error message in Jenkins console log
* Succeeds if yes:
  * Store the parameters in artifact.properties
  * triggers the [eea-manual-config-testing](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?q=manual&pipeline=eea-manual-config-testing) Spinnaker pipeline

### Input parameters

* CHART_NAME: Name of the microservice helm chart (Mandatory if GERRIT_REFSPEC is not defined)
* CHART_REPO: Repository path of the microservice helm chart (Mandatory if GERRIT_REFSPEC is not defined)
* CHART_VERSION: Version of the microservice helm chart (Mandatory if GERRIT_REFSPEC is not defined)
* GERRIT_REFSPEC: Refspec of the commit in cnint repo in "refs/changes/87/4641487/1" format (Mandatory if CHART_NAME, CHART_REPO, CHART_VERSION are not defined)
* META_GERRIT_REFSPEC: Gerrit Refspec of the Meta chart git repo e.g.: refs/changes/87/4641487/1 (Optional parameter. If specified, the Meta helm chart will be prepared during the PrepareBaseline stage)
* SKIP_TESTING_INSTALL: true or false. Default: false Skip install test execution
* SKIP_TESTING_UPGRADE: true or false. Default: true Skip upgrade test execution
* CLUSTER_NAME: Cluster resource name to execute install on
* UPGRADE_CLUSTER_NAME: Cluster resource name to execute upgrade on
* HELM_AND_CMA_VALIDATION_MODE - Use HELM values or HELM values and CMA configurations. valid options: ""  legacy mode, "true"  use helm values, cma is diabled, "false" use helm values and load CMA configurations
* BUILD_RESULT_WHEN_CMA_HEALTH_CHECK_FAILED build result when the CMA health check failed
* CUSTOM_CLUSTER_LABEL : Cluster label in case skiping install or upgrade cleanup
* SKIP_INSTALL_CLEANUP : true or false. Default: false Skip install cleanup
* SKIP_UPGRADE_CLEANUP : true or false. Default: false Skip upgrade cleanup

### Steps

* Params DryRun check
* Check params for cluster cleanup

  > The `CUSTOM_CLUSTER_LABEL` is mandatory, if the `SKIP_INSTALL_CLEANUP` is true or the `SKIP_UPGRADE_CLEANUP` is true.

* Verify executor user

  > The user who triggered the build must be a member of the `eea-manual-config-testing-executors` Gerrit group. Otherwise, the build will fail.

* Decide on cluster cleanup

  > The parameters `SKIP_INSTALL_CLEANUP` and `SKIP_UPGRADE_CLEANUP` will be used as the decision for skipping cleanup. Also, if `CLUSTER_NAME`/`UPGRADE_CLUSTER_NAME` parameters are not specified, clusters from the ProductCI pool with the `bob-ci`/`bob-ci-upgrade-ready` labels will be used. If the parameters are specified, the cleanup will be determined whether the cluster is in the ProductCI cluster pool or not. If not, automatic cleanup will be skipped for the specified cluster.

* Archive artifact.properties
* Post
  * cleanWs()

## [eea-manual-config-testing](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?q=manual&pipeline=eea-manual-config-testing) Spinnaker pipeline

### Stages:

* [PrepareBaseline](https://seliius27190.seli.gic.ericsson.se:8443/view/Manual%20config%20testing/job/eea-config-testing-baseline-prepare/) job
Updates the baseline EEA integration helm chart according to the given CHART_NAME, CHART_REPO, CHART_VERSION or GERRIT_REFSPEC parameters. If META_GERRIT_REFSPEC parameter was specified in the [eea-config-testing-trigger](#trigger-job-eea-config-testing-trigger), the Meta helm chart will be prepared as well
* [Config Testing Nx1 Install](https://seliius27190.seli.gic.ericsson.se:8443/view/Manual%20config%20testing/job/eea-config-testing-nx1/) install test of the updated EEA integration helm chart from PrepareBaseline stage
  * This pipeline also calls the [spotfire-asset-install](https://seliius27190.seli.gic.ericsson.se:8443/job/spotfire-asset-install) job two times
    1. To deploy K8S Spotfire platform on Product CI cluster with below input parameters
       * INSTALL_SPOTFIRE_PLATFORM: Boolean input parameter that must be checked to install Spotfire BI Visualization Platform in spotfire-platform namespace
       * DEPLOY_STATIC_CONTENT: Boolean input parameter that must be checked to install or re-install the specified static content (SC) version
       * AGENT_LABEL: Jenkins agent with the label will be used for the build
       * CLUSTER_NAME: Cluster resource name to execute Spotfire platform install on
       * EEA4_NS_NAME: Namespace where EEA4 will be/is deployed
       * OAM_POOL: IP Pool name where eric-ts-platform-haproxy service will get LoadBalancer IP from
       * SF_ASSET_VERSION: Spotfire asset version
       * STATIC_CONTENT_PKG: Static content package version
    2. To link Spotfire platform with EEA
       * SETUP_TLS_AND_SSO: To set Up TLS Connection Between Spotfire and OLAP (Vertica) Database
       * ENABLE_CAPACITY_REPORTER: To configure and enable capacity reporter
       * AGENT_LABEL: Jenkins agent with the label will be used for the build
       * CLUSTER_NAME: Cluster resource name to execute Spotfire platform install on
       * PREVIOUS_JOB_BUILD_ID: Build ID of the previous job where the Spotfire platform was installed on the selected cluster
       * EEA4_NS_NAME: Namespace where EEA4 will be/is deployed
       * OAM_POOL: IP Pool name where eric-ts-platform-haproxy service will get LoadBalancer IP from
* [Config Testing Nx1 Upgrade](https://seliius27190.seli.gic.ericsson.se:8443/view/Manual%20config%20testing/job/eea-config-testing-nx1-upgrade/) upgrade test of the updated EEA integration helm chart from PrepareBaseline stage

## [eea-manual-config-testing-post-actions](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?q=manual&pipeline=eea-manual-config-testing-post-actions) Spinnaker pipeline

It is triggered by [eea-manual-config-testing](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?q=manual&pipeline=eea-manual-config-testing) Spinnaker pipeline execution

### Stages:

* eea-manual-config-testing-post-actions Collect variables from the parent [eea-manual-config-testing](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?q=manual&pipeline=eea-manual-config-testing) Spinnaker pipeline
* [Post actions (dashboard)](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-post-activities/) updates [Application Dashboard](http://10.223.227.167:61616/dashboard?stage=4&stage=5&stage=8&stage=9&last=1)
* [Collect Prod CI Execution KPIs](https://seliius27190.seli.gic.ericsson.se:8443/job/collect-prod-ci-execution-kpis/) collects execution KPIs

## CMA related stages and steps

See page [CMA configurations in product deployments](https://eteamspace.internal.ericsson.com/display/ECISE/CMA+configurations+in+product+deployments)
