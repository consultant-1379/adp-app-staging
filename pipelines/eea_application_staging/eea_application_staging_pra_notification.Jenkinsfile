@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def git = new GitScm(this, 'EEA/adp-app-staging')

pipeline {
    agent {
        node {
            label 'productci'
        }
    }
    options {
        buildDiscarder(logRotator(daysToKeepStr: "14", artifactDaysToKeepStr: "7"))
    }
    parameters {
        string(name: 'PARENT_EXECUTION_NAME', description: 'ADP loop name', defaultValue: '')
        string(name: 'CHART_NAME', description: 'ADP GS name', defaultValue: '')
        string(name: 'CHART_REPO', description: 'ADP GS repo', defaultValue: '')
        string(name: 'CHART_VERSION', description: 'ADP GS version', defaultValue: '')
        string(name: 'EEA_VERSION', description: 'EEA Product version', defaultValue: '')
        string(name: 'SPINNAKER_TRIGGER_URL', description: 'Spinnaker pipeline triggering url', defaultValue: '')
        string(name: 'SPINNAKER_ID', description: "The spinnaker execution's id", defaultValue: 'test')
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

        stage('Set Spinnaker link'){
            steps {
                script {
                    if ( params.SPINNAKER_ID != '' ) {
                        currentBuild.description = '<a href="https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/details/' + params.SPINNAKER_ID + '">Spinnaker URL: ' + params.SPINNAKER_ID + '</a>'
                    }
                }
            }
        }

        stage('get email') {
            steps {
                script {
                    try{
                        def result = sh (
                            script: """
grep "$PARENT_EXECUTION_NAME"  product-ci-loop-triggers.md | awk -F"[|]" '{print \$4}'|awk -F"[:,)]" '{print \$2}'
                                    """,
                             returnStdout : true
                        ).trim()
                        echo """ $result """
                        env.MAIL_TO = result
                    }catch (err) {
                        echo "Caught: ${err}"
                        currentBuild.result = 'FAILURE'
                    }
                }
            }
        }
    }
    post {
        success {
            script{
                def recipient = "${env.MAIL_TO},b973ce22.ericsson.onmicrosoft.com@emea.teams.ms,PDLEEA3PPH@pdl.internal.ericsson.com,PDLAINVAUT@pdl.internal.ericsson.com"
                mail subject: "Change in ADP GS PRA version in EEA4 baseline",
                body: """
ADP GS chart name : ${CHART_NAME}
ADP GS chart repo : ${CHART_REPO}
ADP GS chart version : ${CHART_VERSION}
EEA version : ${EEA_VERSION}
Spinnaker Trigger : https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/details/${SPINNAKER_TRIGGER_URL}

""",
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
