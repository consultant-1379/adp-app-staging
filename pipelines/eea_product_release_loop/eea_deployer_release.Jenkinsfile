@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import com.ericsson.eea4.ci.Artifactory

@Field def gitdeployer = new GitScm(this, 'EEA/deployer')
@Field def gitmeta = new GitScm(this, 'EEA/project-meta-baseline')
@Field def arm = new Artifactory(this, "https://arm.seli.gic.ericsson.se/", "API_TOKEN_EEA")

def releasedVersion
def nextVersion
def newVersion

pipeline {
    options {
        ansiColor('xterm')
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
        string(name: 'DEPLOYER_GIT_TAG_STRING', description: 'PRA git tag, e.g.: eea4_4.4.0_pra', defaultValue: '')
    }

    environment {
        EEA_DEPLOYER_CHART_NAME='eric-eea-deployer'
        EEA_DEPLOYER_CHART_REPO='https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/'
        EEA_DEPLOYER_CHART_REPO_RELEASED='https://arm.seli.gic.ericsson.se/artifactory/proj-eea-released-helm/'
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
                    gitdeployer.checkout('master', '')
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
                        env.EEA_DEPLOYER_CHART_VERSION = ''
                        // get EEA_DEPLOYER_CHART_VERSION
                        def chart = readYaml file: 'eric-eea-ci-meta-helm-chart/Chart.yaml'
                        chart.dependencies.each { dependency ->
                            if (dependency.name == env.EEA_DEPLOYER_CHART_NAME) {
                                env.EEA_DEPLOYER_CHART_VERSION = dependency.version
                                echo "env.EEA_DEPLOYER_CHART_VERSION: ${env.EEA_DEPLOYER_CHART_VERSION}"
                            }
                        }
                    }
                }
            }
        }

        stage('Checkout deployer') {
            steps {
                script {
                    dir('deployer-release') {
                        // checkout git tag = EEA_DEPLOYER_CHART_VERSION to release proper git branch
                        gitdeployer.checkoutRefSpec("refs/tags/${env.EEA_DEPLOYER_CHART_VERSION}", 'FETCH_HEAD', 'deployer')
                    }
                }
            }
        }

        stage('Upload DEPLOYER Helm Chart') {
            steps {
                // Generate deployer helm chart
                withCredentials([
                                usernamePassword(credentialsId: 'arm-functional-user', usernameVariable: 'HELM_USER', passwordVariable: 'HELM_TOKEN'),
                                usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD'),
                                string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                    sh 'bob/bob -r bob-rulesets/ruleset2.0_deployer_release.yaml publish-eea-deployer-released-helm-chart'
                }
            }
        }

        stage('Init versions') {
            steps {
                script {
                    releasedVersion = readFile(".bob/var.eea-deployer-released-version").trim()
                    nextVersion = readFile(".bob/var.eea-deployer-next-version")
                    newVersion = nextVersion + '-1'
                    echo "Released version: ${releasedVersion}"
                    currentBuild.description = "Released version: <a href=\" https://arm.seli.gic.ericsson.se/artifactory/proj-eea-released-helm-local/eric-eea-deployer/eric-eea-deployer-${releasedVersion}.tgz\">eric-eea-deployer-${releasedVersion}.tgz</a>"
                    echo "Next version: ${nextVersion}"
                    echo "New version: ${newVersion}"
                    currentBuild.description += "<br>New version: ${newVersion}"
                }
            }
        }

        stage('Release git branch') {
            steps {
                script {
                    dir('deployer-release') {
                        withCredentials([usernameColonPassword(credentialsId: 'git-functional-http-user', variable: 'ECEAGIT_TOKEN')]) {
                            echo "Get EEA Deployer git branch name from git tag: ${params.DEPLOYER_GIT_TAG_STRING} ..."
                            def gitBranchName = sh(
                                script: """echo "${params.DEPLOYER_GIT_TAG_STRING}" | sed "s/_pra//"
                                """,
                                returnStdout: true).trim()
                            echo "Check if git branch: ${gitBranchName} exists in deployer repo ..."
                            env.GIT_BRANCH_EXISTS = sh(
                                script: """git ls-remote --heads "https://${ECEAGIT_TOKEN}@${GERRIT_HOST}/a/EEA/deployer.git" "${gitBranchName}"
                                """,
                                returnStdout: true).trim()
                            if (env.GIT_BRANCH_EXISTS == "") {
                                echo "git branch: ${gitBranchName} doesn't exists in deployer repo, creating ..."
                                try {
                                    sh (script: """#!/bin/bash
                                        baseCommit=\$(git log --format="%H" -n 1)
                                        git push https://${ECEAGIT_TOKEN}@${GERRIT_HOST}/a/EEA/deployer.git ${'$'}baseCommit:refs/heads/${gitBranchName}
                                    """)
                                } catch (err) {
                                    echo "Caught: ${err}"
                                    error "Error creating git branch: ${gitBranchName} in deployer repo!"
                                }

                                echo "Check if git branch: ${gitBranchName} exists in deployer repo (after creating) ..."
                                try {
                                    env.GIT_BRANCH_EXISTS = sh(
                                        script: """git ls-remote --heads "https://${ECEAGIT_TOKEN}@${GERRIT_HOST}/a/EEA/deployer.git" "${gitBranchName}"
                                        """,
                                        returnStdout: true).trim()
                                    if (env.GIT_BRANCH_EXISTS == '') {
                                        error "Cannot find created git branch for git tag: ${params.DEPLOYER_GIT_TAG_STRING}!"
                                    }
                                } catch (err) {
                                    echo "Caught: ${err}"
                                    error "Error checking git branch: ${gitBranchName} in deployer repo!"
                                }
                            }
                        }
                    }
                }
            }
        }

        stage('DEPLOYER + package build') {
            steps {
                script {
                    env.EEA_DEPLOYER_VERSION_RELEASE = readFile(".bob/var.eea-deployer-released-version").trim()
                    build job: 'eea-deployer-build-deployer-package',
                    parameters: [
                        stringParam(name: 'CHART_VERSION', value: "${env.EEA_DEPLOYER_VERSION_RELEASE}"),
                        stringParam(name: 'GERRIT_REFSPEC', value: "refs/tags/${env.EEA_DEPLOYER_CHART_VERSION}"),
                        booleanParam(name: 'IS_RELEASE', value: true)
                    ], wait : true
                }
            }
        }

        stage('Create PRA Git Tag') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')])
                {
                    withEnv(["EEA_DEPLOYER_GIT_TAG_STRING=${params.DEPLOYER_GIT_TAG_STRING}"]) {
                        sh './bob/bob -r bob-rulesets/ruleset2.0_deployer_release.yaml create-pra-git-tag:git-tag'
                    }
                }
            }
        }

        stage('Exec eea-deployer-release-new-version') {
            steps {
                script {
                    build job: 'eea-deployer-release-new-version',
                    parameters: [
                        booleanParam(name: 'DRY_RUN', value: false),
                        stringParam(name: 'REVISION_NUM', value: "${nextVersion}"),
                        stringParam(name: 'GIT_COMMENT', value: "Increase version after ${releasedVersion}")
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
