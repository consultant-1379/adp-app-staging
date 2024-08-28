@Library('ci_shared_library_eea4') _

import java.time.DayOfWeek
import java.time.LocalDateTime
import groovy.transform.Field

import com.ericsson.eea4.ci.ClusterLockUtils
import com.ericsson.eea4.ci.CommonUtils
import com.ericsson.eea4.ci.Notifications
import com.ericsson.eea4.ci.GlobalVars

@Field def clusterLockUtils =  new ClusterLockUtils(this)
@Field def commonUtils = new CommonUtils(this)
@Field def notif = new Notifications(this)

// List allClusterLabelsToCheck = ['bob-ci', 'bob-ci-upgrade-ready', 'faulty', 'ceph-error']
List allClusterLabelsToCheck = ['bob-ci', 'bob-ci-upgrade-ready', 'ceph-error'] // TODO: EEAEPP-97631 - faulty temporarily removed
List outOfPoolClusterLabelsToCheck = ['faulty', 'ceph-error']
Map clustersToReinstall = [:]

pipeline {
    options {
        ansiColor('xterm')
        skipDefaultCheckout()
        buildDiscarder(logRotator(daysToKeepStr:'14', artifactDaysToKeepStr:'7'))
    }
    agent {
        node {
            label 'productci'
        }
    }
    triggers { cron('00 22 * * *') } //run at 10PM every day
    parameters {
        booleanParam(name: 'DUMMY_RUN', description: 'If true, execute all the build jobs with DRY_RUN=true and do not send email notification', defaultValue: false)
        booleanParam(name: 'CHECK_PERMITTED_TIME_FRAME', description: 'If true, reinstall for the clusters in the pool only allowed in a specific time frame (from Friday 6PM to Monday 0AM ', defaultValue: true)
        string(name: 'MAXIMUM_NUMBER_OF_RETRIES', description: 'The maximum number of cluster reinstall retries', defaultValue: '3')
        string(name: 'REINSTALL_TIMEOUT', description: 'Timeout value for every single reinstallation, default 10 hours', defaultValue: '600')
        string(name: 'REINSTALL_TIMEOUT_UNIT', description: 'Timeout unit, HOURS/MINUTES/SECONDS/etc.', defaultValue: 'MINUTES')
        string(name: 'REINSTALL_TIMEOUT_LOCKED', description: 'Timeout value for reinstallation for locked clusters, default 15 hours', defaultValue: '900')
        string(name: 'REINSTALL_TIMEOUT_LOCKED_UNIT', description: 'Timeout unit, HOURS/MINUTES/SECONDS/etc.', defaultValue: 'MINUTES')
        string(name: 'SLEEP_CYCLE_WAITING_FOR_FREE_RESOURCE_STATUS_TIME', description: 'Sleep time value between checking of cluster status, default 5 minutes', defaultValue: '5')
        string(name: 'SLEEP_CYCLE_WAITING_FOR_FREE_RESOURCE_STATUS_UNIT', description: 'Sleep time unit, HOURS/MINUTES/SECONDS/etc.', defaultValue: 'MINUTES')
    }
    environment {
        REPORT_FILENAME = "auto_reinstallation_report.html"
        CLUSTER_REINSTALL_JOB_NAME = 'cluster-reinstall'
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

        stage('Check if run in Jenkins prod'){
            when {
                expression { env.MAIN_BRANCH != 'master' }
            }
            steps {
                script {
                    dryRun()
                }
            }
        }

        stage('Check Concurrent Builds') {
            steps {
                script {
                    echo "Get count of the currently running ${env.JOB_NAME} job"
                    def testJobId = "${env.JOB_NAME}-${env.BUILD_NUMBER}"
                    def runningJobCount = getRunningJobCount("${env.JOB_NAME}")
                    if ( runningJobCount >= 2 ) {
                        echo "${env.JOB_NAME} is already running (count: ${runningJobCount-1}) --> skip this run"
                        dryRun()
                    }
                }
            }
        }

        stage('Collect clusters to reinstall') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    script {
                        // filter for product ci clusters only
                        def productCiClusters = GlobalVars.Clusters.values().findAll{ it.owner.contains('product_ci') }.collect { it.resource }.sort()

                        productCiClusters.each { clusterName ->
                            echo "Collect info for cluster ${clusterName} ..."
                            clusterLabel = getClusterLabel(clusterName)
                            if (!allClusterLabelsToCheck.contains(clusterLabel)) {
                                echo "${clusterName} has the label ${clusterLabel} for which reinstall should be skipped"
                                return
                            }

                            def priorityOrder = 0

                            echo "Get priority from rook ceph status for cluster ${clusterName} ..."
                            priorityOrder += getPriorityFromRookCephStatus(clusterName)

                            // inccrease priority for clusters that are alreday out of the pool
                            if (outOfPoolClusterLabelsToCheck.contains(clusterLabel)) {
                                if (clusterLabel == "ceph-error") {
                                    priorityOrder += 2000
                                }
                                if (clusterLabel == "faulty") {
                                    priorityOrder += 1000
                                }
                            }

                            // if priorityOrder is non zero, we can add the cluster to the list
                            if (priorityOrder) {
                                echo "priorityOrder exists --> added to reinstall - clusterName: ${clusterName} - clusterLabel: ${clusterLabel} - priority: ${priorityOrder}"
                                clustersToReinstall[clusterName] = [
                                    label: clusterLabel,
                                    priority: priorityOrder,
                                    tryCount: 0,
                                    status: 'Not build yet',
                                    lastBuildResult: '',
                                    lastBuildUrl: '',
                                    todo: '',
                                    emulatedResourceStatus: '', // for debug purposes only, must be blank for prod usage
                                    emulatedBuildResult: '',    // for debug purposes only, must be blank for prod usage
                                ]
                            }
                        }
                        echo "Cluster reinstall group: ${clustersToReinstall}"
                    }
                }
            }
        }

        stage('Reinstall clusters') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    script {
                        if (!clustersToReinstall) {
                            echo "There is NO cluster to reinstall."
                        } else {
                            try {
                                echo "${clustersToReinstall.size()} cluster(s) found to reinstall"
                                clustersToReinstall = getSorted(clustersToReinstall)
                                clustersToReinstall.each { clusterName, value ->
                                    echo "Starting to reinstall cluster ${clusterName} ..."
                                    def statusCheck = clusterLockUtils.getResourceLabelStatus(clusterName)
                                    if (value.emulatedResourceStatus && statusCheck != value.emulatedResourceStatus) {
                                        // override if emulated value exists
                                        echo "Overriding status '${statusCheck}' with emulatedResourceStatus '${value.emulatedResourceStatus}'"
                                        statusCheck = value.emulatedResourceStatus
                                    }
                                    if (statusCheck == "FREE") {
                                        echo "Resource status for cluster '${clusterName}' with label '${value.label}' and priority '${value.priority}' is '${statusCheck}'"
                                        result = reinstallCluster(clusterName, clustersToReinstall, outOfPoolClusterLabelsToCheck)
                                        if (!result) {
                                            if (!outOfPoolClusterLabelsToCheck.contains(value.label)) {
                                                // if any error occurs for clusters that in the pool
                                                error("Process failed, skipping the rest of the reinstalls to avoid accidentally removing all the clusters!")
                                            }
                                        }
                                    } else {
                                        echo "The cluster '${clusterName}' cannot be reinstalled because it's not free. Current status is '${statusCheck}'"
                                        clustersToReinstall[clusterName].status = "Locked"
                                    }
                                }
                            } catch (org.jenkinsci.plugins.workflow.steps.FlowInterruptedException err) {
                                echo "Reinstall clusters FAILED.\nERROR: ${err}"
                            }
                        }
                    }
                }
            }
        }

        stage('Reinstall locked clusters with wait') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    script {
                        try {
                            // start another iteration for clusters with previously Locked state
                            clustersToReinstall.each { clusterName, value ->
                                if ( clustersToReinstall[clusterName].status == "Locked" ) {
                                    reinstallLockedClusterWithWait(clusterName, clustersToReinstall, outOfPoolClusterLabelsToCheck)
                                }
                            }
                        } catch (org.jenkinsci.plugins.workflow.steps.FlowInterruptedException err) {
                            echo "Reinstall locked clusters with wait FAILED.\nERROR: ${err}"
                        }
                    }
                }
            }
        }

    }
    post {
        always {
            script {
                if (!params.DRY_RUN) {
                    htmlContent = createReport(clustersToReinstall)

                    // write content to file and archive it
                    writeFile(file: "${WORKSPACE}/${env.REPORT_FILENAME}", text: htmlContent)
                    archiveArtifacts artifacts: "*.html", allowEmptyArchive: true

                    //notify Driving channel
                    if (!params.DUMMY_RUN && clustersToReinstall) {
                        notif.sendMail("${env.JOB_NAME} (${env.BUILD_NUMBER}) Clusters reinstall report","Result of auto cluster reinstallation: ${env.BUILD_URL}\n${htmlContent}","517d5a14.ericsson.onmicrosoft.com@emea.teams.ms", "text/html")
                    }
                }
            }
        }
        cleanup {
            cleanWs()
        }
    }
}

