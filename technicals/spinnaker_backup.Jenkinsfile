@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import hudson.Util
@Field def gitaas = new GitScm(this, 'EEA/adp-app-staging')

pipeline {
    options { buildDiscarder(logRotator(daysToKeepStr: "7"))}
    agent {
        node {
            label 'productci'
        }
    }

    triggers { cron('0 0 * * *') }

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

        stage('Checkout'){
            steps{
                script {
                    gitaas.checkout('master','')
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

        stage('Create backup folder') {
            steps {
                sh 'mkdir -p backup'
            }
        }

        stage('Spinnaker Backup') {
            steps {
                dir('backup') {
                    script {
                        def application = 'eea'
                        def pipeline_list = sh(script: "spin pipeline list -a ${application} --config ../spin_config | jq -r '.[].name'", , returnStdout: true).trim().split('\n')
                        pipeline_list.each {
                            sh "../technicals/shellscripts/spinnaker_configuration_save.sh ../spin_config ${it}"
                        }
                    }
                }
            }
        }

        stage('Archive and store') {
            steps {
                sh 'tar czvf /data/nfs/productci/spinnaker-backup/spinnaker_pipeline_config_\$(date +%Y%m%d_%H%M).tar.gz backup/*'
            }
        }
    }
    post {
        cleanup {
            cleanWs()
        }
    }

}
