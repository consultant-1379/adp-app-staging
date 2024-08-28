@Library('ci_shared_library_eea4') _

import groovy.transform.Field
import com.ericsson.eea4.ci.CiDashboard
import com.ericsson.eea4.ci.Artifactory
import groovy.json.JsonOutput

@Field def dashboard = new CiDashboard(this)
@Field def arm = new Artifactory(this, "https://arm.seli.gic.ericsson.se/",  "API_TOKEN_EEA")

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
        booleanParam(name: "PUBLISH_HELM", description: "Publish helm chart version on dashboard", defaultValue: false)
        booleanParam(name: "UPLOAD_HELM", description: "Upload helm chart on dashboard", defaultValue: false)
        string(name: "CHART_NAME", description: "Chart name, e.g.: eric-ms-b", defaultValue: "")
        string(name: "CHART_VERSION", description: "Chart version, e.g.: 24.5.0-66", defaultValue: "")
        string(name: "CHART_REPO", description: "Chart repo e.g.: https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm", defaultValue: "")
        string(name: "INT_CHART_NAME", description: "Chart name e.g.: eric-ms-b", defaultValue: "")
        string(name: "INT_CHART_VERSION", description: "Chart version e.g.: 1.0.0-1", defaultValue: "")
        string(name: "INT_CHART_REPO", description: "Chart repo e.g.: https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm", defaultValue: "")
        string(name: "PARENT_JOB_BUILD_URL", description: "A job build url to send on dashboard", defaultValue: "")
        string(name: "PARENT_JOB_BUILD_ID", description: "A job build id to send on dashboard", defaultValue: "")
        string(name: "STAGE_NAME", description: "A stage name to send on dashboard", defaultValue: "")
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
                   if (!params.PUBLISH_HELM && !params.UPLOAD_HELM) {
                        error("At least one action has to be chosen!")
                   } else if (params.PUBLISH_HELM && (!params.INT_CHART_NAME || !params.INT_CHART_VERSION || !params.INT_CHART_REPO || !params.PARENT_JOB_BUILD_URL || !params.PARENT_JOB_BUILD_ID || !params.STAGE_NAME)) {
                        error("CHART_NAME, CHART_VERSION, CHART_REPO, PARENT_JOB_BUILD_URL, PARENT_JOB_BUILD_ID and STAGE_NAME parameters should be specified during helm publishing!")
                   } else if (params.UPLOAD_HELM && (!params.CHART_NAME || !params.CHART_VERSION || !params.CHART_REPO)) {
                        error("CHART_NAME, CHART_VERSION and CHART_REPO parameters should be specified during helm uploading!")
                   }
                }
            }
        }
        stage('Download helm chart') {
            steps{
                script {
                    if (params.PUBLISH_HELM) {
                        env.CHART_NAME = params.INT_CHART_NAME
                        env.CHART_VERSION = params.INT_CHART_VERSION
                        env.CHART_REPO_URL = params.INT_CHART_REPO
                    } else if (params.UPLOAD_HELM) {
                        env.CHART_NAME = params.CHART_NAME
                        env.CHART_VERSION = params.CHART_VERSION
                        env.CHART_REPO_URL = params.CHART_REPO
                    }

                    echo("env.CHART_NAME: " + env.CHART_NAME)
                    echo("env.CHART_VERSION: " + env.CHART_VERSION)
                    echo("env.CHART_REPO_URL: " + env.CHART_REPO_URL)

                    env.CHART_REPO_NAME = env.CHART_REPO_URL.split('/')[4] + "/" + env.CHART_NAME

                    echo("env.CHART_REPO_NAME: " + env.CHART_REPO_NAME)

                    withCredentials([string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                        arm.setUrl("https://arm.seli.gic.ericsson.se", "$API_TOKEN_EEA")
                        arm.setRepo("${env.CHART_REPO_NAME}")
                        arm.downloadArtifact("${env.CHART_NAME}-${env.CHART_VERSION}.tgz", "${env.CHART_NAME}-${env.CHART_VERSION}.tgz")
                    }
                }
            }
        }

        stage('Publish helm chart on dashboard') {
            when {
                expression { params.PUBLISH_HELM }
            }
            steps {
                script {
                    echo "Publish helm chart on CI dashboard"
                    dashboard.publishHelm("${env.CHART_NAME}-${env.CHART_VERSION}.tgz","${env.CHART_VERSION}","${params.PARENT_JOB_BUILD_URL}","${params.PARENT_JOB_BUILD_ID}","${params.STAGE_NAME}")
                }
            }
        }
        stage('Upload helm chart on dashboard'){
            when {
                 expression { params.UPLOAD_HELM }
            }
            steps{
                script {
                    echo "Upload helm chart to CI dashboard"
                    dashboard.uploadHelm("${env.CHART_NAME}-${env.CHART_VERSION}.tgz","${env.CHART_VERSION}")
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
