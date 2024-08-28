@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.CommonUtils
import com.ericsson.eea4.ci.GlobalVars
import com.ericsson.eea4.ci.ClusterLockUtils
import com.ericsson.eea4.ci.ClusterLogUtils
import com.ericsson.eea4.ci.Artifactory
import groovy.transform.Field
import com.ericsson.eea4.ci.UtfTrigger2
import com.ericsson.eea4.ci.EEA_Robot

@Field def gitmeta = new GitScm(this, 'EEA/project-meta-baseline')
@Field def gitjd = new GitScm(this, 'EEA/jenkins-docker')
@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def giteea4rv = new GitScm(this, 'EEA/eea4-rv')
@Field def gitdeployer = new GitScm(this, 'EEA/deployer')
@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def cmutils = new CommonUtils(this)
@Field def globalVars = new GlobalVars()
@Field def clusterLogUtilsInstance = new ClusterLogUtils(this)
@Field def arm = new Artifactory(this, "https://arm.seli.gic.ericsson.se/", "API_TOKEN_EEA")
@Field def utf = new UtfTrigger2(this)
@Field def clusterLockUtils =  new ClusterLockUtils(this)

@Field def CMA_MODE__HELM_VALUES = "true"
@Field def CMA_MODE__HELM_VALUES_AND_CMA_CONF = "false"

@Field def CMA_MODE_IS_HELM = "HELM"
@Field def CMA_MODE_IS_HELM_AND_CMA = "HELM_AND_CMA"

def cluster_lock //for clusterLockParamsMap entry
def credentialToImportXml
def stageResults = [:]
def stageResultsInfo = [:]
def stageCommentList = [:]
def spotfire_install_job
def link_spotfire_platform_to_eea_job
def testExecutionJob

@NonCPS
def createUsernamePasswordCredentialXml (id, username, password) {
    xmlTemplate = """
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>my-credentials-example-id</id>
  <description>This is an example from REST API</description>
  <username>admin</username>
  <password>
    <secret-redacted/>
  </password>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
    """
    def xmlData = new XmlSlurper().parseText(xmlTemplate)
    xmlData.id.replaceBody "${id}"
    xmlData.description.replaceBody "${id}"
    xmlData.username.replaceBody "${username}"
    xmlData.password.replaceBody "${password}"
    updatedXmlData = groovy.xml.XmlUtil.serialize(xmlData)
    return updatedXmlData
}

@NonCPS
def parseJson(def json) {
    new groovy.json.JsonSlurperClassic().parseText(json)
}

void defineJenkinsAgentLabel() {
    script {
        env.AGENT_LABEL = "productci"
        if ( env.CSAR_VERSION ) {
            lock('set-offline-common-upgrade-label') {
                env.PARALLEL_JENKINS_URL = "https://seliius27102.seli.gic.ericsson.se:8443"
                env.PARALLEL_JENKINS_CREDENTIALS_ID = 'test-jenkins-token' // Test Jenkins API Token Credential
                if (env.MAIN_BRANCH != 'master') {
                    env.PARALLEL_JENKINS_URL = "https://seliius27190.seli.gic.ericsson.se:8443"
                    env.PARALLEL_JENKINS_CREDENTIALS_ID = 'jenkins-api-token' // Master Jenkins API Token Credential
                }
                echo "Checking agents with the common offline upgrade running on ${env.PARALLEL_JENKINS_URL} Jenkins instance"
                withCredentials([usernamePassword(credentialsId: env.PARALLEL_JENKINS_CREDENTIALS_ID, usernameVariable: 'JENKINS_USER', passwordVariable: 'JENKINS_PASSWORD')]) {
                    env.AGENT_LABEL = "common-offline-upgrade-${env.JOB_NAME}-${env.BUILD_NUMBER}"
                    def parallelJenkinsAgentsJson = ''
                    def currentjenkinsAvailableAgent = ''
                    def agentLabelUpdated = false
                    while (!agentLabelUpdated) {
                        parallelJenkinsAgentsJson = sh(script: '''
                            curl -s "$PARALLEL_JENKINS_URL"/computer/api/json --user $JENKINS_USER:$JENKINS_PASSWORD --insecure
                        ''', returnStdout: true).trim()
                        parallelJenkinsAgentsJson = parseJson(parallelJenkinsAgentsJson)
                        parallelJenkinsAgentsList = []
                        parallelJenkinsAgentsJson.computer.each { agent ->
                            if ( agent.assignedLabels.name.find { agentLabels -> agentLabels.contains('common-offline-upgrade')} ) {
                                parallelJenkinsAgentsList.add(agent.displayName)
                            }
                        }
                        echo "Offline upgrade can't be executed on the following agents: ${parallelJenkinsAgentsList}. common-offline-upgrade-.* label for these nodes found on ${env.PARALLEL_JENKINS_URL} Jenkins instance"
                        currentjenkinsAvailableAgent = Jenkins.get().computers.find { !it.isOffline() && it.node.labelString.contains('productci') && !it.node.labelString.contains('common-offline-upgrade') && !parallelJenkinsAgentsList.contains(it.node.selfLabel.name) }
                        if (currentjenkinsAvailableAgent) {
                            println currentjenkinsAvailableAgent.node.selfLabel.name
                            env.NODE_NAME = currentjenkinsAvailableAgent.node.selfLabel.name
                            env.OLD_NODE_LABELS = currentjenkinsAvailableAgent.node.labelString
                            echo "Current labels for the ${env.NODE_NAME} node: ${env.OLD_NODE_LABELS}"
                            currentjenkinsAvailableAgent.node.setLabelString("${env.OLD_NODE_LABELS}" + " ${env.AGENT_LABEL}")
                            env.NEW_NODE_LABELS = currentjenkinsAvailableAgent.node.labelString
                            echo "Updated labels for the ${env.NODE_NAME} node: ${env.NEW_NODE_LABELS}"
                            agentLabelUpdated = true
                        } else {
                            echo "An agent that meets the conditions on the current Jenkins was not found. Current agents statuses:"
                            Jenkins.get().computers.each { currentJenkinsAgent ->
                                echo "Name: ${currentJenkinsAgent.node.selfLabel.name}\nLabels: ${currentJenkinsAgent.node.labelString}\nIs online: ${currentJenkinsAgent.isOffline()}"
                            }
                            echo "Required conditions: online, contains 'productci' label, doesn't contain 'common-offline-upgrade-.*' label, not in the parallel Jenkins offline upgrade list: ${parallelJenkinsAgentsList}"
                            sleep(time:5, unit:"MINUTES")
                        }
                    }
                }
            }
        }
        echo "Jenkins agent with the ${env.AGENT_LABEL} label will be used for the build"
    }
}

node('master') {
    stage('Define Jenkins agent label') {
        defineJenkinsAgentLabel()
    }
}

