@Library('ci_shared_library_eea4') _


import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.ScasUtils
import com.ericsson.eea4.ci.Artifactory
import com.ericsson.eea4.ci.Notifications
import groovy.transform.Field

@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def scas = new ScasUtils(this)
@Field def arm = new Artifactory(this, "https://arm.seli.gic.ericsson.se/",  "API_TOKEN_EEA")
@Field def notif = new Notifications(this)

def fileToCheck = ""
def schemaFile = ""
Map checkMap = [:]

pipeline {
    options {
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
        string(name: 'SPINNAKER_TRIGGER_URL', description: 'Spinnaker pipeline triggering url', defaultValue: '')
        string(name: 'PIPELINE_NAME', description: "The spinnaker pipeline name", defaultValue: 'eea-application-staging')
        string(name: 'SPINNAKER_ID', description: "The spinnaker execution's id", defaultValue: '')
    }
    environment {
        REPORT_ARM_PATH = "proj-eea-reports-generic-local"
        SCHEMA_ARM_PATH = "proj-cea-dev-local/eea4-3pp-list-schema"
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

        stage('Checkout adp-app-staging') {
            steps {
                script{
                    gitadp.checkout('master', '')
                }
            }
        }

        stage('Prepare') {
            steps {
                checkoutGitSubmodules()
            }
        }

        stage('Replace + to - in Chart version') {
            steps {
                script {
                    env.REPLACED_CHART_VERSION = sh(script: "echo ${params.CHART_VERSION} | sed 's/+/-/g'", returnStdout: true).trim()
                }
            }
        }

        stage('Init') {
            steps {
                script {
                    // Generate log url link name and log directory names
                    def name = CHART_NAME + ': ' + env.REPLACED_CHART_VERSION
                    // Setup build info
                    currentBuild.description = name
                    if ( params.SPINNAKER_ID != '' ) {
                        currentBuild.description += '<br><a href="https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/details/' + params.SPINNAKER_ID + '">Spinnaker URL: ' + params.SPINNAKER_ID + '</a>'
                    }
                }
            }
        }

        stage('Clean') {
            steps {
                sh './bob/bob clean'
            }
        }
        //Reading whitelist for checking the service is in
        stage('Read whitelist') {
            steps {
                script {
                    def data = readYaml file: "${WORKSPACE}/technicals/coverage_report/input_sanity_check_whitelist.yaml"
                    data.validations.each { validation, validationConfig ->
                        checkMap["in_${validation}"] = validationConfig.services.any { service ->
                            service.contains(CHART_NAME)
                        }
                    }
                }
            }
        }

        stage('Read properties') {
            steps {
                script {
                    def file_path = "technicals/ci_config_default"
                    readProperties(file: file_path).each {key, value -> env[key] = value }
                    sh "cat $file_path"
                }
            }
        }

        stage('3pp list check') {
            steps {
                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                    catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                        script {
                            withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                                 string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                                if (checkMap['in_3pp_list_check_whitelist']) {
                                    echo "The following microservice in 3pp list check whitelist: ${CHART_NAME}!"
                                }
                                else {
                                    try {
                                        if ("${env.SANITY_CHECK_3PP_LIST_EXISTANCE}" == "True") {
                                            fileToCheck = "${CHART_NAME}_${env.REPLACED_CHART_VERSION}_3pp_list.json"
                                            arm.setUrl("https://arm.seli.gic.ericsson.se", "${API_TOKEN_EEA}")
                                            arm.setRepo("${REPORT_ARM_PATH}/${CHART_NAME}")
                                            arm.downloadArtifact("${fileToCheck}", "${fileToCheck}")

                                            if ("${env.SANITY_CHECK_3PP_LIST_STRUCTURE}" == "True") {
                                                if ("${params.PIPELINE_NAME}" == "eea-application-staging") {
                                                    schemaFile = "3pplist_release_schema_1.6.json"
                                                } else {
                                                    schemaFile = "3pplist_schema_1.6.json"
                                                }
                                                arm.setUrl("https://arm.seli.gic.ericsson.se", "${API_TOKEN_EEA}")
                                                arm.setRepo("${SCHEMA_ARM_PATH}")
                                                arm.downloadArtifact("${schemaFile}","${schemaFile}")
                                                sh "jsonschema -i ${fileToCheck} ${schemaFile}"
                                            }
                                        }
                                    } catch (err) {
                                        echo "Caught: ${err}"
                                        error "3PP LIST CHECK FAILED"
                                    } finally {
                                        archiveArtifacts artifacts: fileToCheck, allowEmptyArchive: true
                                        archiveArtifacts artifacts: schemaFile, allowEmptyArchive: true
                                    }
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

        stage ('Download data from SCAS'){
            steps {
                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                    catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                        script {
                            try {
                                def chartContent = readJSON file: "${fileToCheck}"
                                def listOfCaxs = []
                                chartContent.images."3ppList".each { obj ->
                                    obj.each {
                                        listOfCaxs.add("${it.versionCAX}/${it.numberCAX}")
                                    }
                                }
                                def uniqueCaxs = listOfCaxs.unique()
                                def scasData = []
                                uniqueCaxs.collate( 300 ).each {
                                    println it
                                    def callResult = scas.searchComponentByNumber(it, '')
                                    def result = readJSON text: callResult
                                    result.content.each {
                                        scasData.add(it)
                                    }
                                }
                                if (scasData) { writeJSON file: 'searchComponentByNumber.list.response.json', json: scasData }
                            }
                            catch (err) {
                                error "${STAGE_NAME} FAILED:\n${err}"
                            } finally {
                                archiveArtifacts artifacts: 'searchComponentByNumber.list.response.json', allowEmptyArchive: true
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

        stage ('Check 3PPs') {
            steps {
                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                    catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                        script {
                            if (checkMap['in_check_3pps_whitelist']) {
                                    echo "The following microservice in check 3pp whitelist: ${CHART_NAME}!"
                            }
                            else {
                                try {
                                    def chartContent = readJSON file: "${fileToCheck}"
                                    def scasContent = readJSON file: "searchComponentByNumber.list.response.json"
                                    def invalidNumberRecords = []
                                    def nameMismatchRecords = []
                                    def versionMismatchRecords = []
                                    chartContent.images."3ppList".each { obj ->
                                        obj.each { objData ->
                                            if (!scasContent.findAll{ scasData -> scasData.compProdNumber == "${objData.versionCAX}/${objData.numberCAX}" }) {
                                                echo "Invalid Number Found"
                                                invalidNumber(invalidNumberRecords, "${objData.versionCAX}/${objData.numberCAX}", "${objData.'3ppName'}", "${objData.'3ppVersion'}", "${chartContent.images.imageName}", "${chartContent.images.imageNumber}")
                                            } else {
                                                scasContent.each { scasData ->
                                                    if ( "${objData.versionCAX}/${objData.numberCAX}" == scasData.compProdNumber ) {
                                                        if ( "${objData.'3ppName'}" != scasData.compName ) {
                                                            nameMismatch(nameMismatchRecords, "${objData.versionCAX}/${objData.numberCAX}", "${objData.'3ppName'}", scasData.compName, "${chartContent.images.imageName}", "${chartContent.images.imageNumber}")
                                                            if ( "${objData.'3ppVersion'}" != scasData.compVersion ) {
                                                                versionMismatch(versionMismatchRecords, "${objData.versionCAX}/${objData.numberCAX}", "${objData.'3ppName'}", "${objData.'3ppVersion'}", scasData.compVersion, "${chartContent.images.imageName}", "${chartContent.images.imageNumber}")
                                                            }
                                                        } else if ( "${objData.'3ppVersion'}" != scasData.compVersion ) {
                                                            versionMismatch(versionMismatchRecords, "${objData.versionCAX}/${objData.numberCAX}", "${objData.'3ppName'}", "${objData.'3ppVersion'}", scasData.compVersion, "${chartContent.images.imageName}", "${chartContent.images.imageNumber}")
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    if (nameMismatchRecords) {
                                        writeCSV file: 'name-mismatch.csv', records: nameMismatchRecords, format: CSVFormat.DEFAULT.withHeader('chart.3pp.num','chart.3pp.name','scas.3pp.name','chart.img.name','chart.img.num')
                                        // Check names mismatch second time ignoring special characters
                                        echo "CHECKING NAME MISMATCH WITHOUT SPECIAL CHARACTERS"
                                        def nameMismatchRecordsContent = readCSV file: "name-mismatch.csv", format: CSVFormat.DEFAULT.withHeader()
                                        def nameMismatchRecordsWithoutSpecChars = []
                                        rowNumber = 0
                                        while ( rowNumber < (nameMismatchRecordsContent.size()) ) {
                                            scasContent.each { scasData ->
                                                if ( (nameMismatchRecordsContent[rowNumber].get('chart.3pp.num')) == scasData.compProdNumber ) {
                                                    if ( (nameMismatchRecordsContent[rowNumber].get('chart.3pp.name')).replaceAll("[^a-zA-Z0-9 ]+","").toLowerCase() != scasData.compName.replaceAll("[^a-zA-Z0-9 ]+","").toLowerCase() ) {
                                                        nameMismatch(nameMismatchRecordsWithoutSpecChars, nameMismatchRecordsContent[rowNumber].get('chart.3pp.num'), nameMismatchRecordsContent[rowNumber].get('chart.3pp.name'), scasData.compName, nameMismatchRecordsContent[rowNumber].get('chart.img.name'), nameMismatchRecordsContent[rowNumber].get('chart.img.num'))
                                                    }
                                                }
                                            }
                                            rowNumber++
                                        }
                                        if (nameMismatchRecordsWithoutSpecChars) {
                                            writeCSV file: 'name-mismatch-without-spec-chars.csv', records: nameMismatchRecordsWithoutSpecChars, format: CSVFormat.DEFAULT.withHeader('chart.3pp.num','chart.3pp.name','scas.3pp.name','chart.img.name','chart.img.num')
                                        }
                                        unstable "UNSTABLE: POSSIBLE NAME MISMATCH FOUND BETWEEN CHART 3PPLIST AND SCAS"
                                    }
                                    if (versionMismatchRecords) {
                                        writeCSV file: 'version-mismatch.csv', records: versionMismatchRecords, format: CSVFormat.DEFAULT.withHeader('chart.3pp.num','chart.3pp.name','chart.3pp.ver','scas.3pp.ver','chart.img.name','chart.img.num')
                                        // Check versions mismatch second time ignoring special characters
                                        echo "CHECKING VERSIONS MISMATCH WITHOUT SPECIAL CHARACTERS"
                                        def versionMismatchRecordsContent = readCSV file: "version-mismatch.csv", format: CSVFormat.DEFAULT.withHeader()
                                        def versionMismatchRecordsWithoutSpecChars = []
                                        rowNumber = 0
                                        while ( rowNumber < (versionMismatchRecordsContent.size()) ) {
                                            scasContent.each { scasData ->
                                                if ( (versionMismatchRecordsContent[rowNumber].get('chart.3pp.num')) == scasData.compProdNumber ) {
                                                    if ( (versionMismatchRecordsContent[rowNumber].get('chart.3pp.ver')).replaceAll("[^a-zA-Z0-9 ]+","").toLowerCase() != scasData.compVersion.replaceAll("[^a-zA-Z0-9 ]+","").toLowerCase() ) {
                                                        versionMismatch(versionMismatchRecordsWithoutSpecChars, versionMismatchRecordsContent[rowNumber].get('chart.3pp.num'), versionMismatchRecordsContent[rowNumber].get('chart.3pp.name'), versionMismatchRecordsContent[rowNumber].get('chart.3pp.ver'), scasData.compVersion, versionMismatchRecordsContent[rowNumber].get('chart.img.name'), versionMismatchRecordsContent[rowNumber].get('chart.img.num'))
                                                    }
                                                }
                                            }
                                            rowNumber++
                                        }
                                        if (versionMismatchRecordsWithoutSpecChars) {
                                            writeCSV file: 'version-mismatch-without-spec-chars.csv', records: versionMismatchRecordsWithoutSpecChars, format: CSVFormat.DEFAULT.withHeader('chart.3pp.num','chart.3pp.name','chart.3pp.ver','scas.3pp.ver','chart.img.name','chart.img.num')
                                        }
                                        unstable "UNSTABLE: POSSIBLE VERSION MISMATCH FOUND BETWEEN CHART 3PPLIST AND SCAS"
                                    }
                                    if (invalidNumberRecords) {
                                        writeCSV file: 'invalid-cax-number.csv', records: invalidNumberRecords, format: CSVFormat.DEFAULT.withHeader('chart.3pp.num','chart.3pp.name','chart.3pp.ver','chart.img.name','chart.img.num')
                                        error "FAILURE: CAX NUMBER NOT FOUND IN SCAS"
                                    }
                                }
                                catch (err) {
                                    error "${STAGE_NAME} FAILED:\n${err}"
                                } finally {
                                    archiveArtifacts artifacts: 'invalid-cax-number.csv', allowEmptyArchive: true
                                    archiveArtifacts artifacts: "name-mismatch.csv", allowEmptyArchive: true
                                    archiveArtifacts artifacts: "name-mismatch-without-spec-chars.csv", allowEmptyArchive: true
                                    archiveArtifacts artifacts: 'version-mismatch.csv', allowEmptyArchive: true
                                    archiveArtifacts artifacts: 'version-mismatch-without-spec-chars.csv', allowEmptyArchive: true
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
    }
    post {
        unstable {
            script {
                notifyMsOwner()
            }
        }
        failure {
            script {
                notifyMsOwner()
            }
        }
        cleanup {
            cleanWs()
        }
    }
}

void notifyMsOwner() {
    withCredentials([string(credentialsId: 'jira-eceaconfl-token', variable: 'JIRA_API_TOKEN')]) {
        withEnv(["TEAM_MAILING_LIST_OUT=team_mailing_list"]) {
            try {
                gitcnint.checkout('master', 'cnint')
                sh './bob/bob -r ${WORKSPACE}/cnint/ruleset2.0.yaml get-ms-owner-email-from-jira-component-list'
                def recipient = sh(script: 'cat ${TEAM_MAILING_LIST_OUT}', returnStdout: true).trim()
                def subject = "${env.JOB_NAME} (${env.BUILD_NUMBER}) ${currentBuild.currentResult}"
                def body = "<a href=\"${env.BUILD_URL}\">${env.BUILD_URL}</a><br>3pp List Check ${currentBuild.currentResult} for ${CHART_NAME}:${CHART_VERSION}<br>Please check the build logs"
                notif.sendMail(subject, body, recipient, 'text/html')
            } catch (err) {
                echo "notifyMsOwner() FAILED. Caught ${err}"
            }
        }
    }
}

def invalidNumber(invalidNumberRecords, caxNumber, chartCompName, chartCompVersion, imageName, imageNumber ) {
    println "[ERROR] Invalid number: " + caxNumber
    println "[INFO] in image: " + imageName + " " + imageNumber
    invalidNumberRecords.add([ caxNumber, chartCompName, chartCompVersion, imageName, imageNumber])
}

def nameMismatch(nameMismatchRecords, caxNumber, chartCompName, scasCompName, imageName, imageNumber) {
    println "[WARN] Possible name mismatch:"
    println "[INFO] 3PP number: " + caxNumber
    println "[WARN] 3PP name (in csv): " + chartCompName
    println "[WARN] 3PP name (in scas): " + scasCompName
    nameMismatchRecords.add([ caxNumber, chartCompName, scasCompName, imageName, imageNumber])
}

def versionMismatch(versionMismatchRecords, caxNumber, chartCompName, chartCompVersion, scasCompVersion, imageName, imageNumber) {
    println "[WARN] Possible version mismatch:"
    println "[INFO] 3PP number: " + caxNumber
    println "[WARN] 3PP name: " + chartCompName
    println "[WARN] 3PP version (in csv): " +  chartCompVersion
    println "[WARN] 3PP version (in scas): " + scasCompVersion
    versionMismatchRecords.add([ caxNumber, chartCompName, chartCompVersion, scasCompVersion, imageName, imageNumber ])
}