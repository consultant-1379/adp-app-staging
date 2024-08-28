@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.Artifactory
import groovy.transform.Field

@Field def gitdeployer = new GitScm(this, 'EEA/deployer')
@Field def arm = new Artifactory(this, "https://arm.seli.gic.ericsson.se/",  "API_TOKEN_EEA")

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
        string(name: 'REVISION_NUM', description: 'revision number in values.yaml', defaultValue: '')
        string(name: 'GIT_COMMENT', description: 'Comment for the version increase change', defaultValue: 'version increase')
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

        stage('push patchset') {
            environment {
                DEPLOYER_CHART_PATH="${WORKSPACE}/helm/eric-eea-deployer/Chart.yaml"
            }
            steps {
                script {
                    def NEW_VERSION = REVISION_NUM + '-1'
                    echo "NEW_VERSION: ${NEW_VERSION}"
                    currentBuild.description = "New version: ${NEW_VERSION}"

                    def data = readYaml file: "${env.DEPLOYER_CHART_PATH}"
                    def old_version = data.version
                    def replace = "version: " + "${NEW_VERSION}"
                    sh """sed -i "s/version: $old_version/$replace/"  ${DEPLOYER_CHART_PATH}"""
                }
                withCredentials([usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'TEST_USER', passwordVariable: 'TEST_USER_PASSWORD')]){
                    sh """
                    set -x
                    git add ${env.DEPLOYER_CHART_PATH}
                    git config --local credential.helper "!f() { echo username=\\$TEST_USER; echo password=\\$TEST_USER_PASSWORD; }; f"
                    mkdir -p .git/hooks
                    curl -Lo `git rev-parse --git-dir`/hooks/commit-msg https://$TEST_USER@${GERRIT_HOST}/tools/hooks/commit-msg
                    chmod +x `git rev-parse --git-dir`/hooks/commit-msg
                    git commit -am "${params.GIT_COMMENT}"
                    git push origin HEAD:refs/for/master
                  """

                }
                script {
                    def git_id = sh(
                        script: "git log --format=\"%H\" -n 1",
                        returnStdout : true
                    )trim()
                    echo "git id=${git_id}"
                    sh(
                        script: "ssh -o StrictHostKeyChecking=no -p 29418 ${GERRIT_HOST} gerrit query --current-patch-set ${git_id} --format json  > gerrit_result"
                    )
                    def filePath = readFile "${WORKSPACE}/gerrit_result"
                    def lines = filePath.readLines()
                    def data = readJSON text: lines[0]
                    echo "ref: ${data.currentPatchSet.ref}"   //DEBUG
                    env.GERRIT_REFSPEC = data.currentPatchSet.ref
                    currentBuild.description += "<br>GERRIT_REFSPEC: ${env.GERRIT_REFSPEC}"
                }
            }
        }

        stage('Prepare') {
            steps {
                checkoutGitSubmodules()
            }
        }

        stage('Publish DEPLOYER Helm Chart') {
            steps {
                // Generate deployer helm chart
                withCredentials([
                                usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD'),
                                string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                    sh 'bob/bob -r bob-rulesets/ruleset2.0.yaml publish'
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
