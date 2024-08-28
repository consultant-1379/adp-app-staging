@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import hudson.Util

@Field def git = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitmeta = new GitScm(this, 'EEA/project-meta-baseline')

pipeline {
    options { buildDiscarder(logRotator(daysToKeepStr: "7"))}
    agent {
        node {
            label 'productci'
        }
    }

    parameters {
        string(name: 'CHART_NAME', description: 'Chart name e.g.: eric-ms-b', defaultValue: '')
        string(name: 'CHART_REPO', description: 'Chart repo e.g.: https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm', defaultValue: '')
        string(name: 'CHART_VERSION', description: 'Chart version e.g.: 1.0.0-1', defaultValue: '')
        string(name: 'GERRIT_REFSPEC', description: 'Gerrit Refspect of the integration chart git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'SPINNAKER_TRIGGER_URL', description: 'Spinnaker pipeline triggering url', defaultValue: '')
        string(name: 'REPOSITORY', description: 'ARM repository of the test results repo.', defaultValue: 'proj-eea-reports-generic-local')
    }

    environment {
        REPORT_REPO_PATH = "https://arm.seli.gic.ericsson.se/artifactory/proj-eea-reports-generic-local"
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
            steps {
                script {
                    try {
                        sh 'technicals/shellscripts/gerrit_message.sh ${GERRIT_REFSPEC} "Build Started ${BUILD_URL}"'
                    }
                    catch (err) {
                        echo "Caught: ${err}"
                    }
                }
             }
         }

        stage('Checkout metabaseline') {
            steps {
                script {
                    gitmeta.checkout(env.MAIN_BRANCH, 'project-meta-baseline')
                }
            }
        }

        stage('Checkout adp-app-staging') {
            steps {
                script {
                    git.sparseCheckout("technicals/")
                }
            }
        }

        stage('Prepare') {
            steps {
                dir('project-meta-baseline') {
                    checkoutGitSubmodules()
                }
            }
        }

        stage('Init') {
            steps {
                script {
                    // Generate log url link name and log directory names
                    def name = CHART_NAME + ': ' + CHART_VERSION
                    def gerrit_link = null
                    if (params.GERRIT_REFSPEC != '') {
                        name = "manual change"
                        gerrit_link = getGerritLink(params.GERRIT_REFSPEC)
                    }
                    // Setup build info
                    currentBuild.description = name
                    if (gerrit_link) {
                        currentBuild.description += '<br>' + gerrit_link
                    }
                }
            }
        }

        stage('Clean') {
            steps {
                dir('project-meta-baseline') {
                    sh './bob/bob clean'
                }
            }
        }

        stage('Input sanity check for helm chart') {
            steps {
                dir('project-meta-baseline') {
                    withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                     string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                     string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                     usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                        sh './bob/bob prepare-common'
                        sh './bob/bob lint-helm3'
                    }
                }
            }
        }

    }
}
