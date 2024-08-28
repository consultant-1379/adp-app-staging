@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import com.ericsson.eea4.ci.CommonUtils
import com.ericsson.eea4.ci.CiDashboard

@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitmeta = new GitScm(this, 'EEA/project-meta-baseline')
@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def cmutils = new CommonUtils(this)
@Field def dashboard = new CiDashboard(this)

pipeline {
    agent {
        node {
            label 'productci'
        }
    }
    options {
        skipDefaultCheckout()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(daysToKeepStr: '7', artifactDaysToKeepStr: "7"))
    }
    parameters {
        string(name: 'CHART_NAME', description: 'Chart name e.g.: eric-ms-b', defaultValue: '')
        string(name: 'CHART_REPO', description: 'Chart repo e.g.: https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm', defaultValue: '')
        string(name: 'CHART_VERSION', description: 'Chart version e.g.: 1.0.0-1', defaultValue: '')
        string(name: 'GERRIT_REFSPEC',  description: 'Gerrit Refspec of the project-meta-baseline git repo e.g.: refs/changes/49/18108849/3', defaultValue: '')
        string(name: 'SPINNAKER_TRIGGER_URL', description: 'Spinnaker pipeline triggering url', defaultValue: '')
        string(name: 'SPINNAKER_ID', description: "The spinnaker execution's id", defaultValue: '')
        string(name: 'PIPELINE_NAME', description: 'Spinnaker pipeline name', defaultValue: 'eea-product-ci-meta-baseline-loop')
        string(name: 'EVALUATION', description: 'evaluation variable', defaultValue: 'false')
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

        stage('Set LATEST_GERRIT_REFSPEC') {
            when {
                expression { env.GERRIT_REFSPEC }
            }
            steps {
                script {
                    env.GERRIT_CHANGE_NUMBER = gitmeta.getCommitIdFromRefspec(env.GERRIT_REFSPEC)
                    echo "env.GERRIT_CHANGE_NUMBER=${env.GERRIT_CHANGE_NUMBER}"

                    env.LATEST_GERRIT_REFSPEC = gitmeta.getCommitRefSpec(env.GERRIT_CHANGE_NUMBER)
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

        stage('Validate patchset'){
            when {
                expression { params.GERRIT_REFSPEC }
            }
            steps {
                script {
                    env.REFSPEC_TO_VALIDATE = env.GERRIT_REFSPEC
                    def reviewRules = readYaml file: "technicals/meta_reviewers.yaml"
                    def changeOwner = gitmeta.getGerritQueryJson(env.GERRIT_REFSPEC, '')?.owner?.username
                    if (changeOwner != 'eceagit') {
                        try {
                            env.REFSPEC_TO_VALIDATE = gitadp.checkAndGetCommitLastPatchSetReviewed(env.REFSPEC_TO_VALIDATE,reviewRules)
                        }
                        catch (Exception e) {
                            sendMessageToGerrit(env.GERRIT_REFSPEC, e.message)
                            error("""FAILURE: Validate patchset failed with exception: ${e.class.name},message:  ${e.message}
                            """)
                        }
                    } else {
                        echo "Change owner is technical user, patchset validation SKIPPED."
                    }
                    env.GERRIT_REFSPEC = env.REFSPEC_TO_VALIDATE
                }
            }
        }

        stage('Checkout meta') {
            steps {
                script {
                    gitmeta.checkout(env.MAIN_BRANCH, '')
                }
           }
        }

        stage('Fetch And Cherry Pick changes') {
            when {
                expression { env.GERRIT_REFSPEC }
            }
            steps{
                script{
                    gitmeta.fetchAndCherryPick("EEA/project-meta-baseline", "${env.GERRIT_REFSPEC}")
                }
            }
        }

        stage('Prepare') {
            steps {
                checkoutGitSubmodules()
            }
        }

        stage('Clean') {
            steps {
                sh './bob/bob clean'
            }
        }

        stage('Checkout dimtool dependencies from the cnint') {
            steps {
                dir('bob-rulesets') {
                    script {
                        gitcnint.archiveDir('EEA/cnint', 'HEAD:bob-rulesets/')
                        gitcnint.archiveFile('EEA/cnint', 'HEAD ruleset2.0.yaml')
                        gitcnint.archiveFile('EEA/cnint', 'HEAD docker_config.json.template')
                        sh 'mv ruleset2.0.yaml ../cnint_ruleset2.0.yaml'
                        sh 'cp docker_config.json.template ../docker_config.json.template'
                    }
                }
                dir('dimensioning-tool') {
                    script {
                        gitcnint.archiveDir('EEA/cnint', 'HEAD:dimensioning-tool/')
                    }
                }
                dir('dimensioning-tool-ci') {
                    script {
                        gitcnint.archiveDir('EEA/cnint', 'HEAD:dimensioning-tool-ci/')
                    }
                }
                dir('cnint_eric-eea-int-helm-chart') {
                    script {
                        gitcnint.archiveDir('EEA/cnint', 'HEAD:eric-eea-int-helm-chart/')
                    }
                }
            }
        }

        stage('Checkout meta master') {
            steps {
                script {
                    gitmeta.checkout(env.MAIN_BRANCH, 'gitmeta_master')
                }
           }
        }

        stage('Prepare Helm Chart') {
            steps {
                // Generate integration helm chart
                withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                    sh 'bob/bob prepare-meta'
                }
            }
        }

        stage('Get dataset-version from meta baseline') {
            steps {
                script {
                    env.DATASET_NAME = cmutils.getDatasetVersion(".bob/eric-eea-ci-meta-helm-chart_tmp/eric-eea-ci-meta-helm-chart","values.yaml")
                    sh "echo 'DATASET_NAME=${env.DATASET_NAME}' >> artifact.properties"
                    env.REPLAY_SPEED = cmutils.getDatasetReplaySpeed(".bob/eric-eea-ci-meta-helm-chart_tmp/eric-eea-ci-meta-helm-chart","values.yaml")
                    sh "echo 'REPLAY_SPEED=${env.REPLAY_SPEED}' >> artifact.properties"
                    env.META_BASELINE_CHART_VERSION = cmutils.getChartVersion(".bob/eric-eea-ci-meta-helm-chart_tmp/eric-eea-ci-meta-helm-chart", "Chart.yaml")
                    readProperties(file: 'artifact.properties').each {key, value -> env['PREPARE_' +key] = value }
                    sh "echo 'META_BASELINE_CHART_VERSION=${env.PREPARE_INT_CHART_VERSION}' >> artifact.properties"
                    env.UTF_CHART_NAME = cmutils.extractSubChartData("eric-eea-utf-application", "name", ".bob/eric-eea-ci-meta-helm-chart_tmp/eric-eea-ci-meta-helm-chart","Chart.yaml")
                    sh "echo 'UTF_CHART_NAME=${env.UTF_CHART_NAME}' >> artifact.properties"
                    env.UTF_CHART_REPO = cmutils.extractSubChartData("eric-eea-utf-application", "repository", ".bob/eric-eea-ci-meta-helm-chart_tmp/eric-eea-ci-meta-helm-chart","Chart.yaml")
                    sh "echo 'UTF_CHART_REPO=${env.UTF_CHART_REPO}' >> artifact.properties"
                    env.UTF_CHART_VERSION = cmutils.extractSubChartData("eric-eea-utf-application", "version", ".bob/eric-eea-ci-meta-helm-chart_tmp/eric-eea-ci-meta-helm-chart","Chart.yaml")
                    sh "echo 'UTF_CHART_VERSION=${env.UTF_CHART_VERSION}' >> artifact.properties"
                }
            }
        }

        stage('Compare UTF Application versions from a new drop and from the meta baseline') {
            when {
                allOf {
                    expression { params.EVALUATION == "true" }
                    expression { params.CHART_NAME == "eric-eea-utf-application" }
                }
            }
            steps {
                script {
                    def chartVersion = env.CHART_VERSION.tokenize('-')[0].tokenize('.').collect { it as Integer }
                    def utfChartVersion = env.UTF_CHART_VERSION.tokenize('-')[0].tokenize('.').collect { it as Integer }
                    echo "Current UTF Application chart version: ${env.UTF_CHART_VERSION}\n - MAJOR_NUMBER:" + utfChartVersion[0] + "\n - MINOR_NUMBER:" + utfChartVersion[1] + "\n - PATCH_NUMBER:" + utfChartVersion[2]
                    echo "Incoming UTF Application chart version: ${env.CHART_VERSION}\n - MAJOR_NUMBER: ${chartVersion[0]}\n - MINOR_NUMBER: ${chartVersion[1]}\n - PATCH_NUMBER: ${chartVersion[2]}"
                    if  (chartVersion[0] < utfChartVersion[0]) {
                        error("""FAILURE: The major digit of UTF Application version ${env.CHART_VERSION} from a new drop is lower than UTF Application version ${env.UTF_CHART_VERSION} in the meta chart""")
                    }
                    else if (chartVersion[0] == utfChartVersion[0] && chartVersion[1] < utfChartVersion[1]) {
                        error("""FAILURE: The minor digit of UTF Application version ${env.CHART_VERSION} from a new drop is lower than UTF Application version in the meta chart ${env.UTF_CHART_VERSION}""")
                    }
                    else if (chartVersion[0] == utfChartVersion[0] && chartVersion[1] == utfChartVersion[1] && chartVersion[2] < utfChartVersion[2] ) {
                        error("""FAILURE: The patch digit of UTF Application version ${env.CHART_VERSION} from a new drop is lower than UTF Application version in the meta chart ${env.UTF_CHART_VERSION}""")
                    }
                    else if (chartVersion[0] == utfChartVersion[0] && chartVersion[1] == utfChartVersion[1] && chartVersion[2] == utfChartVersion[2]) {
                        error("""FAILURE: The UTF Application version ${env.CHART_VERSION} from a new drop is equal the one from meta baseline ${env.UTF_CHART_VERSION}""")
                    }
                    else {
                        echo "The UTF Apllication version ${env.CHART_VERSION} is higher than version from meta baseline ${env.UTF_CHART_VERSION}"
                    }
                }
            }
        }

        stage("Run dimtool") {
            steps {
                script {
                    def data = readYaml file: 'cnint_eric-eea-int-helm-chart/Chart.yaml'
                    env.INT_CHART_NAME = data.name
                    env.INT_CHART_VERSION = data.version
                    env.INT_CHART_REPO = "https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/"

                    echo "INT_CHART_NAME=${INT_CHART_NAME}"
                    echo "INT_CHART_REPO=https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/"
                    echo "INT_CHART_VERSION=${INT_CHART_VERSION}"

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

                    copyArtifacts filter: '*.log, dimToolOutput.properties', fingerprintArtifacts: true, projectName: "dimensioning-tool-output-generator", selector: specific("${dimensioning_output_generator_job.number}")
                    readProperties(file: 'dimToolOutput.properties').each {key, value -> env[key] = value }

                    sh "echo 'DIMTOOL_OUTPUT_REPO_URL=${DIMTOOL_OUTPUT_REPO_URL}' >> artifact.properties"
                    sh "echo 'DIMTOOL_OUTPUT_REPO=${DIMTOOL_OUTPUT_REPO}' >> artifact.properties"
                    sh "echo 'DIMTOOL_OUTPUT_NAME=${DIMTOOL_OUTPUT_NAME}' >> artifact.properties"

                    archiveArtifacts artifacts: "*.log, dimToolOutput.properties", allowEmptyArchive: true
                }
            }
        }

        stage('Is dataset changed') {
            steps {
                script {
                    if ( env.GERRIT_REFSPEC ) {
                        changedFiles = getGerritQueryPatchsetChangedFiles("${env.GERRIT_REFSPEC}")
                        changedFiles.each { file ->
                            print file
                            def dataset_information_changed=false
                            if (file == 'eric-eea-ci-meta-helm-chart/values.yaml') {
                                def masterDataset =  readYaml file: "gitmeta_master/eric-eea-ci-meta-helm-chart/values.yaml"
                                def changeDataset =  readYaml file: "eric-eea-ci-meta-helm-chart/values.yaml"
                                if ((masterDataset."dataset-information"."dataset-version" != changeDataset."dataset-information"."dataset-version") || (masterDataset."dataset-information"."replay-speed" != changeDataset."dataset-information"."replay-speed") ||  (masterDataset."dataset-information"."replay-count" != changeDataset."dataset-information"."replay-count")) {
                                    dataset_information_changed=true
                                }
                                echo "${dataset_information_changed}"
                                sh "echo 'DATASET_INFORMATION_CHANGED=${dataset_information_changed}' >> artifact.properties"
                            }
                        }
                    } else {
                        sh "echo 'DATASET_INFORMATION_CHANGED=false' >> artifact.properties"
                    }
                }
            }
        }
        stage('Check product version compatibility') {
            steps{
                dir('.bob/eric-eea-ci-meta-helm-chart_tmp'){
                    script{
                        def intChartVersion = sh(script:"""grep "INT_CHART_VERSION=" $WORKSPACE/artifact.properties |cut -d= -f2""",returnStdout: true ).trim()
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
                    if (['eea-product-ci-meta-baseline-loop'].contains(params.PIPELINE_NAME)) {
                        dashboard.initAppDashboardExecution()
                    }
                    if (env.GERRIT_REFSPEC) {
                        sh "echo 'REFSPEC_TO_VALIDATE=${env.REFSPEC_TO_VALIDATE}' >> artifact.properties"
                    }
                    archiveArtifacts artifacts: "artifact.properties", allowEmptyArchive: true
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
