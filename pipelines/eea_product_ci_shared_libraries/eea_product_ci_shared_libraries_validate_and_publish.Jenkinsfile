@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitlib = new GitScm(this, 'EEA/ci_shared_libraries')

pipeline {
    agent {
        node {
            label 'productci'
        }
    }
    options {
        skipDefaultCheckout()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(daysToKeepStr: "7"))
    }
    parameters {
        string(name: 'GERRIT_REFSPEC', description: 'Gerrit Refspec of the ci shared lib git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'GIT_REPO_URL',  description: 'The URL of the gerrit repo for EEA/ci_shared_libraries', defaultValue: 'https://${GERRIT_HOST}/EEA/ci_shared_libraries.git')
        booleanParam(name: 'SKIP_PUBLISH', description: 'Executes only the validation parts and skip the publish parts (submit, merge, tagging, etc.)', defaultValue: false)
    }
    environment {
        TEST_JENKINS_URL = "https://seliius27102.seli.gic.ericsson.se:8443/"
        TEST_BRANCH_NAME = "prod-ci-test"
        EXCPECTED_RESULT = 'SUCCESS'
    }
    triggers {
        gerrit (
            serverName: 'GerritCentral',
            gerritProjects: [[
                compareType: 'PLAIN',
                pattern: 'EEA/ci_shared_libraries',
                branches: [[ compareType: 'PLAIN', pattern: env.MAIN_BRANCH ]],
                disableStrictForbiddenFileVerification: false,
                topics: [[ compareType: 'REG_EXP', pattern: '^((?!^inca$).)*$' ]]
            ]],
            triggerOnEvents:  [
                [
                    $class              : 'PluginCommentAddedEvent',
                    verdictCategory       : 'Code-Review',
                    commentAddedTriggerApprovalValue: '+1'
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

        stage('Gerrit message') {
            when {
                expression { env.GERRIT_REFSPEC }
            }
            steps {
                script {
                    env.GERRIT_MSG = "Build Started ${BUILD_URL}"
                    sendMessageToGerrit(env.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
             }
         }

        stage('Checkout technicals'){
            steps {
                script {
                    gitadp.sparseCheckout("technicals/")
                }
            }
        }

        stage('Rebase') {
            when {
                expression { env.GERRIT_REFSPEC }
            }
            steps {
                sh "technicals/shellscripts/gerrit_rebase.sh --refspec ${env.GERRIT_REFSPEC}"
            }
        }

        stage('Validate patchset'){
            steps {
                script {
                    env.REFSPEC_TO_VALIDATE = env.GERRIT_REFSPEC
                    def reviewRules = readYaml file: "technicals/ci_shared_lib_reviewers.yaml"
                    try {
                        env.REFSPEC_TO_VALIDATE = gitlib.checkAndGetCommitLastPatchSetReviewed(env.REFSPEC_TO_VALIDATE,reviewRules)
                    }
                    catch (Exception e) {
                        sendMessageToGerrit(env.GERRIT_REFSPEC, e.message)
                        error("""FAILURE: Validate patchset failed with exception: ${e.class.name},message:  ${e.message}
                        """)
                    }
                     // override with the latest refspec
                    env.GERRIT_REFSPEC = env.REFSPEC_TO_VALIDATE
                    echo ("Latest gerrit refspec:  ${env.GERRIT_REFSPEC}")
                }
            }
        }

        stage('Checkout LATEST_GERRIT_REFSPEC') {
            steps {
                script {
                    gitlib.checkoutRefSpec("${env.GERRIT_REFSPEC}", "FETCH_HEAD", "ci_shared_libraries")
                    dir('ci_shared_libraries') {
                        env.COMMIT_ID = gitlib.getCommitHashLong()
                        echo "env.COMMIT_ID=${env.COMMIT_ID}"
                    }
                }
            }
        }

        stage('Prepare') {
            steps {
                dir('ci_shared_libraries') {
                    checkoutGitSubmodules()
                }
            }
        }

        stage('Check which files changed - doc'){
            steps {
                script {
                    SKIP_TESTING = checkIfCommitContainsOnlySkippableFiles(env.GERRIT_REFSPEC, [".md"])
                    echo("SKIP_TESTING: " + SKIP_TESTING)
                }
            }
        }

        stage('Check which files changed - src'){
            steps {
                script {
                    env.JOB_TESTS = false
                    env.LIB_TESTS = false

                    changedFiles = getGerritQueryPatchsetChangedFiles(env.GERRIT_REFSPEC)
                    changedFiles.each { file ->
                        print file
                        if ( file.endsWith(".Jenkinsfile" ) ) {
                            env.JOB_TESTS = true
                        }
                        if ( file.endsWith(".groovy" ) ) {
                            env.LIB_TESTS = true
                        }
                    }
                }
            }
        }

        stage('Run when not just doc file in the change ') {
            when {
                expression { SKIP_TESTING == false }
            }
            stages {

                stage('Check Test Jenkins seed job availability') {
                    steps {
                        script {
                            // setup test jenkins URL
                            echo "TEST_JENKINS_URL is '${TEST_JENKINS_URL}'"
                        }
                        // check test jenkins all-jobs-seed-shared-lib api  connection ok
                        withCredentials([usernamePassword(credentialsId: '  test-jenkins-token', usernameVariable: 'TEST_USER', passwordVariable: 'TEST_USER_PASSWORD')])
                        {
                            echo "TEST_JENKINS_URL is '${TEST_JENKINS_URL}'"
                            sh '''
                                curl -XGET ${TEST_JENKINS_URL}/job/all-jobs-seed-shared-lib/api/json --user $TEST_USER:$TEST_USER_PASSWORD --insecure
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
                                dir ('ci_shared_libraries'){
                                    script {
                                        gitlib.createOrMoveRemoteGitBranch("${TEST_BRANCH_NAME}")
                                    }
                                }
                            }
                        }

                        stage('Setup jobs on test environment') {
                            steps {
                                step([$class: 'RemoteBuildConfiguration',
                                    auth2 : [$class: 'CredentialsAuth', credentials:'test-jenkins-token' ],
                                    remoteJenkinsName : 'test-jenkins',
                                    remoteJenkinsUrl : "${TEST_JENKINS_URL}",
                                    job: 'all-jobs-seed-shared-lib',
                                    token : 'kakukk',
                                    overrideTrustAllCertificates : true,
                                    trustAllCertificates : true,
                                    blockBuildUntilComplete : true
                                    ]
                                )
                            }
                        }

                        stage('Run functional test job on test jenkins') {
                            steps {
                                step([$class: 'RemoteBuildConfiguration',
                                    auth2 : [$class: 'CredentialsAuth' ,credentials:'test-jenkins-token' ],
                                    remoteJenkinsName : 'test-jenkins',
                                    remoteJenkinsUrl : "${TEST_JENKINS_URL}",
                                    job: "functional-test-shared-lib",
                                    token : 'kakukk',
                                    overrideTrustAllCertificates : true,
                                    trustAllCertificates : true,
                                    blockBuildUntilComplete : true
                                    ]
                                )
                            }
                        }
                    }
                }
            }
        }

        stage('Submit & merge changes to master') {
            when {
                expression { params.SKIP_PUBLISH == false }
            }
            steps {
                dir ('ci_shared_libraries'){
                    script {
                        gitlib.gerritReviewAndSubmit(env.COMMIT_ID, '--verified +1 --code-review +2 --submit', 'EEA/ci_shared_libraries')
                    }
                }
            }
        }

        stage('Get latest commit hash after merge') {
            steps {
                script {
                    // override env.COMMIT id, so that git tag can point to the merged commit
                    env.COMMIT_ID = gitlib.getCommitRevision(env.GERRIT_CHANGE_NUMBER)
                    echo "env.COMMIT_ID: ${env.COMMIT_ID}"

                    env.CI_LIB_VERSION = ''
                    env.CHART_NAME = ''
                    env.CHART_REPO = ''
                }
            }
        }

        stage('Generate version') {
            when {
                expression { params.SKIP_PUBLISH == false && SKIP_TESTING == false }
            }
            steps {
                dir ('ci_shared_libraries') {
                    script {
                        sh './bob/bob -r ruleset2.0.yaml generate-version'
                        env.CI_LIB_VERSION = readFile(".bob/var.version").trim()
                        echo "env.CI_LIB_VERSION: ${env.CI_LIB_VERSION}"
                    }
                }
            }
        }

        stage('Create Git Tag') {
            when {
                expression { params.SKIP_PUBLISH == false && SKIP_TESTING == false }
            }
            steps {
                dir ('ci_shared_libraries') {
                    script {
                        gitlib.createOrMoveRemoteGitTag(env.CI_LIB_VERSION, "ci_shared_libraries-${env.CI_LIB_VERSION}")
                    }
                }
            }
        }

        stage ('Package and Upload Helm') {
            when {
                expression { params.SKIP_PUBLISH == false }
            }
            steps {
                dir('ci_shared_libraries') {
                    script {
                        withCredentials([usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD'),
                            usernamePassword(credentialsId: 'arm-functional-user', usernameVariable: 'SELI_ARM_USER', passwordVariable: 'API_TOKEN'),
                            usernamePassword(credentialsId: 'arm-functional-user', usernameVariable: 'HELM_USER', passwordVariable: 'HELM_TOKEN')]) {
                                sh './bob/bob publish'
                                env.CHART_NAME = readFile(".bob/var.hc-name").trim()
                                env.CHART_REPO = readFile(".bob/var.hc-repo").trim()
                                echo "env.CHART_NAME: ${env.CHART_NAME}"
                                echo "env.CHART_REPO: ${env.CHART_REPO}"
                                echo "env.GIT_REPO_URL: ${env.GIT_REPO_URL}"
                        }
                    }
                }
            }
        }

        stage('Archive artifacts') {
            steps {
                dir('ci_shared_libraries') {
                    script {
                        sh """
                        cat > artifact.properties << EOF
CHART_VERSION=${env.CI_LIB_VERSION}
CHART_NAME=${env.CHART_NAME}
CHART_REPO=${env.CHART_REPO}
GERRIT_CHANGE_SUBJECT=${env.GERRIT_CHANGE_SUBJECT}
GERRIT_CHANGE_OWNER_NAME=${env.GERRIT_CHANGE_OWNER_NAME}
EOF
"""
                        archiveArtifacts 'artifact.properties'
                    }
                }
            }
        }

    }

    post {
        failure {
            script {
                if (env.GERRIT_REFSPEC) {
                    env.GERRIT_MSG = "Build Failed ${BUILD_URL}: FAILURE"
                    sendMessageToGerrit(env.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }
        success {
            script {
                if (env.GERRIT_REFSPEC) {
                    env.GERRIT_MSG = "Build Successful ${BUILD_URL}: SUCCESS"
                    sendMessageToGerrit(env.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }
        cleanup {
            cleanWs()
        }
    }
}
