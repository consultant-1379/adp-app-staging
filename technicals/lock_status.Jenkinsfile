@Library('ci_shared_library_eea4') _

import groovy.transform.Field
import hudson.Util;

pipeline {
    options { buildDiscarder(logRotator(daysToKeepStr: "7"))}
    agent {
        node {
            label 'productci'
        }
    }

    triggers { cron('H/5 * * * *') }

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

        stage('Create Status') {
            steps {
                script {
                    sh 'cp /data/nfs/productci/cluster_lock.csv cluster_lock.csv' // copy the csv to workspace
                    archiveArtifacts 'cluster_lock.csv'
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
