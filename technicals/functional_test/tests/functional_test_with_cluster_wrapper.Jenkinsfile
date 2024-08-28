@Library('ci_shared_library_eea4') _

import groovy.transform.Field
import com.ericsson.eea4.ci.GlobalVars
import com.ericsson.eea4.ci.CommonUtils

@Field def vars = new GlobalVars()
@Field def commonUtils = new CommonUtils(this)

@Field def CMA_MODE_IS_HELM = "HELM"
@Field def CMA_MODE_IS_HELM_AND_CMA = "HELM_AND_CMA"

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
        string(name: 'HELM_AND_CMA_VALIDATION_MODE', description: "Use HELM values or HELM values and CMA configurations.", defaultValue: 'HELM_AND_CMA')
    }

    environment {
        EXCPECTED_RESULT = 'SUCCESS'
        TEST_JENKINS_NAME = "test-jenkins"
        TEST_JENKINS_JOB_NAME_WITH_CLUSTER_RUNNER = "functional-test-with-cluster-runner-on-test-env"
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

        stage('Wait for cluster') {
            steps {
                sendLockEventToDashboard(transition: "wait-for-cluster")
                waitForLockableResource("${vars.resourceLabelCommon}", "eea-product-ci-code-loop", "${env.JOB_NAME}")
                sendLockEventToDashboard(transition: "wait-for-lock")
            }
        }

        stage('Resource locking - Start wrapper job on test jenkins (logcollector)') {
            when {
                beforeOptions true
                expression { "${params.JOB_TO_TEST_NAME}" == "cluster-logcollector" }
            }
            options {
                lock resource: null, label: "${vars.resourceLabelCommon}", quantity: 1, variable: 'system'
            }
            steps {
                script {
                    sendLockEventToDashboard(transition: "lock", cluster: env.system)
                    env.LASTLABEL = vars.resourceLabelCommon

                    // start nx1 job to have info on clusters to logcollect
                    try {
                        env.STAGING_NX1_JOB_NAME = "eea-application-staging-nx1"
                        def lastSuccessfulBuildParameters = getJenkinsJobBuildParameters("${env.STAGING_NX1_JOB_NAME}")
                        def extraParameters = [
                            [
                              "_class": "hudson.model.StringParameterValue",
                              "name": "DRY_RUN",
                              "value": "${params.DUMMY_RUN}"
                            ],
                            [
                              "_class": "hudson.model.StringParameterValue",
                              "name": "TEST_CLUSTER",
                              "value": "${env.system}"
                            ],
                            [
                              "_class": "hudson.model.StringParameterValue",
                              "name": "TEST_JOB_NAME",
                              "value": "${env.STAGING_NX1_JOB_NAME}"
                            ],
                        ]
                        mergedBuildParameters = commonUtils.mergeListOfMapObjects(lastSuccessfulBuildParameters, extraParameters)
                        execRemoteBuild("${env.TEST_JENKINS_NAME}", "${params.TEST_JENKINS_URL}", "${env.TEST_JENKINS_JOB_NAME_WITH_CLUSTER_RUNNER}", mergedBuildParameters)
                    }
                    catch (err) {
                        echo "Caught ${STAGING_NX1_JOB_NAME} ERROR: ${err}" // we can ignore any issue at nx1 job here
                    }

                    // start logcollect job
                    def extraParameters = [
                        [
                          "_class": "hudson.model.StringParameterValue",
                          "name": "DRY_RUN",
                          "value": "${params.DUMMY_RUN}"
                        ],
                        [
                          "_class": "hudson.model.StringParameterValue",
                          "name": "TEST_CLUSTER",
                          "value": "${env.system}"
                        ],
                        [
                          "_class": "hudson.model.StringParameterValue",
                          "name": "TEST_JOB_NAME",
                          "value": "${env.JOB_TO_TEST_NAME}"
                        ],
                    ]
                    execRemoteBuild("${env.TEST_JENKINS_NAME}", "${params.TEST_JENKINS_URL}", "${env.TEST_JENKINS_JOB_NAME_WITH_CLUSTER_RUNNER}", extraParameters)
                }
            }
            post {
                always {
                    script {
                        executeCleanUp()
                        sendLockEventToDashboard(transition: "release", cluster: env.system)
                    }
                }
            }
        }

        stage('Resource locking - Start wrapper job on test jenkins (spotfire)') {
            when {
                beforeOptions true
                expression { "${params.JOB_TO_TEST_NAME}" ==~ /(eea-application-staging-batch|eea-product-ci-meta-baseline-loop-test|eea-adp-staging-adp-nx1-loop|eea-application-staging-nx1)/ }
            }
            options {
                lock resource: null, label: "${vars.resourceLabelCommon}", quantity: 1, variable: 'system'
            }
            stages {
                stage('Start wrapper job on test jenkins (spotfire)'){
                    steps {
                        script {
                            sendLockEventToDashboard(transition: "lock", cluster: env.system)
                            env.LASTLABEL = vars.resourceLabelCommon

                            def lastSuccessfulBuildParameters = getJenkinsJobBuildParameters("${env.JOB_TO_TEST_NAME}")

                            def extraParameters = [
                                [
                                  "_class": "hudson.model.StringParameterValue",
                                  "name": "DRY_RUN",
                                  "value": "${params.DUMMY_RUN}"
                                ],
                                [
                                  "_class": "hudson.model.StringParameterValue",
                                  "name": "TEST_CLUSTER",
                                  "value": "${env.system}"
                                ],
                                [
                                  "_class": "hudson.model.StringParameterValue",
                                  "name": "TEST_JOB_NAME",
                                  "value": "${env.JOB_TO_TEST_NAME}"
                                ],
                            ]

                            // override HELM_AND_CMA_VALIDATION_MODE param value from the input if non empty
                            if (env.HELM_AND_CMA_VALIDATION_MODE != "") {
                                extraParameters.add([
                                      "_class": "hudson.model.StringParameterValue",
                                      "name": "HELM_AND_CMA_VALIDATION_MODE",
                                      "value": "${env.HELM_AND_CMA_VALIDATION_MODE}"
                                    ])
                            }

                            mergedBuildParameters = commonUtils.mergeListOfMapObjects(lastSuccessfulBuildParameters, extraParameters)
                            execRemoteBuild("${env.TEST_JENKINS_NAME}", "${params.TEST_JENKINS_URL}", "${env.TEST_JENKINS_JOB_NAME_WITH_CLUSTER_RUNNER}", mergedBuildParameters)
                        }
                    }
                }
            }
            post {
                always {
                    script {
                        executeCleanUp()
                        sendLockEventToDashboard(transition: "release", cluster: env.system)
                    }
                }
            }
        }

        stage('Resource locking - Start wrapper job on test jenkins') {
            when {
                beforeOptions true
                expression { "${params.JOB_TO_TEST_NAME}" != "eea-application-staging-batch" && "${params.JOB_TO_TEST_NAME}" != "cluster-logcollector" && "${params.JOB_TO_TEST_NAME}" != "eea-product-ci-meta-baseline-loop-test" && "${params.JOB_TO_TEST_NAME}" != "eea-adp-staging-adp-nx1-loop" && "${params.JOB_TO_TEST_NAME}" != "eea-application-staging-nx1" } //these are using spotfire VM
            }
            options {
                lock resource: null, label: "${vars.resourceLabelCommon}", quantity: 1, variable: 'system'
            }
            steps {
                script {
                    sendLockEventToDashboard(transition: "lock", cluster: env.system)
                    env.LASTLABEL = vars.resourceLabelCommon

                    def lastSuccessfulBuildParameters = getJenkinsJobBuildParameters("${env.JOB_TO_TEST_NAME}")
                    def extraParameters = [
                        [
                          "_class": "hudson.model.StringParameterValue",
                          "name": "DRY_RUN",
                          "value": "${params.DUMMY_RUN}"
                        ],
                        [
                          "_class": "hudson.model.StringParameterValue",
                          "name": "TEST_CLUSTER",
                          "value": "${env.system}"
                        ],
                        [
                          "_class": "hudson.model.StringParameterValue",
                          "name": "TEST_JOB_NAME",
                          "value": "${env.JOB_TO_TEST_NAME}"
                        ],
                    ]
                    mergedBuildParameters = commonUtils.mergeListOfMapObjects(lastSuccessfulBuildParameters, extraParameters)

                    //CMA WA
                    def matching_helm_and_cma_param = mergedBuildParameters.find { it['name'] == 'HELM_AND_CMA_VALIDATION_MODE' }
                    if ( !matching_helm_and_cma_param ) {
                        def helm_and_cma_extra_param = [
                            [
                              "_class": "hudson.model.StringParameterValue",
                              "name": "HELM_AND_CMA_VALIDATION_MODE",
                              "value": "HELM_AND_CMA"
                            ],
                        ]
                        mergedBuildParameters = commonUtils.mergeListOfMapObjects(mergedBuildParameters, helm_and_cma_extra_param)
                    }

                    execRemoteBuild("${env.TEST_JENKINS_NAME}", "${params.TEST_JENKINS_URL}", "${env.TEST_JENKINS_JOB_NAME_WITH_CLUSTER_RUNNER}", mergedBuildParameters)
                }
            }
            post {
                always {
                    script {
                        executeCleanUp()
                        sendLockEventToDashboard(transition: "release", cluster: env.system)
                    }
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

void executeCleanUp() {
    script {
        def labelmanualchanged = checkLockableResourceLabelManualChange(env.system)
        if (! labelmanualchanged) {
            try {
                echo "Set label for the lockable resource ... \n - cluster: ${env.system} \n - label: cleanup-job"
                build job: "lockable-resource-label-change", parameters: [
                    booleanParam(name: 'DRY_RUN', value: params.DUMMY_RUN),
                    stringParam(name: 'DESIRED_CLUSTER_LABEL', value : "cleanup-job"),
                    stringParam(name: 'CLUSTER_NAME', value : "${env.system}")], wait: true
                env.LASTLABEL = "cleanup-job"
            }
            catch (err) {
                echo "Caught setLockableResourceLabels ERROR: ${err}"
            }
        }

        try {
            echo "Clear note for the lockable resource ... \n - cluster: ${env.system}"
            setLockableResourceNote("${env.system}", "")
        }
        catch (err) {
            echo "Caught setLockableResourceNote ERROR: ${err}"
        }

        if (! labelmanualchanged) {
            try {
                echo "Execute cluster-cleanup job ... \n - cluster: ${env.system}"
                build job: "cluster-cleanup", parameters: [
                    booleanParam(name: 'DRY_RUN', value: params.DUMMY_RUN),
                    stringParam(name: "CLUSTER_NAME", value: env.system),
                    stringParam(name: "LAST_LABEL_SET", value: env.LASTLABEL)
                    ], wait: true
            }
            catch (err) {
                echo "Caught cluster-cleanup job ERROR: ${err}"
                error "CLUSTER CLEANUP FAILED"
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
