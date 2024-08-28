@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def githelper = new GitScm(this, 'EEA/eea4-prod-ci-helper')

def dockerFile = 'docker/Dockerfile'
def version

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
    parameters {
        string(name: 'GERRIT_REFSPEC', description: 'Gerrit Refspec of the eea4-prod-ci-helper git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
        booleanParam(name: 'SKIP_PUBLISH', description: 'Executes only the validation parts and skip the publish parts (submit, merge, tagging, etc.)', defaultValue: false)
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

        stage('Gerrit message') {
            when {
                expression { env.GERRIT_REFSPEC }
            }
            steps {
                script {
                    env.GERRIT_MSG = "Build Started ${BUILD_URL}"
                    sendMessageToGerrit(env.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }

        stage('Checkout technicals'){
            steps {
                script {
                    gitadp.sparseCheckout("technicals/")
                }
            }
        }

        stage('Rebase') {
            when {
                expression { env.GERRIT_REFSPEC }
            }
            steps {
                sh "technicals/shellscripts/gerrit_rebase.sh --refspec ${env.GERRIT_REFSPEC}"
            }
        }

        stage('Validate patchset'){
            steps {
                script {
                    env.REFSPEC_TO_VALIDATE = env.GERRIT_REFSPEC
                    def reviewRules = readYaml file: "technicals/eea4-prod-ci-helper_reviewers.yaml"
                    try {
                        env.REFSPEC_TO_VALIDATE = githelper.checkAndGetCommitLastPatchSetReviewed(env.REFSPEC_TO_VALIDATE,reviewRules)
                    }
                    catch (Exception e) {
                        sendMessageToGerrit(env.GERRIT_REFSPEC, e.message)
                        error("""FAILURE: Validate patchset failed with exception: ${e.class.name},message:  ${e.message}
                        """)
                    }
                     // override with the latest refspec
                    env.GERRIT_REFSPEC = env.REFSPEC_TO_VALIDATE
                    echo ("Latest gerrit refspec:  ${env.GERRIT_REFSPEC}")
                }
            }
        }

        stage('Checkout LATEST_GERRIT_REFSPEC') {
            steps {
                script {
                    githelper.checkoutRefSpec("${env.GERRIT_REFSPEC}", "FETCH_HEAD", "eea4-prod-ci-helper")
                    dir('eea4-prod-ci-helper') {
                        env.COMMIT_ID = githelper.getCommitHashLong()
                        echo "env.COMMIT_ID=${env.COMMIT_ID}"
                    }
                }
            }
        }

        stage('Prepare') {
            steps {
                dir('eea4-prod-ci-helper') {
                    checkoutGitSubmodules()
                }
            }
        }

        stage("Docker build") {
            steps {
                dir('eea4-prod-ci-helper') {
                    script {
                        echo "Building docker image"
                        sh "bob/bob -r bob-rulesets/ruleset2.0.yaml init-drop"
                        version = readFile(".bob/var.version")
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

        stage('Submit & merge changes to master') {
            when {
                expression { params.SKIP_PUBLISH == false }
            }
            steps {
                dir ('eea4-prod-ci-helper') {
                    script {
                        githelper.gerritReviewAndSubmit(env.COMMIT_ID, '--verified +1 --code-review +2 --submit', 'EEA/eea4-prod-ci-helper')
                    }
                }
            }
        }

        stage('Publish docker image') {
            when {
                expression { params.SKIP_PUBLISH == false }
            }
            steps {
                dir ('eea4-prod-ci-helper') {
                    script {
                        withCredentials ([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                            sh "bob/bob -r bob-rulesets/ruleset2.0.yaml docker-image-publish"
                        }
                    }
                }
            }
        }

        stage('Create Git Tag') {
            when {
                expression { params.SKIP_PUBLISH == false }
            }
            steps {
                dir('eea4-prod-ci-helper') {
                    script {
                        githelper.createOrMoveRemoteGitTag("${version}", "${version}")
                    }
                }
            }
        }
    }

    post {
        failure {
            script {
                if (env.GERRIT_REFSPEC) {
                    env.GERRIT_MSG = "Build Failed ${BUILD_URL}: FAILURE"
                    sendMessageToGerrit(env.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }
        success {
            script {
                if (env.GERRIT_REFSPEC) {
                    env.GERRIT_MSG = "Build Successful ${BUILD_URL}: SUCCESS"
                    sendMessageToGerrit(env.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }
        cleanup {
            cleanWs()
        }
    }
}
