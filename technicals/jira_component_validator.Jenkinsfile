@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import com.ericsson.eea4.ci.Notifications

@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def notif = new Notifications(this)

pipeline {
    options {
        buildDiscarder(logRotator(daysToKeepStr: "7"))
        skipDefaultCheckout()
        disableConcurrentBuilds()
    }
    agent {
        node {
            label 'productci'
        }
    }

    triggers { cron('H 4 * * 1-5') }

    stages {
        stage ('Params DryRun check') {
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
                script {
                    gitadp.checkout('master', '')
                }
            }
        }

        stage('Prepare bob') {
            steps {
                checkoutGitSubmodules()
            }
        }

        stage ('Run Jira component validator') {
            steps {
                script {
                    echo "Running a Jira Components Validator"
                    withCredentials([string(credentialsId: 'jira-eceaconfl-token', variable: 'JIRA_API_TOKEN')]) {
                        sh './bob/bob  -r ruleset2.0.yaml run-jira-component-validator > jira_component_validator.log'
                    }
                    def fileContent = readFile "${WORKSPACE}/jira_component_validator.log"
                    if (fileContent.find("ERROR") && fileContent.find("Components with errors")) {
                        def componentsWithErrorsNum = (fileContent =~ /Components with errors\D+(\d+)/)[0][1].toInteger()
                        if (componentsWithErrorsNum > 0) {
                            def lines = fileContent.readLines()
                            componentsToCheckList = ""
                            lines.each { String line ->
                                if (line.contains("Components with errors") || line.contains("ERROR")) {
                                    componentsToCheckList += "<br> ${line}"
                                    println(line)
                                }
                            }
                            def bodyMessage = """<a href=\"${env.BUILD_URL}\">${env.BUILD_URL}</a><p>Components with errors have been found by Jira Component Validator:<br>
                                                ${componentsToCheckList}<br>
                                                Please check</p>
                                            """
                            notif.sendMail("A Jira Component Validator logfile has errors", bodyMessage, "eva.varkonyi@ericsson.com,PDLAINVAUT@pdl.internal.ericsson.com", "text/html")
                        }
                    }
                }
            }
        }
    }
    post {
        always {
            archiveArtifacts artifacts: "jira_component_validator.log", allowEmptyArchive: true
        }
        failure {
            script {
                notif.sendMail("A Jira Component Validator job has failed", "Current build ${env.BUILD_URL} has failed. Please take a look", "42a7977a.ericsson.onmicrosoft.com@emea.teams.ms")
            }
        }
        cleanup {
            cleanWs()
        }
    }
}