pipeline {
    options {
        ansiColor('xterm')
        buildDiscarder(logRotator(daysToKeepStr: "21", artifactDaysToKeepStr: "7"))
        skipDefaultCheckout()
    }
    agent {
        node {
            label "${env.AGENT_LABEL}"
        }
    }
    parameters {
        string(name: 'CHART_NAME', description: 'Chart name e.g.: eric-ms-b', defaultValue: '')
        string(name: 'CHART_REPO', description: 'Chart repo e.g.: https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm', defaultValue: '')
        string(name: 'CHART_VERSION', description: 'Chart version e.g.: 1.0.0-1', defaultValue: '')
        string(name: 'INT_CHART_NAME_PRODUCT', description: 'Chart name e.g.: eric-ms-b', defaultValue: 'eric-eea-int-helm-chart')
        string(name: 'INT_CHART_REPO_PRODUCT', description: 'Chart repo e.g.: https://arm.seli.gic.ericsson.se/artifactory/proj-eea-ci-internal-helm/', defaultValue: 'https://arm.seli.gic.ericsson.se/artifactory/proj-eea-ci-internal-helm/')
        string(name: 'INT_CHART_VERSION_PRODUCT', description: 'Version to upgrade. Format: 1.0.0-1 Set value "latest" to automaticaly define and use latest INT chart version', defaultValue: '')
        string(name: 'SEP_CHART_NAME', description: 'SEP helm chart name', defaultValue: 'eric-cs-storage-encryption-provider')
        string(name: 'SEP_CHART_REPO', description: 'SEP helm chart repo', defaultValue: 'https://arm.sero.gic.ericsson.se/artifactory/proj-adp-rs-storage-encr-released-helm')
        string(name: 'NSEEA', description: 'EEA4 namespace', defaultValue: 'eric-eea-ns')
        string(name: 'NSCRD', description: 'CRD namespace', defaultValue: 'eric-crd-ns')
        string(name: 'UTF_PRODUCT_NAMESPACE', description: 'UTF product namespace', defaultValue: 'eric-eea-ns')
        string(name: 'CSAR_NAME', description: 'CSAR name e.g.: csar-package', defaultValue: 'csar-package')
        string(name: 'CSAR_REPO', description: 'CSAR repo e.g.: https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-eea-drop-generic-local', defaultValue: 'https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-generic-local/')
        string(name: 'CSAR_VERSION', description: 'CSAR version e.g.: 1.0.0-1 Set value "latest" to automaticaly define and use latest CSAR version', defaultValue: '')
        string(name: 'DOCKER_EXECUTOR_IMAGE_NAME', description: 'jenkins-docker image name', defaultValue: 'armdocker.rnd.ericsson.se/proj-eea-drop/eea-jenkins-docker')
        string(name: 'DOCKER_EXECUTOR_IMAGE_VERSION', description: 'jenkins-docker image version', defaultValue: '')
        string(name: 'DEPLOYER_PSP_URL', description: 'DEPLOYER product specific pipeline package URL', defaultValue: 'https://arm.seli.gic.ericsson.se/')
        string(name: 'DEPLOYER_PSP_REPO', description: 'DEPLOYER product specific pipeline package arm repo', defaultValue: 'proj-eea-drop-generic-local')
        string(name: 'DEPLOYER_PSP_NAME', description: 'DEPLOYER product specific pipeline package name', defaultValue: 'eea-deployer')
        string(name: 'DEPLOYER_PSP_VERSION', description: 'DEPLOYER product specific pipeline package version. Specify if DEPLOYER_GERRIT_REFSPEC is empty', defaultValue: '')
        string(name: 'DEPLOYER_GERRIT_REFSPEC', description: 'EEA/deployer repo Gerrit Refspec. Specify if DEPLOYER_PSP_VERSION is empty', defaultValue: '')
        string(name: 'GERRIT_REFSPEC', description: 'Gerrit Refspec of the cnint, for example refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'META_GERRIT_REFSPEC', description: 'Gerrit Refspec of the project-meta-baseline, for example refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'PIPELINE_NAME', description: 'The spinnaker pipeline name', defaultValue: 'eea-application-staging')
        string(name: 'SPINNAKER_TRIGGER_URL', description: 'Spinnaker pipeline triggering url', defaultValue: '')
        string(name: 'SPINNAKER_ID', description: "The spinnaker execution's id", defaultValue: '')
        booleanParam(name: 'SKIP_COLLECT_LOG', description: 'skip the log collection pipeline', defaultValue: false)
        booleanParam(name: 'SKIP_CLEANUP', description: 'skip the cleanup pipeline.', defaultValue: false)
        string(name: 'WAIT_FOR_CLUSTER_LOG_COLLECTOR_RESULT', description: 'Wait for cluster log collector job result to be sure that new docker images work properly', defaultValue: "false")
        string(name: 'CLUSTER_NAME', description:'The cluster that should be locked for upgrade', defaultValue: '')
        string(name: 'UPGRADE_CLUSTER_LABEL', description: 'The cluster resource label that should be locked for upgrade', defaultValue: "${globalVars.resourceLabelUpgrade}")
        string(name: 'CUSTOM_CLUSTER_LABEL', description: 'If CUSTOM_CLUSTER_LABEL is set, we have to set that label at the end of the pipeline executions, and FORCE skip the collect log and cleanup !!!', defaultValue: '')
        string(name: 'lock_start', description: 'Locking start timestamp, will be overwritten', defaultValue: '')
        string(name: 'lock_end', description: 'Locking start timestamp, will be overwritten', defaultValue: '')
        string(name: 'INT_CHART_NAME_META', description: 'Chart name e.g.: eric-ms-b', defaultValue: 'eric-eea-ci-meta-helm-chart')
        string(name: 'INT_CHART_REPO_META', description: 'Chart repo e.g.: https://arm.seli.gic.ericsson.se/artifactory/proj-eea-ci-internal-helm/', defaultValue: 'https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/')
        string(name: 'INT_CHART_VERSION_META', description: 'meta-baseline version to install. Format: 1.0.0-1', defaultValue: 'latest')
        string(name: 'DIMTOOL_OUTPUT_REPO_URL', description: "The url of the artifactory", defaultValue: 'https://arm.seli.gic.ericsson.se')
        string(name: 'DIMTOOL_OUTPUT_REPO', description: "Repo of the chart eg. proj-eea-reports-generic-local/dimtool/prod_ci_artifacts/", defaultValue: 'proj-eea-reports-generic-local/dimtool/prod_ci_artifacts/')
        string(name: 'DIMTOOL_OUTPUT_NAME', description: 'Chart name e.g.: eea-application-staging-baseline-prepare-12695/eea4-dimensioning-tool-output.zip', defaultValue: '')
        choice(name: 'DEPLOY_SH_BASH_ARGS', choices: ['', '-x'], description: 'Optional argument(s) to pass when executing upgrade.sh. E.g. -x can be used for debugging purposes')
        choice(name: 'BUILD_RESULT_WHEN_NELS_CHECK_FAILED', choices: ['FAILURE', 'SUCCESS'], description: 'build result when the Check NELS availability failed')
        string(name: 'ADP_APP_STAGING_GERRIT_REFSPEC_FOR_SF_INSTALL',description: 'Gerrit refspec of the adp-app-staging repo e.g.: refs/changes/87/4641487/1 . Will pass to Spotfire install job', defaultValue: '')
        string(name: 'HELM_AND_CMA_VALIDATION_MODE',
        description: """
        Use HELM values or HELM values and CMA configurations. valid options:
<table>
  <tr>
    <th>Value</th>
    <th ALIGN=left>Comment</th>
  </tr>
  <tr>
    <td>"true" or "HELM"</td>
    <td>use helm values, cma is diabled</td>
  </tr>
  <tr>
    <td>"false" or "HELM_AND_CMA"</td>
    <td>use helm values and load CMA configurations</td>
  </tr>
</table>
            """,
        defaultValue: 'true')
    }

    environment {
        JENKINS_CONTAINER_LOGFILE = "jenkins_docker_container.log"
        JENKINS_DOCKER_HOSTS_FILE = "${env.WORKSPACE}/hosts"
        JENKINS_PORT_LOCKING = "${env.NODE_NAME}" + "-port-reservation"
        CLUSTER_DOCKER_REGISTRY_CERT = "${env.WORKSPACE}/ca.crt"
        TLS_PROXY_NAME = "eric-tm-tls-proxy-ev"
        TLS_PROXY_REPO = "https://arm.sero.gic.ericsson.se/artifactory/proj-adp-tm-tls-proxy-ev-released-helm"
        UTF_PRE_ACTIVITIES_TEST_EXECUTION_ID = 1111 + "${env.BUILD_NUMBER}"
        UTF_PRE_ACTIVITIES_META_FILTER = "@startRefData or @startData"
        UTF_PRE_ACTIVITIES_TEST_TIMEOUT = 2700
        UTF_PRE_ACTIVITIES_TEST_LOGFILE = "utf_upgrade-pre-activities.log"
        UTF_PRE_ACTIVITIES_TEST_NAME = "Upgrade Pre-activities"

        TEST_AFTER_UPGRADE_JOB = "eea-common-product-test-after-deployment"
        SPOTFIRE_ASSET_INSTALL_ASSIGN_LABEL_WRAPPER_JOB_NAME = "spotfire-asset-install-assign-label-wrapper"
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

        stage('Check params') {
            steps {
                checkBuildParameters()
            }
        }

        stage('Cleanup workspace') {
            steps {
                script {
                    cleanWs()
                }
            }
        }

        stage('Build started message to gerrit') {
            when {
                expression {params.GERRIT_REFSPEC || params.DEPLOYER_GERRIT_REFSPEC || params.META_GERRIT_REFSPEC}
            }
            steps {
                sendBuildStartedMessageToGerrit()
            }
        }

        stage('Checkout cnint master') {
            steps {
                checkoutCnintMaster()
            }
        }

        stage('Extract integration chart data') {
            steps {
                extractIntChartData()
            }
        }

        stage('Checkout project-meta-baseline') {
            steps {
                checkoutMeta()
            }
        }

        stage('Ruleset change checkout') {
            when {
                expression {params.GERRIT_REFSPEC && params.PIPELINE_NAME != 'eea-product-ci-meta-baseline-loop'}
            }
            steps {
                loggedStage() {
                    rulesetChangeCheckout()
                }
            }
        }

        stage('Checkout adp-app-staging') {
            steps {
                dir('adp-app-staging-full-checkout') {
                    script {
                        gitadp.checkout(env.MAIN_BRANCH,'')
                    }
                }
                archiveTechnicalsRulesetDirs()
            }
        }

        stage('Check if port locking resource name exists'){
            steps{
                checkPortLockingResourceName(stageResults)
            }
        }

        stage('Resource locking') {
            stages {
                stage('Wait for cluster') {
                    when {
                        expression { params.CLUSTER_NAME == '' }
                    }
                    steps {
                        script {
                            waitForCluster(stageResults)
                        }
                    }
                }

                stage('Lock') {
                    options {
                            lock resource: "${params.CLUSTER_NAME}", label: "${params.UPGRADE_CLUSTER_LABEL}", quantity: 1, variable: 'system'
                    }
                    stages {
                        stage('Log lock') {
                            steps {
                                echo "Locked cluster: $system"
                                script {
                                    logLock()
                                }
                            }
                        }

                        stage('Get installed baseline params from cluster') {
                            steps {
                                loggedStage() {
                                    getInstalledBaselineParamsFromCluster()
                                }
                            }
                        }

                        stage('Set description (SpinnakerURL and versions)') {
                            steps {
                                setDescription()
                            }
                        }

                        stage('Run health check before upgrade') {
                            steps {
                                loggedStage() {
                                    runHealthCheck(stageResults, "${globalVars.waitForPodsBeforeUpgrade}")
                                }
                            }
                        }

                        stage("Test tool and Spotfire deploy") {
                            parallel {
                                stage('utf and data loader deploy') {
                                    steps {
                                        loggedStage() {
                                            utfAndDataLoaderDeploy()
                                        }
                                    }
                                }
                                stage('Execute spotfire deployment') {
                                    steps {
                                        loggedStage() {
                                            executeSpotfireDeployment(stageResults,stageCommentList,spotfire_install_job)
                                        }
                                    }
                                }
                            }
                        }

                        stage('Init vars and get charts') {
                            steps {
                                loggedStage() {
                                    initVarsAndGetCharts()
                                }
                            }
                        }

                        stage('Check NELS availability') {
                            steps {
                                loggedStage() {
                                    checkNelsAvailabilityStage()
                                }
                            }
                        }

                        stage('init UTF Test Variables') {
                            steps {
                                script {
                                    utf.initUtfTestVariables(globalVars)
                                }
                            }
                        }

                        stage('Execute Pre-activites-upgrade check') {
                            steps {
                                loggedStage() {
                                    runPreActivities()
                                }
                            }
                            post {
                                always {
                                    script {
                                        archiveArtifacts artifacts: "stage_${UTF_PRE_ACTIVITIES_TEST_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                                        stageCommentList[env.UTF_PRE_ACTIVITIES_TEST_NAME] = [" <a href=\"${env.BUILD_URL}/artifact/${env.UTF_PRE_ACTIVITIES_TEST_LOGFILE}\">${env.UTF_PRE_ACTIVITIES_TEST_LOGFILE}</a>"]
                                    }
                                }
                            }
                        }

                        stage('Get Jenkins jobs XML') {
                            when {
                                expression { stageResults.find{ it.key == "${PREVIOUS_STAGE}" }?.value == "SUCCESS" }
                            }
                            steps {
                                loggedStage() {
                                    getJenkinsJobsXML(stageResults)
                                }
                            }
                        }

                        stage('Prepare upgrade values files') {
                            when {
                                expression { stageResults.find{ it.key == "${PREVIOUS_STAGE}" }?.value == "SUCCESS" }
                            }
                            steps {
                                loggedStage() {
                                    prepareUpgradeValues(stageResults)
                                }
                            }
                            post {
                                failure {
                                    script {
                                        echo 'ERROR: \"Prepare upgrade values files\" stage failed'
                                    }
                                }
                            }
                        }

                        stage('Get eric-eea-utils image from the cnint') {
                            when {
                                expression { stageResults.find{ it.key == "${PREVIOUS_STAGE}" }?.value == "SUCCESS" && env.UPGRADE_TYPE == "ONLINE" }
                            }
                            steps {
                                loggedStage() {
                                    getUtilsImage(stageResults)
                                }
                            }
                        }

                        stage('Download CSAR package') {
                            when {
                                expression { stageResults.find{ it.key == "${PREVIOUS_STAGE}" }?.value == "SUCCESS" && env.UPGRADE_TYPE == "OFFLINE" }
                            }
                            steps {
                                loggedStage() {
                                    downloadCsarPackage(stageResults)
                                }
                            }
                        }

                        stage('Get cluster docker registry connection info') {
                            when {
                                expression { stageResults.find{ it.key == "${PREVIOUS_STAGE}" }?.value == "SUCCESS" && env.UPGRADE_TYPE == "OFFLINE" }
                            }
                            steps {
                                loggedStage() {
                                    getDockerRegistryConnectionInfo(stageResults)
                                }
                            }
                        }

                        stage('Get jenkins-docker image version') {
                            when {
                                expression { stageResults.find{ it.key == "${PREVIOUS_STAGE}" }?.value == "SUCCESS" }
                            }
                            steps {
                                loggedStage() {
                                    getJenkinsDockerImageVersion(stageResults)
                                }
                            }
                        }

                        stage('Run DinD and Jenkins docker') {
                            when {
                                expression { stageResults.find{ it.key == "${PREVIOUS_STAGE}" }?.value == "SUCCESS" }
                            }
                            steps {
                                loggedStage() {
                                    lockResourceAndRunDockers(stageResults)
                                }
                            }
                            post {
                                always {
                                    resetLockableResource("${env.JENKINS_PORT_LOCKING}", true, true)
                                }
                            }
                        }

                        stage('Get jenkins-cli.jar') {
                            when {
                                expression { stageResults.find{ it.key == "${PREVIOUS_STAGE}" }?.value == "SUCCESS" }
                            }
                            steps {
                                loggedStage() {
                                    getJenkinsCli(stageResults)
                                }
                            }
                        }

                        stage('Import data into Jenkins docker') {
                            when {
                                expression { stageResults.find{ it.key == "${PREVIOUS_STAGE}" }?.value == "SUCCESS" }
                            }
                            steps {
                                loggedStage() {
                                    importDataIntoJenkinsDocker(stageResults)
                                }
                            }
                        }

                        stage('Execute Ingestion') {
                            when {
                                expression { stageResults.find{ it.key == "${PREVIOUS_STAGE}" }?.value == "SUCCESS" && env.UPGRADE_TYPE == "OFFLINE" }
                            }
                            steps {
                                loggedStage() {
                                    executeIngestion(stageResults)
                                }
                            }
                            post {
                                always {
                                    getJenkinsDockerArtifacts("${env.EEA_SOFTWARE_INGESTION_JOB}")
                                }
                            }
                        }

                        stage('Execute Preparation') {
                            when {
                                expression { stageResults.find{ it.key == "${PREVIOUS_STAGE}" }?.value == "SUCCESS" && env.UPGRADE_TYPE == "OFFLINE" }
                            }
                            steps {
                                loggedStage() {
                                    executePreparation(stageResults)
                                }
                            }
                            post {
                                always {
                                    getJenkinsDockerArtifacts("${env.EEA_SOFTWARE_PREPARATION_JOB}")
                                }
                            }
                        }

                        stage('Execute Upgrade') {
                            when {
                                expression { stageResults.find{ it.key == "${PREVIOUS_STAGE}" }?.value == "SUCCESS" }
                            }
                            steps {
                                loggedStage() {
                                    executeUpgrade(stageResults)
                                }
                            }
                            post {
                                always {
                                    getJenkinsDockerArtifacts("${env.EEA_SOFTWARE_UPGRADE_JOB}")
                                    script{
                                        stageCommentList[env.STAGE_NAME] = [" <a href=\"${env.BUILD_URL}/artifact/execute_upgrade.log\">execute_upgrade.log</a>"]
                                    }
                                }
                                failure {
                                    script {
                                        clusterLogUtilsInstance.getResourceCapacity(env.CLUSTER_NAME)
                                    }
                                }
                            }
                        }

                        stage('Apply stream-aggregator configmap') {
                            when {
                                expression { stageResults.find{ it.key == "${PREVIOUS_STAGE}" }?.value == "SUCCESS" }
                            }
                            steps {
                                loggedStage() {
                                    script {
                                        applyAggregatorConfigmap(stageResults)
                                    }
                                }
                            }
                        }

                        stage('Run health check after upgrade') {
                            when {
                                expression { stageResults.find{ it.key == "${PREVIOUS_STAGE}" }?.value == "SUCCESS" }
                            }
                            steps {
                                loggedStage() {
                                    runHealthCheck(stageResults, "${globalVars.waitForPodsAfterUpgrade}")
                                }
                            }
                        }

                        stage('Link Spotfire platform to EEA') {
                            when {
                                expression { stageResults.find{ it.key == "${PREVIOUS_STAGE}" }?.value == "SUCCESS" }
                            }
                            steps {
                                loggedStage() {
                                    linkSpotfirePlatformToEea(stageResults,stageCommentList,link_spotfire_platform_to_eea_job)
                                }
                            }
                        }

                        stage('Run CheckSpotfirePlatform health check') {
                            when {
                                expression { stageResults.find{ it.key == "${PREVIOUS_STAGE}" }?.value == "SUCCESS" }
                            }
                            steps {
                                script {
                                    clusterLogUtilsInstance.runHealthCheck("${globalVars.waitForPodsAfterInstall}", "${STAGE_NAME}", clusterCredentialID=env.CLUSTER_NAME, eeaHealthcheckCheckClasses='CheckSpotfirePlatform',  k8s_namespace='spotfire-platform')
                                }
                            }
                            post {
                                always {
                                    script {
                                        stageCommentList[STAGE_NAME] = ["<a href=\"${env.BUILD_URL}/artifact/check-pods-state-with-wait__stage_"+STAGE_NAME.replaceAll(' ', '_')+".log\">"+STAGE_NAME.replaceAll(' ', '_')+".log</a>"]
                                    }
                                }
                            }
                        }

                        stage('Load config json to CM-Analytics') {
                            when {
                                expression { params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE__HELM_VALUES_AND_CMA_CONF || params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE_IS_HELM_AND_CMA }
                            }
                            steps {
                                loggedStage() {
                                    load_config_json_to_CMAnalytics(stageResults)
                                }
                            }
                        }

                        stage('Run health checks after CM-Analytics config load') {
                            when {
                                expression { params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE__HELM_VALUES_AND_CMA_CONF || params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE_IS_HELM_AND_CMA }
                            }
                            steps {
                                loggedStage() {
                                    runHealthChecks(stageResults, "${globalVars.waitForPodsAfterUpgrade}")
                                }
                            }
                        }

                        stage ('Call test job') {
                            when {
                                expression { stageResults.find{ it.key == "${PREVIOUS_STAGE}" }?.value == "SUCCESS" }
                            }
                            steps {
                                loggedStage() {
                                    runTestsAfterUpgrade(stageResults,stageCommentList,testExecutionJob)
                                }
                            }
                        }
                    }
                    post {
                        always {
                            script {
                                // Stop and remove Jenkins, DinD container, related network, volumes and images
                                cleanupJenkinsDockerEnv()
                                collectBuildLogs()
                            }
                        }
                    }
                }
            }
            post {
                always {
                    postStageAfterResourceLock()
                }
            }
        }
        stage('Archive artifact.properties') {
            steps {
                // Archive artifact.properties so Spinnaker can read the parameters
                archiveArtifacts artifacts: 'artifact.properties', allowEmptyArchive: true
            }
        }
    }
    post {
        always {
            archiveArtifacts artifacts: "watches_count_indicators.log", allowEmptyArchive: true
            finalPostAlways(stageCommentList, stageResultsInfo)
        }
        cleanup {
            cleanWs()
        }
    }
}

