import jenkins.model.CauseOfInterruption.UserInterruption

@NonCPS
def parseJson(def json) {
    new groovy.json.JsonSlurperClassic().parseText(json)
}

pipeline {
    agent { node { label "master" }}
    options {
        buildDiscarder(logRotator(daysToKeepStr: '15', artifactDaysToKeepStr: '15'))
    }
    parameters {
        string(
            name: 'CLUSTER_NAME',
            description: 'Cluster name',
            defaultValue: '',
        )
        string(
            name: 'EEA4_NS_NAME',
            description: 'Namespace where EEA4 will be/is deployed',
            defaultValue: 'eric-eea-ns'
        )
        string (
            name: 'OAM_POOL',
            defaultValue: 'pool0',
            description: """IP Pool name where eric-ts-platform-haproxy service will get LoadBalancer IP from.<br>
                RV clusters: pool0'
                """
        )
        string(
            name: 'SF_ASSET_VERSION',
            defaultValue: 'auto',
            description: """Select Spotfire asset version. Value refers to a directory on Jenkins agent node, where package is already extracted to.
                By default the value is extracted from <a href="https://gerrit-stg.seli.gic.ericsson.se/plugins/gitiles/EEA/cnint/+/master/spotfire_platform.yml">spotfire_platform.yml</a> file from cnint repository.
                If it's needed to specify another version, it can be done by pointing one manually, e.g.
                <b>spotfire-platform-asset-12.5.0-1.5.0-120124</b>
                """
        )
        booleanParam(
            name: 'CLEANUP_SPOTFIRE',
            defaultValue: 'false',
            description: """Cleanup deployed Spotfire from k8s cluster. Cleanup method is automatically called also when INSTALL_SPOTFIRE_PLATFORM is selected."""
        )
        booleanParam(
            name: 'INSTALL_SPOTFIRE_PLATFORM',
            defaultValue: 'false',
            description: """The followings will be performed in this stage:
                <ul>
                    <li>Install Spotfire BI Visualization Platform in spotfire-platform namespace</li>
                    <li>Install PostgreSQL DB & Vertica DB Data Source Templates</li>
                    <li>Import the selected EEA4 Dashboard Data Source ZIP file</li>
                    <li>Trust custom scripts and allow Ericsson brand styling</li>
                    <li>Deploy and start Web player and Python services</li>
                </ul>
                """
        )
        booleanParam(
            name: 'DEPLOY_STATIC_CONTENT',
            defaultValue: 'false',
            description: """Install or re-install the specified static content (SC) version.<br>
                Can be re-executed anytime, can be used to upgrade existing SC version to a new one.
                """
        )
        string(
            name: 'STATIC_CONTENT_PKG',
            defaultValue: 'auto',
            description: """Value is taken into account when <b>DEPLOY_STATIC_CONTENT</b> checkbox is selected.
                By default the value is extracted from <a href="https://gerrit-stg.seli.gic.ericsson.se/plugins/gitiles/EEA/cnint/+/master/spotfire_platform.yml">spotfire_platform.yml</a> file from cnint repository.
                If it's needed to specify another version, it can be done by pointing one manually, e.g.
                <b>proj-eea4-other-dev-local/com/ericsson/eea4/spotfire-static-content/1.1.44/spotfire-static-content-1.1.44.tar.gz</b>
                """
        )
        booleanParam(
            name: 'SETUP_TLS_AND_SSO',
            defaultValue: 'false',
            description: """The followings will be performed in this stage:
                <ul>
                    <li>Set Up TLS Connection Between Spotfire and OLAP (Vertica) Database</li>
                    <li>Configure IAM in EEA namespace for Spotfire and create new Spotfire users in IAM</li>
                    <li>Enable IAM Authentication in Spotfire config</li>
                </ul>
                Select this checkbox only if
                <ol type="1">
                    <li>Spotfire platform is installed earlier</li>
                    <li>EEA4 helm chart is installed earlier</li>
                    <li>Certificates are loaded to EEA namespace</li>
                """
        )
        booleanParam(
            name: 'ENABLE_CAPACITY_REPORTER',
            defaultValue: 'false',
            description: """Configure and enable capacity reporter"""
        )
        string(
            name: 'PREVIOUS_JOB_BUILD_ID',
            defaultValue: '',
            description: """Value is required if <b>ENABLE_CAPACITY_REPORTER</b> checkbox is selected.
                Value should be the build ID of the previous job, where the Spotfire platform was installed on the selected cluster.
                E.g. 234.
                """
        )
        booleanParam(
            name: 'ENABLE_OPTIONAL_FEATURES',
            defaultValue: 'false',
            description: """Activate optional features, that are required for development purposes only.
                <ul>
                    <li>Create LoadBalancer service for PSQL DB: use together with <b>INSTALL_SPOTFIRE_PLATFORM</b> parameter</li>
                    <li>Add admin rights for admin-sf user: use together with <b>SETUP_TLS_AND_SSO</b> parameter</li>
                </ul>
            """
        )
        string(
            name: 'ADP_APP_STAGING_GERRIT_REFSPEC',
            defaultValue: '',
            description: 'Gerrit refspec of the adp-app-staging repo e.g.: refs/changes/87/4641487/1'
        )
        string (
            name: 'CNINT_GERRIT_REFSPEC',
            defaultValue: '',
            description: 'Gerrit refspec of the cnint repo, e.g. refs/changes/87/4641487/1'
        )
    }
    stages {
        stage('Params DryRun check') {
            when {
                expression { params.DRY_RUN == true }
            }
            steps {
                script {
                    currentBuild.displayName = "DRY_RUN_COMPLETED"
                    currentBuild.getRawBuild().getExecutor().interrupt(Result.SUCCESS, new UserInterruption("This was done to update the build info"))
                    sleep (time: 1, unit: "SECONDS")
                }
            }
        }

        stage('Define Jenkins agent label') {
            steps {
                script {
                    lock('set-spotfire-asset-install-label') {
                        env.PARALLEL_JENKINS_URL = "https://seliius27102.seli.gic.ericsson.se:8443"
                        env.PARALLEL_JENKINS_CREDENTIALS_ID = 'test-jenkins-token' // Test Jenkins API Token Credential
                        if (env.MAIN_BRANCH != 'master') {
                            env.PARALLEL_JENKINS_URL = "https://seliius27190.seli.gic.ericsson.se:8443"
                            env.PARALLEL_JENKINS_CREDENTIALS_ID = 'jenkins-api-token' // Master Jenkins API Token Credential
                        }
                        echo "Checking agents with the spotfire asset install running on ${env.PARALLEL_JENKINS_URL} Jenkins instance"
                        withCredentials([usernamePassword(credentialsId: env.PARALLEL_JENKINS_CREDENTIALS_ID, usernameVariable: 'JENKINS_USER', passwordVariable: 'JENKINS_PASSWORD')]) {
                            env.AGENT_LABEL = "spotfire-asset-install-${env.JOB_NAME}-${env.BUILD_NUMBER}"
                            def parallelJenkinsAgentsJson = ''
                            def currentJenkinsAvailableAgent = ''
                            def agentLabelUpdated = false
                            while (!agentLabelUpdated) {
                                parallelJenkinsAgentsJson = sh(script: '''
                                    curl -s "$PARALLEL_JENKINS_URL"/computer/api/json --user $JENKINS_USER:$JENKINS_PASSWORD --insecure
                                ''', returnStdout: true).trim()
                                parallelJenkinsAgentsJson = parseJson(parallelJenkinsAgentsJson)
                                parallelJenkinsAgentsList = []
                                parallelJenkinsAgentsJson.computer.each { agent ->
                                    if ( agent.assignedLabels.name.find { agentLabels -> agentLabels.contains('spotfire-asset-install')} ) {
                                        parallelJenkinsAgentsList.add(agent.displayName)
                                    }
                                }
                                echo "spotfire-asset-install can't be executed on the following agents: ${parallelJenkinsAgentsList}. spotfire-asset-install-.* label for these nodes found on ${env.PARALLEL_JENKINS_URL} Jenkins instance"
                                currentJenkinsAvailableAgent = Jenkins.get().computers.find { !it.isOffline() && it.node.labelString.contains('productci') && !it.node.labelString.contains('spotfire-asset-install') && !parallelJenkinsAgentsList.contains(it.node.selfLabel.name) }
                                if (currentJenkinsAvailableAgent) {
                                    println(currentJenkinsAvailableAgent.node.selfLabel.name)
                                    env.NODE_NAME = currentJenkinsAvailableAgent.node.selfLabel.name
                                    env.OLD_NODE_LABELS = currentJenkinsAvailableAgent.node.labelString
                                    echo "Current labels for the ${env.NODE_NAME} node: ${env.OLD_NODE_LABELS}"
                                    currentJenkinsAvailableAgent.node.setLabelString("${env.OLD_NODE_LABELS}" + " ${env.AGENT_LABEL}")
                                    env.NEW_NODE_LABELS = currentJenkinsAvailableAgent.node.labelString
                                    echo "Updated labels for the ${env.NODE_NAME} node: ${env.NEW_NODE_LABELS}"
                                    agentLabelUpdated = true
                                } else {
                                    echo "An agent that meets the conditions on the current Jenkins was not found. Current agents statuses:"
                                    Jenkins.get().computers.each { currentJenkinsAgent ->
                                        echo "Name: ${currentJenkinsAgent.node.selfLabel.name}\nLabels: ${currentJenkinsAgent.node.labelString}\nIs online: ${currentJenkinsAgent.isOffline()}"
                                    }
                                    echo "Required conditions: online, contains 'productci' label, doesn't contain 'spotfire-asset-install-.*' label, not in the parallel Jenkins spotfire asset install list: ${parallelJenkinsAgentsList}"
                                    sleep(time:3, unit:"MINUTES")
                                }
                            }
                        }
                    }
                    echo "Jenkins agent with the ${env.AGENT_LABEL} label will be used for the build"
                    installBuildResult = build job: "spotfire-asset-install",
                    parameters: [
                        stringParam(name: 'AGENT_LABEL', value: "${env.AGENT_LABEL}"),
                        stringParam(name: 'CLUSTER_NAME', value : params.CLUSTER_NAME),
                        stringParam(name: 'EEA4_NS_NAME', value : params.EEA4_NS_NAME),
                        stringParam(name: 'OAM_POOL', value : params.OAM_POOL),
                        stringParam(name: 'SF_ASSET_VERSION', value : params.SF_ASSET_VERSION),
                        booleanParam(name: 'CLEANUP_SPOTFIRE', value: params.CLEANUP_SPOTFIRE),
                        booleanParam(name: 'INSTALL_SPOTFIRE_PLATFORM', value: params.INSTALL_SPOTFIRE_PLATFORM),
                        booleanParam(name: 'DEPLOY_STATIC_CONTENT', value: params.DEPLOY_STATIC_CONTENT),
                        stringParam(name: 'STATIC_CONTENT_PKG', value : params.STATIC_CONTENT_PKG),
                        booleanParam(name: 'SETUP_TLS_AND_SSO', value: params.SETUP_TLS_AND_SSO),
                        booleanParam(name: 'ENABLE_CAPACITY_REPORTER', value: params.ENABLE_CAPACITY_REPORTER),
                        stringParam(name: 'PREVIOUS_JOB_BUILD_ID', value : params.PREVIOUS_JOB_BUILD_ID),
                        booleanParam(name: 'ENABLE_OPTIONAL_FEATURES', value: params.ENABLE_OPTIONAL_FEATURES),
                        stringParam(name: 'ADP_APP_STAGING_GERRIT_REFSPEC', value : params.ADP_APP_STAGING_GERRIT_REFSPEC),
                        stringParam(name: 'CNINT_GERRIT_REFSPEC', value : params.CNINT_GERRIT_REFSPEC),
                        booleanParam(name: 'DRY_RUN', value: params.DRY_RUN)
                    ], wait: true
                    sh """ echo "SPOTFIRE_ASSET_INSTALL_NEW_BUILD_NUMBER=${installBuildResult.number}" > artifact.properties"""
                    archiveArtifacts artifacts: 'artifact.properties', allowEmptyArchive: true
                }
            }
        }
    }
}
