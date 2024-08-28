@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitlib = new GitScm(this, 'EEA/ci_shared_libraries')

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
    triggers {
        gerrit (
            serverName: 'GerritCentral',
            gerritProjects: [[
                compareType: 'PLAIN',
                pattern: 'EEA/ci_shared_libraries',
                branches: [[ compareType: 'PLAIN', pattern: env.MAIN_BRANCH ]],
                disableStrictForbiddenFileVerification: false,
                topics: [[ compareType: 'REG_EXP', pattern: '^((?!^inca$).)*$' ]]
            ]],
            triggerOnEvents:  [
                [
                    $class              : 'PluginPatchsetCreatedEvent',
                    excludeDrafts       : true,
                    excludeTrivialRebase: false,
                    excludeNoCodeChange : false
                ],
                [
                    $class                      : 'PluginCommentAddedContainsEvent',
                    commentAddedCommentContains : '.*rebuild.*'
                ],
                [
                    $class                      : 'PluginDraftPublishedEvent'
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

        stage('Checkout - ci_shared_libraries') {
            steps {
                script {
                    gitlib.checkoutRefSpec("${GERRIT_REFSPEC}", "FETCH_HEAD", '')
                }
            }
        }

        stage('Prepare') {
            steps {
                checkoutGitSubmodules()
            }
        }

        stage('Rulesets DryRun') {
            steps {
                script {
                    rulesetsDryRun()
                }
            }
        }

        stage('Checkout - scripts') {
            steps {
                dir('technicals') {
                    withCredentials([usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GIT_USER', passwordVariable: 'PASSWORD' )]) {
                        script {
                            gitadp.archiveDir('EEA/adp-app-staging', 'HEAD:technicals/')
                        }
                    }
                }
            }
        }

        stage('Check Ruleset') {
            steps {
                script {
                    gitlib.checkRulesetRepo("${GERRIT_REFSPEC}")
                }
            }
        }

        stage('Jenkins patchset hooks') {
            steps {
                script {
                    try {
                        def result = sh(
                                script: "cd ${WORKSPACE} && ./technicals/shellscripts/run_verify_hooks_common.sh \$GERRIT_PATCHSET_REVISION \$BUILD_URL ${WORKSPACE}",
                                returnStatus : true
                        )
                        sh "echo ${result}"
                        if (result != 0) {
                            currentBuild.result = 'FAILURE'
                        }
                    } catch (err) {
                        echo "Caught: ${err}"
                        currentBuild.result = 'FAILURE'
                    }
                }
            }
        }
        // Unit tests stage here
    }
    post {
        cleanup {
            cleanWs()
        }
    }
}
