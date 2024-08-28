@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def git = new GitScm(this, 'EEA/project-meta-baseline')

pipeline {
    agent {
        node {
            label 'productci'
        }
    }
    options {
      skipDefaultCheckout()
      disableConcurrentBuilds()
      buildDiscarder(logRotator(daysToKeepStr: "7"))
    }

    tools{
        gradle "Default"
    }
    triggers {
        gerrit (
            serverName: 'GerritCentral',
            gerritProjects: [[
                compareType: 'PLAIN',
                pattern: 'EEA/project-meta-baseline',
                branches: [[ compareType: 'PLAIN', pattern: env.MAIN_BRANCH ]],
                topics: [[ compareType: 'REG_EXP', pattern: '^((?!^inca$).)*$' ]]
        ]],
            triggerOnEvents:  [
                [
                    $class              : 'PluginCommentAddedEvent',
                    verdictCategory       : 'Code-Review',
                    commentAddedTriggerApprovalValue: '+1'
                ]
            ]
        )
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

        stage('Checkout') {
            steps {
                script {
                    git.checkoutRefSpec("${GERRIT_REFSPEC}", "FETCH_HEAD", '')
                }
            }
        }

        stage('Prepare') {
            steps {
                checkoutGitSubmodules()
            }
        }

        stage('Prepare Helm Chart') {
            steps {
                // Generate meta baseline helm chart
                withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                 string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                 string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                 usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                    sh 'bob/bob prepare-meta'
                }
            }
        }

        stage('Bob lint') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                             string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                             string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                             usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                    sh 'bob/bob lint-meta:helm'
                }
            }
        }


        stage('Archive artifact.properties') {
            steps {
                // Archive artifact.properties so Spinnaker can read the parameters (GERRIT_REFSPEC)
                archiveArtifacts 'artifact.properties'
            }
        }


   }
    post {
        cleanup {
            cleanWs()
        }
        failure {
            script {
                def recipient = '42a7977a.ericsson.onmicrosoft.com@emea.teams.ms'
                mail subject: "${env.JOB_NAME} (${env.BUILD_NUMBER}) failed",
                body: "It appears that ${env.BUILD_URL} is failing, somebody should do something about that",
                to: "${recipient}",
                replyTo: "${recipient}",
                from: 'eea-seliius27190@ericsson.com'
            }
        }
    }
}
