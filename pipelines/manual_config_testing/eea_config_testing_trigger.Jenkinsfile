@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import com.ericsson.eea4.ci.GlobalVars

@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def vars = new GlobalVars()

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
        string(name: 'CHART_NAME', description: 'Chart name e.g.: eric-ms-b', defaultValue: '')
        string(name: 'CHART_REPO', description: 'Chart repo e.g.: https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm', defaultValue: '')
        string(name: 'CHART_VERSION', description: 'Chart version e.g.: 1.0.0-1', defaultValue: '')
        string(name: 'GERRIT_REFSPEC',  description: 'Gerrit Refspec of the integration chart git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'META_GERRIT_REFSPEC', description: 'Gerrit Refspec of the Meta chart git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
        booleanParam(name: 'SKIP_TESTING_INSTALL', description: "Ability to skip install testing stage for certain commit", defaultValue: false)
        booleanParam(name: 'SKIP_TESTING_UPGRADE', description: "Ability to skip upgrade testing stage for certain commit", defaultValue: true)
        string(name: 'CLUSTER_NAME', description: "cluster resource name to execute install on")
        string(name: 'UPGRADE_CLUSTER_NAME', description: "cluster resource name to execute upgrade on")
        string(name: 'CUSTOM_CLUSTER_LABEL', description: 'CUSTOM_CLUSTER_LABEL is mandatory, if the SKIP_INSTALL_CLEANUP or SKIP_UPGRADE_CLEANUP is true', defaultValue: '')
        booleanParam(name: 'SKIP_INSTALL_CLEANUP', description: "Ability to skip skip the install cleanup pipeline.", defaultValue: false)
        booleanParam(name: 'SKIP_UPGRADE_CLEANUP', description: "Ability to skip upgrade cleanup.", defaultValue: false)
    }
    environment {
        GERRIT_GROUP = 'eea-manual-config-testing-executors'
        PIPELINE_NAME = 'eea-manual-config-testing'
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

        stage('Check parameters') {
            steps {
                script {
                    if (!params.GERRIT_REFSPEC && !params.META_GERRIT_REFSPEC) {
                        currentBuild.result = 'ABORTED'
                        error("GERRIT_REFSPEC or META_GERRIT_REFSPEC must be specified")
                    }
                }
            }
        }

        stage('Check cluster cleanup parameters') {
            when {
                expression { params.SKIP_INSTALL_CLEANUP || params.SKIP_UPGRADE_CLEANUP }
            }
            steps {
                script {
                    if (!params.CUSTOM_CLUSTER_LABEL && params.SKIP_INSTALL_CLEANUP) {
                        currentBuild.result = 'ABORTED'
                        error("CUSTOM_CLUSTER_LABEL is mandatory, if the SKIP_INSTALL_CLEANUP is true")
                    } else if (!params.CUSTOM_CLUSTER_LABEL && params.SKIP_UPGRADE_CLEANUP) {
                        currentBuild.result = 'ABORTED'
                        error("CUSTOM_CLUSTER_LABEL is mandatory, if the SKIP_UPGRADE_CLEANUP is true")
                    }
                }
            }
        }

        stage('Verify executor user') {
            steps {
                script {
                    println "user email:" + BUILD_USER_EMAIL
                    def groupmembers = gitadp.listGerritMembers(GERRIT_GROUP)
                    if (!groupmembers.contains(BUILD_USER_EMAIL)) {
                        error "Not authorized executor"
                    }
                }
            }
        }

        stage('Decide on cluster cleanup') {
            steps {
                script {
                    env.INSTALL_SKIP_CLEANUP = params.SKIP_INSTALL_CLEANUP
                    env.UPGRADE_SKIP_CLEANUP = params.SKIP_UPGRADE_CLEANUP
                    env.CLUSTER_LABEL = ''
                    env.UPGRADE_CLUSTER_LABEL = ''
                    if ( params.CLUSTER_NAME ) {
                        if ( !getLockableResourceDescription("${params.CLUSTER_NAME}").contains("Product CI")) {
                            echo "${params.CLUSTER_NAME} is not in the Product CI clusters pool. Automated cleanup will be skipped"
                            env.INSTALL_SKIP_CLEANUP = true
                        }
                    } else {
                        env.CLUSTER_LABEL = 'bob-ci'
                    }
                    if ( params.UPGRADE_CLUSTER_NAME ) {
                        if ( !getLockableResourceDescription("${params.UPGRADE_CLUSTER_NAME}").contains("Product CI")) {
                            echo "${params.UPGRADE_CLUSTER_NAME} is not in the Product CI clusters pool. Automated cleanup will be skipped"
                            env.UPGRADE_SKIP_CLEANUP = true
                        }
                    } else {
                        env.UPGRADE_CLUSTER_LABEL = 'bob-ci-upgrade-ready'
                    }
                }
            }
        }

        stage('Archive artifact.properties') {
            steps {
                sh '''
                cat > artifact.properties << EOF
CHART_NAME=${CHART_NAME}
CHART_REPO=${CHART_REPO}
CHART_VERSION=${CHART_VERSION}
GERRIT_REFSPEC=${GERRIT_REFSPEC}
META_GERRIT_REFSPEC=${META_GERRIT_REFSPEC}
PIPELINE_NAME=${PIPELINE_NAME}
SKIP_TESTING_INSTALL=${SKIP_TESTING_INSTALL}
SKIP_TESTING_UPGRADE=${SKIP_TESTING_UPGRADE}
CLUSTER_LABEL=${CLUSTER_LABEL}
UPGRADE_CLUSTER_LABEL=${UPGRADE_CLUSTER_LABEL}
CLUSTER_NAME=${CLUSTER_NAME}
UPGRADE_CLUSTER_NAME=${UPGRADE_CLUSTER_NAME}
INSTALL_SKIP_CLEANUP=${INSTALL_SKIP_CLEANUP}
UPGRADE_SKIP_CLEANUP=${UPGRADE_SKIP_CLEANUP}
CUSTOM_CLUSTER_LABEL=${CUSTOM_CLUSTER_LABEL}
EOF
'''
                // Archive artifact.properties so Spinnaker can read the parameters
                archiveArtifacts 'artifact.properties'
            }
        }
    }
    post {
        cleanup {
            cleanWs()
        }
    }
}