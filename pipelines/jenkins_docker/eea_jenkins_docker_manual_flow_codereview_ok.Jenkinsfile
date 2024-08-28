@Library('ci_shared_library_eea4') _

import groovy.transform.Field

import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.Artifactory

@Field def gitjd = new GitScm(this, 'EEA/jenkins-docker')
@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')

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
                pattern: 'EEA/jenkins-docker',
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

        stage ('Check Reviewer') {
            steps {
                script {
                    env.CI_GROUP = 'EEA4\\ CI\\ team'
                    env.REVIEWERS_LIST = gitjd.listGerritMembers(env.CI_GROUP)
                    sh '''
                    set +x
                    [[ ${REVIEWERS_LIST} =~ ${GERRIT_EVENT_ACCOUNT_EMAIL} ]] && \
                        echo "${GERRIT_EVENT_ACCOUNT} found in the EEA4 CI team Gerrit Group" || \
                        { echo "Need a Code-Review from the EEA4 CI team Gerrit Group member! Members:\n${REVIEWERS_LIST}" ; exit 1; }
                    set -x
                    '''
                }
            }
        }

        stage('Checkout - scripts') {
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

        stage('Set LATEST_GERRIT_REFSPEC') {
            steps {
                script {
                    env.GERRIT_CHANGE_NUMBER = gitjd.getCommitIdFromRefspec(params.GERRIT_REFSPEC)
                    echo "env.GERRIT_CHANGE_NUMBER=${env.GERRIT_CHANGE_NUMBER}"

                    env.LATEST_GERRIT_REFSPEC = gitjd.getCommitRefSpec(env.GERRIT_CHANGE_NUMBER)
                    echo "env.LATEST_GERRIT_REFSPEC=${env.LATEST_GERRIT_REFSPEC}"

                    if (env.LATEST_GERRIT_REFSPEC != params.GERRIT_REFSPEC) {
                        echo "There is newer patchset then ${params.GERRIT_REFSPEC}, using this: ${env.LATEST_GERRIT_REFSPEC}"
                        // override with the latest refspec
                        env.GERRIT_REFSPEC = env.LATEST_GERRIT_REFSPEC
                    }
                }
            }
        }

        stage('Checkout LATEST_GERRIT_REFSPEC') {
            steps {
                script {
                    gitjd.checkoutRefSpec("${env.GERRIT_REFSPEC}", "FETCH_HEAD", "jenkins-docker")
                    dir('jenkins-docker') {
                        env.COMMIT_ID = gitjd.getCommitHashLong()
                        echo "env.COMMIT_ID=${env.COMMIT_ID}"
                    }
                }
            }
        }

        stage('Prepare') {
            steps {
                dir('jenkins-docker') {
                    checkoutGitSubmodules()
                }
            }
        }

        stage('Clean') {
            steps {
                dir('jenkins-docker') {
                    script {
                        sh 'bob/bob -r bob-rulesets/ruleset2.0.yaml clean'
                    }
                }
            }
        }

        stage('Init') {
            steps {
                dir ('jenkins-docker') {
                    script {
                        withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'HELM_USER', passwordVariable: 'API_TOKEN_EEA'),
                                     string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP')]) {
                            sh './bob/bob -r bob-rulesets/ruleset2.0.yaml init-ci-internal'
                            env.CHART_VERSION = readFile(".bob/var.docker-image-version").trim()
                            env.CHART_NAME = readFile(".bob/var.hc-name").trim()
                            env.CHART_REPO = readFile(".bob/var.hc-repopath").trim()
                            echo "env.CHART_VERSION: ${env.CHART_VERSION}"
                            echo "env.CHART_NAME: ${env.CHART_NAME}"
                            echo "env.CHART_REPO: ${env.CHART_REPO}"
                        }
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                dir('jenkins-docker') {
                    sh 'bob/bob -r bob-rulesets/ruleset2.0.yaml build-docker-image'
                }
            }
        }

        stage('Test Docker Image') {
            steps {
                dir('jenkins-docker') {
                    script {
                        withEnv(["JENKINS_DOCKER_CONTAINER_LOGFILE=jenkins_docker_container.log"]) {
                            try {
                                sh 'bob/bob -r bob-rulesets/ruleset2.0.yaml test-docker-image'
                            } catch (err) {
                                error "TEST DOCKER IMAGE FAILED\nCaught: ${err}"
                            } finally {
                                archiveArtifacts artifacts: "${JENKINS_DOCKER_CONTAINER_LOGFILE}", allowEmptyArchive: true
                            }
                        }
                    }
                }
            }
        }

        stage('Cleanup Docker Image') {
            steps {
                dir('jenkins-docker') {
                    withEnv(["DOCKER_IMAGE_VERSION=${env.INT_CHART_VERSION}"]) {
                        sh 'bob/bob -r bob-rulesets/ruleset2.0.yaml cleanup-docker-image'
                    }
                }
            }
        }

        stage('Check skip-testing comment exist') {
            steps {
                script {
                    env.SKIP_TESTING = gitjd.getCommitComments("${env.GERRIT_CHANGE_ID}", "skip-testing").contains("skip-testing")
                }
            }
        }

        stage('Check which files changed to skip testing'){
            when {
                expression { !env.SKIP_TESTING.toBoolean() }
            }
            steps {
                dir ('jenkins-docker') {
                    script {
                        catchError(stageResult: 'FAILURE', buildResult: currentBuild.result) {
                            try {
                                if (env.GERRIT_REFSPEC) {
                                    env.SKIP_TESTING = checkIfCommitContainsOnlySkippableFiles(env.GERRIT_REFSPEC, [".md"])
                                }
                            }
                            catch (err) {
                                error "Caught: ${err}"
                            }
                        }
                    }
                }
            }
        }

        stage('Archive artifact.properties') {
            steps {
                dir('jenkins-docker') {
                    script {
                        sh "echo 'GERRIT_REFSPEC=${env.GERRIT_REFSPEC}' >> artifact.properties"
                        sh "echo 'GERRIT_CHANGE_SUBJECT=${env.GERRIT_CHANGE_SUBJECT}' >> artifact.properties"
                        sh "echo 'GERRIT_CHANGE_OWNER_NAME=${env.GERRIT_CHANGE_OWNER_NAME}' >> artifact.properties"
                        sh "echo 'SKIP_TESTING=${env.SKIP_TESTING}' >> artifact.properties"
                        archiveArtifacts artifacts: 'artifact.properties', allowEmptyArchive: true
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
