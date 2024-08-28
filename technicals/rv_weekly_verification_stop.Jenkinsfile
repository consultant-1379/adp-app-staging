@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import com.ericsson.eea4.ci.CiDashboard
import com.ericsson.eea4.ci.CommonUtils

@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def dashboard = new CiDashboard(this)

pipeline {
    agent {
        node {
            label 'productci'
        }
    }
    options {
        skipDefaultCheckout()
        buildDiscarder(logRotator(daysToKeepStr:'14', artifactDaysToKeepStr: "10"))
    }
    parameters {
        string(name: 'CHART_NAME', description: 'Chart name e.g.: ', defaultValue: 'eric-eea-int-helm-chart')
        string(name: 'CHART_REPO', description: 'Chart repo e.g.: https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm', defaultValue: 'https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/')
        string(name: 'CHART_VERSION', description: 'Chart version e.g.: 1.0.0-1', defaultValue: '')
        string(name: 'WEEKLY_DROP_TAG', description: 'weekly drop what is need to be closed e.g. weekly_drop_2023_w7', defaultValue: 'weekly_drop_<year>_<week number>')
        choice(name: 'RESULT', choices: ['PASSED','FAILED'], description: 'weekly drop test result')
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

        stage('Stop dashboard execution') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    script {
                        echo "stop execution"
                        dashboard.finishExecution("rv-loops","${params.RESULT}","${params.WEEKLY_DROP_TAG}","${params.CHART_VERSION}")
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
