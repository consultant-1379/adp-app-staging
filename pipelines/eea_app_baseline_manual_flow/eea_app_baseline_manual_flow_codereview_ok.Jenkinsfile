@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.ClusterLockUtils
import groovy.transform.Field

@Field def gitcnint = new GitScm(this, "EEA/cnint")
@Field def gitadp = new GitScm(this, "EEA/adp-app-staging")
@Field def clusterLockUtils =  new ClusterLockUtils(this)

pipeline {
    agent {
        node {
            label 'productci'
        }
    }
    options {
        skipDefaultCheckout()
        buildDiscarder(logRotator(daysToKeepStr: '7', artifactDaysToKeepStr: "7"))
    }
    parameters {
        string(name: 'GERRIT_REFSPEC', description: 'Gerrit Refspec of the cnint git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'GERRIT_CHANGE_ID', description: 'GERRIT_CHANGE_ID realted to the provided GERRIT_REFSPEC', defaultValue: '')
        string(name: 'GERRIT_CHANGE_SUBJECT', description: 'GERRIT_CHANGE_SUBJECT realted to the provided GERRIT_REFSPEC', defaultValue: '')
        string(name: 'GERRIT_CHANGE_OWNER_NAME', description: 'GERRIT_CHANGE_OWNER_NAME realted to the provided GERRIT_REFSPEC', defaultValue: '')
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

         stage('Wait for baseline-install resource is free') {
            steps {
                script {
                    while ( clusterLockUtils.getResourceLabelStatus("baseline-publish") != "FREE" ) {
                        sleep(time: 5, unit: 'MINUTES' )
                    }
                }
            }
        }

        stage('Checkout - scripts'){
            steps {
                script {
                    gitadp.sparseCheckout("technicals/")
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
                    env.GERRIT_CHANGE_NUMBER = gitcnint.getCommitIdFromRefspec(env.GERRIT_REFSPEC)
                    echo "env.GERRIT_CHANGE_NUMBER=${env.GERRIT_CHANGE_NUMBER}"

                    env.LATEST_GERRIT_REFSPEC = gitcnint.getCommitRefSpec(env.GERRIT_CHANGE_NUMBER)
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
                    gitcnint.checkoutRefSpec("${env.GERRIT_REFSPEC}", "FETCH_HEAD", "cnint")
                }
            }
        }

        stage('Prepare') {
            steps {
                dir('cnint') {
                    checkoutGitSubmodules()
                }
            }
        }

        stage('Functional test - init') {
            steps {
                script {
                    dir('cnint') {
                        withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                            usernamePassword(credentialsId: 'ECEAART_SEROGIC_API_KEY', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO')
                        ]){
                            sh './bob/bob init'
                        }
                    }
                }
            }
        }

        stage('Prepare Helm Chart') {
            steps {
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

        // This stage is cheking "skip-testing" comment and if it exist, write "SKIP_TESTING=true" parameter to artifact.properties
        /*
            The logic is as follows:
            When the reviewer realizes that a commit doesn't need to be tested, he puts a +1 in Gerrit and adds a "skip-testing" comment.
            The reviewer can be anyone, but if he is not in the "cnint-manual-commit-reviewers" group, the check will give an error and the staging will not run.
            At this point, it checks for the right comment.
        */
        stage('Check skip-testing comment exist') {
            steps {
                script {
                    echo "Check Gerrit's comments"
                    env.SKIP_TESTING = gitcnint.getCommitComments("${params.GERRIT_CHANGE_ID}", "skip-testing").contains("skip-testing")
                }
            }
        }

        stage('Check which files changed to skip testing'){
            // If the variable env.SKIP_TESTING contains a value of "true", this check is skipped.
            when {
                expression { !env.SKIP_TESTING }
            }
            steps {
                dir('cnint') {
                    script {
                        catchError(stageResult: 'FAILURE', buildResult: currentBuild.result) {
                            try {
                                if (env.GERRIT_REFSPEC) {
                                    env.SKIP_TESTING = checkIfCommitContainsOnlySkippableFiles(env.GERRIT_REFSPEC, [".md"])
                                }
                            }
                            catch (err) {
                                error "Caught: ${err}"
                            }
                        }
                    }
                }
            }
        }

        stage('Archive artifact.properties') {
            steps {
                dir('cnint') {
                    // Archive artifact.properties so Spinnaker can read the parameters (env.GERRIT_REFSPEC)
                    script {
                        try {
                            sh "echo 'SKIP_TESTING=${env.SKIP_TESTING}' >> artifact.properties"
                            sh 'echo "GERRIT_CHANGE_SUBJECT=' + "${params.GERRIT_CHANGE_SUBJECT}" + '" >> artifact.properties'
                            sh 'echo "GERRIT_CHANGE_OWNER_NAME=' + "${params.GERRIT_CHANGE_OWNER_NAME}" + '" >> artifact.properties'
                            sh 'echo "GERRIT_REFSPEC=' + "${params.GERRIT_REFSPEC}" + '" >> artifact.properties'
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
