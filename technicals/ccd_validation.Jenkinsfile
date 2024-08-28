@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.ClusterLockUtils
import com.ericsson.eea4.ci.Notifications
import com.ericsson.eea4.ci.GlobalVars
import groovy.transform.Field
import com.ericsson.eea4.ci.CommonUtils

@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def clusterLockUtils =  new ClusterLockUtils(this)
@Field def notif = new Notifications(this)
@Field def gitmeta = new GitScm(this, 'EEA/project-meta-baseline')
@Field def cmutils = new CommonUtils(this)

def testResultMap = [:]

pipeline {
    agent {
        node {
            label 'productci'
        }
    }
    options {
        skipDefaultCheckout()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(daysToKeepStr: "7"))
    }
    parameters {
        booleanParam(name: 'DRY_RUN', defaultValue: false)
        string(name: 'CLUSTER_NAME', description: 'Locked cluster for install a new nersion of CCD', defaultValue: '')
        string(name: 'CCD_VERSION', description: 'CCD version which we want to test. please check possible values from https://seliius27190.seli.gic.ericsson.se:8443/job/rv-ccd-install/  CCD_VERSION', defaultValue: '')
        string(name: 'ROOK_VERSION', description: 'ROOK version to install', defaultValue: '')
        string(name: 'INT_CHART_VERSION', description: 'Chart version e.g.: 1.0.0-1', defaultValue: 'latest')
        string(name: 'NUM_RUN', description: 'Show how many test runs are needed', defaultValue: '3')
        booleanParam(name: 'SKIP_INSTALL', description: 'Use for skip Install test pipeline', defaultValue: false)
        booleanParam(name: 'SKIP_UPGRADE', description: 'Use for skip Upgrade test pipeline', defaultValue: false)
        choice(
            name: 'OS_INSTALL_METHOD',
            choices: [
                'parallel',
                'one-by-one'
            ],
            description: 'How to do the OS install when execute RV_CCI_INSTALL job'
        )
        string(name: 'GERRIT_REFSPEC', description: 'Gerrit Refspec of repo e.g.: refs/changes/82/13836482/2', defaultValue: '')
    }
    environment {
        CLUSTER_LABEL = 'ccd_validation'
        INT_CHART_NAME = 'eric-eea-int-helm-chart'
        INT_CHART_REPO = 'https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/'
        ABSOLUTE_URL = 'https://seliius27190.seli.gic.ericsson.se:8443/job/'
        REPORT_FILENAME = 'test_new_version_ccd.html'
        DIMENSIONING_OUTPUT_GENERATOR_JOB_NAME = 'dimensioning-tool-output-generator'
    }

    stages {
        stage('Params DryRun check') {
            when {
                expression { params.DRY_RUN == true }
            }
            steps {
                dryRun()
            }
        }

        stage('Run when run in Jenkins master'){
            when {
                expression { env.MAIN_BRANCH != 'master' }
            }
            steps {
                script {
                    dryRun()
                }
            }
        }

        stage('Check params') {
            steps {
                script {
                    if (!params.CCD_VERSION || !params.CLUSTER_NAME || !params.ROOK_VERSION) {
                        error "CLUSTER_NAME, CCD_VERSION and ROOK_VERSION input parameters are mandatory and should be specified!"
                    }
                }
            }
        }

        stage('Checkout cnint') {
            steps {
                script {
                    // GERRIT_REFSPEC param was added to checkout new docker images from exact commit to check if they work properly
                    if ( params.GERRIT_REFSPEC != '' ) {
                        gitcnint.checkoutRefSpec("${GERRIT_REFSPEC}", "FETCH_HEAD", "")
                    }else {
                        gitcnint.checkout("master", "")
                    }
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

        stage('Checkout meta') {
            steps {
                script {
                    gitmeta.checkout('master', 'project-meta-baseline')
                    dir('project-meta-baseline') {
                        env.UTF_CHART_NAME = cmutils.extractSubChartData("eric-eea-utf-application", "name", "eric-eea-ci-meta-helm-chart","Chart.yaml")
                        env.UTF_CHART_REPO = cmutils.extractSubChartData("eric-eea-utf-application", "repository", "eric-eea-ci-meta-helm-chart","Chart.yaml")
                        env.UTF_CHART_VERSION = cmutils.extractSubChartData("eric-eea-utf-application", "version", "eric-eea-ci-meta-helm-chart","Chart.yaml")
                        env.DATASET_NAME = cmutils.getDatasetVersion("eric-eea-ci-meta-helm-chart","values.yaml")
                        env.REPLAY_SPEED = cmutils.getDatasetReplaySpeed("eric-eea-ci-meta-helm-chart","values.yaml")
                        echo "UTF_CHART_NAME=${UTF_CHART_NAME}"
                        echo "UTF_CHART_REPO=${UTF_CHART_REPO}"
                        echo "UTF_CHART_VERSION=${UTF_CHART_VERSION}"
                        echo "DATASET_NAME=${DATASET_NAME}"
                        echo "REPLAY_SPEED=${REPLAY_SPEED}"
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

        stage('Check free cluster') {
            steps {
                script {
                    def isClusterFree = false

                    while(!isClusterFree) {
                        def statusCheck = clusterLockUtils.getResourceLabelStatus("${params.CLUSTER_NAME}")
                        if ( statusCheck == "FREE" ) {
                            isClusterFree = true
                            env.CLUSTER = "${params.CLUSTER_NAME}".replaceAll('_','-')
                        } else {
                            sleep(time: 15, unit: 'MINUTES' )
                        }
                    }
                }
            }
        }

        stage('Run cluster reinstall job') {
            steps {
                script {
                    if ( params.CCD_VERSION != '' ) {
                        retry(3) {
                            def clusterReinstall = build job: 'cluster-reinstall',
                            parameters: [
                                booleanParam(name: 'DRY_RUN', value: false),
                                stringParam(name: 'CLUSTER_NAME', value: params.CLUSTER_NAME),
                                stringParam(name: 'CCD_VERSION', value: params.CCD_VERSION),
                                stringParam(name: 'ROOK_VERSION', value: params.ROOK_VERSION),
                                stringParam(name: 'OS_INSTALL_METHOD', value: params.OS_INSTALL_METHOD),
                                stringParam(name: 'REFSPEC', value: params.REFSPEC),
                                stringParam(name: 'REINSTALL_LABEL', value: env.CLUSTER_LABEL),
                                booleanParam(name: 'EXECUTE_CLUSTER_VALIDATE', value: false)
                            ], wait: true
                            testResultMap["${clusterReinstall.projectName}-${clusterReinstall.number}"] = clusterReinstall.getResult()
                        }
                    } else {
                        error "CCD_VERSION parameter is empty"
                    }
                }
            }
        }

        stage('Generate and apply dimtool output file') {
            steps {
                script {
                    def dimensioning_output_generator_job = build job: "${DIMENSIONING_OUTPUT_GENERATOR_JOB_NAME}", parameters: [
                            stringParam(name: 'INT_CHART_NAME', value: env.INT_CHART_NAME),
                            stringParam(name: 'INT_CHART_REPO', value : env.INT_CHART_REPO),
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
                }
            }
        }

        stage('Run test pipeline') {
            steps {
                catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                    script {
                        def maxAttempts = params.NUM_RUN.toInteger()

                        for ( int attempt = 1; attempt <= maxAttempts; attempt++ ) {
                            println "Start ${attempt} test list"
                            def baselineInstallExitCode = 0
                            def installBuildResult;
                            def installClusterLogCollectorBuildResult;
                            def baselineInstall;
                            def upgradelBuildResult;
                            def upgradeClusterLogCollectorBuildResult;

                            if ( !params.SKIP_INSTALL ) {
                                try {
                                    installBuildResult = build job: "ccd-validation-eea-application-staging-batch",
                                    parameters: [
                                        booleanParam(name: 'DRY_RUN', value: false),
                                        stringParam(name: 'INT_CHART_NAME', value: env.INT_CHART_NAME),
                                        stringParam(name: 'INT_CHART_REPO', value: env.INT_CHART_REPO),
                                        stringParam(name: 'INT_CHART_VERSION', value: env.INT_CHART_VERSION),
                                        stringParam(name: 'GERRIT_REFSPEC', value: params.GERRIT_REFSPEC),
                                        stringParam(name: 'CLUSTER_LABEL', value: env.CLUSTER_LABEL),
                                        stringParam(name: 'DIMTOOL_OUTPUT_REPO_URL', value: env.DIMTOOL_OUTPUT_REPO_URL),
                                        stringParam(name: 'DIMTOOL_OUTPUT_REPO', value: env.DIMTOOL_OUTPUT_REPO),
                                        stringParam(name: 'DIMTOOL_OUTPUT_NAME', value: env.DIMTOOL_OUTPUT_NAME),
                                        booleanParam(name: 'SKIP_COLLECT_LOG', value: true),
                                        stringParam(name: 'CUSTOM_CLUSTER_LABEL', value: env.CLUSTER_LABEL),
                                        stringParam(name: 'HELM_AND_CMA_VALIDATION_MODE', value: "HELM_AND_CMA"),
                                        stringParam(name: 'BUILD_RESULT_WHEN_CMA_HEALTH_CHECK_FAILED', value: "FAILURE"),
                                        stringParam(name: 'BUILD_RESULT_WHEN_NELS_CHECK_FAILED', value: "FAILURE"),
                                        booleanParam(name: 'SKIP_CLEANUP', value: true)
                                    ], wait: true, propagate: false
                                    testResultMap["${installBuildResult.projectName}-${installBuildResult.number}"] = installBuildResult.getResult()
                                } catch (err) {
                                    echo "${STAGE_NAME} FAILED:\n${err}"
                                    testResultMap["${installBuildResult.projectName}-${installBuildResult.number}"] = installBuildResult.getResult()
                                }

                                try {
                                    installClusterLogCollectorBuildResult = build job: "cluster-logcollector",
                                    parameters: [
                                        booleanParam(name: 'DRY_RUN', value: false),
                                        stringParam(name: 'CLUSTER_NAME', value: env.CLUSTER),
                                        stringParam(name: 'AFTER_CLEANUP_DESIRED_CLUSTER_LABEL', value: env.CLUSTER_LABEL)
                                    ], wait: true
                                    testResultMap["${installClusterLogCollectorBuildResult.projectName}-${installClusterLogCollectorBuildResult.number}"] = installClusterLogCollectorBuildResult.getResult()
                                } catch (err) {
                                    echo "${STAGE_NAME} FAILED:\n${err}"
                                    testResultMap["${installClusterLogCollectorBuildResult.projectName}-${installClusterLogCollectorBuildResult.number}"] = installClusterLogCollectorBuildResult.getResult()
                                }
                            }

                            if ( !params.SKIP_UPGRADE ) {
                                try {
                                    baselineInstall = build job: "ccd-validation-eea-application-staging-product-baseline-install",
                                    parameters: [
                                        stringParam(name: 'CLUSTER_LABEL', value: env.CLUSTER_LABEL),
                                        stringParam(name: 'CUSTOM_CLUSTER_LABEL', value: env.CLUSTER_LABEL),
                                        booleanParam(name: 'SKIP_COLLECT_LOG', value: true)
                                    ], wait: true, propagate: false
                                    testResultMap["${baselineInstall.projectName}-${baselineInstall.number}"] = baselineInstall.getResult()
                                    if (baselineInstall.getResult() != 'SUCCESS') {
                                        baselineInstallExitCode = 1
                                    }
                                } catch (err) {
                                    testResultMap["${baselineInstall.projectName}-${baselineInstall.number}"] = baselineInstall.getResult()
                                    echo "${STAGE_NAME} FAILED:\n${err}"
                                    baselineInstallExitCode = 1
                                }

                                try {
                                    if ( baselineInstallExitCode == 0 ) {
                                        upgradelBuildResult = build job: "ccd-validation-eea-common-product-upgrade",
                                        parameters: [
                                            booleanParam(name: 'DRY_RUN', value: false),
                                            stringParam(name: 'INT_CHART_NAME_PRODUCT', value: env.INT_CHART_NAME),
                                            stringParam(name: 'INT_CHART_REPO_PRODUCT', value: env.INT_CHART_REPO),
                                            stringParam(name: 'INT_CHART_VERSION_PRODUCT', value: env.INT_CHART_VERSION),
                                            stringParam(name: 'GERRIT_REFSPEC',  value: params.GERRIT_REFSPEC),
                                            booleanParam(name: 'SKIP_COLLECT_LOG', value: true),
                                            booleanParam(name: 'SKIP_CLEANUP', value: true),
                                            stringParam(name: 'CUSTOM_CLUSTER_LABEL', value: env.CLUSTER_LABEL),
                                            stringParam(name: "UPGRADE_CLUSTER_LABEL", value: env.CLUSTER_LABEL)
                                        ], wait: true, propagate: false
                                        testResultMap["${upgradelBuildResult.projectName}-${upgradelBuildResult.number}"] = upgradelBuildResult.getResult()
                                    }
                                } catch (err) {
                                    echo "${STAGE_NAME} FAILED:\n${err}"
                                    testResultMap["${upgradelBuildResult.projectName}-${upgradelBuildResult.number}"] = upgradelBuildResult.getResult()
                                }

                                try {
                                    upgradeClusterLogCollectorBuildResult = build job: "cluster-logcollector",
                                    parameters: [
                                        stringParam(name: 'CLUSTER_NAME', value: env.CLUSTER),
                                        stringParam(name: 'AFTER_CLEANUP_DESIRED_CLUSTER_LABEL', value: env.CLUSTER_LABEL)
                                    ], wait: true
                                    testResultMap["${upgradeClusterLogCollectorBuildResult.projectName}-${upgradeClusterLogCollectorBuildResult.number}"] = upgradeClusterLogCollectorBuildResult.getResult()
                                } catch (err) {
                                    echo "${STAGE_NAME} FAILED:\n${err}"
                                    testResultMap["${upgradeClusterLogCollectorBuildResult.projectName}-${upgradeClusterLogCollectorBuildResult.number}"] = upgradeClusterLogCollectorBuildResult.getResult()
                                }
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
                if ( !params.DRY_RUN ) {
                    println "Create Report for Driving Channel"
                    def tableStatus
                    testResultMap.each { testRun, value ->
                        tableStatus += """
                        <tr>
                            <td>${testRun}</td>
                            <td>${value}</td>
                        </tr>
                        """
                    }
                    def htmlContent = """<!DOCTYPE html>
                        <html>
                            <head>
                            <style>
                            table {
                            font-family: arial, sans-serif;
                            border-collapse: collapse;
                            width: 50%;
                            }

                            td, th {
                            border: 1px solid #dddddd;
                            text-align: left;
                            padding: 8px;
                            }

                            tr:nth-child(even) {
                            background-color: #dddddd;
                            }
                            </style>
                            </head>

                            <body>
                            <h2>New version of CCD test report</h2>
                            <table>
                                <tr>
                                    <th>Name of job</th>
                                    <th>Result</th>
                                </tr>
                                ${tableStatus}
                            </table>
                            <br>
                            <p><a href="${env.BUILD_URL}" target="_blank">Link of Current Test new version of CCD Job</a></p>
                            </body>
                        </html>
                    """

                    // write content to file and archive it
                    writeFile(file: "${WORKSPACE}/${env.REPORT_FILENAME}", text: htmlContent)
                    archiveArtifacts artifacts: "*.html", allowEmptyArchive: true

                    //notify for Driving channel
                    notif.sendMail("${env.JOB_NAME} (${env.BUILD_NUMBER}) Test new version of CCD report","Result of tests: ${env.BUILD_URL}\n${htmlContent}","517d5a14.ericsson.onmicrosoft.com@emea.teams.ms", "text/html")

                    try {
                        echo "Execute cluster-logcollector job ... \n - cluster: ${env.CLUSTER}"
                        build job: "cluster-logcollector", parameters: [
                            stringParam(name: "CLUSTER_NAME", value: env.CLUSTER),
                            stringParam(name: 'LAST_LABEL_SET', value: env.LASTLABEL)
                            ], wait: true
                    }
                    catch (err) {
                        echo "Caught cluster-logcollector ERROR: ${err}"
                    }

                    if ( testResultMap.find{it.value == "FAILURE"} ) {
                        currentBuild.result = "FAILURE"
                        // if new version of CCD failed, we need to reinstall cluster with proper CCD version
                        retry(3) {
                            build job: 'cluster-reinstall',
                            parameters: [
                                booleanParam(name: 'DRY_RUN', value: false),
                                stringParam(name: 'CLUSTER_NAME', value: params.CLUSTER_NAME),
                                stringParam(name: 'OS_INSTALL_METHOD', value: params.OS_INSTALL_METHOD)
                            ], wait: true
                        }
                    }
                }
            }
        }
        cleanup {
            cleanWs()
        }
    }
}
