@Library('ci_shared_library_eea4') _

import groovy.transform.Field
import com.ericsson.eea4.ci.ClusterLogUtils
import com.ericsson.eea4.ci.GlobalVars

@Field def clusterLogUtilsInstance = new ClusterLogUtils(this)
@Field def globalVars = new GlobalVars()

@Field def DEFAULT_BASELINE_INSTALL_MODE_IS_HELM = 'HELM'
@Field def DEFAULT_BASELINE_INSTALL_MODE_IS_HELM_AND_CMA = 'HELM_AND_CMA'

def generic_upgrade_job

pipeline {
    options {
        buildDiscarder(logRotator(daysToKeepStr: '7', artifactNumToKeepStr: '7'))
        skipDefaultCheckout()
        ansiColor('xterm')
    }
    agent {
        node {
            label 'productci'
        }
    }

    parameters {
        string(name: 'CHART_NAME', description: 'Chart name e.g.: eric-ms-b', defaultValue: '')
        string(name: 'CHART_REPO', description: 'Chart repo e.g.: https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm', defaultValue: '')
        string(name: 'CHART_VERSION', description: 'Chart version e.g.: 1.0.0-1', defaultValue: '')
        string(name: 'INT_CHART_NAME', description: 'Chart name e.g.: eric-ms-b', defaultValue: '')
        string(name: 'INT_CHART_REPO', description: 'Chart repo e.g.: https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm', defaultValue: '')
        string(name: 'INT_CHART_VERSION', description: 'Chart version e.g.: 1.0.0-1', defaultValue: 'latest')
        string(name: 'GERRIT_REFSPEC',  description: 'Gerrit Refspect of the integration chart git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'SPINNAKER_TRIGGER_URL', description: 'Spinnaker pipeline triggering url', defaultValue: '')
        string(name: 'SPINNAKER_ID', description: "The spinnaker execution's id", defaultValue: '')
        string(name: 'PIPELINE_NAME', description: "The spinnaker pipeline name", defaultValue: 'eea-adp-staging')
        booleanParam(name: 'SKIP_COLLECT_LOG', description: 'skip the log collection pipeline', defaultValue: false)
        booleanParam(name: 'SKIP_CLEANUP', description: 'skip the cleanup pipeline. Used when SKIP_COLLECT_LOG is false', defaultValue: false)
        string(name: 'CLUSTER_LABEL', description: "The cluster resource label that should be locked for upgrade", defaultValue: "${globalVars.resourceLabelUpgrade}")
        string(name: 'CUSTOM_CLUSTER_LABEL', description: 'If CUSTOM_CLUSTER_LABEL is set, we have to set that label at the end of the pipeline executions, and FORCE skip the collect log and cleanup !!!', defaultValue: '')
        string(name: 'SEP_CHART_NAME', description: 'SEP helm chart name', defaultValue: 'eric-cs-storage-encryption-provider' )
        string(name: 'SEP_CHART_REPO', description: 'SEP helm chart repo', defaultValue: 'https://arm.sero.gic.ericsson.se/artifactory/proj-adp-rs-storage-encr-released-helm' )
        string(name: 'INT_CHART_NAME_META', description: 'Chart name e.g.: eric-ms-b', defaultValue: 'eric-eea-ci-meta-helm-chart')
        string(name: 'INT_CHART_REPO_META', description: 'Chart repo e.g.: https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/', defaultValue: 'https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/')
        string(name: 'INT_CHART_VERSION_META', description: 'meta-baseline version to install. Format: 1.0.0-1', defaultValue: 'latest')
        string(name: 'DIMTOOL_OUTPUT_REPO_URL', description: "The url of the artifactory", defaultValue: 'https://arm.seli.gic.ericsson.se')
        string(name: 'DIMTOOL_OUTPUT_REPO', description: "Repo of the chart eg. proj-eea-reports-generic-local/dimtool/prod_ci_artifacts/", defaultValue: 'proj-eea-reports-generic-local/dimtool/prod_ci_artifacts/')
        string(name: 'DIMTOOL_OUTPUT_NAME', description: 'Chart name e.g.: eea-application-staging-baseline-prepare-12695/eea4-dimensioning-tool-output.zip', defaultValue: '')
        choice(name: 'BUILD_RESULT_WHEN_NELS_CHECK_FAILED', choices: ['FAILURE', 'SUCCESS'], description: 'build result when the Check NELS availability failed')
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

        stage('Init') {
            steps {
                script {
                    currentBuild.description = ""
                    env.GENERIC_UPGRADE_JOB_BUILD_NUMBER = ""
                    env.GENERIC_UPGRADE_JOB_DESCRIPTION = ""
                    env.ARCHIVE_FILE_PATH = ""
                }
            }
        }

        stage('Prepare upgrade') {
            steps {
                script {
                    def prepare_upgrade_job = build job: "eea-product-prepare-upgrade", parameters: [
                        booleanParam(name: 'DRY_RUN', value: false),
                        stringParam(name: "SPINNAKER_ID", value: params.SPINNAKER_ID),
                        stringParam(name: "PIPELINE_NAME", value: params.PIPELINE_NAME),
                        stringParam(name: "CUSTOM_CLUSTER_LABEL", value: params.CLUSTER_LABEL),
                        stringParam(name: "HELM_AND_CMA_VALIDATION_MODE", value: params.HELM_AND_CMA_VALIDATION_MODE),
                        stringParam(name: "DEFAULT_BASELINE_INSTALL_MODE", value: params.DEFAULT_BASELINE_INSTALL_MODE)
                    ], wait: true
                    downloadJenkinsFile("${env.JENKINS_URL}/job/eea-product-prepare-upgrade/${prepare_upgrade_job.number}/artifact/artifact.properties", "eea_product_prepare_upgrade_artifact.properties")
                    readProperties(file: 'eea_product_prepare_upgrade_artifact.properties').each {key, value -> env['PREPARE_UPGRADE_' +key] = value }
                    archiveArtifacts artifacts: "eea_product_prepare_upgrade_artifact.properties", allowEmptyArchive: true
                }
            }
        }

        stage('Execute upgrade') {
            steps {
                catchError(stageResult: 'FAILURE', buildResult: 'FAILURE') {
                    script {
                        generic_upgrade_job = build job: "eea-common-product-upgrade", parameters: [
                            booleanParam(name: 'DRY_RUN', value: false),
                            stringParam(name: 'CHART_NAME', value: params.CHART_NAME),
                            stringParam(name: 'CHART_REPO', value: params.CHART_REPO),
                            stringParam(name: 'CHART_VERSION', value: params.CHART_VERSION),
                            stringParam(name: 'INT_CHART_NAME_PRODUCT', value: params.INT_CHART_NAME),
                            stringParam(name: 'INT_CHART_REPO_PRODUCT', value: params.INT_CHART_REPO),
                            stringParam(name: 'INT_CHART_VERSION_PRODUCT', value: params.INT_CHART_VERSION),
                            stringParam(name: 'INT_CHART_NAME_META', value: params.INT_CHART_NAME_META),
                            stringParam(name: 'INT_CHART_REPO_META', value: params.INT_CHART_REPO_META),
                            stringParam(name: 'INT_CHART_VERSION_META', value: params.INT_CHART_VERSION_META),
                            stringParam(name: 'SPINNAKER_TRIGGER_URL', value: params.SPINNAKER_TRIGGER_URL),
                            stringParam(name: 'SPINNAKER_ID', value: params.SPINNAKER_ID),
                            stringParam(name: 'PIPELINE_NAME', value: params.PIPELINE_NAME),
                            stringParam(name: 'GERRIT_REFSPEC',  value: params.GERRIT_REFSPEC),
                            booleanParam(name: 'SKIP_COLLECT_LOG', value: params.SKIP_COLLECT_LOG),
                            booleanParam(name: 'SKIP_CLEANUP', value: params.SKIP_CLEANUP),
                            stringParam(name: 'CUSTOM_CLUSTER_LABEL', value: params.CUSTOM_CLUSTER_LABEL),
                            stringParam(name: "UPGRADE_CLUSTER_LABEL", value: env.PREPARE_UPGRADE_CUSTOM_CLUSTER_LABEL),
                            stringParam(name: 'DIMTOOL_OUTPUT_REPO_URL', value: params.DIMTOOL_OUTPUT_REPO_URL),
                            stringParam(name: 'DIMTOOL_OUTPUT_REPO', value: params.DIMTOOL_OUTPUT_REPO),
                            stringParam(name: 'DIMTOOL_OUTPUT_NAME', value: params.DIMTOOL_OUTPUT_NAME),
                            stringParam(name: 'BUILD_RESULT_WHEN_NELS_CHECK_FAILED', value: params.BUILD_RESULT_WHEN_NELS_CHECK_FAILED),
                            stringParam(name: 'HELM_AND_CMA_VALIDATION_MODE', value: params.HELM_AND_CMA_VALIDATION_MODE)
                        ], wait: true, propagate: false

                        def jobResult = generic_upgrade_job.getResult()
                        if (jobResult != 'SUCCESS') {
                            error("Build of 'eea-common-product-upgrade' failed with result: ${jobResult}")
                        }
                    }
                }
            }
            post {
                always {
                    script {
                        echo "Execute upgrade - post.always action"
                        if (generic_upgrade_job?.description) {
                            env.GENERIC_UPGRADE_JOB_DESCRIPTION = generic_upgrade_job.description.replaceFirst('<br>Upstream job: <a href="(.*?)">(.*?)</a>', '')
                            echo "Add eea-common-product-upgrade job description to the currentBuild.description"
                            currentBuild.description += env.GENERIC_UPGRADE_JOB_DESCRIPTION
                        }
                        if (generic_upgrade_job?.number) {
                            env.GENERIC_UPGRADE_JOB_BUILD_NUMBER = generic_upgrade_job.number
                            echo "env.GENERIC_UPGRADE_JOB_BUILD_NUMBER: ${env.GENERIC_UPGRADE_JOB_BUILD_NUMBER}"
                            env.ARCHIVE_FILE_PATH = "artifacts-eea-common-product-upgrade-${env.GENERIC_UPGRADE_JOB_BUILD_NUMBER}"
                            echo "env.ARCHIVE_FILE_PATH: ${env.ARCHIVE_FILE_PATH}"
                            env.GENERIC_UPGRADE_JOB_URL = "${env.JENKINS_URL}job/eea-common-product-upgrade/${env.GENERIC_UPGRADE_JOB_BUILD_NUMBER}"
                            currentBuild.description += '<br>' + "Generic upgrade job: <a href=\"${env.GENERIC_UPGRADE_JOB_URL}\">${env.GENERIC_UPGRADE_JOB_URL}</a>"

                            try {
                                downloadJenkinsFile("${env.JENKINS_URL}/job/eea-common-product-upgrade/${generic_upgrade_job.number}/artifact/performance.properties", "${WORKSPACE}/performance.properties")
                                load "${WORKSPACE}/performance.properties"
                            } catch(err) {
                                echo "Caught error: ${err} during save performance.properties"
                            }
                        }
                    }
                }
            }
        }

        stage('Copy artifacts') {
            when {
                expression {env.ARCHIVE_FILE_PATH}
            }
            steps {
                catchError(stageResult: 'FAILURE', buildResult: 'SUCCESS') {
                    script {
                        copyArtifacts(
                            projectName: "eea-common-product-upgrade",
                            selector: specific("${env.GENERIC_UPGRADE_JOB_BUILD_NUMBER}"),
                            target: "${env.ARCHIVE_FILE_PATH}",
                            fingerprintArtifacts: true,
                            optional: true)
                    }
                }
            }
        }

        stage('Arhive artifacts') {
            when {
                expression {env.ARCHIVE_FILE_PATH && fileExists(env.ARCHIVE_FILE_PATH)}
            }
            steps {
                catchError(stageResult: 'FAILURE', buildResult: 'SUCCESS') {
                    script {
                        dir("${env.ARCHIVE_FILE_PATH}") {
                            def archiveFiles = findFiles(glob: "*")
                                archiveFiles.each { archiveFile ->
                                echo "archiveArtifacts: ${archiveFile} ..."
                                try {
                                    archiveArtifacts artifacts: "${archiveFile}", allowEmptyArchive: true
                                } catch(err) {
                                    echo "Caught archiveArtifacts ERROR!\n - archiveFile: ${archiveFile}\n - error: ${err}"
                                }
                            }
                        }
                    }
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
