@Library('ci_shared_library_eea4') _

import groovy.transform.Field
import com.ericsson.eea4.ci.CiDashboard
import com.ericsson.eea4.ci.GlobalVars

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
        booleanParam(name: "DRY_RUN", description: "Use dry run to regenerate the job's parameters", defaultValue: false)
        booleanParam(name: "UPLOAD_CLUSTER_NAME", description: "Send cluster name on dashboard", defaultValue: false)
        booleanParam(name: "ACTIVATE_DEACTIVATE_CLUSTER", description: "Activate or deactivate cluster on dashboard", defaultValue: false)
        booleanParam(name: "UPLOAD_CLUSTER_LOCK_EVENT", description: "Send lock event on dashboard", defaultValue: false)
        string(name: "CLUSTER_NAME", description: "Cluster lockable resource name", defaultValue: "")
        choice(name: 'CLUSTER_STATUS', choices: ['ACTIVE', 'INACTIVE'], description: 'Cluster active status will be sent on dashboard')
        string(name: "CLUSTER_LOCK_EVENT", description: "Send a lock event on dashboard", defaultValue: "")
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
                    if (!params.CLUSTER_NAME) {
                        error "Cluster name cannot be empty!"
                    }
                    if (!params.UPLOAD_CLUSTER_NAME && !params.UPLOAD_CLUSTER_LOCK_EVENT && !params.ACTIVATE_DEACTIVATE_CLUSTER) {
                        error("At least one action has to be chosen!")
                    }
                }
            }
        }

        stage('Upload cluster name and resource details on dashboard') {
            when {
                 expression { params.UPLOAD_CLUSTER_NAME }
            }
            steps {
                script {
                    echo "Upload cluster name and details on CI dashboard"
                    sendClusterResourceToDashboard(params.CLUSTER_NAME)
                }
            }
        }
        stage('Activate or deactivate cluster on dashboard') {
            when {
                 expression { params.ACTIVATE_DEACTIVATE_CLUSTER }
            }
            steps {
                script {
                    if(params.CLUSTER_STATUS == 'ACTIVE') {
                        echo "Activate cluster on dashboard"
                        dashboard.uploadClusterHealthData(params.CLUSTER_NAME, [clusterIsActive:true])
                    } else {
                        echo "Deactivate cluster on dashboard"
                        dashboard.uploadClusterHealthData(params.CLUSTER_NAME, [clusterIsActive:false])
                    }
                }
            }
        }
        stage('Upload cluster lock event on dashboard') {
            when {
                expression { params.UPLOAD_CLUSTER_LOCK_EVENT}
            }
            steps {
                script {
                    echo "Upload cluster lock event on CI dashboard"
                    if(params.CLUSTER_NAME) {
                        sendLockEventToDashboard(transition: "${params.CLUSTER_LOCK_EVENT}",cluster: "${params.CLUSTER_NAME}")
                    } else {
                        sendLockEventToDashboard(transition: "${params.CLUSTER_LOCK_EVENT}")
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
