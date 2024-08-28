# Information about eea_adp_staging loop in Product CI

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## EEA ADP STAGING CI pipelines in Jenkins and Spinnaker

Purpose of these pipelines is to validate ADP GS drops (both PRA and non-PRA versions) and give feedback about them towards the ADP GS development team.
In case of non-PRA versions feedback sent via Spinnaker after eea-adp-staging pipeline has finished.
For PRA versions EEA Application staging pipeline is triggered after a successful ADP staging install and ADP staging upgrade run, and the application staging pipeline will add the new PRA version to the integration helm chart if that version has passed the application staging pipelines. When a new ADP GS PRA version is added to the product integration helm chart owners of the ADP GS in EEA organization notified via email based on the information stored at the [Jira Component list](https://eteamproject.internal.ericsson.com/projects/EEAEPP?selectedItem=com.atlassian.jira.jira-projects-plugin:components-page).

### eea-adp-staging

* [Link](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/configure/4cf92d8c-cbea-4dc7-a899-6ed601433dd6)
* Input parameters
  * CHART_NAME
  * CHART_VERSION
  * CHART_REPO
  * GERRIT_REFSPEC
  * HELM_AND_CMA_VALIDATION_MODE - Use HELM values or HELM values and CMA configurations. valid options: ""  legacy mode, "true"  use helm values, cma is diabled, "false" use helm values and load CMA configurations
  * BUILD_RESULT_WHEN_CMA_HEALTH_CHECK_FAILED build result when the CMA health check failed

* Stages
  * PrepareBaseline, stage type: jenkins, job: [eea-adp-staging-adp-prepare-baseline](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-adp-staging-adp-prepare-baseline/), wait for result: true
  * EEA ADP Staging Install, stage type: jenkins, job: [eea-adp-staging-adp-nx1-loop](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-adp-staging-adp-nx1-loop/), wait for result: true, parameters from previous stage: INT_CHART_NAME, INT_CHART_VERSION, INT_CHART_REPO
  * Stages in Jenkins job:
    * Params DryRun check
    * Cluster params check
    * HELM_AND_CMA_VALIDATION_MODE Param check
    * Checkout (cnint)
    * Prepare bob
    * Checkout adp-app-staging
    * Checkout technicals
    * Checkout project-meta-baseline
    * Init Description
    * Resource locking - utf deploy and K8S Install
      * Wait for cluster
      * Lock
        * log lock
        * init vars
        * Check if namespace exist
        * Check NELS availability
        * CRD Install
        * Install K8S-based Spotfire
          * utf and data loader deploy
          * Execute Spotfire deployment
            * Calls the [spotfire-asset-install](https://seliius27190.seli.gic.ericsson.se:8443/job/spotfire-asset-install) job
            * To deploy K8S Spotfire platform on Product CI cluster with below input parameters
              * INSTALL_SPOTFIRE_PLATFORM: Boolean input parameter that must be checked to install Spotfire BI Visualization Platform in spotfire-platform namespace
              * DEPLOY_STATIC_CONTENT: Boolean input parameter that must be checked to install or re-install the specified static content (SC) version
              * AGENT_LABEL: Jenkins agent with the label will be used for the build
              * CLUSTER_NAME: Cluster resource name to execute Spotfire platform install on
              * EEA4_NS_NAME: Namespace where EEA4 will be/is deployed
              * OAM_POOL: IP Pool name where eric-ts-platform-haproxy service will get LoadBalancer IP from
              * SF_ASSET_VERSION: Spotfire asset version
              * STATIC_CONTENT_PKG: Static content package version
          * SEP Install
        * Set CMA helm values
        * Download and apply dimtool output file
        * K8S Install Test
        * Create stream-aggregator configmap
        * Run health check after install
        * Link Spotfire platform to EEA
          * Calls the [spotfire-asset-install](https://seliius27190.seli.gic.ericsson.se:8443/job/spotfire-asset-install) job
          * input parameters:
            * SETUP_TLS_AND_SSO: To set Up TLS Connection Between Spotfire and OLAP (Vertica) Database
            * ENABLE_CAPACITY_REPORTER: To configure and enable capacity reporter
            * AGENT_LABEL: Jenkins agent with the label will be used for the build
            * CLUSTER_NAME: Cluster resource name to execute Spotfire platform install on
            * PREVIOUS_JOB_BUILD_ID: Build ID of the previous job where the Spotfire platform was installed on the selected cluster
            * EEA4_NS_NAME: Namespace where EEA4 will be/is deployed
            * OAM_POOL: IP Pool name where eric-ts-platform-haproxy service will get LoadBalancer IP from
        * Run CheckSpotfirePlatform health check
          * execute eea_healthcheck.py from eric-eea-utils-ci docker image, parameters:
            * --run-only (Run only the listed check classes): CheckSpotfirePlatform
            * --namespace: spotfire-platform
        * Load config cubes json to CM-Analytics
        * Run health check after CM-Analytics config load
        * Run CMA health check after CM-Analytics config load
        * Execute BRO tests
        * init UTF Test Variables
        * UTF Pre-activities
        * Execute Cucumber UTF Test
          * Decisive Nx1 ADP UTF Cucumber Tests
        * Decisive robot Tests
        * UTF Post-activities
  * EEA ADP Staging Upgrade, stage type: jenkins, job: [eea-adp-staging-adp-nx1-loop-upgrade](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-adp-staging-adp-nx1-loop-upgrade/), wait for result: true, parameters from previous stage: INT_CHART_NAME, INT_CHART_VERSION, INT_CHART_REPO
  * EEA Application Staging, stage type: pipeline(spinnaker) - triggering [eea-application-staging](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/eea-application-staging.md), wait for result: false
* Files
  * adp-app-staging/jobs/eea_adp_staging/eea_adp_staging_adp_nx1_loop.groovy
  * adp-app-staging/jobs/eea_adp_staging/eea_adp_staging_adp_nx1_loop_upgrade.groovy
  * adp-app-staging/jobs/eea_adp_staging/eea_adp_staging_adp_prepare_baseline.groovy
  * adp-app-staging/pipelines/eea_adp_staging/eea_adp_staging_adp_nx1_loop.Jenkinsfile
  * adp-app-staging/pipelines/eea_adp_staging/eea_adp_staging_adp_nx1_loop_upgrade.Jenkinsfile
  * adp-app-staging/pipelines/eea_adp_staging/eea_adp_staging_adp_prepare_baseline.Jenkinsfile
* Trigger
  * ADP trigger, [ARM repo:](https://arm.sero.gic.ericsson.se/artifactory/proj-adp-gs-all-helm/)
* Configuration
  * This pipeline run concurrently
  * eea-adp-staging-adp-nx1-loop using next bob rules: init-mxe, init-eric-eea-analysis-system-overview-install, verify-values-files to check helm values from next lists (`values-list.txt, mxe-values-list.txt`) and k8s-test-splitted-values bob-rules with next helm values (`helm-values/custom_environment_values.yaml, dataflow-configuration/all-VPs-configuration/refdata-values.yaml, dataflow-configuration/all-VPs-configuration/correlator-values.yaml, dataflow-configuration/all-VPs-configuration/aggregator-values.yaml, dataflow-configuration/all-VPs-configuration/db-loader-values.yaml, dataflow-configuration/all-VPs-configuration/db-manager-values.yaml, dataflow-configuration/all-VPs-configuration/dashboard-values.yaml, dataflow-configuration/all-VPs-configuration/irc-values.yaml, dataflow-configuration/all-VPs-configuration/pp-values.yaml, helm-values/custom_values_correlator_inc_weight_category.yml, helm-values/custom_values_correlator_pgwu.yml, helm-values/eea4-dimensioning-tool-output-values.yaml, helm-values/custom_deployment_values.yaml, helm-values/custom_prod_ci_dimensioning_values.yaml` from the master branch for install)
    Note: in case of a new Backup Restore Orchestrator (BRO) version integration eea-adp-staging-adp-nx1-loop will start with additional stages:
    * Create and export BRO backup (issues an utf-create-export-bro.log logfile)
    * BRO Validate system works as expected: before roll back (with a bro_validate_system_before_rollback.log logfile)
    * BRO Change IAM config (with a bro_change_iam_config.log logfile)
    * Import and restore from BRO backup (roll back) (produces a bro_import_and_restore_backup.log logfile)
    * cleanup IAM cache after rollback (runs a technicals/shellscripts/clean_cache_iam.sh scripts, it's necessary to check logs in console output)
    * BRO Validate system works as expected: after roll back (with a bro_validate_system_after_rollback.log logfile)
    Platform Kyiv team is responsible for these tests
  * eea-adp-staging-adp-nx1-loop-upgrade using the following rules:
    * setup-ci-custom-yaml
* [Used test data in validation](https://eteamspace.internal.ericsson.com/display/ECISE/Common+EEA4+CI+data+loading)

### Common

* Common files
  * adp-app-staging/technicals/eea_adp_staging_seed.groovy
  * adp-app-staging/technicals/eea_adp_staging_seed.Jenkinsfile
  * adp-app-staging/technicals/eea_adp_batch_loop_seed.groovy
  * adp-app-staging/technicals/eea_adp_batch_loop_seed.Jenkinsfile
* Jenkins view
  * [link](https://seliius27190.seli.gic.ericsson.se:8443/view/EEA%20ADP%20Staging/)

### Restore spinnaker pipeline

* Copy the pipeline
  * Copy the JSON code from the examples to the spinnaker, into a new pipeline (you can select configure, pipeline actions, edit as JSON)
* Set up triggers
  * Check the triggers in the architecture wiki, and set up triggers in spinnaker
  * Example: [link](https://spinnaker.rnd.gic.ericsson.se/#/applications/adp_e2e_cicd/executions/details/01E7T84AKMJSE46SQYZZ4JWCBA?stage=0&step=0&details=pipelineConfig)
  * Create a new, or edit an already existing stage which triggers the eea-adp-staging pipeline
  * Example for condition: `${#stage['AdpStaging']['context']('CHART_VERSION').contains("-")}`
    **Important!!!
    In E2E pipelines such conditions are not allowed.
    Details of all stages of the E2E spinnaker pipelines must be visible on the dashboard.**

### HC script execute

HC script should be executed after installs to prevent failures during E2E tests because of unhealthy EEA deployment.

Affected pipelines:
[eea-adp-staging-adp-nx1-loop](https://seliius27190.seli.gic.ericsson.se:8443/view/EEA%20ADP%20Staging%20View/job/eea-adp-staging-adp-nx1-loop/)

### Log collection from the test cluster

The logcollector has been separated from the pipelines to reduce the execution time. In this case the next spinnaker pipeline can be started if there are enough free clusters without wasting time on log collection and cleanup.

Job name: [cluster-logcollector](https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-logcollector)
Job doc [link](https://eteamspace.internal.ericsson.com/display/ECISE/Cluster+Log+Collector)

The cluster specific logs are available in the arm repo and all CI pipeline contains a link on the job page for that.
e.g.: [Cluster logs](https://arm.seli.gic.ericsson.se/artifactory/proj-eea-reports-generic-local/clusterlogs/)

#### Performance data collection from the test cluster

Meanwhile the log collection from the cluster, we are [save performance data](https://eteamspace.internal.ericsson.com/display/ECISE/EEA4+Product+CI+performance+data+collection) from cluster and send to [central ELK](https://eteamspace.internal.ericsson.com/display/ECISE/ELK+%28aka+Elastic+stack%29+for+EEA4+CI).
The Grafana URL in job desription points to Perf_EEA4_Resource dashboard and filter for the execution which run data was collected

### Cleanup of the test cluster

The cleanup has been separated also. This called only by the cluster-logcollector Jenkins job with wait for result = true option.
Cleanup of the eea4 product namespace, utf namespace and the used CRDs from the test environment.

Job name: [cluster-cleanup](https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-cleanup)
Job doc [link](https://eteamspace.internal.ericsson.com/display/ECISE/Cluster+cleanup)

### Dimensioning Tool usage in Product CI Install pipelenes

[Dimtool in Product CI](https://eteamspace.internal.ericsson.com/display/ECISE/Dimtool+in+Product+CI)

## CMA related stages and steps

See page [CMA configuartions in product deployments](https://eteamspace.internal.ericsson.com/display/ECISE/CMA+configuartions+in+product+deployments)
