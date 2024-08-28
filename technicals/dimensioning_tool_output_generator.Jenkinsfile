@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import com.ericsson.eea4.ci.GlobalVars

@Field def gitcnint = new GitScm(this, 'EEA/cnint')

pipeline {
    agent {
        node {
            label 'productci'
        }
    }

    options {
        ansiColor('xterm')
        buildDiscarder(logRotator(daysToKeepStr: "14", artifactDaysToKeepStr: "7"))
    }

    parameters {
        string(name: 'INT_CHART_NAME', description: 'Chart name e.g.: eric-eea-int-helm-chart', defaultValue: 'eric-eea-int-helm-chart')
        string(name: 'INT_CHART_REPO', description: 'Chart repo e.g.: https://arm.seli.gic.ericsson.se/artifactory/proj-eea-ci-internal-helm/', defaultValue: 'https://arm.seli.gic.ericsson.se/artifactory/proj-eea-ci-internal-helm/')
        string(name: 'INT_CHART_VERSION', description: 'Chart version e.g.: 24.14.0-5', defaultValue: '')
        string(name: 'GERRIT_REFSPEC',  description: 'Gerrit Refspec of the integration chart git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'UTF_CHART_NAME', description: 'UTF chart name, e.g.: eric-eea-utf-application', defaultValue: '')
        string(name: 'UTF_CHART_REPO', description: 'UTF chart repo, e.g.: https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm', defaultValue: '')
        string(name: 'UTF_CHART_VERSION', description: 'UTF chart version, e.g.: 1.770.0-0', defaultValue: '')
        string(name: 'DATASET_NAME', description: 'Dataset name on NFS server, e.g.: EEA_49_20240209', defaultValue: '')
        string(name: 'REPLAY_SPEED', description: 'A speed of the data loading, e.g.: 1', defaultValue: '1')
        booleanParam(name: 'DIMTOOL_VALIDATE_OUTPUT', description: 'Validate dimensioning tool output or not', defaultValue: false)
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

        stage('Check params') {
            steps {
                script {
                    if(!params.INT_CHART_NAME || !params.INT_CHART_REPO || !params.INT_CHART_VERSION || !params.UTF_CHART_NAME || !params.UTF_CHART_REPO || !params.UTF_CHART_VERSION || !params.DATASET_NAME) {
                        error "All the INT_CHART_NAME, INT_CHART_REPO, INT_CHART_VERSION, UTF_CHART_NAME, UTF_CHART_REPO, UTF_CHART_VERSION and DATASET_NAME input parameters should be specified!"
                    }
                }
            }
        }

        stage('Checkout cnint') {
            steps {
                script {
                    if (params.GERRIT_REFSPEC) {
                        gitcnint.checkoutRefSpec("${params.GERRIT_REFSPEC}", "FETCH_HEAD", 'cnint')
                    } else {
                        gitcnint.checkout(env.MAIN_BRANCH, 'cnint')
                    }
                }
            }
        }

        stage('Prepare') {
            steps {
                dir('cnint') {
                    checkoutGitSubmodules()
                }
            }
        }

        stage('Clean') {
            steps {
                dir('cnint') {
                    sh './bob/bob clean'
                }
            }
        }

        stage("Run dimtool") {
            steps {
                dir('cnint') {
                    script {
                        withEnv(["DIMTOOL_CHART_PATH=${WORKSPACE}/cnint/${env.INT_CHART_NAME}",
                                 "UTF_CHART_NAME=${params.UTF_CHART_NAME}",
                                 "UTF_CHART_REPO=${params.UTF_CHART_REPO}",
                                 "UTF_CHART_VERSION=${params.UTF_CHART_VERSION}",
                                 "DATASET_NAME=${params.DATASET_NAME}",
                                 "REPLAY_SPEED=${params.REPLAY_SPEED}",
                                 "DIMTOOL_VALIDATE_OUTPUT=${params.DIMTOOL_VALIDATE_OUTPUT}"
                        ]) {
                            withCredentials([string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                                usernamePassword(credentialsId: 'ECEAART_SEROGIC_API_KEY', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
                                usernamePassword(credentialsId: 'arm-seli-eeaprodart-token', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD')
                            ]) {
                                try {
                                    sh """curl -H "X-JFrog-Art-Api: \${API_TOKEN_EEA}" -o ${env.INT_CHART_NAME}-${env.INT_CHART_VERSION}.tgz ${env.INT_CHART_REPO}/${env.INT_CHART_NAME}/${env.INT_CHART_NAME}-${env.INT_CHART_VERSION}.tgz
                                        cp -f ${env.INT_CHART_NAME}-${env.INT_CHART_VERSION}.tgz .bob/
                                        tar -xzf ${env.INT_CHART_NAME}-${env.INT_CHART_VERSION}.tgz
                                        echo INT_CHART_NAME=${env.INT_CHART_NAME}-${env.INT_CHART_VERSION}
                                       """
                                    sh './bob/bob init dimtool-trigger > dimtool-trigger.log'
                                    sh './bob/bob -r bob-rulesets/dimtool_ruleset.yaml upload-dimtool:upload-to-arm upload-prod-ci-artifacts'
                                    def artifactsLink = readFile(".bob/dimtool-artifacts-link")
                                    currentBuild.description = '<br>Dimtool artifacts: <a href="' + artifactsLink + '">' + env.JOB_NAME + '-' + env.BUILD_NUMBER + '</a>'
                                } catch (err) {
                                    echo "RUN DIMTOOL FAILED"
                                    error "Caught: ${err}"
                                } finally {
                                    archiveArtifacts artifacts: "dimtool-trigger.log", allowEmptyArchive: true
                                }
                            }
                        }

                        env.DIMTOOL_OUTPUT_REPO_URL = "https://arm.seli.gic.ericsson.se"
                        env.DIMTOOL_OUTPUT_REPO = "proj-eea-reports-generic-local/dimtool/prod_ci_artifacts/"
                        env.DIMTOOL_OUTPUT_ARCHIVE_NAME = "eea4-dimensioning-tool-output.zip"
                        env.DIMTOOL_OUTPUT_NAME = JOB_NAME + "-" + BUILD_NUMBER + "/" + DIMTOOL_OUTPUT_ARCHIVE_NAME

                        sh '''
                            echo "DIMTOOL_OUTPUT_REPO_URL=\${DIMTOOL_OUTPUT_REPO_URL}" >> dimToolOutput.properties
                            echo "DIMTOOL_OUTPUT_REPO=\${DIMTOOL_OUTPUT_REPO}" >> dimToolOutput.properties
                            echo "DIMTOOL_OUTPUT_NAME=\${DIMTOOL_OUTPUT_NAME}" >> dimToolOutput.properties
                        '''
                        archiveArtifacts 'dimToolOutput.properties'
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
