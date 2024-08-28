@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def gitconf = new GitScm(this, 'EEA/eea4-ci-config')
@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')

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
        stage("Params DryRun check") {
            when {
                expression { params.DRY_RUN == true }
            }
            steps {
                script {
                    dryRun()
                }
            }
        }

        stage("Checkout - eea4-ci-config") {
            steps {
                script {
                    gitconf.checkoutRefSpec("${GERRIT_REFSPEC}", "FETCH_HEAD", 'eea4-ci-config')
                }
            }
        }

        stage("Prepare") {
            steps {
                dir('eea4-ci-config') {
                    checkoutGitSubmodules()
                }
            }
        }

        stage("Checkout - scripts") {
            steps {
                dir("technicals") {
                    script {
                        gitadp.archiveDir('EEA/adp-app-staging', 'HEAD:technicals/')
                    }
                }
            }
        }

        stage("Jenkins patchset hooks") {
            steps {
                dir('eea4-ci-config') {
                    script {
                        try {
                            def result = sh(
                                    script: "${WORKSPACE}/technicals/shellscripts/run_verify_hooks_common.sh \$GERRIT_PATCHSET_REVISION \$BUILD_URL ${WORKSPACE}/eea4-ci-config ${WORKSPACE} technicals/hooks_static/pre_* technicals/hooks/pre_*",
                                    returnStatus : true
                            )
                            sh "echo ${result}"
                            if (result != 0) {
                                currentBuild.result = 'FAILURE'
                            }
                        } catch (err) {
                            echo "Caught: ${err}"
                            currentBuild.result = 'FAILURE'
                        }
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
                dir('eea4-ci-config') {
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
    }

    post {
        cleanup {
            cleanWs()
        }
    }
}
