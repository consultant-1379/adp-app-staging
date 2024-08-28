@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.CommonUtils
import com.ericsson.eea4.ci.ClusterLockUtils
import groovy.transform.Field

@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitmeta = new GitScm(this, 'EEA/project-meta-baseline')
@Field def cmutils = new CommonUtils(this)
@Field def clusterLockUtils =  new ClusterLockUtils(this)

pipeline {
    agent {
        node {
            label 'productci'
        }
    }
    options {
        buildDiscarder(logRotator(daysToKeepStr: '14', artifactDaysToKeepStr: '7'))
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

    environment {
        DIMTOOL_CHART_PATH = ".bob/eric-eea-int-helm-chart_tmp/eric-eea-int-helm-chart"
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

        stage('Wait for baseline-install resource is free') {
            steps {
                script {
                    while ( clusterLockUtils.getResourceLabelStatus("baseline-publish") != "FREE" ) {
                        sleep(time: 5, unit: 'MINUTES' )
                    }
                }
            }
        }

        stage('Checkout - scripts') {
            steps {
                script {
                    gitadp.sparseCheckout("technicals/")
                }
            }
        }
        stage('Checkout - cnint') {
            steps {
                script {
                    gitcnint.checkoutRefSpec("${GERRIT_REFSPEC}", "FETCH_HEAD", 'cnint')
                }
            }
        }

        stage('Gather reviewers list for files in patchset') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {
                    script {
                        reviewRules = readYaml file: "technicals/cnint_reviewers.yaml"
                        gitcnint.verifyCodeReviewers("${GERRIT_REFSPEC}", reviewRules)
                    }
                }
            }
        }

        stage('Check Ruleset') {
            steps {
                script {
                    dir('cnint') {
                        gitcnint.checkRulesetRepo("${GERRIT_REFSPEC}")
                    }
                }
            }
        }

        stage('Prepare') {
            steps {
                script {
                    dir('cnint') {
                        checkoutGitSubmodules()
                    }
                }
            }
        }

        stage('Prepare Helm Chart') {
            steps {
                script {
                    dir('cnint') {
                        // Generate integration helm chart
                        withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                         string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                         string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                         usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                            sh 'bob/bob prepare-without-upload'
                        }
                    }
                }
            }
        }

        stage('Get dataset informations from meta baseline') {
            steps {
                script {
                    gitmeta.checkout('master', 'project-meta-baseline')
                    env.DATASET_NAME = cmutils.getDatasetVersion("${WORKSPACE}/project-meta-baseline/eric-eea-ci-meta-helm-chart","values.yaml")
                    sh "echo 'DATASET_NAME=${env.DATASET_NAME}' >> cnint/artifact.properties"
                    env.REPLAY_SPEED = cmutils.getDatasetReplaySpeed("${WORKSPACE}/project-meta-baseline/eric-eea-ci-meta-helm-chart","values.yaml")
                    sh "echo 'REPLAY_SPEED=${env.REPLAY_SPEED}' >> cnint/artifact.properties"
                    env.META_BASELINE_CHART_VERSION = cmutils.getChartVersion("${WORKSPACE}/project-meta-baseline/eric-eea-ci-meta-helm-chart", "Chart.yaml")
                    sh "echo 'META_BASELINE_CHART_VERSION=${env.META_BASELINE_CHART_VERSION}' >> cnint/artifact.properties"
                    env.UTF_CHART_NAME = cmutils.extractSubChartData("eric-eea-utf-application", "name", "${WORKSPACE}/project-meta-baseline/eric-eea-ci-meta-helm-chart","Chart.yaml")
                    sh "echo 'UTF_CHART_NAME=${env.UTF_CHART_NAME}' >> cnint/artifact.properties"
                    env.UTF_CHART_REPO = cmutils.extractSubChartData("eric-eea-utf-application", "repository", "${WORKSPACE}/project-meta-baseline/eric-eea-ci-meta-helm-chart","Chart.yaml")
                    sh "echo 'UTF_CHART_REPO=${env.UTF_CHART_REPO}' >> cnint/artifact.properties"
                    env.UTF_CHART_VERSION = cmutils.extractSubChartData("eric-eea-utf-application", "version", "${WORKSPACE}/project-meta-baseline/eric-eea-ci-meta-helm-chart","Chart.yaml")
                    sh "echo 'UTF_CHART_VERSION=${env.UTF_CHART_VERSION}' >> cnint/artifact.properties"
                }
            }
        }

        stage('Run Dimensioning Tool'){
            steps{
                script{
                    dir('cnint'){
                        withCredentials([
                            usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                            string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')
                        ]){
                            try {
                                readProperties(file: 'artifact.properties').each {key, value -> env[key] = value }
                                sh 'bob/bob init:set-int-chart-version'
                                sh 'bob/bob dimtool-trigger > dimtool-trigger.log'
                            } catch (err) {
                                echo "RUN DIMTOOL FAILED"
                                error "Caught: ${err}"
                            }
                            finally {
                                archiveArtifacts artifacts: "dimtool-trigger.log", allowEmptyArchive: true
                                archiveArtifacts artifacts: ".bob/eea4-dimensioning-tool-user-input.zip", allowEmptyArchive: true
                                archiveArtifacts artifacts: ".bob/eea4-dimensioning-tool-output.zip", allowEmptyArchive: true
                            }
                        }
                    }
                }
            }
        }
        stage('Archive artifact.properties') {
            steps {
                // Archive artifact.properties so Spinnaker can read the parameters (GERRIT_REFSPEC)
                archiveArtifacts 'cnint/artifact.properties'
            }
        }
    }

    post {
        cleanup {
            cleanWs()
        }
    }
}
