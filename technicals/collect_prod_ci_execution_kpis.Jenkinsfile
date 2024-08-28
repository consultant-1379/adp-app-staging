@Library('ci_shared_library_eea4') _

import java.text.SimpleDateFormat
import groovy.json.JsonOutput
import groovy.transform.Field

import com.ericsson.eea4.ci.SpinUtils
import com.ericsson.eea4.ci.CiDashboard

@Field def spinUtilsInstance = new SpinUtils(this)
@Field def dashboard = new CiDashboard(this)

pipeline {
    options {
        skipDefaultCheckout()
        buildDiscarder(logRotator(daysToKeepStr: "7"))
    }
    agent {
        node {
            label "productci"
        }
    }
    parameters {
        string(name: 'PIPELINE_NAME', description: 'Name of Spinnaker pipeline', defaultValue: 'eea-application-staging')
        string(name: 'PIPELINE_EXEC_ID', description: 'Execution ID of Spinnaker pipeline', defaultValue: '')
    }
    stages {
        stage("Params DryRun check") {
            when {
                expression { params.DRY_RUN == true }
            }
            steps {
                script {
                    dryRun()
                }
            }
        }
        stage('Clean workspace') {
            steps {
                script {
                    cleanWs()
                }
            }
        }
        stage('Create spin config') {
            steps {
                script {
                    spinUtilsInstance.createSpinConfig()
                }
            }
        }

        stage('Collect information about pipeline execution') {
            steps {
                catchError(stageResult: 'FAILURE', buildResult: 'SUCCESS') {
                    script {
                        def pipelineName = params.PIPELINE_NAME
                        def pipelineExecId = params.PIPELINE_EXEC_ID
                        def execLimit = 200

                        // exec spin CLI
                        def executionText = spinUtilsInstance.getSpinData("pipeline execution get $pipelineExecId")
                        def executionJSON = readJSON text: executionText

                        SimpleDateFormat dateFormatter = new SimpleDateFormat('yyyy-MM-dd HH:mm:ss')
                        // setting time zone to UTC to format dates in the universal time zone
                        dateFormatter.setTimeZone(TimeZone.getTimeZone("UTC"))

                        // OUTPUT: pipeline result
                        def pipelineResult = dashboard.mapExecutionResult(executionJSON[0].status)

                        // OUTPUT: start time (actual execution)
                        long startTime = executionJSON[0].buildTime
                        def startDate = dateFormatter.format(new Date(startTime))

                        // OUTPUT: end time (actual execution)
                        long endTime = executionJSON[0].endTime
                        def endDate = dateFormatter.format(new Date(endTime))

                        // OUTPUT: build duration (calc)
                        def buildDuration = (endTime - startTime).intdiv(1000)

                        // def parent_exec_id = getInitialParentExecution(executionJSON[0])
                        // println('Initial parent pipeline execution is "' + parent_exec_id + '".')

                        // OUTPUT: lead time (calc)
                        long leadStartTime = getLeadStartTime(executionJSON[0])
                        def leadStartDate = dateFormatter.format(new Date(leadStartTime))
                        def leadTime = (endTime - leadStartTime).intdiv(1000)

                        //get pending executions by pipeline name
                        def queuePipelineName = pipelineName
                        if (pipelineName == 'eea-application-staging') {
                            queuePipelineName = 'eea-application-staging-wrapper'
                        }

                        // exec spin CLI
                        def wrapperPipelineId = spinUtilsInstance.getSpinPipelineId(queuePipelineName)
                        def pendingExecutionText = spinUtilsInstance.getSpinData("pipeline execution list --pipeline-id ${wrapperPipelineId} --limit ${execLimit}")
                        def pendingExecutionList = readJSON text: pendingExecutionText

                        // OUTPUT: queue length (from spin cli)
                        def queueLength = 0
                        // setting queueStartTime to now in order to decrease it in the following loop
                        def queueStartTime = System.currentTimeMillis()
                        // iterate through pipeline executions to calculate items and find the earliest in the queue
                        pendingExecutionList.each {
                            def status = it.status
                            if (status == 'NOT_STARTED') {
                                queueLength++
                                queueStartTime = it.buildTime < queueStartTime ? it.buildTime : queueStartTime
                            }
                        }
                        // OUTPUT: queue waiting time (calc)
                        def queueWaitTime = (System.currentTimeMillis() - queueStartTime).intdiv(1000)
                        def queueStartDate = dateFormatter.format(new Date(queueStartTime))

                        def jsonStr
                        echo "Prepare KPI data sending ..."

                        try {
                            Map line = [
                                "PipelineName": "${pipelineName}",
                                "PipelineExecId": "${pipelineExecId}",
                                "PipelineResult": "${pipelineResult}",
                                "StartTime": "${startDate}",
                                "EndTime": "${endDate}",
                                "BuildDuration": "${buildDuration}",
                                "LeadTime": "${leadTime}",
                                "QueueLength": "${queueLength}",
                                "QueueWaitingTime": "${queueWaitTime}"
                            ]

                            jsonStr = JsonOutput.prettyPrint(JsonOutput.toJson([line]))
                            def jsonFileName = "${pipelineName}_${pipelineExecId}_${env.BUILD_NUMBER}.uploadExecutionKpi.json"
                            sh "echo '$jsonStr' >> ${jsonFileName}"
                            archiveArtifacts artifacts: "${jsonFileName}", allowEmptyArchive: true
                        }
                        catch (Exception e) {
                            error("Prepare KPI data sending FAILED with exception: ${e.class.name}\n - message: ${e.message}")
                        }

                        echo "Execute KPI data sending ..."
                        try {
                            dashboard.uploadExecutionKpi(jsonStr)
                        }
                        catch (Exception e) {
                            error("dashboard::uploadExecutionKpi FAILED with exception: ${e.class.name}\n - message: ${e.message}")
                        }
                    }
                }
            }
        }

        /*
        stage('test uploadExecutionKpi') {
            steps {
                catchError(stageResult: 'FAILURE', buildResult: 'SUCCESS') {
                    script {
                        def pipelineName = params.PIPELINE_NAME
                        def pipelineExecId = params.PIPELINE_EXEC_ID
                        def jsonStr = """[{
    "PipelineName": "eea-application-staging",
    "PipelineExecId": "01GHCP09XRQ9608QPGBY4D3KVD",
    "PipelineResult": "SUCCEEDED",
    "StartTime": "2022-11-08 22:33:04",
    "EndTime": "2022-11-09 00:51:56",
    "BuildDuration": "8332",
    "LeadTime": "23470",
    "QueueLength": "0",
    "QueueWaitingTime": "0"
}]"""
                        def jsonFileName = "${pipelineName}_${pipelineExecId}_${env.BUILD_NUMBER}.uploadExecutionKpi.json"
                        sh "echo '$jsonStr' >> ${jsonFileName}"
                        archiveArtifacts artifacts: "${jsonFileName}", allowEmptyArchive: true
                        def result = dashboard.uploadExecutionKpi(jsonStr, "/api/v1/stages/uploadExecutionKpi")
                        echo "result: ${result}"
                    }
                }
            }
        }
        */

    }
    post {
        cleanup {
            cleanWs()
        }
    }
}

String getInitialParentExecution(def executionJSON) {
    if (executionJSON.trigger.parentExecution == null || executionJSON.trigger.parentExecution.application != "eea") {
        return executionJSON.id
    }
    else {
        getInitialParentExecution(executionJSON.trigger.parentExecution)
    }
}

String getLeadStartTime(def executionJSON) {
    if (executionJSON.trigger.parentExecution == null || executionJSON.trigger.parentExecution.application != "eea") {
        return executionJSON.buildTime
    }
    else {
        getLeadStartTime(executionJSON.trigger.parentExecution)
    }
}
