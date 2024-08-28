@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import com.ericsson.eea4.ci.Artifactory
import com.ericsson.eea4.ci.ClusterLockUtils

@Field def git = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitdoc = new GitScm(this, 'EEA/eea4_documentation')
@Field def arm = new Artifactory(this, "https://arm.seli.gic.ericsson.se/",  "API_TOKEN_EEA")

def resource_lock

pipeline {
    agent {
        node {
            label 'productci'
        }
    }

    options {
        buildDiscarder(logRotator(daysToKeepStr: "14", artifactDaysToKeepStr: "7"))
        skipDefaultCheckout()
    }

    parameters {
        string(name: 'CHART_NAME', description: 'Chart name e.g.:eric-eea-ci-code-helm-chart ', defaultValue: 'eric-eea-ci-code-helm-chart')
        string(name: 'CHART_REPO', description: 'Chart repo e.g.: https://arm.seli.gic.ericsson.se/artifactory/proj-adp-helm', defaultValue: '')
        string(name: 'CHART_VERSION', description: 'Chart version e.g.: 1.0.0-1', defaultValue: '')
        string(name: 'SPINNAKER_ID', description: 'Execution id of the triggering Spinnaker pipeline', defaultValue: '')
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

        stage('Set description') {
            steps {
                script {
                    currentBuild.description = '<a href="https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/details/' + params.SPINNAKER_ID + '">Spinnaker URL: ' + params.SPINNAKER_ID + '</a>'
                }
            }
        }


        stage('Checkout and lock - eea4_documentation') {
            options {
                lock resource: null, label: "doc-build", quantity: 1, variable: 'resource'
            }

            steps {
                script {
                    lock('resource-relabel') {
                        resource_lock = new ClusterLockUtils(this)
                        resource_lock.setReserved('publish-ongoing', env.resource)
                        def note = "eea-application-staging - " + params.SPINNAKER_ID
                        echo 'Note: ' + note
                        resource_lock.setNoteForResource( env.resource, note )
                        gitdoc.checkout('master', 'eea4_documentation')
                    }
                }
            }
        }

        stage('add version info - eea4_documentation') {
            steps {
                dir('eea4_documentation') {
                    sh """
                        echo "version: ${env.CHART_VERSION}" > eea_product_version.txt

                    """
                    script {
                        gitdoc.createPatchset("${env.WORKSPACE}/eea4_documentation/","${params.CHART_VERSION} in eea-application-staging")
                        env.GIT_ID = gitdoc.getCommitHashLong()
                        echo "env.GIT_ID: ${env.GIT_ID}"
                    }
                }
            }
        }

        stage('Prepare') {
            steps {
                dir('eea4_documentation') {
                    script {
                        checkoutGitSubmodules()
                    }
                }
            }
        }


        stage('Build and generate DXP packages') {
            steps {
                dir('eea4_documentation') {
                    script {
                        withCredentials([string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN'),
                            usernamePassword(credentialsId: 'eceadcm', usernameVariable: 'DITACMSAPI_USER', passwordVariable: 'DITACMSAPI_PASSWORD')]){
                            env.HELM_CHART_VERSION = params.CHART_VERSION
                            env.HELM_CHART_URL = params.CHART_REPO
                            env.DOC_PATH = "${WORKSPACE}/eea4_documentation"
                            env.HELM_REPO = "${params.CHART_REPO}".tokenize('/').last()
                            sh './bob/bob -r bob-rulesets/docreviewOK.yaml prepare-dependencies'
                            sh './bob/bob -r bob-rulesets/docreviewOK.yaml generate-dxp-docs'
                        }
                    }
                }
            }
        }

        stage('Archieve build folder') {
            steps {
                dir('eea4_documentation') {
                    script {
                        sh "tar -czf doc_build_\$(date '+%m-%d-%Y_%H-%M-%S').tar.gz doc_build/"
                        archiveArtifacts "doc_build_*.tar.gz"
                    }
                }
            }
        }

        stage('Archive artifact.properties') {
            steps {
                script {
                    def logContent = "DOC_BUILD_NUMBER=" + env.BUILD_NUMBER + "\n" +
                                     "DOC_COMMIT_ID=" + env.GIT_ID
                    writeFile file: "artifact.properties", text: logContent
                    currentBuild.description += "<br>VERSION:" + params.CHART_VERSION
                    currentBuild.description += "<br>DOC_COMMIT_ID:" + env.GIT_ID
                }
                archiveArtifacts 'artifact.properties'
            }
        }
    }

    post {
        failure {
            script {
                lock('resource-relabel') {
                    def manager = org.jenkins.plugins.lockableresources.LockableResourcesManager.get()
                    def resources =  manager.getResourcesWithLabel('doc-build', null)
                    def note = "eea-application-staging - " + env.BUILD_NUMBER
                    resources.each {
                        if (it.getNote() == note) {
                            echo "Reserved resource found ${it}"
                            echo "isReserved: ${it.isReserved()}"
                            it.setNote('')
                        }
                    }
                    manager.recycle(resources)
                }
            }
        }
        cleanup {
            cleanWs()
        }
    }
}
