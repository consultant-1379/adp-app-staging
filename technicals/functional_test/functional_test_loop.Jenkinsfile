@Library('ci_shared_library_eea4') _

import groovy.json.JsonOutput
import groovy.transform.Field

import com.ericsson.eea4.ci.GitScm

@Field def git = new GitScm(this, 'EEA/adp-app-staging')
@Field def git_shared_lib = new GitScm(this, 'EEA/ci_shared_libraries')

def maximumNumberOfFilesToValidate = 1
def repoPathSharedLib = "ci_shared_libraries"
def wrapperJobWithCluster  = "functional-test-with-cluster-wrapper"
def wrapperJobWithoutCluster = "functional-test-without-cluster-wrapper"
def deployTypeInstall = "install"
def deployTypeUpgrade = "upgrade"

/**
* List of Maps containing changed files to be validated
* - fileName:     contains the file name from the repo to validate
* - validatorJob: this job will be executed on test Jenkins by the wrapper job
* - wrapperJob:   this is the name of the wrapper job on master Jenkins
*                 if not defined 'wrapperJobWithCluster' will be used
*                 possible values:
*                  - wrapperJobWithoutCluster
*                  - wrapperJobWithCluster
* - deployType":  in case of install jobs both HELM and CMA configurations need to be validated
*                   - this means that 2 install test validation will be executed:
*                     - one with HELM_AND_CMA_VALIDATION_MODE=HELM
*                     - one with HELM_AND_CMA_VALIDATION_MODE=HELM_AND_CMA
*                 possible values:
*                  - deployTypeInstall
*                  - deployTypeUpgrade
*/

def validationParams = [
    [
        "fileName": "shared_lib_testing", // special case for shared library changes
        "validatorJob": "eea-adp-staging-adp-nx1-loop",
    ],
    [
        "fileName": "eea_application_staging_product_baseline_install.Jenkinsfile",
        "validatorJob": "eea-application-staging-product-baseline-install",
    ],
    [
        "fileName": "eea_adp_staging_adp_nx1_loop.Jenkinsfile",
        "validatorJob": "eea-adp-staging-adp-nx1-loop",
        "deployType": deployTypeInstall,
    ],
    [
        "fileName": "eea_application_staging_nx1.Jenkinsfile",
        "validatorJob": "eea-application-staging-nx1",
        "deployType": deployTypeInstall,
    ],
    [
        "fileName": "eea_application_staging_batch.Jenkinsfile",
        "validatorJob": "eea-application-staging-batch",
        "deployType": deployTypeInstall,
    ],
    [
        "fileName": "eea_product_ci_meta_baseline_loop_test.Jenkinsfile",
        "validatorJob": "eea-product-ci-meta-baseline-loop-test",
        "deployType": deployTypeInstall,
    ],
    [
        "fileName": "eea_common_product_upgrade.Jenkinsfile",
        "validatorJob": "eea-application-staging-product-upgrade",
        "deployType": deployTypeUpgrade,
    ],
    [
        "fileName": "eea_application_staging_product_upgrade.Jenkinsfile",
        "validatorJob": "eea-application-staging-product-upgrade",
        "deployType": deployTypeUpgrade,
    ],
    [
        "fileName": "eea_product_ci_meta_baseline_loop_upgrade.Jenkinsfile",
        "validatorJob": "eea-product-ci-meta-baseline-loop-upgrade",
        "deployType": deployTypeUpgrade,
    ],
    [
        "fileName": "eea_common_product_test_after_deployment.Jenkinsfile",
        "validatorJob": "eea-product-ci-meta-baseline-loop-upgrade",
        "deployType": deployTypeUpgrade,
    ],
    [
        "fileName": "eea_adp_staging_adp_nx1_loop_upgrade.Jenkinsfile",
        "validatorJob": "", // NOT TESTED YET
        "deployType": deployTypeUpgrade,
    ],
    [
        "fileName": "eea_application_staging_nx1_upgrade.Jenkinsfile",
        "validatorJob": "", // NOT TESTED YET
        "deployType": deployTypeUpgrade,
    ],
    [
        "fileName": "eea_product_release_loop_bfu_gate_upgrade.Jenkinsfile",
        "validatorJob": "", // NOT TESTED YET
        "deployType": deployTypeUpgrade,
    ],
    [
        "fileName": "cluster_cleanup.Jenkinsfile",
        "validatorJob": "cluster-cleanup",
    ],
    [
        "fileName": "cluster_logcollector.Jenkinsfile",
        "validatorJob": "cluster-logcollector",
    ],
    [
        "fileName": "csar_build.Jenkinsfile",
        "validatorJob": "csar-build",
        "wrapperJob": wrapperJobWithoutCluster,
    ],
    [
        "fileName": "eea_jenkins_docker_xml_generator.Jenkinsfile",
        "validatorJob": "eea-jenkins-docker-xml-generator",
        "wrapperJob": wrapperJobWithoutCluster,
    ],
    [
        "fileName": "spotfire_asset_install.Jenkinsfile",
        "validatorJob": "eea-application-staging-nx1",
    ],
    [
        "fileName": "ansible/spotfire_asset_install",
        "validatorJob": "eea-application-staging-nx1",
    ],
]

