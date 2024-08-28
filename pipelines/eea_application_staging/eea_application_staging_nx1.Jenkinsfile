@Library('ci_shared_library_eea4') _

import org.jenkinsci.plugins.workflow.support.steps.build.RunWrapper

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import com.ericsson.eea4.ci.GlobalVars
import com.ericsson.eea4.ci.UtfTrigger2
import com.ericsson.eea4.ci.CommonUtils
import com.ericsson.eea4.ci.ClusterLogUtils
import com.ericsson.eea4.ci.EEA_Robot

@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def gitmeta = new GitScm(this, 'EEA/project-meta-baseline')
@Field def vars = new GlobalVars()
@Field def utf = new UtfTrigger2(this)
@Field def cmutils = new CommonUtils(this)
@Field def clusterLogUtilsInstance = new ClusterLogUtils(this)

@Field def CMA_MODE__HELM_VALUES = "true"
@Field def CMA_MODE__HELM_VALUES_AND_CMA_CONF = "false"

@Field def CMA_MODE_IS_HELM = "HELM"
@Field def CMA_MODE_IS_HELM_AND_CMA = "HELM_AND_CMA"

def stageResultsInfo = [:]
def stageCommentList = [:]

def spotfire_install_job
def link_spotfire_platform_to_eea_job
def utf_build

