@Library('ci_shared_library_eea4') _

import groovy.transform.Field

import com.ericsson.eea4.ci.GlobalVars
import com.ericsson.eea4.ci.ClusterLockUtils

@Field def vars = new GlobalVars()

@Field def CMA_MODE__HELM_VALUES = "true"
@Field def CMA_MODE__HELM_VALUES_AND_CMA_CONF = "false"

@Field def CMA_MODE_IS_HELM = "HELM"
@Field def CMA_MODE_IS_HELM_AND_CMA = "HELM_AND_CMA"

@Field def DEFAULT_BASELINE_INSTALL_MODE_IS_HELM = 'HELM'
@Field def DEFAULT_BASELINE_INSTALL_MODE_IS_HELM_AND_CMA = 'HELM_AND_CMA'

def COLOR_RED='\033[31m'
def COLOR_GREEN='\033[32m'
def COLOR_YELLOW='\033[33m'
def COLOR_BLUE='\033[34m'
def COLOR_BOLD='\033[1m'
def COLOR_NORMAL='\033[0m'
def COLOR_FRAMED='\033[51m'

def BASELINE_INSTALL_MAX_RETRY = 3

pipeline {
    options {
        skipDefaultCheckout()
        buildDiscarder(logRotator(daysToKeepStr: '7', artifactDaysToKeepStr: '7'))
        ansiColor('xterm')
    }
    agent {
        node {
            label 'productci'
        }
    }

    parameters {
        string(name: 'GIT_BRANCH', description: 'Gerrit git branch of the integration chart git repo e.g.: eea4_4.4.0_pra . If the value is latest than calculate the branch name using the latest pra git tag', defaultValue: 'latest')
        string(name: 'BASELINE_UPGRADE_CLUSTER_LABEL', description: "Upgrade ready resource label name e.g.: bob-ci-upgrade-ready", defaultValue: "${vars.resourceLabelUpgrade}")
        string(name: 'SPINNAKER_ID', description: "The spinnaker execution's id", defaultValue: '')
        string(name: 'PIPELINE_NAME', description: "The spinnaker pipeline name", defaultValue: 'eea-application-staging')
        string(name: 'CUSTOM_CLUSTER_LABEL', description: 'Should be overriden based on HELM_AND_CMA_VALIDATION_MODE value. If CUSTOM_CLUSTER_LABEL is set, we have to set that label at the end of the pipeline executions, and FORCE skip the cleanup !!!', defaultValue: "${vars.resourceLabelUpgrade}")
        string(name: 'HELM_AND_CMA_VALIDATION_MODE',
        description: """
        Use HELM values or HELM values and CMA configurations. valid options:
<table>
  <tr>
    <th>Value</th>
    <th ALIGN=left>Comment</th>
  </tr>
  <tr>
    <td>"true" or "HELM"</td>
    <td>use helm values, cma is diabled</td>
  </tr>
  <tr>
    <td>"false" or "HELM_AND_CMA"</td>
    <td>use helm values and load CMA configurations</td>
  </tr>
</table>
            """,
        defaultValue: 'HELM_AND_CMA')
        choice(name: 'DEFAULT_BASELINE_INSTALL_MODE', choices: [DEFAULT_BASELINE_INSTALL_MODE_IS_HELM_AND_CMA, DEFAULT_BASELINE_INSTALL_MODE_IS_HELM], description: 'What is the default value of HELM_AND_CMA_VALIDATION_MODE during eea-application-staging-product-baseline-install')
        string(name: 'WAIT_FOR_BASELINE_INSTALL', description: 'Should be overriden based on HELM_AND_CMA_VALIDATION_MODE value. Wait for eea-application-staging-product-baseline-install', defaultValue: "false")
    }

    environment {
        EEA_APPLICATION_STAGING_PRODUCT_BASELINE_INSTALL_JENKINS_JOB = "eea-application-staging-product-baseline-install"
        LOCKABLE_RESOURCE_LABEL_CHANGE_JENKINS_JOB = "lockable-resource-label-change"
    }

    stages {
        stage('Params DryRun check') {
            when {
                expression { params.DRY_RUN == true }
            }
            steps {
                script {
                    dryRun()
                }
            }
        }


        stage('Prepare product baseline on Test Jenkins') {
            when {
                expression { env.MAIN_BRANCH != 'master'}
            }
            steps {
                script {

                    echo "Check if there is any available free clusters with label: ${params.BASELINE_UPGRADE_CLUSTER_LABEL}"
                    def lockableResourceInstance = new ClusterLockUtils(this)

                    readyForUpgrade = lockableResourceInstance.getFreeClusterCount(params.BASELINE_UPGRADE_CLUSTER_LABEL)
                    readyForUpgradeCount = readyForUpgrade.size()

                    if ( readyForUpgradeCount < 1 ) {
                        echo "readyForUpgradeCount: ${readyForUpgradeCount} < 1 --> start new baseline-install"
                        try {
                            build job: "${env.EEA_APPLICATION_STAGING_PRODUCT_BASELINE_INSTALL_JENKINS_JOB}", parameters: [
                                booleanParam(name: 'DRY_RUN', value: false),
                                stringParam(name: "GIT_BRANCH", value: params.GIT_BRANCH),
                                stringParam(name: "SPINNAKER_ID", value: params.SPINNAKER_ID),
                                stringParam(name: "PIPELINE_NAME", value: params.PIPELINE_NAME),
                                stringParam(name: "CUSTOM_CLUSTER_LABEL", value: params.CUSTOM_CLUSTER_LABEL),
                                stringParam(name: "HELM_AND_CMA_VALIDATION_MODE", value: params.HELM_AND_CMA_VALIDATION_MODE),
                                booleanParam(name: "SKIP_CLEANUP", value: true)
                            ], wait: true
                        } catch (err) {
                            echo "Caught: ${err}"
                            error "${env.EEA_APPLICATION_STAGING_PRODUCT_BASELINE_INSTALL_JENKINS_JOB} FAILED"
                        }
                    } else {
                        echo "readyForUpgradeCount: ${readyForUpgradeCount} >= 1 --> skip baseline-install"
                    }
                    sh """ echo "CUSTOM_CLUSTER_LABEL=${env.CUSTOM_CLUSTER_LABEL}" > artifact.properties"""
                    archiveArtifacts artifacts: 'artifact.properties', allowEmptyArchive: true
                }
            }
        }

        stage('Prepare product baseline on Master Jenkins') {
            when {
                expression { env.MAIN_BRANCH == 'master'}
            }
            steps {
                script {
                    currentBuild.description = ''
                    if ( params.SPINNAKER_ID != '' ) {
                        currentBuild.description += '<br>Spinnaker URL: <a href="https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/details/' + params.SPINNAKER_ID + '">' + params.SPINNAKER_ID + '</a>'
                    }
                    if ( params.HELM_AND_CMA_VALIDATION_MODE != '' ) {
                        currentBuild.description += "<br>HELM_AND_CMA_VALIDATION_MODE: ${HELM_AND_CMA_VALIDATION_MODE} <i><br>  - true or HELM: use helm values, cma is disabled<br>  - false or HELM_AND_CMA: use helm values and load CMA configurations)</i>"
                    }
                    if ( params.CUSTOM_CLUSTER_LABEL != '' ) {
                        currentBuild.description += "<br>CUSTOM_CLUSTER_LABEL: ${CUSTOM_CLUSTER_LABEL}"
                    }

                    echo "Check if there is any available free clusters with label: ${params.BASELINE_UPGRADE_CLUSTER_LABEL}"
                    def lockableResourceInstance = new ClusterLockUtils(this)
                    lockableResourceInstance.downloadClusterLockParams()
                    lockableResourceInstance.initClusterLockParamsFromFile()
                    lockableResourceInstance.processClusterLockParams(params.PIPELINE_NAME, "${env.EEA_APPLICATION_STAGING_PRODUCT_BASELINE_INSTALL_JENKINS_JOB}") //Must be used the original job

                    int baselineInstallMaximumJobCount =  lockableResourceInstance.getMaximumJobCount()
                    echo COLOR_BOLD + "params.PIPELINE_NAME: \"${params.PIPELINE_NAME}\" ${env.EEA_APPLICATION_STAGING_PRODUCT_BASELINE_INSTALL_JENKINS_JOB} baselineInstallMaximumJobCount: ${baselineInstallMaximumJobCount}" + COLOR_NORMAL
                    echo COLOR_BOLD + "params.CUSTOM_CLUSTER_LABEL: \"${CUSTOM_CLUSTER_LABEL}\" params.HELM_AND_CMA_VALIDATION_MODE:\"${HELM_AND_CMA_VALIDATION_MODE}\" params.DEFAULT_BASELINE_INSTALL_MODE:\"${DEFAULT_BASELINE_INSTALL_MODE}\"" + COLOR_NORMAL

                    def freeReadyForUpgrade = lockableResourceInstance.getFreeClusterCount(params.BASELINE_UPGRADE_CLUSTER_LABEL)
                    def freeReadyForUpgradeCount = freeReadyForUpgrade.size()
                    def baselineInstallRetries = 1

                    def runningBaselineInstallJobCount = getRunningJobCount("${env.EEA_APPLICATION_STAGING_PRODUCT_BASELINE_INSTALL_JENKINS_JOB}", "${vars.resourceLabelCommon}") //Must be used the original job
                    echo COLOR_BOLD + "freeReadyForUpgradeCount: ${freeReadyForUpgradeCount} runningBaselineInstallJobCount: ${runningBaselineInstallJobCount}" + COLOR_NORMAL

                    def startProductBaselineInstallJob = false

                    if ( params.HELM_AND_CMA_VALIDATION_MODE != params.DEFAULT_BASELINE_INSTALL_MODE ) {
                        echo COLOR_GREEN +"startProductBaselineInstallJob True params.HELM_AND_CMA_VALIDATION_MODE:\"${params.HELM_AND_CMA_VALIDATION_MODE}\" != params.DEFAULT_BASELINE_INSTALL_MODE:\"${params.DEFAULT_BASELINE_INSTALL_MODE}\"  " + COLOR_NORMAL
                        startProductBaselineInstallJob = true
                        env.WAIT_FOR_BASELINE_INSTALL = true
                        baselineInstallRetries = BASELINE_INSTALL_MAX_RETRY
                        if ( params.CUSTOM_CLUSTER_LABEL == "${vars.resourceLabelUpgrade}" ) {
                                env.UPSTREAM_JOB_NAME = getLastUpstreamBuildEnvVarValue('JOB_NAME', env.JOB_NAME).trim()
                                env.UPSTREAM_JOB_BUILD_NUMBER = getLastUpstreamBuildEnvVarValue('BUILD_NUMBER', env.BUILD_NUMBER).trim()
                                env.CUSTOM_CLUSTER_LABEL = "${vars.resourceLabelUpgradePrefix}${env.UPSTREAM_JOB_NAME}-${env.UPSTREAM_JOB_BUILD_NUMBER}"
                                echo COLOR_BOLD + COLOR_GREEN +  "CUSTOM_CLUSTER_LABEL has been changed to: ${env.CUSTOM_CLUSTER_LABEL}" + COLOR_NORMAL
                        }

                    } else { //params.HELM_AND_CMA_VALIDATION_MODE == params.DEFAULT_BASELINE_INSTALL_MODE
                        if ( params.CUSTOM_CLUSTER_LABEL != "${vars.resourceLabelUpgrade}" ) {
                            if ( freeReadyForUpgradeCount > 0 ) {
                                echo  COLOR_FRAMED + COLOR_BOLD +  "${env.LOCKABLE_RESOURCE_LABEL_CHANGE_JENKINS_JOB} will executed. params.CUSTOM_CLUSTER_LABEL: \"${params.CUSTOM_CLUSTER_LABEL}\" != \"${vars.resourceLabelUpgrade}\" " + COLOR_NORMAL
                                echo "We can use one from preinstalled clusters"
                                lock(resource: null, label: "${vars.resourceLabelUpgrade}", quantity: 1, variable: 'CLUSTER_NAME') {
                                    echo "Will use the ${CLUSTER_NAME} with ${params.CUSTOM_CLUSTER_LABEL} for upgrade"
                                    build job: "${env.LOCKABLE_RESOURCE_LABEL_CHANGE_JENKINS_JOB}", parameters: [
                                        booleanParam(name: 'DRY_RUN', value: false),
                                        stringParam(name: 'DESIRED_CLUSTER_LABEL', value : "${params.CUSTOM_CLUSTER_LABEL}"),
                                        stringParam(name: 'CLUSTER_NAME', value : "${CLUSTER_NAME}"),
                                        booleanParam(name: 'RESOURCE_RECYCLE', value: false)
                                    ], wait: true
                                }
                            } else {
                                startProductBaselineInstallJob = true
                                env.WAIT_FOR_BASELINE_INSTALL = true
                                baselineInstallRetries = BASELINE_INSTALL_MAX_RETRY
                            }
                        } else { //params.CUSTOM_CLUSTER_LABEL == "${vars.resourceLabelUpgrade}"
                            def ongoingAndFreeUpgradeClusters = freeReadyForUpgradeCount + runningBaselineInstallJobCount
                            if (ongoingAndFreeUpgradeClusters < baselineInstallMaximumJobCount ) {
                                startProductBaselineInstallJob = true
                            } else {
                                echo  COLOR_YELLOW + COLOR_BOLD + "startProductBaselineInstallJob skipped because  runningBaselineInstallJobCount: ${runningBaselineInstallJobCount} + freeReadyForUpgradeCount ${freeReadyForUpgradeCount} (${ongoingAndFreeUpgradeClusters} )  >= baselineInstallMaximumJobCount: ${baselineInstallMaximumJobCount} " + COLOR_NORMAL
                            }
                        }
                    }

                    echo COLOR_FRAMED + COLOR_BOLD + "startProductBaselineInstallJob: \"${startProductBaselineInstallJob}\"  baselineInstallRetries:\"${baselineInstallRetries}\" env.WAIT_FOR_BASELINE_INSTALL:\"${env.WAIT_FOR_BASELINE_INSTALL}\"  env.CUSTOM_CLUSTER_LABEL: \"${env.CUSTOM_CLUSTER_LABEL}\" " + COLOR_NORMAL
                    if( startProductBaselineInstallJob ) {
                        echo "\"${env.EEA_APPLICATION_STAGING_PRODUCT_BASELINE_INSTALL_JENKINS_JOB}\" started..... "

                        def baselineInstallBuildJobResult = "NOT_EXECUTED"
                        def baselineInstallRuns = 0
                        while(  ( baselineInstallRuns < baselineInstallRetries ) && ( baselineInstallBuildJobResult != "SUCCESS" ) ) {
                            echo "baselineInstallRuns: ${baselineInstallRuns} from baselineInstallRetries ${baselineInstallRetries} "
                            baselineInstallRuns += 1
                            def baselineInstallBuild = build job: "${env.EEA_APPLICATION_STAGING_PRODUCT_BASELINE_INSTALL_JENKINS_JOB}", parameters: [
                                booleanParam(name: 'DRY_RUN', value: false),
                                stringParam(name: "GIT_BRANCH", value: params.GIT_BRANCH),
                                stringParam(name: "SPINNAKER_ID", value: params.SPINNAKER_ID),
                                stringParam(name: "PIPELINE_NAME", value: params.PIPELINE_NAME),
                                stringParam(name: "CUSTOM_CLUSTER_LABEL", value: env.CUSTOM_CLUSTER_LABEL),
                                stringParam(name: "HELM_AND_CMA_VALIDATION_MODE", value: params.HELM_AND_CMA_VALIDATION_MODE),
                                booleanParam(name: "SKIP_CLEANUP", value: true)
                            ],  propagate: false, wait: env.WAIT_FOR_BASELINE_INSTALL.toBoolean(),  waitForStart: !env.WAIT_FOR_BASELINE_INSTALL.toBoolean()

                            currentBuild.description += "<br>${env.EEA_APPLICATION_STAGING_PRODUCT_BASELINE_INSTALL_JENKINS_JOB}: <a href=\"" + env.JENKINS_URL + '/job/${env.EEA_APPLICATION_STAGING_PRODUCT_BASELINE_INSTALL_JENKINS_JOB}/' + baselineInstallBuild.number + '/">' + "${env.EEA_APPLICATION_STAGING_PRODUCT_BASELINE_INSTALL_JENKINS_JOB}/${baselineInstallBuild.number}"+ '</a>'

                            baselineInstallBuildJobResult = baselineInstallBuild.getResult()
                            echo "baselineInstallBuildJobResult: \"${baselineInstallBuildJobResult}\""

                            if (env.WAIT_FOR_BASELINE_INSTALL.toBoolean() && baselineInstallBuildJobResult == "SUCCESS") {
                                downloadJenkinsFile("${env.JENKINS_URL}/job/${env.EEA_APPLICATION_STAGING_PRODUCT_BASELINE_INSTALL_JENKINS_JOB}/${baselineInstallBuild.number}/artifact/product_baseline.groovy")
                                if ( fileExists("product_baseline.groovy") ) {
                                    archiveArtifacts artifacts: "product_baseline.groovy", allowEmptyArchive: true
                                }
                            }
                        }
                        if ( env.WAIT_FOR_BASELINE_INSTALL.toBoolean() && baselineInstallBuildJobResult != "SUCCESS"  ) {
                            error "\"${env.EEA_APPLICATION_STAGING_PRODUCT_BASELINE_INSTALL_JENKINS_JOB}\" was unsucessfull ${baselineInstallRetries} times "
                        }
                    }

                    sh """ echo "CUSTOM_CLUSTER_LABEL=${env.CUSTOM_CLUSTER_LABEL}" > artifact.properties"""
                    archiveArtifacts artifacts: 'artifact.properties', allowEmptyArchive: true
                }
            }
        }
    }
    post {
        cleanup {
            cleanWs()
        }
    }
}
