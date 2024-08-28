@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def git_shared_lib = new GitScm(this, 'EEA/ci_shared_libraries')

pipeline {

    options {
        disableConcurrentBuilds()
        skipDefaultCheckout()
        buildDiscarder(logRotator(daysToKeepStr: '14', artifactDaysToKeepStr: '7'))
    }

    agent {
        node {
            label 'productci'
        }
    }

    parameters {
        choice(name: 'VERSION_TYPE', choices: ['MAJOR', 'MINOR', 'PATCH'], description: 'Type of release version update')
        booleanParam(name: 'PUBLISH_DRY_RUN', description: 'Enable dry-run for version increase (skip git push)', defaultValue:false)
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
        stage('Checkout ci_shared_libraries') {
            steps {
                script {
                    git_shared_lib.checkout(env.MAIN_BRANCH, 'ci_shared_libraries')
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
        stage('Increment version prefix') {
            steps {
                dir('ci_shared_libraries') {
                    withCredentials([usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                        sh './bob/bob -r ruleset2.0.yaml increment-version-prefix'
                    }
                }
            }
        }

        stage ('Package and Upload Helm') {
            steps {
                dir('ci_shared_libraries') {
                    script {
                        withCredentials([usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD'),
                        usernamePassword(credentialsId: 'arm-functional-user', usernameVariable: 'SELI_ARM_USER', passwordVariable: 'API_TOKEN'),
                        usernamePassword(credentialsId: 'arm-functional-user', usernameVariable: 'HELM_USER', passwordVariable: 'HELM_TOKEN')]) {
                           sh 'cat VERSION_PREFIX > .bob/var.version'
                           sh './bob/bob  publish'
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
