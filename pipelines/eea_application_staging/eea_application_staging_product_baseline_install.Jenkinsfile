@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import com.ericsson.eea4.ci.GlobalVars
import com.ericsson.eea4.ci.CommonUtils
import com.ericsson.eea4.ci.ClusterLockUtils
import com.ericsson.eea4.ci.ClusterLogUtils

@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def gitmeta = new GitScm(this, 'EEA/project-meta-baseline')
@Field def vars = new GlobalVars()
@Field def cmutils = new CommonUtils(this)
@Field def clusterLogUtilsInstance = new ClusterLogUtils(this)

@Field def CMA_MODE__HELM_VALUES = "true"
@Field def CMA_MODE__HELM_VALUES_AND_CMA_CONF = "false"

@Field def CMA_MODE_IS_HELM = "HELM"
@Field def CMA_MODE_IS_HELM_AND_CMA = "HELM_AND_CMA"


def cluster_lock //for clusterLockParamsMap entry
def stageResultsInfo = [:]
def stageCommentList = [:]

def spotfire_install_job
def link_spotfire_platform_to_eea_job

def eea_product_ci_meta_baseline_loop_utf_and_data_loader_deploy_build

pipeline {
    options {
        buildDiscarder(logRotator(daysToKeepStr: "14", artifactDaysToKeepStr: "7"))
        skipDefaultCheckout()
        ansiColor('xterm')
    }
    agent {
        node {
            label 'productci'
        }
    }

    parameters {
        string(name: 'INT_CHART_NAME', description: 'Chart name e.g.: eric-ms-b', defaultValue: 'eric-eea-int-helm-chart')
        string(name: 'INT_CHART_REPO', description: 'Chart repo i.e.: https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/', defaultValue: 'https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/')
        string(name: 'GIT_BRANCH', description: 'Gerrit git branch of the integration chart git repo e.g.: eea4_4.4.0_pra . If the value is latest than calculate the branch name using the latest pra git tag', defaultValue: 'latest')
        string(name: 'SPINNAKER_TRIGGER_URL', description: 'Spinnaker pipeline triggering url', defaultValue: '')
        string(name: 'lock_start', description: 'Locking start timestamp, will be overwritten', defaultValue: '')
        string(name: 'lock_end', description: 'Locking start timestamp, will be overwritten', defaultValue: '')
        string(name: 'SPINNAKER_ID', description: "The spinnaker execution's id", defaultValue: '')
        string(name: 'PIPELINE_NAME', description: "The spinnaker pipeline name", defaultValue: '')
        string(name: 'GERRIT_REFSPEC',  description: 'Gerrit Refspec of the integration chart git repo e.g.: refs/changes/90/12941790/2', defaultValue: '')
        booleanParam(name: 'SKIP_META_BASELINE_INSTALL', description: 'skip the meta-baseline install stage', defaultValue: true)
        booleanParam(name: 'SKIP_COLLECT_LOG', description: 'skip the log collection pipeline', defaultValue: false)
        booleanParam(name: 'SKIP_CLEANUP', description: 'skip the cleanup pipeline.', defaultValue: true)
        string(name: 'CUSTOM_CLUSTER_LABEL', description: 'If CUSTOM_CLUSTER_LABEL is set, we have to set that label at the end of the pipeline executions, and FORCE skip the cleanup !!!', defaultValue: "${vars.resourceLabelUpgrade}")
        string(name: 'CLUSTER_LABEL', defaultValue: "${vars.resourceLabelCommon}", description: "cluster resource label to execute on. Default valuse is 'bob-ci' . Don't specify if CLUSTER_NAME specified")
        string(name: 'CLUSTER_NAME', description: "cluster resource name to execute on. Don't specify if CLUSTER_LABEL specified")
        choice(name: 'BUILD_RESULT_WHEN_NELS_CHECK_FAILED', choices: ['FAILURE', 'SUCCESS'], description: 'build result when the Check NELS availability failed')

        choice(name: 'HELM_AND_CMA_VALIDATION_MODE', choices: [CMA_MODE_IS_HELM_AND_CMA, CMA_MODE__HELM_VALUES_AND_CMA_CONF, CMA_MODE__HELM_VALUES, CMA_MODE_IS_HELM],
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
                """)
        booleanParam(name: 'SKIP_SPOTFIRE_INSTALL', description: 'skip the Spotfire install stage', defaultValue: false)
        string(
            name: 'ADP_APP_STAGING_GERRIT_REFSPEC_FOR_SF_INSTALL',
            defaultValue: '',
            description: 'Gerrit refspec of the adp-app-staging repo e.g.: refs/changes/87/4641487/1 . Will pass to Spotfire install job'
        )
    }

    environment {
        NAMESPACE = 'eric-eea-ns'
        SEP_CHART_NAME = "eric-cs-storage-encryption-provider"
        SEP_CHART_REPO = "https://arm.sero.gic.ericsson.se/artifactory/proj-adp-rs-storage-encr-released-helm"
        LINK_SPOTFIRE_PLATFORM_TO_EEA_STAGE_NAME = "Link Spotfire platform to EEA"
        EXECUTE_SPOTFIRE_DEPLOYMENT_STAGE_NAME = "Execute Spotfire deployment"
        SPOTFIRE_ASSET_INSTALL_ASSIGN_LABEL_WRAPPER_JOB_NAME = "spotfire-asset-install-assign-label-wrapper"
        RUN_HEALTH_CHECK_AFTER_INSTALL_STAGE_NAME = "Run health check after install"
        RUN_HEALTH_CHECK_AFTER_CM_ANALYTICS_CONFIG_LOAD_STAGE_NAME = "Run health check after CM-Analytics config load"
        RUN_CMA_HEALTH_CHECK_AFTER_CM_ANALYTICS_CONFIG_LOAD_STAGE_NAME = "Run CMA health check after CM-Analytics config load"
        DIMENSIONING_OUTPUT_GENERATOR_JOB_NAME = "dimensioning-tool-output-generator"
        RUN_CHECKSPOTFIREPLATFORM_HEALTH_CHECK_STAGE_NAME = "Run CheckSpotfirePlatform health check"
        EEA_PRODUCT_CI_META_BASELINE_LOOP_UTF_AND_DATA_LOADER_DEPLOY_JOB_NAME = "eea-product-ci-meta-baseline-loop-utf-and-data-loader-deploy"
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

        stage('Cluster params check') {
            steps {
                checkBuildParameters()
            }
        }

        stage('Cleanup workspace') {
            steps {
                script {
                    cleanWs()
                }
            }
        }

        stage('Checkout cnint') {
            steps {
                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                    script {
                        if ( !params.GIT_BRANCH?.trim() && !params.GERRIT_REFSPEC?.trim() ) {
                            error "GIT_BRANCH or GERRIT_REFSPEC should be specified!"
                        }
                        if( params.GIT_BRANCH?.trim() && params.GERRIT_REFSPEC?.trim() ) {
                            error "only one of the GIT_BRANCH or GERRIT_REFSPEC should be specified"
                        }
                        if( params.GIT_BRANCH?.trim() ) {
                            if( params.GIT_BRANCH == 'latest' ) {
                                gitcnint.checkout("latest_release", 'cnint_latest_release')
                                dir('cnint_latest_release') {
                                    env.GIT_BRANCH = sh (script: '''#!/bin/bash
                                        commit_id=$(git log --format="%H" -n 1)
                                        git show-ref --tags -d | grep "${commit_id}" | grep '_pra' | awk -F"[ ^]" '{print $2}' | awk -F/ '{print $3}' | sed 's/_pra//'
                                    ''', returnStdout: true).trim()
                                }
                            }
                            gitcnint.checkout("${env.GIT_BRANCH}", 'cnint')
                        }
                        if( params.GERRIT_REFSPEC?.trim() ) {
                            gitcnint.checkoutRefSpec("${GERRIT_REFSPEC}","FETCH_HEAD", 'cnint')
                            dir('cnint') {
                                env.GIT_BRANCH = sh (script: '''#!/bin/bash
                                    git name-rev --name-only HEAD  --no-undefined | awk -F'/' '{print $3}'
                                ''', returnStdout: true).trim()
                            }
                        }
                        dir('cnint') {
                            sh "git status"
                        }
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                }
            }
        }

        stage('Checkout adp-app-staging full') {
            steps {
                dir('adp-app-staging-full-checkout') {
                    script {
                        gitadp.checkout(env.MAIN_BRANCH,'')
                    }
                }
            }
        }

        stage('Checkout adp-app-staging') {
            steps {
                script {
                    gitadp.checkout('master', 'adp-app-staging')
                }
            }
        }

        stage('Init eric-eea-int-helm-chart version from the cnint') {
            steps {
                script {
                    def data = readYaml file: 'cnint/eric-eea-int-helm-chart/Chart.yaml'
                    env.INT_CHART_VERSION = data.version
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

        stage('Get utf version from the meta') {
            steps {
                script {
                    gitmeta.checkout("master", "project-meta-baseline")
                    getUtfVersionFromTheMeta()
                }
            }
        }

        stage('Build started message to gerrit') {
            steps {
                sendBuildStartedMessageToGerrit()
            }
        }

        stage('Resource locking - utf deploy and K8S Install') {
            stages {
                stage('Wait for cluster') {
                    when {
                        expression { params.CLUSTER_LABEL }
                    }
                    steps {
                        script {
                            env.CLUSTER = ""
                            sendLockEventToDashboard (transition: "wait-for-cluster")
                            waitForLockableResource("${params.CLUSTER_LABEL}", "${params.PIPELINE_NAME}", "${env.JOB_NAME}")
                            sendLockEventToDashboard (transition: "wait-for-lock")
                        }
                    }
                }

                stage('Lock') {
                    options {
                        lock resource: "${params.CLUSTER_NAME}", label: "${params.CLUSTER_LABEL}", quantity: 1, variable: 'system'
                    }
                    stages {
                        stage('log lock') {
                            steps {
                                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                                    script {
                                        env.CLUSTER = env.system
                                        logLock()
                                    }
                                }
                            }
                            post {
                                always {
                                    archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                                }
                            }
                        }

                        stage('init vars') {
                            steps {
                                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                                    dir('cnint') {
                                        //call ruleset init
                                        withCredentials([usernamePassword(credentialsId: 'arm-seli-eeaprodart-token', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                                            usernamePassword(credentialsId: 'arm-sero-eeaprodart-token', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
                                            usernamePassword(credentialsId: 'arm-seli-eeaprodart-token', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
                                            string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                            file(credentialsId: env.system, variable: 'KUBECONFIG')
                                        ]) {
                                            script {
                                                sh './bob/bob init'
                                            }
                                        }
                                    }
                                }
                            }
                            post {
                                always {
                                    archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                                }
                            }
                        }

                        stage('Check NELS availability') {
                            steps {
                                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                                    catchError(stageResult: 'FAILURE', buildResult: "${params.BUILD_RESULT_WHEN_NELS_CHECK_FAILED}") {
                                        dir('cnint') {
                                            script {
                                                withCredentials([usernamePassword(credentialsId: 'hub-root-user', usernameVariable: 'HUB_ROOT_USER', passwordVariable: 'HUB_ROOT_PASSWD'),
                                                                 file(credentialsId: env.system, variable: 'KUBECONFIG')]) {
                                                    checkNelsAvailability()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            post {
                                always {
                                    archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                                }
                            }
                        }

                        stage('Check if namespace exist') {
                            steps {
                                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                                    dir('cnint') {
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
                            }
                            post {
                                always {
                                    script {
                                        archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                                        stageCommentList[STAGE_NAME] = ["<a href=\"${env.BUILD_URL}/artifact/check-namespaces-not-exist.log\">check-namespaces-not-exist.log</a>"]
                                    }
                                }
                            }
                        }

                        stage('CRD Install') {
                            steps {
                                CDR_Install()
                            }
                            post {
                                always {
                                    script {
                                        archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                                        stageCommentList[STAGE_NAME] = ["<a href=\"${env.BUILD_URL}/artifact/crd-install.log\">crd-install.log</a>"]
                                    }
                                }
                            }
                        }

                        stage('Set CMA helm values') {
                            steps {
                                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                                    dir('cnint') {
                                        set_cma_helm_values()
                                    }
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

                        stage("Run dimtool") {
                            steps {
                                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')){
                                    runDimensioningTool(stageCommentList)
                                }
                            }
                            post {
                                always {
                                    archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                                }
                            }
                        }

                        stage('Parallel install prerequisite for EEA4') {
                            parallel {
                                stage('utf and data loader deploy') {
                                    when {
                                        expression { params.SKIP_META_BASELINE_INSTALL == false }
                                    }
                                    steps{
                                        utfAndDataLoaderDeploy(eea_product_ci_meta_baseline_loop_utf_and_data_loader_deploy_build)
                                    }
                                    post {
                                        always {
                                            archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                                            script {
                                                stageCommentList[STAGE_NAME] = ["<a href=\"${env.JENKINS_URL}/job/${env.EEA_PRODUCT_CI_META_BASELINE_LOOP_UTF_AND_DATA_LOADER_DEPLOY_JOB_NAME}/${eea_product_ci_meta_baseline_loop_utf_and_data_loader_deploy_build.number}\">${env.EEA_PRODUCT_CI_META_BASELINE_LOOP_UTF_AND_DATA_LOADER_DEPLOY_JOB_NAME}/${eea_product_ci_meta_baseline_loop_utf_and_data_loader_deploy_build.number}</a>"]
                                            }
                                        }
                                    }
                                }

                                stage('SEP Install') {
                                    steps {
                                        tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                                            sepInstall()
                                        }
                                    }
                                    post {
                                        always {
                                            archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                                        }
                                    }
                                }

                                stage("Execute Spotfire deployment") { //EXECUTE_SPOTFIRE_DEPLOYMENT_STAGE_NAME
                                    when {
                                        expression { params.SKIP_SPOTFIRE_INSTALL == false }
                                    }
                                    steps {
                                        executeSpotfireDeployment(spotfire_install_job, stageCommentList)
                                    }
                                    post {
                                        always {
                                            archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                                        }
                                    }
                                }
                            }
                        }

                        stage('Store meta-baseline-install configmap') {
                            when {
                                expression { params.SKIP_META_BASELINE_INSTALL == false }
                            }
                            steps{
                                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                                    dir('cnint') {
                                        storeInstalledMetaBaselineParamsFromCluster()
                                    }
                                }
                            }
                            post {
                                always {
                                    archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                                }
                            }
                        }

                        stage('Set description') {
                            steps {
                                setDescription(stageResultsInfo)
                            }
                        }


                        stage('Product Install') {
                            steps {
                                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                                    dir('cnint') {
                                        script {
                                            Map args = [
                                                "helmTimeout":   "4200",
                                                "clusterName":   "${env.system}",
                                                "pipelineName":  "${env.JOB_NAME}",
                                                "bobRulesList":  ["./bob/bob -r ruleset2.0.yaml init-mxe", "./bob/bob -r ruleset2.0.yaml verify-values-files > k8s-test-verify-values.log", "./bob/bob -r ruleset2.0.yaml k8s-test-splitted-values > k8s-test.log"]
                                            ]
                                            echo "Installing ${INT_CHART_VERSION}"
                                            cmutils.k8sInstallTest(args)
                                        }
                                    }
                                }
                            }
                            post {
                                failure {
                                    script {
                                        dir('cnint') {
                                            clusterLogUtilsInstance.getResourceCapacity(env.CLUSTER)
                                        }
                                    }
                                }
                                always {
                                    script {
                                        archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                                        dir ('cnint') {
                                            script {
                                                cmutils.archiveFilesFromLog("k8s-test.log", "--helm_value_file=(\\S+)[\\]\\s]", "install-configvalues.tar.gz")
                                            }
                                        }
                                        archiveArtifacts artifacts: "cnint/install-configvalues.tar.gz", allowEmptyArchive: true
                                        archiveArtifacts artifacts: "cnint/*values*.txt", allowEmptyArchive: true
                                        stageCommentList[STAGE_NAME] = ["<a href=\"${env.BUILD_URL}/artifact/k8s-test.log\">k8s-test.log</a>"]
                                        stageCommentList[STAGE_NAME] += ["<a href=\"${env.BUILD_URL}/artifact/k8s-test-verify-values.log\">k8s-test-verify-values.log</a>"]
                                    }
                                }
                            }
                        }

                        stage("Link Spotfire platform to EEA") { //LINK_SPOTFIRE_PLATFORM_TO_EEA_STAGE_NAME
                            when {
                                expression { params.SKIP_SPOTFIRE_INSTALL == false }
                            }
                            steps {
                                linkSpotfirePlatformToEEA(link_spotfire_platform_to_eea_job, stageCommentList)
                            }
                        }

                        stage('Run CheckSpotfirePlatform health check') { // RUN_CHECKSPOTFIREPLATFORM_HEALTH_CHECK_STAGE_NAME
                            when {
                                expression { params.SKIP_SPOTFIRE_INSTALL == false }
                            }
                            steps {
                                script {
                                    dir('cnint') {
                                        clusterLogUtilsInstance.runHealthCheck("${vars.waitForPodsAfterInstall}", "${STAGE_NAME}", clusterCredentialID=env.CLUSTER, eeaHealthcheckCheckClasses='CheckSpotfirePlatform',  k8s_namespace='spotfire-platform')
                                    }
                                }
                            }
                            post {
                                always {
                                    script {
                                    stageCommentList[STAGE_NAME] = ["<a href=\"${env.BUILD_URL}/artifact/check-pods-state-with-wait__stage_"+RUN_CHECKSPOTFIREPLATFORM_HEALTH_CHECK_STAGE_NAME.replaceAll(' ', '_')+".log\">"+RUN_CHECKSPOTFIREPLATFORM_HEALTH_CHECK_STAGE_NAME.replaceAll(' ', '_')+".log</a>"]
                                    }
                                }
                            }
                        }

                        stage('Create stream-aggregator configmap') {
                            when {
                                expression { params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE__HELM_VALUES_AND_CMA_CONF || params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE_IS_HELM_AND_CMA }
                            }
                            steps {
                                dir ('cnint') {
                                    script {
                                        // WA START: EEA 4.9.0 Dimensioning Tool Output fix https:// ger rit.erics son.se/#/c/17870486/
                                        // TODO: Should be remove after 4.9.1 PRA
                                        sh """ cp -f "${vars.cma_stream_aggregator_dimensioning_file_path}${vars.cma_stream_aggregator_dimensioning_file}" "${vars.cma_stream_aggregator_dimensioning_file_path}${vars.cma_stream_aggregator_dimensioning_file}.orig.BEFORE_WA" """
                                        archiveArtifacts artifacts: "${vars.cma_stream_aggregator_dimensioning_file_path}${vars.cma_stream_aggregator_dimensioning_file}.orig.BEFORE_WA", allowEmptyArchive: true
                                        sh """
                                            yq-4.x -i eval 'del(.aggregators.*.sparkDriver.instances)' "${vars.cma_stream_aggregator_dimensioning_file_path}${vars.cma_stream_aggregator_dimensioning_file}"
                                        """
                                        // WA END

                                        cmutils.createAggregatorConfigmapFromDimtoolOutput()
                                    }
                                }
                            }
                        }

                        stage('Run health check after install') {
                            steps {
                                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                                    dir('cnint') {
                                        script {
                                            clusterLogUtilsInstance.runHealthCheck("${vars.waitForPodsAfterInstall}", "${STAGE_NAME}")
                                        }
                                    }
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
                                expression { params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE__HELM_VALUES_AND_CMA_CONF || params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE_IS_HELM_AND_CMA }
                            }
                            steps {
                                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                                    loadConfigJsonToCMAnalytics()
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

                        stage('Run health check after CM-Analytics config load') {
                            when {
                                expression { params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE__HELM_VALUES_AND_CMA_CONF || params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE_IS_HELM_AND_CMA }
                            }
                            steps {
                                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                                    dir('cnint') {
                                        script {
                                            clusterLogUtilsInstance.runHealthCheck("${vars.waitForPodsAfterInstall}", "${STAGE_NAME}")
                                        }
                                    }
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

                        stage('Run CMA health check after CM-Analytics config load') {
                            when {
                                expression { params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE__HELM_VALUES_AND_CMA_CONF || params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE_IS_HELM_AND_CMA }
                            }
                            steps {
                                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                                    dir('cnint') {
                                        script {
                                            clusterLogUtilsInstance.runHealthCheckWithCMA("${vars.waitForPodsAfterInstall}", "${STAGE_NAME}")
                                        }
                                    }
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

                        stage('Store product-baseline-install configmap') {
                            steps{
                                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                                    dir('cnint') {
                                        storeInstalledBaselineParamsFromCluster()
                                    }
                                }
                            }
                            post {
                                always {
                                    archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                                }
                            }
                        }

                    }
                    post {
                        always {
                            script {
                                echo "Lock stage always post action currentBuild.result:" + currentBuild.result
                                //Save the lock times
                                env.lock_end = java.time.LocalDateTime.now()
                                sh "{ (echo '$system,${env.lock_start},${env.lock_end},eea-application-staging-product-baseline-install' >> /data/nfs/productci/cluster_lock.csv) } || echo '/data/nfs/productci/cluster_lock.csv is unreachable'"
                                archiveArtifacts artifacts: "watches_count_indicators.log", allowEmptyArchive: true

                                try {
                                    env.END_EPOCH = ((new Date()).getTime()/1000 as double).round()
                                    sh """
                                    cat > performance.properties << EOF
START_EPOCH=${env.START_EPOCH}
END_EPOCH=${env.END_EPOCH}
SPINNAKER_TRIGGER_URL=${params.SPINNAKER_TRIGGER_URL}
EOF
                                    """.stripIndent()
                                    archiveArtifacts artifacts: 'performance.properties', allowEmptyArchive: true

                                    def currentJobFullDisplayName = currentBuild.getFullDisplayName().replace(' #', '__')
                                    clusterLogUtilsInstance.addGrafanaUrlToJobDescription(env.START_EPOCH, env.END_EPOCH, params.SPINNAKER_TRIGGER_URL, currentJobFullDisplayName)
                                    saveProductBaselineInstallPerfData()
                                }
                                catch (err) {
                                     echo "Caught performance data export ERROR: ${err}"
                                }
                            }
                        }
                        success {
                            script {
                                echo "Lock stage success post action currentBuild.result:" + currentBuild.result
                                dir('cnint') {
                                    clusterLogUtilsInstance.getResourceCapacity(env.CLUSTER)
                                }

                                def new_label = "${vars.resourceLabelUpgrade}"
                                if ( params.CUSTOM_CLUSTER_LABEL?.trim() ) {
                                    new_label = params.CUSTOM_CLUSTER_LABEL
                                }

                                def labelmanualchanged = checkLockableResourceLabelManualChange(env.CLUSTER)
                                echo "labelmanualchanged: " + labelmanualchanged + ", params.SKIP_COLLECT_LOG: " + params.SKIP_COLLECT_LOG + ", new_label: " + new_label + ", params.CUSTOM_CLUSTER_LABEL: " + params.CUSTOM_CLUSTER_LABEL
                                if ( params.SKIP_COLLECT_LOG ) {
                                    if (!labelmanualchanged) {
                                        try {
                                            build job: "lockable-resource-label-change", parameters: [
                                                booleanParam(name: 'DRY_RUN', value: false),
                                                stringParam(name: 'DESIRED_CLUSTER_LABEL', value: new_label),
                                                stringParam(name: 'CLUSTER_NAME', value: env.CLUSTER),
                                                booleanParam(name: 'RESOURCE_RECYCLE', value: false),
                                                stringParam(name: 'SPINNAKER_ID', value: params.SPINNAKER_ID),
                                                stringParam(name: 'SPINNAKER_TRIGGER_URL', value: params.SPINNAKER_TRIGGER_URL)
                                            ], wait: true
                                            echo "The '${new_label}' label is set for the resource ${env.CLUSTER}"
                                        } catch (err) {
                                            echo "Caught: ${err}"
                                            error "Failed to set '${new_label}' label for the resource ${env.CLUSTER}"
                                        }
                                    }
                                } else {
                                    prepareClusterForLogCollection("${env.CLUSTER}", "${env.JOB_NAME}", "${env.BUILD_NUMBER}", labelmanualchanged)
                                }


                            }
                        }
                        failure {
                            script {
                                if (!"${env.EEA_NS_CHECK_FAILED}".toBoolean()) {
                                    def labelmanualchanged = checkLockableResourceLabelManualChange(env.CLUSTER)
                                    prepareClusterForLogCollection("${env.CLUSTER}", "${env.JOB_NAME}", "${env.BUILD_NUMBER}", labelmanualchanged)
                                }
                            }
                        }
                    }
                }
            }
            post {
                always {
                    script {
                        sendLockEventToDashboard (transition: "release", cluster: env.CLUSTER)
                    }
                }
                success {
                    postSuccessStageAfterResourceLock()
                }
                failure {
                    postFailureStageAfterResourceLock()
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
                if ( !params.DRY_RUN ) {
                    echo 'Publish logs to arm'
                    def logFolder = clusterLogUtilsInstance.getLogCollectionFolder("${env.JOB_NAME}", "${env.BUILD_NUMBER}")
                    clusterLogUtilsInstance.publishLogsToArm("${logFolder}")
                }
                cmutils.generateStageResultsHtml(stageCommentList, stageResultsInfo)
            }
        }

        failure {
            script {
                if (params.GERRIT_REFSPEC?.trim()) {
                    sendMessageToGerrit(params.GERRIT_REFSPEC, "Build Failed ${BUILD_URL}: FAILURE")
                }
            }
        }
        success {
            script {
                if (params.GERRIT_REFSPEC?.trim()) {
                    sendMessageToGerrit(params.GERRIT_REFSPEC, "Build Successful ${BUILD_URL}: SUCCESS")
                }
            }
        }
        cleanup {
            cleanWs()
        }
    }
}

def saveProductBaselineInstallPerfData () {
    dir('cnint') {
        withCredentials([usernamePassword(credentialsId: 'arm-seli-eeaprodart-token', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
            usernamePassword(credentialsId: 'arm-sero-eeaprodart-token', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
            usernamePassword(credentialsId: 'arm-seli-eeaprodart-token', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
            file(credentialsId: env.system, variable: 'KUBECONFIG')
        ]) {
            withEnv(["NAME_OF_CONFIGMAP='product-baseline-install-perf-data'", "CONFIGMAP_FILENAME=performance.properties" ]){
                sh """cp "${WORKSPACE}/performance.properties" "${WORKSPACE}/cnint/" """
                sh "./bob/bob -r ${WORKSPACE}/cnint/ruleset2.0.yaml create-configmap-from-file"
            }
        }
    }
}

void storeInstalledMetaBaselineParamsFromCluster(){
    script {
        archiveArtifacts artifacts: "meta_baseline.groovy", allowEmptyArchive: true
        withCredentials([usernamePassword(credentialsId: 'arm-seli-eeaprodart-token', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
            usernamePassword(credentialsId: 'arm-sero-eeaprodart-token', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
            usernamePassword(credentialsId: 'arm-seli-eeaprodart-token', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
            file(credentialsId: env.system, variable: 'KUBECONFIG')
        ]) {
            withEnv(["NAME_OF_CONFIGMAP='meta-baseline-install'", "CONFIGMAP_FILENAME=meta_baseline.groovy" ]){
                sh "./bob/bob -r ${WORKSPACE}/cnint/ruleset2.0.yaml create-configmap-from-file"
            }
        }
    }
}

void storeInstalledBaselineParamsFromCluster(){
    script {
        sh "echo 'env.BASELINE_GIT_BRANCH=\"${env.GIT_BRANCH}\"\nenv.BASELINE_INT_CHART_VERSION=\"${env.INT_CHART_VERSION}\"\nenv.BASELINE_BUILD_URL=\"${BUILD_URL}\"\nenv.BASELINE_BUILD_NUMBER=\"${BUILD_NUMBER}\"\nenv.BASELINE_JOB_NAME=\"${JOB_NAME}\"' > product_baseline.groovy"
        sh "echo 'env.BASELINE_CLUSTER_NAME=\"${env.CLUSTER}\"\nenv.BASELINE_HELM_AND_CMA_VALIDATION_MODE=\"${env.HELM_AND_CMA_VALIDATION_MODE}\"' >> product_baseline.groovy"
        archiveArtifacts artifacts: "product_baseline.groovy", allowEmptyArchive: true
        withCredentials([usernamePassword(credentialsId: 'arm-seli-eeaprodart-token', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
            usernamePassword(credentialsId: 'arm-sero-eeaprodart-token', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
            usernamePassword(credentialsId: 'arm-seli-eeaprodart-token', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
            file(credentialsId: env.system, variable: 'KUBECONFIG')
        ]) {
            withEnv(["NAME_OF_CONFIGMAP='product-baseline-install'", "CONFIGMAP_FILENAME=product_baseline.groovy" ]){
                sh "./bob/bob -r ${WORKSPACE}/cnint/ruleset2.0.yaml create-configmap-from-file"
            }
        }
    }
}
void checkBuildParameters() {
    script {
        if (!params.CLUSTER_LABEL && !params.CLUSTER_NAME) {
            currentBuild.result = 'ABORTED'
            error("CLUSTER_LABEL or CLUSTER_NAME must be specified")
        } else if (params.CLUSTER_LABEL && params.CLUSTER_NAME) {
            currentBuild.result = 'ABORTED'
            error("Only one of CLUSTER_LABEL or CLUSTER_NAME must be specified")
        }
        if ( (env.MAIN_BRANCH == 'master') && params.SKIP_CLEANUP && !params.CUSTOM_CLUSTER_LABEL) {
            currentBuild.result = 'ABORTED'
            error("CUSTOM_CLUSTER_LABEL must be specified when SKIP_CLEANUP is true")
        }
    }
}
void postSuccessStageAfterResourceLock() {
    script {
        try {
            echo "After lock stage success post action currentBuild.result:" + currentBuild.result
            def do_the_cleanup = !params.SKIP_CLEANUP
            def new_label = "${vars.resourceLabelUpgrade}"
            if ( params.CUSTOM_CLUSTER_LABEL?.trim() ) {
                new_label = params.CUSTOM_CLUSTER_LABEL
                do_the_cleanup = false
            }
            if ( !params.SKIP_COLLECT_LOG ) {
                if (!env.CLUSTER) {
                    echo "There was no cluster lock, COLLECT_LOG skipped"
                } else {
                    try {
                        echo "Execute cluster-logcollector job ... \n - cluster: ${env.CLUSTER}"
                        build job: "cluster-logcollector", parameters: [
                            stringParam(name: "CLUSTER_NAME", value: env.CLUSTER),
                            stringParam(name: "DESIRED_CLUSTER_LABEL", value: new_label),
                            booleanParam(name: "CLUSTER_CLEANUP", value: do_the_cleanup),
                            stringParam(name: "AFTER_CLEANUP_DESIRED_CLUSTER_LABEL", value: new_label),
                            stringParam(name: 'LAST_LABEL_SET', value: env.LASTLABEL)
                        ], wait: true
                    }
                    catch (err) {
                        echo "Caught cluster-logcollector ERROR: ${err}"
                    }
                }
            } else if ( params.SKIP_COLLECT_LOG && !params.SKIP_CLEANUP ) {
                if (!env.CLUSTER) {
                        echo "There was no cluster lock, COLLECT_LOG skipped"
                } else {
                    try {
                        echo "Execute cluster-cleanup job ... \n - cluster: ${env.CLUSTER}"
                        build job: "cluster-cleanup", parameters: [
                            stringParam(name: "CLUSTER_NAME", value: env.CLUSTER),
                            stringParam(name: 'CNINT_GERRIT_REFSPEC', value: params.GERRIT_REFSPEC),
                            stringParam(name: "DESIRED_CLUSTER_LABEL", value: "${vars.resourceLabelCommon}"),
                            stringParam(name: "LAST_LABEL_SET", value: env.LASTLABEL),
                            stringParam(name: 'SPINNAKER_ID', value: params.SPINNAKER_ID),
                            stringParam(name: 'SPINNAKER_TRIGGER_URL', value: params.SPINNAKER_TRIGGER_URL)
                        ], wait: true
                    }
                    catch (err) {
                        echo "Caught cluster-logcollector ERROR: ${err}"
                    }
                }
            } else {
                echo "COLLECT_LOG skipped (params.SKIP_COLLECT_LOG=${params.SKIP_COLLECT_LOG})"
            }
        } catch (err) {
            echo "Caught: ${err}"
        }
    }
}

void postFailureStageAfterResourceLock() {
    script {
        echo "After lock stage failure post action currentBuild.result:" + currentBuild.result
        if (!"${env.EEA_NS_CHECK_FAILED}".toBoolean()) {
            def do_the_cleanup = true
            def new_label = "${vars.resourceLabelCommon}"
            if (env.CUSTOM_CLUSTER_LABEL?.trim() != "" && params.CUSTOM_CLUSTER_LABEL != vars.resourceLabelUpgrade) {
                new_label = params.CUSTOM_CLUSTER_LABEL
                do_the_cleanup = false
            }
            if ( !params.SKIP_COLLECT_LOG ) {
                if (!env.CLUSTER) {
                    echo "There was no cluster lock, COLLECT_LOG skipped"
                } else {
                    build job: "cluster-logcollector", parameters: [
                        booleanParam(name: 'DRY_RUN', value: false),
                        stringParam(name: "CLUSTER_NAME", value: env.CLUSTER),
                        stringParam(name: "DESIRED_CLUSTER_LABEL", value: new_label),
                        booleanParam(name: "CLUSTER_CLEANUP", value: do_the_cleanup),
                        stringParam(name: "AFTER_CLEANUP_DESIRED_CLUSTER_LABEL", value: new_label),
                        stringParam(name: 'LAST_LABEL_SET', value: env.LASTLABEL),
                        stringParam(name: 'SPINNAKER_ID', value: params.SPINNAKER_ID),
                        stringParam(name: 'SPINNAKER_TRIGGER_URL', value: params.SPINNAKER_TRIGGER_URL)
                    ], wait: true
                }
            } else if ( params.SKIP_COLLECT_LOG && do_the_cleanup ) {
                if (!env.CLUSTER) {
                        echo "There was no cluster lock, COLLECT_LOG skipped"
                } else {
                    echo "do_the_cleanup: " + do_the_cleanup
                    try {
                        echo "Execute cluster-cleanup job ... \n - cluster: ${env.CLUSTER}"
                        build job: "cluster-cleanup", parameters: [
                            booleanParam(name: 'DRY_RUN', value: false),
                            stringParam(name: "CLUSTER_NAME", value: env.CLUSTER),
                            stringParam(name: 'CNINT_GERRIT_REFSPEC', value: params.GERRIT_REFSPEC),
                            stringParam(name: "DESIRED_CLUSTER_LABEL", value: new_label),
                            stringParam(name: "LAST_LABEL_SET", value: env.LASTLABEL),
                            stringParam(name: 'SPINNAKER_ID', value: params.SPINNAKER_ID),
                            stringParam(name: 'SPINNAKER_TRIGGER_URL', value: params.SPINNAKER_TRIGGER_URL)
                        ], wait: true
                    }
                    catch (err) {
                        echo "Caught cluster-logcollector ERROR: ${err}"
                    }
                }
            } else {
                echo "COLLECT_LOG skipped (params.SKIP_COLLECT_LOG=${params.SKIP_COLLECT_LOG})"
            }
        }
    }
}

void set_cma_helm_values() {
    script {
        echo "HELM_AND_CMA_VALIDATION_MODE mode is: ${params.HELM_AND_CMA_VALIDATION_MODE}"
        if (params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE__HELM_VALUES || params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE_IS_HELM ) {
            //configurationManagement disabled for all ms
            sh "echo 'helm-values/disable-cma-values.yaml' >> values-list.txt"
            sh "echo 'helm-values/disable-cma-values.yaml' >> mxe-values-list.txt"
            echo "configurationManagement disabled for all ms"
        }
        else if (params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE__HELM_VALUES_AND_CMA_CONF || params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE_IS_HELM_AND_CMA ) {
            echo "configurationManagement enabled for all ms"
        }
    }
}

void loadConfigJsonToCMAnalytics() {
    dir('cnint') {
        script {
            withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                usernamePassword(credentialsId: 'ECEAART_SEROGIC_API_KEY', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
                file(credentialsId: env.system, variable: 'KUBECONFIG')
            ]){
                cmutils.removeAggregationsFromConfigurationsByNamePattern()
                withEnv(["CMA_EXT_CONFIG_FILE=${vars.cma_correlator_content_version_path}", "CMA_EXT_CONFIG_ENDPOINT=${vars.cma_correlator_content_version_endpoint}"]) {
                    sh './bob/bob load-cm-analytics-config-cubes-into-eea'
                }
                withEnv(["CMA_EXT_CONFIG_FILE=${vars.cma_config_path}"]) {
                    sh './bob/bob load-cm-analytics-config-cubes-into-eea'
                }
            }
        }
    }
}

void runDimensioningTool(stageCommentList) {
    dir('cnint') {
        script {
            env.GERRIT_REFSPEC_FOR_DIMTOOL = env.GIT_BRANCH
            if ( params.GERRIT_REFSPEC ) {
                env.GERRIT_REFSPEC_FOR_DIMTOOL = params.GERRIT_REFSPEC
            }
            def dimensioning_output_generator_job = build job: "${DIMENSIONING_OUTPUT_GENERATOR_JOB_NAME}", parameters: [
                    booleanParam(name: 'DIMTOOL_VALIDATE_OUTPUT', value: true),
                    stringParam(name: 'INT_CHART_NAME', value: params.INT_CHART_NAME),
                    stringParam(name: 'INT_CHART_REPO', value : params.INT_CHART_REPO),
                    stringParam(name: 'INT_CHART_VERSION', value: env.INT_CHART_VERSION),
                    stringParam(name: 'UTF_CHART_NAME', value: env.UTF_CHART_NAME),
                    stringParam(name: 'UTF_CHART_REPO', value: env.UTF_CHART_REPO),
                    stringParam(name: 'UTF_CHART_VERSION', value: env.UTF_CHART_VERSION),
                    stringParam(name: 'DATASET_NAME', value: env.DATASET_NAME),
                    stringParam(name: 'REPLAY_SPEED', value: env.REPLAY_SPEED),
                    stringParam(name: 'GERRIT_REFSPEC', value: env.GERRIT_REFSPEC_FOR_DIMTOOL)
            ], wait: true
            def dimToolGeneratorJobResult = dimensioning_output_generator_job.getResult()
            stageCommentList[STAGE_NAME] = ["<a href=\"${env.JENKINS_URL}/job/${DIMENSIONING_OUTPUT_GENERATOR_JOB_NAME}/${dimensioning_output_generator_job.number}\">${DIMENSIONING_OUTPUT_GENERATOR_JOB_NAME}/${dimensioning_output_generator_job.number}</a>"]
            if (dimToolGeneratorJobResult != 'SUCCESS') {
                error("Build of ${DIMENSIONING_OUTPUT_GENERATOR_JOB_NAME} job failed with result: ${dimToolGeneratorJobResult}")
            }

            copyArtifacts filter: 'dimToolOutput.properties', fingerprintArtifacts: true, projectName: "dimensioning-tool-output-generator", selector: specific("${dimensioning_output_generator_job.number}")
            readProperties(file: 'dimToolOutput.properties').each {key, value -> env[key] = value }

            echo "DIMTOOL_OUTPUT_REPO_URL=${DIMTOOL_OUTPUT_REPO_URL}"
            echo "DIMTOOL_OUTPUT_REPO=${DIMTOOL_OUTPUT_REPO}"
            echo "DIMTOOL_OUTPUT_NAME=${DIMTOOL_OUTPUT_NAME}"

            cmutils.useValuesFromDimToolOutput("${DIMTOOL_OUTPUT_REPO_URL}", "${DIMTOOL_OUTPUT_REPO}", "${DIMTOOL_OUTPUT_NAME}")
        }
    }
}

void sepInstall() {
    dir('cnint') {
        withCredentials([usernamePassword(credentialsId: 'arm-seli-eeaprodart-token', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
            usernamePassword(credentialsId: 'arm-sero-eeaprodart-token', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
            usernamePassword(credentialsId: 'arm-seli-eeaprodart-token', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
            string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
            file(credentialsId: env.system, variable: 'KUBECONFIG')
        ]) {
            script {
                try {
                    env.SEP_CHART_VERSION = sh(
                        script: '''cat .bob/chart/eric-eea-int-helm-chart/Chart.yaml | grep -A 2 storage-encryption-provider | grep version | awk -F' ' '{print $2}' | tr -d '\\n'
                        ''',
                        returnStdout : true)
                    echo "Installing SEP version: ${env.SEP_CHART_VERSION}"
                    sh './bob/bob k8s-test-sep > sep-install.log'
                }
                catch (err) {
                    echo "Caught: ${err}"
                    error "SEP INSTALL FAILED"
                }
                finally {
                    try {
                        archiveArtifacts artifacts: 'sep-install.log'
                    } catch (err) {
                        echo "Caught: ${err}"
                    }
                }
            }
        }
    }

}
void executeSpotfireDeployment(spotfire_install_job, stageCommentList) {
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        script {
            if ( !params.ADP_APP_STAGING_GERRIT_REFSPEC_FOR_SF_INSTALL?.trim() && params.GIT_BRANCH?.trim() ) {
                env.ADP_APP_STAGING_GERRIT_REFSPEC_FOR_SF_INSTALL = env.GIT_BRANCH
                echo "params.GIT_BRANCH: ${params.GIT_BRANCH} set to env.ADP_APP_STAGING_GERRIT_REFSPEC_FOR_SF_INSTALL"
            }

            def data = readYaml file: 'cnint/spotfire_platform.yml'
            env.SF_ASSET_VERSION = data.spotfire_platform.spotfire_asset.version
            currentBuild.description += "<br>Spotfire_asset version: ${env.SF_ASSET_VERSION}"
            env.SF_STATIC_CONTENT_PATH = data.spotfire_platform.spotfire_static_content.download_url.split('artifactory/')[1]
            env.SF_STATIC_CONTENT_VERSION = data.spotfire_platform.spotfire_static_content.version
            env.STATIC_CONTENT_PKG = env.SF_STATIC_CONTENT_PATH + env.SF_STATIC_CONTENT_VERSION + "/spotfire-static-content-" + env.SF_STATIC_CONTENT_VERSION + ".tar.gz"
            spotfire_install_job = build job: "${SPOTFIRE_ASSET_INSTALL_ASSIGN_LABEL_WRAPPER_JOB_NAME}", parameters: [
                    booleanParam(name: 'INSTALL_SPOTFIRE_PLATFORM', value: true),
                    booleanParam(name: 'DEPLOY_STATIC_CONTENT', value: true),
                    stringParam(name: 'CLUSTER_NAME', value : env.CLUSTER),
                    stringParam(name: 'SF_ASSET_VERSION', value: env.SF_ASSET_VERSION),
                    stringParam(name: 'STATIC_CONTENT_PKG', value: env.STATIC_CONTENT_PKG),
                    stringParam(name: 'CNINT_GERRIT_REFSPEC', value: params.GERRIT_REFSPEC),
                    stringParam(name: 'ADP_APP_STAGING_GERRIT_REFSPEC', value: env.ADP_APP_STAGING_GERRIT_REFSPEC_FOR_SF_INSTALL)
            ], wait: true
            stageCommentList[STAGE_NAME] = ["<a href=\"${env.JENKINS_URL}/job/${SPOTFIRE_ASSET_INSTALL_ASSIGN_LABEL_WRAPPER_JOB_NAME}/${spotfire_install_job.number}\">${SPOTFIRE_ASSET_INSTALL_ASSIGN_LABEL_WRAPPER_JOB_NAME}/${spotfire_install_job.number}</a>"]
            def spotfireInstallJobResult = spotfire_install_job.getResult()
            downloadJenkinsFile("${env.JENKINS_URL}/job/${SPOTFIRE_ASSET_INSTALL_ASSIGN_LABEL_WRAPPER_JOB_NAME}/${spotfire_install_job.number}/artifact/artifact.properties", "spotfire_asset_install_assign_label_wrapper_artifact.properties")
            readProperties(file: 'spotfire_asset_install_assign_label_wrapper_artifact.properties').each {key, value -> env[key] = value }
            if (spotfireInstallJobResult != 'SUCCESS') {
                error("Build of spotfire-asset-install job failed with result: ${spotfireInstallJobResult}")
            }
        }
    }
}

void linkSpotfirePlatformToEEA(link_spotfire_platform_to_eea_job, stageCommentList) {
    script {
        link_spotfire_platform_to_eea_job = build job: "${SPOTFIRE_ASSET_INSTALL_ASSIGN_LABEL_WRAPPER_JOB_NAME}", parameters: [
                booleanParam(name: 'SETUP_TLS_AND_SSO', value: true),
                booleanParam(name: 'ENABLE_CAPACITY_REPORTER', value: true),
                stringParam(name: 'CLUSTER_NAME', value : env.CLUSTER),
                stringParam(name: 'PREVIOUS_JOB_BUILD_ID', value: env.SPOTFIRE_ASSET_INSTALL_NEW_BUILD_NUMBER),
                stringParam(name: 'SF_ASSET_VERSION', value: env.SF_ASSET_VERSION),
                stringParam(name: 'STATIC_CONTENT_PKG', value: env.STATIC_CONTENT_PKG),
                stringParam(name: 'CNINT_GERRIT_REFSPEC', value: params.GERRIT_REFSPEC),
                stringParam(name: 'ADP_APP_STAGING_GERRIT_REFSPEC', value: env.ADP_APP_STAGING_GERRIT_REFSPEC_FOR_SF_INSTALL)
        ], wait: true
        stageCommentList[STAGE_NAME] = ["<a href=\"${env.JENKINS_URL}/job/${SPOTFIRE_ASSET_INSTALL_ASSIGN_LABEL_WRAPPER_JOB_NAME}/${link_spotfire_platform_to_eea_job.number}\">${SPOTFIRE_ASSET_INSTALL_ASSIGN_LABEL_WRAPPER_JOB_NAME}/${link_spotfire_platform_to_eea_job.number}</a>"]
        def link_spotfire_platform_to_eea_job_result = link_spotfire_platform_to_eea_job.getResult()
        if (link_spotfire_platform_to_eea_job_result != 'SUCCESS') {
            error("Build of spotfire-asset-install job failed with result: ${link_spotfire_platform_to_eea_job_result}")
        }
    }
}

void getUtfVersionFromTheMeta() {
    env.DATASET_NAME = cmutils.getDatasetVersion("${WORKSPACE}/project-meta-baseline/eric-eea-ci-meta-helm-chart","values.yaml")
    sh "echo 'DATASET_NAME=${env.DATASET_NAME}' >> artifact.properties"
    env.REPLAY_SPEED = cmutils.getDatasetReplaySpeed("${WORKSPACE}/project-meta-baseline/eric-eea-ci-meta-helm-chart","values.yaml")
    sh "echo 'REPLAY_SPEED=${env.REPLAY_SPEED}' >> artifact.properties"
    env.META_BASELINE_CHART_VERSION = cmutils.getChartVersion("${WORKSPACE}/project-meta-baseline/eric-eea-ci-meta-helm-chart", "Chart.yaml")
    sh "echo 'META_BASELINE_CHART_VERSION=${env.META_BASELINE_CHART_VERSION}' >> artifact.properties"
    env.UTF_CHART_NAME = cmutils.extractSubChartData("eric-eea-utf-application", "name", "${WORKSPACE}/project-meta-baseline/eric-eea-ci-meta-helm-chart","Chart.yaml")
    sh "echo 'UTF_CHART_NAME=${env.UTF_CHART_NAME}' >> artifact.properties"
    env.UTF_CHART_REPO = cmutils.extractSubChartData("eric-eea-utf-application", "repository", "${WORKSPACE}/project-meta-baseline/eric-eea-ci-meta-helm-chart","Chart.yaml")
    sh "echo 'UTF_CHART_REPO=${env.UTF_CHART_REPO}' >> artifact.properties"
    env.UTF_CHART_VERSION = cmutils.extractSubChartData("eric-eea-utf-application", "version", "${WORKSPACE}/project-meta-baseline/eric-eea-ci-meta-helm-chart","Chart.yaml")
    sh "echo 'UTF_CHART_VERSION=${env.UTF_CHART_VERSION}' >> artifact.properties"
}

void utfAndDataLoaderDeploy(eea_product_ci_meta_baseline_loop_utf_and_data_loader_deploy_build) {
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        dir('cnint') {
            script {
                eea_product_ci_meta_baseline_loop_utf_and_data_loader_deploy_build = build job: env.EEA_PRODUCT_CI_META_BASELINE_LOOP_UTF_AND_DATA_LOADER_DEPLOY_JOB_NAME, parameters: [
                    booleanParam(name: 'dry_run', value: false),
                    stringParam(name: 'INT_CHART_NAME', value: "eric-eea-ci-meta-helm-chart"),
                    stringParam(name: 'INT_CHART_REPO', value: "https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm"),
                    stringParam(name: 'CHART_VERSION', value: "${INT_CHART_VERSION}"),
                    stringParam(name: 'RESOURCE', value: "${env.system}")
                ], wait: true
                downloadJenkinsFile("${env.JENKINS_URL}/job/eea-product-ci-meta-baseline-loop-utf-and-data-loader-deploy/${eea_product_ci_meta_baseline_loop_utf_and_data_loader_deploy_build.number}/artifact/meta_baseline.groovy")
                load "meta_baseline.groovy"
                archiveArtifacts artifacts: "meta_baseline.groovy", allowEmptyArchive: true
            }
        }
    }
}

void setDescription(stageResultsInfo) {
    script {
        if( params.SPINNAKER_ID?.trim() ) {
            currentBuild.description += '<br><a href="https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/details/' + params.SPINNAKER_ID + '">Spinnaker URL: ' + params.SPINNAKER_ID + '</a>'
        }
        currentBuild.description += '<br>Installed version: ' + INT_CHART_VERSION
        currentBuild.description += '<br>GIT_BRANCH: ' + env.GIT_BRANCH
        currentBuild.description += '<br>HELM_AND_CMA_VALIDATION_MODE:' + params.HELM_AND_CMA_VALIDATION_MODE

        stageResultsInfo["INT_CHART_VERSION"] = env.INT_CHART_VERSION
        stageResultsInfo["GIT_BRANCH"] = env.GIT_BRANCH
        stageResultsInfo["HELM_AND_CMA_VALIDATION_MODE"] = params.HELM_AND_CMA_VALIDATION_MODE
        stageResultsInfo["DATASET_NAME"] = env.DATASET_NAME
        stageResultsInfo["REPLAY_SPEED"] = env.REPLAY_SPEED
    }

}

void CDR_Install() {
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        dir('cnint') {
            withCredentials([usernamePassword(credentialsId: 'arm-seli-eeaprodart-token', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                usernamePassword(credentialsId: 'arm-sero-eeaprodart-token', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
                usernamePassword(credentialsId: 'arm-seli-eeaprodart-token', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
                file(credentialsId: env.system, variable: 'KUBECONFIG')
            ]){
                script {
                    try {
                        sh './bob/bob k8s-test:download-extract-chart k8s-test:package-helper-chart k8s-test-crd > crd-install.log'
                    }
                    catch (err) {
                        echo "Caught: ${err}"
                        error "CRD INSTALL FAILED"
                    }
                    finally {
                        try {
                            archiveArtifacts artifacts: "crd-install.log", allowEmptyArchive: true
                        } catch (err) {
                            echo "Caught archiveArtifacts ERROR: ${err}"
                        }
                    }
                }
            }
        }
    }
}

void sendBuildStartedMessageToGerrit() {
    script {
        currentBuild.description = ""
        if (params.GERRIT_REFSPEC != "") {
            try {
                env.GERRIT_MSG = "Build Started ${BUILD_URL}"
                sendMessageToGerrit(params.GERRIT_REFSPEC, env.GERRIT_MSG)

                gtokens = params.GERRIT_REFSPEC.split("/")
                if (gtokens.length == 5) {
                    gerrit_link = "<a href=\"https://${GERRIT_HOST}/#/c/" + gtokens[3] + '/' + gtokens[4] + '">gerrit change: '  + gtokens[3] + ',' + gtokens[4] + '</a>'
                    currentBuild.description = gerrit_link
                }
            }
            catch (err) {
                echo "Caught: ${err}"
            }
        }
    }
}

void logLock() {
    echo "Locked cluster: $system"
    env.lock_start = java.time.LocalDateTime.now()
    currentBuild.description += "<br>Locked cluster: $system"
    // In order to use cluster name in POST stages
    sendLockEventToDashboard (transition: "lock", cluster: env.CLUSTER)

    env.START_EPOCH = ((new Date()).getTime()/1000 as double).round()
}
