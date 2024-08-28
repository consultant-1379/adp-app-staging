@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def gitcdd = new GitScm(this, "EEA/cdd")
@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
def defaultReviewGroup = 'cdd-manual-commit-reviewers'

pipeline {
    agent {
        node {
            label 'productci'
        }
    }
    options {
        skipDefaultCheckout()
        buildDiscarder(logRotator(daysToKeepStr: '14', artifactDaysToKeepStr: '7'))
    }
    parameters {
        string(name: 'GERRIT_REFSPEC', description: 'Gerrit Refspec of the cdd git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
    }
    triggers {
        gerrit (
            serverName: 'GerritCentral',
            gerritProjects: [[
                compareType: 'PLAIN',
                pattern: 'EEA/cdd',
                branches: [[ compareType: 'PLAIN', pattern: env.MAIN_BRANCH ]],
                disableStrictForbiddenFileVerification: false,
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

        stage('Checkout cdd') {
            steps {
                script {
                    gitcdd.checkoutRefSpec("${GERRIT_REFSPEC}", 'FETCH_HEAD', '')
                }
            }
        }

        stage('Checkout technicals') {
            steps {
                script {
                    dir ('technicals') {
                        gitadp.archiveDir('EEA/adp-app-staging', 'HEAD:technicals/')
                    }
                }
            }
        }

        stage('Check if reviewers verification is needed') {
            steps {
                script {
                    if ( GERRIT_CHANGE_OWNER_NAME == "ECEAGIT" && (GERRIT_CHANGE_SUBJECT.contains("Automatic uplifting") || GERRIT_CHANGE_SUBJECT.contains("Increase time based helm chart version"))) {
                        env.SKIP_REVIEWERS_VALIDATION = true
                    }
                }
            }
        }

        stage ('Verify reviewers') {
            when {
                expression { !env.SKIP_REVIEWERS_VALIDATION }
            }
            steps {
                script {
                    def result = false
                    def reviewRules = readYaml file: "technicals/cdd_reviewers.yaml"
                    try {
                        result = gitcdd.verifyCodeReviewers("${GERRIT_REFSPEC}", reviewRules)
                    }
                    catch (err) {
                        error err.message
                    }
                    if (!result) {
                        error ("Verify reviewers failed")
                    }
                }
            }
        }

        stage('Check if the change can be added to the queue') {
            steps {
                script {
                    if ( gitcdd.listGerritMembers(defaultReviewGroup).contains("${GERRIT_EVENT_ACCOUNT_EMAIL}") ) {
                        env.PATCHSET_ALLOWED_TO_MERGE = true
                    } else {
                        message = "Authorized CR+1 were found, notification to the Product CI team to add this change to the queue was sent"
                        sendMessageToGerrit(env.GERRIT_REFSPEC, message)
                    }
                }
            }
        }

        stage('Execute eea_cdd_manual_flow_codereview_ok job') {
            when {
                expression { env.PATCHSET_ALLOWED_TO_MERGE }
            }
            steps {
                script {
                    codereview_ok_job = build job: "eea-cdd-manual-flow-codereview-ok", parameters: [
                        booleanParam(name: 'DRY_RUN', value: false),
                        stringParam(name: 'GERRIT_REFSPEC',  value: params.GERRIT_REFSPEC),
                        stringParam(name: 'GERRIT_CHANGE_ID', value: params.GERRIT_CHANGE_ID),
                        stringParam(name: 'GERRIT_CHANGE_SUBJECT', value: params.GERRIT_CHANGE_SUBJECT),
                        stringParam(name: 'GERRIT_CHANGE_OWNER_NAME', value: params.GERRIT_CHANGE_OWNER_NAME)
                    ], wait: false, waitForStart: true
                }
            }
        }

        stage('Archive artifact.properties') {
            steps {
                script {
                    try {
                        sh 'echo "GERRIT_REFSPEC=' + "${GERRIT_REFSPEC}" + '" >> artifact.properties'
                        sh 'echo "GERRIT_CHANGE_SUBJECT=' + "${GERRIT_CHANGE_SUBJECT}" + '" >> artifact.properties'
                        sh 'echo "GERRIT_CHANGE_OWNER_NAME=' + "${GERRIT_CHANGE_OWNER_NAME}" + '" >> artifact.properties'
                    } catch (err) {
                        println("Caught: " + err)
                    }
                }
                archiveArtifacts 'artifact.properties'
            }
        }
    }
    post {
        failure {
            script {
                def recipient = "${GERRIT_EVENT_ACCOUNT_EMAIL}"
                mail subject: "${env.JOB_NAME} (${env.BUILD_NUMBER}) failed",
                body: """
The ${env.BUILD_URL} failed for the ${GERRIT_CHANGE_URL} Gerrit change. Please check Gerrit comments or Jenkins build output<br>

GERRIT_CHANGE_SUBJECT: ${GERRIT_CHANGE_SUBJECT}<br>
GERRIT_CHANGE_OWNER_NAME: ${GERRIT_CHANGE_OWNER_NAME}<br>
GERRIT_PROJECT: ${GERRIT_PROJECT}
""",
                mimeType: 'text/html',
                to: "${recipient}",
                replyTo: "${recipient}",
                from: 'eea-seliius27190@ericsson.com'
            }
        }
        success {
            script {
                if ( !env.PATCHSET_ALLOWED_TO_MERGE ) {
                    def recipient = "155310d2.ericsson.onmicrosoft.com@emea.teams.ms"
                mail subject: "Gerrit change awaits Product CI review",
                body: """
The <a href="${GERRIT_CHANGE_URL}">${GERRIT_CHANGE_URL}</a> Gerrit change has received enough CR - pending review from Product CI and adding to the queue.<br>
Please add a CR+1 to the Gerrit change after review to add it to the queue<br><br>
GERRIT_CHANGE_SUBJECT: ${GERRIT_CHANGE_SUBJECT}<br>
GERRIT_PROJECT: ${GERRIT_PROJECT}
""",
                mimeType: 'text/html',
                to: "${recipient}",
                replyTo: "${recipient}",
                from: 'eea-seliius27190@ericsson.com'
                }
            }
        }
        cleanup {
            cleanWs()
        }
    }
}
