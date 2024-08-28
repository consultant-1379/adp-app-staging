@Library('ci_shared_library_eea4') _


import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import hudson.Util;
import com.ericsson.eea4.ci.GlobalVars
import com.ericsson.eea4.ci.Artifactory
import com.ericsson.eea4.ci.SanityCheck
import com.ericsson.eea4.ci.SpinUtils
import com.ericsson.eea4.ci.MimerUtils
import com.ericsson.eea4.ci.CiDashboard
import com.ericsson.eea4.ci.CommonUtils

@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitcommoner = new GitScm(this, 'eea-release-team/commoner')
@Field def arm = new Artifactory(this, "https://arm.seli.gic.ericsson.se/", "API_TOKEN_EEA")
@Field def vars = new GlobalVars()
@Field def sc = new SanityCheck(this)
@Field def spin = new SpinUtils(this)
@Field def mimer = new MimerUtils(this)
@Field def dashboard = new CiDashboard(this)
@Field def cmutils = new CommonUtils(this)

def whiteListServices = []
def whiteListRepos = []
def chartNameList = []
def chartRepoList = []
def chartVersion = []
def waitForClusterLogCollect = false
def stageResultsInfo = [:]
def stageCommentList = [:]

pipeline {
   options { buildDiscarder(logRotator(daysToKeepStr: "14", artifactDaysToKeepStr: "7"))}
    agent {
        node {
            label 'productci'
        }
    }

    parameters {
        string(name: 'CHART_NAME', description: 'Chart name e.g.: eric-ms-b', defaultValue: '')
        string(name: 'CHART_REPO', description: 'Chart repo e.g.: https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm', defaultValue: '')
        string(name: 'CHART_VERSION', description: 'Chart version e.g.: 1.0.0-1', defaultValue: '')
        string(name: 'GERRIT_REFSPEC', description: 'Gerrit Refspec of the integration chart git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'SPINNAKER_TRIGGER_URL', description: 'Spinnaker pipeline triggering url', defaultValue: '')
        string(name: 'REPOSITORY', description: 'ARM repository of the test results repo.', defaultValue: 'proj-eea-reports-generic-local')
        string(name: 'PIPELINE_NAME', description: "The spinnaker pipeline name", defaultValue: 'eea-application-staging')
        string(name: 'SPINNAKER_ID', description: "The spinnaker execution's id", defaultValue: '')
    }

    environment {
        REPORT_REPO_PATH = "https://arm.seli.gic.ericsson.se/artifactory/proj-eea-reports-generic-local"
        STAGES_STATUS_FILENAME = "stages_status.html"
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

        stage('Checkout adp-app-staging') {
            steps {
                script {
                    gitadp.sparseCheckout("technicals/")
                }
            }
        }

        stage('Init chart list for drop') {
            when {
                expression { params.CHART_NAME }
            }
            steps {
                script {
                    chartNameList = params.CHART_NAME.split(',')
                    chartRepoList = params.CHART_REPO.split(',')
                    for (int i = 0; i < chartRepoList.size(); i++) {
                        if (getLastNCharacters(chartRepoList[i], 1) == "/") {
                            chartRepoList[i] = removeLastNCharacters(chartRepoList[i], 1)
                        }
                    }
                    chartVersion = params.CHART_VERSION.split(',')
                }
            }
        }

       stage('Init chart list for manual change') {
            when {
                expression { params.GERRIT_REFSPEC }
            }
            steps {
                script {
                    gitcnint.sparseCheckoutRefSpec("${env.GERRIT_REFSPEC}", "eric-eea-int-helm-chart/Chart.yaml","FETCH_HEAD", 'new')
                    gitcnint.sparseCheckout("eric-eea-int-helm-chart/Chart.yaml", 'master', 'old')
                    def oldFileContent = sh(script: 'cat old/eric-eea-int-helm-chart/Chart.yaml', returnStdout: true).trim()
                    def newFileContent = sh(script: 'cat new/eric-eea-int-helm-chart/Chart.yaml', returnStdout: true).trim()
                    def oldEntries = parseFile(oldFileContent.split('\n'))
                    def newEntries = parseFile(newFileContent.split('\n'))
                    (chartNameList,chartRepoList,chartVersion) = compare_chart_list(oldEntries,newEntries)
                    def changed = "Changed:\n"
                    for (int i = 0; i < chartNameList.size(); i++) {
                        changed += chartRepoList[i]+"/"+chartNameList[i]+":"+chartVersion[i]+"\n"
                    }
                    println(changed)
                }
            }
        }

        stage('Load whitelist') {
            when {
                expression { chartNameList.size() > 0 }
            }
            steps {
                script {
                    def data = readYaml file: "technicals/input_sanity_check_whitelist.yaml"
                    whiteListServices = data.services
                    echo ("whiteListServices ${whiteListServices}")
                    if ( data.repos) {
                        whiteListRepos = data.repos
                    }
                    echo ("whiteListRepos ${whiteListRepos}")
                }
            }
        }

        stage('Trigger input-sanity-check') {
            steps {
                catchError(buildResult: 'FAILURE', stageResult: 'FAILURE' ) {
                    script {
                        dir ('input_sanity_check_logs'){
                            if (chartNameList.size() == 0) {
                                echo ("No helm chart change, no input-sanity-check will be triggered")
                            }
                            else {
                                int i = 0
                                def result = true
                                chartNameList.each { chartName ->
                                    echo "The CHART_NAME ${chartName} not in the input sanity check whitelist ${ !whiteListServices.contains(chartName)}"
                                    echo "The repository ${chartRepoList[i].substring(chartRepoList[i].lastIndexOf("/")+1)} not in the input sanity check whitelist ${!whiteListRepos.contains(chartRepoList[i].substring(chartRepoList[i].lastIndexOf("/")+1))}"
                                    echo ""
                                    if (!whiteListServices.contains(chartName) && !whiteListRepos.contains(chartRepoList[i].substring(chartRepoList[i].lastIndexOf("/")+1))) {
                                        def sanityBuild = null
                                        try {
                                            sanityBuild = build (job: "input-sanity-check", parameters: [
                                            booleanParam(name: 'dry_run', value: false),
                                            stringParam(name: 'CHART_NAME', value: chartName),
                                            stringParam(name: 'CHART_REPO', value: chartRepoList[i]),
                                            stringParam(name: 'CHART_VERSION', value: chartVersion[i]),
                                            stringParam(name: 'GERRIT_REFSPEC', value: params.GERRIT_REFSPEC),
                                            stringParam(name: 'SPINNAKER_TRIGGER_URL', value: params.SPINNAKER_TRIGGER_URL),
                                            stringParam(name: 'REPOSITORY', value: params.REPOSITORY),
                                            stringParam(name: 'PIPELINE_NAME', value: params.PIPELINE_NAME),
                                            stringParam(name: 'SPINNAKER_ID', value: params.SPINNAKER_ID)
                                            ], wait: true, propagate: false)
                                        }
                                        catch (Exception e) {
                                            echo ("Input-sanity-check for ${chartName} failed with exception : ${e}")
                                            result = false
                                        }
                                        dir (chartName) {
                                            copyArtifacts fingerprintArtifacts: true, projectName: "input-sanity-check", selector: specific("${sanityBuild.number}")
                                        }
                                        if (sanityBuild.result != 'SUCCESS' ) {
                                            echo ("Input-sanity-check for ${chartName} failed")
                                            result = false
                                        }
                                    }
                                    i++
                                }
                                if (!result) {
                                    error("Input-sanity-check failed")
                                }
                            }
                        }
                    }
                }
            }
        }

        stage('Trigger eea-3pp-list-check') {
            steps {
                catchError(buildResult: 'FAILURE', stageResult: 'FAILURE' ) {
                    script {
                        dir ('eea_3pp_list_check_logs'){
                            if (chartNameList.size() == 0) {
                                echo ("No helm chart change, no eea-3pp-list-check will be triggered")
                            }
                            else {
                                int i = 0
                                def result = true
                                chartNameList.each { chartName ->
                                    echo "chartName not in whitelist ${ !whiteListServices.contains(chartName)}"
                                    echo "repo not in whitelist ${ !whiteListRepos.contains(chartRepoList[i].substring(chartRepoList[i].lastIndexOf("/")+1))}"
                                    if (!whiteListServices.contains(chartName) && !whiteListRepos.contains(chartRepoList[i].substring(chartRepoList[i].lastIndexOf("/")+1))) {
                                        def list3ppBuild = null
                                        try {
                                            list3ppBuild = build (job: "eea-3pp-list-check", parameters: [
                                            booleanParam(name: 'dry_run', value: false),
                                            stringParam(name: 'CHART_NAME', value: chartName),
                                            stringParam(name: 'CHART_REPO', value: chartRepoList[i]),
                                            stringParam(name: 'CHART_VERSION', value: chartVersion[i]),
                                            stringParam(name: 'SPINNAKER_TRIGGER_URL', value: params.SPINNAKER_TRIGGER_URL),
                                            stringParam(name: 'PIPELINE_NAME', value: params.PIPELINE_NAME),
                                            stringParam(name: 'SPINNAKER_ID', value: params.SPINNAKER_ID)
                                            ], wait: true, propagate: false)
                                        }
                                        catch (Exception e) {
                                            echo ("eea-3pp-list-check for ${chartName} failed with exception : ${e}")
                                            result = false
                                        }
                                        dir (chartName) {
                                            copyArtifacts fingerprintArtifacts: true, projectName: "eea-3pp-list-check", selector: specific("${list3ppBuild.number}")
                                        }
                                        if (list3ppBuild.result == 'FAILURE' ) {
                                            echo ("eea-3pp-list-check for ${chartName} failed")
                                            result = false
                                        }
                                    }
                                    i++
                                }
                                if (!result) {
                                    error("eea-3pp-list-check failed")
                                }
                            }
                        }
                    }
                }
            }
        }

        stage('Check if waiting for log collect necessary') {
            when {
                expression { params.GERRIT_REFSPEC }
            }
            steps {
                script {
                    def changedFilesList = gitcnint.getGerritQueryPatchsetChangedFiles(params.GERRIT_REFSPEC)
                    echo "changedFilesList ${changedFilesList}"
                    def newList = changedFilesList.findAll { it != 'eric-eea-int-helm-chart/Chart.yaml' }
                    if (newList.size() > 0) {
                        waitForClusterLogCollect = true
                    }
                    else if (changedFilesList.findAll { it = 'eric-eea-int-helm-chart/Chart.yaml' }) {
                        def data = readYaml file: "${WORKSPACE}/technicals/coverage_report/input_sanity_check_whitelist.yaml"
                        chartNameList.each { chartName ->
                            if (whiteListServices.contains(chartName)
                                || data.validations.non_pra_whitelist.services?.contains(chartName)
                                || data.validations.non_pra_upgrade_whitelist.services?.contains(chartName)
                                || data.validations.non_pra_with_helm_whitelist.services?.contains(chartName)
                                || data.validations.non_pra_upgrade_with_helm_whitelist.services?.contains(chartName)
                            ) {
                                waitForClusterLogCollect = true
                            }
                        }
                    }
                }
            }
        }

        stage('Archive artifacts') {
            steps {
                script {
                    sh "echo 'WAIT_FOR_CLUSTER_LOG_COLLECTOR_RESULT=${waitForClusterLogCollect}' >> artifact.properties"
                    archiveArtifacts artifacts: 'artifact.properties' , allowEmptyArchive: true, fingerprint: true
                    archiveArtifacts artifacts: 'input_sanity_check_logs/**', allowEmptyArchive: true, fingerprint: true
                    archiveArtifacts artifacts: 'eea_3pp_list_check_logs/**', allowEmptyArchive: true, fingerprint: true
                }
            }
        }
    }
    post {
        always {
            script {
                postStage(stageCommentList,stageResultsInfo)
           }
        }
        failure {
            script {
                if(params.GERRIT_REFSPEC != '') {
                    env.GERRIT_MSG = "Build Failed ${BUILD_URL}: FAILURE"
                    sendMessageToGerrit(params.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }
        success {
            script {
                if(params.GERRIT_REFSPEC != '') {
                    env.GERRIT_MSG = "Build Successful ${BUILD_URL}: SUCCESS"
                    sendMessageToGerrit(params.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }
        cleanup {
            cleanWs()
        }
    }
}

def postStage(def stageCommentList,def stageResultsInfo){
    try {
        archiveArtifacts artifacts: 'cnint/.bob/check-helm/design-rule-check-report.html', allowEmptyArchive: true
        archiveArtifacts artifacts: "cnint/.bob/*.html", allowEmptyArchive: true
        cmutils.generateStageResultsHtml(stageCommentList,stageResultsInfo)
    }
    catch (err) {
            echo "Caught: ${err}"
    }
}

def parseFile(lines) {
    def entries = [:]
    def currentName, currentRepository, currentVersion

    lines.each { line ->
        def (key, value) = line.split(": ").collect { it.trim() }

        switch (key) {
            case "name":
                currentName = value
                break
            case "repository":
                currentRepository = value
                break
            case "version":
                currentVersion = value
                if (currentName && currentRepository && !currentRepository.contains("-gs-")) {
                    entries[currentName] = [repo: currentRepository, version: currentVersion]
                }
                currentName = null
                currentRepository = null
                currentVersion = null
                break
        }
    }
    return entries
}

def compare_chart_list(oldEntries,newEntries){
    def nameList = []
    def repoList = []
    def versionList = []
    newEntries.each { name, data ->
        if (oldEntries[name] && oldEntries[name].version == data.version) {return}
        nameList << name
        repoList << data.repo
        versionList << data.version
    }
    return [nameList,repoList,versionList]
}

def getLastNCharacters(String str, int n){
  return n > str?.size() ? null : n ? str[-n..-1] : ''
}

def removeLastNCharacters(String str, int n) {
    if(str != null && !str.trim().isEmpty()) {
        return str.substring(0, str.length() - n);
    }
    return str;
}
