@Library('ci_shared_library_eea4') _

pipeline {
    options {
        disableConcurrentBuilds()
        skipDefaultCheckout()
        buildDiscarder(logRotator(artifactDaysToKeepStr: "7", daysToKeepStr: "14"))
    }
    agent {
        node {
            label 'productci'
        }
    }
    triggers { cron('*/5 * * * *') }
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
        stage('Execute prepare upgrade when run in Jenkins master'){
            when {
                expression { env.MAIN_BRANCH == 'master' }
            }
            steps {
                script {
                    try {
                        build job: "eea-product-prepare-upgrade", parameters: [
                            booleanParam(name: 'DRY_RUN', value: false)
                        ], wait: true
                    } catch (err) {
                        echo "Caught: ${err}"
                        error "eea-product-prepare-upgrade FAILED"
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
