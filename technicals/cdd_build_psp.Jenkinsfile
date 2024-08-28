@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.Artifactory
import groovy.transform.Field

@Field def gitcdd = new GitScm(this, 'EEA/cdd')
@Field def arm = new Artifactory(this, "https://arm.seli.gic.ericsson.se/", "API_TOKEN_EEA")

pipeline {
    options { buildDiscarder(logRotator(daysToKeepStr: "30")) }
    agent { node { label "productci" }}
    parameters {
        string(name: 'NEW_PSP_VERSION', description: 'New version of the product specifc package e.g.: 1.0.0', )
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

        stage('Cleanup workspace') {
            steps {
                script {
                    cleanWs()
                }
            }
        }

        stage('Checkout CDD') {
            steps {
                script {
                    gitcdd.checkout('master', '')
                }
            }
        }

        stage('Build swdp-cdd package') {
            steps {
                script {
                    try {
                        sh 'tar -cvzf swdp-cdd.tar.gz --directory $(dirname $(find product/ -type d -name "swdp-cdd")) swdp-cdd'
                    } catch (err) {
                        echo "Caught: ${err}"
                        error "Failed to create swdp-cdd.tar.gz"
                    } finally {
                        try {
                            archiveArtifacts "swdp-cdd.tar.gz"
                        } catch (err) {
                            echo "Caught archiveArtifacts ERROR: ${err}"
                        }
                    }
                }
            }
        }

        stage('Upload to artifactory') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                        arm.setUrl("https://arm.seli.gic.ericsson.se/", "$API_TOKEN_EEA")
                        arm.setRepo("proj-eea4-other-dev-local")
                        arm.deployArtifact("swdp-cdd.tar.gz", "com/ericsson/eea4/cdd-product-specific-pipeline/${params.NEW_PSP_VERSION}/swdp-cdd.tar.gz")
                    }
                }
            }
        }
    }
    post {
        cleanup {
            cleanWs()
        }
    }
}