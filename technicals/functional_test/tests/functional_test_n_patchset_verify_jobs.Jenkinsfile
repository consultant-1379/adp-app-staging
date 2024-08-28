@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def git = new GitScm(this, 'EEA/adp-app-staging')

pipeline {
    options {
        disableConcurrentBuilds()
        buildDiscarder(logRotator(daysToKeepStr: '14', artifactDaysToKeepStr: '7'))
    }

    agent {
        node {
            label 'productci'
        }
    }
    parameters {
        string(name: 'TEST_BRANCH_NAME', description: 'test branch name', defaultValue:"prod-ci-test")
        string(name: 'TEST_JENKINS_URL', description: 'test branch name', defaultValue:"https://seliius27102.seli.gic.ericsson.se:8443")
    }

    environment {
        EXCPECTED_RESULT = 'FAILURE'
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
                script {
                    git.checkout( "${params.TEST_BRANCH_NAME}", "adp-app-staging")
                }
            }
        }

        stage ('init'){
            steps {
                script {
                    env.TEST_JOB_URL = "${TEST_JENKINS_URL}/job/patchset-verify-jobs"
                    withCredentials([usernamePassword(credentialsId: 'test-jenkins-token', usernameVariable: 'TEST_USER', passwordVariable: 'TEST_USER_PASSWORD')]){
                        def result_next_build = sh(
                            script: "curl --silent ${TEST_JOB_URL}/api/json --user $TEST_USER:$TEST_USER_PASSWORD --insecure | jq -r '.nextBuildNumber'",
                            returnStdout : true
                        )
                        if ("${result_next_build}" != ''){
                            env.NEXT_BUILD_NUMBER =  "${result_next_build}".trim()
                        }else
                        {
                           error ('Build failed because next build number not found')
                        }
                    }
                }
            }
        }

        stage('push patchset to test branch'){
            steps{
                withCredentials([usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'TEST_USER', passwordVariable: 'TEST_USER_PASSWORD')]){
                    sh """
                    set -x
                    cd adp-app-staging
                    cat >> jobs/eea_app_baseline_manual_flow/eea_app_baseline_manual_flow_precodereview.groovy << EOF
}
EOF
                    git add jobs/eea_app_baseline_manual_flow/eea_app_baseline_manual_flow_precodereview.groovy
                    git config --local credential.helper "!f() { echo username=\\$TEST_USER; echo password=\\$TEST_USER_PASSWORD; }; f"
                    mkdir -p .git/hooks
                    curl -Lo `git rev-parse --git-dir`/hooks/commit-msg https://$TEST_USER@${GERRIT_HOST}/tools/hooks/commit-msg
                    chmod +x `git rev-parse --git-dir`/hooks/commit-msg
                    git commit -am "test the trigger"
                    git push origin HEAD:refs/for/${TEST_BRANCH_NAME}
                  """
                }
                script{
                    def result_revision = sh(
                                            script: "git log --format=\"%H\" -n 1",
                                            returnStdout : true
                                        )
                    if ("${result_revision}" != ''){
                        env.TEST_REVISION = "${result_revision}"
                        echo "TEST_REVISION: $env.TEST_REVISION"
                    }
                }
            }
        }
        stage('check job in test jenkins'){
            steps{
                timeout(time: 15, unit: 'MINUTES'){
                    script{
                        env.TEST_STATE = ''
                        while ( "${env.TEST_STATE}" != "${EXCPECTED_RESULT}") {
                            sleep(time:10,unit:"SECONDS")
                            withCredentials([usernamePassword(credentialsId: 'test-jenkins-token', usernameVariable: 'TEST_USER', passwordVariable: 'TEST_USER_PASSWORD')])
                            {
                                sh """
                                    curl '${TEST_JOB_URL}/${NEXT_BUILD_NUMBER}/api/json'  --user ${TEST_USER}:${TEST_USER_PASSWORD} --insecure | jq -r '.result' | tee env_jobResult
                                    cat  env_jobResult
                                """
                                env.TEST_STATE = readFile("env_jobResult").trim()
                                echo "env.TEST_STATE value: ${env.TEST_STATE}"
                                echo "EXCPECTED_RESULT: ${EXCPECTED_RESULT}"
                            }
                        }
                        if ("${env.TEST_STATE}" != "${EXCPECTED_RESULT}"){
                           error ( "${TEST_JOB_URL}/${NEXT_BUILD_NUMBER} result ${env.TEST_STATE} not equals excpected  ${EXCPECTED_RESULT}" )
                        }
                    }
                }
            }
        }
    }
}
