@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def git = new GitScm(this, 'EEA/adp-app-staging')

pipeline {
    agent {
        node {
            label 'master'
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
                pattern: 'EEA/adp-app-staging',
                branches: [[ compareType: 'PLAIN', pattern: env.MAIN_BRANCH ]],
                disableStrictForbiddenFileVerification: false,
                topics: [[ compareType: 'REG_EXP', pattern: '^((?!^inca$).)*$' ]],
                filePaths: [[ compareType: 'ANT', pattern: 'technicals/**/*.groovy' ]]
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

        stage('Checkout') {
            steps {
                script {
                    git.checkoutRefSpec("${GERRIT_REFSPEC}", "FETCH_HEAD", 'adp-app-staging')
                }
            }
        }

        stage('Job DSL generation and content validation') {
            steps {
                script {
                    try {
                        sh(
                            script: "(cd 'adp-app-staging' && find technicals/ -name '*.groovy' -print0 | xargs -0 git diff-tree --no-commit-id --name-only -r HEAD --diff-filter=ACMRT) > env_inject"
                        )
                        def result = readFile("env_inject")
                        if (result.size() != 0) {
                            echo "result not null"
                            def files = result.split("\\r?\\n")
                            script{
                                for (filename in files) {
                                    def result_generation = sh(
                                        script: "export JAVA_HOME=/proj/cea/tools/environments/jdk/jdk-11.0.6 ; cd adp-app-staging && gradle genJob -Partifactory_contextUrl=${ARM_CONTEXT_URL} -PjobFileName=${filename} -g ${WORKSPACE}/gradle",
                                        returnStatus: true
                                    )
                                    sh "echo ${result_generation}"
                                    if (result_generation != 0) {
                                        currentBuild.result = 'FAILURE'
                                    }
                                }
                            }
                            def result_validation = sh(
                                script: "cd adp-app-staging/build/jobs; python ${WORKSPACE}/adp-app-staging/technicals/pythonscripts/jobdslgroovycontent.py",
                                returnStatus: true
                            )
                            sh "echo ${result_validation}"
                            if (result_validation != 0) {
                                currentBuild.result = 'FAILURE'
                            }
                        }
                    }
                    catch (err) {
                        echo "Caught: ${err}"
                        currentBuild.result = 'FAILURE'
                    }
                }
            }
        }

        stage('Validating Jenkinsfile existence') {
            steps {
                script {
                    try {
                        def result = sh(
                            script: "cd 'adp-app-staging' && ./technicals/shellscripts/collect_jenkinsfiles.sh 'adp-app-staging'",
                            returnStatus: true
                        )
                        sh "echo ${result}"
                        if (result != 0) {
                            echo 'Jenkinsfile existence check FAILED:'
                            sh 'cat adp-app-staging/err_inject'
                            currentBuild.result = 'FAILURE'
                        }
                    } catch (err) {
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
