@Library('ci_shared_library_eea4') _


import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.CiDashboard
import com.ericsson.eea4.ci.CommonUtils
import com.ericsson.eea4.ci.ClusterLockUtils
import groovy.transform.Field
import com.ericsson.eea4.ci.Artifactory

@Field def git = new GitScm(this, 'EEA/cnint')
@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitmeta = new GitScm(this, 'EEA/project-meta-baseline')
@Field def dashboard = new CiDashboard(this)
@Field def cmutils = new CommonUtils(this)
@Field def clusterLockUtils =  new ClusterLockUtils(this)

pipeline {
    agent {
        node {
            label 'productci'
        }
    }
    options {
        skipDefaultCheckout()
        buildDiscarder(logRotator(daysToKeepStr: '7', artifactDaysToKeepStr: "7"))
    }
    parameters {
        string(name: 'CHART_NAME', description: 'Chart name e.g.: eric-ms-b', defaultValue: '')
        string(name: 'CHART_REPO', description: 'Chart repo e.g.: https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm', defaultValue: '')
        string(name: 'CHART_VERSION', description: 'Chart version e.g.: 1.0.0-1', defaultValue: '')
        string(name: 'GERRIT_REFSPEC',  description: 'Gerrit Refspec of the cnint git repo, e.g.: refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'SPINNAKER_ID', description: 'Spinnaker pipeline execution id', defaultValue: '')
        string(name: 'PIPELINE_NAME', description: 'Spinnaker pipeline name', defaultValue: '')
        choice(name: 'BUILD_RESULT_WHEN_VERIFY_PRODUCT_CI_CAPACITY_FAILED', choices: ['FAILURE', 'SUCCESS'], description: 'build result when the Verify Product CI capacity failed')
    }
    environment {
        DIMENSIONING_OUTPUT_GENERATOR_JOB_NAME = "dimensioning-tool-output-generator"
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

        stage('Set build description') {
            steps {
                script {
                    currentBuild.description = ''
                    if (env.GERRIT_REFSPEC) {
                        def gerritLink = getGerritLink(env.GERRIT_REFSPEC)
                        currentBuild.description += gerritLink
                    } else {
                        def link = '<a href="' + env.BUILD_NUMBER + '/console">' + params.CHART_NAME + ':' + params.CHART_VERSION + '</a>'
                        currentBuild.description += link
                    }
                    if (params.SPINNAKER_ID) {
                        currentBuild.description += '<br><a href="https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/details/' + params.SPINNAKER_ID + '">Spinnaker URL: ' + params.SPINNAKER_ID + '</a>'
                    }
                }
            }
        }

        stage('Wait for baseline-install resource is free') {
            steps {
                script {
                    while ( clusterLockUtils.getResourceLabelStatus("baseline-publish") != "FREE" ) {
                        sleep(time: 5, unit: 'MINUTES' )
                    }
                }
            }
        }

        stage('Checkout - scripts'){
            steps {
                script {
                    gitadp.sparseCheckout("technicals/")
                }
            }
        }

        stage('Checkout') {
            steps {
                script {
                    git.checkout('master', 'cnint')
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

        stage('Prepare Helm Chart') {
            steps {
                dir('cnint') {
                    // Generate integration helm chart
                    withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                        usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                        usernamePassword(credentialsId: 'ECEAART_SEROGIC_API_KEY', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
                        string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                        string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                        usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')
                    ]) {
                        sh 'bob/bob prepare'
                    }
                }
            }
        }

        stage('Checkout meta master') {
            steps {
                dir('cnint') {
                    script {
                        gitmeta.checkout('master', 'project-meta-baseline')
                    }
                }
            }
        }

        stage('Get dataset information from meta baseline') {
            steps {
                dir('cnint') {
                    script {
                        env.DATASET_NAME = cmutils.getDatasetVersion("project-meta-baseline/eric-eea-ci-meta-helm-chart","values.yaml")
                        sh "echo 'DATASET_NAME=${env.DATASET_NAME}' >> artifact.properties"
                        env.REPLAY_SPEED = cmutils.getDatasetReplaySpeed("project-meta-baseline/eric-eea-ci-meta-helm-chart","values.yaml")
                        sh "echo 'REPLAY_SPEED=${env.REPLAY_SPEED}' >> artifact.properties"
                        env.META_BASELINE_CHART_VERSION = cmutils.getChartVersion("project-meta-baseline/eric-eea-ci-meta-helm-chart", "Chart.yaml")
                        sh "echo 'META_BASELINE_CHART_VERSION=${env.META_BASELINE_CHART_VERSION}' >> artifact.properties"
                        env.UTF_CHART_NAME = cmutils.extractSubChartData("eric-eea-utf-application", "name", "project-meta-baseline/eric-eea-ci-meta-helm-chart","Chart.yaml")
                        sh "echo 'UTF_CHART_NAME=${env.UTF_CHART_NAME}' >> artifact.properties"
                        env.UTF_CHART_REPO = cmutils.extractSubChartData("eric-eea-utf-application", "repository", "project-meta-baseline/eric-eea-ci-meta-helm-chart","Chart.yaml")
                        sh "echo 'UTF_CHART_REPO=${env.UTF_CHART_REPO}' >> artifact.properties"
                        env.UTF_CHART_VERSION = cmutils.extractSubChartData("eric-eea-utf-application", "version", "project-meta-baseline/eric-eea-ci-meta-helm-chart","Chart.yaml")
                        sh "echo 'UTF_CHART_VERSION=${env.UTF_CHART_VERSION}' >> artifact.properties"
                    }
                }
            }
        }

        stage("Run dimtool") {
            steps {
                dir('cnint') {
                    script {
                        env.INT_HELM_CHART_ARCHIVE_NAME = sh (script: ''' find . -name "*.tgz" -exec basename \\{} .tgz \\; ''', returnStdout: true).trim()
                        echo "INT_HELM_CHART_ARCHIVE_NAME=${INT_HELM_CHART_ARCHIVE_NAME}"
                        env.INT_CHART_NAME = sh (script: ''' echo "${INT_HELM_CHART_ARCHIVE_NAME}" | awk \'match($0,/^([a-z]+(-[a-z]+)+)/){print substr($0,RSTART,RLENGTH)}\' ''', returnStdout: true).trim()
                        env.INT_CHART_VERSION = sh (script: '''echo "${INT_HELM_CHART_ARCHIVE_NAME}" | awk \'match($0,/([0-9]+\\.){1,}[0-9]+-[0-9]+-[0-9a-z]+/){print substr($0,RSTART,RLENGTH)}\' ''', returnStdout: true).trim()
                        env.INT_CHART_REPO = "https://arm.seli.gic.ericsson.se/artifactory/proj-eea-ci-internal-helm/"

                        echo "INT_CHART_NAME=${INT_CHART_NAME}"
                        echo "INT_CHART_REPO=https://arm.seli.gic.ericsson.se/artifactory/proj-eea-ci-internal-helm/"
                        echo "INT_CHART_VERSION=${INT_CHART_VERSION}"

                        def dimensioning_output_generator_job = build job: "${DIMENSIONING_OUTPUT_GENERATOR_JOB_NAME}", parameters: [
                                stringParam(name: 'INT_CHART_NAME', value: env.INT_CHART_NAME),
                                stringParam(name: 'INT_CHART_REPO', value : env.INT_CHART_REPO),
                                stringParam(name: 'INT_CHART_VERSION', value: env.INT_CHART_VERSION),
                                stringParam(name: 'UTF_CHART_NAME', value: env.UTF_CHART_NAME),
                                stringParam(name: 'UTF_CHART_REPO', value: env.UTF_CHART_REPO),
                                stringParam(name: 'UTF_CHART_VERSION', value: env.UTF_CHART_VERSION),
                                stringParam(name: 'DATASET_NAME', value: env.DATASET_NAME),
                                stringParam(name: 'REPLAY_SPEED', value: env.REPLAY_SPEED),
                                stringParam(name: 'GERRIT_REFSPEC', value: env.GERRIT_REFSPEC)
                        ], wait: true
                        def dimToolGeneratorJobResult = dimensioning_output_generator_job.getResult()
                        if (dimToolGeneratorJobResult != 'SUCCESS') {
                            error("Build of ${DIMENSIONING_OUTPUT_GENERATOR_JOB_NAME} job failed with result: ${dimToolGeneratorJobResult}")
                        }

                        copyArtifacts filter: 'dimToolOutput.properties', fingerprintArtifacts: true, projectName: "dimensioning-tool-output-generator", selector: specific("${dimensioning_output_generator_job.number}")
                        readProperties(file: 'dimToolOutput.properties').each {key, value -> env[key] = value }

                        sh "echo 'DIMTOOL_OUTPUT_REPO_URL=${DIMTOOL_OUTPUT_REPO_URL}' >> artifact.properties"
                        sh "echo 'DIMTOOL_OUTPUT_REPO=${DIMTOOL_OUTPUT_REPO}' >> artifact.properties"
                        sh "echo 'DIMTOOL_OUTPUT_NAME=${DIMTOOL_OUTPUT_NAME}' >> artifact.properties"

                        archiveArtifacts artifacts: "*.log, dimToolOutput.properties" , allowEmptyArchive: true
                    }
                }
            }
        }

        stage("Verify Product CI capacity") {
            steps {
                dir('cnint') {
                    script {
                        catchError(buildResult: "${params.BUILD_RESULT_WHEN_VERIFY_PRODUCT_CI_CAPACITY_FAILED}", stageResult: 'FAILURE') {
                            try {
                                copyArtifacts filter: 'product_ci_cluster_infos/Output.html', fingerprintArtifacts: true, projectName: 'EEA4-cluster-info-collector', selector: lastCompleted()
                                withCredentials([usernamePassword(credentialsId: 'arm-seli-eeaprodart-token', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA')]) {
                                    def arm = new Artifactory(this,"${DIMTOOL_OUTPUT_REPO_URL}","${API_TOKEN_EEA}")
                                    arm.setRepo("${DIMTOOL_OUTPUT_REPO}")
                                    arm.downloadArtifact("${DIMTOOL_OUTPUT_NAME}", "${DIMTOOL_OUTPUT_NAME}".split('/')[1])
                                }
                                sh "unzip eea4-dimensioning-tool-output.zip -d eea4-dimensioning-tool-output"
                                env.DIMTOOL_VALUES_PATH = sh( script: '''find  eea4-dimensioning-tool-output -name values.yaml''', returnStdout: true).trim()
                                echo "DIMTOOL_VALUES_PATH=${DIMTOOL_VALUES_PATH}"

                                archiveArtifacts artifacts: "product_ci_cluster_infos/Output.html" , allowEmptyArchive: true
                                archiveArtifacts artifacts: "${DIMTOOL_VALUES_PATH}" , allowEmptyArchive: true

                                sh "python3 ${WORKSPACE}/technicals/pythonscripts/verify_productci_capacity.py -ih product_ci_cluster_infos/Output.html -id '${env.DIMTOOL_VALUES_PATH}' -x cluster_productci_appdashboard"
                            } catch (err) {
                                if (err.toString().contains('10')) {
                                    env.GERRIT_MSG = "Not enough CPU resources in ProductCI cluster pool ${BUILD_URL}: FAILURE"
                                } else if (err.toString().contains('20')) {
                                    env.GERRIT_MSG = "Not enough Memory resources in ProductCI cluster pool ${BUILD_URL}: FAILURE"
                                } else if (err.toString().contains('30')) {
                                    env.GERRIT_MSG = "Not enough CPU and Memory resources in ProductCI cluster pool ${BUILD_URL}: FAILURE"
                                } else {
                                    env.GERRIT_MSG = "Build failed. No problems were identified. If you know why this problem occurred, please add a suitable Cause for it ($BUILD_URL)"
                                }
                                if (env.GERRIT_REFSPEC) {
                                    sendMessageToGerrit(env.GERRIT_REFSPEC, env.GERRIT_MSG)
                                }
                                // Should be enabled later when we are sure dimtool is stable in ProductCI
                                // gitcnint.gerritReview(env.GERRIT_REFSPEC, '--verified -1', 'EEA/cnint')
                                error "Caught: ${err}, details: ${env.GERRIT_MSG}"
                            }
                        }
                    }
                }
            }
        }
        stage('Check product version compatibility') {
            steps{
                dir('cnint/project-meta-baseline'){
                    script{
                        def intChartVersion = sh(script:"""grep "INT_CHART_VERSION=" $WORKSPACE/cnint/artifact.properties |cut -d= -f2""",returnStdout: true ).trim()
                        checkProdVersionCompatibility('proj-eea-drop-generic-local',intChartVersion)
                    }
                }
            }
        }
    }
    post {
        always {
            script {
                if (!params.DRY_RUN) {
                    dir('cnint') {
                        dashboard.initAppDashboardExecution()
                        archiveArtifacts artifacts: "artifact.properties", allowEmptyArchive: true
                    }
                }
            }
        }
        cleanup {
            cleanWs()
        }
    }
}
