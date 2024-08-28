# EEA4 Common ONLINE and OFFLINE Product Upgrade

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Description

This job is a common wrapper for all other jobs using product upgrade in the Product CI Loop.
It can be triggered from the following Spinnaker loops:

+ [EEA Application Staging](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-application-staging), for more details follow [this](https://eteamspace.internal.ericsson.com/display/ECISE/Information+about+eea-application-staging+loop+in+Product+CI) link.
+ [EEA Metabaseline Loop](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-product-ci-meta-baseline-loop), for more details follow [this](https://eteamspace.internal.ericsson.com/display/ECISE/Information+about+eea_product_ci_meta_baseline_loop+in+Product+CI) link.
+ [EEA ADP Staging](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-adp-staging), for more details follow [this](https://eteamspace.internal.ericsson.com/display/ECISE/Information+about+eea_adp_staging+loop+in+Product+CI) link.

## Jobs calling eea-common-product-upgrade

+ [eea-adp-staging-adp-nx1-loop-upgrade](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-adp-staging-adp-nx1-loop-upgrade/)
+ [eea-application-staging-product-upgrade](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-product-upgrade/)
+ [eea-application-staging-nx1-upgrade](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-nx1-upgrade/)
+ [eea-product-ci-meta-baseline-loop-upgrade](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-ci-meta-baseline-loop-upgrade/)
+ [eea-product-release-loop-bfu-gate-upgrade](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-release-loop-bfu-gate-upgrade/)

## Different version scenarios used by the specific upgrade pipelines

|Jenkins job-name                          | INSTALL version               | META version                        | UPGRADE version              |
|------------------------------------------|-------------------------------|-------------------------------------|------------------------------|
|eea-adp-staging-adp-nx1-loop-upgrade      | cnint latest_release git tag  | project-meta-baseline master latest | incoming param from Spinnaker|
|eea-application-staging-product-upgrade   | cnint latest_release git tag  | project-meta-baseline master latest | incoming param from Spinnaker|
|eea-application-staging-nx1-upgrade       | cnint latest_release git tag  | project-meta-baseline master latest | incoming param from Spinnaker|
|eea-product-ci-meta-baseline-loop-upgrade | cnint latest_release git tag  | incoming param from Spinnaker       | cnint master latest          |
|eea-product-release-loop-bfu-gate-upgrade | incoming param from Spinnaker | project-meta-baseline master latest | cnint master latest          |

## Jenkins job

This is a unified Jenkins job, which both supports ONLINE and OFFLINE upgrade and can be used in all the Product CI loops which requires upgrade testing.
The upgrade type is defined automatically based on the Jenkins job input parameters. If `INT_CHART_NAME_PRODUCT` specified, the upgrade type will be considered ONLINE, if `CSAR_VERSION` specified, the upgrade type will be considered OFFLINE.

The OFFLINE upgrade has a limitation, only 1 offline upgrade build can be executed per 1 Jenkins agent.

Job name: [eea-common-product-upgrade](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-common-product-upgrade/)

Diagram to display how the common-upgrade job interacts with the jenkins-docker: <https://eteamspace.internal.ericsson.com/display/ECISE/Common+Upgrade+Diagram>

## Parameters from eea_common_product_upgrade.groovy

+ DRY_RUN - This parameter is used to rebuild the job (without running its full logic) in case of change in parameters.
+ JENKINSFILE_GERRIT_REFSPEC - Git ref in EEA/adp-app-staging repo to technicals/eea_common_product_upgrade.Jenkinsfile for fetch from master or change test from refspec. Default is ${MAIN_BRANCH}, test E.g: refs/changes/80/16735380/3

## Parameters from eea_common_product_upgrade.Jenkinsfile

+ CHART_NAME - Chart name
+ CHART_REPO - Chart repo
+ CHART_VERSION - Chart version e.g.: 1.0.0-1
+ INT_CHART_NAME_PRODUCT - Integration Chart name, defaultValue: 'eric-eea-int-helm-chart'
+ INT_CHART_REPO_PRODUCT Integration Chart, defaultValue: <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-ci-internal-helm/>
+ INT_CHART_VERSION_PRODUCT - product-baseline version to upgrade
+ SEP_CHART_NAME - SEP helm chart name, defaultValue: 'eric-cs-storage-encryption-provider'
+ SEP_CHART_REPO - SEP helm chart repo, defaultValue: <https://arm.sero.gic.ericsson.se/artifactory/proj-adp-rs-storage-encr-released-helm>
+ NSEEA - EEA4 namespace, defaultValue: 'eric-eea-ns'
+ NSCRD - CRD namespace', defaultValue: 'eric-crd-ns'
+ UTF_PRODUCT_NAMESPACE' - UTF product namespace, defaultValue: 'eric-eea-ns'
+ CSAR_NAME - CSAR name, defaultValue: 'csar-package'
+ CSAR_REPO - CSAR repo, defaultValue: <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-generic-local/>
+ CSAR_VERSION - CSAR version, defaultValue: ''
DOCKER_EXECUTOR_IMAGE_NAME - jenkins-docker image name, defaultValue: <armdocker.rnd.ericsson.se/proj-eea-drop/eea-jenkins-docker>
+ DOCKER_EXECUTOR_IMAGE_VERSION - jenkins-docker image version
+ DEPLOYER_PSP_URL - DEPLOYER product specific pipeline package URL, defaultValue: <https://arm.seli.gic.ericsson.se/>
+ DEPLOYER_PSP_REPO - DEPLOYER product specific pipeline package arm repo, defaultValue: 'proj-eea-drop-generic-local'
+ DEPLOYER_PSP_NAME - DEPLOYER product specific pipeline package name, defaultValue: 'eea-deployer'
+ DEPLOYER_PSP_VERSION - DEPLOYER product specific pipeline package version
+ DEPLOYER_GERRIT_REFSPEC - EEA/deployer repo Gerrit Refspec
+ GERRIT_REFSPEC - Gerrit Refspec of the cnint
+ META_GERRIT_REFSPEC - Gerrit Refspec of the project-meta-baseline
+ PIPELINE_NAME - The spinnaker pipeline name, defaultValue: 'eea-application-staging'
+ SPINNAKER_TRIGGER_URL - Spinnaker pipeline triggering url
+ SPINNAKER_ID - The spinnaker execution's id
+ SKIP_COLLECT_LOG - skip the log collection pipeline
+ SKIP_CLEANUP - skip the cleanup pipeline
+ WAIT_FOR_CLUSTER_LOG_COLLECTOR_RESULT - Wait for cluster log collector job result to be sure that new docker images work properly
+ CLUSTER_NAME - The cluster that should be locked for upgrade
+ UPGRADE_CLUSTER_LABEL - The cluster resource label that should be locked for upgrade
+ CUSTOM_CLUSTER_LABEL - If CUSTOM_CLUSTER_LABEL is set, we have to set that label at the end of the pipeline executions, and FORCE skip the collect log and cleanup
+ lock_start - Locking start timestamp, will be overwritten
+ lock_end - Locking start timestamp, will be overwritten
+ INT_CHART_NAME_META - Meta Chart name, defaultValue: 'eric-eea-ci-meta-helm-chart'
+ INT_CHART_REPO_META - Meta Chart repo, defaultValue: <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/>
+ INT_CHART_VERSION_META - Meta version to install, defaultValue: 'latest'
+ DIMTOOL_OUTPUT_REPO_URL - The url of the artifactory for Dimensioning Tool output
+ DIMTOOL_OUTPUT_REPO - Repo of the Dimensioning Tool output file reachable eg. proj-eea-reports-generic-local/dimtool/prod_ci_artifacts/
+ DIMTOOL_OUTPUT_NAME - Dimensioning Tool output file name with prepare job folder name, which created the output. name e.g.: eea-application-staging-baseline-prepare-12695/eea4-dimensioning-tool-output.zip
+ DEPLOY_SH_BASH_ARGS - Optional argument(s) to pass when executing upgrade.sh
+ BUILD_RESULT_WHEN_NELS_CHECK_FAILED - Build result when the Check NELS availability failed, ['FAILURE', 'SUCCESS']
+ ADP_APP_STAGING_GERRIT_REFSPEC_FOR_SF_INSTALL - Gerrit refspec of the adp-app-staging. Will pass to Spotfire install job
+ HELM_AND_CMA_VALIDATION_MODE - Use HELM values or HELM values and CMA configurations. valid options ("true":  use helm values, cma is disabled / "false": use helm values and load CMA configurations)

## Steps

+ Define Jenkins agent label
  > If params.CSAR_VERSION is not set, the update type will be considered ONLINE, and the Jenkins agent with the productci label will be used
  > If CSAR_VERSION is set, the build will be executed, the update type will be considered OFFLINE, and the Jenkins agent to run the build will be determined using the [One build per one agent logic](#one-build-per-one-jenkins-agent)
  > The agent with the defined label will be locked for the build execution
+ Params DryRun check
+ Check params
+ Cleanup workspace
+ Build started message to gerrit
+ Checkout cnint master
+ Extract integration chart data
+ Checkout project-meta-baseline master
+ Ruleset change checkout
+ Checkout adp-app-staging
+ Check if port locking resource name exists
+ Resource locking
  + Wait for cluster
    > Wait for preinstalled free cluster with label defined in UPGRADE_CLUSTER_LABEL parameter, using default value: bob-ci-upgrade-ready
  + Lock
    + Log lock
    + Get installed baseline params from cluster
    + Set description (SpinnakerURL and versions)
    + Run health check before upgrade
    + Test tool and Spotfire deploy
      + UTF and data loader deploy
      + Execute spotfire deployment
    + Init vars and get charts
    + Check NELS availability
    + init UTF Test Variables
    + Execute Pre-activites-upgrade check
    + Upgrade Pre-activities
    + Get Jenkins jobs XML
    + Prepare upgrade values files
      + If the DIMTOOL_OUTPUT_NAME is set then download, extract and use the Dimensioning Tool output from there
      + If the DIMTOOL_OUTPUT_NAME isn't set then execute the Dimensioning Tool output generation. Input data come from master for that.
    + Get eric-eea-utils image from the cnint
    + Download CSAR package
    + Get cluster docker registry connection info
    + Get jenkins-docker image version
    + Run DinD and Jenkins docker
    + Get jenkins-cli.jar
    + Import data into Jenkins docker
    + Execute Ingestion
    + Execute Preparation
    + Execute Upgrade
    + Create stream-aggregator configmap
    + Run health check after upgrade
    + Link Spotfire platform to EEA
    + Run CheckSpotfirePlatform health check
    + Load config json to CM-Analytics (optional when HELM_AND_CMA_VALIDATION_MODE=false)
    + Run health checks after CM-Analytics config load (optional when HELM_AND_CMA_VALIDATION_MODE=false)
      + start these
        + clusterLogUtilsInstance.runHealthCheck
        + clusterLogUtilsInstance.runHealthCheckWithCMA
    + Call test job: Executes the [eea-common-product-test-after-deployment](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-common-product-test-after-deployment/) job
    + Post actions:
      + Remove DinD and Jenkins docker containers, volume and networks
      + Relabeling cluster
        + If CUSTOM_CLUSTER_LABEL parameter is not empty we will set the parameter value to the resource label.
      + Generating logs directories
  + Post actions:
    + Cluster log collection
      + If SKIP_COLLECT_LOG parameter is false we will collect logs from the test environment using ADP log collector from a separated job. /wait for result: false/
      + Job name: [cluster-logcollector](https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-logcollector)
      + Job doc [link](https://eteamspace.internal.ericsson.com/display/ECISE/Cluster+Log+Collector)
      + SKIP_CLEANUP parameter is passed to the logcollector job and depending it's value will execute the cleanup procedure of the eea4 product namespace, utf namespace and the used CRDs from the test environment from a separated job.
+ Archive artifact.properties
+ Post actions:
  + Send Gerrit message
  + cleanWs()
  + [Remove offline upgrade label from the agent](#jenkins-agent-label-cleanup)

## One build per One Jenkins agent

One build per One Jenkins agent flow:

+ Lock set-offline-common-upgrade-label
  > This resource locking is needed to avoid a situation where one Jenkins agent is reserved for two different builds. Resource locking will not allow to start defining a label at the same time, the process will be performed one by one
  + Define parralel Jenkins URL
    > In Product CI we have Live and Test Jenkins instances, who have shared Jenkins agents. So when running on test Jenkins we should get information about labels for agents in Live Jenkins and vice versa
  + Define label for the build
    > The label for the build is defined with this pattern `common-offline-upgrade-${env.JOB_NAME}-${env.BUILD_NUMBER}`
  + Get busy agents from the parrallel Jenkins
    > If agent on the parralel Jenkins contains `common-offline-upgrade-*` label it can't be used for the upgrade on the current Jenkins
  + Get agents from the current Jenkins
    > Get online agents, which contains productci label, and doesn't contain `common-offline-upgrade-*` label
  + Set label for the agent
    > If an agent matching the conditions has been found, it will be assigned a label generated in previous step
    > If an agent matching the conditions was not found, a new agent search will occur every 5 minutes until an agent is found

## Jenkins agent label cleanup

Jenkins job: <https://seliius27190.seli.gic.ericsson.se:8443/job/cleanup-jenkins-agent-label/>

## Parameters

+ LABEL_TO_REMOVE_LIST - Comma-separated list of labels to remove from the Jenkins agent. E.g: label-1,label-2,label-n
+ JENKINS_AGENTS_LIST - Comma-separated list of Jenkins agent to remove label from. E.g; agent-1,agent-2,agent-n

## Steps

+ Params DryRun check
+ Check upstream build
  > Generates offline upgrade label to remove from the agents based on the upstream build `common-offline-upgrade-${env.UPSTREAM_PROJECT_NAME}-${env.UPSTREAM_PROJECT_BUILD_NUMBER}`
+ Check variables
  > Skipped if `eea-common-product-upgrade` upstream build was found
+ Remove labels from the agents

## Cluster status logs location

Cluster logs will be uploaded to arm repo and links for that will be available for every pipelines in the Jenkins page info.
e.g.: [Cluster logs](https://arm.seli.gic.ericsson.se/artifactory/proj-eea-reports-generic-local/clusterlogs/)

The log folder link to arm repo may not be available immediately right after running the job (even for success or fail results), as logcollect can take up to 6-10 minutes. So when you click on the link and get a "404" error, you need to try a little bit later again.

## Cluster status logs naming convention

The collect-logs-from-cluster bob rule executes the [data_collector.sh](https://arm.sero.gic.ericsson.se/artifactory/proj-adp-data-collector-released-generic-local/adp-data-collector/) script on the target cluster which collects logfiles and HELM chart configuration from the Kubernetes cluster.\
We collect cluster logs after these steps using the following naming convention for them:

+ CRD Upgrade
  + crd-upgrade.log: bob k8s-test:download-extract-chart, bob k8s-test:package-helper-chart, bob k8s-test-crd
    + INT_CHART_VERSION: upgraded version e.g. 4.2.2-45-h0ebf3e9
+ SEP Install at Upgrade
  + sep-install-at-upgrade.log: bob k8s-test-sep-upgrade -r bob-rulesets/upgrade.yaml
    + SEP_CHART_VERSION: upgraded eric-cs-storage-encryption-provider version from eric-eea-int-helm-chart/Chart.yaml
+ Product services upgrade
  + product_service_upgrade_log_collector.log: bob collect-logs-from-cluster
  + product_service_upgrade_utf_log_collector.log: bob collect-utf-logs-from-cluster
  + `product_service_upgrade_INT_CHART_VERSION_logs_eric-eea-ns_TIMESTAMP.tgz`: collect-logs-from-cluster result, e.g.: product_service_upgrade_4.2.2-45-h0ebf3e9_logs_eric-eea-ns_2022-02-08-17-42-03.tgz
    + INT_CHART_VERSION: upgraded version e.g. 4.2.2-45-h0ebf3e9
    + TIMESTAMP: when the logs collect run
  + service-upgrade-configvalues.tar.gz: helm config values collected by archiveFilesFromLog()
+ Product config upgrade
  + product_config_upgrade_log_collector.log: bob collect-logs-from-cluster
  + product_config_upgrade_utf_log_collector.log: bob collect-utf-logs-from-cluster
  + `product_config_upgrade_INT_CHART_VERSION_logs_eric-eea-ns_TIMESTAMP.tgz`: collect-logs-from-cluster result, e.g.: product_config_upgrade_4.2.2-45-h0ebf3e9_logs_eric-eea-ns_2022-02-08-18-18-58.tgz
    + INT_CHART_VERSION: upgraded version e.g. 4.2.2-45-h0ebf3e9
    + TIMESTAMP: when the logs collect run
  + config-upgrade-configvalues.tar.gz: helm config values collected by archiveFilesFromLog()
  + software-upgrade-values.tgz: helm values which are used during EEA4 relaese Software upgrade
  + mxe-software-upgrade-values.tgz: helm values which are used during MXE Software upgrade
  + config-upgrade-values.tgz:  helm values which are used during EEA4 release Config upgrade
  + mxe-config-upgrade-values.tgz: helm values which are used during MXE Config upgrade

## Jenkins job logging

+ Stages logging implemented with Jenkins tee
  + It will add to the log every single command output executed inside the stage and display it the output in the Console Log at the same time
  + Example

```
stage('Stage name') {
    steps {
        tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
            script {
                ...
            }
        }
    }
    post {
        always {
            script {
                archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
            }
        }
    }
}
```

+ In case the command output is quite large and makes the console log unreadable, we need to redirect the output to a separate file
  + Example

```
stage('Stage name') {
    steps {
        tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
            script {
                try {
                    sh 'bob/bob rule-with-large-output > large-output.log'
                }
                catch(err) {
                    echo "Caught: ${err}"
                    error "${STAGE_NAME} FAILED".toUpperCase()
                }
                finally {
                    archiveArtifacts artifacts: "large-output.log", allowEmptyArchive: true
                }
            }
        }
    }
    post {
        always {
            script {
                archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
            }
        }
    }
}
```

## Method too large error avoiding

+ Due to the large size of the job, the contents of the stages must be moved to a separate function, and the new function must be called from the stage
  + Example

```
pipeline {
    stages {
        stage('Stage name') {
            steps {
                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                    functionForTheStage()
                }
            }
            post {
                always {
                    script {
                        archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                    }
                }
            }
        }
    }
}

void functionForTheStage() {
    script {
        try {
            sh '''
                echo "My very important script"
            '''
        } catch(err) {
            echo "Caught: ${err}"
            error "${STAGE_NAME} FAILED".toUpperCase()
        }
    }
}
```

## Jenkins docker jobs

## eea-software-ingestion

Jenkinsfile: <https://gerrit.ericsson.se/plugins/gitiles/EEA/deployer/+/master/jenkins/eea_software_ingestion.Jenkinsfile>
During the Jenkins job xml generation the [eea-jenkins-docker-xml-generator](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-jenkins-docker-xml-generator) job extend the eea-software-ingestion file name with DEPLOYER version, e.g: eea-software-ingestion-0.3.1-11.xml
The version job will be imported to the dockerized Jenkins.

## Parameters

+ PACKAGED_CSAR_LOCATION_PATH - The path of the directory where *.csar is stored, defaultValue: '/deployer-workspace'
+ UPGRADE_SCRIPTS_DIRECTORY_PATH - The path of the directory where upgrade scripts are stored, defaultValue: '/deployer-workspace/eea-deployer/product/scripts'
+ CSAR_PACKAGE_DIRECTORY_PATH - The path of the directory where the CSAR package is stored
+ KUBE_CONFIG_FILE - Kubernetes config file, defaultValue: '/local/.kube/config'
+ SKIP_PREPARE_WORKSPACE_STAGE - Skip "Prepare workspace" stage
+ SKIP_UNPACK_CSAR_STAGE - Skip "Unpack csar package" stage
+ SKIP_HEALTHCHECK_STAGE - Skip "Healthcheck" stage

## Steps

+ Params DryRun check
+ Prepare workspace
  > Create directories structure, copy scripts and give permissions
+ Unpack csar package
+ Healthcheck
  > Simple check to verify, that we have connection to the cluster

## eea-software-preparation

Jenkinsfile: <https://gerrit.ericsson.se/plugins/gitiles/EEA/deployer/+/master/jenkins/eea_software_preparation.Jenkinsfile>
During the Jenkins job xml generation the [eea-jenkins-docker-xml-generator](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-jenkins-docker-xml-generator) job extend the eea-software-preparation file name with DEPLOYER version, e.g: eea-software-preparation-0.3.1-11.xml
The version job will be imported to the dockerized Jenkins.

## Parameters

+ CSAR_PACKAGE_DIRECTORY_PATH - The path of the directory where the CSAR package is stored
+ NSEEA - EEA4 namespace, defaultValue: 'eric-eea-ns'
+ NSCRD - CRD namespace, defaultValue: 'eric-crd-ns'
+ IMAGE_PULLSECRET - Secret for pulling images from registry, defaultValue: 'local-pullsecret'
+ DOCKER_REGISTRY - URL of the Docker container registry, defaultValue: 'k8s-registry.eccd.local'
+ DOCKER_REGISTRY_JENKINS_CREDENTIAL_NAME - Jenkins credential name to connect to the container registry, defaultValue: 'container-registry'
+ DOCKER_PATH - The path of the docker binary to use, defaultValue: '/usr/local/bin/docker'
+ DOCKER_CONFIG_FILE - Docker config.json file, defaultValue: '$HOME/.docker/config.json'
+ KUBE_CONFIG_FILE - 'Kubernetes config file, defaultValue: '/local/.kube/config'
+ SKIP_CONFIGURE_DOCKER_REGISTRY_STAGE - Skip "Upload images" stage
+ SKIP_UPLOAD_IMAGES_STAGE - Skip "Upload images" stage

## Steps

+ Skip "Upload images" stage
+ Skip "Upload images" stage
+ Upload images
  + Post
    + always: archive stage logs

## eea-software-upgrade

Jenkinsfile: <https://gerrit.ericsson.se/plugins/gitiles/EEA/deployer/+/master/jenkins/eea_software_upgrade.Jenkinsfile>
During the Jenkins job xml generation the [eea-jenkins-docker-xml-generator](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-jenkins-docker-xml-generator) job extend the eea-software-upgrade file name with DEPLOYER version, e.g: eea-software-upgrade-0.3.1-11.xml-0.3.1-11.xml
The version job will be imported to the dockerized Jenkins.

## Parameters

+ ONLINE_UPGRADE_SOURCE_DIRECTORY - The path of the directory where online-upgrade related package is stored
+ UPGRADE_SCRIPTS_DIRECTORY_PATH - The path of the directory where online-upgrade related scripts are stored
+ CSAR_PACKAGE_DIRECTORY_PATH - The path of the directory where the CSAR package is stored
+ DOCKER_PATH - The path of the docker binary to use, defaultValue: '/usr/local/bin/docker'
+ KUBECTL_PATH - The path of the kubectl binary to use, defaultValue: '/usr/local/bin/kubectl'
+ HELM_PATH - The path of the helm binary to use, defaultValue: '/usr/local/bin/helm'
+ KUBE_CONFIG_FILE - Kubernetes config file, defaultValue: '/local/.kube/config'
+ IMAGE_PULLSECRET - Secret for pulling images from registry, defaultValue: 'local-pullsecret'
+ DOCKER_REGISTRY - URL of the Container registry, defaultValue: 'k8s-registry.eccd.local'
+ NSEEA - EEA4 namespace, defaultValue: 'eric-eea-ns'
+ NSCRD - CRD namespace, defaultValue: 'eric-crd-ns'
+ SEP_UPGRADE_VALUES_FILES_PATH - The path of the directory where all custom configuration (yaml files are stored for sep upgrade), defaultValue: '/deployer-workspace/helm-values'
+ SEP_VALUES_FILE - SEP values file name to use for SEP upgrade, defaultValue: 'sep_values.yaml'
+ SEP_ENVIRONMENT_VALUES_FILE - Environment values file name to use for SEP upgrade, defaultValue: 'custom_environment_values.yaml'
+ EEA_SOFTWARE_UPGRADE_VALUES_FILES_PATH - The path of the directory where all custom configuration (yaml files for the EEA software upgrade are stored), defaultValue: '/software-upgrade-values'
+ EEA_CONFIGURATION_UPGRADE_VALUES_FILES_PATH - The path of the directory where all custom configuration (yaml files for the EEA Configuration upgrade are stored), defaultValue: '/config-upgrade-values'
+ PATCH_KAFKA_FOR_TLS_PROXY - Execute patch_kafka_for_tls_proxy step during EEA Configuration upgrade
+ PATH_TO_CUSTOM_VALUES_FILES - The path of the directory where all custom configuration (yaml files are stored for upgrade_tls_proxies, patch_kafka_for_tls_proxy)
+ TLS_PROXY_UPGRADE_BOOTSTRAP_FILE - Name of the configuration (yaml file for upgrading TLS Proxy bootstrap server)
+ TLS_PROXY_UPGRADE_BROKER_FILES - Comma seprated names of the configuration (yaml files for upgrading TLS Proxy broker servers)
+ TLS_PROXY_BASE_NAME_OVERRIDE - Name to be used for helm parameter nameOverride for TLS Proxy deployment
+ TLS_PROXY_KAFKA_STATEFULSET_PATCH_FILE - Name of the patch file for patching eric-data-message-bus-kf statefulset'
+ TLS_PROXY_KAFKA_SERVICE_PATCH_FILE - Name of the patch file for patching eric-data-message-bus-kf service'
+ MXE_SOFTWARE_UPGRADE_VALUES_FILES_PATH - The path of the directory where all custom configuration (yaml files for the MXE software upgrade are stored), defaultValue: '/mxe-software-upgrade-values'
+ MXE_CONFIGURATION_UPGRADE_VALUES_FILES_PATH - The path of the directory where all custom configuration (yaml files for the MXE Configuration upgrade  are stored), defaultValue: '/mxe-config-upgrade-values'
+ ONLINE_UPGRADE - Enable if the online upgrade will be executed
+ SKIP_PREPARE_UPGRADE_WORKSPACE_STAGE - Skip "Prepare upgrade workspace" stage
+ SKIP_CRDS_UPGRADE_STAGE - Skip "CRDs upgrade" stage
+ SKIP_SEP_UPGRADE_STAGE - Skip "SEP upgrade" stage
+ SKIP_EEA_SW_UPGRADE_STAGE - Skip "EEA Software upgrade" stage
+ SKIP_EEA_CONFIG_UPGRADE_STAGE - Skip "EEA Configuration upgrade" stage
+ SKIP_TLS_PROXIES_UPGRADE_STAGE - Skip "TLS proxies upgrade"
+ SKIP_MXE_SW_UPGRADE_STAGE - Skip "MXE Software upgrade" stage
+ SKIP_MXE_CONFIG_UPGRADE_STAGE - Skip "MXE Configuration upgrade" stage
+ UPGRADE_SH_BASH_ARGS - Optional argument(s) to pass when executing upgrade.sh. E.g. -x can be used for debugging purposes

## Configurations

You can configure the timeout in [deployment_configs.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/deployer/+/master/product/source/pipeline_package/eea-deployer/product/scripts/deployment_configs.yaml)

+ software_upgrade_timeout: software upgrade timeout for one EEA release (EEA4 release or MXE release). Overall time can reach max 2xsoftware_upgrade_timeout (90m)
+ software_upgrade_helm_timeout: software upgrade HELM timeout. Must be less than software_upgrade_timeout
+ config_upgrade_timeout: config upgrade timeout for one EEA release (EEA4 release or MXE release). Overall time can reach max config_upgrade_timeout (90m)
+ config_upgrade_helm_timeout: config upgrade HELM timeout. Must be less than software_upgrade_timeout
+ sep_upgrade_helm_timeout: Upgrading Storage Encryption Provider helm timeout
+ tls_proxies_upgrade_helm_timeout: Upgrading TLS Proxies helm timeout
+ eric_data_message_bus_kf_kubectl_timeout: Waiting timeout for eric-data-message-bus-kf statefulset to be Ready

## Steps

+ Params DryRun check
+ Prepare upgrade workspace
  + Post
    + always: archive stage logs
+ CRDs upgrade
  + Post
    + always: archive stage logs
+ SEP upgrade
  + Post
    + always: archive stage logs
+ EEA Software upgrade
  + Post
    + always: archive stage logs
+ EEA Configuration upgrade
  + Post
    + always: archive stage logs
+ TLS proxies upgrade
+ MXE Software upgrade
  + Post
    + always: archive stage logs
+ MXE Configuration upgrade
  + Post
    + always: archive stage logs

## eea-software-validation-and-verification

The job currently is not used!

Jenkinsfile: <https://gerrit.ericsson.se/plugins/gitiles/EEA/deployer/+/master/jenkins/eea_software_validation_and_verification.Jenkinsfile>

## Port locking stages

The following lockable resource needs to be defined for each build node which has the `productci` label on the Jenkins.

```
JENKINS_PORT_LOCKING = "${env.NODE_NAME}" + "-port-reservation"
e.g: selieea0032-port-reservation
```

+ Check if port locking resource name exists: This steps check is the lockable-resorce name exists for the jenkins build node.
+ Run DinD and Jenkins docker: It checks if the lockable resource released by the previous job in 10 seconds and  locks it for the execution of this stage.
