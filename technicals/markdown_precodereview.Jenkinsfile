@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')

pipeline {

    agent {
        node {
            label 'productci'
        }
    }
    options {
      skipDefaultCheckout()
      buildDiscarder(logRotator(daysToKeepStr: "7"))
    }

    triggers {
        gerrit (
            serverName: 'GerritCentral',
            gerritProjects: [[
                    compareType: 'PLAIN',
                    pattern: 'EEA/adp-app-staging',
                    branches: [[ compareType: 'PLAIN', pattern: env.MAIN_BRANCH ]],
                    disableStrictForbiddenFileVerification: false,
                    topics: [[ compareType: 'REG_EXP', pattern: '^((?!^inca$).)*$' ]],
                    filePaths: [[ compareType: 'ANT', pattern: '*.md' ],
                        [ compareType: 'ANT', pattern: '**/*.md' ]
                    ]
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

        stage('Checkout Refspec'){
            steps{
                script {
                    echo "checkoutRefSpec: ${GERRIT_REFSPEC}"
                    gitadp.checkoutRefSpec("${GERRIT_REFSPEC}","FETCH_HEAD",'adp-app-staging')
                }
            }
        }

        stage('Prepare') {
            steps {
                dir('adp-app-staging'){
                    checkoutGitSubmodules()
                }
            }
        }

        stage('Lint') {
            steps {
                dir('adp-app-staging') {
                    script {
                        env.MD_FILES = sh(script: 'git diff-tree --no-commit-id --name-only -r HEAD --diff-filter=ACMRT -- | grep .md$ | tr "\r\n" " " ', returnStdout: true).trim()
                        if ( env.MD_FILES ) {
                            echo ".md files in change ${GERRIT_REFSPEC}: ${env.MD_FILES}"
                            withEnv(["MD_FILES=${env.MD_FILES}"]) { sh "bob/bob -r ruleset2.0.yaml markdown-lint" }
                        } else {
                            echo "No .md files in change ${GERRIT_REFSPEC}"
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
