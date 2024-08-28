@Library('ci_shared_library_eea4') _

import groovy.transform.Field

import com.ericsson.eea4.ci.GitScm

@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitdeployer = new GitScm(this, 'EEA/deployer')

pipeline {
    agent {
        node {
            label 'master'
        }
    }
    tools{
        gradle "Default"
    }
    options {
        ansiColor('xterm')
        skipDefaultCheckout()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(daysToKeepStr: "7"))
    }
    parameters {
        string(name: 'GIT_BRANCH', description: 'Git branch or tag of the EEA/deployer git repo e.g.: 1.0.0-1', defaultValue: 'master')
        string(name: 'GERRIT_REFSPEC', description: 'Gerrit Refspec of the EEA/deployer git repo e.g.: refs/changes/82/13836482/2', defaultValue: '')
        string(name: 'CHART_VERSION', description: 'DEPLOYER chart version e.g.: 0.1.0-he3089c5', defaultValue: '')
        string(name: 'SPINNAKER_ID', description: "The spinnaker execution's id", defaultValue: '')
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
                expression { env.GERRIT_REFSPEC && !env.GERRIT_REFSPEC.contains('refs/tags')}
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

        stage('Checkout - EEA/adp-app-staging') {
            steps {
                script {
                    gitadp.checkout('master', 'adp-app-staging')
                }
            }
        }

        stage('Checkout - EEA/deployer') {
            steps {
                script {
                    if (!params.GIT_BRANCH?.trim() && !params.GERRIT_REFSPEC?.trim()) {
                        error "GIT_BRANCH or GERRIT_REFSPEC should be specified!"
                    }
                    if(params.GIT_BRANCH?.trim() && params.GERRIT_REFSPEC?.trim()) {
                        error "Only one of the GIT_BRANCH or GERRIT_REFSPEC should be specified!"
                    }
                    if (params.GERRIT_REFSPEC?.trim()) {
                        gitdeployer.checkoutRefSpec('${GERRIT_REFSPEC}', 'FETCH_HEAD', 'deployer')
                    } else {
                        gitdeployer.checkout('${GIT_BRANCH}', 'deployer')
                    }
                }
            }
        }

        stage('Generate xml') {
            steps {
                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                    script {
                        sh (
                            script: "export JAVA_HOME=/proj/cea/tools/environments/jdk/jdk-11.0.6 ; cd deployer && ls jenkins/*.groovy > ${WORKSPACE}/env_inject"
                        )
                        def result = readFile("env_inject")
                        echo "${result}"
                        if (result.size() != 0){
                            echo "result not null"
                            def files = result.split("\\r?\\n")
                            script{
                                for (filename in files) {
                                    def result_generation = sh(
                                        script: "export JAVA_HOME=/proj/cea/tools/environments/jdk/jdk-11.0.6 ; cd deployer && gradle genJob -Partifactory_contextUrl=${ARM_CONTEXT_URL} -PjobFileName=${filename} -g ${WORKSPACE}/gradle",
                                        returnStatus : true
                                    )
                                    sh "echo ${result_generation}"
                                    if (result_generation != 0){
                                        currentBuild.result = 'FAILURE'
                                    }
                                }
                            }
                            def result_validation = sh(
                                script: "cd deployer/build/jenkins; python ${WORKSPACE}/adp-app-staging/technicals/pythonscripts/jobdslgroovycontent.py",
                                returnStatus : true
                            )
                            sh "echo ${result_validation}"
                            if (result_validation != 0){
                                currentBuild.result = 'FAILURE'
                            }

                            if ( params.GERRIT_REFSPEC && params.CHART_VERSION ) {
                                env.DEPLOYER_CHART_VERSION = params.CHART_VERSION
                            } else {
                                dir('deployer') {
                                    def deployer_chart = readYaml file: 'helm/eric-eea-deployer/Chart.yaml'
                                    env.DEPLOYER_CHART_VERSION = deployer_chart.version
                                }
                            }
                            currentBuild.description += "DEPLOYER Chart version: ${env.DEPLOYER_CHART_VERSION}"

                            sh """
                            cd deployer/build/jenkins
                            for file_name in \$(ls *.xml)
                            do
                                file_name_without_extension="\${file_name%.xml}"
                                sed -i "s#<description></description>#<description>\${file_name_without_extension}:${env.DEPLOYER_CHART_VERSION}</description>#" "\${file_name}"
                                mv "\${file_name}" "\${file_name_without_extension}-${env.DEPLOYER_CHART_VERSION}.xml"
                            done
                            """
                            archiveArtifacts artifacts: "deployer/build/jenkins/*.xml".replaceAll(' ', '_'), allowEmptyArchive: true
                        }
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                }
            }
        }
    }
    post {
        success {
            script {
                if (env.GERRIT_REFSPEC && !env.GERRIT_REFSPEC.contains('refs/tags')) {
                    env.GERRIT_MSG = "Build Successful ${BUILD_URL}: SUCCESS"
                    sendMessageToGerrit(env.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }
        failure {
            script {
                if (env.GERRIT_REFSPEC && !env.GERRIT_REFSPEC.contains('refs/tags')) {
                    env.GERRIT_MSG = "Build Failed ${BUILD_URL}: FAILURE"
                    sendMessageToGerrit(env.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }
        cleanup {
            cleanWs()
        }
    }
}
