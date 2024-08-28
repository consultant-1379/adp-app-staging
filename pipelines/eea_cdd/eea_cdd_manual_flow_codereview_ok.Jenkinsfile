@Library('ci_shared_library_eea4') _

import groovy.transform.Field

import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.Artifactory

@Field def gitcdd = new GitScm(this, 'EEA/cdd')
@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')

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
    parameters {
        string(name: 'GERRIT_REFSPEC', description: 'Gerrit Refspec of the cdd git repo e.g.: refs/changes/82/13836482/2', defaultValue: '')
        string(name: 'GERRIT_CHANGE_ID', description: 'GERRIT_CHANGE_ID realted to the provided GERRIT_REFSPEC', defaultValue: '')
        string(name: 'GERRIT_CHANGE_SUBJECT', description: 'Parameter name for the commit subject (commit message 1st line)', defaultValue: '')
        string(name: 'GERRIT_CHANGE_OWNER_NAME', description: 'The name of the owner of the change', defaultValue: '')
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

        stage('Checkout - scripts') {
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
                    env.GERRIT_CHANGE_NUMBER = gitcdd.getCommitIdFromRefspec(params.GERRIT_REFSPEC)
                    echo "env.GERRIT_CHANGE_NUMBER=${env.GERRIT_CHANGE_NUMBER}"

                    env.LATEST_GERRIT_REFSPEC = gitcdd.getCommitRefSpec(env.GERRIT_CHANGE_NUMBER)
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
                    gitcdd.checkoutRefSpec("${env.GERRIT_REFSPEC}", "FETCH_HEAD", "cdd")
                    dir('cdd') {
                        env.COMMIT_ID = gitcdd.getCommitHashLong()
                        echo "env.COMMIT_ID=${env.COMMIT_ID}"
                    }
                }
            }
        }

        stage('Prepare') {
            steps {
                dir('cdd') {
                    checkoutGitSubmodules()
                }
            }
        }

        stage('Clean') {
            steps {
                dir('cdd') {
                    sh 'bob/bob -r bob-rulesets/ruleset2.0.yaml clean'
                }
            }
        }

        stage('Prepare Helm Chart') {
            steps {
                dir ('cdd') {
                    withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                     string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                     string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                     usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                        sh 'bob/bob -r bob-rulesets/ruleset2.0.yaml prepare-without-upload'
                    }
                }
            }
        }

        stage('Set properties by changed files') {
            steps {
                dir ('cdd') {
                    script {
                        def ccdTestLoopMap = ['jenkins/eea_software_ingestion':'INGESTION','jenkins/eea_software_preparation':'PREPARATION','jenkins/eea_software_upgrade':'UPGRADE','jenkins/eea_software_validation_and_verification':'VALIDATION','jenkins/eea_software_rollback':'ROLLBACK', 'product/source/pipeline_package/swdp-cdd/product/scripts/upgrade' : 'COMMON_UPGRADE'  ]
                        changedFiles = gitcdd.getGerritQueryPatchsetChangedFiles("${GERRIT_REFSPEC}")
                        String mapValue
                        def valueList = []
                        changedFiles.each { changedFile ->
                            print changedFile
                            mapValue =  ccdTestLoopMap.get(changedFile.substring(0,changedFile.lastIndexOf(".") ))
                            if ("$mapValue"!="null") {
                                sh "echo '$mapValue=true' >> artifact.properties"
                            }
                        }
                    }
                }
            }
        }

        stage('Check skip-testing comment exist') {
            steps {
                script {
                    env.SKIP_TESTING = gitcdd.getCommitComments("${env.GERRIT_CHANGE_ID}", "skip-testing").contains("skip-testing")
                }
            }
        }

        stage('Check which files changed to skip testing'){
            when {
                expression { !env.SKIP_TESTING.toBoolean() }
            }
            steps {
                dir ('cdd') {
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
                dir ('cdd') {
                    script {
                        sh "echo 'SKIP_TESTING=${env.SKIP_TESTING}' >> artifact.properties"
                        sh "echo 'GERRIT_CHANGE_SUBJECT=${env.GERRIT_CHANGE_SUBJECT}' >> artifact.properties"
                        sh "echo 'GERRIT_CHANGE_OWNER_NAME=${env.GERRIT_CHANGE_OWNER_NAME}' >> artifact.properties"
                        sh "echo 'GERRIT_REFSPEC=${env.GERRIT_REFSPEC}' >> artifact.properties"
                        archiveArtifacts artifacts: 'artifact.properties', allowEmptyArchive: true
                    }
                }
            }
        }
    }
    post {
        always {
            script {
                if ( params.GERRIT_REFSPEC ) {
                    env.GERRIT_MSG = "Build result ${BUILD_URL}: ${currentBuild.result}"
                    sendMessageToGerrit(env.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }
        cleanup {
            cleanWs()
        }
    }
}
