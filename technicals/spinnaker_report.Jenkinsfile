@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import java.text.SimpleDateFormat

@Field def gitaas = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitcnint = new GitScm(this, 'EEA/cnint')

pipeline{
    options { buildDiscarder(logRotator(daysToKeepStr: "30"))}
    agent { node { label "productci" }}
    triggers { cron('0 0 * * *') }
    // parameters {
    //     string(name: 'LENGTH', description: 'last n executions to generate report from', defaultValue: '200')
    // }
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
        stage('Checkout cnint') {
            steps {
                script{
                    gitcnint.checkout(env.MAIN_BRANCH, 'cnint')
                }
            }
        }
        stage('Create spin config') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'eceaspin', usernameVariable: 'SPIN_USERNAME', passwordVariable: 'SPIN_PASSWORD')]) {
                    writeFile file: 'spin_config', text: "gate:\n  endpoint: https://spinnaker-api.rnd.gic.ericsson.se\nauth:\n  enabled: true\n  basic:\n    username: ${SPIN_USERNAME}\n    password: ${SPIN_PASSWORD}"
                }
            }
        }
        stage('Create report') {
            steps {
                script {
                    def reportfile = 'report.html'
                    def exec_limit = 200
                    def pipeline_list = ['eea-application-staging-wrapper','eea-application-staging', 'eea-adp-staging', 'eea-product-ci-meta-baseline-loop']
                    def currentdate = new Date()
                    def currentdate_formatted = new SimpleDateFormat('yyyy-MM-dd HH:mm:ss')
                    appendFile(reportfile, '<html><body><style>td { border-bottom: 1px groove; border-right: 1px groove; border-collapse: collapse; padding: 10px; }</style>')
                    appendFile(reportfile, '<h1>Spinnaker Pipeline Report - as of ' + currentdate_formatted.format(currentdate) + ' (last ' + exec_limit + ' executions max)</h1>')
                    pipeline_list.each { pipeline_name ->
                        appendFile(reportfile, '<h2>' + pipeline_name + '</h2>')
                        appendFile(reportfile, query_pipeline(pipeline_name, exec_limit))
                    }
                    appendFile(reportfile, '</body></html>')
                    archiveArtifacts reportfile
                }
            }
        }
    }
}

String get_pipeline_id(String pipeline_name) {
    sh 'spin pipelines list --application eea --config spin_config > pipeline_list.json'
    def pipeline_list = readJSON file: "pipeline_list.json"
    def retval
    pipeline_list.each {
        if (it.name == pipeline_name) {
            retval = it.id
        }
    }
    return retval
}

String[] get_executions(String pipeline_id, int limit) {
    // the function queries Spinnaker by Spin CLI and returns the results in Groovy data structure.
    sh 'spin pipeline execution list --succeeded --failed --pipeline-id ' + pipeline_id + ' --limit ' + limit + ' --config spin_config > execution_list.json'

    // read the returned JSON
    def execution_list = readJSON file: "execution_list.json"
    def retval = [] // this will hold the result
    // iterate the result and get the relevant information
    execution_list.each {
        def triggering_user = it.authentication.user
        def triggering_pipeline = 'MANUAL START'
        try {
            triggering_pipeline = it.trigger.parentExecution.name
        }catch (exc) {
            println('Manual start, exception caught ' + exc)
        }
        def buildtime = it.buildTime
        def status = it.status
        def stages = it.stages
        def id = it.id
        def exec_failure = ''
        def starttime = it.startTime
        int duration = 0
        stages.reverse().each { stage ->
            if (stage.status == 'TERMINAL') {
                exec_failure = stage.name
            }
            // if (stage.startTime != null) {
            //     starttime = stage.startTime
            // }
        }
        if (status == 'NOT_STARTED' || status == 'RUNNING' || status == 'CANCELED') {
            duration = 0
        } else {
            duration = (it.endTime - it.startTime).intdiv(1000)
        }
        def duration_minutes = duration.intdiv(60)
        def duration_seconds = duration - duration_minutes * 60
        println(duration_minutes + ':' + duration_seconds)
        retval.add([triggering_pipeline, triggering_user, duration_minutes + ':' + duration_seconds, it.status, exec_failure, duration, id])
    }
    return retval
}

