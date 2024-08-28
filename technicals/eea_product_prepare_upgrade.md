# EEA4 Product Prepare Upgrade

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Description

The job contains the common logic for baseline install triggers considering different purposes e.g. "Helm" or "Helm+CMA" based installs.
Later on we have to introduce here the capability of multiconfig runs as well.

This job is responsible for starting the [eea-application-staging-product-baseline-install](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-product-baseline-install/) Jenkins job to have pre installed clusters for the product- and meta-baseline upgrade jobs.
The job also aims to handle the case, when the default baseline installation mode is Helm+CMA, but the upstream upgrade job needs only Helm based baseline installed cluster.
The job can be triggered from the product and meta upgrade jobs directly or started by time triggered cron job or can be started manually also.

+ On Test Jenkins: because of the functional tests working mechanism to serve the upgrade requiremenmts properly we cannot start more than one baseline install at the same time. We cannot run this job on the Test Jenkins from time based job also. Only the upgrade jobs will start this to have preinstalled baseline clusters.
+ On Master Jenkins: there is no similar limitation

## Jenkins job

Job name: [eea-product-prepare-upgrade](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-prepare-upgrade/)

## Jobs calling eea-product-prepare-upgrade

+ [eea-product-prepare-upgrade-scheduler](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-prepare-upgrade-scheduler/)
+ [eea-application-staging-product-upgrade](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-product-upgrade/)
+ [eea-product-ci-meta-baseline-loop-upgrade](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-ci-meta-baseline-loop-upgrade/)
+ [eea-adp-staging-adp-nx1-loop-upgrade](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-adp-staging-adp-nx1-loop-upgrade/)
+ [eea-application-staging-nx1-upgrade](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-nx1-upgrade/)

## Parameters

