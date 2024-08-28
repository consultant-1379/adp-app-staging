@Library('ci_shared_library_eea4') _

import groovy.transform.Field
import com.ericsson.eea4.ci.CiDashboard

@Field def dashboard = new CiDashboard(this)

pipeline {
    agent {
        node {
            label 'productci'
        }
    }
    options {
        ansiColor('xterm')
        buildDiscarder(logRotator(daysToKeepStr: '7', artifactDaysToKeepStr: '7'))
    }
    parameters {
        booleanParam(name: 'DRY_RUN', defaultValue: false, description: "Use dry run to regenerate the job's parameters")
        booleanParam(name: 'CREATE_A_NEW_STAGE', defaultValue: true, description: 'Call function to upload a helm to dashboard')
        booleanParam(name: 'UPDATE_AN_EXISTING_STAGE', defaultValue: true, description: 'Call function to send to dashboard the execution start')
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
                    if (params.CREATE_A_NEW_STAGE && params.UPDATE_AN_EXISTING_STAGE) {
                        error "CREATE_A_NEW_STAGE and UPDATE_AN_EXISTING_STAGE input parameters cannot be specified at the same time!"
                    }
                }
            }
        }
        stage('Create a new stage on dashboard') {
            when {
                 expression { params.CREATE_A_NEW_STAGE }
            }
            steps {
                script {
                     // A functionality will be added in the future
                     echo "Creating a new stage on CI dashboard"
                }
            }
        }
        stage('Update an existing stage on dashboard') {
            when {
                 expression { params.UPDATE_AN_EXISTING_STAGE }
            }
            steps {
                script {
                    // A functionality will be added in the future
                    echo "Updating an existing stage on CI dashboard"
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
