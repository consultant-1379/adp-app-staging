@Library('ci_shared_library_eea4') _

import groovy.transform.Field

import com.ericsson.eea4.ci.Artifactory
import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.Notifications

@Field def arm = new Artifactory(this, "https://arm.seli.gic.ericsson.se/", "API_TOKEN_EEA")
@Field def git = new GitScm(this, 'EEA/adp-app-staging')
@Field def notif = new Notifications(this)

def SPOTFIRE_PLATFORM_ASSET_FILE = 'SPOTFIRE_PLATFORM_ASSET_FILE'

pipeline {
    options {
        buildDiscarder(logRotator(daysToKeepStr: '14', artifactDaysToKeepStr: '7'))
        disableConcurrentBuilds()
        skipDefaultCheckout()
    }
    agent {
        node {
            label 'productci'
        }
    }
    parameters {
        stashedFile(
            name: SPOTFIRE_PLATFORM_ASSET_FILE,
            description: """SF asset package file<br>
                - accepted naming convention: spotfire-platform-asset-[SF platform version]-[asset build version].zip<br>
                - e.g. spotfire-platform-asset-12.5.0-1.5.0.zip
            """
        )
        string(
            name: 'SHA256SUM',
            description: 'sha256sum hash value of the package',
            defaultValue: ""
        )
        booleanParam(
            name: 'SEND_EMAIL_NOTIFICATION',
            description: 'Send email notification if true',
            defaultValue: true
        )
    }
    environment {
        ARM_URL = 'https://arm.seli.gic.ericsson.se'
        ARM_REPO = 'proj-eea-drop-generic-local'
        ARM_PATH = 'sf-platform-asset'
        NFS_HOST = 'seliics00309.ete.ka.sw.ericsson.se'
        NFS_PORT = '22'
        NFS_PATH = '/data/nfs/product_ci/spotfire_cn'
        MOUNTED_NFS_PATH = '/data/nfs/spotfire_cn'
    }
    stages {
        stage('DryRun') {
            when {
                expression { params.DRY_RUN }
            }
            steps {
                script {
                    dryRun()
                }
           }
        }

        stage('CleanWorkspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout - scripts') {
            steps{
                script{
                    git.sparseCheckout("technicals/")
                }
            }
        }

        stage('Preparation') {
            steps {
                script {
                    if (!env.SPOTFIRE_PLATFORM_ASSET_FILE_FILENAME) {
                        error "SPOTFIRE_PLATFORM_ASSET_FILE must be specified!"
                    }
                    if (!params.SHA256SUM) {
                        error "SHA256SUM must be specified!"
                    }
                    try {
                        echo "Unstash uploaded file: ${SPOTFIRE_PLATFORM_ASSET_FILE} ..."
                        unstash SPOTFIRE_PLATFORM_ASSET_FILE
                        sh "mv ${SPOTFIRE_PLATFORM_ASSET_FILE} ${env.SPOTFIRE_PLATFORM_ASSET_FILE_FILENAME}"

                        if (fileExists("${env.SPOTFIRE_PLATFORM_ASSET_FILE_FILENAME}")) {
                            echo "Uploaded file exists: ${env.SPOTFIRE_PLATFORM_ASSET_FILE_FILENAME}"
                        } else {
                            error "Uploaded file does NOT exists: ${env.SPOTFIRE_PLATFORM_ASSET_FILE_FILENAME}!"
                        }

                        echo "Generate uploaded zip checksum ..."
                        env.SPOTFIRE_PLATFORM_ASSET_FILE_SHA256SUM = generateFileCheckSum("${env.SPOTFIRE_PLATFORM_ASSET_FILE_FILENAME}")
                        echo "Generated 'sha256sum' checksum of local file '${env.SPOTFIRE_PLATFORM_ASSET_FILE_FILENAME}':\n|${env.SPOTFIRE_PLATFORM_ASSET_FILE_SHA256SUM}|"

                        echo "Verify uploaded zip checksum ..."
                        if (env.SPOTFIRE_PLATFORM_ASSET_FILE_SHA256SUM.contains("${params.SHA256SUM}")) {
                            echo "Checksum is OK..."
                        } else {
                            error "ZIP 'sha256sum' checksums doesn't match!\n - local: |${env.SPOTFIRE_PLATFORM_ASSET_FILE_SHA256SUM}|\n - input: |${params.SHA256SUM}|"
                        }
                    }
                    catch (err) {
                        error("${STAGE_NAME} FAILED!\nERROR: ${err}")
                    }
                }
            }
        }

        stage('Check uploaded filename') {
            steps {
                script {
                    def validatorPattern = /(spotfire-platform-asset-(\d+(\.\d+)+)-((\d+(\.\d+)+)(-\d+)?))\.zip/
                    def matcher = ("${env.SPOTFIRE_PLATFORM_ASSET_FILE_FILENAME}" =~ validatorPattern)
                    if (matcher.matches()) {
                        env.SF_ASSET_VERSION = matcher[0][1]
                        env.SF_ASSET_PLATFORM_VERSION = matcher[0][2]
                        env.SF_ASSET_BUILD_VERSION = matcher[0][4]
                        echo "- SF full version: ${env.SF_ASSET_VERSION}"
                        echo "- SF platform version: ${env.SF_ASSET_PLATFORM_VERSION}"
                        echo "- SF build version: ${env.SF_ASSET_BUILD_VERSION}"
                    } else {
                        msg = "${STAGE_NAME} FAILED! Wrong input filename format!"
                        msg += "\n - filename: ${env.SPOTFIRE_PLATFORM_ASSET_FILE_FILENAME}"
                        msg += "\n - accepted naming: 'spotfire-platform-asset-<SF platform version>-<asset build version>.zip'"
                        msg += "\n - e.g.: 'spotfire-platform-asset-12.5.0-1.5.0-120124.zip'"
                        msg += "\n - validatorPattern: ${validatorPattern}"
                        error "${msg}"
                    }
                    env.ARM_PATH_AND_FILENAME = "${env.ARM_PATH}/${env.SPOTFIRE_PLATFORM_ASSET_FILE_FILENAME}"
                    env.ARM_PATH_FULL = "${env.ARM_URL}/artifactory/${env.ARM_REPO}/${env.ARM_PATH_AND_FILENAME}"
                    env.NFS_PATH_FULL = "${env.MOUNTED_NFS_PATH}/${SF_ASSET_VERSION}"
                }
            }
        }

        stage('Set build description') {
            steps {
                script {
                    currentBuild.description = "Version: ${env.SF_ASSET_VERSION}"
                    currentBuild.description += "<br>ARM url: <a href='${env.ARM_PATH_FULL}'>link</a>"
                    currentBuild.description += "<br>NFS path: ${env.NFS_PATH_FULL}"
                }
            }
        }

        stage('Check file in arm') {
            steps {
                script {
                    try {
                        withCredentials([string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                            arm.setUrl(env.ARM_URL, "${API_TOKEN_EEA}")
                            arm.setRepo(env.ARM_REPO)
                            if (arm.checkIfArtifactExists(env.ARM_REPO, env.ARM_PATH_AND_FILENAME)) {
                                error "${STAGE_NAME} FAILED! Spotfire platform asset file already exists in the ARM!\n - repo: ${env.ARM_REPO}\n - path: ${env.ARM_PATH_AND_FILENAME}\n - url: ${env.ARM_PATH_FULL}"
                            }
                        }
                    }
                    catch (err) {
                        error("${STAGE_NAME} FAILED!\nERROR: ${err}")
                    }
                }
            }
        }

        stage('Unzip file') {
            steps {
                script {
                    try {
                        echo "Unzip ${env.SPOTFIRE_PLATFORM_ASSET_FILE_FILENAME} to dir: ${env.SF_ASSET_VERSION} ..."
                        unzip zipFile: "${env.SPOTFIRE_PLATFORM_ASSET_FILE_FILENAME}", dir: "${env.SF_ASSET_VERSION}"
                    }
                    catch (err) {
                        error("${STAGE_NAME} FAILED!\nERROR: ${err}")
                    }
                }
            }
        }

        stage('Check zip structure') {
            steps {
                script {
                    try {
                        if (!fileExists("${env.SF_ASSET_VERSION}/${env.SF_ASSET_VERSION}")) {
                            msg = "${STAGE_NAME} FAILED! Wrong input file structure!"
                            msg += "\n - filename: ${env.SPOTFIRE_PLATFORM_ASSET_FILE_FILENAME}"
                            msg += "\n - a subdir equal to the filename must exist in the compressed file: 'spotfire-platform-asset-<SF platform version>-<asset build version>'"
                            msg += "\n - e.g.: 'spotfire-platform-asset-12.5.0-1.5.0-120124'"
                            error "${msg}"
                        }
                    }
                    catch (err) {
                        error("${STAGE_NAME} FAILED!\nERROR: ${err}")
                    }
                }
            }
        }

        stage('Upload to arm') {
            steps {
                script {
                    try {
                        echo "Upload file to artifactory ..."
                        arm.deployArtifact("${env.SPOTFIRE_PLATFORM_ASSET_FILE_FILENAME}", "${env.ARM_PATH_AND_FILENAME}")

                        echo "Check if uploaded file exists ..."
                        if (!arm.checkIfArtifactExists(env.ARM_REPO, env.ARM_PATH_AND_FILENAME)) {
                            error "Spotfire platform asset file does NOT exists in the ARM!\n - repo: ${env.ARM_REPO}\n - path: ${env.ARM_PATH_AND_FILENAME}\n - url: ${env.ARM_PATH_FULL}"
                        }
                    }
                    catch (err) {
                        error("${STAGE_NAME} FAILED!\nERROR: ${err}")
                    }
                }
            }
        }

        stage('Verify arm checksum') {
            steps {
                script {
                    try {
                        echo "Download arm hash from artifactory ..."
                        def hashFile = "${env.SPOTFIRE_PLATFORM_ASSET_FILE_FILENAME}.sha256"
                        arm.downloadArtifact("${ARM_PATH_AND_FILENAME}.sha256", hashFile)
                        downloadedArmHash = sh(returnStdout: true, script: "cat ${hashFile}").trim()

                        echo "Verify arm checksum ..."
                        if (env.SPOTFIRE_PLATFORM_ASSET_FILE_SHA256SUM.contains("${downloadedArmHash}")) {
                            echo "Checksum is OK..."
                        } else {
                            error "ARM 'sha256sum' checksums doesn't match!\n - local: |${env.SPOTFIRE_PLATFORM_ASSET_FILE_SHA256SUM}|\n - arm: |${downloadedArmHash}|"
                        }
                    }
                    catch (err) {
                        error("${STAGE_NAME} FAILED!\nERROR: ${err}")
                    }
                }
            }
        }

        stage('Upload to nfs') {
            steps {
                script {
                    try {
                        echo "Upload source dir ${SF_ASSET_VERSION} to nfs target: ${NFS_PATH} ..."
                        withCredentials([usernamePassword(credentialsId: 'hub-eceabuild-user', usernameVariable: 'NFS_USER', passwordVariable: 'NFS_PASSWORD')]) {
                            sh '''
                            sshpass -p ${NFS_PASSWORD} sftp -o StrictHostKeyChecking=no -o BatchMode=no -P ${NFS_PORT} ${NFS_USER}@${NFS_HOST}:${NFS_PATH} <<EOF
                            put -r ${SF_ASSET_VERSION}/${SF_ASSET_VERSION}
                            bye
                            EOF
                            '''.stripIndent()
                        }
                    }
                    catch (err) {
                        error("${STAGE_NAME} FAILED!\nERROR: ${err}")
                    }
                }
            }
        }

        stage('Verify nfs checksum') {
            steps {
                script {
                    try {
                        echo "Generate checksum ..."
                        env.SPOTFIRE_PLATFORM_ASSET_DIR_SHA256SUM = generateDirectoryCheckSum("${env.SF_ASSET_VERSION}/${env.SF_ASSET_VERSION}")
                        echo "Generated 'sha256sum' checksum of local dir '${env.SF_ASSET_VERSION}':\n|${env.SPOTFIRE_PLATFORM_ASSET_DIR_SHA256SUM}|"

                        env.SPOTFIRE_PLATFORM_ASSET_MOUNTED_NFS_DIR_SHA256SUM = generateDirectoryCheckSum("${env.NFS_PATH_FULL}")
                        echo "Generated 'sha256sum' checksum of nfs dir '${env.NFS_PATH_FULL}':\n|${env.SPOTFIRE_PLATFORM_ASSET_MOUNTED_NFS_DIR_SHA256SUM}|"

                        echo "Verify nfs checksum ..."
                        if (env.SPOTFIRE_PLATFORM_ASSET_DIR_SHA256SUM.contains("${env.SPOTFIRE_PLATFORM_ASSET_MOUNTED_NFS_DIR_SHA256SUM}")) {
                            echo "Checksum is OK..."
                        } else {
                            error "NFS 'sha256sum' checksums doesn't match!\n - local: |${env.SPOTFIRE_PLATFORM_ASSET_DIR_SHA256SUM}|\n - nfs: |${env.SPOTFIRE_PLATFORM_ASSET_MOUNTED_NFS_DIR_SHA256SUM}|"
                        }
                    }
                    catch (err) {
                        error("${STAGE_NAME} FAILED!\nERROR: ${err}")
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                if (!params.DRY_RUN && params.SEND_EMAIL_NOTIFICATION) {
                    try {
                        def recipient = "PDLEEA4PRO@pdl.internal.ericsson.com, markku.mikkola@ericsson.com, mika.laaksonen@ericsson.com"
                        def subject = "${env.JOB_NAME} (${env.BUILD_NUMBER}) ${currentBuild.currentResult}"
                        def body = "<a href=\"${env.BUILD_URL}\">${env.BUILD_URL}</a><br>Spotfire Platform Asset Uploader job finished with ${currentBuild.currentResult} for package: ${env.SPOTFIRE_PLATFORM_ASSET_FILE_FILENAME}<br>"
                        notif.sendMail(subject, body, recipient, 'text/html')
                    } catch (err) {
                        echo "sendMail FAILED. Caught ${err}"
                    }
                }
            }
        }
        cleanup {
            cleanWs()
        }
    }
}

String generateFileCheckSum(String fileName) {
    return sh(returnStdout: true, script: "sha256sum '${fileName}'").trim()
}

String generateDirectoryCheckSum(String directory) {
    return sh(returnStdout: true, script: "cd ${directory} && ${WORKSPACE}/technicals/shellscripts/sha256_directory.sh")
}
