@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def git = new GitScm(this, 'EEA/cnint')

pipeline {
    agent {
        node {
            label 'productci'
        }
    }
    options {
      skipDefaultCheckout()
      buildDiscarder(logRotator(daysToKeepStr: "7"))
    }

    triggers { cron('@midnight') }

    environment {
        INT_HELM_CHART_YAML_FILENAME = 'eric-eea-int-helm-chart/Chart.yaml'
        REPORT_FILENAME = 'baseline-artifactory-diff-report.txt'
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

        stage('Checkout') {
            steps {
                script {
                    git.checkout(env.MAIN_BRANCH, '')
                }
            }
        }

        stage('Prepare') {
            steps {
                checkoutGitSubmodules()
            }
        }

        stage('Check GS versions') {

            steps {
                echo "bob init"
                withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                                 usernamePassword(credentialsId: 'ECEAART_SEROGIC_API_KEY', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
                                 usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
                                 string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP')]) {
                            sh './bob/bob init'
                }
                echo "get GS versions from artifactory"
                withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                                 usernamePassword(credentialsId: 'ECEAART_SEROGIC_API_KEY', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
                                 usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
                                 string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP')]) {
                            sh './bob/bob get-gs-versions'
                }

                script {
                    env.FAILED_SERVICES = ''

                    // collect gs from chart to a list
                    def datas = readYaml file: env.INT_HELM_CHART_YAML_FILENAME
                    def dependencies = datas.dependencies

                    // iterate over services
                    datas.dependencies.each {dependency ->
                        if (dependency.repository.contains('proj-adp-gs-all-helm')) {
                            env.BASELINE_VERSION = dependency.version
                            env.SERVICE_NAME = dependency.name

                            // check latest from artifactory
                            env.ARTIFACTORY_VERSION = sh (script:"""
                                cat artifactory_list.json |  jq -r '[.[] | select((.name=="myrepo/${env.SERVICE_NAME}") and ( .version|test(".\\\\+") ))][0]'| jq -r .version
                                """,
                                returnStdout: true).trim()

                            env.MSG = "Service: ${env.SERVICE_NAME} Artifactory version: ${env.ARTIFACTORY_VERSION} Baseline version: ${env.BASELINE_VERSION}"
                            echo env.MSG

                            // check if versions are the same and service not already in the list (because of the service aliases)
                            if ((env.BASELINE_VERSION != env.ARTIFACTORY_VERSION) && (!env.FAILED_SERVICES.contains(env.SERVICE_NAME))) {
                                env.FAILED_SERVICES = env.FAILED_SERVICES.concat("${env.MSG}\n")
                            }
                        }
                    }

                    // fail if one or more didn't match
                    if (env.FAILED_SERVICES) {
                        // write report content to file and archive it
                        writeFile(file: "${WORKSPACE}/${env.REPORT_FILENAME}", text: env.FAILED_SERVICES)
                        archiveArtifacts "*.txt"
                        error "Baseline and artifactory PRA versions of ADP GS didn't match!\n\nenv.FAILED_SERVICES:\n${env.FAILED_SERVICES}"
                    } else {
                        echo "Baseline and artifactory PRA versions of ADP GS are the same!"
                    }
                }
            }
        }
    }

    post {
        failure {
            script{
                if (env.MAIN_BRANCH == 'master') {
                    def recipient = '0b4b5be9.ericsson.onmicrosoft.com@emea.teams.ms'
                    mail subject: "Baseline and artifactory ADP GS PRA versions mismatch",
                    body: "The following services have different PRA versions in baseline and artifactory:\n${env.FAILED_SERVICES}",
                    to: "${recipient}",
                    replyTo: "${recipient}",
                    from: 'eea-seliius27190@ericsson.com'
                }
            }
        }
        cleanup {
            cleanWs()
        }
    }
}
