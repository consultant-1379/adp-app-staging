@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import com.ericsson.eea4.ci.GlobalVars
import com.ericsson.eea4.ci.UtfTrigger2
import com.ericsson.eea4.ci.CommonUtils
import com.ericsson.eea4.ci.ClusterLogUtils
import com.ericsson.eea4.ci.Artifactory
import com.ericsson.eea4.ci.EEA_Robot

@Field def gitmeta = new GitScm(this, 'EEA/project-meta-baseline')
@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def vars = new GlobalVars()
@Field def utf = new UtfTrigger2(this)
@Field def cmutils = new CommonUtils(this)
@Field def clusterLogUtilsInstance = new ClusterLogUtils(this)
@Field def arm = new Artifactory(this, "https://arm.seli.gic.ericsson.se/",  "API_TOKEN_EEA")

def k8s_master //k8s master node name

@Field def CMA_MODE__HELM_VALUES = "true"
@Field def CMA_MODE__HELM_VALUES_AND_CMA_CONF = "false"
def stageResultsInfo = [:]
def stageCommentList = [:]

@Field def CMA_MODE_IS_HELM = "HELM"
@Field def CMA_MODE_IS_HELM_AND_CMA = "HELM_AND_CMA"

def spotfire_install_job
def link_spotfire_platform_to_eea_job

