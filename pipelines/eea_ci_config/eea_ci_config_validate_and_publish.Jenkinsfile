@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitconf = new GitScm(this, 'EEA/eea4-ci-config')

// changed files to validate
def changedFiles

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
        string(name: 'GERRIT_REFSPEC', description: 'Gerrit Refspec of the ci config git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
        booleanParam(name: 'SKIP_PUBLISH', description: 'Executes only the validation parts and skip the publish parts (submit, merge, tagging, etc.)', defaultValue: false)
    }
    triggers {
        gerrit (
            serverName: 'GerritCentral',
            gerritProjects: [[
                compareType: 'PLAIN',
                pattern: 'EEA/eea4-ci-config',
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
                    def reviewRules = readYaml file: "technicals/eea4_ci_config_reviewers.yaml"
                    try {
                        env.REFSPEC_TO_VALIDATE = gitconf.checkAndGetCommitLastPatchSetReviewed(env.REFSPEC_TO_VALIDATE,reviewRules)
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
                    gitconf.checkoutRefSpec("${env.GERRIT_REFSPEC}", "FETCH_HEAD", "eea4-ci-config")
                    dir('eea4-ci-config') {
                        env.COMMIT_ID = gitconf.getCommitHashLong()
                        echo "env.COMMIT_ID=${env.COMMIT_ID}"
                    }
                }
            }
        }

        stage("Get changed files") {
            steps {
                script {
                    changedFiles = gitconf.getGerritQueryPatchsetChangedFiles("${GERRIT_REFSPEC}")
                    echo "changedFiles: " + changedFiles
                }
            }
        }

        stage("Validate cluster lock params") {
            steps {
                dir("eea4-ci-config") {
                    script {
                        def clusterLockParams = "config/cluster_lock_params.json"
                        def schema = "schema/cluster_lock_params.schema.json"
                        if (changedFiles.contains(clusterLockParams)) {
                            jsonSchemaValidate(schema, clusterLockParams)
                        }
                    }
                }
            }
        }

        stage("Validate kubectl/helm uplift config params") {
            steps {
                dir('eea4-ci-config') {
                    script {
                        def upliftParams = "config/kubectl_helm_uplift.json"
                        def schema = "schema/kubectl_helm_uplift.schema.json"
                        if (changedFiles.contains(upliftParams)) {
                            jsonSchemaValidate(schema, upliftParams)
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
                dir ('eea4-ci-config'){
                    script {
                        gitconf.gerritReviewAndSubmit(env.COMMIT_ID, '--verified +1 --code-review +2 --submit', 'EEA/eea4-ci-config')
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