List validationList = []
boolean SKIP_TESTING = false
boolean SHARED_LIB_TESTING = false

pipeline {
    agent {
        node {
            label 'productci'
        }
    }

    options {
        ansiColor('xterm')
        skipDefaultCheckout()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(daysToKeepStr:'14', artifactDaysToKeepStr: '7'))
    }

    parameters {
        string(name: 'GERRIT_REFSPEC', description: 'emulate trigger', defaultValue:"")
        string(name: 'SPINNAKER_TRIGGER_URL', description: 'Spinnaker pipeline triggering url', defaultValue: '')
        string(name: 'SPINNAKER_ID', description: "The spinnaker execution's id", defaultValue: 'test')
        string(name: 'CHART_NAME', description: 'Chart name e.g.: eric-ms-b', defaultValue: '')
        string(name: 'CHART_REPO', description: 'Chart repo e.g.: https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm', defaultValue: '')
        string(name: 'CHART_VERSION', description: 'Chart version e.g.: 1.0.0-1', defaultValue: '')
    }

    environment {
        TEST_BRANCH_NAME = "prod-ci-test"
        TEST_JENKINS_NAME = "test-jenkins"
        TEST_JENKINS_URL = "https://seliius27102.seli.gic.ericsson.se:8443"
        LATEST_CI_LIB_GIT_TAG = 'LATEST_CI_LIB'
        LATEST_CI_LIB_TEST_GIT_TAG = 'LATEST_CI_LIB_TEST'
        LATEST_CI_LIB_GIT_TAG_MSG = 'Latest CI Shared Libraries version'
        LATEST_CI_LIB_TEST_GIT_TAG_MSG = 'Latest CI Shared Libraries TEST version'
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

        stage('Check for shared library changes') {
            steps {
                script {
                    if ( params.CHART_NAME == 'eric-eea-ci-shared-lib') {
                        if ( !params.CHART_VERSION ) {
                            error: "In case of testing CI Shared Libraries, params.CHART_VERSION must not be empty!"
                        }
                        SHARED_LIB_TESTING = true
                    }
                }
            }
        }

        stage('Gerrit message') {
            when {
                expression { params.GERRIT_REFSPEC }
            }
            steps {
                script {
                    env.GERRIT_MSG = "Build Started ${BUILD_URL}"
                    sendMessageToGerrit(params.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
             }
        }

        stage('Set Spinnaker link') {
            steps {
                script {
                    if ( params.SPINNAKER_ID ) {
                        currentBuild.description = '<a href="https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/details/' + params.SPINNAKER_ID + '">Spinnaker URL: ' + params.SPINNAKER_ID + '</a>'
                    }
                }
            }
        }

        stage('Validate patchset changes') {
            when {
                expression { params.GERRIT_REFSPEC && params.GERRIT_REFSPEC != 'null'}
            }
            steps {
                script {
                    def result = git.verifyNoNewPathSet(params.GERRIT_REFSPEC)
                    if (!result) {
                        error ('New patchset created since stage Prepare')
                    }
                }
             }
        }

        stage('Check which files changed - .md') {
            when {
                expression { params.GERRIT_REFSPEC }
            }
            steps {
                script {
                    SKIP_TESTING = checkIfCommitContainsOnlySkippableFiles(params.GERRIT_REFSPEC, [".md"])
                    echo("SKIP_TESTING: " + SKIP_TESTING)
                }
            }
        }

        stage('Collect changed files to validate') {
            steps {
                script {
                    changedFiles = []

                    // Run only when GERRIT_REFSPEC is defined
                    if (params.GERRIT_REFSPEC) {
                        changedFiles += getGerritQueryPatchsetChangedFiles(params.GERRIT_REFSPEC)
                    }

                    // Run only when testing shared lib
                    if (SHARED_LIB_TESTING) {
                        changedFiles += ['shared_lib_testing']
                    }

                    changedFiles.each { file ->
                        obj = validationParams.find { file.contains(it.fileName) }
                        if (obj && obj.get('validatorJob')) {
                            // check if validationList already contains the validatorJob,
                            // because if several file changes need to be validated with the same job, it should be executed only once
                            def existsValidatorJob = validationList.flatten().any { it.validatorJob == obj.get('validatorJob') }
                            if (!existsValidatorJob) {
                                validationList.add([
                                    "fileName": obj.get('fileName'),
                                    "wrapperJob": obj.get('wrapperJob', wrapperJobWithCluster),
                                    "validatorJob": obj.get('validatorJob'),
                                    "deployType": obj.get('deployType')])
                            }
                        }
                    }
                    validationListPretty = JsonOutput.prettyPrint(JsonOutput.toJson([validationList]))
                    echo "validationList:\n${validationListPretty}"

                    if (validationList.size() > maximumNumberOfFilesToValidate) {
                        error "Too many files are changed in the patchset, which must be validated in the functional test loop.\nPlease split the commit.\n - Maximum number of files to validate:${maximumNumberOfFilesToValidate}\n - GERRIT_REFSPEC: ${params.GERRIT_REFSPEC}\n - validationList: ${validationListPretty}"
                    }
                }
            }
        }

        stage('Run when not just .md file in the change') {
            when {
                expression { !SKIP_TESTING }
            }
            stages {
                stage('Checkout') {
                    steps{
                        script{
                            if ( params.GERRIT_REFSPEC ) {
                                git.checkoutRefSpec("${GERRIT_REFSPEC}","FETCH_HEAD", 'adp-app-staging')
                            } else {
                                git.checkout('master', 'adp-app-staging')
                            }
                            git_shared_lib.checkout('master', repoPathSharedLib)
                        }
                    }
                }

                stage('Set LATEST_CI_LIB_TEST tag') {
                    steps {
                        catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                            script {
                                dir(repoPathSharedLib) {
                                    // in case of testing shared lib, need to move LATEST_CI_LIB_TEST tag
                                    if ( SHARED_LIB_TESTING ) {

                                        // get the commit hash of the tag (CHART_VERSION) being tested
                                        def remoteTag = git_shared_lib.checkRemoteGitTagExists(params.CHART_VERSION)
                                        if ( remoteTag ) {
                                            env.LATEST_CI_LIB_TEST_COMMIT_ID = remoteTag.split()[0]
                                        } else {
                                            error: "No commit exists with tag ${params.CHART_VERSION}!"
                                        }
                                        echo "Commit hash for tag ${CHART_VERSION}: ${env.LATEST_CI_LIB_TEST_COMMIT_ID}"

                                        // set LATEST_CI_LIB_TEST_GIT_TAG tag to the version being tested
                                        git_shared_lib.createOrMoveRemoteGitTag(env.LATEST_CI_LIB_TEST_GIT_TAG, env.LATEST_CI_LIB_GIT_TAG_MSG, env.LATEST_CI_LIB_TEST_COMMIT_ID)
                                        latestTag = git_shared_lib.checkRemoteGitTagExists(env.LATEST_CI_LIB_TEST_GIT_TAG)
                                        echo "LATEST_CI_LIB_TEST commit: ${latestTag}"

                                    // in case of testing adp app staging - "LATEST_CI_LIB_TEST" git tag should point to the same change as "LATEST_CI_LIB"
                                    } else {

                                        // "LATEST_CI_LIB_TEST" git tag should point to the change same as "LATEST_CI_LIB"
                                        def remoteTag = git_shared_lib.checkRemoteGitTagExists(env.LATEST_CI_LIB_GIT_TAG)
                                        if ( remoteTag ) {
                                            env.LATEST_CI_LIB_COMMIT_ID = remoteTag.split()[0]
                                        } else {
                                            error: "No commit exist with tag ${env.LATEST_CI_LIB_GIT_TAG}"
                                        }
                                        git_shared_lib.createOrMoveRemoteGitTag(env.LATEST_CI_LIB_TEST_GIT_TAG, env.LATEST_CI_LIB_TEST_GIT_TAG_MSG, env.LATEST_CI_LIB_COMMIT_ID)
                                    }
                                    echo "Remote git tags: " + git_shared_lib.listRemoteGitTags().trim()
                                }
                            }
                        }
                    }
                }

                stage('Test Jenkins setup') {
                    steps {
                        echo "TEST_BRANCH_NAME is '${env.TEST_BRANCH_NAME}'"
                        echo "TEST_JENKINS_NAME is '${env.TEST_JENKINS_NAME}'"
                        echo "TEST_JENKINS_URL is '${env.TEST_JENKINS_URL}'"

                        echo "check test jenkins - all-jobs-seed api - connection ok"
                        withCredentials([usernamePassword(credentialsId: '  test-jenkins-token', usernameVariable: 'TEST_USER', passwordVariable: 'TEST_USER_PASSWORD')])
                        {
                            sh '''
                                curl -XGET ${TEST_JENKINS_URL}/job/all-jobs-seed/api/json --user $TEST_USER:$TEST_USER_PASSWORD --insecure
                               '''
                        }
                    }
                }

                stage('Running test - with resource locking') {
                    options {
                        lock resource: null, label: 'test-jenkins', quantity: 1, variable: 'TEST_JENKINS'
                            withCredentials([usernamePassword(credentialsId: 'jenkins-api-token', usernameVariable: 'TEST_JENKINS_USER', passwordVariable: 'TEST_JENKINS_PASSWORD')])
                    }
                    stages {
                        stage('Recreating test branch') {
                            steps {
                                dir ('adp-app-staging'){
                                    script {
                                        git.createOrMoveRemoteGitBranch("${TEST_BRANCH_NAME}")
                                    }
                                }
                            }
                        }

                        stage('Setup jobs on test environment') {
                            steps {
                                step([$class: 'RemoteBuildConfiguration',
                                    auth2 : [$class: 'CredentialsAuth' ,credentials:'test-jenkins-token' ],
                                    remoteJenkinsName : "${env.TEST_JENKINS_NAME}",
                                    remoteJenkinsUrl : "${env.TEST_JENKINS_URL}",
                                    job: 'all-jobs-seed',
                                    token : 'kakukk',
                                    overrideTrustAllCertificates : true,
                                    trustAllCertificates : true,
                                    blockBuildUntilComplete : true
                                    ]
                                )
                            }
                        }

                        stage('Running tests from wrapper') {
                            steps {
                                catchError(stageResult: 'FAILURE', buildResult: 'FAILURE') {
                                    script {
                                        try {
                                            validationList.each { validationItem ->
                                                wrapperJob = validationItem.get('wrapperJob')
                                                validatorJob = validationItem.get('validatorJob')
                                                deployType = validationItem.get('deployType')
                                                if (deployType == deployTypeInstall) {
                                                    // in this case of install jobs both HELM and CMA configurations need to be validated
                                                    executeJob(wrapperJob, validatorJob, 'HELM') // helmAndCMAValidationMode='HELM'
                                                    executeJob(wrapperJob, validatorJob, 'HELM_AND_CMA')  // helmAndCMAValidationMode='HELM_AND_CMA'
                                                } else {
                                                    executeJob(wrapperJob, validatorJob)
                                                }
                                            }
                                        } finally {
                                            script {
                                                dir ('adp-app-staging') {
                                                    git.deleteRemoteGitBranch("${TEST_BRANCH_NAME}")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                    }
                }
            }
        }
    }
    post {
        failure {
            script {
                def recipient = "b973ce22.ericsson.onmicrosoft.com@emea.teams.ms"
                mail subject: "${env.JOB_NAME} (${env.BUILD_NUMBER}) failed",
                body: "It appears that ${env.BUILD_URL} is failing, somebody should do something about that",
                to: "${recipient}",
                replyTo: "${recipient}",
                from: 'eea-seliius27190@ericsson.com'

                if (params.GERRIT_REFSPEC != '') {
                    env.GERRIT_MSG = "Build Failed ${BUILD_URL}: FAILURE"
                    sendMessageToGerrit(params.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }
        success {
            script {
                if (params.GERRIT_REFSPEC != '') {
                    env.GERRIT_MSG = "Build Successful ${BUILD_URL}: SUCCESS"
                    sendMessageToGerrit(params.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }
        cleanup {
           cleanWs()
        }
    }
}

def executeJob(def wrapperJob, def validatorJob, def helmAndCMAValidationMode='') {
    echo "Execute functional test for wrapperJob: ${wrapperJob}, validatorJob: ${validatorJob}, helmAndCMAValidationMode: ${helmAndCMAValidationMode} ..."
    try {
        build job: wrapperJob,
            parameters: [
                stringParam(name: 'TEST_BRANCH_NAME', value: "${env.TEST_BRANCH_NAME}"),
                stringParam(name: 'TEST_JENKINS_URL', value: "${env.TEST_JENKINS_URL}"),
                stringParam(name: 'JOB_TO_TEST_NAME', value: "${validatorJob}"),
                stringParam(name: 'HELM_AND_CMA_VALIDATION_MODE', value: "${helmAndCMAValidationMode}")
            ],
            wait : true
    } catch (err) {
        error "Execute functional test for wrapperJob: ${wrapperJob}, validatorJob: ${validatorJob} FAILED!\nCaught: ${err}"
    }
}
