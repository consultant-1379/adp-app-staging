@Library('ci_shared_library_eea4') _

import groovy.transform.Field
import com.ericsson.eea4.ci.Notifications
import com.ericsson.eea4.ci.CiDashboard
import com.ericsson.eea4.ci.ClusterLockUtils
import com.ericsson.eea4.ci.GlobalVars

@Field def notif = new Notifications(this)
@Field def dashboard = new CiDashboard(this)
@Field def clusterLockUtils =  new ClusterLockUtils(this)
@Field def vars = new GlobalVars()

@Field def vars_ProdCI_Clusters = GlobalVars.Clusters.values().findAll{ it.owner.contains('product_ci') }.collect { it.resource }.sort()

pipeline{
    options {
        buildDiscarder(logRotator(daysToKeepStr: "30"))
    }
    agent {
        node {
            label "productci"
        }
    }
    parameters {
        string(name: 'DESIRED_CLUSTER_LABEL', description: 'Desired cluster label. Must be provided to run the pipeline.')
        string(name: 'CLUSTER_NAME', description: 'Cluster name to change. Must be provided to run the pipeline.')
        string(name: 'SPINNAKER_TRIGGER_URL', description: 'Spinnaker pipeline triggering url', defaultValue: '')
        string(name: 'SPINNAKER_ID', description: "The spinnaker execution's id", defaultValue: '')
        string(name: 'PIPELINE_NAME', description: "The spinnaker pipeline name", defaultValue: '')
        string(name: 'DESCRIPTION', description: "Description in payload for dashboard api", defaultValue: 'SUCCESS')
        booleanParam(name: 'RESOURCE_RECYCLE', description: 'Execute resource recycle if parameter value is true e.g.: true (Do not use this from inside the lock step!!!)', defaultValue: true)
        booleanParam(name: 'IGNORE_LOCK', description: 'Relable even if the cluster is Locked.  Only use if it is justified!!!', defaultValue: false)
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
        stage('Params check') {
            steps {
                script {
                    if (!params.DESIRED_CLUSTER_LABEL || !params.CLUSTER_NAME) {
                        currentBuild.result = 'ABORTED'
                        error("DESIRED_CLUSTER_LABEL AND CLUSTER_NAME must be specified")
                    }
                }
            }
        }
        stage('Resource locking - label change') {
            stages {
                stage('Lock') {
                    options {
                        lock resource: null, label: "resource-relabel", quantity: 1, variable: 'system'
                    }
                    stages {
                        stage('Label change') {
                            steps {
                                script {
                                    echo(checkForLog())
                                    try {
                                        currentBuild.description = "Cluster: ${params.CLUSTER_NAME}"

                                        def oldLabel = getLockableResourceLabels("${params.CLUSTER_NAME}")
                                        currentBuild.description += "<br>Old label: ${oldLabel}"
                                        currentBuild.description += "<br>New label: ${params.DESIRED_CLUSTER_LABEL}"

                                        echo "Changing label for lockable resource: ${params.CLUSTER_NAME} ...\n - old label: ${oldLabel}\n - new label: ${params.DESIRED_CLUSTER_LABEL}"
                                        setLockableResourceLabels("${params.CLUSTER_NAME}", "${params.DESIRED_CLUSTER_LABEL}")
                                        if (params.DESCRIPTION != 'SUCCESS') {
                                            clusterLockUtils.setLockableResourceNote(params.CLUSTER_NAME, params.DESCRIPTION)
                                        } else {
                                            clusterLockUtils.setLockableResourceNote(params.CLUSTER_NAME, "")
                                        }
                                    }
                                    catch (err) {
                                        echo "Caught: ${err}"
                                        notif.sendMail("${env.JOB_NAME} (${env.BUILD_NUMBER}) Label change failed","${env.BUILD_URL} label change failed to finish on cluster ${params.CLUSTER_NAME}","2b661627.ericsson.onmicrosoft.com@emea.teams.ms")
                                    }
                                }
                            }
                        }
                        stage('Reset Lockable Resource') {
                            when {
                                expression { params.RESOURCE_RECYCLE == true }
                            }
                            steps {
                                resetLockableResource("${params.CLUSTER_NAME}", true, true)
                            }
                        }
                    }
                }

                stage('Prepare a json payload structure and send it to CI Dashboard') {
                    when {
                        expression {
                            params.CLUSTER_NAME in vars_ProdCI_Clusters
                        }
                    }
                    steps {
                        script {
                            try {
                                dashboard.sendLockableResourceLabelChangeEvents(params.CLUSTER_NAME, params.DESIRED_CLUSTER_LABEL, params.DESCRIPTION)
                            } catch (err) {
                                echo "Caught: ${err}"
                            }
                        }
                    }
                }
            }
        }
    }
}

def checkForLog() {
    def resourceStatus = clusterLockUtils.getResourceLabelStatus(params.CLUSTER_NAME)
    def upstreamCause = currentBuild.rawBuild.getCause(hudson.model.Cause$UpstreamCause)
    if (resourceStatus == "FREE"){
        return("[INFO] Cluster is FREE")
    }
    if (upstreamCause && upstreamCause?.upstreamProject != env.JOB_NAME) {
        return("[INFO] Started by " + upstreamCause.upstreamProject + " # " + upstreamCause.upstreamBuild)
    }
    if (params.SPINNAKER_TRIGGER_URL){
        return("[INFO] Started by " + params.SPINNAKER_TRIGGER_URL)
    }
    if (!params.RESOURCE_RECYCLE){
        return("[INFO] Relable on " + params.CLUSTER_NAME + " was started MANUALLY but RESOURCE_RECYCLE was not set!")
    }
    if (params.IGNORE_LOCK){
        return("[WARNING] Relable on " + params.CLUSTER_NAME + " was started MANUALLY but IGNORE_LOCK was set!")
    }
    error("[ERROR] Relable on " + params.CLUSTER_NAME + " was started MANUALLY, but cluster already locked!")
}