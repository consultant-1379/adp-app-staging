@Library('ci_shared_library_eea4') _

import groovy.transform.Field

import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.Artifactory
import com.ericsson.eea4.ci.Artifactory

@Field def gitcdd = new GitScm(this, 'EEA/cdd')
@Field def gitdocker = new GitScm(this, 'EEA/jenkins-docker')
@Field def arm = new Artifactory(this, "https://arm.seli.gic.ericsson.se/", "API_TOKEN_EEA")

@NonCPS
def generatePackageNames (xml) {
    def xmlData = new XmlSlurper().parseText(xml)
    def packagesToRename = [:]
    xmlData.Boxes.children().each { box ->
        packageName = box.ProductNumber.text().replace("/", "_")+'-'+box.RState.text()
        echo "Generated packageName ${packageName}"
        packagesToRename[box.Filename.text()] = "${packageName}.zip"
        box.Filename.replaceBody "${packageName}.zip"
    }
    updatedXmlData = groovy.xml.XmlUtil.serialize(xmlData)
    return [updatedXmlData, packagesToRename]
}

@NonCPS
def updateXmlMD5 (xml, md5Sums) {
    def xmlData = new XmlSlurper().parseText(xml)
    xmlData.Boxes.children().each { box ->
        for (md5Sum in md5Sums) {
            if (md5Sum.key == box.Filename.text()) {
                box.MD5.replaceBody "${md5Sum.value}"
                break
            }
        }
    }
    updatedXmlData = groovy.xml.XmlUtil.serialize(xmlData)
    return updatedXmlData
}

