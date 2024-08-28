@Library('ci_shared_library_eea4') _

pipeline {
    options {
        buildDiscarder(logRotator(daysToKeepStr: '14', artifactDaysToKeepStr: '7'))
        skipDefaultCheckout()
        disableConcurrentBuilds()
    }
    agent {
        node {
            label 'productci'
        }
    }

    parameters {
        string(name: 'NEW_BFU_GATE', description: 'Git tag of the new BFU gate e.g: eea4_4.4.0_pra', defaultValue: '')
        string(name: 'GIT_TAG_STRING', description: 'The commit message for the latest_release and latest_BFU_gate Git tags. E.g: EEA 4.4.0 PRA release', defaultValue: 'PRA release')
        string(name: 'BFU_GATE_VALIDATION_RUNS_NUMBER', description: 'This parameter sets a number of bfu gate validation runs should be utilized before tagging stage run', defaultValue: '5')
        string(name: 'BASELINE_INSTALL_JENKINSFILE_GERRIT_REFSPEC', description: 'This parameter sets the JENKINSFILE_GERRIT_REFSPEC eea-application-staging-product-baseline-install Jenkins job', defaultValue: '${MAIN_BRANCH}')
        string(name: 'UPGRADE_JENKINSFILE_GERRIT_REFSPEC', description: 'This parameter sets the JENKINSFILE_GERRIT_REFSPEC eea-common-product-upgrade', defaultValue: '${MAIN_BRANCH}')
    }

    environment {
        RUN_BFU_GATE_TAGGING = false
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


        stage('bfu-gate validating'){
            steps {
                script {
                    for (int i = 0; i < params.BFU_GATE_VALIDATION_RUNS_NUMBER.toInteger(); i++) {
                        try {
                            echo "Running the eea-product-release-loop-bfu-gate-upgrade ${i} validation..."
                            build job: "eea-product-release-loop-bfu-gate-upgrade", parameters: [
                                booleanParam(name: 'DRY_RUN', value: false),
                                stringParam(name: "NEW_BFU_GATE", value: params.NEW_BFU_GATE),
                                stringParam(name: 'BASELINE_INSTALL_JENKINSFILE_GERRIT_REFSPEC', value: params.BASELINE_INSTALL_JENKINSFILE_GERRIT_REFSPEC),
                                stringParam(name: 'UPGRADE_JENKINSFILE_GERRIT_REFSPEC', value: params.UPGRADE_JENKINSFILE_GERRIT_REFSPEC)
                            ], wait: true
                        } catch (err) {
                            echo "Caught: ${err}"
                            error "eea-product-release-loop-bfu-gate-upgrade FAILED"
                        }
                    }
                }
            }
        }
/*
        stage('bfu-gate validating check latest runs'){
            steps {

                // TODO: it's needed to implement a check of the latest 5 runs of the eea-product-release-loop-bfu-gate-upgrade pipeline if they were successful and have the same bfu gate version
                // An example of a possible code snippet has been provided in the EEAEPP-84706 ticket. If it was 5 successful builds with the same bfu gate version we can run bfu gate tagging stage
            }
        }
*/
    }
    post {
        failure {
            script{
                def recipient = 'PDLEEA4PRO@pdl.internal.ericsson.com'
                mail subject: "${env.JOB_NAME} (${env.BUILD_NUMBER}) failed",
                body: "Upgrade from the new BFU gate : ${params.NEW_BFU_GATE} to the latest baseline failing",
                to: "${recipient}",
                replyTo: "${recipient}",
                from: 'eea-seliius27190@ericsson.com'
            }
        }
        cleanup {
            cleanWs()
        }
    }
}