pipeline {
    options {
        buildDiscarder(logRotator(daysToKeepStr: '7', artifactDaysToKeepStr: "7"))
        ansiColor('xterm')
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
        string(name: 'GERRIT_REFSPEC',  description: 'Gerrit Refspec of the integration chart git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'SPINNAKER_TRIGGER_URL', description: 'Spinnaker pipeline triggering url', defaultValue: '')
        string(name: 'lock_start', description: 'Locking start timestamp, will be overwritten', defaultValue: '')
        string(name: 'lock_end', description: 'Locking start timestamp, will be overwritten', defaultValue: '')
        string(name: 'SPINNAKER_ID', description: "The spinnaker execution's id", defaultValue: '')
        string(name: 'PIPELINE_NAME', description: "The spinnaker pipeline name", defaultValue: 'eea-application-staging')
        booleanParam(name: 'SKIP_COLLECT_LOG', description: 'skip the log collection pipeline', defaultValue: false)
        booleanParam(name: 'SKIP_CLEANUP', description: 'skip the cleanup pipeline. Used when SKIP_COLLECT_LOG is false', defaultValue: false)
        string(name: 'CUSTOM_CLUSTER_LABEL', description: 'If CUSTOM_CLUSTER_LABEL is set, we have to set that label at the end of the pipeline executions, and FORCE skip the collect log and cleanup !!!', defaultValue: '')
        string(name: 'CLUSTER_LABEL', defaultValue: "${vars.resourceLabelCommon}", description: "cluster resource label to execute on. Default valuse is 'bob-ci' . Don't specify if CLUSTER_NAME specified")
        string(name: 'CLUSTER_NAME', description: "cluster resource name to execute on. Don't specify if CLUSTER_LABEL specified")
        string(name: 'INT_CHART_NAME_META', description: 'Chart name e.g.: eric-ms-b', defaultValue: 'eric-eea-ci-meta-helm-chart')
        string(name: 'INT_CHART_REPO_META', description: 'Chart repo e.g.: https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/', defaultValue: 'https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/')
        string(name: 'INT_CHART_VERSION_META', description: 'meta-baseline version to install. Format: 1.0.0-1', defaultValue: '')
        string(name: 'DIMTOOL_OUTPUT_REPO_URL', description: "The url of the artifactory", defaultValue: 'https://arm.seli.gic.ericsson.se')
        string(name: 'DIMTOOL_OUTPUT_REPO', description: "Repo of the chart eg. proj-eea-reports-generic-local/dimtool/prod_ci_artifacts/", defaultValue: 'proj-eea-reports-generic-local/dimtool/prod_ci_artifacts/')
        string(name: 'DIMTOOL_OUTPUT_NAME', description: 'Chart name e.g.: eea-application-staging-baseline-prepare-12695/eea4-dimensioning-tool-output.zip', defaultValue: '')
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
        choice(name: 'BUILD_RESULT_WHEN_CMA_HEALTH_CHECK_FAILED', choices: ['FAILURE', 'SUCCESS'], description: 'build result when the CMA health check failed')
        choice(name: 'BUILD_RESULT_WHEN_NELS_CHECK_FAILED', choices: ['FAILURE', 'SUCCESS'], description: 'build result when the Check NELS availability failed')
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
        UTF_PRE_ACTIVITIES_TEST_LOGFILE = "utf_pre_activities_loading.log"
        UTF_PRE_ACTIVITIES_META_FILTER = "@startRefData or @startData"
        UTF_PRE_ACTIVITIES_TEST_TIMEOUT = 2700
        UTF_PRE_ACTIVITIES_CHECK_TEST_EXECUTION_ID = 1112 + "${env.BUILD_NUMBER}"
        UTF_PRE_ACTIVITIES_CHECK_META_FILTER = "@startDataCheck"
        UTF_PRE_ACTIVITIES_CHECK_TEST_TIMEOUT = 1800
        UTF_POST_ACTIVITIES_TEST_NAME = "UTF Post-activities"
        UTF_POST_ACTIVITIES_TEST_LOGFILE = "utf_post_activities_loading.log"
        UTF_POST_ACTIVITIESTEST_EXECUTION_ID = 9999 + "${env.BUILD_NUMBER}"
        UTF_POST_ACTIVITIESMETA_FILTER = "@stopData"
        UTF_POST_ACTIVITIESTEST_TIMEOUT = 1800
        UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_NAME = "Decisive Nx1 Staging UTF Cucumber Tests"
        UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_EXECUTION_ID = 101 + "${env.BUILD_NUMBER}"
        UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_META_FILTER = "@decisive and @nx1 and @staging and not @onlyUpgrade and not @tc_under_development"
        UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER = "report_decisive_and_nx1_and_staging_and_not_onlyUpgrade_and_not_tc_under_development"
        UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_TIMEOUT = "1800"
        UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_LOGFILE = "utf_decisive_nx1_staging_cucumber.log"
        SEP_CHART_NAME = "eric-cs-storage-encryption-provider"
        SEP_CHART_REPO = "https://arm.sero.gic.ericsson.se/artifactory/proj-adp-rs-storage-encr-released-helm"
        LINK_SPOTFIRE_PLATFORM_TO_EEA_STAGE_NAME = "Link Spotfire platform to EEA"
        EXECUTE_SPOTFIRE_DEPLOYMENT_STAGE_NAME = "Execute Spotfire deployment"
        SPOTFIRE_ASSET_INSTALL_ASSIGN_LABEL_WRAPPER_JOB_NAME = "spotfire-asset-install-assign-label-wrapper"
        SPOTFIRE_SERVER = "spotfire"
        RUN_HEALTH_CHECK_AFTER_INSTALL_STAGE_NAME = "Run health check after install"
        RUN_HEALTH_CHECK_AFTER_CM_ANALYTICS_CONFIG_LOAD_STAGE_NAME = "Run health check after CM-Analytics config load"
        RUN_CMA_HEALTH_CHECK_AFTER_CM_ANALYTICS_CONFIG_LOAD_STAGE_NAME = "Run CMA health check after CM-Analytics config load"
        RUN_CHECKSPOTFIREPLATFORM_HEALTH_CHECK = "Run CheckSpotfirePlatform health check"
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

        stage('HELM_AND_CMA_VALIDATION_MODE Param check'){
            steps {
                script {
                    if ( params.HELM_AND_CMA_VALIDATION_MODE != CMA_MODE__HELM_VALUES && params.HELM_AND_CMA_VALIDATION_MODE != CMA_MODE__HELM_VALUES_AND_CMA_CONF && params.HELM_AND_CMA_VALIDATION_MODE != CMA_MODE_IS_HELM && params.HELM_AND_CMA_VALIDATION_MODE != CMA_MODE_IS_HELM_AND_CMA ) {

                        error "HELM_AND_CMA_VALIDATION_MODE \"${params.HELM_AND_CMA_VALIDATION_MODE}\" validation error. Valid options:  CMA_MODE__HELM_VALUES:\"${CMA_MODE__HELM_VALUES}\" or \"${CMA_MODE_IS_HELM}\" CMA_MODE__HELM_VALUES_AND_CMA_CONF: \"${CMA_MODE__HELM_VALUES_AND_CMA_CONF}\" or \"${CMA_MODE_IS_HELM_AND_CMA}\""
                    }
                }
            }
        }

        stage('Gerrit message') {
            when {
                expression {params.GERRIT_REFSPEC?.trim()}
            }
            steps {
                script {
                    env.GERRIT_MSG = "Build Started ${BUILD_URL}"
                    sendMessageToGerrit(params.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }

        stage('Checkout') {
            steps {
                script {
                    gitcnint.checkout('master', '')
                }
            }
        }

        stage('Ruleset and config change checkout') {
            when {
                expression {params.GERRIT_REFSPEC?.trim()}
            }
            steps {
                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                    script {
                        gitcnint.fetchAndCherryPick('EEA/cnint', "${params.GERRIT_REFSPEC}")
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

        stage('Prepare') {
            steps {
                checkoutGitSubmodules()
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

        stage('Checkout technicals') {
            steps {
                checkoutTechnicals()
            }
        }

        stage('Checkout project-meta-baseline') {
            steps {
                checkoutMeta()
            }
        }

        stage('Init Description') {
            steps {
                initCurrentBuildDescription()
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
                                script {
                                    env.CLUSTER = env.system
                                    logLock()
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
                                    sh './bob/bob -r ruleset2.0.yaml init'
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
                                CRD_Install(stageCommentList)
                            }
                        }

                        stage('Parallel install prerequisite for EEA4') {
                            parallel {
                                stage('utf and data loader deploy-deploy') {
                                    steps{
                                        script {
                                            utf_build = build job: "eea-product-ci-meta-baseline-loop-utf-and-data-loader-deploy",parameters: [
                                                    booleanParam(name: 'dry_run', value: false),
                                                    stringParam(name: 'INT_CHART_NAME', value : "${env.INT_CHART_NAME_META}"),
                                                    stringParam(name: 'INT_CHART_REPO', value : "${env.INT_CHART_REPO_META}"),
                                                    stringParam(name: 'INT_CHART_VERSION', value: "${env.INT_CHART_VERSION_META}"),
                                                    stringParam(name: 'RESOURCE', value : "${env.system}")], wait: true
                                            downloadJenkinsFile("${env.JENKINS_URL}/job/eea-product-ci-meta-baseline-loop-utf-and-data-loader-deploy/${utf_build.number}/artifact/meta_baseline.groovy")
                                            load "${WORKSPACE}/meta_baseline.groovy"
                                        }
                                    }
                                    post {
                                        always {
                                            script {
                                    stageCommentList[STAGE_NAME] = ["<a href=\"${env.JENKINS_URL}/job/eea-product-ci-meta-baseline-loop-utf-and-data-loader-deploy/${utf_build.number}\">eea-product-ci-meta-baseline-loop-utf-and-data-loader-deploy/${utf_build.number}</a>"]
                                            }
                                        }
                                    }
                                }
                                stage("Execute Spotfire deployment") { //EXECUTE_SPOTFIRE_DEPLOYMENT_STAGE_NAME
                                    steps {
                                        executeSpotfireDeployment(spotfire_install_job, stageCommentList)
                                    }
                                }
                                stage('SEP Install') {
                                    steps {
                                        SEP_Install(stageCommentList)
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

                        stage('Download and apply dimtool output file') {
                            steps {
                                script {
                                    cmutils.useValuesFromDimToolOutput("${params.DIMTOOL_OUTPUT_REPO_URL}", "${params.DIMTOOL_OUTPUT_REPO}", "${params.DIMTOOL_OUTPUT_NAME}" )
                                }
                            }
                        }

                        stage('K8S Install Test') {
                            steps {
                                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                                    script {
                                        Map args = [
                                            "helmTimeout":   "4200",
                                            "clusterName":   "${env.system}",
                                            "bobRulesList":  ["./bob/bob -r ruleset2.0.yaml init-mxe", "./bob/bob -r ruleset2.0.yaml init-eric-eea-analysis-system-overview-install", "./bob/bob -r ruleset2.0.yaml verify-values-files > k8s-test-verify-values.log", "./bob/bob -r ruleset2.0.yaml k8s-test-splitted-values > k8s-test.log"]

                                        ]
                                        cmutils.k8sInstallTest(args)

                                    }
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
                                        stageCommentList[STAGE_NAME] = [" <a href=\"${env.BUILD_URL}/artifact/k8s-test.log\">k8s-test.log</a>"]
                                        stageCommentList[STAGE_NAME] += ["<a href=\"${env.BUILD_URL}/artifact/k8s-test-verify-values.log\">k8s-test-verify-values.log</a>"]
                                    }
                                    archiveArtifacts artifacts: "install-configvalues.tar.gz", allowEmptyArchive: true
                                    archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                                }
                            }
                        }

                        stage("Link Spotfire platform to EEA") { //LINK_SPOTFIRE_PLATFORM_TO_EEA_STAGE_NAME
                            steps {
                                linkSpotfirePlatformToEEA(link_spotfire_platform_to_eea_job, stageCommentList)
                            }
                        }

                        stage('Run CheckSpotfirePlatform health check') { // RUN_CHECKSPOTFIREPLATFORM_HEALTH_CHECK
                            steps {
                                script {
                                    clusterLogUtilsInstance.runHealthCheck("${vars.waitForPodsAfterInstall}", "${STAGE_NAME}", clusterCredentialID=env.CLUSTER, eeaHealthcheckCheckClasses='CheckSpotfirePlatform',  k8s_namespace='spotfire-platform')
                                }
                            }
                            post {
                                always {
                                    script {
                                    stageCommentList[STAGE_NAME] = ["<a href=\"${env.BUILD_URL}/artifact/check-pods-state-with-wait__stage_"+RUN_CHECKSPOTFIREPLATFORM_HEALTH_CHECK.replaceAll(' ', '_')+".log\">"+RUN_CHECKSPOTFIREPLATFORM_HEALTH_CHECK.replaceAll(' ', '_')+".log</a>"]
                                    }
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

                        stage("Run health check after install") { //RUN_HEALTH_CHECK_AFTER_INSTALL_STAGE_NAME
                            steps {
                                script {
                                    clusterLogUtilsInstance.runHealthCheck("${vars.waitForPodsAfterInstall}", "${STAGE_NAME}")
                                }
                            }
                            post {
                                always {
                                    script {
                                        stageCommentList[STAGE_NAME] = ["<a href=\"${env.BUILD_URL}/artifact/check-pods-state-with-wait__stage_"+RUN_HEALTH_CHECK_AFTER_INSTALL_STAGE_NAME.replaceAll(' ', '_')+".log\">"+RUN_HEALTH_CHECK_AFTER_INSTALL_STAGE_NAME.replaceAll(' ', '_')+".log</a>"]
                                    }
                                }
                            }
                        }

                        stage('Load config json to CM-Analytics') {
                            when {
                                expression { params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE__HELM_VALUES_AND_CMA_CONF || params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE_IS_HELM_AND_CMA }
                            }
                            steps {
                                script {
                                    withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                                        usernamePassword(credentialsId: 'ECEAART_SEROGIC_API_KEY', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
                                        file(credentialsId: env.system, variable: 'KUBECONFIG')
                                    ]){
                                        cmutils.removeAggregationsFromConfigurationsByNamePattern()
                                        withEnv(["CMA_EXT_CONFIG_FILE=${vars.cma_correlator_content_version_path}", "CMA_EXT_CONFIG_ENDPOINT=${vars.cma_correlator_content_version_endpoint}"]) {
                                            sh './bob/bob -r ruleset2.0.yaml load-cm-analytics-config-cubes-into-eea > load_cm_analytics_config_cubes_into_correlator_content_version.log'
                                        }
                                        // WA: Temporary sleeping
                                        sleep(time: 5, unit: 'MINUTES' )
                                        withEnv(["CMA_EXT_CONFIG_FILE=${vars.cma_config_path}"]) {
                                            sh './bob/bob -r ruleset2.0.yaml load-cm-analytics-config-cubes-into-eea > load_cm_analytics_config_cubes_into_eea_all_in_one.log'
                                        }
                                    }
                                }
                            }
                            post {
                                always {
                                    script {
                                        archiveArtifacts artifacts: "load_cm_analytics_config_cubes_into_correlator_content_version.log", allowEmptyArchive: true
                                        archiveArtifacts artifacts: "load_cm_analytics_config_cubes_into_eea_all_in_one.log", allowEmptyArchive: true
                                        stageCommentList[STAGE_NAME] = ["<a href=\"${env.BUILD_URL}/artifact/load_cm_analytics_config_cubes_into_correlator_content_version.log\">load_cm_analytics_config_cubes_into_correlator_content_version.log</a>"]
                                        stageCommentList[STAGE_NAME] += ["<a href=\"${env.BUILD_URL}/artifact/load_cm_analytics_config_cubes_into_eea_all_in_one.log\">load_cm_analytics_config_cubes_into_eea_all_in_one.log</a>"]
                                    }
                                }
                            }
                        }

                        stage("Run health check after CM-Analytics config load") { //RUN_HEALTH_CHECK_AFTER_CM_ANALYTICS_CONFIG_LOAD_STAGE_NAME
                            when {
                                expression { params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE__HELM_VALUES_AND_CMA_CONF || params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE_IS_HELM_AND_CMA}
                            }
                            steps {
                                script {
                                    clusterLogUtilsInstance.runHealthCheck("${vars.waitForPodsAfterInstall}", "${STAGE_NAME}")
                                }
                            }
                            post {
                                always {
                                    script {
                                        stageCommentList[STAGE_NAME] = ["<a href=\"${env.BUILD_URL}/artifact/check-pods-state-with-wait__stage_"+ RUN_HEALTH_CHECK_AFTER_CM_ANALYTICS_CONFIG_LOAD_STAGE_NAME.replaceAll(' ', '_')+".log\">"+ RUN_HEALTH_CHECK_AFTER_CM_ANALYTICS_CONFIG_LOAD_STAGE_NAME.replaceAll(' ', '_')+".log</a>"]
                                    }
                                }
                            }
                        }

                        stage("Run CMA health check after CM-Analytics config load") { //RUN_CMA_HEALTH_CHECK_AFTER_CM_ANALYTICS_CONFIG_LOAD_STAGE_NAME
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
                            post {
                                always {
                                    script {
                                        stageCommentList[STAGE_NAME] = ["<a href=\"${env.BUILD_URL}/artifact/check-pods-state-with-wait__stage_"+RUN_CMA_HEALTH_CHECK_AFTER_CM_ANALYTICS_CONFIG_LOAD_STAGE_NAME.replaceAll(' ', '_')+".log\">"+RUN_CMA_HEALTH_CHECK_AFTER_CM_ANALYTICS_CONFIG_LOAD_STAGE_NAME.replaceAll(' ', '_')+".log</a>"]
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
                                    stageCommentList[pre_activities.name] = [" <a href=\"${env.BUILD_URL}/artifact/${pre_activities.logfile}\">${pre_activities.logfile}</a>"]
                                }
                            }
                            post {
                                always {
                                    script {
                                        clusterLogUtilsInstance.getResourceCapacity(env.CLUSTER)
                                        archiveArtifacts artifacts: "stage_${UTF_PRE_ACTIVITIES_TEST_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                                    }
                                }
                            }
                        }

                        stage('Execute Cucumber UTF Test') {
                            steps {
                                script {
                                    def cucumber_tests =  [[name: "${UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_NAME}", build_result: 'FAILURE', stage_result: 'FAILURE', exec_id: "101", metafilter: "${UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_META_FILTER}", timeout: "${UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_TIMEOUT}", logfile: "${UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_LOGFILE}", report_folder: "${UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER}"],]
                                    utf.execUtfTests(cucumber_tests)
                                    utf.generateUtfTestReportLinks(cucumber_tests)
                                    utf.generateSumReportLinks(cucumber_tests)
                                    cucumber_tests.each { test ->
                                        stageCommentList[test.name] = [" <a href=\"${env.BUILD_URL}/artifact/${test.logfile}\">${test.logfile}</a>"]
                                    }
                                }
                            }
                            post {
                                always {
                                    script {
                                        archiveArtifacts artifacts: "stage_${UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                                    }
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
                                        stageCommentList[STAGE_NAME] = [" <a href=\"${env.BUILD_URL}/artifact/decisive-eea-robot.log\">decisive-eea-robot.log</a>"]
                                    }
                                }
                            }
                        }

                        stage('Execute UTF Post activities') {
                            steps {
                                script {
                                    def utf_post_activities = [[name: "${UTF_POST_ACTIVITIES_TEST_NAME}", build_result: 'SUCCESS', stage_result: 'FAILURE', exec_id: "${UTF_POST_ACTIVITIESTEST_EXECUTION_ID}", metafilter: "${env.UTF_POST_ACTIVITIESMETA_FILTER}", timeout: "${UTF_POST_ACTIVITIESTEST_TIMEOUT}", logfile: "${UTF_POST_ACTIVITIES_TEST_LOGFILE}"],]
                                    utf.execUtfTests(utf_post_activities)
                                    utf_post_activities.each { test ->
                                        stageCommentList[test.name] = [" <a href=\"${env.BUILD_URL}/artifact/${test.logfile}\">${test.logfile}</a>"]
                                    }
                                }
                            }
                        }
                    }
                    post {
                        always {
                            script {
                                archiveArtifacts artifacts: "stage_${UTF_POST_ACTIVITIES_TEST_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                                if (!"${env.EEA_NS_CHECK_FAILED}".toBoolean()) {
                                    def labelmanualchanged = checkLockableResourceLabelManualChange(env.CLUSTER)
                                    if ( params.CUSTOM_CLUSTER_LABEL?.trim() ) {
                                        try {
                                            setLockableResourceLabels(env.CLUSTER, params.CUSTOM_CLUSTER_LABEL)
                                        }
                                        catch (err) {
                                            echo "Caught setLockableResourceLabels ERROR: ${err}"
                                        }
                                    } else if ( ! params.SKIP_COLLECT_LOG ) {
                                        try {
                                            prepareClusterForLogCollection("${env.CLUSTER}", "${env.JOB_NAME}", "${env.BUILD_NUMBER}", labelmanualchanged)
                                        }
                                        catch (err) {
                                            echo "Caught prepareClusterForLogCollection ERROR: ${err}"
                                        }
                                    }
                                }

                                // Save the lock times
                                env.lock_end = java.time.LocalDateTime.now()
                                sh "{ (echo '$system,${env.lock_start},${env.lock_end},eea-application-staging-nx1' >> /data/nfs/productci/cluster_lock.csv) } || echo '/data/nfs/productci/cluster_lock.csv is unreachable'"

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
                }
            }
            post {
                always {
                    postStageAfterResourceLock()
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
        failure {
            script {
                if(params.GERRIT_REFSPEC != '') {
                    env.GERRIT_MSG = "Build Failed ${BUILD_URL}: FAILURE"
                    sendMessageToGerrit(params.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }
        success {
            script {
                if(params.GERRIT_REFSPEC != '') {
                    env.GERRIT_MSG = "Build Successful ${BUILD_URL}: SUCCESS"
                    sendMessageToGerrit(params.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }
        always {
            script {
                if (params.HELM_AND_CMA_VALIDATION_MODE) {
                        stageResultsInfo["HELM_AND_CMA_VALIDATION_MODE"] = params.HELM_AND_CMA_VALIDATION_MODE
                        stageResultsInfo["Options meaning:"] = "\"true\": use helm values, cma is diabled<br>"
                        stageResultsInfo["Options meaning:"] += "\"false\": use helm values and load CMA configuration"
                }
                cmutils.generateStageResultsHtml(stageCommentList,stageResultsInfo)
            }
        }
        cleanup {
            cleanWs()
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

void postStageAfterResourceLock() {
    script {
        sendLockEventToDashboard (transition: "release", cluster: env.CLUSTER)
        if (!"${env.EEA_NS_CHECK_FAILED}".toBoolean()) {
            if( params.CUSTOM_CLUSTER_LABEL?.trim()  ) {
                echo "Cluster has a new label ${params.CUSTOM_CLUSTER_LABEL}"
            } else if ( ! params.SKIP_COLLECT_LOG ) {
                if (!env.CLUSTER) {
                        echo "There was no cluster lock, COLLECT_LOG skipped"
                } else {
                    try {
                        echo "Execute cluster-logcollector job ... \n - cluster: ${env.CLUSTER}"
                        build job: "cluster-logcollector", parameters: [
                            stringParam(name: "CLUSTER_NAME", value: env.CLUSTER),
                            stringParam(name: 'SERVICE_NAME', value: params.CHART_NAME),
                            booleanParam(name: "CLUSTER_CLEANUP", value: !env.SKIP_CLEANUP.toBoolean()),
                            stringParam(name: 'LAST_LABEL_SET', value: env.LASTLABEL),
                            stringParam(name: 'PIPELINE_NAME', value: params.PIPELINE_NAME),
                            stringParam(name: 'SPINNAKER_ID', value: params.SPINNAKER_ID),
                            stringParam(name: 'SPINNAKER_TRIGGER_URL', value: params.SPINNAKER_TRIGGER_URL)
                            ], wait: true
                    }
                    catch (err) {
                        echo "Caught cluster-logcollector ERROR: ${err}"
                    }
                }
            } else if ( params.SKIP_COLLECT_LOG && !params.SKIP_CLEANUP ) {
                if (!env.CLUSTER_NAME) {
                        echo "There was no cluster lock, COLLECT_LOG skipped"
                } else {
                    try {
                        echo "Execute cluster-cleanup job ... \n - cluster: ${env.CLUSTER}"
                        build job: "cluster-cleanup", parameters: [
                            stringParam(name: "CLUSTER_NAME", value: env.CLUSTER),
                            stringParam(name: 'CNINT_GERRIT_REFSPEC', value: params.GERRIT_REFSPEC),
                            stringParam(name: "DESIRED_CLUSTER_LABEL", value: "${vars.resourceLabelCommon}"),
                            stringParam(name: "LAST_LABEL_SET", value: env.LASTLABEL),
                            stringParam(name: 'PIPELINE_NAME', value: params.PIPELINE_NAME),
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

void initCurrentBuildDescription() {
    script {
        // Generate log url link name and log directory names
        def name = CHART_NAME + ': ' + CHART_VERSION
        def gerrit_link = null
        if (params.GERRIT_REFSPEC != '') {
            name = "manual change"
            gerrit_link = getGerritLink(params.GERRIT_REFSPEC)
        }
        // Setup build info
        currentBuild.description = name
        if (gerrit_link) {
            currentBuild.description += '<br>' + gerrit_link
        }
        if ( params.SPINNAKER_ID != '' ) {
            currentBuild.description += '<br>Spinnaker URL: <a href="https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/details/' + params.SPINNAKER_ID + '">' + params.SPINNAKER_ID + '</a>'
        }
        currentBuild.description += "<br>HELM_AND_CMA_VALIDATION_MODE: " + params.HELM_AND_CMA_VALIDATION_MODE
    }
}

void checkoutTechnicals() {
    dir('adp-app-staging') {
        withCredentials([usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GIT_USER', passwordVariable: 'PASSWORD' )]) {
            script {
                gitadp.archiveDir('EEA/adp-app-staging', 'HEAD:technicals/')
                gitadp.archiveDir('EEA/adp-app-staging', 'HEAD:rulesets/')
                sh 'ln -s "${WORKSPACE}/adp-app-staging/shellscripts" "${WORKSPACE}/shellscripts"'
            }
            sh (
                script: """
                cp  ${WORKSPACE}/adp-app-staging/pythonscripts/k8s_cleanup.py ${WORKSPACE}/adp-app-staging/
                """
            )
        }
    }
}

void logLock() {
    echo "Locked cluster: $system"
    env.lock_start = java.time.LocalDateTime.now()
    env.START_EPOCH = ((new Date()).getTime()/1000 as double).round()
    currentBuild.description += "<br>Locked cluster: $system"

    // To use cluster name in POST stages
    sendLockEventToDashboard (transition : "lock", cluster: env.CLUSTER)
}

void CRD_Install(stageCommentList) {
    withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
        usernamePassword(credentialsId: 'ECEAART_SEROGIC_API_KEY', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
        usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
        file(credentialsId: env.system, variable: 'KUBECONFIG')
    ]){
        script {
            try {
                sh "echo 'CLUSTER='${system} > artifact.properties"
                sh './bob/bob -r ruleset2.0.yaml k8s-test:download-extract-chart k8s-test:package-helper-chart k8s-test-crd > crd-install.log'
            }
            catch (err) {
                echo "Caught: ${err}"
                error "CRD INSTALL FAILED"
            } finally {
                archiveArtifacts artifacts: "crd-install.log", allowEmptyArchive: true
                archiveArtifacts artifacts: 'artifact.properties', allowEmptyArchive: true
                stageCommentList[STAGE_NAME] = [" <a href=\"${env.BUILD_URL}/artifact/crd-install.log\">crd-install.log</a>"]
            }
        }
    }
}

void checkoutMeta() {
    script {
        echo "params.INT_CHART_VERSION_META: \"${params.INT_CHART_VERSION_META}\""
        if (params.INT_CHART_VERSION_META.trim()) {
            gitmeta.checkoutRefSpec("${params.INT_CHART_VERSION_META}", "FETCH_HEAD", 'project-meta-baseline')
        } else {
            echo "params.INT_CHART_VERSION_META is empty, therefore project-meta-baseline master will be checked out"
            gitmeta.checkout('master', 'project-meta-baseline')
        }
        dir('project-meta-baseline') {
            checkoutGitSubmodules()
        }
    }
}

void SEP_Install(stageCommentList) {
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
                    ''', returnStdout : true)
                echo "Installing SEP version: ${env.SEP_CHART_VERSION}"
                sh './bob/bob -r ruleset2.0.yaml k8s-test-sep > sep-install.log'
            }
            catch (err) {
                echo "Caught: ${err}"
                error "SEP INSTALL FAILED"
            }
            finally {
                archiveArtifacts artifacts: 'sep-install.log', allowEmptyArchive: true
                stageCommentList[STAGE_NAME] = [" <a href=\"${env.BUILD_URL}/artifact/sep-install.log\">sep-install.log</a>"]
            }
        }
    }
}

void executeSpotfireDeployment(spotfire_install_job, stageCommentList) {
    script {
        spotfire_install_job = build job: "${SPOTFIRE_ASSET_INSTALL_ASSIGN_LABEL_WRAPPER_JOB_NAME}", parameters: [
                booleanParam(name: 'INSTALL_SPOTFIRE_PLATFORM', value: true),
                booleanParam(name: 'DEPLOY_STATIC_CONTENT', value: true),
                stringParam(name: 'CLUSTER_NAME', value : env.CLUSTER),
                stringParam(name: 'CNINT_GERRIT_REFSPEC', value: params.GERRIT_REFSPEC)
        ], wait: true
        stageCommentList[STAGE_NAME] = [" <a href=\"${env.JENKINS_URL}/job/${SPOTFIRE_ASSET_INSTALL_ASSIGN_LABEL_WRAPPER_JOB_NAME}/${spotfire_install_job.number}\">${SPOTFIRE_ASSET_INSTALL_ASSIGN_LABEL_WRAPPER_JOB_NAME}/${spotfire_install_job.number}</a>"]
        def spotfireInstallJobResult = spotfire_install_job.getResult()
        downloadJenkinsFile("${env.JENKINS_URL}/job/${SPOTFIRE_ASSET_INSTALL_ASSIGN_LABEL_WRAPPER_JOB_NAME}/${spotfire_install_job.number}/artifact/artifact.properties", "spotfire_asset_install_assign_label_wrapper_artifact.properties")
        readProperties(file: 'spotfire_asset_install_assign_label_wrapper_artifact.properties').each {key, value -> env[key] = value }
        if (spotfireInstallJobResult != 'SUCCESS') {
            error("Build of spotfire-asset-install job failed with result: ${spotfireInstallJobResult}")
        }
    }
}

void linkSpotfirePlatformToEEA(link_spotfire_platform_to_eea_job, stageCommentList) {
    script {
        link_spotfire_platform_to_eea_job = build job: "${SPOTFIRE_ASSET_INSTALL_ASSIGN_LABEL_WRAPPER_JOB_NAME}", parameters: [
                booleanParam(name: 'SETUP_TLS_AND_SSO', value: true),
                booleanParam(name: 'ENABLE_CAPACITY_REPORTER', value: true),
                stringParam(name: 'CLUSTER_NAME', value : env.CLUSTER),
                stringParam(name: 'PREVIOUS_JOB_BUILD_ID', value: env.SPOTFIRE_ASSET_INSTALL_NEW_BUILD_NUMBER)
        ], wait: true
        stageCommentList[STAGE_NAME] = ["<a href=\"${env.JENKINS_URL}/job/${SPOTFIRE_ASSET_INSTALL_ASSIGN_LABEL_WRAPPER_JOB_NAME}/${link_spotfire_platform_to_eea_job.number}\">${SPOTFIRE_ASSET_INSTALL_ASSIGN_LABEL_WRAPPER_JOB_NAME}/${link_spotfire_platform_to_eea_job.number}</a>"]
        def link_spotfire_platform_to_eea_job_result = link_spotfire_platform_to_eea_job.getResult()
        if (link_spotfire_platform_to_eea_job_result != 'SUCCESS') {
            error("Build of spotfire-asset-install job failed with result: ${link_spotfire_platform_to_eea_job_result}")
        }
    }
}
