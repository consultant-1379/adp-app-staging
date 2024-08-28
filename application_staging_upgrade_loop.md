# Application staging upgrade loop

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Description

eea-application-staging-product-upgrade pipeline is triggered by every change verified at the [EEA Application Staging](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-application-staging) loop as a prerequisite before merging something to the product baseline. For more details about EEA Application Staging, follow [this](https://eteamspace.internal.ericsson.com/display/ECISE/Information+about+eea-application-staging+loop+in+Product+CI) link.

## Jenkins job

Job name: [eea-application-staging-product-upgrade](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-product-upgrade/)

## Parameters

+ CHART_NAME - Chart name e.g.: eric-ms-b
+ CHART_REPO - Chart repo e.g.: [https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm]
+ CHART_VERSION - Chart version e.g.: 1.0.0-1
+ INT_CHART_NAME - Chart name e.g.: eric-ms-b
+ INT_CHART_REPO - Chart repo e.g.: [https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm]
+ INT_CHART_VERSION - Chart version e.g.: 1.0.0-1
+ GERRIT_REFSPEC - Gerrit Refspect of the integration chart git repo e.g.: refs/changes/87/4641487/1
+ SPINNAKER_TRIGGER_URL - Spinnaker pipeline triggering url
+ SPINNAKER_ID - The spinnaker execution's id
+ PIPELINE_NAME - The spinnaker pipeline name
+ CLUSTER_NAME - Locked cluster with new version of CCD
+ CLUSTER_LABEL - Special label for test new version of CCD
+ SKIP_COLLECT_LOG - skip the log collection pipeline
+ SKIP_CLEANUP - skip the cleanup pipeline. Used when SKIP_COLLECT_LOG is false
+ WAIT_FOR_CLUSTER_LOG_COLLECTOR_RESULT - Wait for cluster log collector job result to be sure that new docker images work properly
+ CUSTOM_CLUSTER_LABEL - If CUSTOM_CLUSTER_LABEL is set, we have to set that label at the end of the pipeline executions, and FORCE skip the collect log and cleanup !!!
+ SEP_CHART_NAME - SEP helm chart name
+ SEP_CHART_REPO - SEP helm chart repo
+ DIMTOOL_OUTPUT_REPO_URL - The url of the artifactory
+ DIMTOOL_OUTPUT_REPO - Repo of the chart eg. proj-eea-reports-generic-local/dimtool/prod_ci_artifacts/
+ DIMTOOL_OUTPUT_NAME - Chart name e.g.: eea-application-staging-baseline-prepare-12695/eea4-dimensioning-tool-output.zip
+ BUILD_RESULT_WHEN_NELS_CHECK_FAILED - build result when the Check NELS availability failed
+ HELM_AND_CMA_VALIDATION_MODE - Use HELM values or HELM values and CMA configurations. valid options ("true":  use helm values, cma is disabled / "false": use helm values and load CMA configurations)
+ DEFAULT_BASELINE_INSTALL_MODE - What is the default value of HELM_AND_CMA_VALIDATION_MODE during eea-application-staging-product-baseline-install

## Steps

+ Params DryRun check
+ Cluster params check
+ Init
+ Validate patchset changes
+ Prepare upgrade
  + Execute [eea-product-prepare-upgrade](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-prepare-upgrade/) Jenkins job to have pre installed cluster containing the product baseline.
  + Job doc [link](https://eteamspace.internal.ericsson.com/display/ECISE/EEA4+Product+Prepare+Upgrade)
+ Execute upgrade
  + Execute [eea-common-product-upgrade](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-common-product-upgrade/) Jenkins job to validate changes using the generic common upgrade job.
  + Job doc [link](https://eteamspace.internal.ericsson.com/display/ECISE/EEA4+Common+Product+Upgrade)
+ Copy artifacts
  + Copy artifacts from the wrapper job to
+ Archive artifacts
