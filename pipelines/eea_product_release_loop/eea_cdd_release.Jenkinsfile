@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import com.ericsson.eea4.ci.Artifactory

@Field def gitcdd = new GitScm(this, 'EEA/cdd')
@Field def gitmeta = new GitScm(this, 'EEA/project-meta-baseline')
@Field def arm = new Artifactory(this, "https://arm.seli.gic.ericsson.se/", "API_TOKEN_EEA")

def releasedVersion
def nextVersion
def newVersion

pipeline {
    options {
        disableConcurrentBuilds()
        buildDiscarder(logRotator(daysToKeepStr: '14', artifactDaysToKeepStr: '7'))
    }
    agent {
        node {
            label 'productci'
        }
    }

    parameters {
        string(name: 'META_CHART_VERSION', description: 'Chart version of the metachart, eg: 4.4.0-1', defaultValue: '')
        string(name: 'CDD_GIT_TAG_STRING', description: 'PRA git tag, e.g.: eea4_4.4.0_pra', defaultValue: '')
        booleanParam(name: 'SEND_MESSAGE_TO_GERRIT', description: 'Turning off to send messages to Gerrit in all downstream jobs', defaultValue: false)
    }

    environment {
        CDD_CHART_NAME='eric-eea-cdd'
        CDD_CHART_REPO='https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/'
        CDD_CHART_REPO_RELEASED='https://arm.seli.gic.ericsson.se/artifactory/proj-eea-released-helm/'
    }

    stages {
        stage('Params DryRun check') {
            when {
                expression { params.DRY_RUN == true }
            }
            steps {
                dryRun()
            }
        }

        stage('Checkout') {
            steps {
                script {
                    gitcdd.checkout('master', '')
                }
            }
        }

        stage('Prepare') {
            steps {
                checkoutGitSubmodules()
            }
        }

        stage('Read versions from meta') {
            steps {
                script {
                    gitmeta.checkout(env.META_CHART_VERSION, 'project-meta-baseline')
                    dir('project-meta-baseline') {
                        env.CDD_CHART_VERSION = ''
                        // get CDD_CHART_VERSION
                        def chart = readYaml file: 'eric-eea-ci-meta-helm-chart/Chart.yaml'
                        chart.dependencies.each { dependency ->
                            if (dependency.name == env.CDD_CHART_NAME) {
                                env.CDD_CHART_VERSION = dependency.version
                                echo "env.CDD_CHART_VERSION: ${env.CDD_CHART_VERSION}"
                            }
                        }
                    }
                }
            }
        }

        stage('Checkout cdd') {
            steps {
                script {
                    dir('cdd-release') {
                        // checkout git tag = CDD_CHART_VERSION to release proper git branch
                        gitcdd.checkoutRefSpec("refs/tags/${env.CDD_CHART_VERSION}", 'FETCH_HEAD', 'cdd')
                    }
                }
            }
        }

        stage('Upload CDD Helm Chart') {
            steps {
                // Generate cdd helm chart
                withCredentials([
                                usernamePassword(credentialsId: 'arm-functional-user', usernameVariable: 'HELM_USER', passwordVariable: 'HELM_TOKEN'),
                                usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD'),
                                string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                    sh 'bob/bob -r bob-rulesets/ruleset2.0_cdd_release.yaml publish-cdd-released-helm-chart'
                }
            }
        }

        stage('Init versions') {
            steps {
                script {
                    releasedVersion = readFile(".bob/var.cdd-released-version").trim().split("\\+")[0];
                    nextVersion = readFile(".bob/var.cdd-next-version")
                    newVersion = nextVersion + '-1'
                    echo "Released version: ${releasedVersion}"
                    echo "Next version: ${nextVersion}"
                    echo "New version: ${newVersion}"
                }
            }
        }

        stage('Release git branch') {
            steps {
                script {
                    dir('cdd-release') {
                        withCredentials([usernameColonPassword(credentialsId: 'git-functional-http-user', variable: 'ECEAGIT_TOKEN')]) {
                            echo "Get cdd git branch name from git tag: ${params.CDD_GIT_TAG_STRING} ..."
                            def gitBranchName = sh(
                                script: """echo "${params.CDD_GIT_TAG_STRING}" | sed "s/_pra//"
                                """,
                                returnStdout: true).trim()
                            echo "Check if git branch: ${gitBranchName} exists in cdd repo ..."
                            env.GIT_BRANCH_EXISTS = sh(
                                script: """git ls-remote --heads "https://${ECEAGIT_TOKEN}@${GERRIT_HOST}/a/EEA/cdd.git" "${gitBranchName}"
                                """,
                                returnStdout: true).trim()
                            if (env.GIT_BRANCH_EXISTS == "") {
                                echo "git branch: ${gitBranchName} doesn't exists in cdd repo, creating ..."
                                try {
                                    sh (script: """#!/bin/bash
                                        baseCommit=\$(git log --format="%H" -n 1)
                                        git push https://${ECEAGIT_TOKEN}@${GERRIT_HOST}/a/EEA/cdd.git ${'$'}baseCommit:refs/heads/${gitBranchName}
                                    """)
                                } catch (err) {
                                    echo "Caught: ${err}"
                                    error "Error creating git branch: ${gitBranchName} in cdd repo!"
                                }

                                echo "Check if git branch: ${gitBranchName} exists in cdd repo (after creating) ..."
                                try {
                                    env.GIT_BRANCH_EXISTS = sh(
                                        script: """git ls-remote --heads "https://${ECEAGIT_TOKEN}@${GERRIT_HOST}/a/EEA/cdd.git" "${gitBranchName}"
                                        """,
                                        returnStdout: true).trim()
                                    if (env.GIT_BRANCH_EXISTS == '') {
                                        error "Cannot find created git branch for git tag: ${params.CDD_GIT_TAG_STRING}!"
                                    }
                                } catch (err) {
                                    echo "Caught: ${err}"
                                    error "Error checking git branch: ${gitBranchName} in cdd repo!"
                                }
                            }
                        }
                    }
                }
            }
        }

        stage('CDD + package build') {
            steps {
                script {
                    env.CDD_VERSION_RELEASE = readFile(".bob/var.cdd-released-version").trim()
                    build job: 'eea-cdd-build-cdd-package',
                    parameters: [
                        stringParam(name: 'CHART_VERSION', value: "${env.CDD_VERSION_RELEASE}"),
                        stringParam(name: 'GERRIT_REFSPEC', value: "refs/tags/${env.CDD_CHART_VERSION}"),
                        booleanParam(name: 'SEND_MESSAGE_TO_GERRIT', value: params.SEND_MESSAGE_TO_GERRIT)
                    ], wait : true
                }
            }
        }

        stage('Create PRA Git Tag') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')])
                {
                    sh './bob/bob -r bob-rulesets/ruleset2.0_cdd_release.yaml create-pra-git-tag:git-tag'
                }
            }
        }

        stage('Exec eea-cdd-release-new-version') {
            steps {
                script {
                    build job: 'eea-cdd-release-new-version',
                    parameters: [
                        booleanParam(name: 'DRY_RUN', value: false),
                        stringParam(name: 'REVISION_NUM', value: "${nextVersion}"),
                        stringParam(name: 'GIT_COMMENT', value: "Increase version after PRA ${releasedVersion}")
                    ], wait: true
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
