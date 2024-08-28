@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.Artifactory
import groovy.transform.Field

@Field def gitadpapp = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitdoc = new GitScm(this, 'EEA/eea4_documentation')
@Field def arm = new Artifactory(this, "https://arm.seli.gic.ericsson.se/",  "API_TOKEN_EEA")


pipeline {
    agent {
        node {
            label 'productci'
        }
    }

    options {
        buildDiscarder(logRotator(daysToKeepStr: '7', artifactDaysToKeepStr: '3'))
    }

    parameters {
        string(name: 'BUILD_NUMBER',  description: 'The build number of the job previously built the documentation', defaultValue: '')
        choice(name: 'DOC_BUILD_JOBNAME',  choices: ['eea-application-staging-documentation-build', 'docreviewOK-job'], description: 'The name of the job previously built the documentation')
        string(name: 'DOC_COMMIT_ID',  description: 'Commit id of the documentation repo change', defaultValue: '')
        string(name: 'DOCREPO_URL',  description: 'The URL of the gerrit repo for EEA/eea4_documentation', defaultValue: 'https://${GERRIT_HOST}/EEA/eea4_documentation.git')
        booleanParam(name: 'MANUAL_RECOVER_AFTER_FAILED_PUBLISH', description: 'Just retry the failed publish operation of document helm chart and documentation', defaultValue: false)
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

        stage('Checkout - adp-app-staging') {
            steps {
                script {
                    gitadpapp.checkout(env.MAIN_BRANCH,'adp-app-staging')
                }
            }
        }

        stage('Checkout - eea4_documentation master') {
            when {
                expression { ! params.MANUAL_RECOVER_AFTER_FAILED_PUBLISH }
            }
            steps {
                script {
                    gitdoc.checkout(env.MAIN_BRANCH,'eea4_documentation')
                }
            }
        }

        stage('Checkout - eea4_documentation upto commit id') {
            when {
                expression { params.MANUAL_RECOVER_AFTER_FAILED_PUBLISH }
            }
            steps {
                dir ('eea4_documentation') {
                    script {
                        def refspec = gitdoc.getCommitRefSpec(params.DOC_COMMIT_ID)
                        gitdoc.checkoutRefSpec(refspec)
                    }
                }
            }
        }

        stage('Prepare - eea4_documentation') {
            steps {
                dir ('eea4_documentation') {
                    script {
                        checkoutGitSubmodules()
                    }
                }
            }
        }

        stage('Copy artifact from docreviewOK or eea-application-staging-documentation-build job') {
            steps {
                dir ('eea4_documentation') {
                    script {
                        step ([$class: 'CopyArtifact',
                            projectName: params.DOC_BUILD_JOBNAME,
                            selector: specific(params.BUILD_NUMBER),
                            filter: 'doc_build_*.tar.gz',
                            target: 'doc_publish']);
                    }
                }
            }
        }

        stage('Extract artifacts') {
            steps {
                dir('eea4_documentation/doc_publish') {
                    script {
                        sh (
                            script: '''
                            for file in $(tar tf doc_build_*.tar.gz | egrep -i 'zip$'); do stripnumber=$(echo $file | awk -F"/" '{print NF-1}'); tar xf doc_build_*.tar.gz $file --strip-components=$stripnumber; done
                            '''
                        )
                    }
                }
            }
        }

        stage('Generate Helm Chart version') {
            steps {
                dir ('eea4_documentation') {
                    withCredentials([
                                usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD'),
                                string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                        sh 'bob/bob -r bob-rulesets/documentation_publish.yaml generate-version'
                        script {
                            env.DOC_VERSION = readFile(".bob/var.version")
                        }
                    }
                }
            }
        }

        stage('Publish Helm Chart') {
            steps {
                dir ('eea4_documentation') {
                    script {
                        withCredentials([
                                        usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                        usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD'),
                                        string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                            env.HELM_CHART_PATH = "${WORKSPACE}/eea4_documentation"
                            sh 'bob/bob -r bob-rulesets/documentation_publish.yaml publish-helm-chart'
                        }
                    }
                }
            }
        }

        stage('Create Git Tag') {
            steps {
                dir ('eea4_documentation') {
                    script {
                        sh(
                            script: "ssh -o StrictHostKeyChecking=no -p ${GERRIT_PORT} ${GERRIT_HOST} gerrit query --current-patch-set ${params.DOC_COMMIT_ID} --format json  > gerrit_result"
                        )
                        def filePath = readFile "./gerrit_result"
                        def lines = filePath.readLines()
                        def data = readJSON text: lines[0]
                        echo "commit_id: ${data.currentPatchSet.revision}"
                        env.COMMIT_ID = data.currentPatchSet.revision
                        env.GIT_REPO_URL = "${env.DOCREPO_URL}"
                        echo "git_repo_url: ${env.GIT_REPO_URL}" //Debug
                    }
                    withCredentials([usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]){
                        // Create git tag 'v<version>'
                        sh './bob/bob -r bob-rulesets/documentation_publish.yaml create-git-tag'
                    }
                }
            }
        }

        stage('Publish documentation') {
            steps {
                dir ('eea4_documentation') {
                    script {
                        withCredentials([string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]){
                            sh './bob/bob -r bob-rulesets/documentation_publish.yaml publish-docs'
                        }
                    }
                }
            }
        }

        stage('Archive artifact.properties') {
            steps {
                dir ('eea4_documentation') {
                    sh './bob/bob -r bob-rulesets/documentation_publish.yaml generate-output-parameters'
                    sh "echo 'DOC_VERSION=${env.DOC_VERSION}' >> artifact.properties"
                    archiveArtifacts artifacts:'artifact.properties', allowEmptyArchive: true
                }
            }
        }
    }

    post {
        failure {
            script {
                if (env.GERRIT_REFSPEC) {
                    try {
                        sh '${WORKSPACE}/adp-app-staging/technicals/shellscripts/gerrit_message.sh ${GERRIT_REFSPEC} "Build Failed ${BUILD_URL}"'
                    }
                    catch (err) {
                        echo "Caught: ${err}"
                    }
                }
            }
        }
        cleanup {
            cleanWs()
        }
    }
}
