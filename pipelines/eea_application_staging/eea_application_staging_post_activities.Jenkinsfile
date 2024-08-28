@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import com.ericsson.eea4.ci.CiDashboard

@Field def git = new GitScm(this, 'EEA/adp-app-staging')
@Field def dashboard = new CiDashboard(this)

pipeline {
    agent {
        node {
            label 'productci'
        }
    }

    options {
        buildDiscarder(logRotator(daysToKeepStr: "14", artifactDaysToKeepStr: "7"))
    }

    parameters {
        string(name: 'SPINNAKER_ID', description: "The spinnaker execution's id of eea-application-staging", defaultValue: '')
        string(name: 'STAGING_RESULT', description: "The result of eea-application-staging", defaultValue: '')
        string(name: 'PIPELINE_NAME', description: "The spinnaker pipeline name", defaultValue: '')
        string(name: 'FAILED_STAGES', description: "The name of failed stages of eea-application-staging (if any)", defaultValue: '')
        string(name: 'VERSION', description: "The integration helm version  ", defaultValue: '')
        string(name: 'CHART_NAME', description: "The integration helm name", defaultValue: 'eric-eea-int-helm-chart')
        string(name: 'GRANNY_PIPELINE_NAME', description: "The most top pipeline which caused current one", defaultValue: '')
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

        stage('Close staging execution on dashboard') {
            when {
                expression { params.VERSION }
            }
            steps {
                catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                    script {
                        // SUCCEEDED, CANCELED, TERMINAL
                        dashboard.setSpinnakerUrl("${params.SPINNAKER_ID}")
                        if (params.FAILED_STAGES) {
                            // we get unquoted JSON from Spinnaker [stage1, stage2], so we need to parse it by
                            // 1) stripping square brackets, 2) splitting string by ', ' delimiter
                            String failedStages = params.FAILED_STAGES.replaceAll('^\\[|\\]$', '')
                            ArrayList failedSpinnakerStages = failedStages.split(',\\s*')
                            dashboard.setFailedSpinnakerStages(failedSpinnakerStages)
                        }
                        dashboard.setArtifactName("${params.CHART_NAME}")
                        dashboard.finishExecution("${params.PIPELINE_NAME}", "${params.STAGING_RESULT}", "${params.SPINNAKER_ID}", "${params.VERSION}")
                    }
                }
            }
        }

        stage('Call an automatic confluence updater') {
            when {expression { params.GRANNY_PIPELINE_NAME && params.GRANNY_PIPELINE_NAME == 'eric-eea-utf-application-drop' }}
            parallel {
                stage('Update the trouble report confluence ID page') {
                    steps {
                        catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                            script {
                                echo "Updating the trouble report confluence ID page"
                                build job: "as-toolbox-confluence", parameters: [
                                    stringParam(name: "CONFLUENCE_MODE", value: "trouble_report"),
                                    stringParam(name: "PAGE_ID", value: "967138121")
                                ], wait: true
                            }
                        }
                    }
                }
                stage('Update the test case catalog confluence ID page') {
                    steps {
                        catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                            script {
                                echo "Update the test case catalog confluence ID page"
                                build job: "as-toolbox-confluence", parameters: [
                                    stringParam(name: "CONFLUENCE_MODE", value: "test_case_catalog"),
                                    stringParam(name: "PAGE_ID", value: "1100717459")
                                ], wait: true
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
