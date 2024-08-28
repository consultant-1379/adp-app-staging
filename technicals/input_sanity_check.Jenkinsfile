@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import hudson.Util;
import com.ericsson.eea4.ci.GlobalVars
import com.ericsson.eea4.ci.Artifactory
import com.ericsson.eea4.ci.SanityCheck
import com.ericsson.eea4.ci.SpinUtils
import com.ericsson.eea4.ci.MimerUtils
import com.ericsson.eea4.ci.CiDashboard
import com.ericsson.eea4.ci.Notifications
import com.ericsson.eea4.ci.CommonUtils

@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitcommoner = new GitScm(this, 'eea-release-team/commoner')
@Field def arm = new Artifactory(this, "https://arm.seli.gic.ericsson.se/", "API_TOKEN_EEA")
@Field def vars = new GlobalVars()
@Field def sc = new SanityCheck(this)
@Field def spin = new SpinUtils(this)
@Field def mimer = new MimerUtils(this)
@Field def dashboard = new CiDashboard(this)
@Field def notif = new Notifications(this)
@Field def cmutils = new CommonUtils(this)

Map checkMap = [:]
def whiteList = [:]
def stageResultsInfo = [:]
def stageCommentList = [:]

pipeline {
    options {
        ansiColor('xterm')
        buildDiscarder(logRotator(daysToKeepStr: "14", artifactDaysToKeepStr: "7"))
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
        hidden(name: 'GERRIT_REFSPEC', defaultValue: '', description: 'Legacy Gerrit Refspec of adp-app-staging chart git repo e.g.: refs/changes/87/4641487/1 IMPORTANT: this overwrites GERRIT_REFSPEC_ADP')
        string(name: 'GERRIT_REFSPEC_ADP', description: 'Gerrit Refspec of adp-app-staging chart git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'GERRIT_REFSPEC_CNINT', description: 'Gerrit Refspec of cnint chart git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'SPINNAKER_TRIGGER_URL', description: 'Spinnaker pipeline triggering url', defaultValue: '')
        string(name: 'REPOSITORY', description: 'ARM repository of the test results repo.', defaultValue: 'proj-eea-reports-generic-local')
        string(name: 'PIPELINE_NAME', description: "The spinnaker pipeline name", defaultValue: 'eea-application-staging')
        string(name: 'SPINNAKER_ID', description: "The spinnaker execution's id", defaultValue: '')
        choice(name: 'NON_PRA_INSTALL_EXEC_CHECK_WITH_HELM_BUILD_RESULT', choices: ['SUCCESS', 'FAILURE'], description: 'build result when non-pra helm install check fails')
        choice(name: 'NON_PRA_UPGRADE_EXEC_CHECK_WITH_HELM_BUILD_RESULT', choices: ['FAILURE', 'SUCCESS'], description: 'build result when non-pra helm upgrade check fails')
        choice(name: 'NON_PRA_INSTALL_EXEC_CHECK_WITH_CMA_BUILD_RESULT', choices: ['FAILURE', 'SUCCESS'], description: 'build result when non-pra CMA install check fails')
        choice(name: 'NON_PRA_UPGRADE_EXEC_CHECK_WITH_CMA_BUILD_RESULT', choices: ['SUCCESS', 'FAILURE'], description: 'build result when non-pra CMA upgrade check fails')
    }

    environment {
        REPORT_REPO_PATH = "https://arm.seli.gic.ericsson.se/artifactory/proj-eea-reports-generic-local"
        STAGES_STATUS_FILENAME = "stages_status.html"
        GERRIT_REFSPEC_ADP = "${env.GERRIT_REFSPEC ? env.GERRIT_REFSPEC :  params.GERRIT_REFSPEC_ADP}"
    }

    stages {
        stage('DryRun check') {
            when {
                expression { params.DRY_RUN == true }
            }
            steps {
                dryRun()
            }
        }

        stage('Gerrit message') {
            when {
                expression {env.GERRIT_REFSPEC_ADP}
            }
            steps {
                gerritMessage(env.GERRIT_REFSPEC_ADP)
            }
        }

        stage('Checkout adp-app-staging') {
            steps {
                checkoutAdp()
            }
        }

        stage('Checkout cnint') {
            steps {
                checkoutCnint()
            }
        }

        stage('Prepare') {
            steps {
                prepareCnint()
            }
        }

        stage('Replace + to - in Chart version') {
            steps {
                replacePlusToMinusInChartVersion()
            }
        }

        stage('Init') {
            steps {
                createLinksAndBuildDescriptions()
            }
        }

        stage('Clean') {
            steps {
                bobClean()
            }
        }

        stage('Read whitelist') { //Reading whitelist for checking the service is in
            steps {
                readWhitelist(checkMap,whiteList)
            }
        }
        stage('Non-PRA execution checks'){
            when {
                expression { params.PIPELINE_NAME == 'eea-application-staging' }
            }
            stages {
                stage('Get Spinaker Config') {
                    steps{
                        getNonPraSpinConfig()
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                        }
                    }
                }
                stage('Check HELM Install'){
                    steps{
                        doNonPraExecutionCheck(checkMap, env.NON_PRA_INSTALL_EXEC_CHECK_WITH_HELM_BUILD_RESULT, ["Staging Nx1 with Helm configuration" : "non_pra_with_helm_whitelist", "Install with Helm" : "non_pra_with_helm_whitelist"])
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                        }
                    }
                }

                stage('Check HELM Upgrade'){
                    steps{
                        doNonPraExecutionCheck(checkMap, env.NON_PRA_UPGRADE_EXEC_CHECK_WITH_HELM_BUILD_RESULT, ["Staging Nx1 Upgrade with Helm configuration" : "non_pra_upgrade_with_helm_whitelist", "Upgrade with Helm" : "non_pra_upgrade_with_helm_whitelist"])
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                        }
                    }
                }

                stage('Check CMA Install'){
                    steps{
                        doNonPraExecutionCheck(checkMap, env.NON_PRA_INSTALL_EXEC_CHECK_WITH_CMA_BUILD_RESULT, ["Staging Nx1" : "non_pra_whitelist", "Install" : "non_pra_whitelist"])
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                        }
                    }
                }

                stage('Check CMA Upgrade'){
                    steps{
                        doNonPraExecutionCheck(checkMap, env.NON_PRA_UPGRADE_EXEC_CHECK_WITH_CMA_BUILD_RESULT, ["Staging Nx1 Upgrade" : "non_pra_upgrade_whitelist", "Upgrade" : "non_pra_upgrade_whitelist"])
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                        }
                    }
                }
            }
        }

        stage('Evaluate documentation deliverables') {
            steps{
                evaluateDocumentationDeliverables(checkMap)
            }
            post {
                always {
                    archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                }
            }
        }

        stage('Input sanity check for helm chart and Docker images') {
            steps {
                inputSanityCheckForHelmChartAndDockerImages(checkMap)
            }
            post {
                always {
                    archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                }
            }
        }

        stage('Image Repo Checking') {
            steps {
                imageRepoChecking(checkMap)
            }
            post {
                always {
                    archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                }
            }
        }

        stage('CBO Age Report') {
            steps {
                cboAgeReport(checkMap)
            }
            post {
                always {
                    archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                }
            }
        }

        stage('Read properties') {
            steps {
                readPropertiesFile()
            }
        }

        stage('Test reports check') {
            steps {
                testReportCheck()
            }
            post {
                always {
                    archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                }
            }
        }

        stage('Security report checks') {
            steps {
                securityReportChecks(checkMap, stageCommentList)
            }
            post {
                always {
                    archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                }
            }
        }

        stage('Release documentation validation') {
            steps {
                releaseDocumentationValidation(checkMap)
            }
            post {
                always {
                    archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                }
            }

        }

        stage('Input sanity check for sonarqube') {
            steps {
                inputSanityCheckForSonarQube(checkMap['in_sonarqube_report_config_whitelist'])
            }
            post {
                always {
                    archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                }
            }
        }

        stage('Interface coverage report check') {
            steps {
                interfaceCoverageReportCheck(checkMap)
            }
            post {
                always {
                    archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                }
            }
        }

        stage('Service Level CI test reports validation') {
            steps {
                serviceLevelCiTestReportsValidation(checkMap)
            }
            post {
                always {
                    archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                }
            }
        }

        stage('CRDs check in service helm charts') {
            steps {
                CRDsCheckInServiceHelmCharts(checkMap)
            }
            post {
                always {
                    archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                }
            }
        }

        stage('Validate microservice in mimer') {
            steps {
                productVersionMimerCheck()
            }
            post {
                always {
                    archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                }
            }
        }

        stage('Notification change in whitelist') {
            when {
                expression {env.GERRIT_REFSPEC_ADP}
            }
            steps {
                notificationChangeInWhitelist(whiteList)
            }
        }
    }
    post {
        always {
            postStageAlways(stageCommentList,stageResultsInfo)
        }
        failure {
            postStageFailure()
        }
        success {
            postStageSuccess()
        }
        cleanup {
            cleanWs()
        }
    }
}

