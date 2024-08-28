@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

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
                    filePaths: [[ compareType: 'ANT', pattern: 'ruleset2.0.yaml' ],[ compareType: 'ANT', pattern: 'bob-rulesets/*' ]]
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
        stage('Checkout master'){
            steps{
                script{
                    gitcnint.checkout(env.MAIN_BRANCH, '')
                }
            }
        }
        stage('Checkout commit'){
            steps{
                script{
                    gitcnint.checkoutRefSpec("${GERRIT_REFSPEC}","FETCH_HEAD", '')
                }
            }
        }
        stage('Check ruleset diff') {
            steps {
                script {
                    try{
                        def result = sh(
                                script: """git diff origin/master""",
                                returnStdout : true
                        )
                        echo """ $result """
                        env.RULESET_CHANGE = result

                    }catch (err) {
                        echo "Caught: ${err}"
                        currentBuild.result = 'FAILURE'
                    }
                }
            }
        }
    }
    post {
        success {
            script {
                try {
                  def recipient = 'd6b48954.ericsson.onmicrosoft.com@emea.teams.ms'
                  mail subject: "Change in cnint/ruleset files",
                  body: """
  Refspec : ${GERRIT_REFSPEC}
  Change URL : ${GERRIT_CHANGE_URL}
  Commit subject : ${GERRIT_CHANGE_SUBJECT}
  Patchset uploader : ${GERRIT_PATCHSET_UPLOADER}
  Commit change ID : ${GERRIT_CHANGE_ID}

  ${env.RULESET_CHANGE}

  """,
                  to: "${recipient}",
                  replyTo: "${recipient}",
                  from: 'eea-seliius27190@ericsson.com'
                } catch (err) {
                  echo "Caught: ${err}"
                }
            }
        }

        cleanup {
            cleanWs()
        }
    }
}
