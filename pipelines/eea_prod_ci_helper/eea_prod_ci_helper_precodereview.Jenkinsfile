@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def githelper = new GitScm(this, 'EEA/eea4-prod-ci-helper')
@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')

// changed files to validate
def dockerFile = 'docker/Dockerfile'

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
                pattern: 'EEA/eea4-prod-ci-helper',
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
        stage("Params DryRun check") {
            when {
                expression { params.DRY_RUN == true }
            }
            steps {
                script {
                    dryRun()
                }
            }
        }

        stage("Checkout - eea4-prod-ci-helper") {
            steps {
                script {
                    githelper.checkoutRefSpec("${GERRIT_REFSPEC}", "FETCH_HEAD", "eea4-prod-ci-helper")
                }
            }
        }

        stage("Prepare") {
            steps {
                dir('eea4-prod-ci-helper') {
                    checkoutGitSubmodules()
                }
            }
        }

        stage("Checkout - scripts") {
            steps {
                dir("technicals") {
                    script {
                        gitadp.archiveDir('EEA/adp-app-staging', 'HEAD:technicals/')
                    }
                }
            }
        }

        stage("Jenkins patchset hooks") {
            steps {
                dir('eea4-prod-ci-helper') {
                    script {
                        try {
                            def result = sh(
                                    script: "${WORKSPACE}/technicals/shellscripts/run_verify_hooks_common.sh \$GERRIT_PATCHSET_REVISION \$BUILD_URL ${WORKSPACE}/eea4-prod-ci-helper ${WORKSPACE} technicals/hooks_static/pre_* technicals/hooks/pre_*",
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
        }

        stage('Markdownlint') {
            steps {
                dir('eea4-prod-ci-helper') {
                    script {
                        env.MD_FILES = sh(script: 'git diff-tree --no-commit-id --name-only -r HEAD --diff-filter=ACMRT -- | grep .md$ | tr "\r\n" " " ', returnStdout: true).trim()
                        if ( env.MD_FILES ) {
                            echo ".md files in change ${GERRIT_REFSPEC}: ${env.MD_FILES}"
                            withEnv(["MD_FILES=${env.MD_FILES}"]) { sh "bob/bob -r bob-rulesets/ruleset2.0.yaml markdown-lint" }
                        } else {
                            echo "No .md files in change ${GERRIT_REFSPEC}, SKIP Markdownlint."
                        }
                    }
                }
            }
        }

        stage("Docker build") {
            steps {
                dir('eea4-prod-ci-helper') {
                    script {
                        echo "Building docker image"
                        sh "bob/bob -r bob-rulesets/ruleset2.0.yaml init-precodereview"
                        def version = readFile(".bob/var.version")
                        echo "Docker image version: ${version}"
                        withEnv(["DOCKER_FILE=${dockerFile}"]) { sh "bob/bob -r bob-rulesets/ruleset2.0.yaml docker-image-build"}
                    }
                }
            }
        }

        stage("Validate docker image") {
            steps {
                dir('eea4-prod-ci-helper') {
                    script {
                        echo "Check kubectl & Helm version"
                        sh "bob/bob -r bob-rulesets/ruleset2.0.yaml docker-image-test"
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
