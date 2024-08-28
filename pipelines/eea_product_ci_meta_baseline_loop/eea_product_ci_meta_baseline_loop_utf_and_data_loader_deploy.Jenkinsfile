@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.CommonUtils
import groovy.transform.Field

@Field def gitmeta = new GitScm(this, 'EEA/project-meta-baseline')
@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def cmutils = new CommonUtils(this)

pipeline {
    options {
        disableConcurrentBuilds()
        skipDefaultCheckout()
        buildDiscarder(logRotator(daysToKeepStr: '30', artifactNumToKeepStr: '30'))
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
        string(name: 'INT_CHART_NAME', description: 'Chart name e.g.: eric-ms-b', defaultValue: '')
        string(name: 'INT_CHART_REPO', description: 'Chart repo e.g.: https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm', defaultValue: '')
        string(name: 'INT_CHART_VERSION', description: 'Chart version e.g.: 1.0.0-1', defaultValue: '')
        string(name: 'RESOURCE',  description: 'Jenkins resource lock variable', defaultValue: '')
        string(name: 'GERRIT_REFSPEC',  description: 'Gerrit Refspect of the project-meta-baseline git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
    }

    environment {
        META_DEPLOY_TIMEOUT = 15
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

        stage('Checkout meta') {
             when {
                expression { params.GERRIT_REFSPEC == ''}
            }
            steps {
                script {
                    gitmeta.checkout('master', 'project-meta-baseline')
                }
            }
        }
        stage('Checkout meta - refspec') {
            when {
                expression { params.GERRIT_REFSPEC != ''}
            }
            steps {
                script {
                    gitmeta.checkoutRefSpec("${GERRIT_REFSPEC}", "FETCH_HEAD", 'project-meta-baseline')
                }
            }
        }

        stage('Prepare meta') {
            steps {
                dir('project-meta-baseline') {
                    checkoutGitSubmodules()
                }
            }
        }

        stage('Get meta version ') {
            steps {
                script {
                    if (env.INT_CHART_VERSION == ''){
                        dir('project-meta-baseline') {
                                echo "params.INT_CHART_VERSION is not set, so read them from project-meta-baseline master"
                                def data = readYaml file: 'eric-eea-ci-meta-helm-chart/Chart.yaml'
                                env.INT_CHART_VERSION = data.version
                                echo "env.INT_CHART_VERSION: ${env.INT_CHART_VERSION}"
                                def dataValues = readYaml file: 'eric-eea-ci-meta-helm-chart/values.yaml'
                                env.UTF_DATASET_ID = dataValues["dataset-information"]["dataset-version"]
                                env.UTF_REPLAY_SPEED = dataValues["dataset-information"]["replay-speed"]
                                env.UTF_REPLAY_COUNT = dataValues["dataset-information"]["replay-count"]
                                env.RVROBOT_VERSION = ''
                                data.dependencies.each { dependency ->
                                    if (dependency.name == 'eric-eea-robot') {
                                        env.RVROBOT_VERSION = dependency.version
                                    }
                                }
                        }
                    } else if (env.INT_CHART_VERSION != '' ) {
                        withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA')]){

                            sh """mkdir "${INT_CHART_NAME}-${INT_CHART_VERSION}" """

                            cmutils.executeSh ("""
                                    curl -H "X-JFrog-Art-Api: ${env.API_TOKEN_EEA}" -o "${INT_CHART_NAME}-${INT_CHART_VERSION}/${INT_CHART_NAME}-${INT_CHART_VERSION}.tgz" "${INT_CHART_REPO}/${INT_CHART_NAME}/${INT_CHART_NAME}-${INT_CHART_VERSION}.tgz"
                                    tar -C "${INT_CHART_NAME}-${INT_CHART_VERSION}" -xf "${INT_CHART_NAME}-${INT_CHART_VERSION}/${INT_CHART_NAME}-${INT_CHART_VERSION}.tgz"
                                """
                            )

                            def data = readYaml file: "${INT_CHART_NAME}-${INT_CHART_VERSION}/${INT_CHART_NAME}/Chart.yaml"
                            def dataValues = readYaml file: "${INT_CHART_NAME}-${INT_CHART_VERSION}/${INT_CHART_NAME}/values.yaml"
                            env.UTF_DATASET_ID = dataValues["dataset-information"]["dataset-version"]
                            env.UTF_REPLAY_SPEED = dataValues["dataset-information"]["replay-speed"]
                            env.UTF_REPLAY_COUNT = dataValues["dataset-information"]["replay-count"]
                            env.RVROBOT_VERSION = ''
                            data.dependencies.each { dependency ->
                                if (dependency.name == 'eric-eea-robot') {
                                    env.RVROBOT_VERSION = dependency.version
                                }
                            }
                        }
                    }
                    echo "env.UTF_DATASET_ID: ${env.UTF_DATASET_ID}"
                    echo "env.UTF_REPLAY_SPEED: ${env.UTF_REPLAY_SPEED}"
                    echo "env.UTF_REPLAY_COUNT: ${env.UTF_REPLAY_COUNT}"
                    echo "env.RVROBOT_VERSION: ${env.RVROBOT_VERSION}"

                    def variables = "env.META_BASELINE_NAME=\"${INT_CHART_NAME}\"\nenv.META_BASELINE_VERSION=\"${env.INT_CHART_VERSION}\"\nenv.UTF_DATASET_ID=\"${env.UTF_DATASET_ID}\"\nenv.UTF_REPLAY_SPEED=\"${env.UTF_REPLAY_SPEED}\"\nenv.UTF_REPLAY_COUNT=\"${env.UTF_REPLAY_COUNT}\"\nenv.RVROBOT_VERSION=\"${env.RVROBOT_VERSION}\"\n"
                    writeFile(file: 'meta_baseline.groovy', text: variables)
                    archiveArtifacts 'meta_baseline.groovy'
                }
            }
        }

        stage('Utf deploy') {
            stages {
                stage('Set description') {
                    steps {
                        script {
                            currentBuild.description = "${INT_CHART_NAME}-${env.INT_CHART_VERSION}"
                            currentBuild.description += "<br>UTF_DATASET_ID: ${env.UTF_DATASET_ID}"
                            currentBuild.description += "<br>UTF_REPLAY_SPEED: ${env.UTF_REPLAY_SPEED}"
                            currentBuild.description += "<br>UTF_REPLAY_COUNT: ${env.UTF_REPLAY_COUNT}"
                            currentBuild.description += "<br>RVROBOT_VERSION: ${env.RVROBOT_VERSION}"
                            currentBuild.description += "<br>cluster: " + params.RESOURCE
                        }
                    }
                }
                stage('Init meta vars') {
                    steps {
                        dir('project-meta-baseline') {
                            //call ruleset init
                            withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                                usernamePassword(credentialsId: 'ECEAART_SEROGIC_API_KEY', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
                                usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
                                string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                file(credentialsId: params.RESOURCE, variable: 'KUBECONFIG')
                            ]){
                                sh './bob/bob init -r ruleset2.0.yaml'
                            }
                        }
                    }
                }

                stage('Meta-deploy') {
                    steps {
                        timeout(time: "${META_DEPLOY_TIMEOUT}", unit: 'MINUTES') {
                            dir('project-meta-baseline') {
                                catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                                    withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                                        usernamePassword(credentialsId: 'ECEAART_SEROGIC_API_KEY', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
                                        usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
                                        file(credentialsId: params.RESOURCE, variable: 'KUBECONFIG')
                                    ]) {
                                        sh './bob/bob k8s-test-utf'
                                    }
                                }
                            }
                        }
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
