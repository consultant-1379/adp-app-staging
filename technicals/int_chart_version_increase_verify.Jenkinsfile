@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def git = new GitScm(this, 'EEA/cnint')

Map masterList = [:]
Map msList = [:]

pipeline {
    agent {
        node {
            label 'productci'
        }
    }

    options {
      skipDefaultCheckout()
      buildDiscarder(logRotator(daysToKeepStr: "7"))
    }

    environment {
        INT_CHART_NAME = 'eric-eea-int-helm-chart'
    }

    triggers {
        gerrit (
            serverName: 'GerritCentral',
            gerritProjects: [[
                    compareType: 'PLAIN',
                    pattern: 'EEA/cnint',
                    branches: [[ compareType: 'PLAIN', pattern: env.MAIN_BRANCH ]],
                    disableStrictForbiddenFileVerification: false,
                    topics: [[ compareType: 'REG_EXP', pattern: '^((?!^inca$).)*$' ]],
                    filePaths: [[ compareType: 'ANT', pattern: 'eric-eea-int-helm-chart/Chart.yaml' ]]
            ]],
            triggerOnEvents:  [
                [
                    $class              : 'PluginPatchsetCreatedEvent',
                    excludeDrafts       : false,
                    excludeTrivialRebase: false,
                    excludeNoCodeChange : false
                ],
                [
                    $class                      : 'PluginCommentAddedContainsEvent',
                    commentAddedCommentContains : '.*rebuild.*'
                ],
                [
                    $class                      : 'PluginDraftPublishedEvent'
                ]
            ]
        )
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
        stage('Collect original alias'){
            steps{
                script{
                    git.checkout(env.MAIN_BRANCH, 'cnint')
                    dir('cnint') {
                        script {
                            //Collecting original alias for comparing with new alias
                            def data = readYaml file: "${env.INT_CHART_NAME}/Chart.yaml"
                            data.dependencies.each { dependency ->
                                if (masterList [dependency.name]) {
                                    alias = masterList[dependency.name].alias
                                } else {
                                    alias = []
                                }
                                if (dependency.alias) {
                                    alias += dependency.alias
                                } else {
                                    alias += dependency.name
                                }
                                masterList [dependency.name] = ["version": dependency.version, "alias": alias]
                            }
                        }
                    }
                }
            }
        }
        stage('Checkout commit'){
            steps{
                script{
                    git.checkoutRefSpec("${GERRIT_REFSPEC}","FETCH_HEAD", 'cnint')
                }
            }
        }
        stage('cnint chart version increase check') {
            steps {
                dir('cnint'){
                    script {
                        try{
                            def result = sh(
                                    script: """git diff origin/master:eric-eea-int-helm-chart/Chart.yaml eric-eea-int-helm-chart/Chart.yaml | grep -Pzo "(name: eric-eea-int-helm-chart\\n-version)" """,
                                    returnStatus : true
                            )
                            echo """ $result """
                            if (result != 1){
                                echo "Manual eric-eea-int-helm-chart version change is forbidden"
                                currentBuild.result = 'FAILURE'
                            }
                        }catch (err) {
                            echo "Caught: ${err}"
                            currentBuild.result = 'FAILURE'
                        }
                    }
                }

            }
        }
        //Checking version numbers
        stage('Check version numbers in aliases') {
            steps {
                dir('cnint') {
                    script {
                        //Collect aliases
                        def data = readYaml file: "${env.INT_CHART_NAME}/Chart.yaml"
                        def errors = [:]
                        data.dependencies.each { dependency ->
                            if (msList[dependency.name]) {
                                alias = msList[dependency.name].alias
                            } else {
                                alias = []
                            }
                            if (dependency.alias) {
                                alias += dependency.alias
                            } else {
                                alias += dependency.name
                            }
                            //Checking versions
                            if (msList[dependency.name] && msList[dependency.name].version != dependency.version) {
                                if(!errors[dependency.name]){
                                    errors[dependency.name] = [dependency.version, msList[dependency.name].version]
                                }
                                else {
                                    errors[dependency.name].add(dependency.version)
                                }
                            }
                            msList[dependency.name] = ["version": dependency.version, "alias": alias]
                        }
                        if (errors.size() > 0) {
                            //Print errors
                            def msg = " Version differences were found for the following service(s):\n"
                            errors.each { name , versions  ->
                                def masterVersion = masterList[name].version
                                msg += "-service: ${name}, master alias version: ${masterVersion}\n new alias versions: ${versions}\n"
                            }
                            error "${msg}"
                        }
                    }
                }
            }
        }
    }
}
