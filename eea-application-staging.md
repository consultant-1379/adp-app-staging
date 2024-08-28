# Information about eea-application-staging loop in Product CI

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## EEA APPLICATION STAGING CI pipelines in Jenkins and Spinnaker

Purpose of EEA Application Staging pipelines is to validate new µService drops for those µServices which are part of the EEA integration helm chart.
These µServices can be ADP GS and EEA specific µServices as well. When a new drop has passed the application staging pipelines the new µService version will be added to the integration helm chart. When a new ADP GS PRA version is added to the product integration helm chart owners of the ADP GS in EEA organization notified via email based on the information stored at the [Jira Component list](https://eteamproject.internal.ericsson.com/projects/EEAEPP?selectedItem=com.atlassian.jira.jira-projects-plugin:components-page).

## Testing disabled services in application stagning loop

As some services has to be delivered in disabled state by default and we need to verify these as well in the EEA Application Staging loop the following extra configuration needed in the deployment custom values file for these services. The helm-values/custom_deployment_values.yaml file in cnint repo contains the list of the services which has to be enabled during the deployment. This will overwrite the default state for these services from the integration helm chart.
As GL-D1121-033 guideline from ADP doesn't allow any service in disabled state in the integration chart you have to put the service on exception list for this guideline at the lint rule of the same ruleset file as above in cnint repo.

### eea-application-staging

[Link](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/configure/be1e2288-295f-47eb-a1cf-48ba4b2fdb96)

#### Input parameters

* CHART_NAME
* CHART_VERSION
* CHART_REPO
* GERRIT_REFSPEC
* GIT_COMMIT_ID
* SPINNAKER_TRIGGER_URL
* GERRIT_CHANGE_SUBJECT
* GERRIT_CHANGE_OWNER_NAME
* SKIP_TESTING
* HELM_AND_CMA_VALIDATION_MODE - Use HELM values or HELM values and CMA configurations. valid options: ""  legacy mode, "true"  use helm values, cma is diabled, "false" use helm values and load CMA configurations
* BUILD_RESULT_WHEN_CMA_HEALTH_CHECK_FAILED build result when the CMA health check failed

#### Stages

* Sanity check, stage type : jenkins : job : input-sanity-check, wait for result : true
* PrepareBaseline, stage type : jenkins, job : eea-application-staging-baseline-prepare, wait for result : true
* Staging Batch, stage type : jenkins, job : eea-application-staging-batch, wait for result : true
  * Checkout project-meta-baseline
  * ........................
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
    ***Note*** In case of a version change in the [Spotfire descriptor yaml file](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/spotfire_platform.yml) application staging pipeline will validate the new SF packages before it will be used in other pipelines
  * Run CheckSpotfirePlatform health check
    * execute eea_healthcheck.py from eric-eea-utils-ci docker image, parameters:
      * --run-only (Run only the listed check classes): CheckSpotfirePlatform
      * --namespace: spotfire-platform
  * ........................
  * Decisive robot Tests
* CSAR pre-upload check, stage type: jenkins, job: csar-check, wait for result : true
* Upgrade, stage type: jenkins, job: eea-application-product-upgrade, wait for result: true
* CPI build, stage type: jenkins, job: eea-application-staging-documentation-build, wait for result: true
* CSAR, stage type: jenkins, job: csar-build, wait for result : true
* PublishBaseline, stage type : jenkins, job : eea-application-staging-publish-baseline, wait for result : true
* ADP GS PRA notification, stage type : jenkins, job : eea-application-staging-pra-notification, wait for result : true

#### Files

* technicals/input_sanity_check.groovy
* technicals/input_sanity_check.Jenkinsfile
* jobs/eea_application_staging/eea_application_staging_baseline_prepare.groovy
* pipelines/eea_application_staging/eea_application_staging_prepare_baseline.Jenkinsfile
* jobs/csar/csar_check.groovy
* pipelines/csar/csar_check.Jenkinsfile
* jobs/eea_application_staging/eea_application_staging_batch.groovy
* pipelines/eea_application_staging/eea_application_staging_batch.Jenkinsfile
* jobs/eea_application_staging/eea_application_staging_product_upgrade.groovy
* pipelines/eea_application_staging/eea_application_staging_product_upgrade.Jenkinsfile
* jobs/eea_application_staging/eea_application_staging_documentation_build.groovy
* pipelines/eea_application_staging/eea_application_staging_documentation_build.Jenkinsfile
* jobs/csar/csar_build.groovy
* pipelines/csar/csar_build.Jenkinsfile
* jobs/eea_application_staging/eea_application_staging_publish_baseline.groovy
* pipelines/eea_application_staging/eea_application_staging_publish_baseline.Jenkinsfile
* jobs/eea_application_staging/eea_application_staging_pra_notification.groovy
* pipelines/eea_application_staging/eea_application_staging_pra_notification.Jenkinsfile

#### Trigger

eea-adp-staging spinnaker [pipeline](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/configure/4cf92d8c-cbea-4dc7-a899-6ed601433dd6) (non PRA ADP only)

#### Configuration

eea-application-staging-batch using verify-values-files (`values-list.txt`) and k8s-test-splitted-values bob-rules (`helm-values/custom_environment_values.yaml, dataflow-configuration/all-VPs-configuration/refdata-values.yaml, dataflow-configuration/all-VPs-configuration/correlator-values.yaml, dataflow-configuration/all-VPs-configuration/aggregator-values.yaml, dataflow-configuration/all-VPs-configuration/db-loader-values.yaml, dataflow-configuration/all-VPs-configuration/db-manager-values.yaml, dataflow-configuration/all-VPs-configuration/dashboard-values.yaml, helm-values/custom_values_correlator_inc_weight_category.yml, helm-values/custom_values_correlator_pgwu.yml, helm-values/custom_dimensioning_values.yaml, helm-values/custom_deployment_values.yaml` from the master branch or specified GERRIT_REFSPEC are used for the install), eea-application-staging-product-upgrade

### eea-application-staging-non-pra

* [Link](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/configure/dad52daa-7065-433f-9d9e-b44dbc1bc978)
* Input parameters
  * CHART_NAME
  * CHART_VERSION
  * CHART_REPO
  * GERRIT_REFSPEC
  * GIT_COMMIT_ID
  * SPINNAKER_TRIGGER_URL
  * SKIP_TESTING_INSTALL
    * input of this parameter can be configured for µService pipelines in the artifact.properties files
    * if you don't want to run install validation, artifact.properties generated by the µService drop Jenkins job should contain this:
      * `SKIP_TESTING_INSTALL=true`
  * SKIP_TESTING_UPGRADE
    * input of this parameter can be configured for µService pipelines in the artifact.properties files
    * if you don't want to run upgrade validation, artifact.properties generated by the µService drop Jenkins job should contain this:
      * `SKIP_TESTING_UPGRADE=true`
* Stages
  * Sanity check, stage type : jenkins : job : input-sanity-check, wait for result : true
  * PrepareBaseline, stage type : jenkins, job : [eea-application-staging-baseline-prepare](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-baseline-prepare/), wait for result : true
  * Staging Nx1, stage type : jenkins, job : [eea-application-staging-nx1](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-nx1/), wait for result : true
    * execution can be skipped if the input parameter `SKIP_TESTING_INSTALL` is set to `true`
    * please note that PRA versions can only be validated after a SUCCESSFUL install and update has been verified
  * Staging Nx1 Upgrade, stage type : jenkins, job : [eea-application-staging-nx1-upgrade](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-nx1-upgrade/), wait for result : true
    * execution can be skipped if the input parameter `SKIP_TESTING_UPGRADE` is set to `true`
    * please note that PRA versions can only be validated after a SUCCESSFUL install and update has been verified
* Files
  * jobs/eea_application_staging/eea_application_staging_baseline_prepare.groovy
  * pipelines/eea_application_staging/eea_application_staging_prepare_baseline.Jenkinsfile
  * jobs/eea_application_staging/eea_application_staging_nx1.groovy
  * pipelines/eea_application_staging/eea_application_staging_nx1.Jenkinsfile
  * jobs/eea_application_staging/eea_application_staging_nx1_upgrade.groovy
  * pipelines/eea_application_staging/eea_application_staging_nx1_upgrade.Jenkinsfile
* Trigger
  * µService release pipelines
* Configuration
  * eea-application-staging-nx1 leveraging next bob rules: init-mxe, init-eric-eea-analysis-system-overview-install, verify-values-files to check helm values from next lists (`values-list.txt, mxe-values-list.txt`) and k8s-test-splitted-values bob-rules with next helm values (`helm-values/custom_environment_values.yaml,dataflow-configuration/all-VPs-configuration/refdata-values.yaml,dataflow-configuration/all-VPs-configuration/correlator-values.yaml,dataflow-configuration/all-VPs-configuration/aggregator-values.yaml,dataflow-configuration/all-VPs-configuration/db-loader-values.yaml,dataflow-configuration/all-VPs-configuration/db-manager-values.yaml,dataflow-configuration/all-VPs-configuration/dashboard-values.yaml,dataflow-configuration/all-VPs-configuration/irc-values.yaml,dataflow-configuration/all-VPs-configuration/pp-values.yaml,helm-values/custom_values_correlator_inc_weight_category.yml,helm-values/custom_values_correlator_pgwu.yml,helm-values/eea4-dimensioning-tool-output-values.yaml,helm-values/custom_deployment_values.yaml,helm-values/custom_prod_ci_dimensioning_values.yaml` from the master branch for install)
  * archiving of the above helm config value files as `install-configvalues.tar.gz` using archiveFilesFromLog()
* eea-application-staging-nx1-upgrade using the following rules:
  * setup-ci-custom-yaml

### eea-app-baseline-manual-flow

This Spinnaker pipeline is for triggering EEA Application Staging in case of manual changes. Before triggering the application staging these patchsets are validated by:

* [precodereivew job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-app-baseline-manual-flow-precodereview/) which gives verified +1/-1 voted in Gerrit
* [run-hooks-cnint](https://seliius27190.seli.gic.ericsson.se:8443/job/run-hooks-cnint/) which gives verified +1/-1 voted in Gerrit
  * Using latest adp-helm-dr-check Docker image validating the integration helm chart to be in-line with ADP helm DRs before any manual change in it.

  * Following exemption used: GL-D1121-033 skipped for eric-eea-spotfire-dashboards, eric-eea-refdata-data-document-database-pg and eric-eea-refdata-provisioner, eric-eea-cm-storage-backend

  * To validate only the top level chart the following flag is used: -DhelmDesignRule.feature.dependency=1

  * Values files verification included to this Jenkins job. Verification is done using the `/local/bin/get_and_check_values_files.py` script from the `eea4-utils` docker image excluding the eea4-dimensioning-tool-output-values.yaml. If the verification fails, the pipeline will fail, and the patchset author will receive a notification about the failed verification stage

* developer during manual code review
  * Verifies integration helm chart using latest version of adp-helm-dr-check Docker image to be in-line with ADP helm design rules.
* [verify-cr job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-app-baseline-manual-flow-verify-cr/) which verifies if the change has enough Code-Reviews from authorized people. [Detailed job documentation](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/documentation/cnintReviewProcess.md)
* [codereview-ok job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-app-baseline-manual-flow-codereview-ok/) which rebases the commit and  prepares prerequisites for eea applications staging triggering.
codereview-ok job will be triggered by the verify-cr job in case, if all authorized CR+1 for the changes were found
eea-app-baseline-manual-flow will be triggered by the codereview-ok job from Jenkins and this will trigger the Application Staging.

* [Link](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/configure/35cebcd7-2471-46cb-a90e-7a2b504eb216)
* Input parameters
  * GERRIT_REFSPEC
* Stages
  * eea-applcation-staging, stage type : Pipeline, pipeline : eea-applcation-staging, wait for result : true
* Files
  * jobs/eea_app_baseline_manual_flow/eea_app_baseline_manual_flow_codereview_ok.groovy
  * pipelines/eea_app_baseline_manual_flow/eea_app_baseline_manual_flow_codereview_ok.Jenkinsfile
  * jobs/eea_app_baseline_manual_flow/eea_app_baseline_manual_flow_precodereview.groovy
  * pipelines/eea_app_baseline_manual_flow/eea_app_baseline_manual_flow_precodereview.Jenkinsfile
  * technicals/patchset_hooks_cnint.groovy
  * technicals/patchset_hooks_cnint.Jenkinsfile

* Trigger
  * [codereview-ok job Jenkins job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-app-baseline-manual-flow-codereview-ok/)

### CSM µService integration in EEA application staging pipelines

After architectural change of CSM 2 legacy services were split to 9 separate µServices. As CSM is owned by EIAP development team outside of EEA but they are not part of ADP GS/RS services either. EEA is just reusing these services shared on domain level. So integration flow for these services is different both from EEA and ADP GS/RS services.

#### Non PRA drop flow

On EIAP side dev team maintains similar E2E Spinnaker flows to trigger their user applications like what we have for ADP GS/RS. [Example](https://spinnaker.rnd.gic.ericsson.se/#/applications/adc-e2e-cicd/executions/details/01GTKBA2A2BEMFYQ7A8NR0M14X?stage=1&step=0&details=pipelineConfig) for eric-oss-session-mgmt-ebm-termination service.

For all CSM services we have a drop pipeline in Spinnaker at EEA application. You can find other components that triggers the pipeline [here](https://eteamproject.internal.ericsson.com/projects/EEAEPP?selectedItem=com.atlassian.jira.jira-projects-plugin:components-page)). The CSM services are connected with the EIAP E2E pipelines at the dedicated EEA stage. These drop pipelines handles both non PRA and PRA versions and triggers the proper EEA Application staging Spinnaker pipeline like it's done for EEA µServices.

#### PRA drop flow

CSM PRA drops are built by the owner team of CSM services at EEA side as EIAP is not creating + versions yet. This release responsibility is at EEA side.

Release job for all CSM services is [here](https://seliius27191.seli.gic.ericsson.se:8443/job/eric_csm_release_drop).

This triggers a [central CSM drop pipeline](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eric-csm-release-drop) in Spinnaker at EEA side which is needed for separating different µService triggers and prepare proper parameters for the µService specific drop pipelines. This triggers the same µService drop pipelines which are mentioned in the Non PRA drop flow, and via that the + versions are reaching the [eea-application-staging-wrapper](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-application-staging-wrapper) pipeline.

### Certificate handling in Product CI pipelines

We are using a pre-generated CA certificate in Product CI pipelines, which is stored in [eea4-certs](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/eric-eea-int-helm-chart-ci/static/eea4-certs/)
The CA certificate expiration date is:  Jul 22 08:26:41 2033 GMT

```
[cnint]$ openssl x509 -enddate -noout -in eric-eea-int-helm-chart-ci/static/eea4-certs/external_ca.pem
notAfter=Jul 22 08:26:41 2033 GMT
```

The [post_install_certm.sh](https://gerrit.ericsson.se/plugins/gitiles/EEA/general_ci/+/master/docker/toolbox/tools/post_install_certm.sh) is used from [ci-toolbox docker image](https://arm.seli.gic.ericsson.se/ui/repos/tree/General/proj-eea-drop-docker-global/proj-eea-drop/ci-toolbox) in [ruleset2.0.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/ruleset2.0.yaml) rules, e.g: [upload-cas](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/ruleset2.0.yaml#424) rule.

The post_install_certm.sh has --external-ca-key-filename and --external-ca-cert-filename parameters and using those parameters we can specify which CA files are to be used during each service certificates generation (ingress or egress).

### eea-cbos-verify

Running nightly, verifies the baseline Common Base OS with the CBOS Age Tool. Sends notification report to specific people where problems found.
No input parameters (uses latest chart)

### HC script execute

HC script should be executed after installs to prevent failures during E2E tests because of unhealthy EEA deployment.

Affected pipelines:

[eea-application-staging-batch](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-batch/)
[eea-application-staging-nx1](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-nx1/)

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

## Resource locking during the publish-baseline

To avoid problems in *prepare builds while* publish is running the lockable resource logic was introduced.

When publish is executed, it locks a lockable resource named `baseline-publish`. So prepare build cannot be started while `baseline-publish` lockable resource is busy

## Introduce extra checks in baseline-prepare

To prevent unnecessary waste of resources and to avoid publish and documentation change workflow errors, we introduced some extra validation in the Prepare logic.
Those issues can happen, when a µService drop version already merged to cnint, but the process and validation restarts for whatever reason.
To solve this we introduced a logic to the [eea-application-staging-baseline-prepare](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-baseline-prepare/) Jenkins job, that checks the master state of the IHC and if the same version of that service is available then fail the prepare and the whole pipeline.
The new check stage `Check if chart version is already merged` will be executed only when a CHART_NAME and CHART_VERSION parameter is given for prepare job.

Also, we introduced the check for int chart version.
The issue is when old int chart version equals to new int chart version, it can cause the failing of the baseline-publish job, to avoid this case we created a new stage with comparing version parameters.
The stage `Check chart version` will take the parameters `INT_CHART_VERSION` and `INT_CHART_VERSION_STABLE` as `newIntChartVersion` and `oldIntChartVersion` from artifacts and compare them. If they are the same, the baseline-prepare will fail.

## Introduce new time based internal versioning of EEA

New versioning flow:

* new version format: `<year>.<week>.<patch/EP number>-<build number>`
  * e.g.: 23.44.0-1
* at each Monday 0:00 CET version updater would change the versions to the following: yy.ww.0-1
* last digit will be increased only by EPs, on the master branch it should be continuously 0
* weekly drops, RCs and PRAs won't change the actual version of the charts, just add git tags

## Transition from helm based configuration to CMA

Until the end of a transition period from helm based config to CMA, both configurations should be tested in Product CI, [see study](https://eteamspace.internal.ericsson.com/display/ECISE/EEAEPP-81492+Integrate+CMA+to+Product+CI) for details.

### CMA/Helm config related changes eea-application-staging

* In the [eea-application-staging-baseline-prepare](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-baseline-prepare/) job a new variable  `VALIDATE_WITH_HELM` is introduced, and it's value gets written to the artifact.properties file. This value is set to `true` only in case:
  * the change is a manual change AND the caller pipeline is eea-application-staging
  * AND if helm configuration files (the ones listed in cnint/values-list.txt or  cnint/custom-cma-disable.yaml) changed in the commit

### eea-product-release-time-based-new-version Jenkins job

To support new time based internal versioning of EEA we created an automated umbrella job which would change the following helm chart versions on time based triggers:

* EEA integration helm chart
* Metabaseline helm chart
* Documentaiton helm chart
* CDD helm chart

It's automatically triggered at each Monday 0:00 CET, BUT Product CI Team can update helm chart versions manually with this job, if needed. (e.g. if automated change can't run because of a maintenance weekend)

Job name: [eea-product-release-time-based-new-version](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-release-time-based-new-version/)
Doc link: [eea-product-release-time-based-new-version](https://eteamspace.internal.ericsson.com/display/ECISE/Information+about+eea-product-release-loop+in+Product+CI#InformationabouteeaproductreleaseloopinProductCI-1.9.eea-product-release-time-based-new-version)

* Jobs calling eea-product-release-time-based-new-version
  * [eea-product-release-job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-release-job/)

## Restore spinnaker pipeline

* Copy the pipeline
  * Copy the JSON code from the examples to the spinnaker, into a new pipeline (you can select configure, pipeline actions, edit as JSON)
* Set up triggers
  * Check the triggers in the architecture wiki, and set up triggers in spinnaker
  * Instructions : [link](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/trigger-product-ci-loop-guide.md)
  * Create a new, or edit an already existing stage which triggers the eea-application-staging pipeline
  * Example for condition : `${#stage['stage_name']['context']('CHART_VERSION').contains("-")}`
    **Important!!!
    In E2E pipelines such conditions are not allowed.
    Details of all stages of the E2E spinnaker pipelines must be visible on the dashboard.**

## Dimensioning Tool usage in Product CI Install pipelines

[Dimtool in Product CI](https://eteamspace.internal.ericsson.com/display/ECISE/Dimtool+in+Product+CI)

## CMA related stages and steps

See page [CMA configurations in product deployments](https://eteamspace.internal.ericsson.com/display/ECISE/CMA+configurations+in+product+deployments)
