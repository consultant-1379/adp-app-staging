@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import hudson.Util;
import com.ericsson.eea4.ci.CommonUtils
import com.ericsson.eea4.ci.Notifications
import hudson.slaves.OfflineCause.UserCause


@Field def cmutils = new CommonUtils(this)
@Field def notif = new Notifications(this)

def nodeLabel = "productci"
def oldNodeLabel = ""
def buildNode
def bodyMessage = ""
Integer waitForNodeIdleTimeout

pipeline {
    agent {
        node {
            label 'master'
        }
    }

    options {
        skipDefaultCheckout()
        buildDiscarder(logRotator(daysToKeepStr: "7"))
    }

    parameters {
        string(name: 'NODE_NAME', description: 'Name of the Jenkins build node to be cleaned up')
        string(name: 'WAIT_FOR_NODE_IDLE_TIMEOUT', description: 'Wait for node to become idle before timeout (hours)', defaultValue: '12')
        string(name: 'MAINTENANCE_LABEL', description: 'This special label is set on hosts during docker cleanup maintenance. Change this when run on non-productci nodes!', defaultValue: 'prodci-maintenance-docker-cleanup')
        string(name: 'EMERGENCY_DISK_FULL_TRESHOLD', description: 'If any docker volume is above this percentage, don\'t move host back to pool if timeout reached and send notificaton.', defaultValue: '90')
        string(name: 'NOTIFICATION_EMAIL', description: 'E-mail address for notifications. Change this when run on non-productci nodes!', defaultValue: 'PDLEEA4PRO@pdl.internal.ericsson.com')
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

        stage("Prepare") {
            steps {
                script {
                    waitForNodeIdleTimeout = params.WAIT_FOR_NODE_IDLE_TIMEOUT as Integer
                    echo "Running with the following params:"
                    echo "    NODE_NAME: ${params.NODE_NAME}"
                    echo "    WAIT_FOR_NODE_IDLE_TIMEOUT: ${params.WAIT_FOR_NODE_IDLE_TIMEOUT}"
                    echo "    MAINTENANCE_LABEL: ${params.MAINTENANCE_LABEL}"
                    echo "    EMERGENCY_DISK_FULL_TRESHOLD: ${params.EMERGENCY_DISK_FULL_TRESHOLD}"
                    echo "    NOTIFICATION_EMAIL: ${params.NOTIFICATION_EMAIL}"

                    if (!params.NODE_NAME?.trim()) {
                        error "NODE_NAME cannot be empty!"
                    }
                }
            }
        }

        stage("Mark node offline") {
            steps {
                timeout(time: waitForNodeIdleTimeout, unit: 'HOURS') {
                    script {
                        def emergencyDiskFullTreshold = params.EMERGENCY_DISK_FULL_TRESHOLD as Float
                        try {
                            currentBuild.description = "${params.NODE_NAME}"
                            buildNode = Jenkins.get().getComputer(params.NODE_NAME)
                            // set node offline
                            echo "Mark node ${params.NODE_NAME} temporary offline"
                            buildNode.setTemporarilyOffline(true, new UserCause(User.current(), "Maintenance - scheduled automatic docker cleanup"))

                            // wait with relabel until node is idle - this way only productci and manually set labels will to be reapplied, no junk labels
                            echo "Waiting for host to finish running executions. Wait timeout: ${waitForNodeIdleTimeout} hours."
                            while (! buildNode.isIdle()) {
                                echo "node ${params.NODE_NAME} is busy - " + buildNode.countBusy() + " execution(s) running"
                                sleep(time:4, unit:"MINUTES")
                            }
                            echo "Node  ${params.NODE_NAME} is idle, ready for cleanup."
                        } catch (err) {
                            // get disk usage info
                            echo "Checking if disk usage over ${emergencyDiskFullTreshold}% on any volumes..."
                            def diskUsage = cmutils.getDockerVolumesDiskUsageReport(params.NODE_NAME)
                                        echo """${params.NODE_NAME} docker volumes diskUsage:
    /var/lib/docker/volumes usage:   ${diskUsage[0]}%
    docker-pool (LV) data usage:     ${diskUsage[1]}%
    docker-pool (LV) meta usage:     ${diskUsage[2]}%"""

                            // if any docker volume over 90%, don't put back to pool, but send notification
                            if (diskUsage.any{vol -> vol >= emergencyDiskFullTreshold}) {
                                def msg = "Disk usage over ${emergencyDiskFullTreshold}% on node ${params.NODE_NAME}, check and cleanup manually!\n"
                                bodyMessage += msg
                                error "${msg}"
                            } else {
                                // if timeout exception is reached, move node back to online
                                buildNode.setTemporarilyOffline(false, null)
                                buildNode.waitUntilOnline()
                                def msg = "TIMEOUT waiting for node ${params.NODE_NAME} exceeded, host moved back to online. Please check host for possibly stuck jobs!\n"
                                bodyMessage += msg
                                error "${msg} Details:\n${err}"
                            }
                        }
                    }
                }
            }
        }

        stage("Start docker cleanup on Jenkins node") {
            steps {
                script {
                    def old_label = buildNode.node.labelString
                    echo "Current node label(s): ${old_label}"
                    try {
                        buildNode.node.setLabelString(params.MAINTENANCE_LABEL)
                        echo "Label set to ${params.MAINTENANCE_LABEL}"
                        echo "Starting cleanup..."
                        cmutils.cleanupDocker(params.NODE_NAME)
                        echo "Finished cleanup."
                    } catch (err) {
                        echo "Caught ${err}"
                    } finally {
                        echo "Marking node ${params.NODE_NAME} online"
                        buildNode.node.setLabelString(old_label)
                        buildNode.setTemporarilyOffline(false, null)
                        buildNode.waitUntilOnline()
                        echo "Node ${params.NODE_NAME} is back online."
                    }
                }
            }
        }
    }
    post {
        failure {
            script {
                echo "FAILURE"
                bodyMessage += "Docker cleanup job for Jenkis build node ${params.NODE_NAME} ran into an error and failed, needs check!\n${env.BUILD_URL})"
                notif.sendMail("Docker cleanup job for node ${params.NODE_NAME} failed ${env.BUILD_URL}", bodyMessage, params.NOTIFICATION_EMAIL)
            }
        }
        cleanup {
            cleanWs()
        }
    }
}