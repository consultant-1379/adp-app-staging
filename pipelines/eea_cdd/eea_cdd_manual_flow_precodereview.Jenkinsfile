@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field gitcdd = new GitScm(this, 'EEA/cdd')
@Field gitadp = new GitScm(this, 'EEA/adp-app-staging')

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
                pattern: 'EEA/cdd',
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

        stage('Checkout cdd') {
            steps {
                script {
                    gitcdd.checkoutRefSpec("${GERRIT_REFSPEC}", "FETCH_HEAD", 'cdd')
                }
            }
        }

        stage('Checkout adp-app-staging') {
            steps {
                script {
                    gitadp.checkout("master", "adp-app-staging")
                }
            }
        }

        stage('Check Ruleset') {
            steps {
                script {
                    gitcdd.checkRulesetRepo("${GERRIT_REFSPEC}")
                }
            }
        }

        stage('Prepare') {
            steps {
                dir('cdd') {
                    checkoutGitSubmodules()
                }
            }
        }

        stage('Rulesets DryRun') {
            steps {
                dir('cdd') {
                    script {
                        rulesetsDryRun()
                    }
                }
            }
        }

        stage('Clean') {
            steps {
                dir('cdd') {
                    script {
                        sh 'bob/bob -r bob-rulesets/ruleset2.0.yaml clean'
                    }
                }
            }
        }

        stage('Jenkins patchset hooks') {
            steps {
                script {
                    try {
                        def result = sh(
                                script: "${WORKSPACE}/adp-app-staging/technicals/shellscripts/run_verify_hooks_common.sh \$GERRIT_PATCHSET_REVISION \$BUILD_URL ${WORKSPACE}/cdd ${WORKSPACE}/adp-app-staging technicals/hooks_static/pre_* technicals/hooks/pre_*",
                                returnStatus : true
                        )
                        sh "echo ${result}"
                        if (result != 0) {
                            error "JENKINS PATCHSET HOOKS FAILED"
                        }
                    } catch (err) {
                        error "JENKINS PATCHSET HOOKS FAILED\nCaught: ${err}"
                    }
                }
            }
        }

        stage('Check if jenkins/* changed') {
            steps {
                script {
                    changedFiles = gitcdd.getGerritQueryPatchsetChangedFiles("${GERRIT_REFSPEC}")
                    env.GENERATE_XML = false
                    changedFiles.each { file ->
                        print file
                        if (file.startsWith("jenkins/")) {
                            env.GENERATE_XML = true
                            echo "Changes found in jenkins/ directory. Generate XMLs stage will be executed"
                        }
                    }
                }
            }
        }

        stage('Generate XMLs') {
            when {
                expression { env.GENERATE_XML.toBoolean() }
            }
            steps {
                build job: "eea-jenkins-docker-xml-generator", parameters: [
                    stringParam(name: 'GIT_BRANCH', value: ""),
                    stringParam(name: 'GERRIT_REFSPEC', value : "${env.GERRIT_REFSPEC}")
                ], wait: true
            }
        }
    }
    post {
        cleanup {
            cleanWs()
        }
    }
}
