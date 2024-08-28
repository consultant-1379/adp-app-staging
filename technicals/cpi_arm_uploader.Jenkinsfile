@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.Artifactory
import groovy.transform.Field

@Field def arm = new Artifactory(this, "https://arm.seli.gic.ericsson.se/", "API_TOKEN_EEA")

pipeline {
    options {
        buildDiscarder(logRotator(daysToKeepStr: "7"))
        skipDefaultCheckout()
    }
    agent {
        node {
            label "productci"
        }
    }
    parameters {
        string(name: 'SOURCE_FILE_URL', description: 'Link to file to be uploaded to Arm')
        string(name: 'ARM_UPLOAD_URL', description: 'Arm URL for file upload', defaultValue: 'https://arm.seli.gic.ericsson.se')
        choice(name: 'ARM_UPLOAD_REPO', description: 'Target Arm repo for file upload', choices: ['proj-cea-dev-local/cpi-tools', 'proj-eea-docs-drop-generic-local'])
        string(name: 'ARM_UPLOAD_PATH', description: 'Target Arm path for file upload. Eg.: ditacms/adp/certm/0.1')
        string(name: 'ARM_UPLOAD_FILE', description: 'The name with which the file will be uploaded to ARM. Eg.: certm.zip')
    }

    stages {
        stage('Params DryRun check') {
            when {
                expression { params.DRY_RUN == true}
            }
            steps {
                script {
                    dryRun()
                }
            }
        }

        stage('Get file from the specified source') {
            steps {
                script {
                    sh "wget -O ${params.ARM_UPLOAD_FILE} ${params.SOURCE_FILE_URL}"
                }
            }
        }

        stage('Upload to artifactory') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                        arm.setUrl("${params.ARM_UPLOAD_URL}", "$API_TOKEN_EEA")
                        arm.setRepo("${params.ARM_UPLOAD_REPO}/${params.ARM_UPLOAD_PATH}")
                        arm.deployArtifact("${params.ARM_UPLOAD_FILE}", "${params.ARM_UPLOAD_FILE}")
                    }
                }
            }
        }
    }
    post {
        success {
            script {
                currentBuild.description = "Uploaded artifact: <a href='${params.ARM_UPLOAD_URL}/artifactory/${params.ARM_UPLOAD_REPO}/${params.ARM_UPLOAD_PATH}'>${params.ARM_UPLOAD_URL}/artifactory/${params.ARM_UPLOAD_REPO}/${params.ARM_UPLOAD_PATH}</a>"
            }
        }
        cleanup {
            cleanWs()
        }
    }
}