def gerritMessage(def REFSPEC) {
    script {
        sendMessageToGerrit(REFSPEC, "Build Started ${BUILD_URL}")
    }
}

def checkoutAdp(){
    script {
        gitadp.sparseCheckout("technicals/")
    }
}

def checkoutCnint(){
    script {
        if(params.GERRIT_REFSPEC_CNINT != '') {
            gitcnint.checkoutRefSpec("${env.GERRIT_REFSPEC_CNINT}", "FETCH_HEAD", "cnint")
            return
        }
        gitcnint.checkout(env.MAIN_BRANCH, 'cnint')
    }
}

def prepareCnint(){
    dir('cnint') {
        checkoutGitSubmodules()
    }
}

def replacePlusToMinusInChartVersion(){
    script {
        env.REPLACED_CHART_VERSION = sh(script: "echo ${params.CHART_VERSION} | sed 's/+/-/g'", returnStdout: true).trim()
    }
}

def createLinksAndBuildDescriptions(){
    script {
        // Generate log url link name and log directory names
        def name = CHART_NAME + ': ' + env.REPLACED_CHART_VERSION
        if (env.GERRIT_REFSPEC_ADP || params.GERRIT_REFSPEC_CNINT) {
            name += "<br>manual change"
            name += '<br>ADP: ' + getGerritLink(env.GERRIT_REFSPEC_ADP)
            name += '<br>CNINT: ' + getGerritLink(params.GERRIT_REFSPEC_CNINT)
        }
        currentBuild.description = name
        if ( params.SPINNAKER_ID != '' ) {
            currentBuild.description += '<br><a href="https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/details/' + params.SPINNAKER_ID + '">Spinnaker URL: ' + params.SPINNAKER_ID + '</a>'
        }
    }
}

def bobClean(){
    dir('cnint') {
        sh './bob/bob clean'
    }
}

def readWhitelist(def checkMap, def whiteList){
    script {
        def data = readYaml file: "${WORKSPACE}/technicals/coverage_report/input_sanity_check_whitelist.yaml"
        data.validations.each { validation, validationConfig ->
            checkMap["in_${validation}"] = validationConfig.services.any { service ->
                service.equals(CHART_NAME)
            }
            whiteList[validation] = validationConfig.services
        }
    }
}

def getNonPraSpinConfig(){
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        script {
            def nonPraAge = 10 //days
            spin.createSpinConfig()
            def executionCount = spin.getExecutions('eea-application-staging-non-pra', "${params.CHART_NAME}", "${env.REPLACED_CHART_VERSION}", nonPraAge )
            if ( executionCount == 0) {
                error("There were no SUCCESSFUL non-pra execution in the last  " + nonPraAge + " days ")
            }
        }
    }
}

