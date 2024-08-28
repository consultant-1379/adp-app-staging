@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def git = new GitScm(this, 'EEA/adp-app-staging')

pipeline {
    options {
        disableConcurrentBuilds()
        skipDefaultCheckout()
        buildDiscarder(logRotator(daysToKeepStr: '14', artifactDaysToKeepStr: '7'))
    }

    agent {
        node {
            label 'productci'
        }
    }
    parameters {
        choice(name: 'JENKINS_URL', choices: ['https://seliius27102.seli.gic.ericsson.se:8443', 'https://seliius27190.seli.gic.ericsson.se:8443'], description: '')
        choice(name: 'API_TOKEN', choices: ['test-jenkins-token','jenkins-api-token'], description: '')
    }

    environment {
        EXCPECTED_RESULT = 'SUCCESS'
        PIPELINE_ID = '942723de-1539-43e6-91dd-7ccd51adf90e'
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
                    git.checkout("${params.TEST_BRANCH_NAME}", "adp-app-staging")
                }
            }
        }

        stage ('init'){
            steps {
                script {
                    env.TEST_JOB_URL = "${JENKINS_URL}/job/functional-test-spinnaker-stage"
                    def id= "${params.API_TOKEN}"
                    withCredentials([usernamePassword(credentialsId: id, usernameVariable: 'TEST_USER', passwordVariable: 'TEST_USER_PASSWORD')]){
                        def result_next_build = sh(
                            script: "curl --silent ${TEST_JOB_URL}/api/json --user $TEST_USER:$TEST_USER_PASSWORD --insecure  | jq -r '.nextBuildNumber'",
                            returnStdout : true
                        )
                        if ("${result_next_build}" != ''){
                            env.NEXT_BUILD_NUMBER =  "${result_next_build}".trim()
                            sh "echo 'next ${env.NEXT_BUILD_NUMBER}'"
                        }else
                        {
                           error ('Build failed because next build number not found')
                        }
                    }
                }
                withCredentials([usernamePassword(credentialsId: 'eceaspin', usernameVariable: 'SPIN_USERNAME', passwordVariable: 'SPIN_PASSWORD')]) {
                    writeFile file: 'spin_config', text: "gate:\n  endpoint: https://spinnaker-api.rnd.gic.ericsson.se\nauth:\n  enabled: true\n  basic:\n    username: ${SPIN_USERNAME}\n    password: ${SPIN_PASSWORD}"
                }
            }
        }

        stage('run drop job') {
            steps{
                script {
                    if ("${JENKINS_URL}" == "https://seliius27102.seli.gic.ericsson.se:8443") {
                        step([$class: 'RemoteBuildConfiguration',
                            auth2 : [$class: 'CredentialsAuth' ,credentials:'test-jenkins-token' ],
                            remoteJenkinsName : 'test-jenkins',
                            remoteJenkinsUrl : 'https://seliius27102.seli.gic.ericsson.se:8443/',
                            job: 'functional-test-spinnaker-drop',
                            token : 'kakukk',
                            overrideTrustAllCertificates : true,
                            trustAllCertificates : true,
                            blockBuildUntilComplete : true
                            ]
                        )
                    }else{
                        build job: "functional-test-spinnaker-drop", parameters: [booleanParam(name: 'DRY_RUN', value: false)]
                    }
                }
            }
        }

        stage('poll spinnaker pipeline') {
            steps{
                timeout(time: 5, unit: 'MINUTES'){
                    script{
                        env.TEST_STATE = ''
                        while ( "${env.TEST_STATE}" != "RUNNING") {
                            sleep(time:10,unit:"SECONDS")
                            sh ( script: "spin --config spin_config pipeline execution list -l 1 -i 942723de-1539-43e6-91dd-7ccd51adf90e| jq -r '.[0] | .status' | tee env_pipeline_result",
                                returnStdout: true)
                            env.TEST_STATE = readFile("env_pipeline_result").trim()
                            echo "env.TEST_STATE value: ${env.TEST_STATE}"

                        }
                    }
                }
            }
        }

        stage('poll jenkins stage job'){
            steps{
                timeout(time: 5, unit: 'MINUTES'){
                    script{
                        env.TEST_STATE = ''
                        def id= "${params.API_TOKEN}"
                        while ( "${env.TEST_STATE}" != "${EXCPECTED_RESULT}") {
                            sleep(time:10,unit:"SECONDS")
                            withCredentials([usernamePassword(credentialsId: id, usernameVariable: 'TEST_USER', passwordVariable: 'TEST_USER_PASSWORD')])
                            {
                                sh """
                                    curl '${TEST_JOB_URL}/${NEXT_BUILD_NUMBER}/api/json'  --user ${TEST_USER}:${TEST_USER_PASSWORD} --insecure | jq -r '.result' | tee env_jobResult
                                    cat  env_jobResult
                                """
                                env.TEST_STATE = readFile("env_jobResult").trim()
                                echo "env.TEST_STATE value: ${env.TEST_STATE}"
                                echo "EXCPECTED_RESULT: ${EXCPECTED_RESULT}"
                                if ( "${env.TEST_STATE}" == "FAILURE"){
                                    sh "exit 1"
                                }
                            }
                        }
                        if ("${env.TEST_STATE}" != "${EXCPECTED_RESULT}"){
                           error ( "${TEST_JOB_URL}/${NEXT_BUILD_NUMBER} result ${env.TEST_STATE} not equals excpected  ${EXCPECTED_RESULT}" )
                        }
                    }
                }
            }
        }
        stage('poll spinnaker pipeline for finish') {
            steps{
                timeout(time: 2, unit: 'MINUTES'){
                    script{
                        env.TEST_STATE = ''
                        while ( "${env.TEST_STATE}" != "SUCCEEDED") {
                            sleep(time:10,unit:"SECONDS")
                            sh ( script: "spin --config spin_config pipeline execution list -l 1 -i 942723de-1539-43e6-91dd-7ccd51adf90e| jq -r '.[0] | .status' | tee env_pipeline_result",
                                returnStdout: true)
                            env.TEST_STATE = readFile("env_pipeline_result").trim()
                            echo "env.TEST_STATE value: ${env.TEST_STATE}"
                        }
                    }
                }
            }
        }
    }
}
