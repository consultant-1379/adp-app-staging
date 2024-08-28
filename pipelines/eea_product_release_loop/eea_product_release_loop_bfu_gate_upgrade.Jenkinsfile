@Library('ci_shared_library_eea4') _

import groovy.transform.Field
import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.ClusterLogUtils

@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def clusterLogUtilsInstance = new ClusterLogUtils(this)

@Field def CMA_MODE_IS_HELM = "HELM"
@Field def CMA_MODE_IS_HELM_AND_CMA = "HELM_AND_CMA"

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
        string(name: 'NEW_BFU_GATE', description: 'Git tag of the new BFU gate e.g: eea4_4.4.0_pra', defaultValue: '')
        string(name: 'SPINNAKER_TRIGGER_URL', description: 'Spinnaker pipeline triggering url', defaultValue: '')
        string(name: 'SPINNAKER_ID', description: "The spinnaker execution's id", defaultValue: '')
        string(name: 'PIPELINE_NAME', description: "The spinnaker pipeline name", defaultValue: 'eea-application-staging')
        booleanParam(name: 'SKIP_COLLECT_LOG', description: 'skip the log collection pipeline', defaultValue: false)
        booleanParam(name: 'SKIP_CLEANUP', description: 'skip the cleanup pipeline. Used when SKIP_COLLECT_LOG is false', defaultValue: false)
        string(name: 'BASELINE_INSTALL_JENKINSFILE_GERRIT_REFSPEC', description: 'This parameter sets the JENKINSFILE_GERRIT_REFSPEC eea-application-staging-product-baseline-install Jenkins job', defaultValue: '${MAIN_BRANCH}')
        string(name: 'UPGRADE_JENKINSFILE_GERRIT_REFSPEC', description: 'This parameter sets the JENKINSFILE_GERRIT_REFSPEC eea-common-product-upgrade', defaultValue: '${MAIN_BRANCH}')
        string(name: 'HELM_AND_CMA_VALIDATION_MODE',
        description: """
        Use HELM values or HELM values and CMA configurations. valid options:
<table>
  <tr>
    <th>Value</th>
    <th ALIGN=left>Comment</th>
  </tr>
  <tr>
    <td>"HELM" or "true"</td>
    <td>use helm values, cma is diabled</td>
  </tr>
  <tr>
    <td>"HELM_AND_CMA" or "false"</td>
    <td>use helm values and load CMA configurations</td>
  </tr>
</table>
            """,
        defaultValue: 'HELM_AND_CMA')
        string(name: 'INT_CHART_NAME_META', description: 'Chart name e.g.: eric-ms-b', defaultValue: 'eric-eea-ci-meta-helm-chart')
        string(name: 'INT_CHART_REPO_META', description: 'Chart repo e.g.: https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/', defaultValue: 'https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/')
        string(name: 'INT_CHART_VERSION_META', description: 'meta-baseline version to install. Format: 1.0.0-1', defaultValue: 'latest')
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

        stage('Check params') {
            steps {
                script {
                    // throw the error, if NEW_BFU_GATE is not specified
                    if (!params.NEW_BFU_GATE) {
                        error "NEW_BFU_GATE should be specified!"
                    }
                }
            }
        }

        stage('Determine git branch for product-baseline install') {
            steps {
                script {
                    gitcnint.checkout("${params.NEW_BFU_GATE}", 'cnint')
                    dir('cnint') {
                        env.GIT_BRANCH = sh (script: '''#!/bin/bash
                            commit_id=$(git log --format="%H" -n 1)
                            git show-ref --tags -d | grep "${commit_id}" | grep '_pra' | awk -F"[ ^]" '{print $2}' | awk -F/ '{print $3}' | sed 's/_pra//'
                        ''', returnStdout: true).trim()
                    }
                    if (!env.GIT_BRANCH) {
                        error "Cannot find git branch for BFU gate version: ${params.NEW_BFU_GATE}!"
                    }
                    echo "env.GIT_BRANCH: ${env.GIT_BRANCH}"
                }
            }
        }

        stage('product-baseline install') {
            steps {
                script {
                    env.UPGRADE_CLUSTER_LABEL = "${env.JOB_NAME}_${env.BUILD_NUMBER}"
                    currentBuild.description += "<br><b>UPGRADE_CLUSTER_LABEL:</b> ${env.UPGRADE_CLUSTER_LABEL}"
                    def baseline_install_build = build job: "eea-application-staging-product-baseline-install", parameters: [
                        booleanParam(name: 'DRY_RUN', value: false),
                        stringParam(name: "GIT_BRANCH", value: "${env.GIT_BRANCH}"),
                        stringParam(name: 'CUSTOM_CLUSTER_LABEL', value: "${env.UPGRADE_CLUSTER_LABEL}"),
                        stringParam(name: 'JENKINSFILE_GERRIT_REFSPEC', value: params.BASELINE_INSTALL_JENKINSFILE_GERRIT_REFSPEC),
                        stringParam(name: "HELM_AND_CMA_VALIDATION_MODE", value: params.HELM_AND_CMA_VALIDATION_MODE)
                    ], wait: true
                    currentBuild.description += '<br><b>eea-application-staging-product-baseline-install:</b> <a href="' + env.JENKINS_URL + '/job/eea-application-staging-product-baseline-install/' + baseline_install_build.number + '/">' + "eea-application-staging-product-baseline-install/${baseline_install_build.number}"+ '</a>'
                }
            }
        }

        stage('Execute upgrade') {
            steps {
                catchError(stageResult: 'FAILURE', buildResult: 'FAILURE') {
                    script {
                        env.GENERIC_UPGRADE_JOB_NAME = 'eea-common-product-upgrade'
                        generic_upgrade_job = build job: "${env.GENERIC_UPGRADE_JOB_NAME}", parameters: [
                            booleanParam(name: 'DRY_RUN', value: false),
                            stringParam(name: 'INT_CHART_VERSION_PRODUCT', value: 'latest'),
                            stringParam(name: 'INT_CHART_VERSION_META', value: params.INT_CHART_VERSION_META),
                            stringParam(name: 'INT_CHART_NAME_META', value: params.INT_CHART_NAME_META),
                            stringParam(name: 'INT_CHART_REPO_META', value: params.INT_CHART_REPO_META),
                            stringParam(name: 'SPINNAKER_TRIGGER_URL', value: params.SPINNAKER_TRIGGER_URL),
                            stringParam(name: 'SPINNAKER_ID', value: params.SPINNAKER_ID),
                            stringParam(name: 'PIPELINE_NAME', value: params.PIPELINE_NAME),
                            booleanParam(name: 'SKIP_COLLECT_LOG', value: params.SKIP_COLLECT_LOG),
                            booleanParam(name: 'SKIP_CLEANUP', value: params.SKIP_CLEANUP),
                            stringParam(name: 'UPGRADE_CLUSTER_LABEL', value: "${env.UPGRADE_CLUSTER_LABEL}"),
                            stringParam(name: "HELM_AND_CMA_VALIDATION_MODE", value: params.HELM_AND_CMA_VALIDATION_MODE),
                            stringParam(name: 'JENKINSFILE_GERRIT_REFSPEC', value: params.UPGRADE_JENKINSFILE_GERRIT_REFSPEC)
                        ], wait: true, propagate: false

                        def jobResult = generic_upgrade_job.getResult()
                        if (jobResult != 'SUCCESS') {
                            error("Build of '${env.GENERIC_UPGRADE_JOB_NAME}' failed with result: ${jobResult}")
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
                            echo "Add ${env.GENERIC_UPGRADE_JOB_NAME} job description to the currentBuild.description"
                            currentBuild.description += env.GENERIC_UPGRADE_JOB_DESCRIPTION
                        }
                        if (generic_upgrade_job?.number) {
                            env.GENERIC_UPGRADE_JOB_BUILD_NUMBER = generic_upgrade_job.number
                            echo "env.GENERIC_UPGRADE_JOB_BUILD_NUMBER: ${env.GENERIC_UPGRADE_JOB_BUILD_NUMBER}"
                            env.ARCHIVE_FILE_PATH = "artifacts-${env.GENERIC_UPGRADE_JOB_NAME}-${env.GENERIC_UPGRADE_JOB_BUILD_NUMBER}"
                            echo "env.ARCHIVE_FILE_PATH: ${env.ARCHIVE_FILE_PATH}"
                            env.GENERIC_UPGRADE_JOB_URL = "${env.JENKINS_URL}job/${env.GENERIC_UPGRADE_JOB_NAME}/${env.GENERIC_UPGRADE_JOB_BUILD_NUMBER}"
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
                            projectName: "${env.GENERIC_UPGRADE_JOB_NAME}",
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
