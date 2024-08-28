@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def git = new GitScm(this, 'EEA/adp-app-staging')
@Field def git_shared_lib = new GitScm(this, 'EEA/ci_shared_libraries')

pipeline {
    options {
        disableConcurrentBuilds()
        buildDiscarder(logRotator(daysToKeepStr: '14', artifactDaysToKeepStr: '7'))
    }
    agent {
        node {
            label 'productci'
        }
    }
    parameters {
        string(name: 'CHART_NAME', description: 'Chart name e.g.: eric-ms-b', defaultValue: '')
        string(name: 'CHART_REPO', description: 'Chart repo e.g.: https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm', defaultValue: '')
        string(name: 'CHART_VERSION', description: 'Chart version e.g.: 1.0.0-1', defaultValue: '')
        string(name: 'GERRIT_REFSPEC',  description: 'Gerrit Refspec of the integration chart git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'SPINNAKER_TRIGGER_URL', description: 'Spinnaker pipeline triggering url', defaultValue: '') // spinnaker trigger url
        string(name: 'SPINNAKER_ID', description: "The spinnaker execution's id", defaultValue: '')
    }
    environment {
        // SYSTEM can be selected e.g. using Lockable Resources
        SYSTEM = "hoff130"
        LATEST_CI_LIB_GIT_TAG = "LATEST_CI_LIB"
        LATEST_CI_LIB_GIT_TAG_MSG = "Latest CI Shared Libraries version ${params.CHART_VERSION}"
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
                    if(params.GERRIT_REFSPEC != '') {
                        env.GERRIT_MSG = "Build Started ${BUILD_URL}"
                        sendMessageToGerrit(params.GERRIT_REFSPEC, env.GERRIT_MSG)
                    }
                }
            }
        }

        stage('Validate patchset changes') {
            when {
                expression { params.GERRIT_REFSPEC }
            }
            steps {
                script {
                    def result = git.verifyNoNewPathSet(params.GERRIT_REFSPEC)
                    if (!result) {
                        error ('New patchset created since stage Prepare')
                    }
                }
            }
        }

        stage('Checkout') {
            steps {
                script {
                    git.checkout(env.MAIN_BRANCH, "")
                }
            }
        }

        stage('Prepare') {
            steps {
                checkoutGitSubmodules()
            }
        }

        stage('Checkout ci_shared_libraries') {
            when {
                expression { params.CHART_NAME == 'eric-eea-ci-shared-lib' }
            }
            steps {
                script {
                    git_shared_lib.checkout(env.MAIN_BRANCH, "ci_shared_libraries")
                }
            }
        }

        stage('Init') {
            steps {
                script {
                    if (params.GERRIT_REFSPEC != null && params.GERRIT_REFSPEC != '') {
                        def tokens = params.GERRIT_REFSPEC.split("/")
                        if (tokens.length == 5) {
                            def link = getGerritLink(params.GERRIT_REFSPEC)
                            currentBuild.description = link
                        } else {
                            def link = '<a href="' + env.BUILD_NUMBER + '/console">' + params.GERRIT_REFSPEC + '</a>'
                            currentBuild.description = link
                        }
                    } else {
                        def link = '<a href="' + env.BUILD_NUMBER + '/console">' + params.CHART_NAME + ':' + params.CHART_VERSION + '</a>'
                        currentBuild.description = link
                    }

                    if ( params.SPINNAKER_ID != '' ) {
                        currentBuild.description += '<br><a href="https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/details/' + params.SPINNAKER_ID + '">Spinnaker URL: ' + params.SPINNAKER_ID + '</a>'
                    }

                }
            }
        }

        stage('Publish Helm Chart') {
            steps {
                // Generate integration helm chart
                withCredentials([
                                usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD'),
                                string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                    sh 'bob/bob publish'
                }
            }
        }

        stage('Publish LATEST_CI_LIB Git tag') {
            when {
                expression { params.CHART_NAME == 'eric-eea-ci-shared-lib' }
            }
            steps {
                script {
                    dir("ci_shared_libraries") {
                        def remoteTag = git_shared_lib.checkRemoteGitTagExists(params.CHART_VERSION)
                        if ( remoteTag ) {
                            env.LATEST_CI_LIB_COMMIT_ID = remoteTag.split()[0]
                        } else {
                            error: "No commit exists with tag ${params.CHART_VERSION}"
                        }
                        // set LATEST_CI_LIB tag to the tested version (params.CHART_VERSION in this case)
                        git_shared_lib.createOrMoveRemoteGitTag(env.LATEST_CI_LIB_GIT_TAG, env.LATEST_CI_LIB_GIT_TAG_MSG, env.LATEST_CI_LIB_COMMIT_ID)
                        latestTag = git_shared_lib.checkRemoteGitTagExists(env.LATEST_CI_LIB_GIT_TAG)
                        echo "LATEST_CI_LIB commit: ${latestTag}"
                    }
                }
            }
        }

        stage('Archive artifact.properties') {
            steps {
                // Archive artifact.properties so Spinnaker can read the parameters
                archiveArtifacts 'artifact.properties'
            }
        }
    }
    post {
        success {
            script{
                if(params.GERRIT_REFSPEC != '') {
                    env.GERRIT_MSG = "Build Successful ${BUILD_URL}: SUCCESS"
                    sendMessageToGerrit(params.GERRIT_REFSPEC, env.GERRIT_MSG)
                }

                if ( params.CHART_REPO != null && params.CHART_REPO != '' ){
                    if ( params.CHART_REPO.contains('proj-adp-gs-all-helm')){
                        def recipient = 'PDLEEA3PPH@pdl.internal.ericsson.com'
                        mail subject: "New ADP GS added into EEA4:  ${params.CHART_NAME} (${params.CHART_VERSION})",
                        body: "ADP GS name: ${params.CHART_NAME}, helm chart link: ${params.CHART_REPO}, helm chart version:  ${params.CHART_VERSION} ",
                        to: "${recipient}",
                        replyTo: "${recipient}",
                        from: 'eea-seliius27190@ericsson.com'
                    }
                }
            }
        }
        failure {
            script {
                if(params.GERRIT_REFSPEC != '') {
                    env.GERRIT_MSG = "Build Failed ${BUILD_URL}: FAILURE"
                    sendMessageToGerrit(params.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }
        cleanup {
            cleanWs()
        }
    }
}