def finalPostAlways(def stageCommentList, def stageResultsInfo){
    env.GERRIT_MSG = "Build result " + env.BUILD_URL + ": " + currentBuild.result
    if ( env.GERRIT_REFSPEC ) {
        sendMessageToGerrit(env.GERRIT_REFSPEC, env.GERRIT_MSG)
    }
    if ( env.DEPLOYER_GERRIT_REFSPEC ) {
        sendMessageToGerrit(env.DEPLOYER_GERRIT_REFSPEC, env.GERRIT_MSG)
    }
    if ( env.META_GERRIT_REFSPEC ) {
        sendMessageToGerrit(env.META_GERRIT_REFSPEC, env.GERRIT_MSG)
    }
    stageResultsInfo["RVROBOT_VERSION"] = env.RVROBOT_VERSION
    stageResultsInfo["UTF_DATASET_ID"] = env.UTF_DATASET_ID
    stageResultsInfo["UTF_REPLAY_SPEED"] = env.UTF_REPLAY_SPEED
    stageResultsInfo["UTF_REPLAY_COUNTL"] = env.UTF_REPLAY_COUNT
    stageResultsInfo["Baseline version"] = env.BASELINE_INT_CHART_VERSION
    stageResultsInfo["Baseline branch"] = env.BASELINE_GIT_BRANCH
    stageResultsInfo["Upgrade type"] = env.UPGRADE_TYPE
    cmutils.generateStageResultsHtml(stageCommentList,stageResultsInfo)
}

void checkBuildParameters() {
    script {
        currentBuild.description = ""
        if (!params.UPGRADE_CLUSTER_LABEL && !params.CLUSTER_NAME) {
            currentBuild.result = 'ABORTED'
            error("UPGRADE_CLUSTER_LABEL or CLUSTER_NAME must be specified")
        } else if (params.UPGRADE_CLUSTER_LABEL && params.CLUSTER_NAME) {
            currentBuild.result = 'ABORTED'
            error("Only one of UPGRADE_CLUSTER_LABEL or CLUSTER_NAME must be specified")
        }
        if (!params.INT_CHART_VERSION_PRODUCT && !params.CSAR_VERSION) {
            currentBuild.result = 'ABORTED'
            error("INT_CHART_VERSION_PRODUCT or CSAR_VERSION must be specified")
        } else if (params.INT_CHART_VERSION_PRODUCT && params.CSAR_VERSION) {
            currentBuild.result = 'ABORTED'
            error("Only one of INT_CHART_VERSION_PRODUCT or CSAR_VERSION must be specified")
        }
        else if (env.INT_CHART_VERSION_PRODUCT != 'latest') {
            if (!params.INT_CHART_NAME_PRODUCT) {
                error "INT_CHART_NAME should be specified!"
            }
            if (!params.INT_CHART_REPO_PRODUCT) {
                error "INT_CHART_REPO should be specified!"
            }
        }
        if (!params.INT_CHART_VERSION_META) {
            error "INT_CHART_VERSION_META should be specified!"
        }
        if (env.INT_CHART_VERSION_META != 'latest') {
            if (!params.INT_CHART_NAME_META) {
                error "INT_CHART_NAME_META should be specified!"
            }
            if (!params.INT_CHART_REPO_META) {
                error "INT_CHART_REPO_META should be specified!"
            }
        }
        if (params.INT_CHART_VERSION_PRODUCT) {
            env.UPGRADE_TYPE = "ONLINE"
        } else {
            env.UPGRADE_TYPE = "OFFLINE"
        }
        if ( (env.MAIN_BRANCH == 'master') && params.SKIP_CLEANUP && !params.CUSTOM_CLUSTER_LABEL) {
            currentBuild.result = 'ABORTED'
            error("CUSTOM_CLUSTER_LABEL must be specified when SKIP_CLEANUP is true")
        }

        if ( params.HELM_AND_CMA_VALIDATION_MODE != CMA_MODE__HELM_VALUES && params.HELM_AND_CMA_VALIDATION_MODE != CMA_MODE__HELM_VALUES_AND_CMA_CONF && params.HELM_AND_CMA_VALIDATION_MODE != CMA_MODE_IS_HELM && params.HELM_AND_CMA_VALIDATION_MODE != CMA_MODE_IS_HELM_AND_CMA ) {

            error "HELM_AND_CMA_VALIDATION_MODE \"${params.HELM_AND_CMA_VALIDATION_MODE}\" validation error. Valid options: CMA_MODE__HELM_VALUES:\"${CMA_MODE__HELM_VALUES}\" or \"${CMA_MODE_IS_HELM}\" CMA_MODE__HELM_VALUES_AND_CMA_CONF: \"${CMA_MODE__HELM_VALUES_AND_CMA_CONF}\" or \"${CMA_MODE_IS_HELM_AND_CMA}\""
        }
    }
}

void checkoutCnintMaster() {
    script {
        gitcnint.checkout('master', '')
        checkoutGitSubmodules()
        sh "echo 'CLUSTER='${env.CLUSTER_NAME} > artifact.properties"
    }
}

void extractIntChartData() {
    script {
        withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA')]) {
            if ( env.UPGRADE_TYPE == "ONLINE" ) {
                if ( env.INT_CHART_VERSION_PRODUCT == 'latest' ) {
                    def data = readYaml file: 'eric-eea-int-helm-chart/Chart.yaml'
                    env.INT_CHART_NAME_PRODUCT = data.name
                    env.INT_CHART_REPO_PRODUCT = "https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/"
                    env.INT_CHART_VERSION_PRODUCT = data.version
                }
            } else if ( env.UPGRADE_TYPE == "OFFLINE" ) {
                if ( env.CSAR_VERSION == 'latest' ) {
                    getLatestCsarVersion()
                }
                if ( env.CSAR_REPO.contains('proj-eea-drop') ) {
                    env.INT_CHART_REPO_PRODUCT = "https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/"
                }
                env.INT_CHART_NAME_PRODUCT = 'eric-eea-int-helm-chart'
                env.INT_CHART_VERSION_PRODUCT = env.CSAR_VERSION
            }
        }
        echo "env.INT_CHART_NAME_PRODUCT: ${env.INT_CHART_NAME_PRODUCT}"
        echo "env.INT_CHART_REPO_PRODUCT: ${env.INT_CHART_REPO_PRODUCT}"
        echo "env.INT_CHART_VERSION_PRODUCT: ${env.INT_CHART_VERSION_PRODUCT}"
    }
}

void checkoutMeta() {
    script {
        if ( params.META_GERRIT_REFSPEC ) {
            echo "META_GERRIT_REFSPEC: ${params.META_GERRIT_REFSPEC} is going to be checked out."
            gitmeta.checkoutRefSpec("${params.META_GERRIT_REFSPEC}", "FETCH_HEAD", 'project-meta-baseline')
        } else {
            echo "project-meta-baseline master will be checked out"
            gitmeta.checkout('master', 'project-meta-baseline')
        }
        dir('project-meta-baseline') {
            if ( env.INT_CHART_VERSION_META == 'latest' ) {
                def data = readYaml file: 'eric-eea-ci-meta-helm-chart/Chart.yaml'
                env.INT_CHART_NAME_META = data.name
                env.INT_CHART_REPO_META = 'https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm'
                env.INT_CHART_VERSION_META = data.version
            }
            env.DEPLOYER_CHART_VERSION_META = cmutils.extractSubChartData("eric-eea-deployer", "version", "${WORKSPACE}/project-meta-baseline/eric-eea-ci-meta-helm-chart","Chart.yaml")
            checkoutGitSubmodules()
            echo "env.INT_CHART_NAME_META: ${env.INT_CHART_NAME_META}"
            echo "env.INT_CHART_REPO_META: ${env.INT_CHART_REPO_META}"
            echo "env.INT_CHART_VERSION_META: ${env.INT_CHART_VERSION_META}"
            echo "DEPLOYER_CHART_VERSION_META: ${env.DEPLOYER_CHART_VERSION_META}"

            if ( !( params.DIMTOOL_OUTPUT_NAME && params.DIMTOOL_OUTPUT_NAME.trim() ) )
            {
                env.DATASET_NAME = cmutils.getDatasetVersion("eric-eea-ci-meta-helm-chart","values.yaml")
                sh "echo 'DATASET_NAME=${env.DATASET_NAME}' >> $WORKSPACE/artifact.properties"
                env.REPLAY_SPEED = cmutils.getDatasetReplaySpeed("eric-eea-ci-meta-helm-chart","values.yaml")
                sh "echo 'REPLAY_SPEED=${env.REPLAY_SPEED}' >> $WORKSPACE/artifact.properties"
                env.META_BASELINE_CHART_VERSION = cmutils.getChartVersion("eric-eea-ci-meta-helm-chart", "Chart.yaml")
                sh "echo 'META_BASELINE_CHART_VERSION=${env.META_BASELINE_CHART_VERSION}' >> $WORKSPACE/artifact.properties"
                env.UTF_CHART_NAME = cmutils.extractSubChartData("eric-eea-utf-application", "name", "eric-eea-ci-meta-helm-chart","Chart.yaml")
                sh "echo 'UTF_CHART_NAME=${env.UTF_CHART_NAME}' >> $WORKSPACE/artifact.properties"
                env.UTF_CHART_REPO = cmutils.extractSubChartData("eric-eea-utf-application", "repository", "eric-eea-ci-meta-helm-chart","Chart.yaml")
                sh "echo 'UTF_CHART_REPO=${env.UTF_CHART_REPO}' >> $WORKSPACE/artifact.properties"
                env.UTF_CHART_VERSION = cmutils.extractSubChartData("eric-eea-utf-application", "version", "eric-eea-ci-meta-helm-chart","Chart.yaml")
                sh "echo 'UTF_CHART_VERSION=${env.UTF_CHART_VERSION}' >> $WORKSPACE/artifact.properties"
            }
        }
    }
}

void getJenkinsJobsXML(stageResults) {
    catchError(buildResult: 'FAILURE', stageResult: 'FAILURE' ) {
        script {
            PREVIOUS_STAGE = "${STAGE_NAME}"
            try {
                gitjd.checkout('master', 'jenkins-docker')
                sh "mkdir -p ${env.WORKSPACE}/jenkins-jobs/"
                def executeXmlGenerator = false
                if(params.DEPLOYER_PSP_VERSION?.trim() && params.DEPLOYER_GERRIT_REFSPEC?.trim()) {
                    error "Only one of the DEPLOYER_PSP_VERSION or DEPLOYER_GERRIT_REFSPEC should be specified!"
                }
                if (params.DEPLOYER_GERRIT_REFSPEC?.trim()) {
                    gitdeployer.checkoutRefSpec('${DEPLOYER_GERRIT_REFSPEC}', 'FETCH_HEAD', 'deployer')
                    env.DEPLOYER_GIT_BRANCH = ""
                    env.DEPLOYER_GERRIT_REFSPEC = params.DEPLOYER_GERRIT_REFSPEC
                    executeXmlGenerator = true
                } else if (params.DEPLOYER_PSP_VERSION) {
                    //download-package
                    withCredentials([string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                        dir('deployer-workspace') {
                            env.PSP_PACKAGE = "${params.DEPLOYER_PSP_NAME}-${params.DEPLOYER_PSP_VERSION}.tar.gz"
                            arm.setUrl("${params.DEPLOYER_PSP_URL}", "${API_TOKEN_EEA}")
                            arm.setRepo("${params.DEPLOYER_PSP_REPO}")
                            arm.downloadArtifact( "${env.PSP_PACKAGE}", "${env.PSP_PACKAGE}")
                            sh """
                                tar -xf $PSP_PACKAGE
                                cp -r eea-deployer/product/jenkins/*.xml $WORKSPACE/jenkins-jobs/
                            """
                        }
                    }
                    //It is not needed to call eea-deployer-jenkins-docker-xml-generator as package contains necessary xml files
                    executeXmlGenerator = false
                } else {
                    env.DEPLOYER_GIT_BRANCH = env.DEPLOYER_CHART_VERSION_META ? env.DEPLOYER_CHART_VERSION_META : "master"
                    echo "DEPLOYER_GIT_BRANCH: ${env.DEPLOYER_GIT_BRANCH}"
                    env.DEPLOYER_GERRIT_REFSPEC = ""
                    gitdeployer.checkoutRefSpec("${env.DEPLOYER_GIT_BRANCH}", 'FETCH_HEAD', 'deployer')
                    executeXmlGenerator = true
                }
                if (executeXmlGenerator) {
                    xmlGeneratorBuildData = build job: "eea-deployer-jenkins-docker-xml-generator", parameters: [
                        stringParam(name: 'GIT_BRANCH', value: "${env.DEPLOYER_GIT_BRANCH}"),
                        stringParam(name: 'GERRIT_REFSPEC', value : "${env.DEPLOYER_GERRIT_REFSPEC}")
                    ], wait: true
                    env.XML_GENERATOR_BUILD_NUMBER = xmlGeneratorBuildData.number
                    copyArtifacts(
                        projectName: "eea-deployer-jenkins-docker-xml-generator",
                        selector: specific("${env.XML_GENERATOR_BUILD_NUMBER}"),
                        filter: "**/*.xml",
                        flatten: true,
                        target: "${env.WORKSPACE}/jenkins-jobs/",
                        fingerprintArtifacts: true
                    )
                    sh "cp -r ${env.WORKSPACE}/deployer/product/source/pipeline_package/eea-deployer ${env.WORKSPACE}/deployer-workspace/eea-deployer"
                }
                stageResults."${STAGE_NAME}" = "SUCCESS"
            } catch(err) {
                stageResults."${STAGE_NAME}" = "FAILURE"
                echo "Caught: ${err}"
                error "${STAGE_NAME} FAILED".toUpperCase()
            }
        }
    }
}

void utfAndDataLoaderDeploy() {
    script {
        def gerritRefspec
        if ( params.PIPELINE_NAME == 'eea-product-ci-meta-baseline-loop' ) {
            gerritRefspec = params.META_GERRIT_REFSPEC
        } else {
            gerritRefspec = 'master'
        }
        def utf_build = build job: "eea-product-ci-meta-baseline-loop-utf-and-data-loader-deploy", parameters: [
            booleanParam(name: 'dry_run', value: false),
            stringParam(name: 'INT_CHART_NAME', value: "${env.INT_CHART_NAME_META}"),
            stringParam(name: 'INT_CHART_REPO', value: "${env.INT_CHART_REPO_META}"),
            stringParam(name: 'INT_CHART_VERSION', value: "${INT_CHART_VERSION_META}"),
            stringParam(name: 'RESOURCE', value: "${env.CLUSTER_NAME}"),
            stringParam(name: 'GERRIT_REFSPEC', value : "${gerritRefspec}")
        ], wait: true
        downloadJenkinsFile("${env.JENKINS_URL}/job/eea-product-ci-meta-baseline-loop-utf-and-data-loader-deploy/${utf_build.number}/artifact/meta_baseline.groovy")
        archiveArtifacts artifacts: "meta_baseline.groovy", allowEmptyArchive: true
        load "meta_baseline.groovy"
    }
}

void initVarsAndGetCharts() {
    script {
        withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                        usernamePassword(credentialsId: 'ECEAART_SEROGIC_API_KEY', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
                        usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
                        string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                        string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                        file(credentialsId: env.CLUSTER_NAME, variable: 'KUBECONFIG')
        ]) {
            withEnv(["HELM_TIMEOUT=3800",
                "INT_CHART_NAME=${env.INT_CHART_NAME_PRODUCT}",
                "INT_CHART_REPO=${env.INT_CHART_REPO_PRODUCT}",
                "INT_CHART_VERSION=${env.INT_CHART_VERSION_PRODUCT}"
            ]) {
                sh 'mkdir -p $WORKSPACE/deployer-workspace'
                sh './bob/bob -r ruleset2.0.yaml init'
                sh './bob/bob -r ruleset2.0.yaml init-mxe'
                sh './bob/bob -r ruleset2.0.yaml k8s-post-install:copy-tls-keys-and-certificates-to-a-eric-data-loader-secret-in-the-eric-eea-ns'
                // Download and extract the Integration helm chart
                sh './bob/bob -r ruleset2.0.yaml k8s-test-without-post-install:download-extract-chart'
                if ( env.UPGRADE_TYPE == "ONLINE" ) {
                    if (params.CHART_NAME == params.SEP_CHART_NAME) {
                        env.SEP_CHART_REPO = "${params.CHART_REPO}"
                        echo "SEP repo: ${env.SEP_CHART_REPO}"
                    }
                    env.SEP_CHART_VERSION = sh(
                        script: '''cat .bob/chart/eric-eea-int-helm-chart/Chart.yaml | grep -A 2 storage-encryption-provider | grep version | awk -F ' ' '{print $2}' | tr -d '\\n'
                        ''', returnStdout : true)
                    echo "SEP CHART VERSION: ${env.SEP_CHART_VERSION}"
                    env.TLS_PROXY_VERSION = sh(
                        script: '''cat .bob/chart/eric-eea-int-helm-chart/Chart.yaml | grep -A 2 eric-tm-tls-proxy-ev | grep version | awk -F ' ' '{print $2}' | tr -d '\\n'
                        ''', returnStdout : true)
                    echo "TLS PROXY CHART VERSION: ${env.TLS_PROXY_VERSION}"
                    // Download and extract the SEP helm chart
                    sh './bob/bob k8s-test-sep-upgrade-new:download-extract-chart -r bob-rulesets/upgrade.yaml'
                    // Download the TLS PROXY helm chart
                    sh 'curl -H "X-JFrog-Art-Api: $API_TOKEN_ADP" $TLS_PROXY_REPO/$TLS_PROXY_NAME/$TLS_PROXY_NAME-$TLS_PROXY_VERSION.tgz --fail -o .bob/chart/$TLS_PROXY_NAME-$TLS_PROXY_VERSION.tgz'
                    // Copy all helm charts to the $WORKSPACE/deployer-workspace/Definitions/OtherTemplates directory
                    sh '''
                        mkdir -p $WORKSPACE/deployer-workspace/Definitions/OtherTemplates
                        cp .bob/chart/*.tgz $WORKSPACE/deployer-workspace/Definitions/OtherTemplates/
                    '''
                } else {
                    echo "Offline upgrade using CSAR will be perfomed"
                }
            }
        }
    }
}

