@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def git = new GitScm(this, 'EEA/adp-app-staging')

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
                    pattern: 'EEA/adp-app-staging',
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

        stage('Checkout - scripts'){
            steps{
                script {
                    git.sparseCheckout("technicals/")
                }
            }
        }

        stage('Checkout'){
            steps{
                script {
                    git.checkoutRefSpec("${GERRIT_REFSPEC}","FETCH_HEAD",'adp-app-staging')
                }
            }
        }

        stage('Check Ruleset') {
            steps {
                script {
                    git.checkRulesetRepo("${GERRIT_REFSPEC}")
                }
            }
        }

        stage('Prepare') {
            steps {
                dir('adp-app-staging') {
                    checkoutGitSubmodules()
                }
            }
        }

        stage('Rulesets DryRun') {
            steps {
                dir('adp-app-staging') {
                    script {
                        rulesetsDryRun()
                    }
                }
            }
        }

        stage('Rulesets Validations') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE'){
                    script {
                        build job: "ruleset-change-validate", parameters: [
                            booleanParam(name: 'dry_run', value: false),
                            stringParam(name: 'GERRIT_PROJECT', value : "${env.GERRIT_PROJECT}"),
                            stringParam(name: 'GERRIT_REFSPEC', value : "${env.GERRIT_REFSPEC}"),
                            stringParam(name: 'GERRIT_HOST', value : "${env.GERRIT_HOST}"),
                            stringParam(name: 'GERRIT_BRANCH', value : "${env.GERRIT_BRANCH}"),
                            stringParam(name: 'GERRIT_PORT', value : "${env.GERRIT_PORT}"),
                            stringParam(name: 'GERRIT_CHANGE_URL', value : "${env.GERRIT_CHANGE_URL}"),
                            stringParam(name: 'GERRIT_CHANGE_NUMBER', value : "${env.GERRIT_CHANGE_NUMBER}"),
                        ]
                    }
                }
            }
        }

        stage('Jenkins patchset hooks') {
            steps {
                script {
                    sh "cd ${WORKSPACE} && ./technicals/shellscripts/run_verify_hooks.sh \$GERRIT_PATCHSET_REVISION \$BUILD_URL"
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
