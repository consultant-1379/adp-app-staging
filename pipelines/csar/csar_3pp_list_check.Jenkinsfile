@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import com.ericsson.eea4.ci.ScasUtils
import com.ericsson.eea4.ci.Artifactory

@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def scas = new ScasUtils(this)

pipeline {
    options {
        buildDiscarder(logRotator(daysToKeepStr: '7', artifactDaysToKeepStr: "7"))
        skipDefaultCheckout()
    }
    agent {
        node {
            label 'productci'
        }
    }
    parameters {
        string(name: 'PACKAGE_NAME', description: 'Name of the CSAR package e.g.: csar-package', defaultValue: 'csar-package')
        string(name: 'LIST_SUFFIX', description: '3PP list file name suffix e.g.: 3pp_list.csv', defaultValue: '3pp_list.csv')
        string(name: 'PACKAGE_REPO_URL', description: "The url of the artifactory", defaultValue: 'https://arm.seli.gic.ericsson.se')
        string(name: 'PACKAGE_REPO', description: 'CSAR package repo e.g.: proj-eea-drop-generic-local', defaultValue: 'proj-eea-drop-generic-local')
        string(name: 'PACKAGE_VERSION', description: 'CSAR package version e.g.: 1.0.0-1', defaultValue: '')
    }
    environment {
        CSV_NAME = "${params.PACKAGE_NAME}-${params.PACKAGE_VERSION}.${params.LIST_SUFFIX}"
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
                    gitadp.checkout(env.MAIN_BRANCH, 'adp-app-staging')
                }
            }
        }
        stage('Prepare') {
            steps {
                dir('adp-app-staging') {
                    script {
                        checkoutGitSubmodules()
                        sh './bob/bob clean'  //simple bob command to init vars
                    }
                }
            }
        }
        stage ('Download 3pp_list') {
            steps {
                catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                    script {
                        try {
                            withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                         string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                         usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                                def arm = new Artifactory(this, "${params.PACKAGE_REPO_URL}", "$API_TOKEN_EEA")
                                arm.setRepo("${params.PACKAGE_REPO}")
                                arm.downloadArtifact( "${env.CSV_NAME}", "${env.CSV_NAME}")
                            }
                        }
                        catch (err) {
                            error "${STAGE_NAME} FAILED:\n${err}"
                        } finally {
                            archiveArtifacts artifacts: CSV_NAME, allowEmptyArchive: true
                        }
                    }
                }
            }
        }
        stage ('Download data from SCAS'){
            steps {
                catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                    script {
                        try {
                            def csvContent = readCSV file: "${WORKSPACE}/${env.CSV_NAME}", format: CSVFormat.DEFAULT.withHeader()
                            int rowNumber = 0
                            def listOfCaxs = []
                            while ( rowNumber < (csvContent.size()) ){
                                listOfCaxs.add (csvContent[rowNumber].get('versionCAX/numberCAX'))
                                rowNumber++
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
        stage ('Check 3PPs ') {
            steps {
                catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                    script {
                        try {
                            def csvContent = readCSV file: "${WORKSPACE}/${env.CSV_NAME}", format: CSVFormat.DEFAULT.withHeader()
                            def scasData = readJSON file: "${WORKSPACE}/searchComponentByNumber.list.response.json"
                            def invalidNumberRecords = []
                            def nameMismatchRecords = []
                            def versionMismatchRecords = []
                            int rowNumber = 0
                            while ( rowNumber < (csvContent.size()) ) {
                                if (!scasData.findAll{ map -> map.compProdNumber == (csvContent[rowNumber].get('versionCAX/numberCAX')) } ) {
                                    invalidNumber(invalidNumberRecords, rowNumber, csvContent[rowNumber].get('versionCAX/numberCAX'), csvContent[rowNumber].get('3ppName'), csvContent[rowNumber].get('3ppVersion'), csvContent[rowNumber].get('imageName'), csvContent[rowNumber].get('imageNumber'))
                                } else {
                                    scasData.each {
                                        if ( (csvContent[rowNumber].get('versionCAX/numberCAX')) == it.compProdNumber ) {
                                            if ( (csvContent[rowNumber].get('3ppName')) != it.compName ) {
                                                nameMismatch(nameMismatchRecords, rowNumber, csvContent[rowNumber].get('versionCAX/numberCAX'), csvContent[rowNumber].get('3ppName'), it.compName, csvContent[rowNumber].get('imageName'), csvContent[rowNumber].get('imageNumber'))
                                                if ( (csvContent[rowNumber].get('3ppVersion')) != it.compVersion ) {
                                                    versionMismatch(versionMismatchRecords, rowNumber, csvContent[rowNumber].get('versionCAX/numberCAX'), csvContent[rowNumber].get('3ppName'), csvContent[rowNumber].get('3ppVersion'), it.compVersion, csvContent[rowNumber].get('imageName'), csvContent[rowNumber].get('imageNumber'))
                                                }
                                            } else if ( (csvContent[rowNumber].get('3ppVersion')) != it.compVersion ) {
                                                versionMismatch(versionMismatchRecords, rowNumber, csvContent[rowNumber].get('versionCAX/numberCAX'), csvContent[rowNumber].get('3ppName'), csvContent[rowNumber].get('3ppVersion'), it.compVersion, csvContent[rowNumber].get('imageName'), csvContent[rowNumber].get('imageNumber'))
                                            }
                                        }
                                    }
                                }
                                rowNumber++
                            }
                            if (invalidNumberRecords) { writeCSV file: 'invalid-cax-number.csv', records: invalidNumberRecords, format: CSVFormat.DEFAULT.withHeader('csv.row.num','csv.3pp.num','csv.3pp.name','csv.3pp.ver','csv.img.name','csv.img.num')}
                            if (nameMismatchRecords) { writeCSV file: 'name-mismatch.csv', records: nameMismatchRecords, format: CSVFormat.DEFAULT.withHeader('csv.row.num','csv.3pp.num','csv.3pp.name','scas.3pp.name','csv.img.name','csv.img.num') }
                            if (versionMismatchRecords) { writeCSV file: 'version-mismatch.csv', records: versionMismatchRecords, format: CSVFormat.DEFAULT.withHeader('csv.row.num','csv.3pp.num','csv.3pp.name','csv.3pp.ver','scas.3pp.ver','csv.img.name','csv.img.num') }
                        }
                        catch (err) {
                            error "${STAGE_NAME} FAILED:\n${err}"
                        } finally {
                            archiveArtifacts artifacts: 'invalid-cax-number.csv', allowEmptyArchive: true
                            archiveArtifacts artifacts: "name-mismatch.csv", allowEmptyArchive: true
                            archiveArtifacts artifacts: 'version-mismatch.csv', allowEmptyArchive: true
                        }
                    }
                }
            }
        }
    }
    post{
        cleanup {
            cleanWs()
        }
    }
}

def invalidNumber(invalidNumberRecords, rowNumber, caxNumber, csvCompName, csvCompVersion, imageName, imageNumber ){
    println "[INFO] " + rowNumber + ":"
    println "[ERROR] Invalid number: " + caxNumber
    println "[INFO] in image: " + imageName + " " + imageNumber
    invalidNumberRecords.add([ rowNumber, caxNumber, csvCompName, csvCompVersion, imageName, imageNumber])
}

def nameMismatch(nameMismatchRecords, rowNumber, caxNumber, csvCompName, scasCompName, imageName, imageNumber) {
    println "[INFO] " + rowNumber + ":"
    println "[WARN] Possible name mismatch:"
    println "[INFO] 3PP number: " + caxNumber
    println "[WARN] 3PP name (in csv): " + csvCompName
    println "[WARN] 3PP name (in scas): " + scasCompName
    nameMismatchRecords.add([ rowNumber, caxNumber, csvCompName, scasCompName, imageName, imageNumber])
}

def versionMismatch(versionMismatchRecords, rowNumber, caxNumber, csvCompName, csvCompVersion, scasCompVersion, imageName, imageNumber) {
    println "[INFO] " + rowNumber + ":"
    println "[WARN] Possible version mismatch:"
    println "[INFO] 3PP number: " + caxNumber
    println "[WARN] 3PP name: " + csvCompName
    println "[WARN] 3PP version (in csv): " +  csvCompVersion
    println "[WARN] 3PP version (in scas): " + scasCompVersion
    versionMismatchRecords.add([ rowNumber, caxNumber, csvCompName, csvCompVersion, scasCompVersion, imageName, imageNumber ])
}
