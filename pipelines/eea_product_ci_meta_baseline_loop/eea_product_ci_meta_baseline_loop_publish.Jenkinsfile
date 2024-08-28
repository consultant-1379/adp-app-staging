@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import com.ericsson.eea4.ci.CiDashboard

@Field def git = new GitScm(this, 'EEA/project-meta-baseline')
@Field def dashboard = new CiDashboard(this)

pipeline {
    options {
        disableConcurrentBuilds()
        skipDefaultCheckout()
        buildDiscarder(logRotator(daysToKeepStr: '7', artifactDaysToKeepStr: '3'))
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
        string(name: 'GERRIT_REFSPEC',  description: 'Gerrit Refspect of the integration chart git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'SPINNAKER_TRIGGER_URL', description: 'Spinnaker pipeline triggering url', defaultValue: '')
        string(name: 'SPINNAKER_ID', description: "The spinnaker execution's id", defaultValue: 'test')
    }
    environment {
        // SYSTEM can be selected e.g. using Lockable Resources
        SYSTEM = "hoff130"
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
                    git.checkout('master', '')
                }
            }
        }


        stage('Prepare bob') {
            steps {
                checkoutGitSubmodules()
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

                    if(params.GERRIT_REFSPEC != '') {
                        env.GERRIT_MSG = "Build Started ${BUILD_URL}"
                        sendMessageToGerrit(params.GERRIT_REFSPEC, env.GERRIT_MSG)
                    }

                    if ( params.SPINNAKER_ID != '' ) {
                        currentBuild.description = '<a href="https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/details/' + params.SPINNAKER_ID + '">Spinnaker URL: ' + params.SPINNAKER_ID + '</a>'
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

        stage('Publish Helm Chart') {
            steps {
                // Generate integration helm chart
                withCredentials([
                                usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD'),
                                string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                    script {
                        sh 'bob/bob publish-meta'
                    }
                }
            }
        }

        stage('Init dashboard execution') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    script {
                        readProperties(file: 'artifact.properties').each {key, value -> env[key] = value }
                        def chart_path = ".bob/${env.INT_CHART_NAME}-${env.INT_CHART_VERSION}.tgz"
                        echo "upload chart to dashboard"
                        dashboard.uploadHelm(chart_path, "${env.INT_CHART_VERSION}")

                        def ihcChangeType = dashboard.ihcChangeTypeNewMicroserviceVersion
                        if (params.GERRIT_REFSPEC) {
                            ihcChangeType = dashboard.ihcChangeTypeManual
                        }
                        echo "init IHC change type: ${ihcChangeType}"

                        echo "set execution"
                        dashboard.startExecutionWithArtifactName("project-meta-baseline","${env.BUILD_URL}","${params.SPINNAKER_ID}", "${env.INT_CHART_VERSION}", "${ihcChangeType}","${env.INT_CHART_NAME}"  )
                        dashboard.finishExecution("project-meta-baseline","SUCCESS","${params.SPINNAKER_ID}","${env.INT_CHART_VERSION}")
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
            script {
                try {
                    if ( params.CHART_REPO != null && params.CHART_REPO != '' ) {
                        if ( params.CHART_REPO.contains('proj-adp-gs-all-helm')) {
                            def recipient = 'PDLEEA3PPH@pdl.internal.ericsson.com'
                            mail subject: "New ADP GS added into EEA4:  ${params.CHART_NAME} (${params.CHART_VERSION})",
                            body: "ADP GS name: ${params.CHART_NAME}, helm chart link: ${params.CHART_REPO}, helm chart version:  ${params.CHART_VERSION} ",
                            to: "${recipient}",
                            replyTo: "${recipient}",
                            from: 'eea-seliius27190@ericsson.com'
                        }
                    }
                }
                catch (err) {
                    echo "Caught: ${err}"
                }

                if(params.GERRIT_REFSPEC != '') {
                    env.GERRIT_MSG = "Build Successful ${BUILD_URL}: SUCCESS"
                    sendMessageToGerrit(params.GERRIT_REFSPEC, env.GERRIT_MSG)
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
