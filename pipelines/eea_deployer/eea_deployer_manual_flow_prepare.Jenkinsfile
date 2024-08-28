@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.ClusterLockUtils
import groovy.transform.Field
import com.ericsson.eea4.ci.CommonUtils
import com.ericsson.eea4.ci.Artifactory

@Field def gitdeployer = new GitScm(this, 'EEA/deployer')
@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def clusterLockUtils =  new ClusterLockUtils(this)
@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def gitmeta = new GitScm(this, 'EEA/project-meta-baseline')
@Field def cmutils = new CommonUtils(this)
@Field def arm = new Artifactory(this, "https://arm.seli.gic.ericsson.se/", "API_TOKEN_EEA")

pipeline {
    agent {
        node {
            label 'productci'
        }
    }
    options {
        ansiColor('xterm')
        skipDefaultCheckout()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(daysToKeepStr: '7', artifactDaysToKeepStr: '3'))
    }
    parameters {
        string(name: 'CHART_NAME', description: 'Chart name e.g.: eric-ms-b', defaultValue: '')
        string(name: 'CHART_REPO', description: 'Chart repo e.g.: https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm', defaultValue: '')
        string(name: 'CHART_VERSION', description: 'Chart version e.g.: 0.1.0-0', defaultValue: '')
        string(name: 'GERRIT_REFSPEC',  description: 'Gerrit Refspec of the deployer git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'SPINNAKER_TRIGGER_URL', description: 'Spinnaker pipeline triggering url', defaultValue: '')
        string(name: 'SPINNAKER_ID', description: "The spinnaker execution's id", defaultValue: '')
        string(name: 'SKIP_TESTING', description: "Ability to skip testing stage for certain commit", defaultValue: 'false')
    }

    environment {
        CSAR_NAME="csar-package"
        CSAR_REPO='https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-generic-local/'
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
                    } else {
                        def link = '<a href="' + env.BUILD_NUMBER + '/console">' + params.CHART_NAME + ':' + params.CHART_VERSION + '</a>'
                        currentBuild.description += link
                    }
                    if (params.SPINNAKER_ID) {
                        currentBuild.description += '<br>Spinnaker URL: <a href="https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/details/' + params.SPINNAKER_ID + '">' + params.SPINNAKER_ID + '</a>'
                    }
                }
            }
        }

        stage('Wait for deployer-publish resource is free') {
            steps {
                script {
                    while ( clusterLockUtils.getResourceLabelStatus("deployer-publish") != "FREE" ) {
                        sleep(time: 5, unit: 'MINUTES' )
                    }
                }
            }
        }

        stage('Checkout - scripts') {
            steps {
                script {
                    gitadp.checkout(env.MAIN_BRANCH, 'adp-app-staging')
                }
            }
        }

        stage('Rebase') {
            when {
                expression { env.GERRIT_REFSPEC }
            }
            steps {
                sh "adp-app-staging/technicals/shellscripts/gerrit_rebase.sh --refspec ${env.GERRIT_REFSPEC}"
            }
        }

        stage('Set LATEST_GERRIT_REFSPEC') {
            when {
                expression { env.GERRIT_REFSPEC }
            }
            steps {
                script {
                    env.GERRIT_CHANGE_NUMBER = gitdeployer.getCommitIdFromRefspec(env.GERRIT_REFSPEC)
                    echo "env.GERRIT_CHANGE_NUMBER=${env.GERRIT_CHANGE_NUMBER}"

                    env.LATEST_GERRIT_REFSPEC = gitdeployer.getCommitRefSpec(env.GERRIT_CHANGE_NUMBER)
                    echo "env.LATEST_GERRIT_REFSPEC=${env.LATEST_GERRIT_REFSPEC}"

                    if (env.LATEST_GERRIT_REFSPEC != params.GERRIT_REFSPEC) {
                        echo "There is newer patchset then ${params.GERRIT_REFSPEC}, using this: ${env.LATEST_GERRIT_REFSPEC}"
                        currentBuild.description += "<br>using newer patchset LATEST_GERRIT_REFSPEC: ${env.LATEST_GERRIT_REFSPEC}"
                        // override with the latest refspec
                        env.GERRIT_REFSPEC = env.LATEST_GERRIT_REFSPEC
                        // TODO: EEAEPP-79292
                        // check if a newer patchset was uploaded by a non technical user (ECEAGIT)
                        // if a non technical user creates a new patchset, prepare should FAIL, because the newer patset must have CR*1 again
                    }
                }
            }
        }

        stage('Checkout master') {
            steps {
                script {
                    gitdeployer.checkout(env.MAIN_BRANCH, "deployer")
                }
            }
        }

        stage('Fetch And Cherry Pick changes') {
            when {
                expression { env.GERRIT_REFSPEC }
            }
            steps{
                dir('deployer') {
                    script{
                        gitdeployer.fetchAndCherryPick("EEA/deployer", "${env.GERRIT_REFSPEC}")
                    }
                }
            }
        }

        stage('Prepare') {
            steps {
                dir('deployer') {
                    checkoutGitSubmodules()
                }
            }
        }

        stage('Clean') {
            steps {
                dir('deployer') {
                    sh 'bob/bob -r bob-rulesets/ruleset2.0.yaml clean'
                }
            }
        }

        stage('Prepare Helm Chart') {
            steps {
                dir ('deployer') {
                    withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                    string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                    string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                    usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                        sh 'bob/bob -r bob-rulesets/ruleset2.0.yaml prepare'
                        script {
                            try {
                                readProperties(file: 'artifact.properties').each {key, value -> env['PREPARED_' + key] = value }
                                currentBuild.description += '<br>Prepared chart: <a href="' + "${PREPARED_INT_CHART_REPO}${PREPARED_INT_CHART_NAME}/${PREPARED_INT_CHART_NAME}-${PREPARED_INT_CHART_VERSION}.tgz\"> ${PREPARED_INT_CHART_NAME}-${PREPARED_INT_CHART_VERSION}.tgz</a>"
                            } catch (err) {
                                echo "Caught an error ${err} during the prepapred package addig to currentBuild.description"
                            }
                        }
                    }
                }
            }
        }

        stage('Check which files changed to skip testing'){
            when {
                expression { !env.SKIP_TESTING.toBoolean() }
            }
            steps {
                dir('deployer') {
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

        stage('Checkout cnint master') {
            steps {
                script {
                    gitcnint.checkout(env.MAIN_BRANCH, 'cnint')
                    dir('cnint') {
                      checkoutGitSubmodules()
                    }
                }
            }
        }

        stage('Download eric-eea-int-helm-chart') {
            steps {
                script {
                    dir('cnint') {
                        if ( params.CHART_VERSION ) {
                            if (params.CHART_VERSION == 'latest') {
                                def data = readYaml file: 'eric-eea-int-helm-chart/Chart.yaml'
                                env.CHART_NAME = data.name
                                env.CHART_REPO = "https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/"
                                env.INT_CHART_VERSION_PRODUCT = data.version
                                withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                                                 usernamePassword(credentialsId: 'ECEAART_SEROGIC_API_KEY', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
                                                 usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
                                                 string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                                 string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                ]) {
                                    // Download and extract the Integration helm chart
                                    sh './bob/bob -r ruleset2.0.yaml k8s-test-without-post-install:download-extract-chart'
                                }
                            }
                        } else {
                            downloadCsarPackage()
                            sh 'unzip -l $CSAR_NAME-$CSAR_VERSION.csar > csar-package.content.txt '
                            sh """
                                eric_eea_int_helm_chart_file_with_path=\$(cat csar-package.content.txt | grep 'eric-eea-int-helm-chart' | awk -F' ' '{print \$4}')
                                unzip -j \$CSAR_NAME-\$CSAR_VERSION.csar \$eric_eea_int_helm_chart_file_with_path -d .bob/
                                mkdir -p .bob/eric-eea-int-helm-chart_tmp/
                                eric_eea_int_helm_chart_file=\$(basename "\${eric_eea_int_helm_chart_file_with_path}")
                                tar xzf .bob/\$eric_eea_int_helm_chart_file -C .bob/eric-eea-int-helm-chart_tmp/
                            """
                        }
                    }
                }
            }
        }

        stage('Checkout meta master') {
            steps {
                dir('cnint') {
                    script {
                        gitmeta.checkout(env.MAIN_BRANCH, 'project-meta-baseline')
                    }
                }
            }
        }

        stage('Get dataset-version from meta baseline') {
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
                        env.INT_HELM_CHART_ARCHIVE_NAME = sh (script: ''' find . -name "eric-eea-int-helm-chart*.tgz" -exec basename \\{} .tgz \\; ''', returnStdout: true).trim()
                        echo "INT_HELM_CHART_ARCHIVE_NAME=${INT_HELM_CHART_ARCHIVE_NAME}"
                        env.INT_CHART_NAME = sh (script: ''' echo "${INT_HELM_CHART_ARCHIVE_NAME}" | awk \'match($0,/^([a-z]+(-[a-z]+)+)/){print substr($0,RSTART,RLENGTH)}\' ''', returnStdout: true).trim()
                        env.INT_CHART_VERSION = sh (script: '''echo "${INT_HELM_CHART_ARCHIVE_NAME}" | awk \'match($0,/([0-9]+\\.){1,}[0-9]+-[0-9]+-[0-9a-z]+/){print substr($0,RSTART,RLENGTH)}\' ''', returnStdout: true).trim()

                        if ( params.CHART_VERSION ) {
                            env.INT_CHART_REPO = env.CHART_REPO
                        } else {
                            env.INT_CHART_REPO = env.PREPARED_INT_CHART_REPO
                        }

                        echo "INT_CHART_NAME=${INT_CHART_NAME}"
                        echo "INT_CHART_REPO=${INT_CHART_REPO}"
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
                                booleanParam(name: 'DIMTOOL_VALIDATE_OUTPUT', value: true)
                        ], wait: true
                        def dimToolGeneratorJobResult = dimensioning_output_generator_job.getResult()
                        if (dimToolGeneratorJobResult != 'SUCCESS') {
                            error("Build of ${DIMENSIONING_OUTPUT_GENERATOR_JOB_NAME} job failed with result: ${dimToolGeneratorJobResult}")
                        }

                        copyArtifacts filter: '*.log, dimToolOutput.properties', fingerprintArtifacts: true, projectName: "dimensioning-tool-output-generator", selector: specific("${dimensioning_output_generator_job.number}")
                        readProperties(file: 'dimToolOutput.properties').each {key, value -> env[key] = value }

                        sh "echo 'DIMTOOL_OUTPUT_REPO_URL=${DIMTOOL_OUTPUT_REPO_URL}' >> ${WORKSPACE}/deployer/artifact.properties"
                        sh "echo 'DIMTOOL_OUTPUT_REPO=${DIMTOOL_OUTPUT_REPO}' >> ${WORKSPACE}/deployer/artifact.properties"
                        sh "echo 'DIMTOOL_OUTPUT_NAME=${DIMTOOL_OUTPUT_NAME}' >> ${WORKSPACE}/deployer/artifact.properties"

                        archiveArtifacts artifacts: "*.log, dimToolOutput.properties", allowEmptyArchive: true
                    }
                }
            }
        }

    }
    post {
        always {
            script {
                if (!params.DRY_RUN) {
                    dir ('deployer') {
                        sh "echo 'SKIP_TESTING=${env.SKIP_TESTING}' >> artifact.properties"
                        sh "echo 'META_BASELINE_CHART_VERSION=${env.META_BASELINE_CHART_VERSION}' >> artifact.properties"
                        archiveArtifacts artifacts: "artifact.properties", allowEmptyArchive: true
                    }
                }
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

void getLatestCsarVersion() {
    arm.setUrl('https://arm.seli.gic.ericsson.se/', "$API_TOKEN_EEA")
    Map args = [
        "repo": "proj-eea-drop-generic-local",
        "type": "file",
        "name": "*.csar",
        "sort_desc": ["created"],
        "limit": 1
    ]
    env.CSAR_VERSION = ""
    def jsonText = arm.searchArtifact(args)
    if (!jsonText) {
        error("Failed to get jsonText")
    }
    def jsonObj = readJSON text: jsonText
    if (!jsonObj) {
        error("Failed to get jsonObj")
    }
    jsonObj.results.eachWithIndex { artifact, idx ->
        env.CSAR_VERSION = arm.getServiceVersion("${artifact.name}")
    }
    if (!env.CSAR_VERSION) {
        error("Failed to determine latest CSAR_VERSION in ARM")
    }
    echo("Latest CSAR_VERSION: ${env.CSAR_VERSION}")
    currentBuild.description += "<br>CSAR_VERSION: ${env.CSAR_VERSION}"
}

void downloadCsarPackage() {
    withCredentials([string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
        script {
            try {
                getLatestCsarVersion()
                sh 'curl -H "X-JFrog-Art-Api: $API_TOKEN_EEA" $CSAR_REPO/$CSAR_NAME-$CSAR_VERSION.csar --fail -o $CSAR_NAME-$CSAR_VERSION.csar'
            }
            catch (err) {
                echo "Caught: ${err}"
                error "CSAR DOWNLOAD FAILED"
            }
        }
    }
}
