# Information about eea_product_ci_meta_baseline_loop in Product CI

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## EEA Product CI Metabaseline loop pipelines in Jenkins and Spinnaker

### eea-app-meta-baseline-manual-flow

This Spinnaker pipeline is for triggering EEA Meta Baseline Staging in case of manual change in the metabaseline helm chart. Before triggering the staging loop  these patchsets are validated by:

* [run-hooks-cnint](https://seliius27190.seli.gic.ericsson.se:8443/job/run-hooks-meta-baseline) which gives verified +1/-1 voted in Gerrit
* developer during manual code review
* [meta baseline manual job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-ci-meta-baseline-loop-manual-job) which rebase the commit and  prepares prerequisites for triggering staging loop.
eea-app-meta-baseline-manual-flow will be triggered by the meta baseline manual job from Jenkins and this will trigger the Metabaseline Staging loop.

* [Link](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/configure/7e5a30db-f095-4c13-94a9-11967ce44a8c)

#### Input parameters

* GERRIT_REFSPEC

#### Stages

Meta Baseline Staging, stage type : pipeline(spinnaker) - triggering [eea-product-ci-meta-baseline-loop](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/configure/e287410d-293f-4c34-9616-6348b0e34624), wait for result : true

* Files
  * technicals/eea_product_ci_meta_baseline_loop_manual.groovy
  * technicals/eea_product_ci_meta_baseline_loop_manual.Jenkinsfile
  * technicals/patchset_hooks_meta_baseline.groovy
  * technicals/patchset_hooks_meta_baseline.groovy
* Trigger
  * Jenkins trigger, [eea-product-ci-meta-baseline-loop-manual-job:](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-ci-meta-baseline-loop-manual-job/)

### eea-product-ci-meta-baseline-loop

Purpose of this loop if to handle updates of EEA4 metabaseline in case of new drops of the elements in this helm chart.

Metabaseline contains test services (e.g. eric-eea-utf-application, eric-data-loader), Product CI code version (eric-eea-ci-code-helm-chart) and connects these to the EEA4 Product baseline (eric-eea-int-helm-chart). New version from any of these will result a new metabaseline version as well.

More information about the meabaseline chart is available [here](https://eteamspace.internal.ericsson.com/display/ECISE/EEA+Meta+Base+Helm+Chart).

* [Link](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/configure/e287410d-293f-4c34-9616-6348b0e34624)
* Input parameters
  * CHART_NAME
  * CHART_VERSION
  * CHART_REPO
  * GERRIT_REFSPEC
  * GIT_COMMIT_ID
  * SPINNAKER_TRIGGER_URL
  * HELM_AND_CMA_VALIDATION_MODE - Use HELM values or HELM values and CMA configurations. valid options: ""  legacy mode, "true"  use helm values, cma is diabled, "false" use helm values and load CMA configurations
  * BUILD_RESULT_WHEN_CMA_HEALTH_CHECK_FAILED build result when the CMA health check failed
* Stages
  * Evaluate Variables, stage type : Evaluate variables, Evaluated variables: GIT_COMMIT_ID, SPINNAKER_TRIGGER_URL
  * Sanity Check, stage type: Jenkins, job: input-sanity-check-metabaseline, wait for result: true, if build unstable consider stage successful, execute step only for triggers where parent ame contains 'drop_'.
  * Prepare, stage type: Jenkins, job: eea-product-ci-meta-baseline-loop-prepare, wait for result: true
  * Test, stage type: Jenkins, job: eea-product-ci-meta-baseline-loop-test, wait for result: true, execute step only for triggers where parent name contains 'drop_' or 'manual'
  * Publish,  stage type: Jenkins, job: eea/product-ci-meta-baseline-loop-publish, wait for result: true
* Files
  * jobs/eea_product_ci_meta_baseline_loop/eea_product_ci_meta_baseline_loop_prepare.groovy
  * pipelines/eea_product_ci_meta_baseline_loop/eea_product_ci_meta_baseline_loop_prepare.Jenkinsfile
  * jobs/eea_product_ci_meta_baseline_loop/eea_product_ci_meta_baseline_loop_publish.groovy
  * pipelines/eea_product_ci_meta_baseline_loop/eea_product_ci_meta_baseline_loop_publish.Jenkinsfile
  * jobs/eea_product_ci_meta_baseline_loop/eea_product_ci_meta_baseline_loop_spotfire.groovy
  * pipelines/eea_product_ci_meta_baseline_loop/eea_product_ci_meta_baseline_loop_spotfire.Jenkinsfile
  * jobs/eea_product_ci_meta_baseline_loop/eea_product_ci_meta_baseline_loop_test.groovy
  * pipelines/eea_product_ci_meta_baseline_loop/eea_product_ci_meta_baseline_loop_test.Jenkinsfile
  * jobs/eea_product_ci_meta_baseline_loop/eea_product_ci_meta_baseline_loop_upgrade.groovy
  * pipelines/eea_product_ci_meta_baseline_loop/eea_product_ci_meta_baseline_loop_upgrade.Jenkinsfile
  * jobs/eea_product_ci_meta_baseline_loop/eea_product_ci_meta_baseline_loop_utf_and_data_loader_deploy.groovy
  * pipelines/eea_product_ci_meta_baseline_loop/eea_product_ci_meta_baseline_loop_utf_and_data_loader_deploy.Jenkinsfile
  * jobs/eea_product_ci_meta_baseline_loop/eea_product_ci_meta_baseline_loop_utf_deploy.groovy
  * adp-app-staging/pipelines/eea_product_ci_meta_baseline_loop/eea_product_ci_meta_baseline_loop_utf_deploy.Jenkinsfile
* Trigger
  * eea-app-meta-baseline-manual-flow [pipeline](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/configure/7e5a30db-f095-4c13-94a9-11967ce44a8c)
* Configuration
  * eea-product-ci-meta-baseline-loop-test using next bob rules: init-mxe, init-eric-eea-analysis-system-overview-install, verify-values-files to check helm values from next lists (`values-list.txt, mxe-values-list.txt`) and k8s-test-splitted-values with next helm values (`helm-values/custom_environment_values.yaml,dataflow-configuration/all-VPs-configuration/refdata-values.yaml,dataflow-configuration/all-VPs-configuration/correlator-values.yaml,dataflow-configuration/all-VPs-configuration/aggregator-values.yaml,dataflow-configuration/all-VPs-configuration/db-loader-values.yaml,dataflow-configuration/all-VPs-configuration/db-manager-values.yaml,dataflow-configuration/all-VPs-configuration/dashboard-values.yaml,dataflow-configuration/all-VPs-configuration/irc-values.yaml,dataflow-configuration/all-VPs-configuration/pp-values.yaml,helm-values/custom_values_correlator_inc_weight_category.yml,helm-values/custom_values_correlator_pgwu.yml,helm-values/eea4-dimensioning-tool-output-values.yaml,helm-values/custom_deployment_values.yaml,helm-values/custom_prod_ci_dimensioning_values.yaml` from the master branch for install)
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
  * archiving of the above helm config value files as `install-configvalues.tar.gz` using archiveFilesFromLog()
  ***Note:*** During a check of new UTF application versions will be launched Backup Restore Orchestrator (BRO) tests. They consist of additional stages:
  * Create and export BRO backup (issues an utf-create-export-bro.log logfile)
  * BRO Validate system works as expected: before roll back (with a bro_validate_system_before_rollback.log logfile)
  * BRO Change IAM config (with a bro_change_iam_config.log logfile)
  * Import and restore from BRO backup (roll back) (produces a bro_import_and_restore_backup.log logfile)
  * cleanup IAM cache after rollback (runs a technicals/shellscripts/clean_cache_iam.sh scripts, it's necessary to check logs in console output)
  * BRO Validate system works as expected: after roll back (with a bro_validate_system_after_rollback.log logfile) Platform_Kyiv team is responsible for these tests
  ***Note:*** After UTF tests are called decisive and non_decisive robot tests that have recently been implemented. All robot's related logs are described in the [product-ci-deliverables](https://eteamspace.internal.ericsson.com/display/ECISE/Product+CI+deliverables) documentation
  ***Note:*** Jenkins plugin for Robot is showning a test result summary for Robot TCs, but it has a limitation that only 1 Robot call's result can be visualised for 1 Jenkins job. As in meta baseline pipeline we have 2 Robot calls (separate one for decisive and non-decisive TCs), and ONLY decisive results are shown in the report summary. Non-decisive test results can be checked among the cluster logs at ARM.
* [Used test data in validation](https://eteamspace.internal.ericsson.com/display/ECISE/Common+EEA4+CI+data+loading)

### eea-metabaseline-product-ci-version-change

* [Link](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/configure/944e2d7c-b967-4a81-a21a-cbf904850fb8)
* Input parameters: -
* Stages
  * Prod Ci Infrastructure Staging, stage type: pipeline, pipeline name: eea-prodct-ci-meta-baseline-loop

* Files: -
* Trigger
  * eea-product-ci-code-loop-publish [Jenkins job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-ci-code-loop-publish/)

### eea-metabaseline-product-version-change

* [Link](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/configure/0284e512-72b3-4738-9540-e2ad5f6ec41d)
* Input parameters: -
* Stages
  * Prod Ci Infrastructure Staging, stage type: pipeline, pipeline name: eea-prodct-ci-meta-baseline-loop

* Files: -
* Trigger
  * eea-application-staging-publish-baseline [Jenkins job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-publish-baseline/)

### Common

* Common files
  * technicals/eea_product_ci_meta_baseline_loop_seed.groovy
  * technicals/eea_product_ci_meta_baseline_loop_seed.Jenkinsfile
* Jenkins view
  * [link](https://seliius27190.seli.gic.ericsson.se:8443/view/EEA%20Product%20CI%20Meta-baseline%20loop%20View/)

### Restore spinnaker pipeline

* Copy the pipeline
  * Copy the JSON code from the examples to the spinnaker, into a new pipeline (you can select configure, pipeline actions, edit as JSON)
* Set up triggers
  * Check the triggers in the architecture wiki, and set up triggers in spinnaker
  * Example : [link](https://spinnaker.rnd.gic.ericsson.se/#/applications/adp_e2e_cicd/executions/details/01E7T84AKMJSE46SQYZZ4JWCBA?stage=0&step=0&details=pipelineConfig)
  * Create a new, or edit an already existing stage which triggers the eea-adp-staging pipeline
  * Example for condition : `${#stage['AdpStaging']['context']('CHART_VERSION').contains("-")}`
    **Important!!!
    In E2E pipelines such conditions are not allowed.
    Details of all stages of the E2E spinnaker pipelines must be visible on the dashboard.**

### HC script execute

HC script should be executed after installs to prevent failures during E2E tests because of unhealthy EEA deployment.

Affected pipelines:
[eea-product-ci-meta-baseline-loop-test](https://seliius27190.seli.gic.ericsson.se:8443/view/EEA%20Product%20CI%20Meta-baseline%20loop%20View/job/eea-product-ci-meta-baseline-loop-test/)

### Log collection from the test cluster

The logcollector has been separated from the pipelines to reduce the execution time. In this case the next spinnaker pipeline can be started if there are enough free clusters without wasting time on log collection and cleanup.

Job name: [cluster-logcollector](https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-logcollector)
Job doc [link](https://eteamspace.internal.ericsson.com/display/ECISE/Cluster+Log+Collector)

The cluster specific logs are available in the arm repo and all CI pipeline contains a link on the job page for that.
e.g.: [Cluster logs](https://arm.seli.gic.ericsson.se/artifactory/proj-eea-reports-generic-local/clusterlogs/)

#### Performance data collection from the test cluster

Meanwhile the log collection from the cluster we are [save performance data](https://eteamspace.internal.ericsson.com/display/ECISE/EEA4+Product+CI+performance+data+collection) from cluster and send to [central ELK](https://eteamspace.internal.ericsson.com/display/ECISE/ELK+%28aka+Elastic+stack%29+for+EEA4+CI).
The Grafana URL in job desription points to Perf_EEA4_Resource dashboard and filter for the execution which run data was collected

### Cleanup of the test cluster

The cleanup has been separated also. This called only by the cluster-logcollector Jenkins job with wait for result = true option.
Cleanup of the eea4 product namespace, utf namespace and the used CRDs from the test environment.

Job name: [cluster-cleanup](https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-cleanup)
Job doc [link](https://eteamspace.internal.ericsson.com/display/ECISE/Cluster+cleanup)

### Dimensioning Tool usage in Product CI Install pipelenes

[Dimtool in Product CI](https://eteamspace.internal.ericsson.com/display/ECISE/Dimtool+in+Product+CI)

### CMA related stages and steps

See page [CMA configurations in product deployments](https://eteamspace.internal.ericsson.com/display/ECISE/CMA+configurations+in+product+deployments)