def doNonPraExecutionCheck(def checkMap, def bldResult, validationMap){
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        script {
            def stgResult = "${bldResult == 'SUCCESS' ? 'UNSTABLE' : 'FAILURE'}"
            catchError(buildResult: bldResult, stageResult: stgResult ) {
                if (!stageCheck(checkMap, validationMap)) {
                    echo("INFO: No CMA Upgrade before 4.9, HELM/CMA Upgrades have to be fixed for 4.9")
                    error("Validation FAILED")
                }
            }
        }
    }
}

def stageCheck(def checkMap, def validationMap){
    return validationMap.any { stageName, stageWhiteList ->
        def stageResult = spin.getLastExecutionStageResult(stageName)
        if ( stageResult == "SUCCESS") {
            echo("Validation of " + stageName + " was SUCCESSFUL")
            return true
        }
        if (checkMap['in_' + stageWhiteList]) {
            echo("VALIDATION SKIPPED because ${params.CHART_NAME} found in " + stageWhiteList)
            return true
        }
        if ("$stageResult" == 'NO_RUN'){
            echo("WARNING: " + stageName + " has no successful run in the last days "  )
        }
        echo("Latest result of " +  stageName + " was " + stageResult)
        return false
    }
}

def evaluateDocumentationDeliverables(def checkMap) {
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
            script {
                withCredentials([usernamePassword(credentialsId: 'arm-seli-eceaart-token', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                    echo(evaluateDocumentation(checkMap))
                }
            }
        }
    }
}

def evaluateDocumentation(def checkMap) {
    arm.setUrl('https://arm.seli.gic.ericsson.se/', "$API_TOKEN_EEA")
    if (checkMap['in_documentation_deliverables_whitelist']) {
        return "The following microservice in documentation_deliverables_whitelist: ${CHART_NAME}!"
    }
    Map args = ["path": "${env.CHART_NAME}/${env.REPLACED_CHART_VERSION}"]
    if (arm.checkServiceDocumentationDeliverables(args)) {
        return "Documentation deliverables exists for service: ${args}"
    }
    if (env.REPLACED_CHART_VERSION == params.CHART_VERSION) { // - versions should not fail, just print
        return "Documentation deliverables NOT found for service: ${args}"
    }
    error("Documentation deliverables NOT found for service: ${args}")
}

void imageRepoChecking(def checkMap){
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        script {
            if (checkMap['in_image_repo_check_whitelist']) {
                echo "The following microservice in image_repo_check_whitelist: ${CHART_NAME}!"
                return
            }
            def repo_list = ["proj-eea-drop", "proj-eea-released"]
            def data = readYaml file: "${WORKSPACE}/cnint/${env.CHART_NAME}/eric-product-info.yaml"
            echo("${env.CHART_NAME}/eric-product-info.yaml:\n" + data)
            def errorsFound = false
            data.images.each { image ->
                image.each {
                    if (params.CHART_VERSION =~ '-'
                    && !(it.value.repoPath =~ '-released|-drop')) {
                        echo("repoPath: ${it.value.repoPath}")
                        errorsFound = true
                    }
                    if (params.CHART_VERSION =~ '\\+'
                    && !(it.value.repoPath =~ '-released')) {
                        echo("repoPath: ${it.value.repoPath}")
                        errorsFound = true
                    }
                }
            }
            if (errorsFound) {
                error("[ERROR] !!! Unsupported repopath other than Released found in eric-product-info.yaml !!!")
            }
        }
    }
}

def cboAgeReport(def checkMap){
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
            dir('cnint') {
                withCredentials([
                    usernamePassword(credentialsId: 'arm-seli-eceaart-token', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
                    usernamePassword(credentialsId: 'arm-sero-eceaart-token', usernameVariable: 'SERO_USER_ARM', passwordVariable: 'SERO_API_TOKEN_EEA')
                ]) {
                    createCbosCredentials() // the CBOS tool needs this credentials.yaml file, so we create it
                }
                runCbosAgeReportTool(checkMap)
            }
        }
    }
}

def runCbosAgeReportTool(def checkMap){
    sh './bob/bob cbo-drop:report -r bob-rulesets/input-sanity-check-rules.yaml > cbos_age_tool.log'
    def crdhelm = findFiles(glob: env.CHART_NAME + '/eric-crd/*.tgz')
    if (crdhelm) {
        env.HELM_CHART_PATH = crdhelm[0]
        env.CBOS_AGE_TOOL_EXIT_CODE_FILE = 'cbos-age-tool-crd_exit-code'
        sh './bob/bob cbo:report -r bob-rulesets/input-sanity-check-rules.yaml > cbos_age_tool_crd.log'
    }
    archiveArtifacts artifacts: "cbos_age_tool*.log", allowEmptyArchive: true
    archiveArtifacts artifacts: "cbos-age-tool*_exit-code", allowEmptyArchive: true
    archiveArtifacts "cbos-age-report-*"
    evaluateCbosToolResult(sh (script: 'cat cbos-age-tool_exit-code', returnStdout: true).trim(), checkMap)
    if (crdhelm) {
        evaluateCbosToolResult(sh (script: 'cat cbos-age-tool-crd_exit-code', returnStdout: true).trim(), checkMap)
    }
}


def readPropertiesFile() {
    script {
        def file_path = "${WORKSPACE}/technicals/ci_config_default"
        readProperties(file: file_path).each {key, value -> env[key] = value }
        sh "cat $file_path"
    }
}

