@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def gitcnint = new GitScm(this, "EEA/cnint")

def labelsToRemoveList = []
def agentsNamesToCleanupList = []
def agentsToCleanupList = []
def defaultAgentLabelCleanupGroup = 'EEA4\\ CI\\ team'

pipeline {
    agent {
        label 'productci'
    }

    triggers {
        upstream(upstreamProjects: "eea-common-product-upgrade", threshold: hudson.model.Result.ABORTED)
    }

    parameters {
        string(name: 'LABEL_TO_REMOVE_LIST', description: 'Comma-separated list of labels to remove from the Jenkins agent. E.g: label-1,label-2,label-n', defaultValue: '')
        string(name: 'JENKINS_AGENTS_LIST', description: 'Comma-separated list of Jenkins agent to remove label from. E.g; agent-1,agent-2,agent-n', defaultValue: '')
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

        stage('Check upstream build') {
            steps {
                script {
                    def upstream = currentBuild.rawBuild.getCause(hudson.model.Cause$UpstreamCause)
                    env.UPSTREAM_PROJECT_NAME = upstream?.upstreamProject
                    env.UPSTREAM_PROJECT_BUILD_NUMBER = upstream?.upstreamBuild
                    if ( env.UPSTREAM_PROJECT_NAME == 'eea-common-product-upgrade' ) {
                        labelsToRemoveList.add("common-offline-upgrade-${env.UPSTREAM_PROJECT_NAME}-${env.UPSTREAM_PROJECT_BUILD_NUMBER}")
                        env.REMOVE_UPSTREAM_BUILD_DEFINED_LABEL = true
                    }
                }
            }
        }

        stage('Check variables') {
            when {
                expression { !env.REMOVE_UPSTREAM_BUILD_DEFINED_LABEL }
            }
            steps {
                script {
                    if ( params.LABEL_TO_REMOVE_LIST ) {
                        labelsToRemoveList = params.LABEL_TO_REMOVE_LIST.split(',')
                    } else {
                        error("params.LABEL_TO_REMOVE_LIST is not specified")
                    }
                    if ( params.JENKINS_AGENTS_LIST ) {
                        agentsNamesToCleanupList = params.JENKINS_AGENTS_LIST.split(',')
                    } else {
                        error "params.JENKINS_AGENTS_LIST is not specified"
                    }
                    if ( labelsToRemoveList && agentsNamesToCleanupList ) {
                        echo "${labelsToRemoveList} labels will be removed from the following Jenkins agents: ${agentsNamesToCleanupList}"
                    }
                }
            }
        }

        stage('Remove labels from the agents') {
            steps {
                script {
                    labelsToRemoveList.each { labelToRemove ->
                        if ( env.REMOVE_UPSTREAM_BUILD_DEFINED_LABEL ) {
                            echo "Search for a ${labelToRemove} label among all agents"
                            agentsToCleanupList = Jenkins.get().computers.findAll { it.node.labelString.contains("${labelToRemove}") }
                        } else if ( agentsNamesToCleanupList ) {
                            agentsToCleanupList = []
                            echo "Search for a ${labelToRemove} labels on ${agentsNamesToCleanupList} agents"
                            agentsNamesToCleanupList.each { agentName ->
                                if ( Jenkins.get().computers.find {it.node.selfLabel.name == "${agentName}" && it.node.labelString.contains("${labelToRemove}")} ) {
                                    echo "[${agentName}] ${labelToRemove} found for the Jenkins agent"
                                    agentsToCleanupList.add(Jenkins.get().computers.find {it.node.selfLabel.name == "${agentName}" && it.node.labelString.contains("${labelToRemove}")})
                                } else {
                                    echo "[${agentName}] ${labelToRemove} not found for the Jenkins agent. Label removal will be skipped for this agent"
                                }
                            }
                        }
                        if ( agentsToCleanupList ) {
                            agentsToCleanupList.each { agent ->
                                echo "[${agent.node.selfLabel.name}] Current labels for the agent: ${agent.node.labelString}"
                                agent.node.setLabelString("${agent.node.labelString}" - "${labelToRemove}")
                                echo "[${agent.node.selfLabel.name}] Updated labels for the agent: ${agent.node.labelString}"
                            }
                        } else {
                            echo "${labelToRemove} label was not found on Jenkins agents"
                        }
                    }
                }
            }
        }
    }
}