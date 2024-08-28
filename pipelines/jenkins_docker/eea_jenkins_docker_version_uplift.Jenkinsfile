@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.Notifications
import groovy.transform.Field

@Field gitjd = new GitScm(this, 'EEA/jenkins-docker')
@Field notif = new Notifications(this)

def pluginsNotFound = []

properties([
    parameters([
        [$class: 'ChoiceParameter',
            choiceType: 'PT_CHECKBOX',
            name: 'PLUGINS_TO_ADD',
            description: 'In case a new plugin from Live Jenkins needs to be added to jenkins-docker, it can be selected here and added to the commit that will be created as a result of the build',
            filterable: true,
            filterLength: 1,
            script: [$class: 'GroovyScript',
                script: [
                    classpath: [],
                    sandbox: true,
                    script: """
                        import jenkins.model.*
                        result = []
                        try {
                            Jenkins.instance.pluginManager.plugins.each { plugin ->
                                result.add(plugin.getShortName()+":"+plugin.getVersion())
                            }
                        } catch (err) {
                            result.add(err)
                        }
                        return result
                    """
                ]
            ]
        ]
    ])
])

pipeline {
    agent {
        node {
            label 'productci'
        }
    }
    options {
        skipDefaultCheckout()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(daysToKeepStr: "7"))
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

        stage('Checkout jenkins-docker') {
            steps {
                script {
                    gitjd.checkout('master', 'jenkins-docker')
                }
            }
        }

        stage('Prepare') {
            steps {
                dir('jenkins-docker') {
                    checkoutGitSubmodules()
                }
            }
        }

        stage('Clean') {
            steps {
                dir('jenkins-docker') {
                    script {
                        sh 'bob/bob -r bob-rulesets/ruleset2.0.yaml clean'
                    }
                }
            }
        }

        stage('Keep original versions') {
            steps {
                script {
                    sh "cp jenkins-docker/docker/plugins.txt original-plugins.txt"
                    sh "cp jenkins-docker/bob-rulesets/ruleset2.0.yaml original-ruleset2.0.yaml"
                }
            }
        }

        stage('Update Jenkins version') {
            steps {
                dir('jenkins-docker') {
                    script {
                        env.OLD_JENKINS_VERSION = sh(script:"""grep -oP 'jenkins-docker-version: "\\K[^"]+' bob-rulesets/ruleset2.0.yaml""", returnStdout: true).trim()
                        env.NEW_JENKINS_VERSION = Jenkins.instance.getVersion()
                        sh "echo 'OLD_JENKINS_VERSION=${env.OLD_JENKINS_VERSION}'"
                        sh "echo 'NEW_JENKINS_VERSION=${env.NEW_JENKINS_VERSION}'"
                        sh """sed -i "s/${OLD_JENKINS_VERSION}/${NEW_JENKINS_VERSION}/" bob-rulesets/ruleset2.0.yaml"""
                        currentBuild.description = "OLD_JENKINS_VERSION ${env.OLD_JENKINS_VERSION}<br>NEW_JENKINS_VERSION ${env.NEW_JENKINS_VERSION}"
                    }
                }
            }
        }

        stage('Update plugins versions') {
            steps {
                dir('jenkins-docker') {
                    script {
                        def pluginsList = readFile(file: 'docker/plugins.txt').replaceAll("(?m)^[ \t]*\r?\n", "");
                        localPluginsList = pluginsList.split('\n')
                        localPluginsList.each { localPlugin ->
                            localPluginName = localPlugin.split(':')[0]
                            localPluginVersion = localPlugin.split(':')[1]
                            pluginFound = false
                            Jenkins.instance.pluginManager.plugins.find { jenkinsPlugin ->
                                if (localPluginName == jenkinsPlugin.getShortName()) {
                                    pluginFound = true
                                    if (localPluginVersion != jenkinsPlugin.getVersion()) {
                                        pluginsList = pluginsList.replaceAll(/${localPlugin}.*/, "${jenkinsPlugin.getShortName()}:${jenkinsPlugin.getVersion()}")
                                        echo "${localPlugin} updated to ${jenkinsPlugin.getShortName()}:${jenkinsPlugin.getVersion()}"
                                        return true
                                    } else {
                                        return true
                                    }
                                }
                            }
                            if ( !pluginFound ) {
                                pluginsNotFound.add(localPluginName)
                                echo "${localPlugin} not found in the Jenkins plugins list. Please create a commit to update the plugin version manually"
                            }
                        }
                        currentBuild.description += "<br>Plugins not found (manual commit needed): " + pluginsNotFound
                        writeFile(file: 'docker/plugins.txt', text: pluginsList)
                    }
                }
            }
        }

        stage('Add new plugins') {
            when {
                expression { PLUGINS_TO_ADD }
            }
            steps {
                dir('jenkins-docker') {
                    script {
                        def pluginsList = readFile(file: 'docker/plugins.txt').replaceAll("(?m)^[ \t]*\r?\n", "");
                        pluginsToAddList = PLUGINS_TO_ADD.split(',')
                        pluginsToAddList.each { plugin ->
                            pluginName = plugin.split(':')[0]
                            pluginVersion = plugin.split(':')[1]
                            if (!pluginsList.contains(pluginName)) {
                                pluginsList = pluginsList.concat("\n${plugin}")
                                echo "${plugin} has been added to the list of plugins"
                            } else {
                                echo "${plugin} found in the list of plugins. Skipping..."
                            }
                        }
                        writeFile(file: 'docker/plugins.txt', text: pluginsList)
                    }
                }
            }
        }

        stage('Check for difference') {
            steps {
                script {
                    env.VERIONS_DIFFERENCE_FOUND = sh(script:"""
                        diff -c ${WORKSPACE}/original-ruleset2.0.yaml ${WORKSPACE}/jenkins-docker/bob-rulesets/ruleset2.0.yaml > ruleset2.0.yaml.diff || echo True
                        diff -c ${WORKSPACE}/original-plugins.txt ${WORKSPACE}/jenkins-docker/docker/plugins.txt > plugins.txt.diff || echo True
                    """, returnStdout: true).trim()
                    archiveArtifacts artifacts: "ruleset2.0.yaml.diff", allowEmptyArchive: true
                    archiveArtifacts artifacts: "plugins.txt.diff", allowEmptyArchive: true
                }
            }
        }

        stage('Create Gerrit change') {
            when {
                expression { env.VERIONS_DIFFERENCE_FOUND }
            }
            steps {
                dir('jenkins-docker') {
                    script {
                        gitjd.createPatchset(".", "Jenkins and plugins versions uplift")
                        def git_id = gitjd.getCommitHashLong()
                        env.GERRIT_REFSPEC = gitjd.getCommitRefSpec(git_id)
                        env.GERRIT_REFSPEC_URL = getGerritLink(env.GERRIT_REFSPEC)
                        currentBuild.description += "<br>Gerrit refspec: " + env.GERRIT_REFSPEC_URL
                    }
                }
            }
        }
    }
    post {
        success {
            script {
                if (!params.DRY_RUN) {
                    def subject = "${env.JOB_NAME} (${env.BUILD_NUMBER}) SUCCESS"
                    def body_message = "<a href=\"${env.BUILD_URL}\">${env.BUILD_URL}</a><br>Jenkins and plugins versions in EEA/jenkins-docker repository were automatically updated.<br>A new commit ${env.GERRIT_REFSPEC_URL} was prepared and should be approved"
                    notif.sendMail(subject, body_message, "517d5a14.ericsson.onmicrosoft.com@emea.teams.ms", "text/html")
                }
            }
        }
        failure {
            script {
                def subject = "${env.JOB_NAME} (${env.BUILD_NUMBER}) FAILURE"
                def body_message = "<a href=\"${env.BUILD_URL}\">${env.BUILD_URL}</a><br>Jenkins and plugins versions uplift in EEA/jenkins-docker FAILED. Please check the build"
                notif.sendMail(subject, body_message, "517d5a14.ericsson.onmicrosoft.com@emea.teams.ms", "text/html")
            }
        }
        cleanup {
            cleanWs()
        }
    }
}