@NonCPS
def getSorted(def toBeSorted){
    toBeSorted.sort(){ a, b -> b.value.priority <=> a.value.priority }
}

def getClusterLabel(String clusterName) {
    echo "Get cluster label for ${clusterName} ..."
    def clusterLabel = ''
    try {
        clusterLabel = clusterLockUtils.getLockableResourceLabels(clusterName.replaceAll('_', '-'))
        echo "clusterLabel for ${clusterName} is ${clusterLabel}"
    }
    catch (err) {
        error "Get cluster label for ${clusterName} FAILED.\nERROR: ${err}"
    }
    return clusterLabel
}

def getPriorityFromRookCephStatus(String clusterName) {
    echo "Get rook ceph status for ${clusterName} ..."
    try {
        rookCephStatus = getRookCephStatusFromClusterInfo(clusterName)
        echo "rookCephStatus for ${clusterName}:\n${rookCephStatus}"
    }
    catch (err) {
        error "Get rook ceph status for ${clusterName} FAILED.\nERROR: ${err}"
    }
    echo "Validate rook ceph status for ${clusterName} ..."
    def priority = 0
    def failureMessageMajor = ""
    try {
        validationResult = validateRookCephStatus("${rookCephStatus}")
        if (validationResult) {
            def failureListMajor = validationResult.get('failureListMajor')
            if (failureListMajor) {
                failureMessageMajor = "Critical/Major rook ceph health problem(s) detected on cluster: ${clusterName}"
                failureListMajor.eachWithIndex { failureMajor, idx ->
                    failureMessageMajor += "\n - ${failureListMajor.size()}/${idx+1}) ${failureMajor}"
                    thresholdMajor = failureMajor.get('thresholdMajor').toString()
                    priority += thresholdMajor.isNumber() ? thresholdMajor.toFloat() : 0
                }
                echo "${failureMessageMajor}"
            }
        } else {
            echo "No major/minor rook ceph health problem detected on cluster: ${clusterName}"
        }
    }
    catch (err) {
        error "Validate rook ceph status for ${clusterName} FAILED.\nERROR: ${err}"
    }
    return priority
}

