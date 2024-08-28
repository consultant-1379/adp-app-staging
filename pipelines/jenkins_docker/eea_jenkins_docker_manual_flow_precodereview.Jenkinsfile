@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field gitjd = new GitScm(this, 'EEA/jenkins-docker')
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
                pattern: 'EEA/jenkins-docker',
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

        stage('Checkout jenkins-docker') {
            steps {
                script {
                    gitjd.checkoutRefSpec("${GERRIT_REFSPEC}", "FETCH_HEAD", 'jenkins-docker')
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
                    dir('jenkins-docker') {
                        def commitAuthor = gitjd.getCommitAuthor()
                        if ( commitAuthor != "ECEAGIT" ) {
                            echo "Commit Author is ${commitAuthor}\nCheck ruleset files will start:"
                            gitjd.checkRulesetRepo("${GERRIT_REFSPEC}")
                        } else {
                            echo "Commit Author is ${commitAuthor}\nSkip ruleset files check"
                        }
                    }
                }
            }
        }

        stage('Prepare') {
            steps {
                dir('jenkins-docker') {
                    checkoutGitSubmodules()
                }
            }
        }

        stage('Rulesets DryRun') {
            steps {
                dir('jenkins-docker') {
                    script {
                        rulesetsDryRun()
                    }
                }
            }
        }

        stage('Clean') {
            steps {
                dir('jenkins-docker') {
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
                                script: "${WORKSPACE}/adp-app-staging/technicals/shellscripts/run_verify_hooks_common.sh \$GERRIT_PATCHSET_REVISION \$BUILD_URL ${WORKSPACE}/jenkins-docker ${WORKSPACE}/adp-app-staging technicals/hooks_static/pre_* technicals/hooks/pre_*",
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

        stage('Init') {
            steps {
                dir ('jenkins-docker') {
                    script {
                        withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'HELM_USER', passwordVariable: 'API_TOKEN_EEA'),
                                     string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP')]) {
                            sh './bob/bob -r bob-rulesets/ruleset2.0.yaml init-ci-internal'
                        }
                    }
                }
            }
        }

        stage('build-docker-image') {
            steps {
                dir('jenkins-docker') {
                    sh 'bob/bob -r bob-rulesets/ruleset2.0.yaml build-docker-image'
                }
            }
        }

        stage('test-docker-image') {
            steps {
                dir('jenkins-docker') {
                    script {
                        withEnv(["JENKINS_DOCKER_CONTAINER_LOGFILE=jenkins_docker_container.log"]) {
                            try {
                                sh 'bob/bob -r bob-rulesets/ruleset2.0.yaml test-docker-image'
                            } catch (err) {
                                error "TEST DOCKER IMAGE FAILED\nCaught: ${err}"
                            } finally {
                                archiveArtifacts artifacts: "${JENKINS_DOCKER_CONTAINER_LOGFILE}", allowEmptyArchive: true
                            }
                        }
                    }
                }
            }
        }

        stage('cleanup-docker-image') {
            steps {
                dir('jenkins-docker') {
                    sh 'bob/bob -r bob-rulesets/ruleset2.0.yaml cleanup-docker-image'
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