def testReportCheck(){
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
            script {
                withCredentials([usernamePassword(credentialsId: 'arm-seli-eceaart-token', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD')]) {
                    def fl = "[\\(_soc.json,${env.SANITY_CHECK_SOC_EXISTANCE},${env.SANITY_CHECK_SOC_STRUCTURE}\\),\\(_sov.json,${env.SANITY_CHECK_SOV_EXISTANCE},${env.SANITY_CHECK_SOV_STRUCTURE}\\)]"
                    sh(
                        script: """python3 ${WORKSPACE}/technicals/pythonscripts/check_for_test_files.py -u \${USER_ARM} -p \${USER_PASSWORD} -url https://arm.seli.gic.ericsson.se/artifactory -c ${CHART_NAME} -cv ${env.REPLACED_CHART_VERSION} -mr ${REPOSITORY} -t ${WORKSPACE}/technicals/json_templates/ -fl """ + fl,
                        label: "testReportCheck"
                    )
                }
            }
        }
    }
}

def securityReportChecks(def checkMap, def stageCommentList){
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        script {
            stageCommentList[env.STAGE_NAME] = [' /ignored for (-) nonPRA version/']
            env.SEC_TEST_RESULT = 'SUCCESS'
            if (PIPELINE_NAME == 'eea-application-staging') {
                env.SEC_TEST_RESULT = 'FAILURE'
            }
            catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                withCredentials([usernamePassword(credentialsId: 'arm-seli-eceaart-token', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                            string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                    def data = readYaml file: "${WORKSPACE}/cnint/${env.CHART_NAME}/eric-product-info.yaml"
                    echo("${env.CHART_NAME}/eric-product-info.yaml:\n" + data)
                    def fileData = ""
                    def imagesToCheck = []
                    data.images.each {image ->
                        image.each {
                            imagesToCheck.add(it.value.name)
                        }
                    }
                    checkImagesWhitelist(imagesToCheck,checkMap)
                }
            }
        }
    }
}

void checkImagesWhitelist(def imagesToCheck, def checkMap){
    imagesToCheck.each{ name ->
        inWhitelistCheck(checkMap, args = [ //_XRAY_REPORT_ validation
            "report":       "${CHART_NAME}_" + "${env.REPLACED_CHART_VERSION}_" + name + "_xray_report.json",
            "existance":    "${env.SANITY_CHECK_XRAY_REPORT_EXISTANCE}",
            "structure":    "${env.SANITY_CHECK_XRAY_REPORT_STRUCTURE}",
            "schema":       "xray_report_schema_v5",
            "repo":         "${REPORT_REPO_PATH}",
            "chart":        "${CHART_NAME}"
        ])
        inWhitelistCheck(checkMap, args = [ //_TRIVY_REPORT_ validation
            "report":       "${CHART_NAME}_" + "${env.REPLACED_CHART_VERSION}_" + name + "_trivy_report.json",
            "existance":    "${env.SANITY_CHECK_TRIVY_REPORT_EXISTANCE}",
            "structure":    "${env.SANITY_CHECK_TRIVY_REPORT_STRUCTURE}",
            "schema":       "trivy_report_schema_v3",
            "repo":         "${REPORT_REPO_PATH}",
            "chart":        "${CHART_NAME}"
        ])
        inWhitelistCheck(checkMap, args = [ //_ANCHOR_REPORT_ validation
            "report":       "${CHART_NAME}_" + "${env.REPLACED_CHART_VERSION}_" + name + "_vuln.json",
            "existance":    "${env.SANITY_CHECK_ANCHOR_REPORT_EXISTANCE}",
            "structure":    "${env.SANITY_CHECK_ANCHOR_REPORT_STRUCTURE}",
            "schema":       "anchore_vuln_schema_v1",
            "repo":         "${REPORT_REPO_PATH}",
            "chart":        "${CHART_NAME}"
        ])
        reportExistsCheck(checkMap, args = [ //_GRYPE_REPORT_ validation
            "report":       "${CHART_NAME}_" + "${env.REPLACED_CHART_VERSION}_" + name + "_grype.json",
            "chart":        "${CHART_NAME}"
        ])
        inWhitelistCheck(checkMap, args = [ //_DETAILS_REPORT_ validation
            "report":       "${CHART_NAME}_" + "${env.REPLACED_CHART_VERSION}_" + name + "_details.json",
            "existance":    "${env.SANITY_CHECK_DETAILS_REPORT_EXISTANCE}",
            "structure":    "${env.SANITY_CHECK_DETAILS_REPORT_STRUCTURE}",
            "schema":       "anchore_details_schema_v1",
            "repo":         "${REPORT_REPO_PATH}",
            "chart":        "${CHART_NAME}"
        ])
    }
    inWhitelistCheck(checkMap, args = [ // OWASP_ZAP_REPORT validation
        "report":       "${CHART_NAME}_${env.REPLACED_CHART_VERSION}_owasp_zap_report.json",
        "existance":    "${env.SANITY_CHECK_OWASP_ZAP_EXISTANCE}",
        "structure":    "${env.SANITY_CHECK_OWASP_ZAP_STRUCTURE}",
        "schema":       "owasp_zap_report_schema",
        "repo":         "${REPORT_REPO_PATH}",
        "chart":        "${CHART_NAME}"
    ])
    inWhitelistCheck(checkMap, args = [ //_NMAP_REPORT_ validation
        "report":       "${CHART_NAME}_${env.REPLACED_CHART_VERSION}_nmap_report.xml",
        "existance":    "${env.SANITY_CHECK_NMAP_REPORT_EXISTANCE}",
        "structure":    "${env.SANITY_CHECK_NMAP_XML_REPORT_STRUCTURE}",
        "schema":       "nmap_xsd_schema",
        "repo":         "${REPORT_REPO_PATH}",
        "chart":        "${CHART_NAME}"
    ])
}

void inWhitelistCheck(def checkMap, def args){
    if(checkMap['in_' + args["report"] + '_report_whitelist']) {
        echo "The following microservice in "+ args["report"] + "_report_whitelist: " + args["chart"] + "!"
        return
    }
    sc.sanityCheckReportsValidation(args)
}
void reportExistsCheck(def checkMap, def args){
    if(checkMap['in_' + args["report"] + '_report_whitelist']) {
        echo "The following microservice in "+ args["report"] + "_report_whitelist: " + args["chart"] + "!"
        return
    }
    sc.checkReportExists(args["report"])
}