def reinstallCluster(String clusterName, Map clustersToReinstall, List outOfPoolClusterLabelsToCheck) {
    clusterLabel = clustersToReinstall[clusterName].label
    try {
        if (outOfPoolClusterLabelsToCheck.contains(clusterLabel)) {
            echo "reinstallCluster for out of pool cluster ..."
            // if the cluster is already out of the pool, no need to check the time frame
            retry(env.MAXIMUM_NUMBER_OF_RETRIES) {
                jobResult = executeReinstallJob(clusterName, clustersToReinstall)
                if ( jobResult != 'SUCCESS' ) {
                    error "executeReinstallJob for ${clusterName} FAILED."
                }
            }
        } else {
            echo "reinstallCluster for in pool cluster ..."
            // if the cluster is still in the pool, need to check the permitted time frame
            // which lasts from 6PM on the current Friday until midnight next Monday
            LocalDateTime now = LocalDateTime.now()
            LocalDateTime fridayAt6PM = now.with(DayOfWeek.FRIDAY).withHour(22).withMinute(0).withSecond(0).withNano(0)
            LocalDateTime nextMondayAtMidnight = now.with(DayOfWeek.MONDAY).plusWeeks(1).toLocalDate().atStartOfDay()
            if (!params.CHECK_PERMITTED_TIME_FRAME || (now.isAfter(fridayAt6PM) && now.isBefore(nextMondayAtMidnight))) {
                jobResult = executeReinstallJob(clusterName, clustersToReinstall)
                if ( jobResult != 'SUCCESS' ) {
                    error "executeReinstallJob for ${clusterName} FAILED."
                }
            } else {
                echo "Reinstall cluster ${clusterName} skipped due to current datetime is out of the permitted time frame to reinstall!"
                echo "- Current Datetime: ${now}"
                echo "- Datetime of current week's Friday at 6PM: $fridayAt6PM"
                echo "- Datetime of next Monday at midnight: $nextMondayAtMidnight"
                clustersToReinstall[clusterName].status = "Skipped"
                return false
            }
        }
    } catch (err) {
        echo "reinstallCluster for ${clusterName} FAILED.\nERROR: ${err}"
        clustersToReinstall[clusterName].todo = "Need manual reinstall"
        def newLabel = "need_manual_reinstall"
        try {
            echo "Relabel cluster ${clusterName} to ${newLabel} ..."
            build job: "lockable-resource-label-change", parameters: [
                booleanParam(name: 'DRY_RUN', value: params.DUMMY_RUN),
                stringParam(name: 'DESIRED_CLUSTER_LABEL', value : newLabel),
                stringParam(name: 'CLUSTER_NAME', value : clusterName)], wait: true
        } catch (relabelError) {
            echo "Relabel cluster ${clusterName} to ${newLabel} FAILED.\nERROR: ${relabelError}"
        }
        return false
    }
    return true
}

