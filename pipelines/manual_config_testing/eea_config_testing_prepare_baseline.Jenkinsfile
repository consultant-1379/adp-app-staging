@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.CiDashboard
import com.ericsson.eea4.ci.CommonUtils
import com.ericsson.eea4.ci.ClusterLockUtils
import groovy.transform.Field
import com.ericsson.eea4.ci.Artifactory

@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def dashboard = new CiDashboard(this)
@Field def gitmeta = new GitScm(this, 'EEA/project-meta-baseline')
@Field def cmutils = new CommonUtils(this)
@Field def clusterLockUtils =  new ClusterLockUtils(this)

pipeline {
    agent {
        node {
            label 'productci'
        }
    }
    options {
        ansiColor('xterm')
        skipDefaultCheckout()
        buildDiscarder(logRotator(daysToKeepStr: "7", artifactDaysToKeepStr: "7"))
    }
    parameters {
        string(name: 'CHART_NAME', description: 'Chart name e.g.: eric-ms-b', defaultValue: '')
        string(name: 'CHART_REPO', description: 'Chart repo e.g.: https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm', defaultValue: '')
        string(name: 'CHART_VERSION', description: 'Chart version e.g.: 1.0.0-1', defaultValue: '')
        string(name: 'GERRIT_REFSPEC',  description: 'cnint Gerrit Refspec of the integration chart git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'META_GERRIT_REFSPEC', description: 'Gerrit Refspec of the Meta chart git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'SPINNAKER_TRIGGER_URL', description: 'Spinnaker pipeline triggering url', defaultValue: '')
        string(name: 'SPINNAKER_ID', description: "The spinnaker execution's id", defaultValue: '')
        string(name: 'PIPELINE_NAME', description: "The spinnaker pipeline name", defaultValue: 'eea-application-staging')
        booleanParam(name: 'SKIP_TESTING', description: "Ability to skip testing stage for certain commit", defaultValue: false)
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

        stage('Gerrit message') {
            when {
              expression { env.GERRIT_REFSPEC }
            }
            steps {
                script {
                    env.GERRIT_MSG = "Build Started ${BUILD_URL}"
                    sendMessageToGerrit(env.GERRIT_REFSPEC, env.GERRIT_MSG)
                    env.GERRIT_COMMIT_ID = gitcnint.getCommitIdFromRefspec(env.GERRIT_REFSPEC)
                    echo "env.GERRIT_COMMIT_ID=${env.GERRIT_COMMIT_ID}"
                }
            }
        }

        stage('Set build description') {
            steps {
                script {
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

        stage('Wait for baseline-publish resource is free') {
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

        stage('Rebase') {
            when {
                expression { env.GERRIT_REFSPEC }
            }
            steps {
                sh "technicals/shellscripts/gerrit_rebase.sh --refspec ${env.GERRIT_REFSPEC}"
            }
        }

        stage('Rebase Meta') {
            when {
                expression { env.META_GERRIT_REFSPEC }
            }
            steps {
                sh "technicals/shellscripts/gerrit_rebase.sh --refspec ${env.META_GERRIT_REFSPEC}"
            }
        }

        stage('Set LATEST_GERRIT_REFSPEC') {
            when {
                expression { env.GERRIT_REFSPEC }
            }
            steps {
                script {
                    env.GERRIT_CHANGE_NUMBER = gitcnint.getCommitIdFromRefspec(env.GERRIT_REFSPEC)
                    echo "env.GERRIT_CHANGE_NUMBER=${env.GERRIT_CHANGE_NUMBER}"

                    env.LATEST_GERRIT_REFSPEC = gitcnint.getCommitRefSpec(env.GERRIT_CHANGE_NUMBER)
                    echo "env.LATEST_GERRIT_REFSPEC=${env.LATEST_GERRIT_REFSPEC}"

                    if (env.LATEST_GERRIT_REFSPEC != params.GERRIT_REFSPEC) {
                        echo "There is newer patchset then ${params.GERRIT_REFSPEC}, using this: ${env.LATEST_GERRIT_REFSPEC}"
                        // override with the latest refspec
                        env.GERRIT_REFSPEC = env.LATEST_GERRIT_REFSPEC
                        // TODO: EEAEPP-79292
                        // check if a newer patchset was uploaded by a non technical user (ECEAGIT)
                        // if a non technical user creates a new patchset, prepare should FAIL, because the newer patset must have CR*1 again
                    }
                }
            }
        }

        stage('Set LATEST_META_GERRIT_REFSPEC') {
            when {
                expression { env.META_GERRIT_REFSPEC }
            }
            steps {
                script {
                    env.META_GERRIT_CHANGE_NUMBER = gitmeta.getCommitIdFromRefspec(env.META_GERRIT_REFSPEC)
                    echo "env.META_GERRIT_CHANGE_NUMBER=${env.META_GERRIT_CHANGE_NUMBER}"

                    env.LATEST_META_GERRIT_REFSPEC = gitcnint.getCommitRefSpec(env.META_GERRIT_CHANGE_NUMBER)
                    echo "env.LATEST_META_GERRIT_REFSPEC=${env.LATEST_META_GERRIT_REFSPEC}"

                    if (env.LATEST_META_GERRIT_REFSPEC != params.META_GERRIT_REFSPEC) {
                        echo "There is newer patchset then ${params.META_GERRIT_REFSPEC}, using this: ${env.LATESTMETA__GERRIT_REFSPEC}"
                        // override with the latest refspec
                        env.META_GERRIT_REFSPEC = env.LATEST_META_GERRIT_REFSPEC
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
                    gitcnint.checkout(env.MAIN_BRANCH, 'cnint')
                }
            }
        }

        stage('Fetch And Cherry Pick changes') {
            when {
                expression { env.GERRIT_REFSPEC }
            }
            steps {
                dir('cnint') {
                    script {
                        gitcnint.fetchAndCherryPick('EEA/cnint', "${env.GERRIT_REFSPEC}")
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

        stage('Prepare Helm Chart') {
            when {
                expression { env.GERRIT_REFSPEC }
            }
            steps {
                dir('cnint') {
                    // Generate integration helm chart
                    withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                    string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                    string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                    usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                        sh 'bob/bob prepare'
                    }
                }
            }
        }

        stage('Checkout project-meta-baseline master') {
            steps {
                script {
                    gitmeta.checkout(env.MAIN_BRANCH, 'project-meta-baseline')
                }
            }
        }

        stage('Fetch And Cherry Pick project-meta-baseline changes') {
            when {
                expression { env.META_GERRIT_REFSPEC }
            }
            steps {
                dir('project-meta-baseline') {
                    script {
                        gitmeta.fetchAndCherryPick('EEA/project-meta-baseline', "${env.META_GERRIT_REFSPEC}")
                    }
                }
            }
        }

        stage('Prepare meta') {
            when {
                expression { env.META_GERRIT_REFSPEC }
            }
            steps {
                dir('project-meta-baseline') {
                    checkoutGitSubmodules()
                }
            }
        }

        stage('Clean meta') {
            when {
                expression { env.META_GERRIT_REFSPEC }
            }
            steps {
                dir('project-meta-baseline') {
                    sh './bob/bob clean'
                }
            }
        }

        stage('Prepare Meta Helm Chart') {
            when {
                expression { env.META_GERRIT_REFSPEC }
            }
            steps {
                dir('project-meta-baseline') {
                    withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                    string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                    string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                    usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                        withEnv(["GERRIT_REFSPEC=${env.META_GERRIT_REFSPEC}"]) {
                            sh 'bob/bob prepare-meta'
                        }
                    }
                }
            }
        }

        stage('Extract data from charts') {
            steps {
                script {
                    if ( !params.GERRIT_REFSPEC ) {
                        env.INT_CHART_PATH = "cnint/eric-eea-int-helm-chart"
                        env.INT_CHART_VERSION = cmutils.getChartVersion("${env.INT_CHART_PATH}", "Chart.yaml")
                        sh "echo 'INT_CHART_VERSION=${env.INT_CHART_VERSION}' >> cnint/artifact.properties"
                    }
                    if ( params.META_GERRIT_REFSPEC ) {
                        env.META_CHART_PATH = "project-meta-baseline/.bob/eric-eea-ci-meta-helm-chart_tmp/eric-eea-ci-meta-helm-chart"
                        readProperties(file: 'project-meta-baseline/artifact.properties').each {key, value -> env[key+'_META'] = value }
                        sh "echo 'INT_CHART_NAME_META=${env.INT_CHART_NAME_META}' >> cnint/artifact.properties"
                        sh "echo 'INT_CHART_REPO_META=${env.INT_CHART_REPO_META}' >> cnint/artifact.properties"
                        sh "echo 'INT_CHART_VERSION_META=${env.INT_CHART_VERSION_META}' >> cnint/artifact.properties"
                    } else {
                        env.META_CHART_PATH = "project-meta-baseline/eric-eea-ci-meta-helm-chart"
                        env.INT_CHART_VERSION_META = cmutils.getChartVersion("${env.META_CHART_PATH}", "Chart.yaml")
                        sh "echo 'INT_CHART_VERSION_META=${env.INT_CHART_VERSION_META}' >> cnint/artifact.properties"
                    }
                    env.DATASET_NAME = cmutils.getDatasetVersion("${env.META_CHART_PATH}", "values.yaml")
                    sh "echo 'DATASET_NAME=${env.DATASET_NAME}' >> cnint/artifact.properties"
                    env.REPLAY_SPEED = cmutils.getDatasetReplaySpeed("${env.META_CHART_PATH}", "values.yaml")
                    sh "echo 'REPLAY_SPEED=${env.REPLAY_SPEED}' >> cnint/artifact.properties"
                    env.UTF_CHART_NAME = cmutils.extractSubChartData("eric-eea-utf-application", "name", "${env.META_CHART_PATH}", "Chart.yaml")
                    sh "echo 'UTF_CHART_NAME=${env.UTF_CHART_NAME}' >> cnint/artifact.properties"
                    env.UTF_CHART_REPO = cmutils.extractSubChartData("eric-eea-utf-application", "repository", "${env.META_CHART_PATH}", "Chart.yaml")
                    sh "echo 'UTF_CHART_REPO=${env.UTF_CHART_REPO}' >> cnint/artifact.properties"
                    env.UTF_CHART_VERSION = cmutils.extractSubChartData("eric-eea-utf-application", "version", "${env.META_CHART_PATH}", "Chart.yaml")
                    sh "echo 'UTF_CHART_VERSION=${env.UTF_CHART_VERSION}' >> cnint/artifact.properties"
                }
            }
        }

        stage("Run dimtool") {
            steps {
                dir('cnint') {
                    script {
                        if (env.GERRIT_REFSPEC) {
                            env.INT_HELM_CHART_ARCHIVE_NAME = sh (script: ''' find .bob/ -type f -name "eric-eea-int-helm-chart*.tgz" -exec basename \\{} .tgz \\;''', returnStdout: true).trim()
                            echo "INT_HELM_CHART_ARCHIVE_NAME=${INT_HELM_CHART_ARCHIVE_NAME}"
                            env.INT_CHART_NAME = sh (script: ''' echo "${INT_HELM_CHART_ARCHIVE_NAME}" | awk \'match($0,/^([a-z]+(-[a-z]+)+)/){print substr($0,RSTART,RLENGTH)}\' |uniq ''', returnStdout: true).trim()
                            env.INT_CHART_VERSION = sh (script: '''echo "${INT_HELM_CHART_ARCHIVE_NAME}" | awk \'match($0,/([0-9]+\\.){1,}[0-9]+-[0-9]+-[0-9a-z]+/){print substr($0,RSTART,RLENGTH)}\' ''', returnStdout: true).trim()
                            env.INT_CHART_REPO = "https://arm.seli.gic.ericsson.se/artifactory/proj-eea-ci-internal-helm/"
                        } else {
                            def data = readYaml file: 'eric-eea-int-helm-chart/Chart.yaml'
                            env.INT_CHART_NAME = data.name
                            env.INT_CHART_REPO = "https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/"
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
                                stringParam(name: 'GERRIT_REFSPEC', value: env.GERRIT_REFSPEC)
                        ], wait: true
                        def dimToolGeneratorJobResult = dimensioning_output_generator_job.getResult()
                        if (dimToolGeneratorJobResult != 'SUCCESS') {
                            error("Build of ${DIMENSIONING_OUTPUT_GENERATOR_JOB_NAME} job failed with result: ${dimToolGeneratorJobResult}")
                        }

                        copyArtifacts filter: '*.log, dimToolOutput.properties', fingerprintArtifacts: true, projectName: "dimensioning-tool-output-generator", selector: specific("${dimensioning_output_generator_job.number}")
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
                                archiveArtifacts artifacts: "${env.DIMTOOL_VALUES_PATH}" , allowEmptyArchive: true

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
    }
    post {
        always {
            script {
                if (!params.DRY_RUN) {
                    dir('cnint') {
                        if (['eea-manual-config-testing'].contains(params.PIPELINE_NAME)) {
                            dashboard.initAppDashboardExecution()
                        }
                        sh "echo 'SKIP_TESTING=${env.SKIP_TESTING}' >> artifact.properties"
                        archiveArtifacts artifacts: "artifact.properties", allowEmptyArchive: true
                    }
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
        success {
            script {
                if (env.GERRIT_REFSPEC) {
                    env.GERRIT_MSG = "Build Successful ${BUILD_URL}: SUCCESS"
                    sendMessageToGerrit(env.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }
        cleanup {
            cleanWs()
        }
    }
}
