@Library('ci_shared_library_eea4') _

import groovy.transform.Field
import com.ericsson.eea4.ci.CiDashboard
import groovy.json.JsonOutput

@Field def dashboard = new CiDashboard(this)

pipeline {
    agent {
        node {
            label 'productci'
        }
    }
    options {
        ansiColor("xterm")
        buildDiscarder(logRotator(daysToKeepStr: "7", artifactDaysToKeepStr: "7"))
    }
    parameters {
        booleanParam(name: "DRY_RUN", description: "Use dry run to regenerate the job's parameters", defaultValue: false)
        booleanParam(name: "START_EXECUTION", description: "Call function to send to dashboard the execution start", defaultValue: false)
        booleanParam(name: "START_EXECUTION_WITH_ARTIFACT_NAME", description: "Call function to send to dashboard the execution start", defaultValue: false)
        booleanParam(name: "FINISH_EXECUTION", description: "Call function to send to dashboard the execution result", defaultValue: false)
        booleanParam(name: "UPLOAD_EXECUTION_KPI", description: "Upload execution KPI data on dashboard", defaultValue: false)
        booleanParam(name: "UPLOAD_EXECUTION_NOT_IN_CSAR", description: "Upload services not in CSAR on dashboard", defaultValue: false)
        booleanParam(name: "UPLOAD_EXECUTION_MIMER", description: "Upload service mimer list on dashboard", defaultValue: false)
        string(name: "INT_CHART_NAME", description: "Chart name, e.g.: eric-eea-ci-meta-helm-chart", defaultValue: "")
        string(name: "INT_CHART_VERSION", description: "Chart version, e.g.: 24.5.0-66", defaultValue: "")
        string(name: "INT_CHART_VERSION_WITHOUT_HASH", description: "Chart versions without hash, e.g.: 24.5.0-66", defaultValue: "")
        string(name: "PARENT_JOB_BUILD_URL", description: "A job build url to send to dashboard", defaultValue: "")
        choice(name: "PARENT_JOB_BUILD_RESULT", choices: ["SUCCESS","FAILURE","ABORTED"], description: "Result of the parent job build")
        string(name: "PARENT_JOB_IHC_CHANGE_TYPE", description: "An integration helm chart change type, e.g.: manual", defaultValue: "")
        string(name: "SPINNAKER_ID", description: "The spinnaker execution's id of eea-application-staging or job ID", defaultValue: "")
        string(name: "PIPELINE_NAME", description: "The spinnaker pipeline name", defaultValue: "")
        string(name: "SPINNAKER_TRIGGER_URL", description: "Spinnaker pipeline triggering url", defaultValue: "")
        string(name: "MIMER_INFO_LIST", description: "Mimer services info list", defaultValue: "")
        string(name: "EXECUTION_KPI_DATA", description: "json KPI data of execution", defaultValue: "")
    }
    stages {
        stage('Params DryRun check') {
            when {
                expression { params.DRY_RUN }
            }
            steps {
                script {
                    dryRun()
                }
            }
        }
        stage('Check params') {
            steps {
                script {
                    if(!params.START_EXECUTION && !params.START_EXECUTION_WITH_ARTIFACT_NAME && !params.FINISH_EXECUTION && !params.UPLOAD_EXECUTION_KPI && !params.UPLOAD_EXECUTION_NOT_IN_CSAR && !params.UPLOAD_EXECUTION_MIMER) {
                        error("Has to be chosen at least one action!")
                    }
                }
            }
        }
        stage('Start pipeline execution with artifact name on dashboard') {
            when {
                expression { params.START_EXECUTION_WITH_ARTIFACT_NAME }
            }
            steps {
                script {
                    echo "start execution with an artifact name"
                    dashboard.startExecutionWithArtifactName("${params.PIPELINE_NAME}","${params.PARENT_JOB_BUILD_URL}","${params.SPINNAKER_ID}","${env.INT_CHART_VERSION}","${params.PARENT_JOB_IHC_CHANGE_TYPE}","${params.INT_CHART_NAME}")
                }
            }
        }
        stage('Start pipeline execution on dashboard'){
            when {
                 expression { params.START_EXECUTION }
            }
            steps{
                script {
                    echo "Start execution"
                    dashboard.startExecution("${params.PIPELINE_NAME}","${params.PARENT_JOB_BUILD_URL}","${params.SPINNAKER_ID}")
                }
            }
        }
        stage('Finish pipeline execution on dashboard'){
            when {
                 expression { params.FINISH_EXECUTION }
            }
            steps{
                script {
                    echo "Finish execution"
                    dashboard.finishExecution("${params.PIPELINE_NAME}","${params.PARENT_JOB_BUILD_RESULT}","${params.SPINNAKER_ID}","${params.INT_CHART_VERSION}")
                }
            }
        }
        stage('Upload execution KPI on dashboard') {
            when {
                expression { params.UPLOAD_EXECUTION_KPI && params.EXECUTION_KPI_DATA }
            }
            steps {
                script {
                    echo "Upload execution KPI on dashboard"
                    def jsonObj = readJSON text: "${params.EXECUTION_KPI_DATA}"
                    def jsonStr = JsonOutput.prettyPrint(JsonOutput.toJson([jsonObj]))
                    dashboard.uploadExecutionKpi(jsonStr)
                }
            }
        }
        stage('Upload execution not in CSAR on dashboard') {
            when {
                expression { params.UPLOAD_EXECUTION_NOT_IN_CSAR && params.SPINNAKER_ID && params.INT_CHART_VERSION_WITHOUT_HASH}
            }
            steps {
                script {
                    echo "Upload services not in CSAR on dashboard"
                    dashboard.uploadNotInCsarPackages("${params.SPINNAKER_ID}","${params.INT_CHART_NAME}","${params.INT_CHART_VERSION_WITHOUT_HASH}")
                }
            }
        }
        stage('Upload execution mimer on dashboard') {
            when {
                expression { params.UPLOAD_EXECUTION_MIMER && params.MIMER_INFO_LIST && params.SPINNAKER_ID && params.PIPELINE_NAME}
            }
            steps {
                script {
                    echo "Upload Mimer info on dashboard"
                    dashboard.uploadExecutionMimer("${params.MIMER_INFO_LIST}","${params.SPINNAKER_ID}","${params.PIPELINE_NAME}")
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
