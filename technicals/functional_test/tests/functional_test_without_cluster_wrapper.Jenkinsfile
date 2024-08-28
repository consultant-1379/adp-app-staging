@Library('ci_shared_library_eea4') _

import groovy.transform.Field
import com.ericsson.eea4.ci.GlobalVars
import com.ericsson.eea4.ci.CommonUtils

@Field def vars = new GlobalVars()
@Field def commonUtils = new CommonUtils(this)

pipeline {
    options {
        ansiColor('xterm')
        skipDefaultCheckout()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(daysToKeepStr:'14', artifactDaysToKeepStr: '7'))
    }

    agent {
        node {
            label 'productci'
        }
    }

    parameters {
        booleanParam(name: 'DUMMY_RUN', description: 'If true, execute remote build job with DRY_RUN=true', defaultValue: false)
        string(name: 'TEST_BRANCH_NAME', description: 'Test branch name', defaultValue:"prod-ci-test")
        string(name: 'TEST_JENKINS_URL', description: 'Remote Jenkins URL', defaultValue:"https://seliius27102.seli.gic.ericsson.se:8443")
        string(name: 'JOB_TO_TEST_NAME', description: 'Test job name', defaultValue:"eea-application-staging-nx1")
    }

    environment {
        EXCPECTED_RESULT = 'SUCCESS'
        TEST_JENKINS_NAME = "test-jenkins"
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

        stage ('Init'){
            steps {
                script {
                    env.TEST_JOB_URL = "${params.TEST_JENKINS_URL}/job/${params.JOB_TO_TEST_NAME}"
                    withCredentials([usernamePassword(credentialsId: 'test-jenkins-token', usernameVariable: 'TEST_USER', passwordVariable: 'TEST_USER_PASSWORD')]){
                        def result_next_build = sh(
                            script: "curl --silent ${TEST_JOB_URL}/api/json --user $TEST_USER:$TEST_USER_PASSWORD --insecure  | jq -r '.nextBuildNumber'",
                            returnStdout : true
                        )
                        if ("${result_next_build}" != '') {
                            env.NEXT_BUILD_NUMBER =  "${result_next_build}".trim()
                        } else {
                           error ('Build failed because next build number not found')
                        }
                    }
                }
            }
        }

        stage('Test without cluster locking') {
            steps {
                script {
                    def lastSuccessfulBuildParameters = getJenkinsJobBuildParameters("${env.JOB_TO_TEST_NAME}")
                    def extraParameters = [
                        [
                          "_class": "hudson.model.StringParameterValue",
                          "name": "DRY_RUN",
                          "value": "${params.DUMMY_RUN}"
                        ],
                    ]
                    mergedBuildParameters = commonUtils.mergeListOfMapObjects(lastSuccessfulBuildParameters, extraParameters)
                    execRemoteBuild("${env.TEST_JENKINS_NAME}", "${params.TEST_JENKINS_URL}", "${env.JOB_TO_TEST_NAME}", mergedBuildParameters)
                }
            }
        }

        stage('Check job in test jenkins') {
            steps{
                timeout(time: 2, unit: 'MINUTES') {
                    script {
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

def createJobRemoteBuildParameters(def job, def parameters) {
    script {
        parametersAsString = ""
        try {
            parameters.each { parameter ->
                parametersAsString += "${parameter.name}=${parameter.value}\n"
            }
            echo "Parameter(s) for job: ${job} for test run:\n${parametersAsString}"
            if (!parametersAsString){
                echo "EMPTY PARAMETERS"
            }
            return parametersAsString
        } catch (err) {
            error "createJobRemoteBuildParameters FAILED\n - job: ${job}\n - ERROR: ${err}"
        }
    }
}

void execRemoteBuild(def remoteJenkinsName, def remoteJenkinsUrl, def job, def parameters) {
    script {
        buildParameters = createJobRemoteBuildParameters(job, parameters)
        echo "Exec remote build for job: ${job} ..."
        try {
            step([$class: 'RemoteBuildConfiguration',
                auth2 : [$class: 'CredentialsAuth', credentials:'test-jenkins-token' ],
                remoteJenkinsName : "${remoteJenkinsName}",
                remoteJenkinsUrl : "${remoteJenkinsUrl}",
                job: "${job}",
                parameters: buildParameters,
                token : 'kakukk',
                overrideTrustAllCertificates : true,
                trustAllCertificates : true,
                blockBuildUntilComplete : true
                ]
            )
        }
        catch (err) {
            error "execRemoteBuild FAILED\n - job: ${job}\n - ERROR: ${err}"
        }
    }
}
