@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def gitdoc = new GitScm(this, 'EEA/eea4_documentation')

pipeline {
    agent {
        node {
            label 'productci'
        }
    }
    options {
      buildDiscarder(logRotator(daysToKeepStr: "7"))
    }
    parameters {
        string(name: 'GERRIT_REFSPEC',  description: 'Gerrit Refspect of the eea4_documentation git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'PWD',  description: 'The source docs folder (${env.PWD}/doc_src) can be defined, volume target in the container should be /doc_src', defaultValue: 'doc')
    }
    triggers {
        gerrit (
            serverName: 'GerritCentral',
            gerritProjects: [[
                compareType: 'PLAIN',
                pattern: 'EEA/eea4_documentation',
                branches: [[ compareType: 'PLAIN', pattern: env.MAIN_BRANCH ]]
            ]],
            triggerOnEvents:  [
                [
                    $class              : 'PluginChangeMergedEvent',
                    excludeDrafts       : true,
                    excludeTrivialRebase: false,
                    excludeNoCodeChange : false
                ],
                [
                    $class                      : 'PluginCommentAddedContainsEvent',
                    commentAddedCommentContains : '.*rebuild-preview.*'
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

        stage('Checkout - eea4_documentation'){
            steps{
                script{
                    gitdoc.checkoutRefSpec("${GERRIT_REFSPEC}","FETCH_HEAD", 'eea4_documentation')
                }
            }
        }

        stage('Check Ruleset') {
            steps {
                script {
                    gitdoc.checkRulesetRepo("${GERRIT_REFSPEC}")
                }
            }
        }

        stage('Prepare') {
            steps {
                dir('eea4_documentation') {
                    checkoutGitSubmodules()
                }
            }
        }

        stage('Build preview package') {
            steps {
                dir('eea4_documentation') {
                    script {
                        withCredentials([ string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN')]){
                          sh 'bob/bob -r bob-rulesets/documentation_preview.yaml build-preview-package'
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
