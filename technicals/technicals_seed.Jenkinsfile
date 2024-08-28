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
      skipDefaultCheckout()
      disableConcurrentBuilds()
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
                disableStrictForbiddenFileVerification: false,
                filePaths: [[ compareType: 'ANT', pattern: 'technicals/**' ]]
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
                commentAddedCommentContains : '.*rebuild-seed.*'
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
                    script {
                        sh(
                            script: "(find technicals/ -name '*.groovy' -print0 | xargs -0 git diff-tree --no-commit-id --name-only -r HEAD --diff-filter=ACMRT --) > env_inject"
                        )
                        def job_names = readFile("env_inject")
                        //build dsl for the list of job_names
                        if (job_names.size() != 0){
                            jobDsl targets : job_names
                        }

                        //collect jenkins job names from the changed '*.groovy' and  '*.Jenkinsfile'
                        sh(
                            script : "technicals/shellscripts/collect_job_names_technicals.sh ${WORKSPACE}/adp-app-staging/"
                        )
                        job_names = readFile("env_inject").split(' ')
                        for (job_name in job_names) {
                            //init dry-runs-job by running itself if changed
                            if (job_name ==~ /.*dry-runs-job.*/) {
                                try {
                                    build job: "dry-runs-job", parameters: [booleanParam(name: 'DRY_RUN', value: true)], propagate: false, wait: true
                                }
                                catch (err) {
                                    echo "Caught: ${err}"
                                    currentBuild.result = 'FAILURE'
                                }
                            }
                        }
                        //init all other changed job with the running dry-runs-job
                        for (job_name in job_names) {
                            if (!(job_name ==~ /.*dry-runs-job.*/)) {
                                try {
                                    build job: "dry-runs-job", parameters: [booleanParam(name: 'DRY_RUN', value: false), stringParam(name: 'JOB_NAMES', value : "${job_name}")], wait: false
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
