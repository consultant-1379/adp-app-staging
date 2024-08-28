@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def git = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitdoc = new GitScm(this, 'EEA/eea4_documentation')
@Field def gitcnint = new GitScm(this, 'EEA/cnint')

pipeline {
    agent {
        node {
            label 'productci'
        }
    }
    options {
      buildDiscarder(logRotator(daysToKeepStr: "7"))
    }
    parameters {
        string(name: 'GERRIT_REFSPEC',  description: 'Gerrit Refspect of the integration chart git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'PWD',  description: 'The source docs folder (${env.PWD}/doc_src) can be defined, volume target in the container should be /doc_src', defaultValue: 'doc')
    }

    triggers {
        gerrit (
            serverName: 'GerritCentral',
            gerritProjects: [[
                compareType: 'PLAIN',
                pattern: 'EEA/eea4_documentation',
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

        stage('Prepare') {
            steps {
                checkoutGitSubmodules()
            }
        }

        stage('Checkout - adp-app-staging'){
            steps{
                script{
                    git.checkout(env.MAIN_BRANCH, 'adp-app-staging')
                }
            }
        }

        stage('Checkout - eea4_documentation'){
            steps{
                script{
                    gitdoc.checkoutRefSpec("${GERRIT_REFSPEC}","FETCH_HEAD", '')
                }
            }
        }

        stage('Check unmerged parents') {
            steps {
                dir('eea4_documentation') {
                    script {
                        catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                            parentCommitStatus = gitdoc.checkGerritQueryParentStatus(GERRIT_REFSPEC)
                            if (parentCommitStatus && parentCommitStatus.toUpperCase() != 'MERGED') {
                                error("Specified refspec ${GERRIT_REFSPEC} has unmerged parent commit(s). Cherry-picking a commit with one- or more possible unmerged parents is not safe!")
                            }
                        }
                    }
                }
            }
        }

        stage('Rulesets DryRun') {
            steps {
                script {
                    rulesetsDryRun(rulesets=[],rulesetsPathToSkip=['adp-app-staging/'])
                }
            }
        }

        stage('Rulesets Validations') {
            steps {
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

        stage('Get helm chart version'){
             steps {
                 dir('cnint') {
                     script {
                         gitcnint.checkout('master','')
                     }
                 }
             }
        }

        stage('Documentation building') {
            steps {
                script {
                    withCredentials([ string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN')]){
                      env.CHART_YAML_PATH = "${WORKSPACE}/cnint/eric-eea-int-helm-chart/Chart.yaml"
                      env.HELM_CHART_VERSION = sh(script:"python3 ${WORKSPACE}/adp-app-staging/technicals/pythonscripts/helm_chart_version_parser.py -p \"${env.CHART_YAML_PATH}\"", returnStdout: true).trim()
                      sh 'bob/bob -r bob-rulesets/document_verify.yaml lint'
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
