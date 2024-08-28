@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def gitcnint = new GitScm(this, "EEA/cnint")
@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')

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
        string(name: 'GERRIT_REFSPEC', description: 'Gerrit Refspec of the cnint git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
    }
    triggers {
        gerrit (
            serverName: 'GerritCentral',
            gerritProjects: [[
                compareType: 'PLAIN',
                pattern: 'EEA/cnint',
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

        stage('Checkout cnint') {
            steps {
                script {
                    gitcnint.checkoutRefSpec("${GERRIT_REFSPEC}", 'FETCH_HEAD', '')
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
                    if ( GERRIT_CHANGE_OWNER_NAME == "ECEAGIT" && GERRIT_CHANGE_SUBJECT.contains("Automatic uplifting")) {
                        env.SKIP_REVIEWERS_VALIDATION = true
                        env.PATCHSET_ALLOWED_TO_MERGE = true
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
                    def reviewRules = readYaml file: "technicals/cnint_reviewers.yaml"
                    try {
                        result = gitcnint.verifyCodeReviewers("${GERRIT_REFSPEC}", reviewRules)
                    }
                    catch (err) {
                        error err.message
                    }
                    if (!result) {
                        error ("Verify reviewers failed")
                    }
                    env.PATCHSET_ALLOWED_TO_MERGE = true
                    message = "Authorized CR+1 was found, change added to the queue"
                    sendMessageToGerrit(env.GERRIT_REFSPEC, message)
                }
            }
        }

        stage('Execute eea_app_baseline_manual_flow_codereview_ok job') {
            when {
                expression { env.PATCHSET_ALLOWED_TO_MERGE }
            }
            steps {
                script {
                    codereview_ok_job = build job: "eea-app-baseline-manual-flow-codereview-ok", parameters: [
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
        cleanup {
            cleanWs()
        }
    }
}