def releaseDocumentationValidation(def checkMap) {
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
            script {
                if(checkMap['release_documentation_validation_whitelist']){
                    echo "The following microservice in release_documentation_validation_whitelist: ${CHART_NAME}!"
                    return
                }
                withCredentials([usernamePassword(credentialsId: 'arm-seli-eceaart-token', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                    string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                    string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                    usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                    def releaseDocTypes = ['soc', 'sov']
                    releaseDocTypes.each() {
                        arm.downloadArtifact("${CHART_NAME}/${CHART_NAME}_${env.REPLACED_CHART_VERSION}_${it}.json","${CHART_NAME}_${env.REPLACED_CHART_VERSION}_${it}.json",REPORT_REPO_PATH.split('/')[-1])
                        sh "python3 ${WORKSPACE}/technicals/pythonscripts/release_document_json_validator.py -c ${CHART_NAME} -cv ${env.REPLACED_CHART_VERSION} -dt ${it} -t ${WORKSPACE}/technicals/json_templates/${it}_schema.json"
                    }
                }
            }
        }
    }
}

def interfaceCoverageReportCheck(def checkMap) {
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        dir('cnint') {
            withCredentials([usernamePassword(credentialsId: 'arm-seli-eceaart-token', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                            string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                            string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                            usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                sh script: """git archive --remote=ssh://\${GERRIT_USERNAME}@${GERRIT_HOST}:${GERRIT_PORT}/EEA/adp-app-staging HEAD:technicals/coverage_report/ | tar -x"""
                script {
                    if (checkMap['in_coverage_report_config_whitelist']) {
                        echo "The following microservice ${CHART_NAME} is whitelisted for Interface coverage report check in Product CI input sanity, skipping this validation."
                        return
                    }
                    sh './bob/bob interface-coverage-report-check -r bob-rulesets/input-sanity-check-rules.yaml'
                }
            }
        }
    }
}

def serviceLevelCiTestReportsValidation(def checkMap) {
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
            script {
                withCredentials([usernamePassword(credentialsId: 'arm-seli-eceaart-token', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                    if (checkMap['in_service_level_CI_test_report_whitelist']) {
                        echo "The following microservice does not need to be validated: ${CHART_NAME}!"
                        return
                    }
                    arm.downloadArtifact("${CHART_NAME}/${CHART_NAME}_${env.REPLACED_CHART_VERSION}_test_results.json","${CHART_NAME}_${env.REPLACED_CHART_VERSION}_test_results.json",env.REPORT_REPO_PATH.split('/')[-1])
                    def extraSwitches = ''
                    if (CHART_NAME in vars.withoutIntegrationLevelList) {
                        extraSwitches += " -ni true"
                    }
                    if(CHART_NAME in vars.withoutUpgradeLevelList) {
                        extraSwitches += " -nu true"
                    }
                    if (CHART_NAME in vars.withoutComponentLevelList) {
                        extraSwitches += " -nc true"
                    }
                    sh """python3 ${WORKSPACE}/technicals/pythonscripts/test_report_json_sanity_check.py -u \${USER_ARM} -p \${USER_PASSWORD} -c ${CHART_NAME} -cv ${env.REPLACED_CHART_VERSION} -t ${WORKSPACE}/technicals/json_templates/""" + extraSwitches
                }
            }
        }
    }
}

def CRDsCheckInServiceHelmCharts(def checkMap) {
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
            dir("cnint/${env.CHART_NAME}") {
                script {
                    if (checkMap['in_crd_check_in_service_helm_charts_whitelist']) {
                        echo "The following microservice in crd_check_in_service_helm_charts_whitelist: ${CHART_NAME}!"
                        return
                    }
                    sh """ find . -type f -iregex ".*.ya?ml" -printf "%P\n" | tee yaml_files """
                    def result = readFile("yaml_files").trim().readLines()
                    if (result.isEmpty()) {
                        return
                    }
                    for (filename in result) {
                        def crdKind = sh (script: """egrep -i kind:.*CustomResourceDefinition $filename  """, returnStatus: true)
                        if ( crdKind == 0 ) {
                            error("!!! CRD found!!! File: " + filename )
                        }
                    }
                }
            }
        }
    }
}

def notificationChangeInWhitelist(def whiteList) {
    script{
        def changedFiles = getGerritQueryPatchsetChangedFiles("${env.GERRIT_REFSPEC_ADP}")
        def foundWhitelistFile = changedFiles.find { file -> file.contains("coverage_report/input_sanity_check_whitelist.yaml") }
        if (!foundWhitelistFile){
            return
        }
        boolean skipNotif = true
        echo "Change(s) in input_sanity_check_whitelist.yaml determined "
        gitadp.checkout('master', 'adp-app-staging')
        def origList = readYaml file: "adp-app-staging/technicals/coverage_report/input_sanity_check_whitelist.yaml"
        def validationList=['owasp_zap_report_whitelist',
                            'xray_report_whitelist',
                            'trivy_report_whitelist',
                            'grype_report_whitelist',
                            'details_report_whitelist',
                            'nmap_report_whitelist']
        def validation = origList.validations.each { validation, validationConfig ->
            if (validationList.contains(validation) && (!whiteList.containsKey(validation) || whiteList[validation] != validationConfig.services)) {
                echo "Changed ${validation} \n"
                skipNotif = false
            }
        }
        if (skipNotif){
            return
        }
        echo "Send notification to Security Team"
        def ger_link = getGerritLink(env.GERRIT_REFSPEC_ADP)
        def recipient = 'PDLURITYEE@pdl.internal.ericsson.com'
        def msg = "Whitelist at adp-app-staging/technicals/coverage_report/input_sanity_check_whitelist.yaml was modified. \n Please review for any security concerns. ${env.BUILD_URL}.   Gerrit Link : ${ger_link}"
        notif.sendMail(
            "${env.JOB_NAME} (${env.BUILD_NUMBER}) Changes Made in input-sanity-check whitelist",
            "${msg}",
            "${recipient}",
        "text/html")
    }
}

