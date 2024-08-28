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
                filePaths: [[ compareType: 'ANT', pattern: 'jobs/eea_ci_config/**' ]]
            ]],
            triggerOnEvents:  [
                [
                    $class : 'PluginChangeMergedEvent',
                    excludeDrafts       : true,
                    excludeTrivialRebase: false,
                    excludeNoCodeChange : false
                ],
                [
                    $class : 'PluginCommentAddedContainsEvent',
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
                dir('adp-app-staging'){
                    jobDsl targets : 'jobs/eea_ci_config/*.groovy'
                    script {
                        try{
                            sh(
                                script : "technicals/shellscripts/collect_job_names.sh jobs/eea_ci_config"
                            )
                            def job_names = readFile("env_inject")
                            build job : "dry-runs-job", parameters : [booleanParam(name : 'dry_run', value : false), stringParam(name : 'JOB_NAMES', value : "${job_names}")]
                        }
                        catch (err) {
                            echo "Caught: ${err}"
                            currentBuild.result = 'FAILURE'
                        }
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