def appendFile(String fileName, String line) {
    // this function is an inefficient way to append to a file.
    def current = ""
    if (fileExists(fileName)) {
        current = readFile fileName
    }
    writeFile file: fileName, text: current + line + '\n'
}

String query_pipeline(String pipeline_name, int limit) {
    // this function creates a string that contains the html table and returns it
    def execution_count = limit
    def exec = get_executions(get_pipeline_id(pipeline_name), execution_count) // query the executions into a list
    execution_count = exec.size() // if there are less executions than we queried for, we will select that number.
    def stages = [:]
    def service_failures = [:]
    def duration_sum = 0
    exec.each {
        def triggering_pipeline = it[0]
        def triggering_user = it[1]
        def duration = it[5]
        def id = it[6]
        def status = it[3]
        def failstage = it[4]
        if (failstage == '') {
            failstage = status
        }
        if (status == 'SUCCEEDED') {
            duration_sum = duration_sum + duration
            println(triggering_pipeline + ' ' + status + ' ' + id + ' ' + duration + ' ' + duration_sum)
        }

        // the following section fills the service_failures hashtable with temporary hashtables and this construct will be used to create the pivottable in a later step.
        if (service_failures.get(triggering_pipeline) == null) {
            def temp = [:]
            temp.put(failstage, 1)
            service_failures.put(triggering_pipeline, temp)
        } else {
            def temp = service_failures.get(triggering_pipeline)
            if (temp.get(failstage) == null) {
                temp.put(failstage, 1)
            } else {
                temp.put(failstage, temp.get(failstage) + 1)
            }
            service_failures.put(triggering_pipeline, temp)
        }

        // the stages hashtable counts the failures in each stage.
        if (stages.get(failstage) == null) {
            stages.put(failstage, 1)
        } else {
            stages.put(failstage, stages.get(failstage) + 1)
        }
    }

    // start creating the string that will hold the html table
    def retval = '<div><table><tr><th>Service</th>'
    stages.keySet().each { stage ->
        retval = retval + '<th>' + stage + '</th>'
    }
    retval = retval + '<th>Grand Total</th><th>Success Ratio/MS</th></tr>'

    // iterate services and print the failcount for each stage
    service_failures.keySet().each { service ->
        def this_line = '<tr><td>' + service + '</td>'
        def failures = service_failures.get(service)
        stages.keySet().each { stage ->
            this_line = this_line + '<td align="right">'
            failures.keySet().each { failure ->
                if (stage == failure) {
                    this_line = this_line + failures.get(failure)
                }
            }
            this_line = this_line + '</td>'
        }

        // count the number of failures
        def run_count = 0
        failures.keySet().each { failure ->
            run_count = run_count + failures.get(failure)
        }

        // calculate success rate
        def success_count = failures.get('SUCCEEDED')
        float success_ratio
        if (success_count == null) {
            success_ratio = 0
        } else {
            success_ratio = 100 * success_count / run_count
        }
        this_line = this_line + '<td align="right">' + run_count + '</td><td align="right">' + success_ratio.round(2) + '%</td></tr>'
        retval = retval + this_line
    }

    // Print the last two lines, one with nominal values and the other with percentages.
    retval = retval +'<tr><td>Grand Total</td>'
    stages.keySet().each { stage ->
        retval = retval + '<td align="right">' + stages.get(stage) + '</td>'
    }
    retval = retval + '<td align="right">' + execution_count + '</td>'
    retval = retval + '</tr><tr><td></td>'
    stages.keySet().each { stage ->
        float failure_ratio = 100 * stages.get(stage) / execution_count
        retval = retval + '<td align="right">' + failure_ratio.round(2) + '%</td>'
    }

    retval = retval + '</tr></table></div>'

    // calculate average duration for successful executions.
    def avg_duration = duration_sum.intdiv(stages.get('SUCCEEDED'))
    def duration_minutes = avg_duration.intdiv(60)

    // add leading zero
    String d_m_s = ''
    if (duration_minutes < 10) { d_m_s = '0' }
    d_m_s = d_m_s + duration_minutes
    def duration_seconds = avg_duration - duration_minutes * 60
    String d_s_s = ''
    if (duration_seconds < 10) { d_s_s = '0' }
    d_s_s = d_s_s + duration_seconds

    retval = retval + '<div>Average duration for successful executions: ' + d_m_s + ':' + d_s_s + ' (minute:second)</div>'
    return retval
}