def reinstallLockedClusterWithWait(String clusterName, Map clustersToReinstall, List outOfPoolClusterLabelsToCheck) {
    timeout(time: env.REINSTALL_TIMEOUT_LOCKED, unit: env.REINSTALL_TIMEOUT_LOCKED_UNIT) {
        while (true) {
            def statusCheck = clusterLockUtils.getResourceLabelStatus(clusterName)
            emulatedResourceStatus = clustersToReinstall[clusterName].get('emulatedResourceStatus')
            if (emulatedResourceStatus && statusCheck != emulatedResourceStatus) {
                // override if emulated value exists
                echo "Overriding status '${statusCheck}' with emulatedResourceStatus '${emulatedResourceStatus}'"
                statusCheck = emulatedResourceStatus
            }
            if (statusCheck == "FREE") {
                result = reinstallCluster(clusterName, clustersToReinstall, outOfPoolClusterLabelsToCheck)
                if (!result) {
                    error("Process failed, skipping the rest of the reinstalls to avoid accidentally removing all the clusters!")
                }
                return true
            }
            sleep(time: env.SLEEP_CYCLE_WAITING_FOR_FREE_RESOURCE_STATUS_TIME, unit: env.SLEEP_CYCLE_WAITING_FOR_FREE_RESOURCE_STATUS_UNIT)
        }
    }
}