void productVersionMimerCheck(){
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
            withCredentials([usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                script {
                    gitcommoner.archiveFile('eea-release-team/commoner', 'HEAD mimer/data/helm_to_number_mapping.csv')
                    def mappingCsv = readCSV file: "${WORKSPACE}/mimer/data/helm_to_number_mapping.csv", format: CSVFormat.DEFAULT.withHeader()
                    int rowNumber = 0
                    def productNumber
                    while ( rowNumber < (mappingCsv.size()) ) {
                        if ( (mappingCsv[rowNumber].get('name')) == params.CHART_NAME ){
                            productNumber = (mappingCsv[rowNumber].get('prod.num'))
                            echo("productNumber: " + productNumber)
                        }
                        rowNumber++
                    }
                    String serviceMimerStatus = ""
                    String productVersion = env.REPLACED_CHART_VERSION.split("-")[0]
                    try {
                        serviceMimerStatus = checkMimer(productNumber,productVersion)
                    }
                    finally {
                        if (serviceMimerStatus) {
                            Map mimerInfo = [
                                "serviceName": "${env.CHART_NAME}",
                                "serviceVersion": "${params.CHART_VERSION}",
                                "serviceMimerStatus": "${serviceMimerStatus}",
                                "productNumber": "${productNumber}",
                                "productVersion": "${productVersion}"
                            ]
                            echo "Upload Mimer info to application dashboard"
                            try {
                                dashboard.uploadExecutionMimer([mimerInfo], "${env.SPINNAKER_ID}", "${env.PIPELINE_NAME}")
                            }
                            catch (err) {
                                echo "FAILED to Upload Mimer info to application dashboard.\nCaught: ${err}"
                            }
                        }
                    }
                }
            }
        }
    }
}

def checkMimer(def productNumber,def productVersion){
    mimer.getProductVersion(productNumber,productVersion)
    def mimerData = readJSON file: "getProductVersion.response.json"
    if ( mimerData.results.code.get(0) != 'OK' ) {
        def msg = "" + mimerData.results.messages.get(0)
        if (msg.contains("product does not exist")) {
            echo("ERROR] product is not in Mimer")
            error(msg)
        }
        if (msg.contains("product version does not exist")) {
            echo("product is in Mimer but version is not in Mimer")
            error(msg)
        }
    }

    if ( mimerData.results.data.lifecycle.lifecycleStage.get(0) != "Released" ){
            if (params.CHART_VERSION.contains("+")) {
                error(productNumber + " " + productVersion + " is not released in Mimer")
            }
            if (!params.CHART_VERSION.contains("+")) {
                echo("[WARN] " + productNumber + " " + productVersion + " is not released in Mimer")
            }
        return "version is in Mimer but is not released in Mimer"
    }
    echo("[INFO] " + productNumber + " " + productVersion + " is released in Mimer")
    return "version is released in Mimer"
}

def postStageAlways(stageCommentList,stageResultsInfo){
    script {
        try {
            archiveArtifacts artifacts: 'cnint/.bob/check-helm/design-rule-check-report.html', allowEmptyArchive: true
            archiveArtifacts artifacts: "cnint/.bob/*.html", allowEmptyArchive: true
            sh ' rm -rf  \'currentBuildResult.json\''
            downloadJenkinsFile("${BUILD_URL}/wfapi/describe", "currentBuildResult.json")
            archiveArtifacts artifacts: 'currentBuildResult.json',  allowEmptyArchive: true
            cmutils.generateStageResultsHtml(stageCommentList,stageResultsInfo)
        }
        catch (err) {
                echo "Caught: ${err}"
        }
    }
}