void getUtilsImage(stageResults) {
    catchError(buildResult: 'FAILURE', stageResult: 'FAILURE' ) {
        script {
            PREVIOUS_STAGE = "${STAGE_NAME}"
            try {
                data = readYaml (file: 'bob-rulesets/upgrade.yaml')
                utilsImage = data["docker-images"]["eea4-utils"].findAll {it}.join(',')
                env.UTILS_IMAGE = utilsImage
                env.UTILS_IMAGE_NAME = utilsImage.tokenize('/').last().replace(':', '_')
                sh '''
                    mkdir -p $WORKSPACE/deployer-workspace/Scripts
                    docker pull $UTILS_IMAGE
                    docker save --output $WORKSPACE/deployer-workspace/Scripts/$UTILS_IMAGE_NAME.tar $UTILS_IMAGE
                '''
                stageResults."${STAGE_NAME}" = "SUCCESS"
            } catch(err) {
                stageResults."${STAGE_NAME}" = "FAILURE"
                echo "Caught: ${err}"
                error "${STAGE_NAME} FAILED".toUpperCase()
            }
        }
    }
}

void getLatestCsarVersion() {
    arm.setUrl('https://arm.seli.gic.ericsson.se/', "$API_TOKEN_EEA")
    Map args = [
        "repo": "proj-eea-drop-generic-local",
        "type": "file",
        "name": "*.csar",
        "sort_desc": ["created"],
        "limit": 1
    ]
    env.CSAR_VERSION = ""
    def jsonText = arm.searchArtifact(args)
    if (!jsonText) {
        error("Failed to get jsonText")
    }
    def jsonObj = readJSON text: jsonText
    if (!jsonObj) {
        error("Failed to get jsonObj")
    }
    jsonObj.results.eachWithIndex { artifact, idx ->
        env.CSAR_VERSION = arm.getServiceVersion("${artifact.name}")
    }
    if (!env.CSAR_VERSION) {
        error("Failed to determine latest CSAR_VERSION in ARM")
    }
    echo("Latest CSAR_VERSION: ${env.CSAR_VERSION}")
}

void getInstalledBaselineParamsFromCluster(){
    script {
        env.CLUSTER_NAME = env.system
        // Read configmap from cluster
        withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
            usernamePassword(credentialsId: 'ECEAART_SEROGIC_API_KEY', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
            usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
            file(credentialsId: env.CLUSTER_NAME, variable: 'KUBECONFIG')
        ]) {
            withEnv(["NAME_OF_CONFIGMAP='product-baseline-install'", "CONFIGMAP_FILENAME=product_baseline.groovy" ]) {
                sh "./bob/bob get-configmap-to-file -r bob-rulesets/upgrade.yaml"
            }
        }
        archiveArtifacts artifacts: "product_baseline.groovy", allowEmptyArchive: true
        load "product_baseline.groovy"
    }
}

void setDescription() {
    script {
        env.UPGRADED_VERSION = "${env.INT_CHART_VERSION_PRODUCT}"
        if ( env.UPGRADE_TYPE == "OFFLINE" ) {
            env.UPGRADED_VERSION = "${env.CSAR_NAME}:${env.CSAR_VERSION}"
        }
        if (params.SPINNAKER_ID) {
            currentBuild.description += '<br>Spinnaker URL: <a href="https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/details/' + params.SPINNAKER_ID + '">' + params.SPINNAKER_ID + '</a>'
        }
        if (params.CHART_NAME && params.CHART_VERSION) {
            currentBuild.description += '<br>' + params.CHART_NAME + ':' + params.CHART_VERSION
        }
        currentBuild.description += '<br>' + "Upgrade type: ${env.UPGRADE_TYPE}"
        currentBuild.description += '<br>' + "Installed meta version: ${env.INT_CHART_VERSION_META}"
        currentBuild.description += '<br>' + "Baseline installed version: ${env.BASELINE_INT_CHART_VERSION}"
        currentBuild.description += '<br>' + "Baseline branch: ${env.BASELINE_GIT_BRANCH}"
        currentBuild.description += '<br>' + "Upgraded version: ${env.UPGRADED_VERSION}"
        currentBuild.description += '<br>' + "Helm and CMA validation mode: ${params.HELM_AND_CMA_VALIDATION_MODE}"
    }
}