@NonCPS
def updateTicketNumber (xml, ticketNumber) {
    def xmlData = new XmlSlurper().parseText(xml)
    xmlData.TicketID.replaceBody "${ticketNumber}"
    updatedXmlData = groovy.xml.XmlUtil.serialize(xmlData)
    return updatedXmlData
}

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
    parameters {
        string(name: 'CHART_VERSION', description: 'CDD chart version e.g.: 0.1.0-he3089c5', defaultValue: '')
        string(name: 'GERRIT_REFSPEC', description: 'Gerrit Refspec of the cdd git repo e.g.: refs/changes/82/13836482/2', defaultValue: '')
        string(name: 'SPINNAKER_TRIGGER_URL', description: 'Spinnaker pipeline triggering url', defaultValue: '')
        string(name: 'SPINNAKER_ID', description: "The spinnaker execution's id", defaultValue: '')
        booleanParam(name: 'SEND_MESSAGE_TO_GERRIT', description: "If a parent job is a cdd release one the sending message to gerrit should be omitted as there is used non-ordinal Gerrit refspec!", defaultValue: true)
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

        stage('Gerrit message') {
            when {
              expression {env.GERRIT_REFSPEC && params.SEND_MESSAGE_TO_GERRIT}
            }
            steps {
                script {
                    env.GERRIT_MSG = "Build Started ${BUILD_URL}"
                    sendMessageToGerrit(env.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
             }
        }

        stage('Set build description') {
            steps {
                script {
                    currentBuild.description = ''
                    if (env.GERRIT_REFSPEC) {
                        def gerritLink = getGerritLink(env.GERRIT_REFSPEC)
                        currentBuild.description += gerritLink
                    } else {
                        def link = '<a href="' + env.BUILD_NUMBER + '/console">' + params.CHART_VERSION + '</a>'
                        currentBuild.description += link
                    }
                    if (params.SPINNAKER_ID) {
                        currentBuild.description += '<br><a href="https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/details/' + params.SPINNAKER_ID + '">Spinnaker URL: ' + params.SPINNAKER_ID + '</a>'
                    }
                }
            }
        }

        stage('Checkout') {
            steps {
                script {
                    gitcdd.checkout('master', 'cdd')
                    gitdocker.checkout('master', 'jenkins-docker')
                }
            }
        }

        stage('EEA/cdd repo change checkout') {
            when {
                expression {params.GERRIT_REFSPEC}
            }
            steps {
                dir('cdd') {
                    script {
                        if(!params.SEND_MESSAGE_TO_GERRIT) {
                            gitcdd.checkoutRefSpec("${params.GERRIT_REFSPEC}", "FETCH_HEAD", "")
                        } else {
                            gitcdd.fetchAndCherryPick('EEA/cdd', "${params.GERRIT_REFSPEC}")
                        }
                    }
                }
            }
        }

        stage('Prepare structure') {
            steps {
                script {
                    sh 'mkdir -p cdd-package-workdir/pipeline_package/swdp-cdd/product'
                }
            }
        }

        stage('Gather system requirements') {
            steps {
                script {
                    dir('jenkins-docker') {

                        def systemRequirements = [:]
                        def jenkinsDockerVersion

                        def jenkinsDockerRequiredMemory = '4 GB+'
                        def jenkinsDockerRequiredDisk = '128 GB'
                        def jenkinsDockerJavaVersion = 'jdk-11.0.20+8 (Eclipse Temurin OpenJDK)'
                        def jenkinsDockerNotes = 'Execute Docker commands inside Jenkins nodes (Docker in Docker feature) is required by EEA jobs.'

                        // get Jenkins docker requirements from ruleset
                        def rulesetData = readYaml file: 'bob-rulesets/ruleset2.0.yaml'
                        def propertiesList = rulesetData['properties']
                        propertiesList.each {prop ->
                            if (prop['jenkins-docker-version']) {
                                jenkinsDockerVersion = prop['jenkins-docker-version']
                            }
                        }

                        // get Jenkins plugins from file
                        def pluginsList = readFile(file: 'docker/plugins.txt').readLines()

                        // construct yaml file
                        systemRequirements['required-memory'] = jenkinsDockerRequiredMemory
                        systemRequirements['required-disk-space'] = jenkinsDockerRequiredDisk
                        systemRequirements['jenkins-version'] = jenkinsDockerVersion
                        systemRequirements['java-version'] = jenkinsDockerJavaVersion
                        systemRequirements['jenkins-plugins'] = pluginsList
                        systemRequirements['notes'] = jenkinsDockerNotes

                        // write yaml
                        writeYaml file: "${WORKSPACE}/cdd-package-workdir/requirements.yaml", data: systemRequirements, overwrite: true
                    }
                }
            }
        }

        stage('Generate pipeline_package') {
            steps {
                script {
                    sh """
                        cp -R cdd/product/source/pipeline_package/swdp-cdd/ cdd-package-workdir/pipeline_package/
                        rm -rf cdd-package-workdir/pipeline_package/swdp-cdd/product/jenkins/*
                    """
                    if (params.GERRIT_REFSPEC) {
                        env.GIT_BRANCH = ""
                    } else {
                        env.GIT_BRANCH = "master"
                    }
                    xmlGeneratorBuildData = build job: "eea-jenkins-docker-xml-generator", parameters: [
                        stringParam(name: 'GIT_BRANCH', value: "${env.GIT_BRANCH}"),
                        stringParam(name: 'GERRIT_REFSPEC', value : "${env.GERRIT_REFSPEC}"),
                        stringParam(name: 'CHART_VERSION', value : params.CHART_VERSION),
                        stringParam(name: 'SPINNAKER_ID', value : params.SPINNAKER_ID),
                        booleanParam(name: 'SEND_MESSAGE_TO_GERRIT', value: params.SEND_MESSAGE_TO_GERRIT)
                    ], wait: true
                    env.XML_GENERATOR_BUILD_NUMBER = xmlGeneratorBuildData.number
                    copyArtifacts(
                        projectName: "eea-jenkins-docker-xml-generator",
                        selector: specific("${env.XML_GENERATOR_BUILD_NUMBER}"),
                        filter: '**/*.xml',
                        flatten: true,
                        target: 'cdd-package-workdir/pipeline_package/swdp-cdd/product/jenkins/',
                        fingerprintArtifacts: true
                    )
                    dir('cdd-package-workdir/pipeline_package') {
                        sh "tar -czf ${WORKSPACE}/cdd-package-workdir/swdp-cdd.tar.gz swdp-cdd"
                    }
                }
            }
        }

        stage('Publish CDD pipeline package') {
            steps {
                script {
                    dir('cdd-package-workdir') {
                        withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                        string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                        string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                        usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                            arm.setUrl("https://arm.seli.gic.ericsson.se/", "$API_TOKEN_EEA")
                            if(!params.SEND_MESSAGE_TO_GERRIT) {
                                arm.setRepo('proj-eea-released-generic-local')
                            } else {
                                arm.setRepo('proj-eea-internal-generic-local')
                            }
                            arm.deployArtifact( "swdp-cdd.tar.gz", "swdp-cdd-${env.CHART_VERSION}.tar.gz")
                            arm.deployArtifact( "requirements.yaml", "swdp-cdd-${env.CHART_VERSION}-requirements.yaml")
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                if ( params.GERRIT_REFSPEC && params.SEND_MESSAGE_TO_GERRIT) {
                    env.GERRIT_MSG = "Build result ${BUILD_URL}: ${currentBuild.result}"
                    sendMessageToGerrit(params.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }
        cleanup {
            cleanWs()
        }
    }
}
