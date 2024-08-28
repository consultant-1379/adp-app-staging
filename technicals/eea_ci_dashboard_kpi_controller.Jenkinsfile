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
        booleanParam(name: 'DRY_RUN', description: "Use dry run to regenerate the job's parameters", defaultValue: false)
        booleanParam(name: 'SEND_KPI', description: 'Send KPI indicator on dashboard', defaultValue: false)
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
        stage('Send KPI on dashboard') {
            when {
                expression { params.SEND_KPI }
            }
            steps {
                script {
                    // A functionality will be added in the future
                    echo "Sending KPI on CI dashboard"
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
