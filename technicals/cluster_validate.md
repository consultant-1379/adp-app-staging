# Cluster validation

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Situations when validation is needed

Cluster validation is necessary in some situations before the cluster can be added to the 'bob-ci' pool which is used for running the Product CI loops. Situations include:

* after installation
* after upgrade
* when there is a suspected problem with the cluster
* when the cluster was borrowed
* etc.

## Validation Job

The Jenkins job [cluster_validate](https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-validate/) can be used to validate the needed cluster. There are some parameters:

* CLUSTER Cluster to validate - credential ID neededg
* AFTER_CLEANUP_DESIRED_CLUSTER_LABEL - The desired new resource label after successful Cluster cleanup run
* CHART_NAME Chart name e.g.: eric-ms-b
* CHART_REPO Chart repo e.g.: [https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm]
* CHART_VERSION Chart version e.g.: 1.0.0-1
* INT_CHART_NAME Internal chart name e.g eric-eea-int-helm-chart
* INT_CHART_REPO Chart repo e.g.: [https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/]
* INT_CHART_VERSION Chart version e.g.: 1.0.0-1 default : latest
* SKIP_CLEANUP - skip the cleanup pipeline. Used when SKIP_COLLECT_LOG is false
* INT_CHART_NAME_META - Chart name e.g.: eric-eea-ci-meta-helm-chart
* INT_CHART_REPO_META - Chart repo e.g.: [https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/]
* INT_CHART_VERSION_META meta-baseline version to install. Format: 1.0.0-1
* BUILD_RESULT_WHEN_NELS_CHECK_FAILED - build result when the Check NELS availability failed default : FAILURE
* HELM_AND_CMA_VALIDATION_MODE - Use HELM values or HELM values and CMA configurations. valid options: ""  legacy mode, "true"  use helm values, cma is diabled, "false" use helm values and load CMA configurations
* BUILD_RESULT_WHEN_CMA_HEALTH_CHECK_FAILED build result when the CMA health check failed

## Validation Job Steps

The main steps of the validation are the following:

* deploying UTF and data-loader
* deploying the product with using next bob rules: init-mxe, init-eric-eea-analysis-system-overview-install, verify-values-files to check helm values from next lists (`values-list.txt, mxe-values-list.txt`) and k8s-test-splitted-values with next helm values (`helm-values/custom_environment_values.yaml,dataflow-configuration/all-VPs-configuration/refdata-values.yaml,dataflow-configuration/all-VPs-configuration/correlator-values.yaml,dataflow-configuration/all-VPs-configuration/aggregator-values.yaml,dataflow-configuration/all-VPs-configuration/db-loader-values.yaml,dataflow-configuration/all-VPs-configuration/db-manager-values.yaml,dataflow-configuration/all-VPs-configuration/dashboard-values.yaml,dataflow-configuration/all-VPs-configuration/irc-values.yaml,dataflow-configuration/all-VPs-configuration/pp-values.yaml,helm-values/custom_values_correlator_inc_weight_category.yml,helm-values/custom_values_correlator_pgwu.yml,helm-values/custom_dimensioning_values.yaml,helm-values/custom_deployment_values.yaml` from the master branch for install)
* run the Decisive Nx1 Staging UTF test
* run the [cluster-logcollector]((https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-logcollector/)) job which will upload collected logs to arm repo then will cleanup the cluster

## How to validate a cluster, step-by-step

1. Set the cluster label in Jenkins [Configuration](https://seliius27190.seli.gic.ericsson.se:8443/configure) > Lockable Resources Manager to something that is not used by any loops (the name doesn't matter).
2. In Jenkins [Lockable Resources](https://seliius27190.seli.gic.ericsson.se:8443/lockable-resources/), check that the cluster is unlocked and unreserved.
3. Run the '[cluster_validate](https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-validate/)' job, and supply the CLUSTER parameter (it can be copied from the Lockable Resources page).
4. If the validation is successful, and no more investigation is needed, don't forget to set the cluster label to 'bob-ci' or any label where the cluster is needed.

## CMA related stages and steps

See page [CMA configurations in product deployments](https://eteamspace.internal.ericsson.com/display/ECISE/CMA+configurations+in+product+deployments)
