@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import com.ericsson.eea4.ci.GlobalVars
import com.ericsson.eea4.ci.UtfTrigger2
import com.ericsson.eea4.ci.ClusterLockUtils
import com.ericsson.eea4.ci.ArchiveLogs
import com.ericsson.eea4.ci.ClusterLogUtils
import com.ericsson.eea4.ci.CommonUtils
import com.ericsson.eea4.ci.EEA_Robot

@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def gitmeta = new GitScm(this, 'EEA/project-meta-baseline')
@Field def vars = new GlobalVars()
@Field def utf = new UtfTrigger2(this)
@Field def clusterLogUtilsInstance = new ClusterLogUtils(this)
@Field def cmutils = new CommonUtils(this)

def stageResults = [:]

@Field def CMA_MODE__HELM_VALUES = "true"
@Field def CMA_MODE__HELM_VALUES_AND_CMA_CONF = "false"

@Field def CMA_MODE_IS_HELM = "HELM"
@Field def CMA_MODE_IS_HELM_AND_CMA = "HELM_AND_CMA"

pipeline {
    options {
        buildDiscarder(logRotator(daysToKeepStr: '7', artifactNumToKeepStr: "7"))
    }
    agent {
        node {
            label 'productci'
        }
    }
    parameters {
        string(name: 'CLUSTER', description: 'Cluster to validate - credential ID needed', defaultValue: '')
        string(name: 'CHART_NAME', description: 'Chart name e.g.: eric-ms-b', defaultValue: '')
        string(name: 'CHART_REPO', description: 'Chart repo e.g.: https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm', defaultValue: '')
        string(name: 'CHART_VERSION', description: 'Chart version e.g.: 1.0.0-1', defaultValue: '')
        string(name: 'INT_CHART_NAME', description: 'Chart name e.g.: eric-ms-b', defaultValue: 'eric-eea-int-helm-chart')
        string(name: 'INT_CHART_REPO', description: 'Chart repo e.g.: https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm', defaultValue: 'https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/')
        string(name: 'INT_CHART_VERSION', description: 'Chart version e.g.: 1.0.0-1', defaultValue: 'latest')
        booleanParam(name: 'SKIP_CLEANUP', description: 'skip the cleanup pipeline. Used when SKIP_COLLECT_LOG is false', defaultValue: false)
        string(name: 'AFTER_CLEANUP_DESIRED_CLUSTER_LABEL', description: "The desired new resource label after successful Cluster cleanup run", defaultValue: "${vars.resourceLabelCommon}")
        string(name: 'INT_CHART_NAME_META', description: 'Chart name e.g.: eric-ms-b', defaultValue: 'eric-eea-ci-meta-helm-chart')
        string(name: 'INT_CHART_REPO_META', description: 'Chart repo e.g.: https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/', defaultValue: 'https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/')
        string(name: 'INT_CHART_VERSION_META', description: 'meta-baseline version to install. Format: 1.0.0-1', defaultValue: '')
        choice(name: 'BUILD_RESULT_WHEN_NELS_CHECK_FAILED', choices: ['FAILURE', 'SUCCESS'], description: 'build result when the Check NELS availability failed')
        string(name: 'HELM_AND_CMA_VALIDATION_MODE',
        description: """
        Use HELM values or HELM values and CMA configurations. valid options:
<table>
  <tr>
    <th>Value</th>
    <th ALIGN=left>Comment</th>
  </tr>
  <tr>
    <td>"true" or "HELM"</td>
    <td>use helm values, cma is diabled</td>
  </tr>
  <tr>
    <td>"false" or "HELM_AND_CMA"</td>
    <td>use helm values and load CMA configurations</td>
  </tr>
</table>
            """,
        defaultValue: 'HELM_AND_CMA')
        choice(name: 'BUILD_RESULT_WHEN_CMA_HEALTH_CHECK_FAILED', choices: ['FAILURE','SUCCESS'], description: 'build result when the CMA health check failed')
    }
    environment {
        UTF_INCLUDED_STORIES  =  "**/*.story"
        UTF_PRODUCT_NAMESPACE = "eric-eea-ns"
        UTF_TEMPLATE_SUBTYPE = "TestCaseTemplate"
        UTF_TEMPLATE_TYPE = "testcase-template"
        UTF_TEMPLATE_ID = "testcase"
        UTF_TEMPLATE_NAME = "Testcaseglobaltemplate"
        UTF_TEST_NAME = "DemoUTFTestCase"
        UTF_PRE_ACTIVITIES_TEST_EXECUTION_ID = 1111 + "${env.BUILD_NUMBER}"
        UTF_PRE_ACTIVITIES_TEST_NAME = "UTF Pre-activities"
        UTF_PRE_ACTIVITIES_META_FILTER = "@startRefData or @startData"
        UTF_PRE_ACTIVITIES_TEST_TIMEOUT = 2700
        UTF_PRE_ACTIVITIES_CHECK_TEST_EXECUTION_ID = 1112 + "${env.BUILD_NUMBER}"
        UTF_PRE_ACTIVITIES_CHECK_META_FILTER = "@startDataCheck"
        UTF_PRE_ACTIVITIES_CHECK_TEST_TIMEOUT = 1800
        UTF_PRE_ACTIVITIES_TEST_LOGFILE = "utf_pre_activities_loading.log"
        UTF_POST_ACTIVITIES_TEST_EXECUTION_ID = 9999 + "${env.BUILD_NUMBER}"
        UTF_POST_ACTIVITIES_TEST_NAME = "UTF Post-activities"
        UTF_POST_ACTIVITIES_TEST_LOGFILE = "utf_post_activities_loading.log"
        UTF_POST_ACTIVITIES_META_FILTER = "@stopData"
        UTF_POST_ACTIVITIES_TEST_TIMEOUT = 1800
        SEP_CHART_NAME = "eric-cs-storage-encryption-provider"
        SEP_CHART_REPO = "https://arm.sero.gic.ericsson.se/artifactory/proj-adp-rs-storage-encr-released-helm"
        DIMTOOL_CHART_PATH = ".bob/chart/eric-eea-int-helm-chart"
        DIMENSIONING_OUTPUT_GENERATOR_JOB_NAME = "dimensioning-tool-output-generator"
        RUN_CHECKSPOTFIREPLATFORM_HEALTH_CHECK = "Run CheckSpotfirePlatform health check"
        SPOTFIRE_SERVER = "spotfire"
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

        stage('Cluster param check') {
            when {
                expression { params.CLUSTER == '' }
            }
            steps {
                script {
                    currentBuild.result = 'ABORTED'
                    error("CLUSTER is empty")
                }
            }
        }

        stage('HELM_AND_CMA_VALIDATION_MODE Param check'){
            steps {
                script {
                    if ( params.HELM_AND_CMA_VALIDATION_MODE != CMA_MODE__HELM_VALUES && params.HELM_AND_CMA_VALIDATION_MODE != CMA_MODE__HELM_VALUES_AND_CMA_CONF && params.HELM_AND_CMA_VALIDATION_MODE != CMA_MODE_IS_HELM && params.HELM_AND_CMA_VALIDATION_MODE != CMA_MODE_IS_HELM_AND_CMA ) {

                        error "HELM_AND_CMA_VALIDATION_MODE \"${params.HELM_AND_CMA_VALIDATION_MODE}\" validation error. Valid options:  CMA_MODE__HELM_VALUES:\"${CMA_MODE__HELM_VALUES}\" or \"${CMA_MODE_IS_HELM}\" CMA_MODE__HELM_VALUES_AND_CMA_CONF: \"${CMA_MODE__HELM_VALUES_AND_CMA_CONF}\" or \"${CMA_MODE_IS_HELM_AND_CMA}\""
                    }
                }
            }
        }

        stage('Checkout'){
            steps{
                script {
                    gitcnint.checkout('master', '')
                }
            }
        }

        stage('Init latest version of eric-eea-int-helm-chart') {
            steps {
                script {
                    if (env.INT_CHART_VERSION == 'latest') {
                        def data = readYaml file: 'eric-eea-int-helm-chart/Chart.yaml'
                        env.INT_CHART_VERSION = data.version
                        println(env.INT_CHART_VERSION)
                   }
                }
            }
        }

        stage('Prepare') {
            steps {
                script {
                    checkoutGitSubmodules()
                }
            }
        }
        stage('Checkout adp-app-staging') {
            steps {
                dir('adp-app-staging-full-checkout') {
                    script {
                        gitadp.checkout(env.MAIN_BRANCH,'')
                    }
                }
            }
        }
        stage('Checkout technicals'){
            steps{
                dir('adp-app-staging'){
                    withCredentials([usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GIT_USER', passwordVariable: 'PASSWORD' )]) {
                        script {
                            gitadp.archiveDir('EEA/adp-app-staging', 'HEAD:technicals/')
                            gitadp.archiveDir('EEA/adp-app-staging', 'HEAD:rulesets/')
                        }
                        sh (
                            script: """
                            cp  ${WORKSPACE}/adp-app-staging/pythonscripts/k8s_cleanup.py ${WORKSPACE}/adp-app-staging/
                            """
                        )
                    }
                }
            }
        }

        stage('Init') {
            steps {
                script {
                    // Generate log url link name and log directory names
                    def name = CHART_NAME + ': ' + CHART_VERSION
                    def gerrit_link = null
                    // Setup build info
                    currentBuild.description = name
                    if (gerrit_link != null) {
                        currentBuild.description += '<br>' + gerrit_link
                    }
                }
            }
        }

        stage('Checkout meta') {
            steps {
                script {
                    gitmeta.checkout('master', 'project-meta-baseline')
                    dir('project-meta-baseline') {
                        def data = readYaml file: 'eric-eea-ci-meta-helm-chart/Chart.yaml'
                        env.INT_CHART_NAME_META = data.name
                        env.INT_CHART_REPO_META = 'https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm'
                        env.INT_CHART_VERSION_META = data.version

                        env.CDD_CHART_VERSION_META = cmutils.extractSubChartData("eric-eea-cdd", "version", "${WORKSPACE}/project-meta-baseline/eric-eea-ci-meta-helm-chart","Chart.yaml")
                        checkoutGitSubmodules()
                        echo "env.INT_CHART_NAME_META: ${env.INT_CHART_NAME_META}"
                        echo "env.INT_CHART_REPO_META: ${env.INT_CHART_REPO_META}"
                        echo "env.INT_CHART_VERSION_META: ${env.INT_CHART_VERSION_META}"
                        echo "CDD_CHART_VERSION_META: ${env.CDD_CHART_VERSION_META}"

                        env.DATASET_NAME = cmutils.getDatasetVersion("eric-eea-ci-meta-helm-chart","values.yaml")
                        sh "echo 'DATASET_NAME=${env.DATASET_NAME}' >> $WORKSPACE/artifact.properties"
                        env.REPLAY_SPEED = cmutils.getDatasetReplaySpeed("eric-eea-ci-meta-helm-chart","values.yaml")
                        sh "echo 'REPLAY_SPEED=${env.REPLAY_SPEED}' >> $WORKSPACE/artifact.properties"
                        env.META_BASELINE_CHART_VERSION = cmutils.getChartVersion("eric-eea-ci-meta-helm-chart", "Chart.yaml")
                        sh "echo 'META_BASELINE_CHART_VERSION=${env.META_BASELINE_CHART_VERSION}' >> $WORKSPACE/artifact.properties"
                        env.UTF_CHART_NAME = cmutils.extractSubChartData("eric-eea-utf-application", "name", "eric-eea-ci-meta-helm-chart","Chart.yaml")
                        sh "echo 'UTF_CHART_NAME=${env.UTF_CHART_NAME}' >> $WORKSPACE/artifact.properties"
                        env.UTF_CHART_REPO = cmutils.extractSubChartData("eric-eea-utf-application", "repository", "eric-eea-ci-meta-helm-chart","Chart.yaml")
                        sh "echo 'UTF_CHART_REPO=${env.UTF_CHART_REPO}' >> $WORKSPACE/artifact.properties"
                        env.UTF_CHART_VERSION = cmutils.extractSubChartData("eric-eea-utf-application", "version", "eric-eea-ci-meta-helm-chart","Chart.yaml")
                        sh "echo 'UTF_CHART_VERSION=${env.UTF_CHART_VERSION}' >> $WORKSPACE/artifact.properties"
                    }
                }
            }
        }

        stage('Wait for lock') {
            steps {
                script {
                    sendLockEventToDashboard (transition: "wait-for-lock")
                }
            }
        }

        stage('Resource locking - utf deploy and K8S Install') {
            stages {
                stage('Lock') {
                    options {
                        lock resource: "${params.CLUSTER}", quantity: 1, variable: 'system'
                    }
                    stages {
                        stage('log lock') {
                            steps {
                                echo "Locked cluster: $system"
                                script {
                                    env.lock_start = java.time.LocalDateTime.now()
                                    currentBuild.description += "<br>Locked cluster: $system"
                                    env.LASTLABEL = getLockableResourceLabels(system)
                                    env.START_EPOCH = ((new Date()).getTime()/1000 as double).round()
                                    env.CLUSTER = env.system
                                    sendLockEventToDashboard (transition: "lock", cluster: env.CLUSTER)
                                }
                            }
                        }

                        stage('init vars'){
                            steps {
                                //call ruleset init
                                withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                                        usernamePassword(credentialsId: 'ECEAART_SEROGIC_API_KEY', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
                                        usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
                                        usernamePassword(credentialsId: 'hub-root-user', usernameVariable: 'HUB_ROOT_USER', passwordVariable: 'HUB_ROOT_PASSWD'),
                                        string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                        file(credentialsId: env.system, variable: 'KUBECONFIG')
                                    ]){
                                    sh './bob/bob init'
                                }
                            }
                        }

                        stage('Check if namespace exist') {
                            steps {
                                withCredentials([file(credentialsId: env.system, variable: 'KUBECONFIG')]) {
                                    script {
                                        env.EEA_NS_CHECK_FAILED = checkIfNameSpaceExists()
                                        if ("${env.EEA_NS_CHECK_FAILED}".toBoolean()) {
                                            error "'${STAGE_NAME}' stage FAILED"
                                        }
                                    }
                                }
                            }
                        }

                        stage('Check NELS availability') {
                            steps {
                                catchError(stageResult: 'FAILURE', buildResult: "${params.BUILD_RESULT_WHEN_NELS_CHECK_FAILED}") {
                                    script {
                                        withCredentials([usernamePassword(credentialsId: 'hub-root-user', usernameVariable: 'HUB_ROOT_USER', passwordVariable: 'HUB_ROOT_PASSWD'),
                                                       file(credentialsId: env.system, variable: 'KUBECONFIG')]) {
                                            checkNelsAvailability()
                                        }
                                    }
                                }
                            }
                        }

                          stage('CRD Install') {
                              steps {
                                withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                                        usernamePassword(credentialsId: 'ECEAART_SEROGIC_API_KEY', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
                                        usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
                                        file(credentialsId: env.system, variable: 'KUBECONFIG')
                                    ]){
                                    script {
                                        try {
                                            sh "echo 'CLUSTER='${system} > artifact.properties"
                                            sh './bob/bob k8s-test:download-extract-chart k8s-test:package-helper-chart k8s-test-crd > crd-install.log'
                                        }
                                        catch (err) {
                                            echo "Caught: ${err}"
                                            error "CRD INSTALL FAILED"
                                        } finally {
                                            try {
                                                archiveArtifacts artifacts: 'artifact.properties', allowEmptyArchive: true
                                                archiveArtifacts artifacts: "crd-install.log", allowEmptyArchive: true
                                            } catch (err) {
                                                echo "Caught archiveArtifacts ERROR: ${err}"
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        stage('Set CMA helm values') {
                            steps {
                                script {
                                    echo "HELM_AND_CMA_VALIDATION_MODE mode is: ${params.HELM_AND_CMA_VALIDATION_MODE}"
                                    if (params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE__HELM_VALUES  || params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE_IS_HELM) {
                                        //configurationManagement disabled for all ms
                                        sh "echo 'helm-values/disable-cma-values.yaml' >> values-list.txt"
                                        sh "echo 'helm-values/disable-cma-values.yaml' >> mxe-values-list.txt"
                                        echo "configurationManagement disabled for all ms"
                                    }
                                    else if (params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE__HELM_VALUES_AND_CMA_CONF || params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE_IS_HELM_AND_CMA) {
                                        echo "configurationManagement enabled for all ms"
                                    }
                                }
                            }
                        }

                        stage('Install Spotfire') {
                            parallel {
                                stage('utf and data loader deploy-deploy') {
                                    steps{
                                        script {
                                            def utf_build = build job: "eea-product-ci-meta-baseline-loop-utf-and-data-loader-deploy",parameters: [
                                                booleanParam(name: 'dry_run', value: false),
                                                stringParam(name: 'INT_CHART_NAME', value : "${env.INT_CHART_NAME_META}"),
                                                stringParam(name: 'INT_CHART_REPO', value : "${env.INT_CHART_REPO_META}"),
                                                stringParam(name: 'INT_CHART_VERSION', value: "${env.INT_CHART_VERSION_META}"),
                                                stringParam(name: 'RESOURCE', value : "${env.system}")], wait: true
                                            downloadJenkinsFile("${env.JENKINS_URL}/job/eea-product-ci-meta-baseline-loop-utf-and-data-loader-deploy/${utf_build.number}/artifact/meta_baseline.groovy")
                                            load "${WORKSPACE}/meta_baseline.groovy"
                                        }
                                    }
                                }
                                stage('Execute spotfire deployment') {
                                    steps {
                                        script {
                                            def spotfire_install_job = build job: "spotfire-asset-install-assign-label-wrapper", parameters: [
                                                    booleanParam(name: 'INSTALL_SPOTFIRE_PLATFORM', value: true),
                                                    booleanParam(name: 'DEPLOY_STATIC_CONTENT', value: true),
                                                    stringParam(name: 'CLUSTER_NAME', value : env.CLUSTER)
                                            ], wait: true
                                            def spotfireInstallJobResult = spotfire_install_job.getResult()
                                            downloadJenkinsFile("${env.JENKINS_URL}/job/spotfire-asset-install-assign-label-wrapper/${spotfire_install_job.number}/artifact/artifact.properties", "spotfire_asset_install_assign_label_wrapper_artifact.properties")
                                            readProperties(file: 'spotfire_asset_install_assign_label_wrapper_artifact.properties').each {key, value -> env[key] = value }
                                            if (spotfireInstallJobResult != 'SUCCESS') {
                                                error("Build of spotfire-asset-install job failed with result: ${spotfireInstallJobResult}")
                                            }
                                        }
                                    }
                                }
                                stage('SEP Install') {
                                    steps {
                                    withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                                            usernamePassword(credentialsId: 'ECEAART_SEROGIC_API_KEY', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
                                            usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
                                            string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                            file(credentialsId: env.system, variable: 'KUBECONFIG')
                                        ]){
                                            script {
                                                try {
                                                    env.SEP_CHART_VERSION = sh(
                                                        script: '''cat .bob/chart/eric-eea-int-helm-chart/Chart.yaml | grep -A 2 storage-encryption-provider | grep version | awk -F' ' '{print $2}' | tr -d '\\n'
                                                        ''',
                                                        returnStdout : true)
                                                    sh './bob/bob k8s-test-sep > sep-install.log'
                                                }
                                                catch (err) {
                                                    echo "Caught: ${err}"
                                                    error "SEP INSTALL FAILED"
                                                }
                                                finally {
                                                    try {
                                                        archiveArtifacts artifacts: 'sep-install.log', allowEmptyArchive: true
                                                    } catch (err) {
                                                        echo "Caught archiveArtifacts ERROR: ${err}"
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        stage('Generate and apply dimtool output file') {
                            steps {
                                script {
                                    def dimensioning_output_generator_job = build job: "${DIMENSIONING_OUTPUT_GENERATOR_JOB_NAME}", parameters: [
                                            booleanParam(name: 'DIMTOOL_VALIDATE_OUTPUT', value: true),
                                            stringParam(name: 'INT_CHART_NAME', value: params.INT_CHART_NAME),
                                            stringParam(name: 'INT_CHART_REPO', value : params.INT_CHART_REPO),
                                            stringParam(name: 'INT_CHART_VERSION', value: env.INT_CHART_VERSION),
                                            stringParam(name: 'UTF_CHART_NAME', value: env.UTF_CHART_NAME),
                                            stringParam(name: 'UTF_CHART_REPO', value: env.UTF_CHART_REPO),
                                            stringParam(name: 'UTF_CHART_VERSION', value: env.UTF_CHART_VERSION),
                                            stringParam(name: 'DATASET_NAME', value: env.DATASET_NAME),
                                            stringParam(name: 'REPLAY_SPEED', value: env.REPLAY_SPEED)
                                    ], wait: true
                                    def dimToolGeneratorJobResult = dimensioning_output_generator_job.getResult()
                                    if (dimToolGeneratorJobResult != 'SUCCESS') {
                                        error("Build of ${DIMENSIONING_OUTPUT_GENERATOR_JOB_NAME} job failed with result: ${dimToolGeneratorJobResult}")
                                    }

                                    downloadJenkinsFile("${env.JENKINS_URL}/job/${DIMENSIONING_OUTPUT_GENERATOR_JOB_NAME}/${dimensioning_output_generator_job.number}/artifact/dimToolOutput.properties", "dimToolOutput.properties")
                                    readProperties(file: 'dimToolOutput.properties').each {key, value -> env[key] = value }

                                    echo "DIMTOOL_OUTPUT_REPO_URL=${DIMTOOL_OUTPUT_REPO_URL}"
                                    echo "DIMTOOL_OUTPUT_REPO=${DIMTOOL_OUTPUT_REPO}"
                                    echo "DIMTOOL_OUTPUT_NAME=${DIMTOOL_OUTPUT_NAME}"

                                    cmutils.useValuesFromDimToolOutput("${DIMTOOL_OUTPUT_REPO_URL}", "${DIMTOOL_OUTPUT_REPO}", "${DIMTOOL_OUTPUT_NAME}")
                                }
                            }
                        }

                        stage('K8S Install Test') {
                            steps {
                                script {
                                    Map args = [
                                            "helmTimeout":   "4200",
                                            "clusterName":   "${env.system}",
                                            "pipelineName":  "${env.JOB_NAME}",
                                            "bobRulesList":  ["./bob/bob -r ruleset2.0.yaml init-mxe", "./bob/bob -r ruleset2.0.yaml init-eric-eea-analysis-system-overview-install", "./bob/bob -r ruleset2.0.yaml verify-values-files > k8s-test-verify-values.log", "./bob/bob -r ruleset2.0.yaml k8s-test-splitted-values > k8s-test.log"]
                                    ]
                                    cmutils.k8sInstallTest(args)
                                }
                            }
                            post {
                                failure {
                                    script {
                                        clusterLogUtilsInstance.getResourceCapacity(env.CLUSTER)
                                    }
                                }
                                always {
                                    script {
                                        cmutils.archiveFilesFromLog("k8s-test.log", "--helm_value_file=(\\S+)[\\]\\s]", "install-configvalues.tar.gz")
                                    }
                                    archiveArtifacts artifacts: "install-configvalues.tar.gz", allowEmptyArchive: true
                                }
                            }
                        }

                        stage('Link Spotfire platform to EEA') {
                            steps {
                                script {
                                    def spotfire_install_job = build job: "spotfire-asset-install-assign-label-wrapper", parameters: [
                                            booleanParam(name: 'SETUP_TLS_AND_SSO', value: true),
                                            booleanParam(name: 'ENABLE_CAPACITY_REPORTER', value: true),
                                            stringParam(name: 'CLUSTER_NAME', value : env.CLUSTER),
                                            stringParam(name: 'PREVIOUS_JOB_BUILD_ID', value: env.SPOTFIRE_ASSET_INSTALL_NEW_BUILD_NUMBER)
                                    ], wait: true
                                    def spotfireInstallJobResult = spotfire_install_job.getResult()
                                    if (spotfireInstallJobResult != 'SUCCESS') {
                                        error("Build of spotfire-asset-install job failed with result: ${spotfireInstallJobResult}")
                                    }
                                }
                            }
                        }

                        stage('Run CheckSpotfirePlatform health check') { // RUN_CHECKSPOTFIREPLATFORM_HEALTH_CHECK
                            steps {
                                script {
                                    clusterLogUtilsInstance.runHealthCheck("${vars.waitForPodsAfterInstall}", "${STAGE_NAME}", clusterCredentialID=env.CLUSTER, eeaHealthcheckCheckClasses='CheckSpotfirePlatform',  k8s_namespace='spotfire-platform')
                                }
                            }
                        }

                        stage('Create stream-aggregator configmap') {
                            steps {
                                script {
                                    cmutils.createAggregatorConfigmapFromDimtoolOutput()
                                }
                            }
                        }
                        stage('Run health check after install') {
                            steps {
                                script {
                                    clusterLogUtilsInstance.runHealthCheck("${vars.waitForPodsAfterInstall}", "${STAGE_NAME}")
                                }
                            }
                            post {
                                always {
                                    script {
                                        archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                                    }
                                }
                            }
                        }

                        stage('Load config json to CM-Analytics') {
                            when {
                                expression { params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE__HELM_VALUES_AND_CMA_CONF || params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE_IS_HELM_AND_CMA}
                            }
                            steps {
                                script {
                                    withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                                        usernamePassword(credentialsId: 'ECEAART_SEROGIC_API_KEY', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
                                        file(credentialsId: env.system, variable: 'KUBECONFIG')
                                    ]){
                                        cmutils.removeAggregationsFromConfigurationsByNamePattern()
                                        withEnv(["CMA_EXT_CONFIG_FILE=${vars.cma_correlator_content_version_path}", "CMA_EXT_CONFIG_ENDPOINT=${vars.cma_correlator_content_version_endpoint}"]) {
                                            sh './bob/bob load-cm-analytics-config-cubes-into-eea'
                                        }
                                        // WA: Temporary sleeping
                                        sleep(time: 5, unit: 'MINUTES' )
                                        withEnv(["CMA_EXT_CONFIG_FILE=${vars.cma_config_path}"]) {
                                            sh './bob/bob load-cm-analytics-config-cubes-into-eea'
                                        }
                                    }
                                }
                            }
                        }

                        stage('Run health check after CM-Analytics config load') {
                            when {
                                expression { params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE__HELM_VALUES_AND_CMA_CONF || params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE_IS_HELM_AND_CMA}
                            }
                            steps {
                                script {
                                    clusterLogUtilsInstance.runHealthCheck("${vars.waitForPodsAfterInstall}", "${STAGE_NAME}")
                                }
                            }
                        }

                        stage('Run CMA health check after CM-Analytics config load') {
                            when {
                                expression { params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE__HELM_VALUES_AND_CMA_CONF || params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE_IS_HELM_AND_CMA}
                            }
                            steps {
                                catchError(stageResult: 'FAILURE', buildResult: "${params.BUILD_RESULT_WHEN_CMA_HEALTH_CHECK_FAILED}") {
                                    script {
                                        clusterLogUtilsInstance.runHealthCheckWithCMA("${vars.waitForPodsAfterInstall}", "${STAGE_NAME}")
                                    }
                                }
                            }
                        }

                        stage('init UTF Test Variables') {
                            steps {
                                script {
                                    utf.initUtfTestVariables(vars)
                                }
                            }
                        }

                        stage('UTF Pre-activities') { // UTF_PRE_ACTIVITIES_TEST_NAME
                            steps {
                                script {
                                    def pre_activities = [name: "${UTF_PRE_ACTIVITIES_TEST_NAME}", build_result: 'FAILURE', stage_result: 'FAILURE', exec_id: "${UTF_PRE_ACTIVITIES_TEST_EXECUTION_ID}", metafilter: "${env.UTF_PRE_ACTIVITIES_META_FILTER}", timeout: "${UTF_PRE_ACTIVITIES_TEST_TIMEOUT}", logfile: "${UTF_PRE_ACTIVITIES_TEST_LOGFILE}"]
                                    utf.execUtfTest(pre_activities)
                                }
                            }
                            post {
                                always {
                                    script {
                                        clusterLogUtilsInstance.getResourceCapacity(env.CLUSTER)
                                    }
                                }
                            }
                        }

                        stage('Decisive Nx1 Staging UTF Cucumber Tests') {
                            steps {
                                script {
                                    def cucumber_test =  [name: 'Decisive Nx1 Staging UTF Cucumber Tests', build_result: 'FAILURE', stage_result: 'FAILURE', exec_id: "101", metafilter: "@decisive and @nx1 and @staging and not @onlyUpgrade and not @tc_under_development", timeout: "1800", logfile: "utf_decisive_nx1_staging_cucumber.log"]
                                    utf.execUtfTest(cucumber_test)
                                }
                            }
                        }

                        stage('Decisive robot Tests') {
                            steps {
                                runRvRobot('decisive')
                            }
                            post {
                                always {
                                    script {
                                        archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                                    }
                                }
                            }
                        }

                        stage("UTF Post-activities") { //UTF_POST_ACTIVITIES_TEST_NAME
                            steps {
                                script {
                                    def stop_data_loading = [name: "${UTF_POST_ACTIVITIES_TEST_NAME}", build_result: 'SUCCESS', stage_result: 'FAILURE', exec_id: "${UTF_POST_ACTIVITIES_TEST_EXECUTION_ID}", metafilter: "${env.UTF_POST_ACTIVITIES_META_FILTER}", timeout: "${UTF_POST_ACTIVITIES_TEST_TIMEOUT}", logfile: "${UTF_POST_ACTIVITIES_TEST_LOGFILE}"]
                                    utf.execUtfTest(stop_data_loading)
                                }
                            }
                        }
                    }
                    post {
                        always {
                            script {
                                if (!"${env.EEA_NS_CHECK_FAILED}".toBoolean()) {
                                    def labelmanualchanged = checkLockableResourceLabelManualChange(params.CLUSTER)
                                    try {
                                        prepareClusterForLogCollection("${params.CLUSTER}", "${env.JOB_NAME}", "${env.BUILD_NUMBER}", labelmanualchanged)
                                    }
                                    catch (err) {
                                        echo "Caught prepareClusterForLogCollection ERROR: ${err}"
                                    }
                                }
                                sendLockEventToDashboard (transition: "release", cluster: env.CLUSTER)
                                // Save the lock times
                                env.lock_end = java.time.LocalDateTime.now()
                                sh "{ (echo '$system,${env.lock_start},${env.lock_end},eea-application-staging-nx1' >> /data/nfs/productci/cluster_lock.csv) } || echo '/data/nfs/productci/cluster_lock.csv is unreachable'"
                            }
                        }
                    }
                }
            }
        }
        stage('Archive artifact.properties') {
            steps {
                 // Archive artifact.properties so Spinnaker can read the parameters
                 archiveArtifacts artifacts: 'artifact.properties', allowEmptyArchive: true
            }
        }
    }
    post {
        always {
            script {
                if (!params.DRY_RUN && params.CLUSTER != '') {
                    echo "currentBuild.result: ${currentBuild.result}"
                    echo "currentBuild.currentResult: ${currentBuild.currentResult}"
                    if (!"${env.EEA_NS_CHECK_FAILED}".toBoolean()) {
                        try {
                            echo "Execute cluster-logcollector job ... \n - cluster: ${params.CLUSTER}"
                            build job: "cluster-logcollector", parameters: [
                                stringParam(name: "CLUSTER_NAME", value: "${params.CLUSTER}"),
                                booleanParam(name: "CLUSTER_CLEANUP", value: !env.SKIP_CLEANUP.toBoolean()),
                                stringParam(name: "AFTER_CLEANUP_DESIRED_CLUSTER_LABEL", value: "${params.AFTER_CLEANUP_DESIRED_CLUSTER_LABEL}"),
                                stringParam(name: 'LAST_LABEL_SET', value: env.LASTLABEL)
                                ], wait: true
                        }
                        catch (err) {
                            echo "Caught cluster-logcollector ERROR: ${err}"
                            error "CLUSTER LOGCOLLECTOR / CLEANUP FAILED"
                        }
                    }

                    try {
                        env.END_EPOCH = ((new Date()).getTime()/1000 as double).round()
                        sh """
                        cat > performance.properties << EOF
                            START_EPOCH=${env.START_EPOCH}
                            END_EPOCH=${env.END_EPOCH}
                            SPINNAKER_TRIGGER_URL='CLUSTER_VALIDATE'
                            EOF
                        """.stripIndent()
                        archiveArtifacts artifacts: 'performance.properties', allowEmptyArchive: true

                        def currentJobFullDisplayName = currentBuild.getFullDisplayName().replace(' #', '__')
                        clusterLogUtilsInstance.addGrafanaUrlToJobDescription(env.START_EPOCH, env.END_EPOCH, 'CLUSTER_VALIDATE', currentJobFullDisplayName)

                    }
                    catch (err) {
                         echo "Caught performance data export ERROR: ${err}"
                    }

                    // Publish logs to ARM
                    def logFolder = "${env.JOB_NAME}-${env.BUILD_NUMBER}/"
                    clusterLogUtilsInstance.publishLogsToArm("${logFolder}")
                }
            }
        }
        cleanup {
            cleanWs()
        }
    }
}

void runRvRobot(String robotTags) {
    def stageBuildResult = robotTags == 'decisive' ? 'FAILURE' : 'SUCCESS'
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        catchError(buildResult: stageBuildResult, stageResult: 'FAILURE' ) {
            dir('project-meta-baseline') {
                script {
                    try {
                        new EEA_Robot(this).initCiPayload(utf)     // prepares env variables for rvrobot test execution
                        env.ROBOT_TAGS = robotTags
                        execRvRobotTest()
                    } catch (err) {
                        error "EXECUTE ERIC-EEA-ROBOT FAILED:\n${err}"
                    }
                }
            }
        }
    }
}
