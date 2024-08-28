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

def VALIDATE_WITH_HELM = "HELM_AND_CMA"

@Field def CMA_MODE_IS_HELM = "HELM"
@Field def CMA_MODE_IS_HELM_AND_CMA = "HELM_AND_CMA"

pipeline {
    agent {
        node {
            label 'productci'
        }
    }
    options {
        ansiColor('xterm')
        skipDefaultCheckout()
        buildDiscarder(logRotator(daysToKeepStr: "14", artifactDaysToKeepStr: "7"))
    }
    parameters {
        string(name: 'CHART_NAME', description: 'Chart name e.g.: eric-ms-b', defaultValue: '')
        string(name: 'CHART_REPO', description: 'Chart repo e.g.: https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm', defaultValue: '')
        string(name: 'CHART_VERSION', description: 'Chart version e.g.: 1.0.0-1', defaultValue: '')
        string(name: 'GERRIT_REFSPEC',  description: 'Gerrit Refspec of the cnint git repo, e.g.: refs/changes/87/4641487/1', defaultValue: '')
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

        stage('Checkout master') {
            steps {
                script {
                    gitcnint.checkout(env.MAIN_BRANCH, 'cnint')
                }
            }
        }

        stage('Validate patchset'){
            when {
                expression { env.GERRIT_REFSPEC }
            }
            steps {
                script {
                    env.REFSPEC_TO_VALIDATE = env.GERRIT_REFSPEC
                    def reviewRules = readYaml file: "technicals/cnint_reviewers.yaml"
                    try {
                        env.REFSPEC_TO_VALIDATE = gitadp.checkAndGetCommitLastPatchSetReviewed(env.REFSPEC_TO_VALIDATE,reviewRules)
                    }
                    catch (Exception e) {
                        sendMessageToGerrit(env.GERRIT_REFSPEC, e.message)
                        error("""FAILURE: Validate patchset failed with exception: ${e.class.name},message:  ${e.message}
                        """)
                    }
                    env.GERRIT_REFSPEC = env.REFSPEC_TO_VALIDATE
                }
            }
        }

        stage('Check if chart version is already merged') {
            when {
                expression {env.CHART_NAME && env.CHART_VERSION}
            }
            steps {
                dir('cnint') {
                    script {
                        env.CHART_VERSION_ON_MASTER = cmutils.extractSubChartData("${CHART_NAME}", "version", "eric-eea-int-helm-chart","Chart.yaml")
                        if (env.CHART_VERSION == env.CHART_VERSION_ON_MASTER) {
                            error "Master state of the IHC already contains the same version of the service:\n - CHART_NAME: ${CHART_NAME}\n - CHART_VERSION: ${CHART_VERSION}\n - CHART_REPO: ${CHART_REPO}"
                        }
                    }
                }
            }
        }

        stage('Check helm values changes') {
            when {
                expression {  env.GERRIT_REFSPEC && params.PIPELINE_NAME == 'eea-application-staging' }
            }
            steps {
                dir('cnint') {
                    script  {
                        // validate with helm: if any of the files in values-list.txt, mxe-values-list.txt changed
                        // OR eric-eea-int-helm-chart/values.yaml
                        // OR if custom-cma-disable.yaml changed
                        def customValuesFileList = readFile("values-list.txt").readLines()
                        customValuesFileList.addAll(readFile("mxe-values-list.txt").readLines())
                        customValuesFileList.removeAll { it.startsWith('#') }
                        customValuesFileList.add('eric-eea-int-helm-chart/values.yaml')
                        customValuesFileList.add('disable-cma-values.yaml')
                        customValuesFileList = customValuesFileList.unique()
                        customValuesFileList.each{line ->
                            print line
                        }
                        def changedFiles = getGerritQueryPatchsetChangedFiles(params.GERRIT_REFSPEC)
                        echo "changedFiles: ${changedFiles}"
                        // check if changed files contains any helm custom value file change
                        if (changedFiles.any { customValuesFileList.contains( it ) }) {
                            VALIDATE_WITH_HELM = CMA_MODE_IS_HELM
                            echo "VALIDATE_WITH_HELM: ${VALIDATE_WITH_HELM}"
                        }
                    }
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
            steps {
                dir('cnint') {
                    // Generate integration helm chart
                    withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                    string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                    string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                    usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                        sh 'bob/bob prepare'
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

        stage('Checkout meta master') {
            steps {
                dir('cnint') {
                    script {
                        gitmeta.checkout('master', 'project-meta-baseline')
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

        stage('Run dimtool') {
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

                        copyArtifacts filter: '*.log, dimToolOutput.properties', fingerprintArtifacts: true, projectName: "dimensioning-tool-output-generator", selector: specific("${dimensioning_output_generator_job.number}")
                        readProperties(file: 'dimToolOutput.properties').each {key, value -> env[key] = value }

                        sh "echo 'DIMTOOL_OUTPUT_REPO_URL=${DIMTOOL_OUTPUT_REPO_URL}' >> artifact.properties"
                        sh "echo 'DIMTOOL_OUTPUT_REPO=${DIMTOOL_OUTPUT_REPO}' >> artifact.properties"
                        sh "echo 'DIMTOOL_OUTPUT_NAME=${DIMTOOL_OUTPUT_NAME}' >> artifact.properties"


                        archiveArtifacts artifacts: "*.log, dimToolOutput.properties", allowEmptyArchive: true
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

        stage('Check which files changed to skip testing'){
            when {
                expression { params.SKIP_TESTING == false }
            }
            steps {
                dir('cnint') {
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

        stage('Check chart version') {
            steps {
                dir('cnint') {
                    script {
                        catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                            def props = readProperties file: 'artifact.properties'
                            def newIntChartVersion = props['INT_CHART_VERSION'].split("-h")[0]// the INT_CHART_VERSION has crypted part
                            def oldIntChartVersion = props['INT_CHART_VERSION_STABLE']
                            if (newIntChartVersion == oldIntChartVersion) {
                                echo "Version check failed: INT_CHART_VERSION equals to INT_CHART_VERSION_STABLE"
                                error("Failing the pipeline due to the last ${oldIntChartVersion} and the new int chart version ${newIntChartVersion} stable are same.")
                            } else {
                                echo "Version check passed: INT_CHART_VERSION ${newIntChartVersion} and INT_CHART_VERSION_STABLE ${oldIntChartVersion} are not same"
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
                        if (['eea-application-staging', 'eea-application-staging-non-pra'].contains(params.PIPELINE_NAME)) {
                            dashboard.initAppDashboardExecution()
                        }
                        env.WAIT_FOR_CLUSTER_LOG_COLLECTOR_RESULT = (env.GERRIT_REFSPEC && !env.SKIP_TESTING.toBoolean())
                        sh "echo 'SKIP_TESTING=${env.SKIP_TESTING}' >> artifact.properties"
                        sh "echo 'WAIT_FOR_CLUSTER_LOG_COLLECTOR_RESULT=${env.WAIT_FOR_CLUSTER_LOG_COLLECTOR_RESULT}' >> artifact.properties"
                        sh "echo 'VALIDATE_WITH_HELM=${VALIDATE_WITH_HELM}' >> artifact.properties"
                        if (env.GERRIT_REFSPEC) {
                            sh "echo 'REFSPEC_TO_VALIDATE=${env.REFSPEC_TO_VALIDATE}' >> artifact.properties"
                        }
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
