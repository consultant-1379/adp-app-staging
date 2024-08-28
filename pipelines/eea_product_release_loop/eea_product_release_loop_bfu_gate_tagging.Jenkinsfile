@Library('ci_shared_library_eea4') _

import groovy.transform.Field
import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.GlobalVars
import com.ericsson.eea4.ci.ClusterLockUtils

@Field def vars = new GlobalVars()
@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def git_shared_lib = new GitScm(this, 'EEA/ci_shared_libraries')

pipeline {
    options {
        buildDiscarder(logRotator(daysToKeepStr: '14', artifactDaysToKeepStr: '7'))
        skipDefaultCheckout()
        disableConcurrentBuilds()
    }
    agent {
        node {
            label 'productci'
        }
    }

    parameters {
        string(name: 'NEW_BFU_GATE', description: 'Git tag of the new BFU gate e.g: eea4_4.4.0_pra', defaultValue: '')
        string(name: 'GIT_TAG_STRING', description: 'The commit message for the latest_release and latest_BFU_gate Git tags. E.g: EEA 4.4.0 PRA release', defaultValue: 'PRA release')
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

        stage('Checkout'){
            steps {
                script {
                    gitcnint.checkout('master', 'cnint')
                    dir('cnint') {
                        sh "git status"
                    }
                }
            }
        }

        stage('Check and recreate latest bfu gate git tag') {
            steps {
                dir('cnint') {
                    script {
                        git_shared_lib.createOrMoveRemoteGitTag('latest_BFU_gate', "${env.GIT_TAG_STRING}", "${params.NEW_BFU_GATE}")
                    }
                }
            }
        }

        stage('Check and recreate latest release git tag') {
            steps {
                dir('cnint') {
                    script {
                        git_shared_lib.createOrMoveRemoteGitTag('latest_release', "${env.GIT_TAG_STRING}", "${params.NEW_BFU_GATE}")
                    }
                }
            }
        }

        stage('Cleanup pre-installed clusters'){
            steps {
                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                    script {
                        echo "Check if there is any available free clusters with label: ${vars.resourceLabelUpgrade}"
                        def lockableResourceInstance = new ClusterLockUtils(this)
                        readyForUpgradeClusters = lockableResourceInstance.getFreeClusterCount(vars.resourceLabelUpgrade)
                        echo "Pre-installed clusters: ${readyForUpgradeClusters}"
                        for (cluster in readyForUpgradeClusters) {
                            try {
                                echo "Execute cluster-cleanup job ... \n - cluster: ${cluster}"
                                build job: "cluster-cleanup", parameters: [
                                    booleanParam(name: 'DRY_RUN', value: false),
                                    stringParam(name: "CLUSTER_NAME", value: cluster)
                                    ], wait: false, waitForStart: true
                            } catch (err) {
                                echo "Caught: ${err}"
                                error "cluster-cleanup FAILED"
                            }
                        }
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
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
