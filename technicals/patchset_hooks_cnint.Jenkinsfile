@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import com.ericsson.eea4.ci.GlobalVars

@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def vars = new GlobalVars()

pipeline {
    agent {
        node {
            label 'productci'
        }
    }
    options {
      skipDefaultCheckout()
      buildDiscarder(logRotator(daysToKeepStr: "7"))
    }

    triggers {
        gerrit (
            serverName: 'GerritCentral',
            gerritProjects: [[
                    compareType: 'PLAIN',
                    pattern: 'EEA/cnint',
                    branches: [[ compareType: 'PLAIN', pattern: env.MAIN_BRANCH ]],
                    disableStrictForbiddenFileVerification: false,
                    topics: [[ compareType: 'REG_EXP', pattern: '^((?!^inca$).)*$' ]]
            ]],
            triggerOnEvents:  [
                [
                    $class              : 'PluginPatchsetCreatedEvent',
                    excludeDrafts       : true,
                    excludeTrivialRebase: false,
                    excludeNoCodeChange : false
                ],
                [
                    $class                      : 'PluginCommentAddedContainsEvent',
                    commentAddedCommentContains : '.*rebuild.*'
                ],
                [
                    $class                      : 'PluginDraftPublishedEvent'
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

        stage('Checkout - scripts') {
            steps{
                script{
                    gitadp.sparseCheckout("technicals/")
                }
            }
        }

        stage('Checkout - cnint') {
            steps{
                script{
                    gitcnint.checkoutRefSpec("${GERRIT_REFSPEC}","FETCH_HEAD", 'cnint')
                }
            }
        }

        stage('Prepare') {
            steps {
                dir('cnint'){
                    checkoutGitSubmodules()
                }
            }
        }

        stage('Rulesets DryRun') {
            steps {
                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                    dir('cnint') {
                        script {
                            rulesetsDryRun()
                        }
                    }
                }
            }
            post {
                always {
                    script {
                        archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                    }
                }
            }
        }

        stage('Rulesets Validations') {
            steps {
                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                    catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE'){
                        script {
                            build job: "ruleset-change-validate", parameters: [
                                booleanParam(name: 'dry_run', value: false),
                                stringParam(name: 'GERRIT_PROJECT', value : "${env.GERRIT_PROJECT}"),
                                stringParam(name: 'GERRIT_REFSPEC', value : "${env.GERRIT_REFSPEC}"),
                                stringParam(name: 'GERRIT_HOST', value : "${env.GERRIT_HOST}"),
                                stringParam(name: 'GERRIT_BRANCH', value : "${env.GERRIT_BRANCH}"),
                                stringParam(name: 'GERRIT_PORT', value : "${env.GERRIT_PORT}"),
                                stringParam(name: 'GERRIT_CHANGE_URL', value : "${env.GERRIT_CHANGE_URL}"),
                                stringParam(name: 'GERRIT_CHANGE_NUMBER', value : "${env.GERRIT_CHANGE_NUMBER}"),
                            ]
                        }
                    }
                }
            }
            post {
                always {
                    script {
                        archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                    }
                }
            }
        }

        stage('Verify values files') {
            steps {
                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                    dir('cnint') {
                        catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                            script {
                                sh '''sed -i "/eea4-dimensioning-tool-output-values.yaml/d" values-list.txt'''
                                sh 'bob/bob verify-values-files:verify-values-files'
                            }
                        }
                    }
                }
            }
            post {
                always {
                    script {
                        archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                    }
                }
                failure {
                    script {
                        echo "Caught: ${err}"
                        def recipient = "${params.GERRIT_EVENT_ACCOUNT_EMAIL}"
                        mail subject: "${env.JOB_NAME} (${env.BUILD_NUMBER}) ${env.STAGE_NAME} FAILED",
                        body: "${env.BUILD_URL} values files verification failed",
                        to: "${recipient}",
                        replyTo: "${recipient}",
                        from: 'eea-seliius27190@ericsson.com'
                    }
                }
            }
        }

        stage('Clean') {
            steps {
                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                    dir('cnint'){
                        sh 'bob/bob clean'
                    }
                }
            }
            post {
                always {
                    script {
                        archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                    }
                }
            }
        }

        stage('Bob - prepare') {
            steps {
                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                    dir('cnint') {
                        withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                    string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                    string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                    usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]){
                            sh 'bob/bob prepare-common'
                        }
                    }
                }
            }
            post {
                always {
                    script {
                        archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                    }
                }
            }
        }

        stage('Bob lint') {
            steps {
                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                    script {
                        dir('cnint') {
                            withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                        string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                        string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                        usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]){
                                sh 'bob/bob lint-integration-helm:dependency-update lint-integration-helm:helm-lint -r bob-rulesets/input-sanity-check-rules.yaml'
                            }
                        }
                    }
                }
            }
            post {
                always {
                    script {
                        archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                    }
                }
            }
        }

        stage('CMA config schema validation') {
            steps {
                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                    script {
                        def cmaconfig = "csar-scripts/cma/"
                        def schema = "technicals/json_templates/cma_all_in_one_external_config_schema.json"
                        def changedfiles = getGerritQueryPatchsetChangedFiles(env.GERRIT_CHANGE_NUMBER)
                        def validationErrors = ''
                        changedfiles
                            .findAll{ it ==~ vars.cma_config_schema_regex }
                            .each{
                                try {
                                    jsonSchemaValidate(schema, "cnint/" + it)
                                } catch (error) {
                                    validationErrors += error.message + "\n"
                                }
                            }
                        if (validationErrors) {
                            env.GERRIT_MSG = "CMA config: " + validationErrors
                            sendMessageToGerrit(env.GERRIT_REFSPEC, env.GERRIT_MSG)
                            error env.GERRIT_MSG
                        }
                    }
                }
            }
            post {
                always {
                    script {
                        archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                    }
                }
            }
        }

        stage('Bob helm design rule check') {
            steps {
                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                    catchError(buildResult: 'FAILURE', stageResult: 'FAILURE'){
                        script {
                            dir('cnint'){
                                withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                    string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                    string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                    usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]){
                                        sh 'bob/bob lint-integration-helm:helm-dr-check -r bob-rulesets/input-sanity-check-rules.yaml'
                                }
                            }
                        }
                    }
                }
            }
            post {
                always {
                    script {
                        archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                    }
                }
            }
        }

        stage('Jenkins patchset hooks') {
            steps {
                script {
                    try{
                        def result = sh(
                                script: "cd ${WORKSPACE} && ./technicals/shellscripts/run_verify_hooks.sh \$GERRIT_PATCHSET_REVISION \$BUILD_URL ${WORKSPACE} 'technicals/hooks/pre_*'",
                                returnStatus : true
                        )
                        sh "echo ${result}"
                        if (result != 0){
                            currentBuild.result = 'FAILURE'
                        }
                    }catch (err) {
                        echo "Caught: ${err}"
                        currentBuild.result = 'FAILURE'
                    }

                }
            }
        }
    }
    post {
        always {
            dir('cnint'){
                archiveArtifacts artifacts: '.bob/check-helm/design-rule-check-report.*', allowEmptyArchive: true
                publishHTML (target: [
                    allowMissing: true,
                    alwaysLinkToLastBuild: false,
                    keepAll: true,
                    reportDir: '.bob/check-helm/',
                    reportFiles: 'design-rule-check-report.html',
                    reportName: "Helm Design Rule Check"
                ])
            }
        }
        cleanup {
            cleanWs()
        }
    }
}