void archiveTechnicalsRulesetDirs() {
    dir('adp-app-staging'){
        withCredentials([usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GIT_USER', passwordVariable: 'PASSWORD' )]) {
            script {
                gitadp.archiveDir('EEA/adp-app-staging', 'HEAD:technicals/')
            }
        }
    }
    dir('rulesets') {
        withCredentials([usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GIT_USER', passwordVariable: 'PASSWORD')]) {
            script {
                gitadp.archiveDir('EEA/adp-app-staging', 'HEAD:rulesets/')
            }
        }
    }
}

void prepareUpgradeValues(stageResults) {
    catchError(buildResult: 'FAILURE', stageResult: 'FAILURE' ) {
        script {
            PREVIOUS_STAGE = "${STAGE_NAME}"
            try {
                def branchname = env.BASELINE_GIT_BRANCH
                echo "Baseline branch: ${branchname}"
                gitcnint.checkout(branchname, 'cnint_baseline')
                env.DIMENSIONING_OUTPUT_GENERATOR_JOB_NAME = "dimensioning-tool-output-generator"
                if ( params.DIMTOOL_OUTPUT_NAME.trim() && params.DIMTOOL_OUTPUT_REPO.trim() && params.DIMTOOL_OUTPUT_REPO_URL.trim() ) {
                    cmutils.useValuesFromDimToolOutput("${params.DIMTOOL_OUTPUT_REPO_URL}", "${params.DIMTOOL_OUTPUT_REPO}", "${params.DIMTOOL_OUTPUT_NAME}")
                } else {
                    def dimensioning_output_generator_job = build job: "${DIMENSIONING_OUTPUT_GENERATOR_JOB_NAME}", parameters: [
                            booleanParam(name: 'DIMTOOL_VALIDATE_OUTPUT', value: true),
                            stringParam(name: 'INT_CHART_NAME', value: env.INT_CHART_NAME_PRODUCT),
                            stringParam(name: 'INT_CHART_REPO', value : env.INT_CHART_REPO_PRODUCT),
                            stringParam(name: 'INT_CHART_VERSION', value: env.INT_CHART_VERSION_PRODUCT),
                            stringParam(name: 'UTF_CHART_NAME', value: env.UTF_CHART_NAME),
                            stringParam(name: 'UTF_CHART_REPO', value: env.UTF_CHART_REPO),
                            stringParam(name: 'UTF_CHART_VERSION', value: env.UTF_CHART_VERSION),
                            stringParam(name: 'DATASET_NAME', value: env.DATASET_NAME),
                            stringParam(name: 'REPLAY_SPEED', value: env.REPLAY_SPEED),
                            stringParam(name: 'GERRIT_REFSPEC', value: params.GERRIT_REFSPEC)
                    ], wait: true
                    def dimToolGeneratorJobResult = dimensioning_output_generator_job.getResult()
                    if (dimToolGeneratorJobResult != 'SUCCESS') {
                        error("Build of ${DIMENSIONING_OUTPUT_GENERATOR_JOB_NAME} job failed with result: ${dimToolGeneratorJobResult}")
                    }
                    copyArtifacts filter: '*.log, dimToolOutput.properties', fingerprintArtifacts: true, projectName: "dimensioning-tool-output-generator", selector: specific("${dimensioning_output_generator_job.number}")
                    readProperties(file: 'dimToolOutput.properties').each {key, value -> env[key] = value }
                    echo "DIMTOOL_OUTPUT_REPO_URL=${DIMTOOL_OUTPUT_REPO_URL} >> ${WORKSPACE}/artifact.properties"
                    echo "DIMTOOL_OUTPUT_REPO=${DIMTOOL_OUTPUT_REPO} >> ${WORKSPACE}/artifact.properties"
                    echo "DIMTOOL_OUTPUT_NAME=${DIMTOOL_OUTPUT_NAME} >> ${WORKSPACE}/artifact.properties"
                    archiveArtifacts artifacts: "*.log, dimToolOutput.properties" , allowEmptyArchive: true
                    cmutils.useValuesFromDimToolOutput("${DIMTOOL_OUTPUT_REPO_URL}", "${DIMTOOL_OUTPUT_REPO}", "${DIMTOOL_OUTPUT_NAME}" )
                }
                echo "HELM_AND_CMA_VALIDATION_MODE mode is: ${params.HELM_AND_CMA_VALIDATION_MODE}"
                if (params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE__HELM_VALUES || params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE_IS_HELM) {
                    echo "CMA configuration usage has to be disabled"
                    sh "echo 'helm-values/disable-cma-values.yaml' >> values-list.txt"
                    sh "echo 'helm-values/disable-cma-values.yaml' >> mxe-values-list.txt"
                }
                sh '''
                    cp -Rv helm-values/ ${WORKSPACE}/deployer-workspace/
                    cp -Rv dataflow-configuration/ ${WORKSPACE}/deployer-workspace/
                    cp -Rv values-list.txt ${WORKSPACE}/deployer-workspace/config-upgrade-values-list.txt
                    cp -Rv mxe-values-list.txt ${WORKSPACE}/deployer-workspace/mxe-config-upgrade-values-list.txt
                '''
                downloadJenkinsFile("${env.BASELINE_BUILD_URL}/artifact/cnint/install-configvalues.tar.gz", "baseline-install-configvalues.tar.gz")
                sh """
                    mkdir baseline_install_configvalues
                    tar -xzvf baseline-install-configvalues.tar.gz -C baseline_install_configvalues
                    cp -Rv baseline_install_configvalues/helm-values/ ${WORKSPACE}/deployer-workspace/baseline-helm-values
                    cp -Rv baseline_install_configvalues/dataflow-configuration/ ${WORKSPACE}/deployer-workspace/baseline-dataflow-configuration
                """
                if (params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE__HELM_VALUES || params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE_IS_HELM) {
                    echo "CMA configuration usage has to be disabled during SW upgrade as well"
                    sh """
                        if ! grep -Fxq "helm-values/disable-cma-values.yaml" cnint_baseline/values-list.txt
                        then
                            echo 'helm-values/disable-cma-values.yaml' >> cnint_baseline/values-list.txt
                        fi
                        if ! grep -Fxq "helm-values/disable-cma-values.yaml" cnint_baseline/mxe-values-list.txt
                        then
                            echo 'helm-values/disable-cma-values.yaml' >> cnint_baseline/mxe-values-list.txt
                        fi
                        if [ ! -f ${WORKSPACE}/deployer-workspace/baseline-helm-values/disable-cma-values.yaml ]
                        then
                            cp -v helm-values/disable-cma-values.yaml ${WORKSPACE}/deployer-workspace/baseline-helm-values/disable-cma-values.yaml
                        fi
                    """
                }
                sh """
                    cp -v cnint_baseline/values-list.txt ${WORKSPACE}/deployer-workspace/software-upgrade-values-list.txt
                    cp -v cnint_baseline/mxe-values-list.txt ${WORKSPACE}/deployer-workspace/mxe-software-upgrade-values-list.txt
                """
                archiveArtifacts artifacts: "baseline-install-configvalues.tar.gz", allowEmptyArchive: true
                dir('deployer-workspace') {
                    // Prepare sw upgrade valeus list based on the baseline values
                    def baselineValuesList = ["software-upgrade-values-list.txt","mxe-software-upgrade-values-list.txt"]
                    def baselineValuesFilesExemptionList = ['custom_environment_values']
                    baselineValuesList.each { valuesList ->
                        valuesListData = readFile(valuesList).readLines()
                        valuesListData = valuesListData.findAll{ !(it =~ /^#/) }.collect{ "baseline-" + it }.join("\n")
                        sh 'echo "' + valuesListData + '" > "' + valuesList + '"'
                        baselineValuesFilesExemptionList.each{ valuesFile ->
                            sh """sed -i "/${valuesFile}/s/baseline-//g" ${valuesList}"""
                        }
                    }
                    if ( env.UPGRADE_TYPE == "OFFLINE" ) {
                        sh '''
                            for VALUES_FILE in helm-values/custom_environment_values.yaml helm-values/mxe-values.yaml; do
                                sed -i 's/#url: k8s-registry.eccd.local/url: k8s-registry.eccd.local/g' "$VALUES_FILE"
                                sed -i 's/armdocker.rnd.ericsson.se/k8s-registry.eccd.local/g' "$VALUES_FILE"
                                sed -i 's/arm-pullsecret/local-pullsecret/g' "$VALUES_FILE"
                            done
                        '''
                    }
                    // Generate values files directories
                    sh '''
                        for VALUES_LIST in *.txt; do
                            DIRECTORY_NAME=$(echo "$VALUES_LIST" | sed -e "s/-list.txt//")
                            mkdir -p "$DIRECTORY_NAME"
                            grep -v "#" "$VALUES_LIST" > "$DIRECTORY_NAME"/values-list.txt
                            while read -r VALUES_FILE; do
                                cp --parents "$VALUES_FILE" $DIRECTORY_NAME/
                            done < "$DIRECTORY_NAME"/values-list.txt
                            rm -f "$VALUES_LIST"
                        done
                        rm -rf baseline-* *.txt *.yaml
                    '''
                }
                stageResults."${STAGE_NAME}" = "SUCCESS"
            } catch(err) {
                stageResults."${STAGE_NAME}" = "FAILURE"
                echo "Caught: ${err}"
                error "${STAGE_NAME} FAILED".toUpperCase()
            }
        }
    }
}

void runPreActivities() {
    script {
        def utf_pre_activitie = [name: "${UTF_PRE_ACTIVITIES_TEST_NAME}", build_result: 'FAILURE', stage_result: 'FAILURE', exec_id: "${UTF_PRE_ACTIVITIES_TEST_EXECUTION_ID}", metafilter: "${env.UTF_PRE_ACTIVITIES_META_FILTER}", timeout: "${UTF_PRE_ACTIVITIES_TEST_TIMEOUT}", logfile: "${UTF_PRE_ACTIVITIES_TEST_LOGFILE}"]
        utf.execUtfTest(utf_pre_activitie)
    }
}

void runHealthCheck(stageResults, String waitTimeout) {
    catchError(buildResult: 'FAILURE', stageResult: 'FAILURE' ) {
        script {
            withCredentials([file(credentialsId: env.CLUSTER_NAME, variable: 'KUBECONFIG')]){
                withEnv(["WAIT_FOR_PODS=${waitTimeout}"]) {
                    PREVIOUS_STAGE = "${STAGE_NAME}"
                    try {
                        clusterLogUtilsInstance.runHealthCheck("${waitTimeout}", "${STAGE_NAME}")
                        stageResults."${STAGE_NAME}" = "SUCCESS"
                    }
                    catch (err) {
                        stageResults."${STAGE_NAME}" = "FAILURE"
                        echo "Caught: ${err}"
                        error "${STAGE_NAME} FAILED".toUpperCase()
                    }
                }
            }
        }
    }
}

void runHealthChecks(stageResults, String waitTimeout) {
    catchError(buildResult: 'FAILURE', stageResult: 'FAILURE' ) {
        script {
            withCredentials([file(credentialsId: env.CLUSTER_NAME, variable: 'KUBECONFIG')]){
                withEnv(["WAIT_FOR_PODS=${waitTimeout}"]) {
                    PREVIOUS_STAGE = "${STAGE_NAME}"
                    try {
                        clusterLogUtilsInstance.runHealthCheck("${waitTimeout}", "${STAGE_NAME}")
                        clusterLogUtilsInstance.runHealthCheckWithCMA("${waitTimeout}", "${STAGE_NAME}")
                        stageResults."${STAGE_NAME}" = "SUCCESS"
                    }
                    catch (err) {
                        stageResults."${STAGE_NAME}" = "FAILURE"
                        echo "Caught: ${err}"
                        error "${STAGE_NAME} FAILED".toUpperCase()
                    }
                }
            }
        }
    }
}


void downloadCsarPackage(stageResults) {
    catchError(buildResult: 'FAILURE', stageResult: 'FAILURE' ) {
        withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA')]) {
            script {
                PREVIOUS_STAGE = "${STAGE_NAME}"
                try {
                    sh 'curl -H "X-JFrog-Art-Api: $API_TOKEN_EEA" $CSAR_REPO/$CSAR_NAME-$CSAR_VERSION.csar --fail -o deployer-workspace/$CSAR_NAME-$CSAR_VERSION.csar'
                    stageResults."${STAGE_NAME}" = "SUCCESS"
                }
                catch (err) {
                    stageResults."${STAGE_NAME}" = "FAILURE"
                    echo "Caught: ${err}"
                    error "${STAGE_NAME} FAILED".toUpperCase()
                }
            }
        }
    }
}

void getDockerRegistryConnectionInfo(stageResults) {
    catchError(buildResult: 'FAILURE', stageResult: 'FAILURE' ) {
        script {
            withCredentials([usernamePassword(credentialsId: 'hub-root-user', usernameVariable: 'HUB_ROOT_USER', passwordVariable: 'HUB_ROOT_PASSWD'),
                            file(credentialsId: env.system, variable: 'KUBECONFIG')]) {
                PREVIOUS_STAGE = "${STAGE_NAME}"
                try {
                    sh './bob/bob -r bob-rulesets/upgrade.yaml prepare-cluster-docker-registry-access'
                    stageResults."${STAGE_NAME}" = "SUCCESS"
                } catch(err) {
                    stageResults."${STAGE_NAME}" = "FAILURE"
                    echo "Caught: ${err}"
                    error "${STAGE_NAME} FAILED".toUpperCase()
                }
            }
        }
    }
}

void getJenkinsDockerImageVersion(stageResults) {
    catchError(buildResult: 'FAILURE', stageResult: 'FAILURE' ) {
        script {
            PREVIOUS_STAGE = "${STAGE_NAME}"
            try {
                if ( !params.DOCKER_EXECUTOR_IMAGE_VERSION ) {
                    if ( params.INT_CHART_VERSION_META == 'latest') {
                        env.DOCKER_EXECUTOR_IMAGE_VERSION = cmutils.extractSubChartData("eric-eea-jenkins-docker", "version", "${WORKSPACE}/project-meta-baseline/eric-eea-ci-meta-helm-chart","Chart.yaml")
                        jenkinsDockerHelmChartRepo = cmutils.extractSubChartData("eric-eea-jenkins-docker", "repository", "${WORKSPACE}/project-meta-baseline/eric-eea-ci-meta-helm-chart","Chart.yaml")
                        env.DOCKER_EXECUTOR_IMAGE_NAME = result = 'armdocker.rnd.ericsson.se/' + (jenkinsDockerHelmChartRepo =~ /proj-eea(.*)/)[0][0].replaceAll(/-helm/, '') + '/eea-jenkins-docker'
                    } else {
                        withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA')]){
                            sh """
                                mkdir ${WORKSPACE}/${INT_CHART_NAME_META}-${INT_CHART_VERSION_META}
                                curl -H "X-JFrog-Art-Api: ${env.API_TOKEN_EEA}" -o "${WORKSPACE}/${INT_CHART_NAME_META}-${INT_CHART_VERSION_META}/${INT_CHART_NAME_META}-${INT_CHART_VERSION_META}.tgz" "${INT_CHART_REPO_META}/${INT_CHART_NAME_META}/${INT_CHART_NAME_META}-${INT_CHART_VERSION_META}.tgz"
                                tar -C "${WORKSPACE}/${INT_CHART_NAME_META}-${INT_CHART_VERSION_META}" -xf "${WORKSPACE}/${INT_CHART_NAME_META}-${INT_CHART_VERSION_META}/${INT_CHART_NAME_META}-${INT_CHART_VERSION_META}.tgz"
                            """
                            env.DOCKER_EXECUTOR_IMAGE_VERSION = cmutils.extractSubChartData("eric-eea-jenkins-docker", "version", "${WORKSPACE}/${INT_CHART_NAME_META}-${INT_CHART_VERSION_META}/${INT_CHART_NAME_META}","Chart.yaml")
                            jenkinsDockerHelmChartRepo = cmutils.extractSubChartData("eric-eea-jenkins-docker", "repository", "${WORKSPACE}/${INT_CHART_NAME_META}-${INT_CHART_VERSION_META}/${INT_CHART_NAME_META}","Chart.yaml")
                            env.DOCKER_EXECUTOR_IMAGE_NAME = result = 'armdocker.rnd.ericsson.se/' + (jenkinsDockerHelmChartRepo =~ /proj-eea(.*)/)[0][0].replaceAll(/-helm/, '') + '/eea-jenkins-docker'
                        }
                    }
                }
                // WA for setting docker repo when using virtual helm repo:
                //   if the repo name calculated from the helm repo is the 'proj-eea' virtual repo,
                //   need to check first if it exists in the released or drop repo
                def virtualRepoName = 'proj-eea'
                def releasedRepoName = 'proj-eea-released'
                def dropRepoName = 'proj-eea-drop'
                if ( env.DOCKER_EXECUTOR_IMAGE_NAME.contains("/${virtualRepoName}/") ) {
                    echo "Virtual repo (${virtualRepoName}) found in DOCKER_EXECUTOR_IMAGE_NAME: ${DOCKER_EXECUTOR_IMAGE_NAME}\nChecking if docker image exists ..."
                    withCredentials([string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                        arm.setUrl(Artifactory.defaultUrl, "${API_TOKEN_EEA}")
                        def armDockerReleasedRepo = "${releasedRepoName}-docker-global/${releasedRepoName}"
                        def armDockerDropRepo = "${dropRepoName}-docker-global/${dropRepoName}"
                        def armDockerPath = "eea-jenkins-docker/${env.DOCKER_EXECUTOR_IMAGE_VERSION}"
                        if (arm.checkIfArtifactExists("${armDockerReleasedRepo}", "${armDockerPath}")) {
                            // check in released repo
                            echo "${armDockerPath} found in ${armDockerReleasedRepo}"
                            env.DOCKER_EXECUTOR_IMAGE_NAME = env.DOCKER_EXECUTOR_IMAGE_NAME.replaceAll("/${virtualRepoName}/", "/${releasedRepoName}/")
                        } else if (arm.checkIfArtifactExists("${armDockerDropRepo}", "${armDockerPath}")) {
                            // check in drop repo
                            echo "${armDockerPath} found in ${armDockerDropRepo}"
                            env.DOCKER_EXECUTOR_IMAGE_NAME = env.DOCKER_EXECUTOR_IMAGE_NAME.replaceAll("/${virtualRepoName}/", "/${dropRepoName}/")
                        } else {
                            error "${armDockerPath} NOT found in repo:\n - ${armDockerReleasedRepo}\n - ${armDockerDropRepo}]"
                        }
                    }
                }
                echo "DOCKER_EXECUTOR_IMAGE_NAME: ${env.DOCKER_EXECUTOR_IMAGE_NAME}"
                echo "DOCKER_EXECUTOR_IMAGE_VERSION: ${env.DOCKER_EXECUTOR_IMAGE_VERSION}"
                stageResults."${STAGE_NAME}" = "SUCCESS"
            } catch(err) {
                stageResults."${STAGE_NAME}" = "FAILURE"
                echo "Caught: ${err}"
                error "${STAGE_NAME} FAILED".toUpperCase()
            }
        }
    }
}

void runDindAndJenkinsDocker(stageResults) {
    catchError(buildResult: 'FAILURE', stageResult: 'FAILURE' ) {
        script {
            withCredentials([file(credentialsId: env.system, variable: 'KUBECONFIG')]) {
                PREVIOUS_STAGE = "${STAGE_NAME}"
                try {
                    env.DOCKER_NETWORK_NAME = "network-${JOB_NAME}-${BUILD_NUMBER}"
                    env.DIND_CONTAINER_NAME = "dind-${JOB_NAME}-${BUILD_NUMBER}"
                    env.DIND_DATA_VOLUME = "dind-data-${JOB_NAME}-${BUILD_NUMBER}"
                    env.DIND_CERTS_VOLUME_NAME = "certs-volume-${JOB_NAME}-${BUILD_NUMBER}"
                    env.JENKINS_DATA_VOLUME = "jenkins-data-${JOB_NAME}-${BUILD_NUMBER}"
                    env.JENKINS_CONTAINER_NAME = "jenkins-docker-executor-${JOB_NAME}-${BUILD_NUMBER}"
                    env.JENKINS_HOSTPORT = sh(script:"${WORKSPACE}/jenkins-docker/scripts/find-free-hostport.sh 8080", returnStdout: true).trim()
                    sh """
                        touch hosts
                        docker network create ${env.DOCKER_NETWORK_NAME}

                        docker run \
                        --name ${env.DIND_CONTAINER_NAME} \
                        --rm --detach --privileged \
                        --network ${env.DOCKER_NETWORK_NAME} \
                        --network-alias docker \
                        --env DOCKER_TLS_CERTDIR=/certs \
                        --volume ${env.DIND_DATA_VOLUME}:/var/lib/docker \
                        --volume ${env.KUBECONFIG}:/local/.kube/config:ro \
                        --volume ${env.DIND_CERTS_VOLUME_NAME}:/certs/client \
                        --volume ${env.JENKINS_DATA_VOLUME}:/var/jenkins_home \
                        --volume ${env.WORKSPACE}/deployer-workspace:/deployer-workspace:rw \
                        --volume ${env.JENKINS_DOCKER_HOSTS_FILE}:/etc/hosts \
                        --volume ${env.CLUSTER_DOCKER_REGISTRY_CERT}:/etc/docker/certs.d/k8s-registry.eccd.local/ca.crt \
                        armdocker.rnd.ericsson.se/dockerhub-ericsson-remote/docker:dind

                        docker run --name ${env.JENKINS_CONTAINER_NAME} \
                        --rm --detach \
                        --network ${env.DOCKER_NETWORK_NAME} \
                        --env DOCKER_HOST=tcp://docker:2376 \
                        --env DOCKER_CERT_PATH=/certs/client \
                        --env DOCKER_TLS_VERIFY=1 \
                        --env KUBECONFIG=/local/.kube/config \
                        --volume ${env.KUBECONFIG}:/local/.kube/config:ro \
                        --volume ${env.DIND_CERTS_VOLUME_NAME}:/certs/client:ro \
                        --volume ${env.JENKINS_DATA_VOLUME}:/var/jenkins_home \
                        --volume ${env.WORKSPACE}/deployer-workspace:/deployer-workspace:rw \
                        --volume ${env.JENKINS_DOCKER_HOSTS_FILE}:/etc/hosts \
                        --volume ${env.CLUSTER_DOCKER_REGISTRY_CERT}:/etc/docker/certs.d/k8s-registry.eccd.local/ca.crt \
                        --publish ${env.JENKINS_HOSTPORT}:8080 \
                        ${env.DOCKER_EXECUTOR_IMAGE_NAME}:${env.DOCKER_EXECUTOR_IMAGE_VERSION}
                    """
                    sh "${WORKSPACE}/jenkins-docker/scripts/check-docker-container-running.sh ${env.JENKINS_CONTAINER_NAME}"
                    stageResults."${STAGE_NAME}" = "SUCCESS"
                } catch (err) {
                    stageResults."${STAGE_NAME}" = "FAILURE"
                    echo "Caught: ${err}"
                    error "${STAGE_NAME} FAILED".toUpperCase()
                }
            }
        }
    }
}

void getJenkinsCli(stageResults) {
    catchError(buildResult: 'FAILURE', stageResult: 'FAILURE' ) {
        script {
            PREVIOUS_STAGE = "${STAGE_NAME}"
            try {
                sh "wget -O jenkins-cli.jar http://127.0.0.1:${env.JENKINS_HOSTPORT}/jnlpJars/jenkins-cli.jar"
                stageResults."${STAGE_NAME}" = "SUCCESS"
            } catch(err) {
                stageResults."${STAGE_NAME}" = "FAILURE"
                echo "Caught: ${err}"
                error "${STAGE_NAME} FAILED".toUpperCase()
            }
        }
    }
}

void importDataIntoJenkinsDocker(stageResults) {
    catchError(buildResult: 'FAILURE', stageResult: 'FAILURE' ) {
        script {
            withCredentials([usernamePassword(credentialsId: 'jenkins-docker-admin', usernameVariable: 'JENKINS_EXECUTOR_USER', passwordVariable: 'JENKINS_EXECUTOR_PASSWORD'),
                        usernamePassword(credentialsId: 'local-image-registry', usernameVariable: 'LOCAL_DOCKER_USERNAME', passwordVariable: 'LOCAL_DOCKER_PASSWORD'),
                        usernamePassword(credentialsId: 'hub-root-user', usernameVariable: 'HUB_ROOT_USER', passwordVariable: 'HUB_ROOT_PASSWD')]) {
                PREVIOUS_STAGE = "${STAGE_NAME}"
                try {
                    credentialToImportXml = createUsernamePasswordCredentialXml('container-registry', env.LOCAL_DOCKER_USERNAME, env.LOCAL_DOCKER_PASSWORD)
                    writeFile file: "container-registry.xml", text: credentialToImportXml
                    sh """
                        java -jar jenkins-cli.jar -s http://127.0.0.1:${JENKINS_HOSTPORT}/ \
                            -webSocket -auth ${JENKINS_EXECUTOR_USER}:${JENKINS_EXECUTOR_PASSWORD} \
                            create-credentials-by-xml system::system::jenkins _ < $WORKSPACE/container-registry.xml
                    """
                    // Import job xml and execute Dry-Run build
                    env.EEA_SOFTWARE_INGESTION_FILENAME = sh(script: ''' find $WORKSPACE/jenkins-jobs/eea-software-ingestion*.xml''', returnStdout : true).trim()
                    env.EEA_SOFTWARE_PREPARATION_FILENAME = sh(script: ''' find $WORKSPACE/jenkins-jobs/eea-software-preparation*.xml''', returnStdout : true).trim()
                    env.EEA_SOFTWARE_UPGRADE_FILENAME = sh(script: ''' find $WORKSPACE/jenkins-jobs/eea-software-upgrade*.xml''', returnStdout : true).trim()
                    env.EEA_SOFTWARE_INGESTION_JOB = sh(script: """ basename ${env.EEA_SOFTWARE_INGESTION_FILENAME} | sed 's/.xml//' -""", returnStdout : true).trim()
                    env.EEA_SOFTWARE_PREPARATION_JOB = sh(script: """ basename ${env.EEA_SOFTWARE_PREPARATION_FILENAME} | sed 's/.xml//' -""", returnStdout : true).trim()
                    env.EEA_SOFTWARE_UPGRADE_JOB = sh(script: """ basename ${env.EEA_SOFTWARE_UPGRADE_FILENAME} | sed 's/.xml//' -""", returnStdout : true).trim()
                    def jobsToImport = [env.EEA_SOFTWARE_INGESTION_JOB, env.EEA_SOFTWARE_PREPARATION_JOB, env.EEA_SOFTWARE_UPGRADE_JOB]
                    for (jobToTimport in jobsToImport) {
                        sh """
                            java -jar jenkins-cli.jar -s http://127.0.0.1:${JENKINS_HOSTPORT}/ \
                                -webSocket -auth ${JENKINS_EXECUTOR_USER}:${JENKINS_EXECUTOR_PASSWORD} \
                                create-job ${jobToTimport} < $WORKSPACE/jenkins-jobs/${jobToTimport}.xml
                            java -jar jenkins-cli.jar -s http://127.0.0.1:${JENKINS_HOSTPORT}/ \
                                -webSocket -auth ${JENKINS_EXECUTOR_USER}:${JENKINS_EXECUTOR_PASSWORD} \
                                build ${jobToTimport} -f -v -p DRY_RUN=true || echo "The build failed with the expected reason: DRY_RUN=true"
                        """
                    }
                    stageResults."${STAGE_NAME}" = "SUCCESS"
                } catch(err) {
                    stageResults."${STAGE_NAME}" = "FAILURE"
                    echo "Caught: ${err}"
                    error "${STAGE_NAME} FAILED".toUpperCase()
                }
            }
        }
    }
}

void executeIngestion(stageResults) {
    catchError(buildResult: 'FAILURE', stageResult: 'FAILURE' ) {
        script {
            withCredentials([usernamePassword(credentialsId: 'jenkins-docker-admin', usernameVariable: 'JENKINS_EXECUTOR_USER', passwordVariable: 'JENKINS_EXECUTOR_PASSWORD')]) {
                PREVIOUS_STAGE = "${STAGE_NAME}"
                try {
                    env.EXTRA_INGESTION_PARAMETERS = ""
                    sh """
                        java -jar jenkins-cli.jar -s http://127.0.0.1:${JENKINS_HOSTPORT}/ \
                        -webSocket -auth ${JENKINS_EXECUTOR_USER}:${JENKINS_EXECUTOR_PASSWORD} \
                        build ${env.EEA_SOFTWARE_INGESTION_JOB} -s -v \
                        -p PACKAGED_CSAR_LOCATION_PATH=/deployer-workspace \
                        -p DEPLOYMENT_SCRIPTS_DIRECTORY_PATH=/deployer-workspace/eea-deployer/product/scripts \
                        -p CSAR_PACKAGE_DIRECTORY_PATH=/var/jenkins_home/workspace/eea_upgrade \
                        ${env.EXTRA_INGESTION_PARAMETERS} > eea-software-ingestion.log
                    """
                    stageResults."${STAGE_NAME}" = "SUCCESS"
                } catch(err) {
                    stageResults."${STAGE_NAME}" = "FAILURE"
                    echo "Caught: ${err}"
                    error "${STAGE_NAME} FAILED".toUpperCase()
                } finally {
                    archiveArtifacts artifacts: "eea-software-ingestion.log", allowEmptyArchive: true
                }
            }
        }
    }
}

void executePreparation(stageResults) {
    catchError(buildResult: 'FAILURE', stageResult: 'FAILURE' ) {
        script {
            withCredentials([usernamePassword(credentialsId: 'jenkins-docker-admin', usernameVariable: 'JENKINS_EXECUTOR_USER', passwordVariable: 'JENKINS_EXECUTOR_PASSWORD')]) {
                PREVIOUS_STAGE = "${STAGE_NAME}"
                try {
                    env.EXTRA_PREPARATION_PARAMETERS = ""
                    sh """
                        java -jar jenkins-cli.jar -s http://127.0.0.1:${JENKINS_HOSTPORT}/ \
                        -webSocket -auth ${JENKINS_EXECUTOR_USER}:${JENKINS_EXECUTOR_PASSWORD} \
                        build ${env.EEA_SOFTWARE_PREPARATION_JOB} -s -v \
                        -p CSAR_PACKAGE_DIRECTORY_PATH=/var/jenkins_home/workspace/eea_upgrade \
                        -p NSEEA=eric-eea-ns \
                        -p NSCRD=eric-crd-ns \
                        -p IMAGE_PULLSECRET=local-pullsecret \
                        -p DOCKER_REGISTRY=k8s-registry.eccd.local \
                        -p DOCKER_REGISTRY_JENKINS_CREDENTIAL_NAME=container-registry \
                        -p DOCKER_PATH=/usr/local/bin/docker \
                        -p DOCKER_CONFIG_FILE=/var/jenkins_home/.docker/config.json \
                        ${env.EXTRA_PREPARATION_PARAMETERS} \
                        -p DEPLOY_SH_BASH_ARGS="${params.DEPLOY_SH_BASH_ARGS}" > eea-software-preparation.log
                    """
                    stageResults."${STAGE_NAME}" = "SUCCESS"
                } catch(err) {
                    stageResults."${STAGE_NAME}" = "FAILURE"
                    echo "Caught: ${err}"
                    error "${STAGE_NAME} FAILED".toUpperCase()
                } finally {
                    archiveArtifacts artifacts: "eea-software-preparation.log", allowEmptyArchive: true
                }
            }
        }
    }
}

void cleanupJenkinsDockerEnv() {
    sh '''
        for container_name in "$JENKINS_CONTAINER_NAME" "$DIND_CONTAINER_NAME"
        do
            if [ "$(docker inspect -f {{.State.Status}} $container_name)" = "running" ]; then
                if [ $container_name = "$JENKINS_CONTAINER_NAME" ]; then
                    docker logs $container_name > "$JENKINS_CONTAINER_LOGFILE" 2>&1
                    gzip -9 "$JENKINS_CONTAINER_LOGFILE"
                fi
                docker container rm -f $container_name
            fi
        done

        for image in "armdocker.rnd.ericsson.se/dockerhub-ericsson-remote/docker:dind" "$DOCKER_EXECUTOR_IMAGE_NAME:$DOCKER_EXECUTOR_IMAGE_VERSION"
        do
            docker rmi -f $image
        done

        docker volume rm $DIND_CERTS_VOLUME_NAME $JENKINS_DATA_VOLUME $DIND_DATA_VOLUME
        docker network rm $(docker network ls -f "name=$DOCKER_NETWORK_NAME" -q)
    '''
}

void collectBuildLogs() {
    env.LOGGING_JOB_NAME = getLastUpstreamBuildEnvVarValue('JOB_NAME', env.JOB_NAME)
    env.LOGGING_BUILD_NUMBER = getLastUpstreamBuildEnvVarValue('BUILD_NUMBER', env.BUILD_NUMBER)
    def upstreamJobUrl = "${env.JENKINS_URL}job/${env.LOGGING_JOB_NAME}/${env.LOGGING_BUILD_NUMBER}"
    def labelmanualchanged = checkLockableResourceLabelManualChange(env.CLUSTER_NAME)
    currentBuild.description += '<br>' + "Upstream job: <a href=\"${upstreamJobUrl}\">${upstreamJobUrl}</a>"
    if (params.CUSTOM_CLUSTER_LABEL) {
        try {
            setLockableResourceLabels(env.CLUSTER_NAME, params.CUSTOM_CLUSTER_LABEL)
        }
        catch (err) {
            echo "Caught setLockableResourceLabels ERROR: ${err}"
        }
    } else if (!params.SKIP_COLLECT_LOG) {
        try {
            prepareClusterForLogCollection("${env.CLUSTER_NAME}", "${env.LOGGING_JOB_NAME}", "${env.LOGGING_BUILD_NUMBER}", labelmanualchanged)
        }
        catch (err) {
            echo "Caught prepareClusterForLogCollection ERROR: ${err}"
        }
    }
    // Save the lock times
    env.lock_end = java.time.LocalDateTime.now()
    sh "{ (echo '$CLUSTER_NAME,${env.lock_start},${env.lock_end},eea-common-product-upgrade' >> /data/nfs/productci/cluster_lock.csv) } || echo '/data/nfs/productci/cluster_lock.csv is unreachable'"
    try {
        env.END_EPOCH = ((new Date()).getTime()/1000 as double).round()
        sh """
        cat > performance.properties << EOF
START_EPOCH=${env.START_EPOCH}
END_EPOCH=${env.END_EPOCH}
SPINNAKER_TRIGGER_URL=${params.SPINNAKER_TRIGGER_URL}
EOF
""".stripIndent()
        archiveArtifacts artifacts: 'performance.properties', allowEmptyArchive: true
        def currentJobFullDisplayName = env.LOGGING_JOB_NAME + '__' + env.LOGGING_BUILD_NUMBER
        withEnv(["CLUSTER=${env.CLUSTER_NAME}"]) {
            clusterLogUtilsInstance.addGrafanaUrlToJobDescription(env.START_EPOCH, env.END_EPOCH, params.SPINNAKER_TRIGGER_URL, currentJobFullDisplayName)
        }
    }
    catch (err) {
            echo "Caught performance data export ERROR: ${err}"
    }

    // Add baseline install logs link to the job's description
    def baselineInstallLogFolder = "${env.BASELINE_JOB_NAME}-${env.BASELINE_BUILD_NUMBER}/"
    def baselineInstallLogLink = clusterLogUtilsInstance.getLogCollectionLink(baselineInstallLogFolder)
    currentBuild.description += baselineInstallLogLink.replaceAll('Cluster logs', 'Cluster logs (baseline install)')

    // Upload to https://arm.seli.gic.ericsson.se/artifactory/proj-eea-reports-generic-local/clusterlogs/
    echo 'Publish logs to arm'
    def logFolder = "${env.LOGGING_JOB_NAME}-${env.LOGGING_BUILD_NUMBER}/"
    clusterLogUtilsInstance.publishLogsToArm("${logFolder}")
}

void getJenkinsDockerArtifacts(String jobName) {
    withCredentials([usernamePassword(credentialsId: 'jenkins-docker-admin', usernameVariable: 'JENKINS_EXECUTOR_USER', passwordVariable: 'JENKINS_EXECUTOR_PASSWORD')]) {
        try {
          sh("curl --silent http://${env.JENKINS_EXECUTOR_USER}:${env.JENKINS_EXECUTOR_PASSWORD}@127.0.0.1:${env.JENKINS_HOSTPORT}/job/${jobName}/lastBuild/api/json > jenkins_docker-${jobName}_build_info.json")
          archiveArtifacts artifacts: "jenkins_docker-${jobName}_build_info.json", allowEmptyArchive: true
          artifactsList = sh(script: "curl --silent http://${env.JENKINS_EXECUTOR_USER}:${env.JENKINS_EXECUTOR_PASSWORD}@127.0.0.1:${env.JENKINS_HOSTPORT}/job/${jobName}/lastBuild/api/json | jq --raw-output .artifacts[].fileName", returnStdout: true).trim().split('\n').collect{it as String}
          artifactsList.each { artifact ->
              sh "curl http://${env.JENKINS_EXECUTOR_USER}:${env.JENKINS_EXECUTOR_PASSWORD}@127.0.0.1:${env.JENKINS_HOSTPORT}/job/${jobName}/lastBuild/artifact/${artifact} -o jenkins_docker-${jobName}-${artifact}"
              archiveArtifacts artifacts: "jenkins_docker-${jobName}-${artifact}", allowEmptyArchive: true
            }
          sh "curl http://${env.JENKINS_EXECUTOR_USER}:${env.JENKINS_EXECUTOR_PASSWORD}@127.0.0.1:${env.JENKINS_HOSTPORT}/job/${jobName}/lastBuild/wfapi/describe  --insecure > jenkins_docker_${jobName}_currentBuildResult.json"
          archiveArtifacts artifacts: "jenkins_docker_${jobName}_currentBuildResult.json", allowEmptyArchive: true
        } catch(err) {
            echo "Caught during getJenkinsDockerArtifacts: ${err}"
        }
    }
}

void executeUpgrade(stageResults) {
    catchError(buildResult: 'FAILURE', stageResult: 'FAILURE' ) {
        script {
            withCredentials([usernamePassword(credentialsId: 'jenkins-docker-admin', usernameVariable: 'JENKINS_EXECUTOR_USER', passwordVariable: 'JENKINS_EXECUTOR_PASSWORD')]) {
                PREVIOUS_STAGE = "${STAGE_NAME}"
                try {
                    if ( env.UPGRADE_TYPE == "ONLINE") {
                        env.EXTRA_UPGRADE_PARAMETERS = "-p ONLINE_UPGRADE=true -p ONLINE_UPGRADE_SOURCE_DIRECTORY=/deployer-workspace -p DEPLOYMENT_SCRIPTS_DIRECTORY_PATH=/deployer-workspace/eea-deployer/product/scripts -p IMAGE_PULLSECRET=arm-pullsecret"
                    } else if ( env.UPGRADE_TYPE == "OFFLINE" ) {
                        env.EXTRA_UPGRADE_PARAMETERS = "-p IMAGE_PULLSECRET=local-pullsecret -p DOCKER_REGISTRY=k8s-registry.eccd.local"
                    }
                    sh """
                        java -jar jenkins-cli.jar -s http://127.0.0.1:${JENKINS_HOSTPORT}/ \
                        -webSocket -auth ${JENKINS_EXECUTOR_USER}:${JENKINS_EXECUTOR_PASSWORD} \
                        build ${env.EEA_SOFTWARE_UPGRADE_JOB} -s -v \
                        -p SKIP_MXE_SW_UPGRADE_STAGE=true \
                        -p CSAR_PACKAGE_DIRECTORY_PATH=/var/jenkins_home/workspace/eea_upgrade \
                        -p NSEEA=eric-eea-ns \
                        -p NSCRD=eric-crd-ns \
                        -p DOCKER_PATH=/usr/local/bin/docker \
                        -p KUBECTL_PATH=/usr/local/bin/kubectl \
                        -p HELM_PATH=/usr/local/bin/helm \
                        -p KUBE_CONFIG_FILE=/local/.kube/config \
                        -p SEP_UPGRADE_VALUES_FILES_PATH=/deployer-workspace/helm-values \
                        -p SEP_VALUES_FILE=sep_values.yaml \
                        -p SEP_ENVIRONMENT_VALUES_FILE=custom_environment_values.yaml \
                        -p EEA_SOFTWARE_UPGRADE_VALUES_FILES_PATH=/deployer-workspace/software-upgrade-values \
                        -p EEA_CONFIGURATION_UPGRADE_VALUES_FILES_PATH=/deployer-workspace/config-upgrade-values \
                        -p MXE_SOFTWARE_UPGRADE_VALUES_FILES_PATH=/deployer-workspace/mxe-software-upgrade-values \
                        -p MXE_CONFIGURATION_UPGRADE_VALUES_FILES_PATH=/deployer-workspace/mxe-config-upgrade-values \
                        ${env.EXTRA_UPGRADE_PARAMETERS} \
                        -p DEPLOY_SH_BASH_ARGS="${params.DEPLOY_SH_BASH_ARGS}" > execute_upgrade.log
                    """
                    stageResults."${STAGE_NAME}" = "SUCCESS"
                } catch(err) {
                    stageResults."${STAGE_NAME}" = "FAILURE"
                    echo "Caught: ${err}"
                    error "${STAGE_NAME} FAILED".toUpperCase()
                } finally {
                    archiveArtifacts artifacts: "execute_upgrade.log", allowEmptyArchive: true
                    try {
                        sh """
                            ls -laR $WORKSPACE/deployer-workspace/ > deployer_workspace_full.list
                            gzip deployer_workspace_full.list
                            tar czf software-upgrade-values.tgz $WORKSPACE/deployer-workspace/software-upgrade-values
                            tar czf config-upgrade-values.tgz $WORKSPACE/deployer-workspace/config-upgrade-values
                            tar czf mxe-software-upgrade-values.tgz $WORKSPACE/deployer-workspace/mxe-software-upgrade-values
                            tar czf mxe-config-upgrade-values.tgz $WORKSPACE/deployer-workspace/mxe-config-upgrade-values
                        """
                        archiveArtifacts artifacts: "deployer_workspace_full.list.gz", allowEmptyArchive: true
                        archiveArtifacts artifacts: "software-upgrade-values.tgz", allowEmptyArchive: true
                        archiveArtifacts artifacts: "config-upgrade-values.tgz", allowEmptyArchive: true
                        archiveArtifacts artifacts: "mxe-software-upgrade-values.tgz", allowEmptyArchive: true
                        archiveArtifacts artifacts: "mxe-config-upgrade-values.tgz", allowEmptyArchive: true
                    } catch(values_err) {
                        echo "Caught: ${values_err}"
                    }
                }
            }
        }
    }
}

void sendBuildStartedMessageToGerrit() {
    script {
        try {
            env.GERRIT_MSG = "Build Started ${BUILD_URL}"
            if ( params.GERRIT_REFSPEC ) {
                sendMessageToGerrit(params.GERRIT_REFSPEC, env.GERRIT_MSG)
                currentBuild.description += "EEA/cnint: " + getGerritLink(params.GERRIT_REFSPEC) + "<br>"
            }
            if ( params.DEPLOYER_GERRIT_REFSPEC ) {
                sendMessageToGerrit(params.DEPLOYER_GERRIT_REFSPEC, env.GERRIT_MSG)
                currentBuild.description += "EEA/deployer: " + getGerritLink(params.DEPLOYER_GERRIT_REFSPEC) + "<br>"
            }
            if ( params.META_GERRIT_REFSPEC ) {
                sendMessageToGerrit(params.META_GERRIT_REFSPEC, env.GERRIT_MSG)
                currentBuild.description += "EEA/project-meta-baseline: " + getGerritLink(params.META_GERRIT_REFSPEC) + "<br>"
            }
        } catch (err) {
            echo "Caught: ${err}"
        }
    }
}

void postStageAfterResourceLock() {
    script {
        sendLockEventToDashboard (transition: "release", cluster: env.CLUSTER_NAME)
        if (params.CUSTOM_CLUSTER_LABEL) {
            echo "Cluster has a new label ${params.CUSTOM_CLUSTER_LABEL}"
        } else if (!params.SKIP_COLLECT_LOG) {
            if (!env.CLUSTER_NAME) {
                    echo "There was no cluster lock, COLLECT_LOG skipped"
            } else {
                try {
                    echo "Execute cluster-logcollector job ... \n - cluster: ${env.CLUSTER_NAME}"
                    build job: "cluster-logcollector", parameters: [
                        stringParam(name: "CLUSTER_NAME", value: env.CLUSTER_NAME),
                        stringParam(name: 'SERVICE_NAME', value: params.CHART_NAME),
                        booleanParam(name: "CLUSTER_CLEANUP", value: !params.SKIP_CLEANUP),
                        stringParam(name: 'LAST_LABEL_SET', value: env.LASTLABEL),
                        stringParam(name: 'PIPELINE_NAME', value: params.PIPELINE_NAME),
                        stringParam(name: 'SPINNAKER_ID', value: params.SPINNAKER_ID),
                        stringParam(name: 'SPINNAKER_TRIGGER_URL', value: params.SPINNAKER_TRIGGER_URL)
                        ], wait: env.WAIT_FOR_CLUSTER_LOG_COLLECTOR_RESULT.toBoolean(), waitForStart: !env.WAIT_FOR_CLUSTER_LOG_COLLECTOR_RESULT.toBoolean()
                }
                catch (err) {
                    echo "Caught cluster-logcollector ERROR: ${err}"
                }
            }
        } else if ( params.SKIP_COLLECT_LOG && !params.SKIP_CLEANUP ) {
            if (!env.CLUSTER_NAME) {
                    echo "There was no cluster lock, COLLECT_LOG skipped"
            } else {
                try {
                    echo "Execute cluster-cleanup job ... \n - cluster: ${env.CLUSTER_NAME}"
                    build job: "cluster-cleanup", parameters: [
                        stringParam(name: "CLUSTER_NAME", value: env.CLUSTER_NAME),
                        stringParam(name: 'CNINT_GERRIT_REFSPEC', value: params.GERRIT_REFSPEC),
                        stringParam(name: "DESIRED_CLUSTER_LABEL", value: "${globalVars.resourceLabelCommon}"),
                        stringParam(name: "LAST_LABEL_SET", value: env.LASTLABEL),
                        stringParam(name: 'PIPELINE_NAME', value: params.PIPELINE_NAME),
                        stringParam(name: 'SPINNAKER_ID', value: params.SPINNAKER_ID),
                        stringParam(name: 'SPINNAKER_TRIGGER_URL', value: params.SPINNAKER_TRIGGER_URL)
                        ], wait: env.WAIT_FOR_CLUSTER_LOG_COLLECTOR_RESULT.toBoolean(), waitForStart: !env.WAIT_FOR_CLUSTER_LOG_COLLECTOR_RESULT.toBoolean()
                }
                catch (err) {
                    echo "Caught cluster-logcollector ERROR: ${err}"
                }
            }
        } else {
            echo "COLLECT_LOG skipped (params.SKIP_COLLECT_LOG=${params.SKIP_COLLECT_LOG})"
        }
    }
}

void load_config_json_to_CMAnalytics(stageResults) {
    script {
        PREVIOUS_STAGE = "${STAGE_NAME}"
        try {
            withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                usernamePassword(credentialsId: 'ECEAART_SEROGIC_API_KEY', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
                string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                file(credentialsId: env.system, variable: 'KUBECONFIG')
            ]){
                sh """
                    mkdir "$BASELINE_JOB_NAME-$BASELINE_BUILD_NUMBER"
                    curl -H "X-JFrog-Art-Api: $API_TOKEN_EEA" -fO "https://arm.seli.gic.ericsson.se//artifactory/proj-eea-reports-generic-local/clusterlogs/\${BASELINE_JOB_NAME}-\${BASELINE_BUILD_NUMBER}/dot_bob_after_product_install_\${BASELINE_JOB_NAME}_\${BASELINE_BUILD_NUMBER}.tar.gz"
                    tar -zxf "dot_bob_after_product_install_\${BASELINE_JOB_NAME}_\${BASELINE_BUILD_NUMBER}.tar.gz" -C "\${BASELINE_JOB_NAME}-\${BASELINE_BUILD_NUMBER}"
                    cp -rv "\${BASELINE_JOB_NAME}-\${BASELINE_BUILD_NUMBER}/.bob/certm-workdir/" .bob/
                """
                sh """
                    ./bob/bob get-sec-access-mgmt-hostname-and-ingress-loadbalancer-ip-oam
                    ./bob/bob get-iam-admin-user-and-passwd
                    ./bob/bob get-cm-analytics-ingress-hostname
                """
                cmutils.removeAggregationsFromConfigurationsByNamePattern()
                withEnv(["CMA_EXT_CONFIG_FILE=${globalVars.cma_correlator_content_version_path}", "CMA_EXT_CONFIG_ENDPOINT=${globalVars.cma_correlator_content_version_endpoint}"]) {
                    sh './bob/bob load-cm-analytics-config-cubes-into-eea'
                }
                withEnv(["CMA_EXT_CONFIG_FILE=${globalVars.cma_config_path}"]) {
                    sh './bob/bob load-cm-analytics-config-cubes-into-eea'
                }
                archiveArtifacts artifacts: "dot_bob_after_product_install_${env.BASELINE_JOB_NAME}_${env.BASELINE_BUILD_NUMBER}.tar.gz", allowEmptyArchive: true
            }
            stageResults."${STAGE_NAME}" = "SUCCESS"
        }
        catch (err) {
            stageResults."${STAGE_NAME}" = "FAILURE"
            echo "Caught: ${err}"
            error "${STAGE_NAME} FAILED".toUpperCase()
        }
    }
}

def logLock() {
    sendLockEventToDashboard (transition: "lock", cluster: env.CLUSTER_NAME)
    echo "Locked cluster: $env.CLUSTER_NAME"
    echo "Locked cluster LASTLABEL: $env.LASTLABEL"
    env.lock_start = java.time.LocalDateTime.now()
    env.START_EPOCH = ((new Date()).getTime()/1000 as double).round()
    currentBuild.description += "Locked cluster: $system"
}

void checkPortLockingResourceName(stageResults){
   try{
        script {
            echo "Port locking resource name: ${env.JENKINS_PORT_LOCKING}"
            if ( ! clusterLockUtils.getResourceLabelStatus("${env.JENKINS_PORT_LOCKING}")) {
             error "Port locking resource does NOT exist for build node: ${env.NODE_NAME} !"
            }
        }
    }
    catch (err) {
        echo "Caught: ${err}"
        error "${STAGE_NAME} FAILED".toUpperCase()
    }
}

void waitForCluster(stageResults){
    try {
        script {
            env.CLUSTER_NAME = ""
            sendLockEventToDashboard (transition: "wait-for-cluster")
            waitForLockableResource("${params.UPGRADE_CLUSTER_LABEL}", "${params.PIPELINE_NAME}", "${env.JOB_NAME}")
            sendLockEventToDashboard (transition: "wait-for-lock")
        }
    }
    catch (err) {
        echo "Caught: ${err}"
        error "${STAGE_NAME} FAILED".toUpperCase()
    }
}

void lockResourceAndRunDockers(stageResults){
    try{
        script {
            echo "Wait for port-locking resource is free"
            while ( clusterLockUtils.getResourceLabelStatus("${env.JENKINS_PORT_LOCKING}") != "FREE" ) {
                sleep(time: 10, unit: 'SECONDS' )
            }
        }
        lock(resource: null, label: "${env.JENKINS_PORT_LOCKING}", quantity: 1, variable: null){
                runDindAndJenkinsDocker(stageResults)
        }
    }
    catch (err) {
        echo "Caught: ${err}"
        error "${STAGE_NAME} FAILED".toUpperCase()
    }
}

def rulesetChangeCheckout(){
    script {
        gitcnint.fetchAndCherryPick('EEA/cnint', "${params.GERRIT_REFSPEC}")
    }
}

void checkNelsAvailabilityStage(){
    catchError(stageResult: 'FAILURE', buildResult: "${params.BUILD_RESULT_WHEN_NELS_CHECK_FAILED}") {
        script {
            withCredentials([usernamePassword(credentialsId: 'hub-root-user', usernameVariable: 'HUB_ROOT_USER', passwordVariable: 'HUB_ROOT_PASSWD'),
                            file(credentialsId: env.CLUSTER_NAME, variable: 'KUBECONFIG')]) {
                checkNelsAvailability()
            }
        }
    }
}


void runTestsAfterUpgrade(stageResults,stageCommentList,testExecutionJob){
    PREVIOUS_STAGE = "${STAGE_NAME}"
    try{
        echo "Run eea-common-product-test-after-deployment job"
        testExecutionJob = build job: "${env.TEST_AFTER_UPGRADE_JOB}", parameters: [
            string(name: 'CLUSTER_NAME', value : "${env.CLUSTER_NAME}"),
            string(name: 'INT_CHART_NAME_PRODUCT', value : "${env.INT_CHART_NAME_PRODUCT}"),
            string(name: 'INT_CHART_REPO_PRODUCT', value : "${env.INT_CHART_REPO_PRODUCT}"),
            string(name: 'INT_CHART_VERSION_PRODUCT', value : "${env.INT_CHART_VERSION_PRODUCT}"),
            string(name: 'GERRIT_REFSPEC', value : "${params.GERRIT_REFSPEC}"),
            string(name: 'META_GERRIT_REFSPEC',  value: "${params.META_GERRIT_REFSPEC}"),
            string(name: 'PIPELINE_NAME', value : "${params.PIPELINE_NAME}"),
            string(name: 'SPINNAKER_TRIGGER_URL', value : "${params.SPINNAKER_TRIGGER_URL}"),
            string(name: 'SPINNAKER_ID', value : "${params.SPINNAKER_ID}"),
            string(name: 'INT_CHART_NAME_META', value: "${env.INT_CHART_NAME_META}"),
            string(name: 'INT_CHART_REPO_META', value: "${env.INT_CHART_REPO_META}"),
            string(name: 'INT_CHART_VERSION_META', value: "${env.INT_CHART_VERSION_META}"),
            string(name: 'CHART_NAME', value: "${env.CHART_NAME}"),
            string(name: 'CHART_REPO', value: "${env.CHART_REPO}"),
            string(name: 'CHART_VERSION', value: "${env.CHART_VERSION}"),
            string(name: 'DEPLOYMENT_TYPE', value: "UPGRADE"),
            booleanParam(name: 'RUN_ROBOT_TESTS', value: true )
            ],propagate: false, wait: true
        def testExecutionJobResult = testExecutionJob.getResult()
        if (testExecutionJobResult != 'SUCCESS') {
            error("${env.TEST_AFTER_UPGRADE_JOB} " + testExecutionJobResult)
        }
        stageResults."${STAGE_NAME}" = "SUCCESS"
    } catch(err) {
        stageResults."${STAGE_NAME}" = "FAILURE"
        echo "Caught: ${err}"
        error "${STAGE_NAME} FAILED".toUpperCase()
    } finally {
        copyArtifacts filter: "*.log, *.tgz, *.gz", fingerprintArtifacts: true, projectName: "${env.TEST_AFTER_UPGRADE_JOB}", selector: specific("${testExecutionJob.number}"), optional: true
        archiveArtifacts artifacts: "bro*.log, *robot*.*, utf*.log, stage*.log " , allowEmptyArchive: true
        testJobUrl = " <a href=\"${env.JENKINS_URL}/job/${env.TEST_AFTER_UPGRADE_JOB}/${testExecutionJob.number}\">${env.TEST_AFTER_UPGRADE_JOB}/${testExecutionJob.number}</a>"
        stageCommentList[STAGE_NAME] = [ "${testJobUrl}" ]
        currentBuild.description += '<br>' + "Test after upgrade job URL: " + testJobUrl
    }
}

void executeSpotfireDeployment(stageResults,stageCommentList,spotfire_install_job) {
    PREVIOUS_STAGE = "${STAGE_NAME}"
    try{
        def data = readYaml file: 'spotfire_platform.yml'
        env.SF_ASSET_VERSION = data.spotfire_platform.spotfire_asset.version
        currentBuild.description += "<br>Spotfire_asset version: ${env.SF_ASSET_VERSION}"
        env.SF_STATIC_CONTENT_PATH = data.spotfire_platform.spotfire_static_content.download_url.split('artifactory/')[1]
        env.SF_STATIC_CONTENT_VERSION = data.spotfire_platform.spotfire_static_content.version
        env.STATIC_CONTENT_PKG = env.SF_STATIC_CONTENT_PATH + env.SF_STATIC_CONTENT_VERSION + "/spotfire-static-content-" + env.SF_STATIC_CONTENT_VERSION + ".tar.gz"
        spotfire_install_job = build job: "${SPOTFIRE_ASSET_INSTALL_ASSIGN_LABEL_WRAPPER_JOB_NAME}", parameters: [
            booleanParam(name: 'INSTALL_SPOTFIRE_PLATFORM', value: true),
            booleanParam(name: 'DEPLOY_STATIC_CONTENT', value: true),
            stringParam(name: 'CLUSTER_NAME', value : env.CLUSTER_NAME),
            stringParam(name: 'SF_ASSET_VERSION', value: env.SF_ASSET_VERSION),
            stringParam(name: 'STATIC_CONTENT_PKG', value: env.STATIC_CONTENT_PKG),
            stringParam(name: 'CNINT_GERRIT_REFSPEC', value: params.GERRIT_REFSPEC),
            stringParam(name: 'ADP_APP_STAGING_GERRIT_REFSPEC', value: env.ADP_APP_STAGING_GERRIT_REFSPEC_FOR_SF_INSTALL)
        ],propagate: false, wait: true
        def spotfireInstallJobResult = spotfire_install_job.getResult()
        downloadJenkinsFile("${env.JENKINS_URL}/job/${SPOTFIRE_ASSET_INSTALL_ASSIGN_LABEL_WRAPPER_JOB_NAME}/${spotfire_install_job.number}/artifact/artifact.properties", "spotfire_asset_install_assign_label_wrapper_artifact.properties")
        readProperties(file: 'spotfire_asset_install_assign_label_wrapper_artifact.properties').each {key, value -> env[key] = value }
        if (spotfireInstallJobResult != 'SUCCESS') {
            error("Build of spotfire-asset-install job failed with result: ${spotfireInstallJobResult}")
        }
        stageResults."${STAGE_NAME}" = "SUCCESS"
    } catch(err) {
        stageResults."${STAGE_NAME}" = "FAILURE"
        echo "Caught: ${err}"
        error "${STAGE_NAME} FAILED".toUpperCase()
    } finally {
        spotfireInstallJobUrl = " <a href=\"${env.JENKINS_URL}/job/${SPOTFIRE_ASSET_INSTALL_ASSIGN_LABEL_WRAPPER_JOB_NAME}/${spotfire_install_job.number}\">${SPOTFIRE_ASSET_INSTALL_ASSIGN_LABEL_WRAPPER_JOB_NAME}/${spotfire_install_job.number}</a>"
        stageCommentList[STAGE_NAME] = [ "${spotfireInstallJobUrl}" ]
        currentBuild.description += '<br>' + "Spotfire asset install job URL: " + spotfireInstallJobUrl
    }
}

void linkSpotfirePlatformToEea(stageResults,stageCommentList,link_spotfire_platform_to_eea_job){
    PREVIOUS_STAGE = "${STAGE_NAME}"
    try{
        link_spotfire_platform_to_eea_job = build job: "${SPOTFIRE_ASSET_INSTALL_ASSIGN_LABEL_WRAPPER_JOB_NAME}", parameters: [
            booleanParam(name: 'SETUP_TLS_AND_SSO', value: true),
            booleanParam(name: 'ENABLE_CAPACITY_REPORTER', value: true),
            stringParam(name: 'CLUSTER_NAME', value : env.CLUSTER_NAME),
            stringParam(name: 'PREVIOUS_JOB_BUILD_ID', value: env.SPOTFIRE_ASSET_INSTALL_NEW_BUILD_NUMBER),
            stringParam(name: 'SF_ASSET_VERSION', value: env.SF_ASSET_VERSION),
            stringParam(name: 'STATIC_CONTENT_PKG', value: env.STATIC_CONTENT_PKG),
            stringParam(name: 'CNINT_GERRIT_REFSPEC', value: params.GERRIT_REFSPEC),
            stringParam(name: 'ADP_APP_STAGING_GERRIT_REFSPEC', value: env.ADP_APP_STAGING_GERRIT_REFSPEC_FOR_SF_INSTALL)
        ], propagate: false, wait: true
        def link_spotfire_platform_to_eea_job_result = link_spotfire_platform_to_eea_job.getResult()
        if (link_spotfire_platform_to_eea_job_result != 'SUCCESS') {
            error("Build of spotfire-asset-install job failed with result: ${link_spotfire_platform_to_eea_job_result}")
        }
        stageResults."${STAGE_NAME}" = "SUCCESS"
    } catch(err) {
        stageResults."${STAGE_NAME}" = "FAILURE"
        echo "Caught: ${err}"
        error "${STAGE_NAME} FAILED".toUpperCase()
    } finally {
        linkSpotfirePlatformToEeaJobUrl = "<a href=\"${env.JENKINS_URL}/job/${SPOTFIRE_ASSET_INSTALL_ASSIGN_LABEL_WRAPPER_JOB_NAME}/${link_spotfire_platform_to_eea_job.number}\">${SPOTFIRE_ASSET_INSTALL_ASSIGN_LABEL_WRAPPER_JOB_NAME}/${link_spotfire_platform_to_eea_job.number}</a>"
        stageCommentList[STAGE_NAME] = [ "${linkSpotfirePlatformToEeaJobUrl}" ]
        currentBuild.description += '<br>' + "Link Spotfire to EEA URL: " + linkSpotfirePlatformToEeaJobUrl
    }
}
void applyAggregatorConfigmap(stageResults){
    catchError(buildResult: 'FAILURE', stageResult: 'FAILURE' ){
        PREVIOUS_STAGE = "${STAGE_NAME}"
        try{
            cmutils.applyAggregatorConfigmapFromDimtoolOutput()
            stageResults."${STAGE_NAME}" = "SUCCESS"
        } catch(err) {
            stageResults."${STAGE_NAME}" = "FAILURE"
            echo "Caught: ${err}"
            error "${STAGE_NAME} FAILED".toUpperCase()
        }
    }
}