def generateStageResultsHtml(){
    def stageResultsHtml = "<html>\n<body>\n<style>\ntable, th, td {\nborder:1px solid black;border-collapse: collapse;}\n</style>\n"
    stageResultsHtml += "<h2>${params.CHART_NAME}:${params.CHART_VERSION}</h2>"
    def beginOfJobStateColor = ''
    if( currentBuild.result != 'SUCCESS' ){
        beginOfJobStateColor = 'style="color:red"'
    }
    stageResultsHtml += "<h3 ${beginOfJobStateColor}>Jenkins job state: ${currentBuild.result}</h3>"
    stageResultsHtml += "<table><tr><th>Stage name</th><th>Stage state</th><th>Additional info</th></tr>"
    def failedStagesTable = "<table><tr><th>Stage name</th><th>Stage state</th><th>Additional info</th></tr>"
    def currBuildJson = readJSON file: "${env.WORKSPACE}/currentBuildResult.json"
    def error = [:]
    currBuildJson.stages.each { item ->
        if ( item.name != 'Declarative: Post Actions') {
            def stageAdditionalInfo = ''
            def underscoredStageName = item.name.replaceAll(' ', '_')
            def beginStageFileLink = ''
            def endStageFileLink = ''
            if ( fileExists("stage_${underscoredStageName}.log")) {
                beginStageFileLink += "<a href=\"${env.BUILD_URL}/artifact/stage_${underscoredStageName}.log\">"
                endStageFileLink += "</a>"
            }
            def stageComment = ''
            if ( item.name == 'Security report checks' ) {
            stageComment += ' /for nonPRA (-) version we ignore this/'
            }


            def stageStatus = item.status
            try {
                if ( item["error"] && item["error"]["message"] ) {
                    if ( !error["message"] ) {
                        error.stage = item.name
                        error.message = item["error"]["message"]
                        stageAdditionalInfo = error.message
                    }
                    if ( error["message"] && item["error"]["message"] == error.message ) {
                        stageStatus = 'SKIPPED'
                        stageAdditionalInfo = "skipped due to earlier failure(s)"
                    }
                }
            }
            catch (item_err) {
                echo "Caught: ${item_err}"
            }


            def beginStageColor = '<p>'
            def endStageColor = '</p>'
            switch( item.status ){
                case 'SUCCESS':
                    beginStageColor = '<p style="color:green">'
                    break
                case 'FAILED':
                    beginStageColor = '<p style="color:red">'
                    break
                case 'UNSTABLE':
                    beginStageColor = '<p style="color:orange">'
                    break
                case 'NOT_EXECUTED':
                case 'SKIPPED':
                    beginStageColor = '<p style="color:gray">'
                    break
            }
            stageResultsHtml += "\n<tr><td>${beginStageFileLink}${item.name}${endStageFileLink}${stageComment}</td><td>${beginStageColor}${item.status}${endStageColor}</td><td>${stageAdditionalInfo}</td></tr>"
            if ( stageStatus == 'FAILED' ) {
                failedStagesTable += "\n<tr><td>${beginStageFileLink}${item.name}${endStageFileLink}${stageComment}</td><td>${beginStageColor}${item.status}${endStageColor}</td><td>${stageAdditionalInfo}</td></tr>"
            }
            if ( stageStatus == 'UNSTABLE' ) {
                failedStagesTable += "\n<tr><td>${beginStageFileLink}${item.name}${endStageFileLink}${stageComment}</td><td>${beginStageColor}${item.status}${endStageColor}</td><td>${stageAdditionalInfo}</td></tr>"
            }
            echo "${item.name} ${stageComment} ${item.status}"
        }
    }
    stageResultsHtml += "</table>\n</body>\n</html>"
    writeFile file: 'stageResults.html', text: stageResultsHtml
    archiveArtifacts artifacts: 'stageResults.html',  allowEmptyArchive: true
    failedStagesTable += "</table>\n</body>\n</html>"
    if ( currentBuild.result == 'FAILURE' ) {
        currentBuild.description += failedStagesTable
    }
    currentBuild.description += "<br>Jenkins job stages results: <a href=\"${BUILD_URL}/artifact/stageResults.html\">stageResults.html</a>"
}

def postStageFailure(){
    script {
        if(params.GERRIT_REFSPEC != '') {
            env.GERRIT_MSG = "Build Failed ${BUILD_URL}: FAILURE"
            sendMessageToGerrit(params.GERRIT_REFSPEC, env.GERRIT_MSG)
        }
    }
}

def postStageSuccess(){
    script {
        if(env.GERRIT_REFSPEC_ADP) {
            env.GERRIT_MSG = "Build Successful ${BUILD_URL}: SUCCESS"
            sendMessageToGerrit(env.GERRIT_REFSPEC_ADP, env.GERRIT_MSG)
        }
    }
}

String createCbosCredentials(){
    sh '''
cat << END > credentials.yaml
repositories:
- url: https://arm.rnd.ki.sw.ericsson.se/artifactory/
  username: ${USER_ARM}
  password: ${API_TOKEN_EEA}
- url: https://arm.sero.gic.ericsson.se/artifactory/
  username: ${USER_ARM}
  password: ${API_TOKEN_EEA}
- url: https://armdocker.rnd.ericsson.se/artifactory/
  username: ${USER_ARM}
  password: ${API_TOKEN_EEA}
- url: https://arm.seli.gic.ericsson.se/artifactory/
  username: ${USER_ARM}
  password: ${API_TOKEN_EEA}
- url: https://serodocker.sero.gic.ericsson.se/artifactory/
  username: ${SERO_USER_ARM}
  password: ${SERO_API_TOKEN_EEA}
END
    '''
}

void inputSanityCheckForSonarQube(def in_sonarqube_report_whitelist) {
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
            script {
                if (in_sonarqube_report_whitelist) {
                    echo "${env.CHART_NAME} is whitelisted at Sonarqube report check in Input Sanity"
                    return
                }
                if ((SANITY_CHECK_SONAR_COVERAGE as Integer) <= 0) {
                    echo "Input sanity check turned off due to configuration SANITY_CHECK_SONAR"
                    return
                }
                echo "Input sanity check for SonarQube"
                def reportName = "${env.CHART_NAME}_${env.REPLACED_CHART_VERSION}_sonarqube_report.json"

                // init SanityCheck args
                Map args = [
                    "report":       "${reportName}",
                    "repo":         "${REPORT_REPO_PATH}",
                    "chart":        "${CHART_NAME}"
                ]
                sc.args = args

                // check if report exists in arm (.json or .tgz)
                if (!sc.checkReportExists(reportName)) {
                    echo("SonarQube .json file not found in ARM, trying to locate .tgz file ...")
                    reportName = reportName.replace(".json", ".tgz")
                }

                if (!sc.checkReportExists(reportName)) {
                    error("${reportName} is missing from ARM!")
                }

                // download report
                if (!sc.downloadReport(reportName)) {
                    error("Download report: ${reportName} FAILED!")
                }

                // collect reports
                def reportsToValidate = sc.collectReportsToValidate(reportName, '.json')

                // validate reports
                reportsToValidate.eachWithIndex { report, idx ->
                    echo("Validate report: ${WORKSPACE}/${report} ...")
                    sh "python3 -m json.tool ${WORKSPACE}/${report}"
                    sh "python3 ${WORKSPACE}/technicals/pythonscripts/sonar_json_sanity_check.py -c ${CHART_NAME} -cv ${env.REPLACED_CHART_VERSION} -t ${WORKSPACE}/technicals/json_templates/ -m ${SANITY_CHECK_SONAR_COVERAGE} -r ${WORKSPACE}/${report}"
                }
            }
        }
    }
}

