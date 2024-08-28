@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import hudson.Util;

@Field def git = new GitScm(this, 'EEA/cnint')

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


        stage('Run when run in main Jenkins'){
            when {
                expression { env.MAIN_BRANCH == 'master' }
            }
            stages{
                stage('Checkout cnint') {
                    steps {
                        script{
                            git.checkout(env.MAIN_BRANCH, 'cnint')
                        }
                    }
                }

                stage('Create spin config') {
                    steps {
                        withCredentials([usernamePassword(credentialsId: 'eceaspin', usernameVariable: 'SPIN_USERNAME', passwordVariable: 'SPIN_PASSWORD')]) {
                            writeFile file: 'spin_config', text: "gate:\n  endpoint: https://spinnaker-api.rnd.gic.ericsson.se\nauth:\n  enabled: true\n  basic:\n    username: ${SPIN_USERNAME}\n    password: ${SPIN_PASSWORD}"
                        }
                    }
                }

                stage('Create Status') {
                    steps {
                        script {
                            sh 'python3 technicals/pythonscripts/drop_status.py --config spin_config --application eea > drop_status.html'
                            archiveArtifacts 'drop_status.html'
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
