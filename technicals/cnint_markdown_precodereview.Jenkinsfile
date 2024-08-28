@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitcnint = new GitScm(this, 'EEA/cnint')

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
                    pattern: 'EEA/cnint',
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
                    excludeNoCodeChange : false,
                    uploaderNameContainsRegEx : '^((?!ECEAGIT).)*$'
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

        stage('Checkout cnint Refspec'){
            steps{
                script {
                    echo "checkoutRefSpec: ${GERRIT_REFSPEC}"
                    gitcnint.checkoutRefSpec("${GERRIT_REFSPEC}","FETCH_HEAD",'cnint')
                }
            }
        }

        stage('Checkout adp-app-staging'){
            steps{
                script {
                    gitadp.checkout('master', 'adp-app-staging')
                }
            }
        }

        stage('Prepare') {
            steps {
                dir('cnint'){
                    checkoutGitSubmodules()
                }
            }
        }

        stage('Lint') {
            steps {
                dir('cnint') {
                    script {
                        env.MD_FILES = sh(script: 'git diff-tree --no-commit-id --name-only -r HEAD --diff-filter=ACMRT -- | grep .md$ | sed "s#^#cnint/#g" - |  tr "\r\n" " " ', returnStdout: true).trim()
                        if ( env.MD_FILES ) {
                            echo ".md files in change ${GERRIT_REFSPEC}: ${env.MD_FILES}"
                            withEnv(["MD_FILES=${env.MD_FILES}"]) {
                                sh "cp ${WORKSPACE}/adp-app-staging/ruleset2.0.yaml adp_app_staging_ruleset2.0.yaml"
                                sh "bob/bob -r adp_app_staging_ruleset2.0.yaml markdown-lint"
                            }
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
