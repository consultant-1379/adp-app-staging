@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import hudson.Util;
import com.ericsson.eea4.ci.CommonUtils
import com.ericsson.eea4.ci.Notifications
import hudson.slaves.OfflineCause.UserCause


@Field def cmutils = new CommonUtils(this)
@Field def notif = new Notifications(this)

// vars
Integer maxNodesUnderCleanup
Integer minProdCiNodesOnline
def prodCiNodesOnline = []
def nodesUnderMaintenance = []
def cleanupNeeded = [:]
def cleanupNodes = []
def stages_to_run = [:]
boolean doCleanup = false

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

    // run every 4 hours
    triggers { cron('0 H/4 * * *') }

    parameters {
        string(name: 'DISK_USAGE_TRESHOLD', description: 'Cleanup nodes when disk usage percentage reached this value', defaultValue: '50')
        string(name: 'MAX_NODES_UNDER_CLEANUP', description: 'Maximum allowed number of build nodes under cleanup at a time', defaultValue: '2')
        string(name: 'MIN_PROD_CI_NODES_ONLINE', description: 'Minimum allowed number of online build nodes at a time', defaultValue: '3')
        string(name: 'WAIT_FOR_NODE_IDLE_TIMEOUT', description: 'Wait for node to become idle before timeout (hours)', defaultValue: '12')
        string(name: 'CLEANUP_NODES_WITH_LABEL', description: 'Execute cleanups only on nodes with this label. Change this when run on non-productci nodes!', defaultValue: 'productci')
        string(name: 'MAINTENANCE_LABEL', description: 'Special label applied to nodes under maintenance. Change this when run on non-productci nodes!', defaultValue: 'prodci-maintenance-docker-cleanup')
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

        stage('Run when run in Production Jenkins') {
            when {
                expression { env.MAIN_BRANCH == 'master' }
            }
            stages {

                stage('Check params') {
                    steps {
                        script {
                            echo "Running with the following params:"
                            echo "    DISK_USAGE_TRESHOLD: ${params.DISK_USAGE_TRESHOLD}"
                            echo "    MAX_NODES_UNDER_CLEANUP: ${params.MAX_NODES_UNDER_CLEANUP}"
                            echo "    MIN_PROD_CI_NODES_ONLINE: ${params.MIN_PROD_CI_NODES_ONLINE}"
                            echo "    WAIT_FOR_NODE_IDLE_TIMEOUT: ${params.WAIT_FOR_NODE_IDLE_TIMEOUT}"
                            echo "    CLEANUP_NODES_WITH_LABEL: ${params.CLEANUP_NODES_WITH_LABEL}"
                            echo "    MAINTENANCE_LABEL: ${params.CLEANUP_NODES_WITH_LABEL}"
                            echo "    NOTIFICATION_EMAIL: ${params.CLEANUP_NODES_WITH_LABEL}"

                            if (!params.CLEANUP_NODES_WITH_LABEL?.trim()) {
                                error "CLEANUP_NODES_WITH_LABEL cannot be empty!"
                            }
                            if (!params.MAINTENANCE_LABEL?.trim()) {
                                error "MAINTENANCE_LABEL cannot be empty!"
                            }
                            currentBuild.description = "Label: ${params.CLEANUP_NODES_WITH_LABEL}"
                        }
                    }
                }

                stage('Check nodes') {
                    steps {
                        catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                            script {
                                Integer prodCiNodesOnlineNr
                                minProdCiNodesOnline = params.MIN_PROD_CI_NODES_ONLINE as Integer
                                maxNodesUnderCleanup = params.MAX_NODES_UNDER_CLEANUP as Integer
                                Jenkins.get().computers
                                .each { n ->
                                    // check number of nodes already under cleanup
                                    if (n.node.labelString.contains(params.MAINTENANCE_LABEL)) {
                                        nodesUnderMaintenance.add(n.node.selfLabel.name)
                                    }
                                    // check nodes with prodCiLabel that are not offline
                                    if (n.node.labelString.contains(params.CLEANUP_NODES_WITH_LABEL)  && ! n.isOffline()) {
                                        prodCiNodesOnline.add(n.node.selfLabel.name)
                                    }
                                }

                                echo "Minimum allowed number of online build nodes with label \"${params.CLEANUP_NODES_WITH_LABEL}\": " + minProdCiNodesOnline
                                echo "Maximum allowed number of build nodes under maintenance with label \"${params.MAINTENANCE_LABEL}\": " + maxNodesUnderCleanup
                                echo "Online nodes with label ${params.CLEANUP_NODES_WITH_LABEL}: ${prodCiNodesOnline}"
                                echo "Nodes under maintenance with label \"${params.MAINTENANCE_LABEL}\": ${nodesUnderMaintenance}"

                                // if number of online nodes with prodCiLabel =< minProdCiNodesOnline number, log, notify & exit
                                prodCiNodesOnlineNr = prodCiNodesOnline.size()
                                if (prodCiNodesOnlineNr <= minProdCiNodesOnline) {
                                    def bodyMessage = "Docker cleanup encountered a problem: number of currently online Jenkins build nodes with label ${params.CLEANUP_NODES_WITH_LABEL} lesser than expected (${minProdCiNodesOnline}), check build nodes! \n${env.BUILD_URL})"
                                    notif.sendMail("Docker cleanup job for node ${params.NODE_NAME} failed ${env.BUILD_URL}", bodyMessage, params.NOTIFICATION_EMAIL)
                                    error "Number of currently online nodes with label \"${params.CLEANUP_NODES_WITH_LABEL}\" is lower or equal than the minimum requirement (${prodCiNodesOnlineNr}), EXIT."
                                }

                                // if number of nodes with label >= maxNodesUnderCleanup, log & exit
                                if (nodesUnderMaintenance.size() >= maxNodesUnderCleanup) {
                                    error "Number of nodes under maintenance already reached ${maxNodesUnderCleanup}, EXIT."
                                }

                                doCleanup = true
                            }
                        }
                    }
                }

                stage('Prioritize nodes based on disk usage') {
                    when {
                        expression { doCleanup }
                    }
                    steps {
                        catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                            script {
                                Float diskUsageTreshold = params.DISK_USAGE_TRESHOLD as Float
                                withCredentials([usernamePassword(credentialsId: 'hub-root-user', usernameVariable: 'HUB_ROOT_USER', passwordVariable: 'HUB_ROOT_PASSWD')]) {
                                    prodCiNodesOnline.each { n ->
                                        // get disk usage
                                        def diskUsage = cmutils.getDockerVolumesDiskUsageReport(n)
                                        echo """${n} docker volumes diskUsage:
    /var/lib/docker/volumes usage:   ${diskUsage[0]}%
    docker-pool (LV) data usage:     ${diskUsage[1]}%
    docker-pool (LV) meta usage:     ${diskUsage[2]}%"""
                                        // determine cleanup necessity by lvm data volume, as /var/lib/docker volume currently is not relevant:
                                        // it can fill up during common upgrade, but it also gets cleaned up directly afterwards
                                        // but this can change in the future - other volumes are logged just in case
                                        if (diskUsage[1] >= diskUsageTreshold) {
                                            cleanupNeeded[n] = diskUsage[1]
                                        }
                                    }
                                }

                                cleanupNeeded = getSorted(cleanupNeeded)
                                echo "${cleanupNeeded.size()} node(s) found over ${diskUsageTreshold}% disk usage: " + cleanupNeeded

                                // if no hosts over diskUsageTreshold, do nothing
                                if (!cleanupNeeded.size()) {
                                    doCleanup = false
                                    error "No nodes with disk usage over ${diskUsageTreshold}%, EXIT."
                                }

                                // get number of nodes that can be removed
                                Integer maxNrToBeRemoved
                                // remaining nr of paralel cleanups allowed
                                Integer freeCleanupSlots = maxNodesUnderCleanup - nodesUnderMaintenance.size()
                                // nr of nodes can be removed without going under minProdCiNodesOnline
                                Integer safeToRemove = prodCiNodesOnline.size() - minProdCiNodesOnline

                                if (safeToRemove < freeCleanupSlots) {
                                    maxNrToBeRemoved = safeToRemove
                                } else {
                                    maxNrToBeRemoved = freeCleanupSlots
                                }

                                // determine hosts to be removed for cleanup
                                def keys = cleanupNeeded.keySet()  as ArrayList
                                if (keys.size() >= maxNrToBeRemoved) {
                                    cleanupNodes = keys[0..<maxNrToBeRemoved]
                                } else {
                                    cleanupNodes = keys
                                }

                                echo "${cleanupNeeded.size()} node(s) need maintenance. Maximum ${maxNrToBeRemoved} node(s) can be removed for maintenance."
                                echo "Starting maintenance on ${cleanupNodes.size()} node(s) with highest disk usage:  " + cleanupNodes
                            }
                        }
                    }
                }

                stage('Start cleanup') {
                    when {
                        expression { doCleanup }
                    }

                    stages {
                        stage ("Generate cleanup jobs") {
                            steps {
                                script {
                                    def waitForNodeIdleTimeout = params.WAIT_FOR_NODE_IDLE_TIMEOUT as Integer
                                    // generate build jobs according on cleanupNodes
                                    cleanupNodes.each { n ->
                                        stages_to_run[n] = {
                                            stage("Cleanup ${n}") {
                                                build(job: "docker-cleanup-node",
                                                    propagate: true,
                                                    wait: true,
                                                    parameters: [
                                                        string(name: "NODE_NAME", value: n),
                                                        string(name: "WAIT_FOR_NODE_IDLE_TIMEOUT", value: params.WAIT_FOR_NODE_IDLE_TIMEOUT),
                                                        string(name: "MAINTENANCE_LABEL", value: params.MAINTENANCE_LABEL),
                                                        string(name: "NOTIFICATION_EMAIL", value: params.NOTIFICATION_EMAIL)
                                                    ]
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        stage('Start parallel cleanup jobs') {
                            steps {
                                catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                                    script {
                                        parallel stages_to_run
                                    }
                                }
                            }
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

@NonCPS
def getSorted(def unsortedMap) {
    unsortedMap.sort { -it.value }
}
