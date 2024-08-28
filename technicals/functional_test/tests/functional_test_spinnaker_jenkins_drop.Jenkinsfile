@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def git = new GitScm(this, 'EEA/adp-app-staging')

pipeline {
    options {
        disableConcurrentBuilds()
        buildDiscarder(logRotator(daysToKeepStr: '14', artifactDaysToKeepStr: '7'))
    }

    agent {
        node {
            label 'productci'
        }
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

        stage('Run test stage') {
            steps {
                sh 'echo drop job'
                writeFile file: 'artifact.properties', text:"CHART_NAME=test"
                archiveArtifacts 'artifact.properties'
            }
        }
    }
}
