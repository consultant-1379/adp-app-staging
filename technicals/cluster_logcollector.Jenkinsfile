@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.ClusterLogUtils
import com.ericsson.eea4.ci.Notifications
import com.ericsson.eea4.ci.CommonUtils
import com.ericsson.eea4.ci.GlobalVars
import com.ericsson.eea4.ci.CiDashboard
import com.ericsson.eea4.ci.ClusterLockUtils
import groovy.transform.Field
import com.ericsson.eea4.ci.ClusterInfo


@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def clusterLogUtilsInstance = new ClusterLogUtils(this)
@Field def notif = new Notifications(this)
@Field def cmutils = new CommonUtils(this)
@Field def vars = new GlobalVars()
@Field def dashboard = new CiDashboard(this)
@Field def clusterLockUtils = new ClusterLockUtils(this)
@Field def clusterInfo = new ClusterInfo(this)


pipeline {
    options {
        buildDiscarder(logRotator(daysToKeepStr: '7', artifactDaysToKeepStr: '3'))
        skipDefaultCheckout()
    }
    agent {
        node {
            label 'productci'
        }
    }
    parameters {
        booleanParam(name: 'DRY_RUN', description: 'Dry run', defaultValue: false)
        string(name: 'SERVICE_NAME', description: "Name of service e.g.: eric-ms-b", defaultValue: "")
        string(name: 'CLUSTER_NAME', description: "Logcollector resource name to execute on.")
        string(name: 'DESIRED_CLUSTER_LABEL', description: "The desired new resource label after successful run", defaultValue: 'cleanup-job')
        string(name: 'GERRIT_REFSPEC', description: 'Gerrit Refspec of the integration chart git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
        booleanParam(name: 'PUBLISH_LOGS_TO_JOB', description: 'Execute publishLogsToJob if parameter value is true e.g.: true', defaultValue: true)
        booleanParam(name: 'PUBLISH_LOGS_TO_ARM', description: 'Execute publishLogsToArm if parameter value is true e.g.: true', defaultValue: true)
        booleanParam(name: 'CLUSTER_CLEANUP', description: 'Execute cluster-cleanup if parameter value is true e.g.: true', defaultValue: true)
        string(name: 'AFTER_CLEANUP_DESIRED_CLUSTER_LABEL', description: "The desired new resource label after successful Cluster cleanup run", defaultValue: "${vars.resourceLabelCommon}")
        string(name: 'LAST_LABEL_SET', description: 'The last cluster lock label set by the automation. Leave empty for manual start', defaultValue: '')
        string(name: 'SPINNAKER_TRIGGER_URL', description: 'Spinnaker pipeline triggering url', defaultValue: '')
        string(name: 'SPINNAKER_ID', description: "The spinnaker execution's id", defaultValue: '')
        string(name: 'PIPELINE_NAME', description: "The spinnaker pipeline name", defaultValue: '')
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
                    if (!params.CLUSTER_NAME) {
                        currentBuild.result = 'ABORTED'
                        error("CLUSTER_NAME must be specified")
                    }

                    // init vars
                    LOG_FOLDER = ""
                    LOG_LINK = ""
                    JOB_LINK = ""
                }
            }
        }

        stage('Checkout') {
            steps {
                script {
                    /*
                        GERRIT_REFSPEC param was added to checkout new docker images from exact cnint commit to check
                        if they work properly, also this param is passed to downstream cluster_cleanap job for the same
                        purposes
                    */
                    if ( params.GERRIT_REFSPEC != '' ) {
                        gitcnint.checkoutRefSpec("${GERRIT_REFSPEC}", "FETCH_HEAD", "")
                    }else {
                        gitcnint.checkout("master", "")
                    }
                }
            }
        }

        stage('Bob Prepare') {
            steps {
                script {
                    checkoutGitSubmodules()
                }
            }
        }

        stage('Bob Init') {
            steps {
                script {
                    withCredentials([
                        usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                        usernamePassword(credentialsId: 'ECEAART_SEROGIC_API_KEY', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
                    ]) {
                        sh './bob/bob init'
                    }
                }
            }
        }

        stage('Resource locking - logcollector') {
            stages {
                stage('Wait for lock') {
                    steps {
                        script {
                            sendLockEventToDashboard (transition: "wait-for-lock")
                        }
                    }
                }
                stage('Lock') {
                    options {
                        lock resource: "${params.CLUSTER_NAME}", quantity: 1, variable: 'system'
                    }
                    stages {
                        stage('Log lock') {
                            steps {
                                script {
                                    // To use cluster name in POST stages
                                    env.CLUSTER = env.system
                                    echo "Locked cluster: ${env.CLUSTER}"
                                    currentBuild.description = currentBuild.description ?: ''
                                    currentBuild.description += "Locked cluster: ${env.CLUSTER}"
                                    env.LASTLABEL = params.LAST_LABEL_SET
                                    sendLockEventToDashboard (transition : "lock", cluster: env.CLUSTER)
                                }
                            }
                        }

                        stage('Get lockable resource note') {
                            steps {
                                script {
                                    LOG_FOLDER = getLockableResourceNote(env.CLUSTER)
                                    if (!LOG_FOLDER) {
                                        echo "Cannot find note for lockable resource: ${env.CLUSTER} -> using env.JOB_NAME & env.BUILD_NUMBER to store logs in arm"
                                        LOG_FOLDER = clusterLogUtilsInstance.getLogCollectionFolder(env.JOB_NAME, env.BUILD_NUMBER)
                                    }
                                    echo "LOG_FOLDER: ${LOG_FOLDER}"
                                }
                            }
                        }

                        stage ('Upload cluster to dashboard') {
                            steps {
                                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                                    script {
                                        def cluster_details = clusterLockUtils.getLockableResourceDescription(env.CLUSTER)
                                        if (cluster_details.contains('Product CI')) {
                                            sendClusterHealthToDashboard(env.CLUSTER)
                                        } else {
                                            echo "Cluster: ${env.CLUSTER} details could not be uploaded to the application dashboard. Uploading is only allowed for Product CI clusters."
                                        }
                                    }
                                }
                            }
                        }

                        stage('Add page info') {
                            steps {
                                script {
                                    try {
                                        echo "get log folder link ..."
                                        LOG_LINK = clusterLogUtilsInstance.getLogCollectionLink("${LOG_FOLDER}")
                                        currentBuild.description += LOG_LINK
                                    }
                                    catch (err) {
                                        echo "Caught getLogCollectionLink ERROR: ${err}"
                                    }

                                    try {
                                        echo "get job link ..."
                                        JOB_LINK = clusterLogUtilsInstance.getLogCollectionJobLink("${LOG_FOLDER}")
                                        currentBuild.description += JOB_LINK
                                    }
                                    catch (err) {
                                        echo "Caught getLogCollectionJobLink ERROR: ${err}"
                                    }
                                }
                            }
                        }

                        stage('Run parallely performance and log collection') {
                            parallel {
                                stage('Collect and save cluster info') {
                                    //Modification based on ticket EEAEPP-95296
                                    steps{
                                        script{
                                            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE'){
                                                //collect data
                                                def ccdVersion = clusterInfo.getCCDVersion(env.CLUSTER)
                                                def k8sServerVer = clusterInfo.getK8sversion(env.CLUSTER)
                                                def OSVersion = clusterInfo.getOSVersion(env.CLUSTER)
                                                def rookVersion = clusterInfo.getRookVersion(env.CLUSTER)
                                                def cephVersion = clusterInfo.getCephVersion(env.CLUSTER)
                                                def cephHealth = clusterInfo.getCephHealth(env.CLUSTER)

                                                def ccdInfo = 'ccdVersion: ' + ccdVersion +
                                                    '\nk8sServerVer: ' + k8sServerVer +
                                                    '\nOSVersion: ' + OSVersion +
                                                    '\nrookVersion: ' + rookVersion +
                                                    '\ncephVersion: ' + cephVersion +
                                                    '\ncephHealth: ' + cephHealth

                                                currentBuild.description += "<br> CCD version: $ccdVersion, rook version: $rookVersion, ceph version: $cephVersion"
                                                //save into file
                                                try {
                                                    writeFile file: "ccd_information.txt", text: ccdInfo
                                                }
                                                catch(err) {
                                                    echo "File write error: ${err}"
                                                }
                                            }
                                        }
                                    }
                                }

                                stage('performance data collection steps') {
                                    stages {
                                        stage('Init performance data collection') {
                                            steps {
                                                script {
                                                    catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                                                            env.UPSTREAM_JOB_NAME = getLastUpstreamBuildEnvVarValue('JOB_NAME').trim()
                                                            env.UPSTREAM_BUILD_NUMBER = getLastUpstreamBuildEnvVarValue('BUILD_NUMBER').trim()
                                                            echo "Upstream job: ${env.UPSTREAM_JOB_NAME} ${env.UPSTREAM_BUILD_NUMBER}"
                                                            copyArtifacts filter: 'performance.properties', fingerprintArtifacts: true, projectName: "${env.UPSTREAM_JOB_NAME}", selector: specific("${env.UPSTREAM_BUILD_NUMBER}")
                                                            readProperties(file: 'performance.properties').each {key, value -> env[key] = value.replace('"', '') }
                                                            echo "SPINNAKER_TRIGGER_URL: ${env.SPINNAKER_TRIGGER_URL} START_EPOCH: ${env.START_EPOCH} END_EPOCH: ${env.END_EPOCH}"
                                                    }
                                                }
                                            }
                                        }

                                        stage('Collect performance data from cluster') {
                                            steps {
                                                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                                                    script {
                                                        if ( ! "${JOB_LINK}".contains('cluster-logcollector') ) {
                                                            build job: "collect-performance-data-from-cluster", parameters: [
                                                                stringParam(name: "CLUSTER", value: env.CLUSTER),
                                                                stringParam(name: "START_EPOCH", value: env.START_EPOCH),
                                                                stringParam(name: "END_EPOCH", value: env.END_EPOCH),
                                                                stringParam(name: "SPINNAKER_TRIGGER", value: env.SPINNAKER_TRIGGER_URL)
                                                                ], wait: true, propagate: false
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                stage('µService and gServices log collection') {
                                    stages {
                                        stage('Collect certs from service') {
                                            when {
                                                expression { !params.SERVICE_NAME.isEmpty() }
                                            }
                                            steps {
                                                script {
                                                    catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                                                        withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                                                        file(credentialsId: env.system, variable: 'KUBECONFIG')]) {
                                                            sh "./bob/bob -r bob-rulesets/log_collecting.yaml collect-current-services-cert"
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        stage('Collect logs from cluster') {
                                            steps {
                                                script {
                                                    catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                                                        clusterLogUtilsInstance.collectClusterLogs()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                stage('Collect coredumps') {
                                    steps {
                                        script {
                                            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                                                clusterLogUtilsInstance.collectClusterCoredumps()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        stage('Publish logs to job') {
                            when {
                                expression { params.PUBLISH_LOGS_TO_JOB == true }
                            }
                            steps {
                                script {
                                    clusterLogUtilsInstance.publishLogsToJob()
                                }
                            }
                        }

                        stage('Publish logs to arm') {
                            when {
                                expression { params.PUBLISH_LOGS_TO_ARM == true }
                            }
                            steps {
                                script {
                                    clusterLogUtilsInstance.publishLogsToArm("${LOG_FOLDER}")
                                }
                            }
                        }
                    }
                }
            }
            post {
                always {
                    script {
                        echo "Lock Post actions: always."
                        sendLockEventToDashboard (transition: "release", cluster: env.CLUSTER)
                        def labelmanualchanged = checkLockableResourceLabelManualChange(env.CLUSTER)
                        echo "currentBuild.result: ${currentBuild.result}"
                        if ( currentBuild.result != 'SUCCESS' ) {
                            description = "${currentBuild.result} ${env.JOB_NAME} ${env.BUILD_NUMBER}"
                        } else {
                            description = ""
                        }
                        if (!labelmanualchanged && params.DESIRED_CLUSTER_LABEL?.trim() ) {
                            try {
                                echo "Set label for the lockable resource ... \n - cluster: ${env.CLUSTER} \n - label: ${params.DESIRED_CLUSTER_LABEL}"
                                build job: "lockable-resource-label-change", parameters: [
                                    booleanParam(name: 'DRY_RUN', value: false),
                                    stringParam(name: 'DESIRED_CLUSTER_LABEL', value : "${params.DESIRED_CLUSTER_LABEL}"),
                                    stringParam(name: 'PIPELINE_NAME', value: params.PIPELINE_NAME),
                                    stringParam(name: 'SPINNAKER_ID', value: params.SPINNAKER_ID),
                                    stringParam(name: 'SPINNAKER_TRIGGER_URL', value: params.SPINNAKER_TRIGGER_URL),
                                    stringParam(name: 'CLUSTER_NAME', value : "${env.CLUSTER}"),
                                    stringParam(name: 'DESCRIPTION', value: description)], wait: true
                                    env.LASTLABEL = params.DESIRED_CLUSTER_LABEL
                            }
                            catch (err) {
                                echo "Caught setLockableResourceLabels ERROR: ${err}"
                            }
                        }

                        try {
                            echo "Clear note for the lockable resource ... \n - cluster: ${env.CLUSTER}"
                            setLockableResourceNote("${env.CLUSTER}", "")
                        }
                        catch (err) {
                            echo "Caught setLockableResourceNote ERROR: ${err}"
                        }

                        if (!labelmanualchanged && params.CLUSTER_CLEANUP) {
                            try {
                                echo "Execute cluster-cleanup job ... \n - cluster: ${env.CLUSTER}"
                                build job: "cluster-cleanup", parameters: [
                                    stringParam(name: "CLUSTER_NAME", value: env.CLUSTER),
                                    stringParam(name: 'CNINT_GERRIT_REFSPEC', value: params.GERRIT_REFSPEC),
                                    stringParam(name: "DESIRED_CLUSTER_LABEL", value: params.AFTER_CLEANUP_DESIRED_CLUSTER_LABEL),
                                    stringParam(name: "LAST_LABEL_SET", value: env.LASTLABEL),
                                    stringParam(name: 'PIPELINE_NAME', value: params.PIPELINE_NAME),
                                    stringParam(name: 'SPINNAKER_ID', value: params.SPINNAKER_ID),
                                    stringParam(name: 'SPINNAKER_TRIGGER_URL', value: params.SPINNAKER_TRIGGER_URL)
                                    ], wait: true
                            }
                            catch (err) {
                                echo "Caught cluster-cleanup job ERROR: ${err}"
                                error "CLUSTER CLEANUP FAILED"
                            }
                        }
                    }
                }
            }
        }
    }
    post {
        failure {
            script {
                echo "Post actions: failure."
                echo "Send failure notification ..."
                def recipient = '2b661627.ericsson.onmicrosoft.com@emea.teams.ms'
                notif.sendMail(
                    "${env.JOB_NAME} (${env.BUILD_NUMBER}) logcollector failed",
                    "${env.BUILD_URL} logcollector failed on cluster ${env.CLUSTER}\n\n${JOB_LINK}\n${LOG_LINK}",
                    "${recipient}",
                    "text/html")
            }
        }
        cleanup {
            cleanWs()
        }
    }
}
