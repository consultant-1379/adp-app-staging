@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitrv = new GitScm(this, 'EEA/eea4-rv')

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
                    pattern: 'EEA/eea4-rv',
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

        stage('Checkout - scripts') {
            steps{
                script{
                    gitadp.sparseCheckout("technicals/")
                }
            }
        }

        stage('Checkout - eea4-rv') {
            steps{
                script{
                    gitrv.checkoutRefSpec("${GERRIT_REFSPEC}","FETCH_HEAD", 'eea4-rv')
                }
            }
        }

        stage('Jenkins patchset hooks') {
            steps {
                script {
                    try{
                        def result = sh(
                                script: "cd ${WORKSPACE} && ./technicals/shellscripts/run_verify_hooks.sh \$GERRIT_PATCHSET_REVISION \$BUILD_URL ${WORKSPACE} technicals/hooks_static/pre_* technicals/hooks/pre_*",
                                returnStatus : true
                        )
                        sh "echo ${result}"
                        if (result != 0){
                            currentBuild.result = 'FAILURE'
                        }
                    }catch (err) {
                        echo "Caught: ${err}"
                        currentBuild.result = 'FAILURE'
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
