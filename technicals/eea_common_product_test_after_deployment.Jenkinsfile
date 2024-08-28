@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.GlobalVars
import com.ericsson.eea4.ci.ClusterLogUtils
import com.ericsson.eea4.ci.ClusterLockUtils
import com.ericsson.eea4.ci.CommonUtils
import com.ericsson.eea4.ci.UtfTrigger2
import com.ericsson.eea4.ci.EEA_Robot
import groovy.transform.Field

@Field def gitmeta = new GitScm(this, 'EEA/project-meta-baseline')
@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def globalVars = new GlobalVars()
@Field def clusterLogUtilsInstance = new ClusterLogUtils(this)
@Field def clusterLockUtils =  new ClusterLockUtils(this)
@Field def cmutils = new CommonUtils(this)
@Field def utf = new UtfTrigger2(this)

def stageResults = [:]
def stageResultsInfo = [:]
def stageCommentList = [:]


pipeline {
    options {
        ansiColor('xterm')
        buildDiscarder(logRotator(daysToKeepStr: "21", artifactDaysToKeepStr: "7"))
        skipDefaultCheckout()
    }

    parameters {
        string(name: 'AGENT_LABEL', description: 'The Jenkins build node label', defaultValue: 'productci')
        string(name: 'CLUSTER_NAME', description:'The cluster where the tests need to be run. It must be locked by parent job or reserved manually', defaultValue: '')
        string(name: 'CHART_NAME', description: 'Chart name e.g.: eric-ms-b', defaultValue: '')
        string(name: 'CHART_REPO', description: 'Chart repo e.g.: https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm', defaultValue: '')
        string(name: 'CHART_VERSION', description: 'Chart version e.g.: 1.0.0-1', defaultValue: '')
        string(name: 'INT_CHART_NAME_PRODUCT', description: 'Chart name e.g.: eric-ms-b', defaultValue: 'eric-eea-int-helm-chart')
        string(name: 'INT_CHART_REPO_PRODUCT', description: 'Chart repo e.g.: https://arm.seli.gic.ericsson.se/artifactory/proj-eea-ci-internal-helm/', defaultValue: 'https://arm.seli.gic.ericsson.se/artifactory/proj-eea-ci-internal-helm/')
        string(name: 'INT_CHART_VERSION_PRODUCT', description: 'Version to upgrade. Format: 1.0.0-1 Set value "latest" to automaticaly define and use latest INT chart version', defaultValue: '')
        string(name: 'GERRIT_REFSPEC', description: 'Gerrit Refspec of the cnint, for example refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'META_GERRIT_REFSPEC', description: 'Gerrit Refspec of the project-meta-baseline, for example refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'PIPELINE_NAME', description: 'The spinnaker pipeline name', defaultValue: 'eea-application-staging')
        string(name: 'SPINNAKER_TRIGGER_URL', description: 'Spinnaker pipeline triggering url', defaultValue: '')
        string(name: 'SPINNAKER_ID', description: "The spinnaker execution's id", defaultValue: '')
        string(name: 'INT_CHART_NAME_META', description: 'Chart name e.g.: eric-ms-b', defaultValue: 'eric-eea-ci-meta-helm-chart')
        string(name: 'INT_CHART_REPO_META', description: 'Chart repo e.g.: https://arm.seli.gic.ericsson.se/artifactory/proj-eea-ci-internal-helm/', defaultValue: 'https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/')
        string(name: 'INT_CHART_VERSION_META', description: 'meta-baseline version to install. Format: 1.0.0-1', defaultValue: '')
        choice(name: 'DEPLOYMENT_TYPE', description: 'Type of the deployment: INSTALL or UPGRADE. Mandatory, if parent job is not used.', choices: ['','INSTALL', 'UPGRADE'])
        booleanParam(name: 'RUN_ROBOT_TESTS', description: 'Run the robot tests if spotfire is deployed.', defaultValue: true)
    }

    agent {
        node {
            label "${params.AGENT_LABEL}"
        }
    }

    environment {
        system = "${params.CLUSTER_NAME}"
        UTF_TEST_TIMEOUT = 1800
        UTF_PRE_ACTIVITIES_TEST_NAME = "UTF Pre-activities"
        UTF_PRE_ACTIVITIES_TEST_LOGFILE = "utf_pre_activities_loading.log"
        UTF_PRE_ACTIVITIES_TEST_EXECUTION_ID = 1111 + "${env.BUILD_NUMBER}"
        UTF_PRE_ACTIVITIES_META_FILTER = "@startRefData or @startData"
        UTF_PRE_ACTIVITIES_TEST_TIMEOUT = 2700

        UTF_PRE_ACTIVITIES_CHECK_NAME = 'Pre-activites-upgrade check after upgrade'
        UTF_PRE_ACTIVITIES_CHECK_TEST_EXECUTION_ID = 1112 + "${env.BUILD_NUMBER}"
        UTF_PRE_ACTIVITIES_CHECK_META_FILTER = "@startDataCheck"
        UTF_PRE_ACTIVITIES_CHECK_TEST_TIMEOUT = 1800
        UTF_PRE_ACTIVITIES_CHECK_LOGFILE = "utf_data_load_check_after_upgrade.log"

        UTF_POST_ACTIVITIES_TEST_NAME = "UTF Post-activities"
        UTF_POST_ACTIVITIES_TEST_EXECUTION_ID = 9999 + "${env.BUILD_NUMBER}"
        UTF_POST_ACTIVITIES_META_FILTER = "@stopData"
        UTF_POST_ACTIVITIES_TEST_TIMEOUT = 1800
        UTF_POST_ACTIVITIES_TEST_LOGFILE = "utf_post_activities_loading.log"

        UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_NAME = "Decisive Nx1 Staging UTF Cucumber Tests"
        UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_EXECUTION_ID = 101 + "${env.BUILD_NUMBER}"
        UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_META_FILTER_UPGRADE = "@decisive and @nx1 and @staging and not @onlyInstall and not @tc_under_development"
        UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER_UPGRADE = "report_decisive_and_nx1_and_staging_and_not_onlyInstall_and_not_tc_under_development"
        UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_META_FILTER_INSTALL = "@decisive and @nx1 and @staging and not @onlyUpgrade and not @tc_under_development"
        UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER_INSTALL = "report_decisive_and_nx1_and_staging_and_not_onlyUpgrade_and_not_tc_under_development"
        UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_TIMEOUT = "1800"
        UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_LOGFILE = "utf_decisive_nx1_staging_cucumber_upgrade.log"

        UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_NAME = "Decisive Batch Staging UTF Cucumber Tests"
        UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_EXECUTION_ID = 102 + "${env.BUILD_NUMBER}"
        UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_META_FILTER_UPGRADE = "@decisive and @slow and @staging and not @onlyInstall and not @tc_under_development"
        UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER_UPGRADE = "report_decisive_and_slow_and_staging_and_not_onlyInstall_and_not_tc_under_development"
        UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_META_FILTER_INSTALL = "@decisive and @slow and @staging and not @onlyUpgrade and not @tc_under_development"
        UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER_INSTALL = "report_decisive_and_slow_and_staging_and_not_onlyUpgrade_and_not_tc_under_development"
        UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_TIMEOUT = "3600"
        UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_LOGFILE = "utf_decisive_batch_staging_cucumber_upgrade.log"

        UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_NAME = "NonDecisive Nx1 Staging UTF Cucumber Tests"
        UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_EXECUTION_ID = 103 + "${env.BUILD_NUMBER}"
        UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_META_FILTER_UPGRADE = "@non_decisive and @nx1 and @staging and not @onlyInstall and not @tc_under_development"
        UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER_UPGRADE = "report_non_decisive_and_nx1_and_staging_and_not_onlyInstall_and_not_tc_under_development"
        UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_META_FILTER_INSTALL = "@non_decisive and @nx1 and @staging and not @onlyInstall and not @tc_under_development"
        UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER_INSTALL = "report_non_decisive_and_nx1_and_staging_and_not_onlyInstall_and_not_tc_under_development"
        UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_TIMEOUT = "1800"
        UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_LOGFILE = "utf_nondecisive_nx1_staging_cucumber_upgrade.log"

        UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_NAME = "NonDecisive Batch Staging UTF Cucumber Tests"
        UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_EXECUTION_ID = 104 + "${env.BUILD_NUMBER}"
        UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_META_FILTER_UPGRADE = "@non_decisive and @slow and @staging and not @onlyInstall and not @tc_under_development"
        UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER_UPGRADE = "report_non_decisive_and_slow_and_staging_and_not_onlyInstall_and_not_tc_under_development"
        UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_META_FILTER_INSTALL = "@non_decisive and @slow and @staging and not @onlyInstall and not @tc_under_development"
        UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER_INSTALL = "report_non_decisive_and_slow_and_staging_and_not_onlyInstall_and_not_tc_under_development"
        UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_TIMEOUT = "3600"
        UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_LOGFILE = "utf_nondecisive_batch_staging_cucumber_upgrade.log"

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

        stage('Check params and set clsuter') {
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

        stage('Checkout cnint master') {
            steps {
                checkoutCnintMaster()
            }
        }

        stage('Checkout project-meta-baseline') {
            steps {
                checkoutMeta()
            }
        }

        stage('Ruleset change checkout') {
            when {
                expression {params.GERRIT_REFSPEC && params.PIPELINE_NAME != 'eea-product-ci-meta-baseline-loop'}
            }
            steps {
                loggedStage(){
                    rulesetChangeCheckout()
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
                archiveTechnicalsRulesetDirs()
            }
        }

        stage('Init vars and get charts') {
            steps {
                loggedStage(){
                    initVarsAndGetCharts()
                }
            }
        }

        stage('Init BRO Test Variables') {
            when {
                expression { (params.CHART_NAME == "eric-ctrl-bro" && params.PIPELINE_NAME == 'eea-adp-staging') || params.PIPELINE_NAME == 'eea-product-ci-meta-baseline-loop' }
            }
            steps {
                loggedStage(){
                    initBROTestVariables()
                }
            }
        }

        stage('Execute BRO tests') {
            when {
                expression { (params.CHART_NAME == "eric-ctrl-bro" && params.PIPELINE_NAME == 'eea-adp-staging') || params.PIPELINE_NAME == 'eea-product-ci-meta-baseline-loop' }
            }
            steps {
                loggedStage(){
                    executeBROTests(stageResults)
                }
            }
        }

        stage('init UTF Test Variables') {
            steps {
                loggedStage() {
                    initTestVariables(stageResults)
                }
            }
        }

        stage('Pre-activites after deployment') {
            steps {
                loggedStage() {
                    runPreActivitiesAfterDeployment(stageResults)
                }
            }
            post {
                always {
                    postPreActivitiesAfterDeployment(stageCommentList)
                }
            }
        }

        stage('Testing after deployment') {
            when {
                expression { stageResults.find{ it.key == "${PREVIOUS_STAGE}" }?.value == "SUCCESS" }
            }
            steps {
                testingAfterDeployment(stageResults,stageCommentList)
            }
            post {
                always {
                    script {
                        archiveArtifacts artifacts: "stage_${UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                        archiveArtifacts artifacts: "stage_${UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                    }
                }
            }
        }

        stage('Decisive robot Tests') {
            when {
                expression { params.RUN_ROBOT_TESTS == true }
            }
            steps {
                loggedStage(){
                    runRvRobot('decisive')
                }
            }
        }

        stage('Non_decisive Robot Tests') {
            when {
                expression { params.PIPELINE_NAME == 'eea-product-ci-meta-baseline-loop' && params.RUN_ROBOT_TESTS == true }
            }
            steps {
                loggedStage(){
                    runRvRobot('non_decisive')
                }
            }
        }

        stage('UTF Post-activities') { // MUST BE SAME AS UTF_POST_ACTIVITIES_TEST_NAME
            steps {
                utfPostActivities(stageCommentList)
            }
            post {
                always {
                    script {
                        archiveArtifacts artifacts: "stage_${UTF_POST_ACTIVITIES_TEST_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                    }
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: "watches_count_indicators.log", allowEmptyArchive: true
            finalPostAlways(stageCommentList, stageResultsInfo)
        }
        cleanup {
            cleanWs()
        }
    }
}


void checkBuildParameters() {
    script {
        currentBuild.description = ""
        if (!params.CLUSTER_NAME) {
            currentBuild.result = 'ABORTED'
            error("CLUSTER_NAME must be specified")
        }
        if ( clusterLockUtils.getResourceLabelStatus( env.system ) == "FREE" ){
            error("${CLUSTER_NAME} is not locked or reserved")
        }

        if (!params.INT_CHART_VERSION_PRODUCT) {
            currentBuild.result = 'ABORTED'
            error("INT_CHART_VERSION_PRODUCT must be specified")
        }
        if (!params.INT_CHART_NAME_PRODUCT) {
            error("INT_CHART_NAME should be specified!")
        }
        if (!params.INT_CHART_REPO_PRODUCT) {
            error("INT_CHART_REPO should be specified!")
        }
        def upstreamCause = currentBuild.rawBuild.getCause(hudson.model.Cause$UpstreamCause)
        if (!params.DEPLOYMENT_TYPE) {
            if ( !upstreamCause) {
                error("DEPLOYMENT_TYPE is not specified.")
            } else if ( upstreamCause.upstreamProject.contains('upgrade') ) {
                env.DEPLOYMENT_TYPE = "UPGRADE"
            } else {
                env.DEPLOYMENT_TYPE = "INSTALL"
            }
        }
        echo "Deployment type: ${env.DEPLOYMENT_TYPE}"
        if ( env.DEPLOYMENT_TYPE == "INSTALL" ) {
            env.UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_META_FILTER = "${env.UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_META_FILTER_INSTALL}"
            env.UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER = "${env.UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER_INSTALL}"
            env.UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_META_FILTER = "${env.UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_META_FILTER_INSTALL}"
            env.UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER = "${env.UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER_INSTALL}"
            env.UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_META_FILTER = "${env.UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_META_FILTER_INSTALL}"
            env.UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER = "${env.UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER_INSTALL}"
            env.UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_META_FILTER = "${env.UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_META_FILTER_INSTALL}"
            env.UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER = "${env.UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER_INSTALL}"
        } else if ( env.DEPLOYMENT_TYPE == "UPGRADE" ) {
            env.UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_META_FILTER = "${env.UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_META_FILTER_UPGRADE}"
            env.UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER = "${env.UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER_UPGRADE}"
            env.UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_META_FILTER = "${env.UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_META_FILTER_UPGRADE}"
            env.UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER = "${env.UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER_UPGRADE}"
            env.UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_META_FILTER = "${env.UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_META_FILTER_UPGRADE}"
            env.UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER = "${env.UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER_UPGRADE}"
            env.UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_META_FILTER = "${env.UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_META_FILTER_UPGRADE}"
            env.UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER = "${env.UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER_UPGRADE}"
        } else {
            error("${env.DEPLOYMENT_TYPE} is not supported.")
        }
    }
}

void checkoutCnintMaster() {
    script {
        gitcnint.checkout('master', '')
        checkoutGitSubmodules()
        sh "echo 'CLUSTER='${env.CLUSTER_NAME} > artifact.properties"
    }
}

void checkoutMeta() {
    script {
        echo "params.INT_CHART_VERSION_META: \"${params.INT_CHART_VERSION_META}\""
        if ( params.INT_CHART_VERSION_META.trim() && !params.META_GERRIT_REFSPEC ) {
            if ( params.INT_CHART_VERSION_META.split('-').size() == 2 ) {
                gitmeta.checkoutRefSpec("${params.INT_CHART_VERSION_META}", "FETCH_HEAD", 'project-meta-baseline')
            } else {
                echo "params.INT_CHART_VERSION_META has hash, therefore project-meta-baseline master will be checked out"
                gitmeta.checkout('master', 'project-meta-baseline')
            }
        } else if ( params.META_GERRIT_REFSPEC ) {
            echo "META_GERRIT_REFSPEC: ${params.META_GERRIT_REFSPEC} is going to be checked out."
            gitmeta.checkoutRefSpec("${params.META_GERRIT_REFSPEC}", "FETCH_HEAD", 'project-meta-baseline')
        } else {
            echo "params.INT_CHART_VERSION_META is empty, therefore project-meta-baseline master will be checked out"
            gitmeta.checkout('master', 'project-meta-baseline')
        }
        dir('project-meta-baseline') {
            checkoutGitSubmodules()
        }

    }
}

def rulesetChangeCheckout(){
    script {
        gitcnint.fetchAndCherryPick('EEA/cnint', "${params.GERRIT_REFSPEC}")
    }
}

void archiveTechnicalsRulesetDirs() {
    dir('adp-app-staging'){
        withCredentials([usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GIT_USER', passwordVariable: 'PASSWORD' )]) {
            script {
                gitadp.archiveDir('EEA/adp-app-staging', 'HEAD:technicals/')
            }
        }
    }
    dir('rulesets') {
        withCredentials([usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GIT_USER', passwordVariable: 'PASSWORD')]) {
            script {
                gitadp.archiveDir('EEA/adp-app-staging', 'HEAD:rulesets/')
            }
        }
    }
}

void initVarsAndGetCharts() {
    script {
        withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                        usernamePassword(credentialsId: 'ECEAART_SEROGIC_API_KEY', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
                        usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
                        string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                        string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                        file(credentialsId: env.CLUSTER_NAME, variable: 'KUBECONFIG')
        ]) {
            withEnv(["HELM_TIMEOUT=3800",
                "INT_CHART_NAME=${env.INT_CHART_NAME_PRODUCT}",
                "INT_CHART_REPO=${env.INT_CHART_REPO_PRODUCT}",
                "INT_CHART_VERSION=${env.INT_CHART_VERSION_PRODUCT}"
            ]) {
                sh './bob/bob -r ruleset2.0.yaml init'
                // Download and extract the Integration helm chart
                sh './bob/bob -r ruleset2.0.yaml k8s-test-without-post-install:download-extract-chart'
            }
        }
    }
}

def initBROTestVariables() {
    script {
        utf.initUtfTestVariables(globalVars, "adp-app-staging-full-checkout/technicals/utf_test_parameters.json")
    }
}

def executeBROTests(def stageCommentList) {
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



def initTestVariables(stageResults) {
    catchError(buildResult: 'FAILURE', stageResult: 'FAILURE' ) {
        script {
            PREVIOUS_STAGE = "${STAGE_NAME}"
            try{
                utf.initUtfTestVariables(globalVars, "adp-app-staging-full-checkout/technicals/utf_test_parameters.json")
                stageResults."${STAGE_NAME}" = "SUCCESS"
            } catch(err) {
                stageResults."${STAGE_NAME}" = "FAILURE"
                echo "Caught: ${err}"
                error "${STAGE_NAME} FAILED".toUpperCase()
            }
        }
    }
}

void runPreActivitiesAfterDeployment(stageResults){
    script {
        if ( env.DEPLOYMENT_TYPE == "INSTALL" ) {
            runPreActivitiesAfterInstall(stageResults)
        } else if ( env.DEPLOYMENT_TYPE == "UPGRADE" ) {
            runPreActivitiesAfterUpgrade(stageResults)
        }
    }
}



void runPreActivitiesAfterInstall(stageResults) {
    script {
        catchError(buildResult: 'FAILURE', stageResult: 'FAILURE' ) {
            PREVIOUS_STAGE = "${STAGE_NAME}"
            try {
                def utf_pre_activities = [name: "${UTF_PRE_ACTIVITIES_TEST_NAME}", build_result: 'FAILURE', stage_result: 'FAILURE', exec_id: "${UTF_PRE_ACTIVITIES_TEST_EXECUTION_ID}", metafilter: "${env.UTF_PRE_ACTIVITIES_META_FILTER}", timeout: "${UTF_PRE_ACTIVITIES_TEST_TIMEOUT}", logfile: "${UTF_PRE_ACTIVITIES_TEST_LOGFILE}"]
                utf.execUtfTest(utf_pre_activities)
                stageResults."${STAGE_NAME}" = "SUCCESS"
            } catch(err) {
                stageResults."${STAGE_NAME}" = "FAILURE"
                echo "Caught: ${err}"
                error "${STAGE_NAME} FAILED".toUpperCase()
            }
        }
    }

}

void runPreActivitiesAfterUpgrade(stageResults) {
    script {
        catchError(buildResult: 'FAILURE', stageResult: 'FAILURE' ) {
            PREVIOUS_STAGE = "${STAGE_NAME}"
            try {
                def data_load_check_after_upgrade = [name: "${UTF_PRE_ACTIVITIES_CHECK_NAME}", build_result: 'FAILURE', stage_result: 'FAILURE', exec_id: "${UTF_PRE_ACTIVITIES_CHECK_TEST_EXECUTION_ID}", metafilter: "${env.UTF_PRE_ACTIVITIES_CHECK_META_FILTER}", timeout: "${UTF_PRE_ACTIVITIES_CHECK_TEST_TIMEOUT}", logfile: "${UTF_PRE_ACTIVITIES_CHECK_LOGFILE}"]
                utf.execUtfTest(data_load_check_after_upgrade)
                stageResults."${STAGE_NAME}" = "SUCCESS"
            } catch(err) {
                stageResults."${STAGE_NAME}" = "FAILURE"
                echo "Caught: ${err}"
                error "${STAGE_NAME} FAILED".toUpperCase()
            }
        }
    }
}

void postPreActivitiesAfterDeployment(stageCommentList){
    script {
        clusterLogUtilsInstance.getResourceCapacity(env.CLUSTER_NAME)
        if ( env.DEPLOYMENT_TYPE == "INSTALL" ) {
            archiveArtifacts artifacts: "stage_${UTF_PRE_ACTIVITIES_TEST_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
            stageCommentList[env.UTF_PRE_ACTIVITIES_TEST_NAME] = [" <a href=\"${env.BUILD_URL}/artifact/${env.UTF_PRE_ACTIVITIES_TEST_LOGFILE}\">${env.UTF_PRE_ACTIVITIES_TEST_LOGFILE}</a>"]
        } else if ( env.DEPLOYMENT_TYPE == "UPGRADE" ) {
            archiveArtifacts artifacts: "stage_${UTF_PRE_ACTIVITIES_CHECK_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
            stageCommentList[env.UTF_PRE_ACTIVITIES_CHECK_NAME] = [" <a href=\"${env.BUILD_URL}/artifact/${env.UTF_PRE_ACTIVITIES_CHECK_LOGFILE}\">${env.UTF_PRE_ACTIVITIES_CHECK_LOGFILE}</a>"]
        }
    }
}

void testingAfterDeployment(stageResults,stageCommentList) {
    catchError(buildResult: 'FAILURE', stageResult: 'FAILURE' ) {
        script {
            PREVIOUS_STAGE = "${STAGE_NAME}"
            try {
                def cucumber_tests;
                if ( params.PIPELINE_NAME == 'eea-product-ci-meta-baseline-loop' ) {
                    cucumber_tests = [[name: "${UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_NAME}", build_result: 'FAILURE', stage_result: 'FAILURE', exec_id: "${UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_EXECUTION_ID}", metafilter: "${UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_META_FILTER}", timeout: "${UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_TIMEOUT}", logfile: "${UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_LOGFILE}", report_folder: "${UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER}"],
                                    [name: "${UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_NAME}", build_result: 'FAILURE', stage_result: 'FAILURE', exec_id: "${UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_EXECUTION_ID}", metafilter: "${UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_META_FILTER}", timeout: "${UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_TIMEOUT}", logfile: "${UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_LOGFILE}", report_folder: "${UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER}"],
                                    [name: "${UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_NAME}", build_result: 'SUCCESS', stage_result: 'FAILURE', exec_id: "${UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_EXECUTION_ID}", metafilter: "${UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_META_FILTER}", timeout: "${UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_TIMEOUT}", logfile: "${UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_LOGFILE}", report_folder: "${UTF_NONDECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER}"],
                                    [name: "${UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_NAME}", build_result: 'SUCCESS', stage_result: 'FAILURE', exec_id: "${UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_EXECUTION_ID}", metafilter: "${UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_META_FILTER}", timeout: "${UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_TIMEOUT}", logfile: "${UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_LOGFILE}", report_folder: "${UTF_NONDECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER}"]]
                }
                else if ( params.PIPELINE_NAME == 'eea-adp-staging' ) {
                    cucumber_tests = [[name: "${UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_NAME}", build_result: 'FAILURE', stage_result: 'FAILURE', exec_id: "${UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_EXECUTION_ID}", metafilter: "${UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_META_FILTER}", timeout: "${UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_TIMEOUT}", logfile: "${UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_LOGFILE}", report_folder: "${UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER}"]]
                } else {
                    cucumber_tests = [[name: "${UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_NAME}", build_result: 'FAILURE', stage_result: 'FAILURE', exec_id: "${UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_EXECUTION_ID}", metafilter: "${UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_META_FILTER}", timeout: "${UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_TIMEOUT}", logfile: "${UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_LOGFILE}", report_folder: "${UTF_DECISIVE_NX1_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER}"],
                                    [name: "${UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_NAME}", build_result: 'FAILURE', stage_result: 'FAILURE', exec_id: "${UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_EXECUTION_ID}", metafilter: "${UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_META_FILTER}", timeout: "${UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_TIMEOUT}", logfile: "${UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_LOGFILE}", report_folder: "${UTF_DECISIVE_BATCH_STAGING_UTF_CUCUMBER_TESTS_REPORT_FOLDER}"]]
                }
                utf.execUtfTests(cucumber_tests)
                utf.generateUtfTestReportLinks(cucumber_tests)
                utf.generateSumReportLinks(cucumber_tests)
                cucumber_tests.each { test ->
                    stageCommentList[test.name] = [" <a href=\"${env.BUILD_URL}/artifact/${test.logfile}\">${test.logfile}</a>"]
                }
                stageResults."${STAGE_NAME}" = "SUCCESS"
            } catch(err) {
                stageResults."${STAGE_NAME}" = "FAILURE"
                echo "Caught: ${err}"
                error "${STAGE_NAME} FAILED".toUpperCase()
            }
        }
    }
}

void runRvRobot(String robotTags) {
    def result = robotTags == 'decisive' ? 'FAILURE' : 'SUCCESS'
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

void utfPostActivities(stageCommentList) {
    script {
        def utf_post_activitie = [name: "${UTF_POST_ACTIVITIES_TEST_NAME}", build_result: 'SUCCESS', stage_result: 'FAILURE', exec_id: "${UTF_POST_ACTIVITIES_TEST_EXECUTION_ID}", metafilter: "${env.UTF_POST_ACTIVITIES_META_FILTER}", timeout: "${UTF_POST_ACTIVITIES_TEST_TIMEOUT}", logfile: "${UTF_POST_ACTIVITIES_TEST_LOGFILE}"]
        utf.execUtfTest(utf_post_activitie)
        stageCommentList[utf_post_activitie.name] = [" <a href=\"${env.BUILD_URL}/artifact/${utf_post_activitie.logfile}\">${utf_post_activitie.logfile}</a>"]
    }
}

def finalPostAlways(def stageCommentList, def stageResultsInfo){
    env.GERRIT_MSG = "Build result " + env.BUILD_URL + ": " + currentBuild.result
    if ( env.GERRIT_REFSPEC ) {
        sendMessageToGerrit(env.GERRIT_REFSPEC, env.GERRIT_MSG)
    }
    cmutils.generateStageResultsHtml(stageCommentList,stageResultsInfo)
}