void evaluateCbosToolResult(def exitCode, def checkMap) {
    echo "cbos-age-tool exit code: ${exitCode}"
    switch (exitCode) {
        case '2':
            catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                error "There are images with more than 6 weeks old CBOS version in the ${params.CHART_NAME} chart! The ${params.CHART_NAME} service is in white list. Error ignored"
            }
            break
        case '1':
            echo "Note: there are images that are less than 6 weeks old CBOS version."
            break
        case '0':
            echo "OK: all images are based on the latest CBOS version."
            break
        case '-1':
            error "There are validation / known runtime errors! Users are responsible to fix these. CBO Age report failed with exit code ${exitCode}"
            break
        case '-2':
            error "There are unknown runtime errors! CI/CD team is responsible to fix these. CBO Age report failed with exit code ${exitCode}"
            break
        default:
            error "CBO Age report failed with exit code ${exitCode}"
            break
    }
}

void inputSanityCheckForHelmChartAndDockerImages(Map checkMap) {
    tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
        catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
            dir('cnint') {
                script {
                    def imagesFailed = false
                    withCredentials([string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                        arm.downloadArtifact("${env.CHART_NAME}/${env.CHART_NAME}-${env.CHART_VERSION}.tgz","${env.CHART_NAME}-${env.CHART_VERSION}.tgz",env.CHART_REPO.split('/')[-1])
                        sh script: """
                            tar -xzf ${env.CHART_NAME}-${env.CHART_VERSION}.tgz
                        """, label: "Unpack ${env.CHART_NAME}"
                    }
                    if(checkMap['in_input_sanity_check_for_helm_chart_and_docker_images_whitelist']){
                        echo "The following microservice in input_sanity_check_for_helm_chart_and_docker_images_whitelist: ${CHART_NAME}!"
                        return
                    }
                    def filePaths = getFilePaths()
                    def listOfImagesToCheckWithRepoPath = getListOfImagesFromFilePaths(filePaths)
                    catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE' ) {
                        bobPrepareCommon()
                        drCheckImage()
                    }
                    parallel listOfImagesToCheckWithRepoPath.collectEntries { image ->
                        ["SanityAnnotations_${image.value}": {
                            if(sanityAnnotations(image)){
                                imagesFailed = true
                            }
                        }]
                    }
                    if(!imagesFailed){
                        return
                    }
                    error("[FAILED] Some images didn't pass, please check the logs!")
                    currentBuild.result = 'FAILURE'
                }
            }
        }
    }
}

def bobPrepareCommon(){
    withCredentials([string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                    string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')
                    ]) {
        sh script: "./bob/bob prepare-common", label: "Prepare bob common"
    }
}

def drCheckImage(){
    withCredentials([string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                    string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')
                    ]) {
        sh script: """
            ./bob/bob lint-ms-helm -r bob-rulesets/input-sanity-check-rules.yaml
        """, label: "CheckImages"
    }
}

def getFilePaths(){
    def data = readYaml file: "${WORKSPACE}/cnint/${env.CHART_NAME}/eric-product-info.yaml"
    def files = sh(script: "find ${WORKSPACE}/cnint/${env.CHART_NAME} -type f -name 'eric-product-info.yaml'", returnStdout: true).trim()
    env.DOCKER_IMAGE_NAME_TO_CHECK = ""
    filePaths = files ? files.split('\n') : []
    return filePaths
}

def sanityAnnotations(def image) {
    def credentialsIdToken = ""
    def hasFailed = false
    imageHost = image.key.split("/")[0]
    switch( imageHost ) {
        case "armdocker.rnd.ericsson.se":
        case "arm.seli.gic.ericsson.se":
            credentialsIdToken = 'arm-seli-eceaart-token'
            break
        case "serodocker.sero.gic.ericsson.se":
            credentialsIdToken = 'arm-sero-eceaart-token'
            break
        default:
            error "invalid imageHost ${imageHost}"
            break
    }
    withCredentials([usernamePassword(credentialsId: credentialsIdToken, usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD')]) {
        env.DOCKER_IMAGE_NAME_TO_CHECK = image.key
        env.FILE_PREFIX = image.value
        def prefix = env.FILE_PREFIX
        def destFileName = "image-design-rule-check-report-${env.FILE_PREFIX}.html"
        try{
            sh script: """
                ./bob/bob sanity-annotations -r bob-rulesets/input-sanity-check-rules.yaml
            """, label: "SanityAnnotations: ${prefix}"
        }
        catch(err) {
            hasFailed = true
            error("[FAILED] Some images didn't pass, please check the logs!")
        }
        finally {
            sh script: """
                destDir=\$(dirname "${destFileName}")
                mkdir -p "\$destDir"
                cp -p .bob/${prefix}/image-design-rule-check-report.html "${destFileName}"
            """, label: "Create report: ${prefix}"
            archiveArtifacts artifacts: "${destFileName}", allowEmptyArchive: true
        }
    }
    return hasFailed
}

def getListOfImagesFromFilePaths(def filePaths){
    def listOfImagesToCheck = []
    def listOfImagesToCheckWithRepoPath = [:]
    filePaths.each {path ->
        data = readYaml file: path
        data.images.each {image ->
            image.each {
                if ( !listOfImagesToCheck.contains(it.value.registry + "/" + it.value.repoPath + "/" + it.value.name + ":" + it.value.tag) ) {
                    listOfImagesToCheck += it.value.registry + "/" + it.value.repoPath + "/" + it.value.name + ":" + it.value.tag
                    imageNameWithPath = it.value.registry + "/" + it.value.repoPath + "/" + it.value.name + ":" + it.value.tag
                    listOfImagesToCheckWithRepoPath[imageNameWithPath] = it.value.name + ":" + it.value.tag
                }
            }
        }
    }
    return listOfImagesToCheckWithRepoPath
}