pipeline {
    agent {
        node {
            label 'productci'
        }
    }
    options {
        ansiColor('xterm')
        buildDiscarder(logRotator(daysToKeepStr: '7', artifactDaysToKeepStr: '3'))
    }
    parameters {
        string(name: 'CHART_NAME', description: 'Chart name e.g.: eric-ms-b', defaultValue: '')
        string(name: 'CHART_REPO', description: 'Chart repo e.g.: https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm', defaultValue: '')
        string(name: 'CHART_VERSION', description: 'Chart version e.g.: 1.0.0-1', defaultValue: '')
        string(name: 'INT_CHART_NAME', description: 'Chart name e.g.: eric-ms-b', defaultValue: '')
        string(name: 'INT_CHART_REPO', description: 'Chart repo e.g.: https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm', defaultValue: '')
        string(name: 'INT_CHART_VERSION', description: 'Chart version e.g.: 1.0.0-1', defaultValue: '')
        string(name: 'GERRIT_REFSPEC',  description: 'Gerrit Refspect of the project-meta-baseline git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'CNINT_GERRIT_REFSPEC',  description: 'Gerrit Refspect of the cnint git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'SPINNAKER_TRIGGER_URL', description: 'Spinnaker pipeline triggering url', defaultValue: '')
        string(name: 'lock_start', description: 'Locking start timestamp, will be overwritten', defaultValue: '')
        string(name: 'lock_end', description: 'Locking start timestamp, will be overwritten', defaultValue: '')
        string(name: 'SPINNAKER_ID', description: "The spinnaker execution's id", defaultValue: '')
        string(name: 'PIPELINE_NAME', description: "The spinnaker pipeline name", defaultValue: 'eea-product-ci-meta-baseline-loop')
        booleanParam(name: 'SKIP_COLLECT_LOG', description: 'skip the log collection pipeline', defaultValue: false)
        booleanParam(name: 'SKIP_CLEANUP', description: 'skip the cleanup pipeline. Used when SKIP_COLLECT_LOG is false', defaultValue: false)
        string(name: 'CUSTOM_CLUSTER_LABEL', description: 'If CUSTOM_CLUSTER_LABEL is set, we have to set that label at the end of the pipeline executions, and FORCE skip the collect log and cleanup !!!', defaultValue: '')
        string(name: 'DIMTOOL_OUTPUT_REPO_URL', description: "The url of the artifactory", defaultValue: 'https://arm.seli.gic.ericsson.se')
        string(name: 'DIMTOOL_OUTPUT_REPO', description: "Repo of the chart eg. proj-eea-reports-generic-local/dimtool/prod_ci_artifacts/", defaultValue: 'proj-eea-reports-generic-local/dimtool/prod_ci_artifacts/')
        string(name: 'DIMTOOL_OUTPUT_NAME', description: 'Chart name e.g.: eea-application-staging-baseline-prepare-12695/eea4-dimensioning-tool-output.zip', defaultValue: '')
        string(name: 'CLUSTER_LABEL', defaultValue: "${vars.resourceLabelCommon}", description: "cluster resource label to execute on. Default valuse is 'bob-ci' . Don't specify if CLUSTER_NAME specified")
        string(name: 'CLUSTER_NAME', description: "cluster resource name to execute on. Don't specify if CLUSTER_LABEL specified")
        string(name: 'HELM_AND_CMA_VALIDATION_MODE',
        description: """
        Use HELM values or HELM values and CMA configurations. valid options:
<table>
  <tr>
    <td>""</td>
    <td>legacy mode</td>
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
        choice(name: 'BUILD_RESULT_WHEN_CMA_HEALTH_CHECK_FAILED', choices: ['SUCCESS','FAILURE'], description: 'build result when the CMA health check failed')
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
        UTF_TEST_TIMEOUT = 1800
        UTF_PRE_ACTIVITIES_TEST_NAME = "UTF Pre-activities"
        UTF_PRE_ACTIVITIES_TEST_LOGFILE = "utf_pre_activities_loading.log"
        UTF_PRE_ACTIVITIES_TEST_EXECUTION_ID = 1111 + "${env.BUILD_NUMBER}"
        UTF_PRE_ACTIVITIES_META_FILTER = "@startRefData or @startData"
        UTF_PRE_ACTIVITIES_TEST_TIMEOUT = 2700
        UTF_POST_ACTIVITIES_TEST_NAME = "UTF Post-activities"
        UTF_POST_ACTIVITIES_TEST_LOGFILE = "utf_post_activities_loading.log"
        UTF_POST_ACTIVITIES_TEST_EXECUTION_ID = 9999 + "${env.BUILD_NUMBER}"
        UTF_POST_ACTIVITIES_META_FILTER = "@stopData"
        SEP_CHART_NAME = "eric-cs-storage-encryption-provider"
        SEP_CHART_REPO = "https://arm.sero.gic.ericsson.se/artifactory/proj-adp-rs-storage-encr-released-helm"
        DIMTOOL_CHART_PATH = ".bob/chart/eric-eea-int-helm-chart"
        UTF_CREATE_AND_EXPORT_BRO_BACKUP_TEST_NAME = "Create and export BRO backup"
        UTF_CREATE_AND_EXPORT_BRO_BACKUP_TEST_EXECUTION_ID = 2000 + "${env.BUILD_NUMBER}"
        UTF_CREATE_AND_EXPORT_BRO_BACKUP_TEST_META_FILTER = "@broCreate and export backup"
        UTF_CREATE_AND_EXPORT_BRO_BACKUP_TEST_LOGFILE = "utf_create_export_bro.log"

        UTF_BRO_VALIDATE_SYSTEM_WORKS_AS_EXPECTED_BEFORE_ROLL_BACK_TEST_NAME = "BRO Validate system works as expected: before roll back"
        UTF_BRO_VALIDATE_SYSTEM_WORKS_AS_EXPECTED_BEFORE_ROLL_BACK_TEST_EXECUTION_ID = 2001 + "${env.BUILD_NUMBER}"
        UTF_BRO_VALIDATE_SYSTEM_WORKS_AS_EXPECTED_BEFORE_ROLL_BACK_TEST_META_FILTER = "@broValidateBefore system works as expected before rollback"
        UTF_BRO_VALIDATE_SYSTEM_WORKS_AS_EXPECTED_BEFORE_ROLL_BACK_TEST_LOGFILE = "bro_validate_system_before_rollback.log"

        UTF_NONDECISIVE_BRO_CHANGE_IAM_CONFIG_NAME = "NonDecisive BRO Change IAM config"
        UTF_NONDECISIVE_BRO_CHANGE_IAM_CONFIG_EXECUTION_ID = 2002 + "${env.BUILD_NUMBER}"
        UTF_NONDECISIVE_BRO_CHANGE_IAM_CONFIG_META_FILTER = "@broChange iam config"
        UTF_NONDECISIVE_BRO_CHANGE_IAM_CONFIG_LOGFILE = "bro_change_iam_config.log"

        UTF_IMPORT_AND_RESTORE_FROM_BRO_BACKUP__ROLL_BACK_NAME = "Import and restore from BRO backup (roll back)"
        UTF_IMPORT_AND_RESTORE_FROM_BRO_BACKUP__ROLL_BACK_EXECUTION_ID = 2003 + "${env.BUILD_NUMBER}"
        UTF_IMPORT_AND_RESTORE_FROM_BRO_BACKUP__ROLL_BACK_META_FILTER = "@broImport and restore from backup"
        UTF_IMPORT_AND_RESTORE_FROM_BRO_BACKUP__ROLL_BACK_LOGFILE = "bro_import_and_restore_backup.log"

        UTF_BRO_VALIDATE_SYSTEM_WORKS_AS_EXPECTED_AFTER_ROLL_BACK_TEST_NAME = "BRO Validate system works as expected: after roll back"
        UTF_BRO_VALIDATE_SYSTEM_WORKS_AS_EXPECTED_AFTER_ROLL_BACK_TEST_EXECUTION_ID = 2004 + "${env.BUILD_NUMBER}"
        UTF_BRO_VALIDATE_SYSTEM_WORKS_AS_EXPECTED_AFTER_ROLL_BACK_TEST_META_FILTER = "@broValidateAfter system works as expected after rollback"
        UTF_BRO_VALIDATE_SYSTEM_WORKS_AS_EXPECTED_AFTER_ROLL_BACK_TEST_LOGFILE = "bro_validate_system_after_rollback.log"

        UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_NAME = "Decisive Nx1 Staging UTF Cucumber Tests"
        UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_EXECUTION_ID = 102
        UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_META_FILTER = "@decisive and @nx1 and @staging and not @onlyUpgrade and not @tc_under_development"
        UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_LOGFILE = "utf_decisive_nx1_staging_cucumber.log"
        UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER = "report_decisive_and_nx1_and_staging_and_not_onlyUpgrade_and_not_tc_under_development"

        UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_NAME = "Decisive Batch Staging UTF Cucumber Tests"
        UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_EXECUTION_ID = 103
        UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_META_FILTER = "@decisive and @slow and @staging and not @onlyUpgrade and not @tc_under_development"
        UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_LOGFILE = "utf_decisive_batch_staging_cucumber.log"
        UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER = "report_decisive_and_slow_and_staging_and_not_onlyUpgrade_and_not_tc_under_development"

        UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_NAME = "NonDecisive Nx1 Staging UTF Cucumber Tests"
        UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_EXECUTION_ID = 105
        UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_META_FILTER = "@non_decisive and @nx1 and @staging and not @onlyUpgrade and not @tc_under_development"
        UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_LOGFILE = "utf_nondecisive_nx1_staging_cucumber.log"
        UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER = "report_non_decisive_and_nx1_and_staging_and_not_onlyUpgrade_and_not_tc_under_development"

        UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_NAME = "NonDecisive Batch Staging UTF Cucumber Tests"
        UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_EXECUTION_ID = 106
        UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_META_FILTER = "@non_decisive and @slow and @staging and not @onlyUpgrade and not @tc_under_development"
        UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_LOGFILE = "utf_nondecisive_batch_staging_cucumber.log"
        UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER = "report_non_decisive_and_slow_and_staging_and_not_onlyUpgrade_and_not_tc_under_development"

        SPOTFIRE_ASSET_INSTALL_ASSIGN_LABEL_WRAPPER_JOB_NAME = "spotfire-asset-install-assign-label-wrapper"
        SPOTFIRE_SERVER = "spotfire"

        RUN_CHECKSPOTFIREPLATFORM_HEALTH_CHECK_STAGE_NAME = "Run CheckSpotfirePlatform health check"
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
                script {
                    if (!params.CLUSTER_LABEL && !params.CLUSTER_NAME) {
                        currentBuild.result = 'ABORTED'
                        error("CLUSTER_LABEL or CLUSTER_NAME must be specified")
                    } else if (params.CLUSTER_LABEL && params.CLUSTER_NAME) {
                        currentBuild.result = 'ABORTED'
                        error("Only one of CLUSTER_LABEL or CLUSTER_NAME must be specified")
                    }
                }
            }
        }

        stage('HELM_AND_CMA_VALIDATION_MODE Param check'){
            steps {
                script {
                    if ( params.HELM_AND_CMA_VALIDATION_MODE != CMA_MODE__HELM_VALUES && params.HELM_AND_CMA_VALIDATION_MODE != CMA_MODE__HELM_VALUES_AND_CMA_CONF && params.HELM_AND_CMA_VALIDATION_MODE != CMA_MODE_IS_HELM && params.HELM_AND_CMA_VALIDATION_MODE != CMA_MODE_IS_HELM_AND_CMA ) {

                        error "HELM_AND_CMA_VALIDATION_MODE \"${params.HELM_AND_CMA_VALIDATION_MODE}\" validation error. Valid options: CMA_MODE__HELM_VALUES:\"${CMA_MODE__HELM_VALUES}\" or \"${CMA_MODE_IS_HELM}\" CMA_MODE__HELM_VALUES_AND_CMA_CONF: \"${CMA_MODE__HELM_VALUES_AND_CMA_CONF}\" or \"${CMA_MODE_IS_HELM_AND_CMA}\""
                    }
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

        stage('Checkout adp-app-staging') {
            steps {
                dir('adp-app-staging-full-checkout') {
                    script {
                        gitadp.checkout(env.MAIN_BRANCH,'')
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
                    def result = gitadp.verifyNoNewPathSet(params.GERRIT_REFSPEC)
                    if (!result) {
                        error ('New patchset created since stage Prepare')
                    }
                }
            }
        }

        stage('Checkout adp') {
            steps {
                script {
                    gitadp.checkout('master', 'adp-app-staging')
                    sh 'ln -s "${WORKSPACE}/adp-app-staging/technicals/shellscripts" "${WORKSPACE}/shellscripts"'
                }
            }
        }

        stage('Check latest GERRIT_REFSPEC') {
            when {
                expression { env.GERRIT_REFSPEC }
            }
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE'){
                    script {
                        checkLatestGERRIT_REFSPEC()
                    }
                }
            }
        }

        stage('Checkout cnint - master ') {
            when {
                expression { !env.CNINT_GERRIT_REFSPEC }
            }
            steps {
                script {
                    gitcnint.checkout('master', 'cnint')
                }
            }
        }

        stage('Checkout cnint - refspec') {
            when {
                expression { env.CNINT_GERRIT_REFSPEC }
            }
            steps {
                script {
                    gitcnint.checkoutRefSpec("${env.CNINT_GERRIT_REFSPEC}", "FETCH_HEAD", 'cnint')
                }
            }
        }

        stage('Checkout meta - master') {
            when {
                expression { !env.GERRIT_REFSPEC }
            }
            steps {
                script {
                    gitmeta.checkout('master', 'project-meta-baseline')
                }
            }
        }

        stage('Checkout meta - refspec') {
            when {
                expression { env.GERRIT_REFSPEC }
            }
            steps {
                script {
                    gitmeta.checkoutRefSpec("${env.GERRIT_REFSPEC}", "FETCH_HEAD", 'project-meta-baseline')
                }
            }
        }

        stage('set Job description') {
            steps {
                script {
                    setJobDescription ()
                }
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
                                    // To use cluster name in POST stages
                                    env.CLUSTER = env.system
                                    sendLockEventToDashboard (transition: "lock", cluster: env.CLUSTER)
                                    logLock()
                                }
                            }
                        }

                        stage('Prepare cnint') {
                            steps {
                                dir('cnint') {
                                    checkoutGitSubmodules()
                                }
                            }
                        }

                        stage('get product version') {
                            steps{
                                dir('project-meta-baseline') {
                                    catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE'){
                                        script{
                                            def data = readYaml file: 'eric-eea-ci-meta-helm-chart/Chart.yaml'
                                            data.dependencies.eachWithIndex { dependency, i ->
                                                if (dependency.name == "eric-eea-int-helm-chart"){
                                                    env.INT_CHART_VERSION_=dependency.version
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        stage('init vars'){
                            steps {
                                dir('cnint') {
                                    //call ruleset init
                                    withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                                            usernamePassword(credentialsId: 'ECEAART_SEROGIC_API_KEY', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
                                            usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
                                            usernamePassword(credentialsId: 'hub-root-user', usernameVariable: 'HUB_ROOT_USER', passwordVariable: 'HUB_ROOT_PASSWD'),
                                            string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                            file(credentialsId: env.system, variable: 'KUBECONFIG')]){
                                        withEnv(["INT_CHART_NAME=eric-eea-int-helm-chart","INT_CHART_REPO=https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/","INT_CHART_VERSION=${env.INT_CHART_VERSION_}"]){
                                            sh './bob/bob -r ruleset2.0.yaml init'
                                        }
                                    }
                                }
                            }
                        }

                        stage('Check if namespace exist') {
                            steps {
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

                        stage('Check NELS availability') {
                            steps {
                                dir('cnint') {
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
                        }

                        stage('CRD Install') {
                            steps {
                                crdInstall()
                            }
                            post {
                                always {
                                    script {
                                        archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                                    }
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

                        stage('init meta vars'){
                            steps{
                                dir('project-meta-baseline') {
                                    //call ruleset init
                                    withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                                        usernamePassword(credentialsId: 'ECEAART_SEROGIC_API_KEY', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
                                        usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
                                        file(credentialsId: env.system, variable: 'KUBECONFIG')
                                    ]){
                                        sh './bob/bob init -r ruleset2.0.yaml'
                                    }
                                }
                            }
                        }

                        stage('Install K8S-based Spotfire') {
                            parallel {
                                stage('meta-deploy') {
                                    steps{
                                        dir('project-meta-baseline') {
                                            catchError(buildResult: 'FAILURE', stageResult: 'FAILURE'){
                                                metaDeploy()
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
                                stage('Execute Spotfire deployment') {
                                    steps {
                                        k8sSpotfireDeploy()
                                    }
                                    post {
                                        always {
                                            script {
                                                archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                                            }
                                        }
                                    }
                                }
                                stage('SEP Install') {
                                    steps {
                                        sepInstall()
                                    }
                                    post {
                                        always {
                                            script {
                                                archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        stage('Checkout technicals'){
                            steps{
                                dir('cnint'){
                                    dir('adp-app-staging'){
                                        script {
                                            gitadp.archiveDir('EEA/adp-app-staging', 'HEAD:technicals/pythonscripts/')
                                            gitadp.archiveDir('EEA/adp-app-staging', 'HEAD:rulesets/')
                                        }
                                    }
                                }
                            }
                        }

                        stage('Set CMA helm values') {
                            steps {
                                setCMAHelmValues()
                            }
                            post {
                                always {
                                    script {
                                        archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                                    }
                                }
                            }
                        }

                        stage('Download and apply dimtool output file') {
                            steps {
                                script {
                                    dir('cnint') {
                                        cmutils.useValuesFromDimToolOutput("${params.DIMTOOL_OUTPUT_REPO_URL}", "${params.DIMTOOL_OUTPUT_REPO}", "${params.DIMTOOL_OUTPUT_NAME}" )
                                    }
                                }
                            }
                        }

                        stage('Install product') {
                            steps{
                                installProduct()
                            }
                            post {
                                failure {
                                    dir ('cnint') {
                                        script {
                                            clusterLogUtilsInstance.getResourceCapacity(env.CLUSTER)
                                        }
                                    }
                                }
                                always {
                                    dir ('cnint') {
                                        script {
                                            cmutils.archiveFilesFromLog("k8s-test.log", "--helm_value_file=(\\S+)[\\]\\s]", "install-configvalues.tar.gz")
                                        }
                                    }
                                    script {
                                        archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                                    }
                                    archiveArtifacts artifacts: "cnint/install-configvalues.tar.gz", allowEmptyArchive: true
                                }
                            }
                        }

                        stage('Link Spotfire platform to EEA') {
                            steps {
                                spotfireLinkToEEA()
                            }
                            post {
                                always {
                                    script {
                                        archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                                    }
                                }
                            }
                        }

                        stage('Run CheckSpotfirePlatform health check') { //RUN_CHECKSPOTFIREPLATFORM_HEALTH_CHECK_STAGE_NAME
                            steps {
                                dir('cnint') {
                                    script {
                                        clusterLogUtilsInstance.runHealthCheck("${vars.waitForPodsAfterInstall}", "${STAGE_NAME}", clusterCredentialID=env.CLUSTER, eeaHealthcheckCheckClasses='CheckSpotfirePlatform',  k8s_namespace='spotfire-platform')
                                    }
                                }
                            }
                        }

                        stage('Create stream-aggregator configmap') {
                            steps {
                                dir ('cnint') {
                                    script {
                                        cmutils.createAggregatorConfigmapFromDimtoolOutput()
                                    }
                                }
                            }
                        }

                        stage('Run health check after install') {
                            steps {
                                dir('cnint') {
                                    script {
                                        clusterLogUtilsInstance.runHealthCheck("${vars.waitForPodsAfterInstall}", "${STAGE_NAME}")
                                    }
                                }
                            }
                            post {
                                always {
                                    script {
                                        archiveArtifacts artifacts: "cnint/stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                                    }
                                }
                            }
                        }

                        stage('Load config json to CM-Analytics') {
                            when {
                                expression { params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE__HELM_VALUES_AND_CMA_CONF || params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE_IS_HELM_AND_CMA }
                            }
                            steps {
                                loadConfigJsonToCMA()
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
                                runHealthCheckAfterCMAConfigLoad()
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
                                runCMAHealthCheckAfterCMAConfigLoad()
                            }
                            post {
                                always {
                                    script {
                                        archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                                    }
                                }
                            }
                        }

                        stage('Init BRO Test Variables') {
                            steps {
                                initBROTestVariables()
                            }
                            post {
                                always {
                                    script {
                                        archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                                    }
                                }
                            }
                        }

                        stage('Execute BRO tests') {
                            steps {
                                executeBROTests(stageCommentList)
                            }
                            post {
                                always {
                                    script {
                                        archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                                    }
                                }
                            }
                        }

                        stage('init UTF Test Variables') {
                            steps {
                                script {
                                    utf.initUtfTestVariables(vars, "adp-app-staging/technicals/utf_test_parameters.json")
                                }
                            }
                        }

                        stage('UTF Pre-activities') { //MUST BE SAME AS UTF_PRE_ACTIVITIES_TEST_NAME!!!
                            steps {
                                dir('cnint') {
                                    script {
                                        def utf_pre_activities = [name: "${UTF_PRE_ACTIVITIES_TEST_NAME}", build_result: 'FAILURE', stage_result: 'FAILURE', exec_id: "${UTF_PRE_ACTIVITIES_TEST_EXECUTION_ID}", metafilter: "${env.UTF_PRE_ACTIVITIES_META_FILTER}", timeout: "${UTF_PRE_ACTIVITIES_TEST_TIMEOUT}", logfile: "${UTF_PRE_ACTIVITIES_TEST_LOGFILE}"]
                                        utf.execUtfTest(utf_pre_activities)
                                    }
                                }
                            }
                            post {
                                always {
                                    dir('cnint') {
                                        script {
                                            clusterLogUtilsInstance.getResourceCapacity(env.CLUSTER)
                                        }
                                    }
                                }
                            }
                        }

                        stage('Execute Cucumber tests') {
                            steps {
                                executeCucumberTests(stageCommentList)
                            }
                            post {
                                always {
                                    script {
                                        archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
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
                                    }
                                }
                            }
                        }

                        stage('Non_decisive robot Tests') {
                            steps {
                                runRvRobot('non_decisive')
                            }
                            post {
                                always {
                                    script {
                                        archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                                    }
                                }
                            }
                        }

                        stage('UTF Post-activities') { // MUST BE SAME AS UTF_POST_ACTIVITIES_TEST_NAME
                            steps {
                                dir('cnint') {
                                    script {
                                        def utf_post_activities = [name: "${UTF_POST_ACTIVITIES_TEST_NAME}", build_result: 'FAILURE', stage_result: 'FAILURE', exec_id: "${UTF_POST_ACTIVITIES_TEST_EXECUTION_ID}", metafilter: "${env.UTF_POST_ACTIVITIES_META_FILTER}", timeout: "${UTF_TEST_TIMEOUT}", logfile: "${UTF_POST_ACTIVITIES_TEST_LOGFILE}"]
                                        utf.execUtfTest(utf_post_activities)
                                    }
                                }
                            }
                        }
                    }
                    post {
                        always {
                            lockPostAlways()
                        }
                    }
                }
            }
            post {
                always {
                    resourceLockingUtfDeployAndK8SInstall()
                }
            }
        }
    }
    post {
        always {
            script {
                archiveArtifacts artifacts: "watches_count_indicators.log", allowEmptyArchive: true
                cmutils.generateStageResultsHtml(stageCommentList,stageResultsInfo)
            }
        }
        failure {
            script {
                if(env.GERRIT_REFSPEC) {
                    env.GERRIT_MSG = "Build Failed ${BUILD_URL}: FAILURE"
                    sendMessageToGerrit(env.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }
        success {
            script {
                if(env.GERRIT_REFSPEC) {
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

def resourceLockingUtfDeployAndK8SInstall() {
    script {
        sendLockEventToDashboard(transition: "release", cluster: env.CLUSTER)

        if ("${env.EEA_NS_CHECK_FAILED}".toBoolean()) {
            return
        }
        if (params.CUSTOM_CLUSTER_LABEL?.trim()) {
            echo "Cluster has a new label ${params.CUSTOM_CLUSTER_LABEL}"
            return
        }

        if (!env.CLUSTER) {
            echo "There was no cluster lock, COLLECT_LOG skipped"
            return
        }

        if (params.SKIP_COLLECT_LOG) {
            echo "COLLECT_LOG skipped"
            return
        }

        try {
            echo "Execute cluster-logcollector job ... \n - cluster: ${env.CLUSTER}"
            build job: "cluster-logcollector", parameters: [
                stringParam(name: "CLUSTER_NAME", value: env.CLUSTER),
                stringParam(name: 'SERVICE_NAME', value: params.CHART_NAME),
                booleanParam(name: "CLUSTER_CLEANUP", value: !params.SKIP_CLEANUP.toBoolean()),
                stringParam(name: 'LAST_LABEL_SET', value: env.LASTLABEL),
                stringParam(name: 'PIPELINE_NAME', value: params.PIPELINE_NAME),
                stringParam(name: 'SPINNAKER_ID', value: params.SPINNAKER_ID),
                stringParam(name: 'SPINNAKER_TRIGGER_URL', value: params.SPINNAKER_TRIGGER_URL)
            ], wait: false, waitForStart: true
        } catch (Exception err) {
            echo "Caught cluster-logcollector ERROR: ${err}"
        }
    }
}

def lockPostAlways() {
    dir('cnint') {
        script {
            if (!"${env.EEA_NS_CHECK_FAILED}".toBoolean()) {
                if ( params.CUSTOM_CLUSTER_LABEL?.trim() ) {
                    try {
                        setLockableResourceLabels(env.CLUSTER, params.CUSTOM_CLUSTER_LABEL)
                    }
                    catch (err) {
                        echo "Caught setLockableResourceLabels ERROR: ${err}"
                    }
                } else if ( ! params.SKIP_COLLECT_LOG ) {
                    try {
                        def labelmanualchanged = checkLockableResourceLabelManualChange(env.CLUSTER)
                        prepareClusterForLogCollection("${env.CLUSTER}", "${env.JOB_NAME}", "${env.BUILD_NUMBER}", labelmanualchanged)
                    }
                    catch (err) {
                        echo "Caught prepareClusterForLogCollection ERROR: ${err}"
                    }
                }
            }

            // Save the lock times
            env.lock_end = java.time.LocalDateTime.now()
            sh "{ (echo '$system,${env.lock_start},${env.lock_end},eea-product-ci-meta-baseline-loop-test' >> /data/nfs/productci/cluster_lock.csv) } || echo '/data/nfs/productci/cluster_lock.csv is unreachable'"

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

void runRvRobot(String robotTags) {
    def result = robotTags == 'decisive' ? 'FAILURE' : 'SUCCESS'
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        catchError(buildResult: result, stageResult: 'FAILURE' ) {
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

def checkLatestGERRIT_REFSPEC() {
    env.GERRIT_CHANGE_NUMBER = gitmeta.getCommitIdFromRefspec(env.GERRIT_REFSPEC)
    echo "env.GERRIT_CHANGE_NUMBER=${env.GERRIT_CHANGE_NUMBER}"

    env.LATEST_GERRIT_REFSPEC = gitmeta.getCommitRefSpec(env.GERRIT_CHANGE_NUMBER)
    echo "env.LATEST_GERRIT_REFSPEC=${env.LATEST_GERRIT_REFSPEC}"

    if (env.LATEST_GERRIT_REFSPEC != params.GERRIT_REFSPEC) {
        error "There is a newer patchset than the value specified in the incoming parameter: ${params.GERRIT_REFSPEC}, latest value: ${env.LATEST_GERRIT_REFSPEC}"
        // TODO: EEAEPP-79292
        // check if a newer patchset was uploaded by any user
        // if any user (tecnical or non technical) creates a new patchset , the validation should FAIL
        // after the Spinnaker prepare stage the refspec must not change
    }
}

def setJobDescription () {
    // Generate log url link name and log directory names
    def name = CHART_NAME + ': ' + CHART_VERSION
    def gerrit_link = null
    if (env.GERRIT_REFSPEC) {
        name = "manual change"
        gerrit_link = getGerritLink(env.GERRIT_REFSPEC)
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

def metaDeploy() {
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
            usernamePassword(credentialsId: 'ECEAART_SEROGIC_API_KEY', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
            usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
            file(credentialsId: env.system, variable: 'KUBECONFIG')
        ]){
            sh './bob/bob k8s-test-utf > k8s-test-utf.log'

            archiveArtifacts "k8s-test-utf.log"
            script {
                try{
                    def data = readYaml file: 'eric-eea-ci-meta-helm-chart/Chart.yaml'
                    env.META_BASELINE_NAME = data.name
                    env.META_BASELINE_VERSION = data.version
                }
                catch (err) {
                    echo "Caught: ${err}"
                }
                echo "Reading env.UTF_DATASET_ID ..."
                try{
                    def dataValues = readYaml file: 'eric-eea-ci-meta-helm-chart/values.yaml'
                    env.UTF_DATASET_ID = dataValues["dataset-information"]["dataset-version"]
                    env.UTF_REPLAY_SPEED = dataValues["dataset-information"]["replay-speed"]
                    env.UTF_REPLAY_COUNT = dataValues["dataset-information"]["replay-count"]
                    echo "env.UTF_DATASET_ID: ${env.UTF_DATASET_ID}"
                    echo "env.UTF_REPLAY_SPEED: ${env.UTF_REPLAY_SPEED}"
                    echo "env.UTF_REPLAY_COUNT: ${env.UTF_REPLAY_COUNT}"
                }
                catch (err) {
                    error "Caught: ${err}"
                }
            }
        }
    }
}

def logLock() {
    echo "Locked cluster: $system"
    if ( !env.LASTLABEL && params.CLUSTER_NAME ) {
        env.LASTLABEL = getLockableResourceLabels("${params.CLUSTER_NAME}")
    }
    echo "Locked cluster current label: ${env.LASTLABEL}"
    env.lock_start = java.time.LocalDateTime.now()
    env.START_EPOCH = ((new Date()).getTime()/1000 as double).round()
    currentBuild.description += "<br>Locked cluster: $system"

    k8s_master = cmutils.getK8SMasterNodeName(system)

}

def crdInstall() {
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        dir('cnint') {
            withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                usernamePassword(credentialsId: 'ECEAART_SEROGIC_API_KEY', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
                usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
                file(credentialsId: env.system, variable: 'KUBECONFIG')
            ]){
                withEnv(["INT_CHART_NAME=eric-eea-int-helm-chart","INT_CHART_REPO=https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/","INT_CHART_VERSION=${env.INT_CHART_VERSION_}"]){
                    script {
                        try {
                            sh 'echo "${INT_CHART_VERSION}"'
                            sh './bob/bob k8s-test:download-extract-chart k8s-test:package-helper-chart k8s-test-crd > crd-install.log'
                        }
                        catch (err) {
                            echo "Caught: ${err}"
                            error "CRD INSTALL FAILED"
                        } finally {
                            archiveArtifacts artifacts: "crd-install.log", allowEmptyArchive: true
                        }
                    }
                }
            }
        }
    }
}

def sepInstall() {
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        dir('cnint') {
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
                        echo "Installing SEP version: ${env.SEP_CHART_VERSION}"
                        sh './bob/bob k8s-test-sep > sep-install.log'
                    }
                    catch (err) {
                        echo "Caught: ${err}"
                        error "SEP INSTALL FAILED"
                    }
                    finally {
                        archiveArtifacts artifacts: 'sep-install.log', allowEmptyArchive: true
                    }
                }
            }
        }
    }
}

def setCMAHelmValues() {
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        dir('cnint') {
            script {
                echo "HELM_AND_CMA_VALIDATION_MODE mode is: ${params.HELM_AND_CMA_VALIDATION_MODE}"
                if (params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE__HELM_VALUES || params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE_IS_HELM) {
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
    }
}

def loadConfigJsonToCMA() {
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        dir('cnint') {
            withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                usernamePassword(credentialsId: 'ECEAART_SEROGIC_API_KEY', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
                file(credentialsId: env.system, variable: 'KUBECONFIG')
            ]){
                cmutils.removeAggregationsFromConfigurationsByNamePattern()
                withEnv(["CMA_EXT_CONFIG_FILE=${vars.cma_correlator_content_version_path}", "CMA_EXT_CONFIG_ENDPOINT=${vars.cma_correlator_content_version_endpoint}"]) {
                    sh './bob/bob -r ruleset2.0.yaml load-cm-analytics-config-cubes-into-eea'
                }
                // WA: Temporary sleeping
                sleep(time: 5, unit: 'MINUTES' )
                withEnv(["CMA_EXT_CONFIG_FILE=${vars.cma_config_path}"]) {
                    sh './bob/bob -r ruleset2.0.yaml load-cm-analytics-config-cubes-into-eea'
                }
            }
        }
    }
}

def runHealthCheckAfterCMAConfigLoad() {
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        dir('cnint') {
            script {
                clusterLogUtilsInstance.runHealthCheck("${vars.waitForPodsAfterInstall}", "${STAGE_NAME}")
            }
        }
    }
}

def runCMAHealthCheckAfterCMAConfigLoad() {
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        dir('cnint') {
            catchError(stageResult: 'FAILURE', buildResult: "${params.BUILD_RESULT_WHEN_CMA_HEALTH_CHECK_FAILED}") {
                script {
                    clusterLogUtilsInstance.runHealthCheckWithCMA("${vars.waitForPodsAfterInstall}", "${STAGE_NAME}")
                }
            }
        }
    }
}

def initBROTestVariables() {
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        script {
            sh "ln -s ${WORKSPACE}/adp-app-staging/technicals/shellscripts -T ${WORKSPACE}/adp-app-staging/shellscripts"
            sh "mkdir -p ${WORKSPACE}/.bob/chart/eric-eea-int-helm-chart"
            sh "ln -s ${WORKSPACE}/cnint/.bob/chart/eric-eea-int-helm-chart/Chart.yaml ${WORKSPACE}/.bob/chart/eric-eea-int-helm-chart/Chart.yaml"
            utf.initUtfTestVariables(vars, "adp-app-staging/technicals/utf_test_parameters.json")
        }
    }
}

def executeBROTests(def stageCommentList) {
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        dir('cnint') {
            script {
                def bro_tests = [[name: "${UTF_CREATE_AND_EXPORT_BRO_BACKUP_TEST_NAME}", build_result: 'FAILURE', stage_result: 'FAILURE', exec_id: "${UTF_CREATE_AND_EXPORT_BRO_BACKUP_TEST_EXECUTION_ID}", metafilter: "${UTF_CREATE_AND_EXPORT_BRO_BACKUP_TEST_META_FILTER}", timeout: "${UTF_TEST_TIMEOUT}", logfile: "${UTF_CREATE_AND_EXPORT_BRO_BACKUP_TEST_LOGFILE}"],
                                 [name: "${UTF_BRO_VALIDATE_SYSTEM_WORKS_AS_EXPECTED_BEFORE_ROLL_BACK_TEST_NAME}", build_result: 'FAILURE', stage_result: 'FAILURE', exec_id: "${UTF_BRO_VALIDATE_SYSTEM_WORKS_AS_EXPECTED_BEFORE_ROLL_BACK_TEST_EXECUTION_ID}", metafilter: "${UTF_BRO_VALIDATE_SYSTEM_WORKS_AS_EXPECTED_BEFORE_ROLL_BACK_TEST_META_FILTER}", timeout: "${UTF_TEST_TIMEOUT}", logfile: "${UTF_BRO_VALIDATE_SYSTEM_WORKS_AS_EXPECTED_BEFORE_ROLL_BACK_TEST_LOGFILE}"],
                                 [name: "${UTF_NONDECISIVE_BRO_CHANGE_IAM_CONFIG_NAME}", build_result: 'SUCCESS', stage_result: 'FAILURE', exec_id: "${UTF_NONDECISIVE_BRO_CHANGE_IAM_CONFIG_EXECUTION_ID}", metafilter: "${UTF_NONDECISIVE_BRO_CHANGE_IAM_CONFIG_META_FILTER}", timeout: "${UTF_TEST_TIMEOUT}", logfile: "${UTF_NONDECISIVE_BRO_CHANGE_IAM_CONFIG_LOGFILE}"],
                                 [name: "${UTF_IMPORT_AND_RESTORE_FROM_BRO_BACKUP__ROLL_BACK_NAME}", build_result: 'FAILURE', stage_result: 'FAILURE', exec_id: "${UTF_IMPORT_AND_RESTORE_FROM_BRO_BACKUP__ROLL_BACK_EXECUTION_ID}", metafilter: "${UTF_IMPORT_AND_RESTORE_FROM_BRO_BACKUP__ROLL_BACK_META_FILTER}", timeout: "${UTF_TEST_TIMEOUT}", logfile: "${UTF_IMPORT_AND_RESTORE_FROM_BRO_BACKUP__ROLL_BACK_LOGFILE}"]]
                utf.execUtfTests(bro_tests)
                bro_tests.each { test ->
                    stageCommentList[test.name] = [" <a href=\"${env.BUILD_URL}/artifact/${test.logfile}\">${test.logfile}</a>"]
                }
                echo "Start cleanup IAM cache after rollback..."
                cmutils.execCleanupIamCacheAfterRollback()
                def bro_test_after_rollback = [name: "${UTF_BRO_VALIDATE_SYSTEM_WORKS_AS_EXPECTED_AFTER_ROLL_BACK_TEST_NAME}", build_result: 'FAILURE', stage_result: 'FAILURE', exec_id: "${UTF_BRO_VALIDATE_SYSTEM_WORKS_AS_EXPECTED_AFTER_ROLL_BACK_TEST_EXECUTION_ID}", metafilter: "${UTF_BRO_VALIDATE_SYSTEM_WORKS_AS_EXPECTED_AFTER_ROLL_BACK_TEST_META_FILTER}", timeout: "${UTF_TEST_TIMEOUT}", logfile: "${UTF_BRO_VALIDATE_SYSTEM_WORKS_AS_EXPECTED_AFTER_ROLL_BACK_TEST_LOGFILE}"]
                utf.execUtfTest(bro_test_after_rollback)
                stageCommentList[bro_test_after_rollback.name] = [" <a href=\"${env.BUILD_URL}/artifact/${bro_test_after_rollback.logfile}\">${bro_test_after_rollback.logfile}</a>"]
            }
        }
    }
}

def k8sSpotfireDeploy() {
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        script {
            spotfire_install_job = build job: "${SPOTFIRE_ASSET_INSTALL_ASSIGN_LABEL_WRAPPER_JOB_NAME}", parameters: [
                    booleanParam(name: 'INSTALL_SPOTFIRE_PLATFORM', value: true),
                    booleanParam(name: 'DEPLOY_STATIC_CONTENT', value: true),
                    stringParam(name: 'CLUSTER_NAME', value : env.CLUSTER),
                    stringParam(name: 'SF_ASSET_VERSION', value: 'auto'),
                    stringParam(name: 'STATIC_CONTENT_PKG', value: 'auto'),
                    stringParam(name: 'CNINT_GERRIT_REFSPEC', value: params.CNINT_GERRIT_REFSPEC)
            ], wait: true
            def spotfireInstallJobResult = spotfire_install_job.getResult()
            env.SPOTFIRE_INSTALL_BUILD_NUMBER = spotfire_install_job.number
            downloadJenkinsFile("${env.JENKINS_URL}/job/${SPOTFIRE_ASSET_INSTALL_ASSIGN_LABEL_WRAPPER_JOB_NAME}/${spotfire_install_job.number}/artifact/artifact.properties", "spotfire_asset_install_assign_label_wrapper_artifact.properties")
            readProperties(file: 'spotfire_asset_install_assign_label_wrapper_artifact.properties').each {key, value -> env[key] = value }
            if (spotfireInstallJobResult != 'SUCCESS') {
                error("Build of ${SPOTFIRE_ASSET_INSTALL_ASSIGN_LABEL_WRAPPER_JOB_NAME} job failed with result: ${spotfireInstallJobResult}")
            }
        }
    }
}

def spotfireLinkToEEA() {
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        script {
            link_spotfire_platform_to_eea_job = build job: "${SPOTFIRE_ASSET_INSTALL_ASSIGN_LABEL_WRAPPER_JOB_NAME}", parameters: [
                    booleanParam(name: 'SETUP_TLS_AND_SSO', value: true),
                    booleanParam(name: 'ENABLE_CAPACITY_REPORTER', value: true),
                    stringParam(name: 'CLUSTER_NAME', value : env.CLUSTER),
                    stringParam(name: 'SF_ASSET_VERSION', value: 'auto'),
                    stringParam(name: 'STATIC_CONTENT_PKG', value: 'auto'),
                    stringParam(name: 'CNINT_GERRIT_REFSPEC', value: params.CNINT_GERRIT_REFSPEC),
                    stringParam(name: 'PREVIOUS_JOB_BUILD_ID', value: env.SPOTFIRE_ASSET_INSTALL_NEW_BUILD_NUMBER)
            ], wait: true
            def spotfireInstallJobResult = link_spotfire_platform_to_eea_job.getResult()
            if (spotfireInstallJobResult != 'SUCCESS') {
                error("Build of ${SPOTFIRE_ASSET_INSTALL_ASSIGN_LABEL_WRAPPER_JOB_NAME} job failed with result: ${spotfireInstallJobResult}")
            }
        }
    }
}

def installProduct() {
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        dir('cnint') {
            script {
                Map args = [
                    "helmTimeout":      "4200",
                    "clusterName":      "${env.system}",
                    "intChartName":     "eric-eea-int-helm-chart",
                    "intChartRepo":     "https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/",
                    "intChartVersion":  "${env.INT_CHART_VERSION_}",
                    "bobRulesetsPath":  "${WORKSPACE}/cnint/adp-app-staging",
                    "bobRulesList":     ["./bob/bob init", "./bob/bob -r ruleset2.0.yaml init-mxe", "./bob/bob -r ruleset2.0.yaml init-eric-eea-analysis-system-overview-install", "./bob/bob -r ruleset2.0.yaml verify-values-files > k8s-test-verify-values.log", "./bob/bob -r ruleset2.0.yaml k8s-test-splitted-values > k8s-test.log"]
                ]
                cmutils.k8sInstallTest(args)
            }
        }
    }
}

def executeCucumberTests(def stageCommentList) {
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        script {
            TIMEOUT = UTF_TEST_TIMEOUT * 2
        }
        timeout(time: "${TIMEOUT}", unit: 'SECONDS') {
            dir('cnint') {
                script {
                    def cucumber_tests = [[name: "${UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_NAME}", build_result: 'FAILURE', stage_result: 'FAILURE', exec_id: "${UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_EXECUTION_ID}", metafilter: "${UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_META_FILTER}", timeout: "${UTF_TEST_TIMEOUT}", logfile: "${UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_LOGFILE}", report_folder: "${UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER}"],
                        [name: "${UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_NAME}", build_result: 'FAILURE', stage_result: 'FAILURE', exec_id: "${UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_EXECUTION_ID}", metafilter: "${UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_META_FILTER}", timeout: "${UTF_TEST_TIMEOUT}", logfile: "${UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_LOGFILE}", report_folder: "${UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER}"],
                        [name: "${UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_NAME}", build_result: 'SUCCESS', stage_result: 'FAILURE', exec_id: "${UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_EXECUTION_ID}", metafilter: "${UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_META_FILTER}", timeout: "${UTF_TEST_TIMEOUT}", logfile: "${UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_LOGFILE}", report_folder: "${UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER}"],
                        [name: "${UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_NAME}", build_result: 'SUCCESS', stage_result: 'FAILURE', exec_id: "${UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_EXECUTION_ID}", metafilter: "${UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_META_FILTER}", timeout: "${UTF_TEST_TIMEOUT}", logfile: "${UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_LOGFILE}", report_folder: "${UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER}"]]
                    utf.execUtfTests(cucumber_tests)
                    utf.generateUtfTestReportLinks(cucumber_tests)
                    utf.generateSumReportLinks(cucumber_tests)
                    cucumber_tests.each { test ->
                        stageCommentList[test.name] = [" <a href=\"${env.BUILD_URL}/artifact/${test.logfile}\">${test.logfile}</a>"]
                    }
                }
            }
        }
    }
}
