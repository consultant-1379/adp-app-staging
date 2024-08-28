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
        string(name: 'GERRIT_REFSPEC', description: 'Gerrit Refspec of the jenkins-docker git repo e.g.: refs/changes/82/13836482/2', defaultValue: '')
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

        stage('Checkout jenkins-docker') {
            steps {
                script {
                    gitjd.checkoutRefSpec("${env.GERRIT_REFSPEC}", "FETCH_HEAD", "jenkins-docker")
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
                            sh './bob/bob -r bob-rulesets/ruleset2.0.yaml init-drop'
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

        stage('Package Helm Chart') {
            steps {
                dir('jenkins-docker') {
                    withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'HELM_USER', passwordVariable: 'API_TOKEN_EEA')]) {
                        sh 'bob/bob -r bob-rulesets/ruleset2.0.yaml package-helm-chart'
                    }
                }
            }
        }

        stage('Submit & merge changes to master') {
            steps {
                dir ('jenkins-docker'){
                    script {
                        env.COMMIT_ID = gitjd.getCommitHashLong()
                        echo "env.COMMIT_ID=${env.COMMIT_ID}"
                        gitjd.gerritReviewAndSubmit(env.COMMIT_ID, '--verified +1 --code-review +2 --submit', 'EEA/jenkins-docker')
                    }
                }
            }
        }

        stage('Create Git Tag') {
            steps {
                dir ('jenkins-docker') {
                    script {
                        gitjd.createOrMoveRemoteGitTag(env.CHART_VERSION, "jenkins-docker-${env.CHART_VERSION}")
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
                script {
                    sh "echo 'CHART_VERSION=${env.CHART_VERSION}' >> artifact.properties"
                    sh "echo 'CHART_REPO=${env.CHART_REPO}' >> artifact.properties"
                    sh "echo 'CHART_NAME=${env.CHART_NAME}' >> artifact.properties"
                    archiveArtifacts artifacts: 'artifact.properties', allowEmptyArchive: true
                }
            }
        }
    }
    post {
        success {
            script {
                if (env.GERRIT_REFSPEC) {
                    env.GERRIT_MSG = "Build Successful ${BUILD_URL}: SUCCESS"
                    sendMessageToGerrit(env.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }
        failure {
            script {
                if (env.GERRIT_REFSPEC) {
                    env.GERRIT_MSG = "Build Failed ${BUILD_URL}: FAILURE"
                    sendMessageToGerrit(env.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }
        cleanup {
            cleanWs()
        }
    }
}