+ GIT_BRANCH - git branch from the [cnint repo](https://gerrit.ericsson.se/#/admin/projects/EEA/cnint,branches) to specify the baseline version to install. e.g.: eea4_4.4.0. If the value is 'latest' than the pipeline will calculate the branch name using the latest pra git tag: 'latest_release'.
+ BASELINE_UPGRADE_CLUSTER_LABEL - Upgrade ready resource label name e.g.: bob-ci-upgrade-ready, defaultValue: bob-ci-upgrade-ready
+ SPINNAKER_ID - The spinnaker execution's id
+ PIPELINE_NAME - The spinnaker pipeline name
+ CUSTOM_CLUSTER_LABEL - Should be overriden based on HELM_AND_CMA_VALIDATION_MODE value. If CUSTOM_CLUSTER_LABEL is set, we have to set that label at the end of the pipeline executions, and FORCE skip the cleanup !!!, defaultValue: 'bob-ci-upgrade-ready'
+ HELM_AND_CMA_VALIDATION_MODE - Use HELM values or HELM values and CMA configurations. valid options ("true" or "HELM":  use helm values, cma is disabled / "false" or "HELM_AND_CMA": use helm values and load CMA configurations)
+ DEFAULT_BASELINE_INSTALL_MODE - What is the default value of HELM_AND_CMA_VALIDATION_MODE during eea-application-staging-product-baseline-install
+ WAIT_FOR_BASELINE_INSTALL - Should be overriden based on HELM_AND_CMA_VALIDATION_MODE value. Wait for eea-application-staging-product-baseline-install', defaultValue: "false"

## Steps

+ Params DryRun check
+ Prepare product baseline
  + Prepare product baseline on Test Jenkins
    + This stage will execute only on Test Jenkins.
    + Check if there is any available free clusters with label: 'bob-ci-upgrade-ready'
    + If readyForUpgradeCount lower than 1, we have to start a new baseline-install job with 'wait: true' option
  + Prepare product baseline on Master Jenkins
    + This stage will execute only on Master Jenkins.
      + Cases when a new [eea-application-staging-product-baseline-install job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-product-baseline-install/) needs to be started:
        + when params.HELM_AND_CMA_VALIDATION_MODE != params.DEFAULT_BASELINE_INSTALL_MODE, than we have to wait till [eea-application-staging-product-baseline-install job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-product-baseline-install/) not finished
          + we will retry the [eea-application-staging-product-baseline-install job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-product-baseline-install/) install max 3 times until not passed
          + if the params.CUSTOM_CLUSTER_LABEL == ['bob-ci-upgrade-ready'](https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master/src/com/ericsson/eea4/ci/GlobalVars.groovy#8) than we set the {env.CUSTOM_CLUSTER_LABEL:
            + if we have upstream job than ["bob-ci-product-upgrade-"](https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master/src/com/ericsson/eea4/ci/GlobalVars.groovy#9)+UPSTREAM_JOB_NAME+UPSTREAM_JOB_BUILD_NUMBER, e.g.: "bob-ci-product-upgrade-eea-application-staging-nx1-upgrade-2135"
            + if self-triggered run than ["bob-ci-product-upgrade-"](https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master/src/com/ericsson/eea4/ci/GlobalVars.groovy#9)+env.JOB_NAME+env.BUILD_NUMBER, e.g: "bob-ci-product-upgrade-eea-product-prepare-upgrade-111111"
        + when params.CUSTOM_CLUSTER_LABEL != ["bob-ci-upgrade-ready"](https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master/src/com/ericsson/eea4/ci/GlobalVars.groovy#8) and we don't have free ['bob-ci-upgrade-ready'](https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master/src/com/ericsson/eea4/ci/GlobalVars.groovy#8) cluster
          + we will retry the [eea-application-staging-product-baseline-install job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-product-baseline-install/) install max 3 times until not passed
        + when summary of preinstalled cluster and ongoing [eea-application-staging-product-baseline-install job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-product-baseline-install/) nums not reached the baselineInstallMaximumJobCount which came from [cluster_lock_params.json](https://gerrit.ericsson.se/plugins/gitiles/EEA/eea4-ci-config/+/master/config/cluster_lock_params.json)
          + Get count of available free clusters with label: 'bob-ci-upgrade-ready' and store in readyForUpgradeCount variable
          + Get count number of the currently running [eea-application-staging-product-baseline-install job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-product-baseline-install/) and store in runningBaselineInstallJobCount variable
            + If readyForUpgradeCount + runningBaselineInstallJobCount lower than baselineInstallMaximumJobCount which came from [cluster_lock_params.json](https://gerrit.ericsson.se/plugins/gitiles/EEA/eea4-ci-config/+/master/config/cluster_lock_params.json)
          + In this case we won't wait until the [eea-application-staging-product-baseline-install](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-product-baseline-install/) will finished and result of it.
      + When the [eea-application-staging-product-baseline-install](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-product-baseline-install/) not failed than the final env.CUSTOM_CLUSTER_LABEL will be saved to artifact.properties which will used by upstream unbrella upgrade job, e.g.: [eea-application-staging-product-upgrade](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-product-upgrade/)
      + Case when call ["lockable-resource-label-change"](https://seliius27190.seli.gic.ericsson.se:8443/job/lockable-resource-label-change/)
        + when params.HELM_AND_CMA_VALIDATION_MODE == params.DEFAULT_BASELINE_INSTALL_MODE and params.CUSTOM_CLUSTER_LABEL != ['bob-ci-upgrade-ready'](https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master/src/com/ericsson/eea4/ci/GlobalVars.groovy#8) and we have free ["bob-ci-upgrade-ready"](https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master/src/com/ericsson/eea4/ci/GlobalVars.groovy#8) cluster
          + than we are chnage a cluster label to params.CUSTOM_CLUSTER_LABEL and will use that cluster during the upgrade
  + Executed job name: [eea-application-staging-product-baseline-install](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-product-baseline-install/)
  + Executed job doc [link](https://eteamspace.internal.ericsson.com/display/ECISE/Application+staging+product-baseline+install)

## Time based execution

To have proper number of preinstalled product-baseline cluster we need to start this from a cron based job also.
The executer Jenkins job: [eea-product-prepare-upgrade-scheduler](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-prepare-upgrade-scheduler/)
This job will start at every 15 minutes and will execute 'eea-product-prepare-upgrade' job on the Master Jenkins only (to avoid paralell execution in Master and Test Jenkins).
