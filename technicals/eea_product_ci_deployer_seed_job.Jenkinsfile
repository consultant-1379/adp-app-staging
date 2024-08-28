@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def git = new GitScm(this, 'EEA/adp-app-staging')

pipeline {
    agent {
        node {
            label 'master'
        }
    }
    options {
      disableConcurrentBuilds()
      skipDefaultCheckout()
      buildDiscarder(logRotator(daysToKeepStr: "7"))
    }
    tools{
        gradle "Default"
    }
    triggers {
        gerrit (
            serverName: 'GerritCentral',
            gerritProjects: [[
                compareType: 'PLAIN',
                pattern: 'EEA/adp-app-staging',
                branches: [[ compareType: 'PLAIN', pattern: env.MAIN_BRANCH ]],
                filePaths: [[ compareType: 'ANT', pattern: 'jobs/eea_deployer/**' ]]
            ]],
            triggerOnEvents:  [
                [
                    $class              : 'PluginChangeMergedEvent',
                    excludeDrafts       : true,
                    excludeTrivialRebase: false,
                    excludeNoCodeChange : false
                ],
                [
                $class                      : 'PluginCommentAddedContainsEvent',
                    commentAddedCommentContains : '.*rebuild.*'
                ]
            ]
        )
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

        stage('Checkout'){
            steps{
                script{
                    git.checkoutRefSpec("${GERRIT_REFSPEC}","FETCH_HEAD", 'adp-app-staging')
                }
            }
        }

        stage('Stage Job DSL generation and Job DSL content validation'){
            steps {
                jobDsl targets :'adp-app-staging/jobs/eea_deployer/*.groovy'
                script {
                    try{
                        sh(
                            script: "${WORKSPACE}/adp-app-staging/technicals/shellscripts/collect_job_names.sh  ${WORKSPACE}/adp-app-staging/jobs/eea_deployer"
                        )
                        def job_names = readFile("env_inject")
                        build job: "dry-runs-job", parameters: [booleanParam(name: 'dry_run', value: false), stringParam(name: 'JOB_NAMES', value : "${job_names}")]
                    }
                    catch (err) {
                        echo "Caught: ${err}"
                        currentBuild.result = 'FAILURE'
                    }
                }
            }
        }
    }
    post {
        cleanup {
            cleanWs()
        }
        failure {
            script{
                def recipient = '42a7977a.ericsson.onmicrosoft.com@emea.teams.ms'
                mail subject: "${env.JOB_NAME} (${env.BUILD_NUMBER}) failed",
                body: "It appears that ${env.BUILD_URL} is failing, somebody should do something about that",
                to: "${recipient}",
                replyTo: "${recipient}",
                from: 'eea-seliius27190@ericsson.com'
            }
        }
    }
}
