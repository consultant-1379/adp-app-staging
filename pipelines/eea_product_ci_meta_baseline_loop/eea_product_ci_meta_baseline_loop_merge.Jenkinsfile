@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def gitmeta = new GitScm(this, 'EEA/project-meta-baseline')


pipeline {
    options {
        disableConcurrentBuilds()
        skipDefaultCheckout()
        buildDiscarder(logRotator(daysToKeepStr: '14', artifactDaysToKeepStr: '7'))
    }
    agent {
        node {
            label 'productci'
        }
    }
    parameters {
        string(name: 'PRODUCT_VERSION', description: 'The new product version', defaultValue: '')
        string(name: 'CPI_VERSION', description: 'The CPI version built during the application staging', defaultValue: '')
        string(name: 'ROBOT_VERSION', description: 'The new ROBOT version', defaultValue: '')
        string(name: 'UTF_VERSION', description: 'The new UTF version', defaultValue: '')
        string(name: 'SPINNAKER_TRIGGER_URL', description: 'Spinnaker pipeline triggering url', defaultValue: '')
    }
    environment {
        CHART_PATH="${WORKSPACE}/eric-eea-ci-meta-helm-chart/Chart.yaml"
        ROBOT_RULESET_FILENAME="${WORKSPACE}/bob-rulesets/eea-robot.yaml"
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

        stage('Init') {
            steps {
                script {
                    env.GIT_CHANGED_FILES = ""
                    env.GIT_COMMIT_MESSAGE = ""
                }
            }
        }

        stage('Checkout') {
            steps {
                script {
                    gitmeta.checkout('master', '')
                }
           }
        }

        stage('update robot ruleset file') {
            when {
                expression { env.ROBOT_VERSION }
            }
            steps {
                script {
                    sh """
                        sed -i -E "s/eric-eea-robot.[0-9]+\\.[0-9]+\\.[0-9]+[-\\+][0-9]+\$/eric-eea-robot:${env.ROBOT_VERSION}/g" ${env.ROBOT_RULESET_FILENAME}
                    """
                    env.GIT_CHANGED_FILES += " ${env.ROBOT_RULESET_FILENAME}"
                }
            }
        }

        stage('update chart versions') {
            steps {
                script {
                    def data = readYaml file: "${env.CHART_PATH}"
                    def dependencies = data.dependencies
                    data.dependencies.each {dependency ->
                        print dependency.name
                        if (params.PRODUCT_VERSION) {
                            if (dependency.name == 'eric-eea-int-helm-chart') {
                                dependency.version = "${params.PRODUCT_VERSION}"
                            }
                        }
                        if (params.CPI_VERSION) {
                            if (dependency.name == 'eric-eea-documentation-helm-chart-ci') {
                                dependency.version = "${params.CPI_VERSION}"
                            }
                        }
                        if (params.ROBOT_VERSION) {
                            if (dependency.name == 'eric-eea-robot') {
                                dependency.version = "${params.ROBOT_VERSION}"
                                env.GIT_COMMIT_MESSAGE += "Updated eric-eea-robot with ${params.ROBOT_VERSION} "
                            }
                        }
                        if (params.UTF_VERSION) {
                            if (dependency.name == 'eric-eea-utf-application') {
                                dependency.version = "${params.UTF_VERSION}"
                                env.GIT_COMMIT_MESSAGE += "Updated eric-eea-utf-application with ${params.UTF_VERSION} "
                            }
                        }
                    }
                    writeYaml file: "${env.CHART_PATH}", data: data, overwrite: true

                    if (params.PRODUCT_VERSION && params.CPI_VERSION) {
                        env.GIT_COMMIT_MESSAGE += "CPI and product: ${params.CPI_VERSION} ${params.PRODUCT_VERSION} "
                    }

                    if (env.GIT_COMMIT_MESSAGE) {
                        env.GIT_CHANGED_FILES += " ${env.CHART_PATH}"
                    }
                }
            }
        }

        stage('push changes') {
            steps {
                script {
                    gitmeta.createPatchset("${env.GIT_CHANGED_FILES}", "${env.GIT_COMMIT_MESSAGE}", "master", true)

                    echo "env.GIT_COMMIT_MESSAGE: ${env.GIT_COMMIT_MESSAGE}"
                    echo "env.GIT_CHANGED_FILES: ${env.GIT_CHANGED_FILES}"

                    env.GIT_COMMIT_ID = gitmeta.getCommitHashLong()
                    echo "env.GIT_COMMIT_ID: ${env.GIT_COMMIT_ID}"

                    env.GERRIT_REFSPEC = gitmeta.getCommitRefSpec(env.GIT_COMMIT_ID)
                    echo "env.GERRIT_REFSPEC: ${env.GERRIT_REFSPEC}"
                }
            }
        }

        stage('Archive arifact'){
            steps {
                sh '''
                cat > artifact.properties << EOF
GERRIT_REFSPEC=${GERRIT_REFSPEC}
EOF
'''
                archiveArtifacts 'artifact.properties'
            }
        }

        stage('Init job description') {
            when {
                expression { env.GERRIT_REFSPEC }
            }
            steps {
                script {
                    def link = getGerritLink(env.GERRIT_REFSPEC)
                    currentBuild.description = link
                }
            }
        }

        stage('Send message to Gerrit') {
            when {
                expression { env.GERRIT_REFSPEC }
            }
            steps {
                script {
                    env.GERRIT_MSG ="Spinnaker pipeline https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/details/${SPINNAKER_TRIGGER_URL}?stage=0&step=0&details=pipelineConfig"
                    sendMessageToGerrit(env.GERRIT_REFSPEC, env.GERRIT_MSG)
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
