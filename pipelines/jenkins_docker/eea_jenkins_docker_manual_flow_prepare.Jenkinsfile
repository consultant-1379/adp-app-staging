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
    parameters {
        string(name: 'GERRIT_REFSPEC',  description: 'Gerrit Refspec of the jenkins-docker git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'PIPELINE_NAME', description: "The spinnaker pipeline name", defaultValue: 'eric-eea-jenkins-docker-drop')
        string(name: 'SPINNAKER_TRIGGER_URL', description: 'Spinnaker pipeline triggering url', defaultValue: '')
        string(name: 'SPINNAKER_ID', description: "The spinnaker execution's id", defaultValue: '')
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

        stage('Set build description') {
            steps {
                script {
                    currentBuild.description = ''
                    if (env.GERRIT_REFSPEC) {
                        def gerritLink = getGerritLink(env.GERRIT_REFSPEC)
                        currentBuild.description += gerritLink
                    }
                    if (params.SPINNAKER_ID) {
                        currentBuild.description += '<br><a href="https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/details/' + params.SPINNAKER_ID + '">Spinnaker URL: ' + params.SPINNAKER_ID + '</a>'
                    }
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
                            env.DOCKER_IMAGE_NAME = readFile(".bob/var.docker-image-name").trim()
                            env.DOCKER_IMAGE_VERSION = readFile(".bob/var.docker-image-version").trim()
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

        stage('Publish Docker Image') {
            steps {
                dir('jenkins-docker') {
                    script {
                        withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                            sh 'bob/bob -r bob-rulesets/ruleset2.0.yaml publish-docker-image'
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

        stage('Package Helm Chart') {
            steps {
                dir('jenkins-docker') {
                    withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'HELM_USER', passwordVariable: 'API_TOKEN_EEA')]) {
                        sh 'bob/bob -r bob-rulesets/ruleset2.0.yaml package-helm-chart'
                    }
                }
            }
        }

        stage('Publish Helm Chart') {
            steps {
                dir('jenkins-docker') {
                    script {
                        withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'HELM_USER', passwordVariable: 'API_TOKEN_EEA')]) {
                            sh 'bob/bob -r bob-rulesets/ruleset2.0.yaml publish-helm-chart'
                        }
                    }
                }
            }
        }

        stage('Archive artifact.properties') {
            steps {
                dir('jenkins-docker') {
                    script {
                        sh "echo 'CHART_NAME=${env.CHART_NAME}' >> artifact.properties"
                        sh "echo 'CHART_REPO=${env.CHART_REPO}' >> artifact.properties"
                        sh "echo 'CHART_VERSION=${env.CHART_VERSION}' >> artifact.properties"
                        sh "echo 'DOCKER_IMAGE_NAME=${env.DOCKER_IMAGE_NAME}' >> artifact.properties"
                        sh "echo 'DOCKER_IMAGE_VERSION=${env.DOCKER_IMAGE_VERSION}' >> artifact.properties"
                        sh "echo 'GERRIT_REFSPEC=${env.GERRIT_REFSPEC}' >> artifact.properties"
                        archiveArtifacts artifacts: 'artifact.properties', allowEmptyArchive: true
                    }
                }
            }
        }
    }
    post {
        always {
            script {
                if ( params.GERRIT_REFSPEC ) {
                    env.GERRIT_MSG = "Build result ${BUILD_URL}: ${currentBuild.result}"
                    sendMessageToGerrit(env.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }
        cleanup {
            cleanWs()
        }
    }
}