def executeReinstallJob(String clusterName, Map clustersToReinstall) {
    lastBuildResult = ''
    lastBuildUrl = ''
    timeout(time: env.REINSTALL_TIMEOUT, unit: env.REINSTALL_TIMEOUT_UNIT) {
        try {
            cluster_reinstall_job = build job: env.CLUSTER_REINSTALL_JOB_NAME, parameters: [
                booleanParam(name: 'DRY_RUN', value: params.DUMMY_RUN),
                stringParam(name: 'CLUSTER_NAME', value: clusterName),
                stringParam(name: 'REINSTALL_LABEL', value: "automated_reinstall")], wait: true, propagate: false
            lastBuildResult = cluster_reinstall_job.getResult()
            lastBuildUrl = cluster_reinstall_job.getAbsoluteUrl()
        } catch (org.jenkinsci.plugins.workflow.steps.FlowInterruptedException err) {
            echo "executeReinstallJob interrupted.\nERROR: ${err}"
            lastBuildResult = 'Interrupted'
        } finally {
            emulatedBuildResult = clustersToReinstall[clusterName].get('emulatedBuildResult')
            if (emulatedBuildResult && lastBuildResult != emulatedBuildResult) {
                // override if emulated value exists
                echo "Overriding lastBuildResult '${lastBuildResult}' with emulatedBuildResult '${emulatedBuildResult}'"
                lastBuildResult = emulatedBuildResult
            }
            clustersToReinstall[clusterName].lastBuildResult = "${lastBuildResult}"
            clustersToReinstall[clusterName].lastBuildUrl = "${lastBuildUrl}"
            clustersToReinstall[clusterName].status = lastBuildResult == 'SUCCESS' ? 'DONE' : 'Failed'
            clustersToReinstall[clusterName].tryCount += 1
            tryCount = clustersToReinstall[clusterName].tryCount
            echo "Result of ${env.CLUSTER_REINSTALL_JOB_NAME} for cluster ${clusterName} is ${lastBuildResult}. (Retry count: ${tryCount}/${env.MAXIMUM_NUMBER_OF_RETRIES})"
        }
    }
    return lastBuildResult
}

def createReport(Map clusterReinstallList) {
    echo "Create Report"
    def tableHeader = ""
    def tableRows = ""
    if (clusterReinstallList) {
        tableHeader += """
        <tr>
            <th>Cluster</th>
            <th>Label</th>
            <th>Priority</th>
            <th>Last Build Result</th>
            <th>Try Count</th>
            <th>Status</th>
            <th>TODO</th>
            <th>Url</th>
        </tr>
        """
        clusterReinstallList.each { clusterName, value ->
            tableRows += """
            <tr>
                <td>${clusterName}</td>
                <td>${value.label}</td>
                <td>${value.priority}</td>
                <td>${value.lastBuildResult}</td>
                <td>${value.tryCount}</td>
                <td>${value.status}</td>
                <td>${value.todo}</td>
                <td><a href="${value.lastBuildUrl}" target="_blank">${value.lastBuildUrl}</a></td>
            </tr>
            """
        }
    } else {
        tableHeader = "<br>There is NO cluster to reinstall."
    }
    def htmlContent = """<!DOCTYPE html>
        <html>
            <head>
            <style>
            table {
            font-family: arial, sans-serif;
            border-collapse: collapse;
            width: 50%;
            }

            td, th {
            border: 1px solid #dddddd;
            text-align: left;
            padding: 8px;
            }

            tr:nth-child(even) {
            background-color: #dddddd;
            }
            </style>
            </head>

            <body>
            <h2>Cluster automation report</h2>
            <table>
                ${tableHeader}
                ${tableRows}
            </table>
            <br>
            <p><a href="${env.BUILD_URL}" target="_blank">${env.BUILD_URL}</a></p>
            </body>
        </html>
    """
    return htmlContent
}
