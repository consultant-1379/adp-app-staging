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
    parameters {
        string(name: 'TEST_STRING', description: 'value from test artifact', defaultValue:"test")
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
                script{
                    sleep(time:10,unit:"SECONDS")
                }
                echo "stage job ${params.TEST_STRING}"
            }
        }
    }
}
