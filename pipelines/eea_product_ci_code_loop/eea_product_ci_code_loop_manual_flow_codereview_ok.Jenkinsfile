@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def git = new GitScm(this, 'EEA/adp-app-staging')

pipeline {
    agent {
        node {
            label 'productci'
        }
    }
    options {
        skipDefaultCheckout()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(daysToKeepStr: '7', artifactDaysToKeepStr: "7"))
    }
    parameters {
        string(name: 'GERRIT_REFSPEC', description: 'Gerrit Refspec of the adp-app-staging git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
    }
    triggers {
        gerrit (
            serverName: 'GerritCentral',
            gerritProjects: [[
                compareType: 'PLAIN',
                pattern: 'EEA/adp-app-staging',
                branches: [[ compareType: 'PLAIN', pattern: env.MAIN_BRANCH ]],
                disableStrictForbiddenFileVerification: false,
                topics: [[ compareType: 'REG_EXP', pattern: '^((?!^inca$).)*$' ]]
            ]],
            triggerOnEvents:  [
                [
                    $class              : 'PluginCommentAddedEvent',
                    verdictCategory       : 'Code-Review',
                    commentAddedTriggerApprovalValue: '+1'
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

        stage('Gerrit message') {
            when {
                expression { env.GERRIT_REFSPEC }
            }
            steps {
                script {
                    env.GERRIT_MSG = "Build Started ${BUILD_URL}"
                    sendMessageToGerrit(env.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
             }
         }

        stage('Checkout - scripts'){
            steps {
                script {
                    git.sparseCheckout("technicals/")
                }
            }
        }

        stage('Rebase') {
            when {
                expression { env.GERRIT_REFSPEC }
            }
            steps {
                sh "technicals/shellscripts/gerrit_rebase.sh --refspec ${env.GERRIT_REFSPEC}"
            }
        }

        stage('Set LATEST_GERRIT_REFSPEC') {
            steps {
                script {
                    env.GERRIT_CHANGE_NUMBER = git.getCommitIdFromRefspec(env.GERRIT_REFSPEC)
                    echo "env.GERRIT_CHANGE_NUMBER=${env.GERRIT_CHANGE_NUMBER}"

                    env.LATEST_GERRIT_REFSPEC = git.getCommitRefSpec(env.GERRIT_CHANGE_NUMBER)
                    echo "env.LATEST_GERRIT_REFSPEC=${env.LATEST_GERRIT_REFSPEC}"

                    if (env.LATEST_GERRIT_REFSPEC != params.GERRIT_REFSPEC) {
                        echo "There is newer patchset then ${params.GERRIT_REFSPEC}, using this: ${env.LATEST_GERRIT_REFSPEC}"
                        // override with the latest refspec
                        env.GERRIT_REFSPEC = env.LATEST_GERRIT_REFSPEC
                    }
                }
            }
        }

        stage('Checkout LATEST_GERRIT_REFSPEC') {
            steps {
                script {
                    git.checkoutRefSpec("${env.GERRIT_REFSPEC}", "FETCH_HEAD", "adp-app-staging")
                }
            }
        }

        stage('Check for test jobs'){
            steps{
                script{
                    changedFiles = getGerritQueryPatchsetChangedFiles("${env.GERRIT_REFSPEC}")
                    changedFiles.each { file ->
                        print file
                        if ( file.startsWith("tests/")){
                                error "Test jobs shouldn't merge"
                        }
                    }
                }
            }
        }

        stage('Prepare') {
            steps {
                dir('adp-app-staging') {
                    checkoutGitSubmodules()
                }
            }
        }

        stage('Prepare Helm Chart') {
            steps {
                dir('adp-app-staging') {
                    // Generate integration helm chart
                    withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                     string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                     string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                     usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                        sh 'bob/bob prepare'
                    }
                }
            }
        }
        stage('Archive artifact.properties') {
            steps {
                // Archive artifact.properties so Spinnaker can read the parameters (env.GERRIT_REFSPEC)
                dir('adp-app-staging') {
                    script {
                        try {
                            sh 'echo "GERRIT_CHANGE_SUBJECT=' + "${GERRIT_CHANGE_SUBJECT}" + '" >> artifact.properties'
                            sh 'echo "GERRIT_CHANGE_OWNER_NAME=' + "${GERRIT_CHANGE_OWNER_NAME}" + '" >> artifact.properties'
                        } catch (err) {
                            println("Caught: " + err)
                        }
                    }
                    archiveArtifacts 'artifact.properties'
                }
            }
        }
    }
    post {
        failure {
            script {
                if (env.GERRIT_REFSPEC) {
                    env.GERRIT_MSG = "Build Failed ${BUILD_URL}: FAILURE"
                    sendMessageToGerrit(env.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }
        success {
            script {
                if (env.GERRIT_REFSPEC) {
                    env.GERRIT_MSG = "Build Successful ${BUILD_URL}: SUCCESS"
                    sendMessageToGerrit(env.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }
        cleanup {
            cleanWs()
        }
    }
}
