@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import com.ericsson.eea4.ci.Artifactory

@Field def gitdoc = new GitScm(this, 'EEA/eea4_documentation')
@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def arm = new Artifactory(this, "https://arm.seli.gic.ericsson.se/",  "API_TOKEN_EEA")

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
        string(name: 'RELEASE_CANDIDATE', description: 'The helm chart release candidate version (e.g. 1.0.0-7)', defaultValue: '')
        string(name: 'GIT_TAG_STRING', description: 'PRA', defaultValue: 'PRA release')
        string(name: 'SOURCE_REPO', description: 'The arm repo of the release candidate', defaultValue: 'proj-eea-docs-drop-generic-local')
        string(name: 'SOURCE_FOLDER', description: 'The folder of the release candidate in the arm repo', defaultValue: 'product-level-docs')
        string(name: 'RELEASED_REPO', description: 'The arm repo of the released version', defaultValue: 'proj-eea-docs-released-generic-local')
        string(name: 'RELEASED_FOLDER', description: 'The folder of the released version in the arm repo', defaultValue: 'product-level-docs')
        booleanParam(name: 'PUBLISH_DRY_RUN', description: 'Enable dry-run for helm chart publish, git tagging and version increase', defaultValue: false)
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

        stage('Checkout adp-app-staging') {
            steps {
                script {
                    gitadp.checkout(env.MAIN_BRANCH, '')
                }
            }
        }
        stage('Checkout eea4_documentation') {
            steps {
                script {
                    gitdoc.checkout(env.MAIN_BRANCH, 'eea4_documentation')
                }
            }
        }
        stage('Prepare') {
            steps {
                dir('eea4_documentation') {
                    checkoutGitSubmodules()
                }
            }
        }
        stage('Cleanup') {
            steps {
                dir('eea4_documentation') {

                    sh './bob/bob -r bob-rulesets/documentation_release.yaml clean'
                }
            }
        }
        stage('Init') {
            steps {
                dir('eea4_documentation') {
                    sh './bob/bob -r bob-rulesets/documentation_release.yaml doc-init'
                    archiveArtifacts 'artifact.properties'
                    script {
                        def props = readProperties  file: 'eric-eea-documentation-helm-chart-ci/Chart.yaml'
                        def CHART_NAME = props['name']
                        def CHART_VERSION = readFile file: '.bob/var.released-version'
                        currentBuild.description = CHART_NAME + ': ' + CHART_VERSION + ' slave: ' + "${env.NODE_NAME}"
                    }
                }
            }
        }
        stage('Copy released artifacts') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                        arm.setUrl("https://arm.seli.gic.ericsson.se/", "$API_TOKEN_EEA")
                        arm.copyArtifact("${params.SOURCE_FOLDER}/${params.RELEASE_CANDIDATE}", "${params.SOURCE_REPO}", "${params.RELEASED_FOLDER}/${params.RELEASE_CANDIDATE}", "${params.RELEASED_REPO}")
                    }
                }
            }

        }
        stage('Publish released helm chart') {
            steps {
                dir('eea4_documentation') {
                    withCredentials([usernamePassword(credentialsId: 'arm-functional-user', usernameVariable: 'HELM_USER', passwordVariable: 'HELM_TOKEN')])
                    {
                        // Repackage and Upload helm chart to -released helm chart repository
                        sh './bob/bob -r bob-rulesets/documentation_release.yaml publish-released-helm-chart'
                    }
                }
            }
        }
        stage('Create PRA Git Tag') {
            steps {
                dir('eea4_documentation') {
                    withCredentials([usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')])
                    {
                        // Create git tag 'v<released version>'
                        sh './bob/bob -r bob-rulesets/documentation_release.yaml create-pra-git-tag'
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
