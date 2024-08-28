@Library('ci_shared_library_eea4') _
import com.ericsson.eea4.ci.Artifactory
import groovy.transform.Field

@Field def arm = new Artifactory(this, "https://arm.seli.gic.ericsson.se/",  "API_TOKEN_EEA")

pipeline {
    agent {
        node {
            label 'productci'
        }
    }

    options {
        buildDiscarder(logRotator(daysToKeepStr: '30', artifactNumToKeepStr: "30"))
        disableConcurrentBuilds()
    }

    triggers { cron('00 21 * * *') } //run at 9PM every day

    parameters {
        booleanParam(name: 'HELM_CLEANUP_ENABLED', description: 'Execute helm repo cleanup if parameter is enabled e.g.: true', defaultValue: true)
        booleanParam(name: 'CSAR_CLEANUP_ENABLED', description: 'Execute csar repo cleanup if parameter is enabled e.g.: true', defaultValue: true)
        booleanParam(name: 'DOCKER_CLEANUP_ENABLED', description: 'Execute docker repo cleanup if parameter is enabled e.g.: true', defaultValue: true)
        booleanParam(name: 'DOCS_CLEANUP_ENABLED', description: 'Execute docs repo cleanup if parameter is enabled e.g.: true', defaultValue: true)
        booleanParam(name: 'REPORTS_DIMTOOL_CLEANUP_ENABLED', description: 'Execute reports repo dimtool cleanup if parameter is enabled e.g.: true', defaultValue: true)
        booleanParam(name: 'REPORTS_MICROSERVICE_CLEANUP_ENABLED', description: 'Execute reports repo microservice cleanup if parameter is enabled e.g.: true', defaultValue: true)
        booleanParam(name: 'REPORTS_INT_CHART_CLEANUP_ENABLED', description: 'Execute reports repo int chart cleanup if parameter is enabled e.g.: true', defaultValue: true)
        booleanParam(name: 'REPORTS_CLUSTER_LOG_CLEANUP_ENABLED', description: 'Execute reports repo cluster log cleanup if parameter is enabled e.g.: true', defaultValue: true)
        booleanParam(name: 'APPLICATION_DASHBOARD_CLEANUP_ENABLED', description: 'Execute application dashboard backups cleanup if parameter is enabled e.g.: true', defaultValue: true)
        booleanParam(name: 'CLEANUP_DIMTOOL_FOLDER',  description: 'Execute dim-tool repo cleanup if parameter is enabled e.g.: true',  defaultValue: true)
        string(name: 'HELM_FILTER_LIMIT', description: 'Limiting number of resulted rows for AQL e.g.: 100', defaultValue: '5000')
        string(name: 'CSAR_FILTER_LIMIT', description: 'Limiting number of resulted rows for AQL e.g.: 100', defaultValue: '5000')
        string(name: 'DOCKER_FILTER_LIMIT', description: 'Limiting number of resulted rows for AQL e.g.: 100', defaultValue: '5000')
        string(name: 'DOCS_FILTER_LIMIT', description: 'Limiting number of resulted rows for AQL e.g.: 100', defaultValue: '5000')
        string(name: 'REPORTS_FILTER_LIMIT', description: 'Limiting number of resulted rows for AQL e.g.: 100', defaultValue: '5000')
        string(name: 'APPLICATION_DASHBOARD_FILTER_LIMIT', description: 'Limiting number of resulted rows for AQL e.g.: 100', defaultValue: '5000')
        booleanParam(name: 'LIST_ONLY', description: 'Do not delete artifacts, only listing enabled e.g.: false', defaultValue: false)
        booleanParam(name: 'EMAIL_ALERT_ENABLED', description: 'Send email alert to Jenkins alerts teams channel if execution is failing', defaultValue: true)
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

        stage('Run when run in Jenkins master'){
          when {
            expression { env.MAIN_BRANCH == 'master' }
          }
            stages{

                stage('Cleanup Artifactory - CSAR internal') {
                    when {
                        expression { params.CSAR_CLEANUP_ENABLED == true }
                    }
                    steps{
                        script {
                            catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                                withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                                 string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                                 usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                                    arm.setUrl('https://arm.seli.gic.ericsson.se/', "$API_TOKEN_EEA")

                                    Map args = [
                                        "repo": "proj-eea-internal-generic-local",
                                        "name": "*.csar",
                                        "createdBefore": "1mo",
                                        "limit": params.CSAR_FILTER_LIMIT,
                                        "dryRun": params.LIST_ONLY
                                    ]

                                    def failCount = arm.cleanupArtifact(args)
                                    if (failCount) {
                                        currentBuild.result = "UNSTABLE"
                                        currentBuild.description = "There are ${failCount} error while deleting artifacts on ARM. (CSAR internal)"
                                        echo(currentBuild.description)
                                    }
                                }
                            }
                        }
                    }
                }

                stage('Cleanup Artifactory - CSAR drop') {
                    when {
                        expression { params.CSAR_CLEANUP_ENABLED == true }
                    }
                    steps{
                        script {
                            catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                                withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                                 string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                                 usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                                    arm.setUrl('https://arm.seli.gic.ericsson.se/', "$API_TOKEN_EEA")

                                    Map args = [
                                        "repo": "proj-eea-drop-generic-local",
                                        "name": "*.csar",
                                        "createdBefore": "1mo",
                                        "artifactsToKeep": 5,
                                        "limit": params.CSAR_FILTER_LIMIT,
                                        "dryRun": params.LIST_ONLY
                                    ]

                                    def failCount = arm.cleanupArtifact(args)
                                    if (failCount) {
                                        currentBuild.result = "UNSTABLE"
                                        currentBuild.description = "There are ${failCount} error while deleting artifacts on ARM. (CSAR drop)"
                                        echo(currentBuild.description)
                                    }
                                }
                            }
                        }
                    }
                }

                stage('Cleanup Artifactory - HELM dev') {
                    when {
                        expression { params.HELM_CLEANUP_ENABLED == true }
                    }
                    steps{
                        script {
                            catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                                withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                                 string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                                 usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                                    arm.setUrl('https://arm.seli.gic.ericsson.se/', "$API_TOKEN_EEA")

                                    Map args = [
                                        "repo": "proj-eea-dev-helm-local",
                                        "name": "*.tgz",
                                        "createdBefore": "1mo",
                                        "limit": params.HELM_FILTER_LIMIT,
                                        "dryRun": params.LIST_ONLY
                                    ]

                                    def failCount = arm.cleanupArtifact(args)
                                    if (failCount) {
                                        currentBuild.result = "UNSTABLE"
                                        currentBuild.description = "There are ${failCount} error while deleting artifacts on ARM. (HELM dev)"
                                        echo(currentBuild.description)
                                    }
                                }
                            }
                        }
                    }
                }

                stage('Cleanup Artifactory - HELM internal') {
                    when {
                        expression { params.HELM_CLEANUP_ENABLED == true }
                    }
                    steps{
                        script {
                            catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                                withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                                 string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                                 usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                                    arm.setUrl('https://arm.seli.gic.ericsson.se/', "$API_TOKEN_EEA")

                                    Map args = [
                                        "repo": "proj-eea-ci-internal-helm-local",
                                        "name": "*.tgz",
                                        "createdBefore": "1mo",
                                        "limit": params.HELM_FILTER_LIMIT,
                                        "dryRun": params.LIST_ONLY
                                    ]

                                    def failCount = arm.cleanupArtifact(args)
                                    if (failCount) {
                                        currentBuild.result = "UNSTABLE"
                                        currentBuild.description = "There are ${failCount} error while deleting artifacts on ARM. (HELM internal)"
                                        echo(currentBuild.description)
                                    }
                                }
                            }
                        }
                    }
                }

                stage('Cleanup Artifactory - HELM drop') {
                    when {
                        expression { params.HELM_CLEANUP_ENABLED == true }
                    }
                    steps{
                        script {
                            catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                                withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                                 string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                                 usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                                    arm.setUrl('https://arm.seli.gic.ericsson.se/', "$API_TOKEN_EEA")

                                    Map args = [
                                        "repo": "proj-eea-drop-helm-local",
                                        "name": "*.tgz",
                                        "createdBefore": "1mo",
                                        "downloadedBefore": "30d",
                                        "artifactsToKeep": 5,
                                        "limit": params.HELM_FILTER_LIMIT,
                                        "dryRun": params.LIST_ONLY,
                                        "checkArtifactInReleasedRepo": true,
                                        "skipCleanup": true
                                    ]

                                    def failCount = arm.cleanupArtifact(args)
                                    if (failCount) {
                                        currentBuild.result = "UNSTABLE"
                                        currentBuild.description = "There are ${failCount} error while deleting artifacts on ARM. (HELM drop)"
                                        echo(currentBuild.description)
                                    }
                                }
                            }
                        }
                    }
                }

                stage('Cleanup Artifactory - DOCKER dev') {
                    when {
                        expression { params.DOCKER_CLEANUP_ENABLED == true }
                    }
                    steps{
                        script {
                            catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                                withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                                 string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                                 usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                                    arm.setUrl('https://arm.seli.gic.ericsson.se/', "$API_TOKEN_EEA")

                                    Map args = [
                                        "repo": "proj-eea-dev-docker-global",
                                        "path": "proj-eea-dev/*",
                                        "name": "manifest*.json",
                                        "createdBefore": "1mo",
                                        "limit": params.DOCKER_FILTER_LIMIT,
                                        "dryRun": params.LIST_ONLY,
                                        "deleteParentDir": true
                                    ]

                                    def failCount = arm.cleanupArtifact(args)
                                    if (failCount) {
                                        currentBuild.result = "UNSTABLE"
                                        currentBuild.description = "There are ${failCount} error while deleting artifacts on ARM. (DOCKER dev)"
                                        echo(currentBuild.description)
                                    }
                                }
                            }
                        }
                    }
                }

                stage('Cleanup Artifactory - DOCKER internal') {
                    when {
                        expression { params.DOCKER_CLEANUP_ENABLED == true }
                    }
                    steps{
                        script {
                            catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                                withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                                 string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                                 usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                                    arm.setUrl('https://arm.seli.gic.ericsson.se/', "$API_TOKEN_EEA")

                                    Map args = [
                                        "repo": "proj-eea-ci-internal-docker-global",
                                        "path": "proj-eea-ci-internal/*",
                                        "name": "manifest*.json",
                                        "createdBefore": "1mo",
                                        "limit": params.DOCKER_FILTER_LIMIT,
                                        "dryRun": params.LIST_ONLY,
                                        "deleteParentDir": true
                                    ]

                                    def failCount = arm.cleanupArtifact(args)
                                    if (failCount) {
                                        currentBuild.result = "UNSTABLE"
                                        currentBuild.description = "There are ${failCount} error while deleting artifacts on ARM. (DOCKER internal)"
                                        echo(currentBuild.description)
                                    }
                                }
                            }
                        }
                    }
                }

                stage('Cleanup Artifactory - DOCKER drop') {
                    when {
                        expression { params.DOCKER_CLEANUP_ENABLED == true }
                    }
                    steps{
                        script {
                            catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                                withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                                 string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                                 usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                                    arm.setUrl('https://arm.seli.gic.ericsson.se/', "$API_TOKEN_EEA")

                                    Map args = [
                                        "repo": "proj-eea-drop-docker-global",
                                        "path": "proj-eea-drop/*",
                                        "name": "manifest*.json",
                                        "createdBefore": "1mo",
                                        "downloadedBefore": "30d",
                                        "artifactsToKeep": 5,
                                        "limit": params.DOCKER_FILTER_LIMIT,
                                        "dryRun": params.LIST_ONLY,
                                        "deleteParentDir": true,
                                        "checkArtifactInReleasedRepo": true,
                                        "skipCleanup": true
                                    ]

                                    def failCount = arm.cleanupArtifact(args)
                                    if (failCount) {
                                        currentBuild.result = "UNSTABLE"
                                        currentBuild.description = "There are ${failCount} error while deleting artifacts on ARM. (DOCKER internal)"
                                        echo(currentBuild.description)
                                    }
                                }
                            }
                        }
                    }
                }

                stage('Cleanup Artifactory - DOCS drop') {
                    when {
                        expression { params.DOCS_CLEANUP_ENABLED == true }
                    }
                    steps{
                        script {
                            catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                                withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                                 string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                                 usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                                    arm.setUrl('https://arm.seli.gic.ericsson.se/', "$API_TOKEN_EEA")

                                    Map args = [
                                        "repo": "proj-eea-docs-drop-generic-local",
                                        "path": "eric-*",
                                        "createdBefore": "1mo",
                                        "createdLast": "2mo",
                                        "downloadedBefore": "30d",
                                        "artifactsToKeep": 5,
                                        "limit": params.DOCS_FILTER_LIMIT,
                                        "dryRun": params.LIST_ONLY,
                                        "checkArtifactInReleasedRepo": true
                                    ]

                                    def failCount = arm.cleanupArtifact(args)
                                    if (failCount) {
                                        currentBuild.result = "UNSTABLE"
                                        currentBuild.description = "There are ${failCount} error while deleting artifacts on ARM. (DOCS drop)"
                                        echo(currentBuild.description)
                                    }
                                }
                            }
                        }
                    }
                }

                stage('Cleanup Artifactory - REPORTS - dimensioning tool plugins') {
                    when {
                        expression { params.REPORTS_DIMTOOL_CLEANUP_ENABLED == true }
                    }
                    steps{
                        script {
                            catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                                withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                                 string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                                 usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                                    arm.setUrl('https://arm.seli.gic.ericsson.se/', "$API_TOKEN_EEA")

                                    Map args = [
                                        "repo": "proj-eea-reports-generic-local",
                                        "path": "dimtool/*",
                                        "createdBefore": "1mo",
                                        "createdLast": "2mo",
                                        "limit": params.REPORTS_FILTER_LIMIT,
                                        "dryRun": params.LIST_ONLY,
                                        "checkArtifactInReleasedRepo": true
                                    ]

                                    def failCount = arm.cleanupArtifact(args)
                                    if (failCount) {
                                        currentBuild.result = "UNSTABLE"
                                        currentBuild.description = "There are ${failCount} error while deleting artifacts on ARM. (REPORTS - dimtool)"
                                        echo(currentBuild.description)
                                    }
                                }
                            }
                        }
                    }
                }

                stage('Cleanup Artifactory - REPORTS - microservice reports') {
                    when {
                        expression { params.REPORTS_MICROSERVICE_CLEANUP_ENABLED == true }
                    }
                    steps{
                        script {
                            catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                                withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                                 string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                                 usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                                    arm.setUrl('https://arm.seli.gic.ericsson.se/', "$API_TOKEN_EEA")

                                    Map args = [
                                        "repo": "proj-eea-reports-generic-local",
                                        "path": "eric-*",
                                        "createdBefore": "1mo",
                                        "createdLast": "2mo",
                                        "limit": params.REPORTS_FILTER_LIMIT,
                                        "dryRun": params.LIST_ONLY,
                                        "checkArtifactInReleasedRepo": true
                                    ]

                                    def failCount = arm.cleanupArtifact(args)
                                    if (failCount) {
                                        currentBuild.result = "UNSTABLE"
                                        currentBuild.description = "There are ${failCount} error while deleting artifacts on ARM. (REPORTS - microservice)"
                                        echo(currentBuild.description)
                                    }
                                }
                            }
                        }
                    }
                }

                stage('Cleanup Artifactory - REPORTS - integration chart reports') {
                    when {
                        expression { params.REPORTS_INT_CHART_CLEANUP_ENABLED == true }
                    }
                    steps{
                        script {
                            catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                                withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                                 string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                                 usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                                    arm.setUrl('https://arm.seli.gic.ericsson.se/', "$API_TOKEN_EEA")

                                    Map args = [
                                        "repo": "proj-eea-reports-generic-local",
                                        "path": "eea4*",
                                        "name": "*test_run_result*",
                                        "createdBefore": "1mo",
                                        "createdLast": "2mo",
                                        "limit": params.REPORTS_FILTER_LIMIT,
                                        "dryRun": params.LIST_ONLY,
                                        "checkArtifactInReleasedRepo": true,
                                        "checkTestRunResults": true
                                    ]

                                    def failCount = arm.cleanupArtifact(args)
                                    if (failCount) {
                                        currentBuild.result = "UNSTABLE"
                                        currentBuild.description = "There are ${failCount} error while deleting artifacts on ARM. (REPORTS - int chart)"
                                        echo(currentBuild.description)
                                    }
                                }
                            }
                        }
                    }
                }

                stage('Cleanup Artifactory - REPORTS - cluster logs') {
                    when {
                        expression {params.REPORTS_CLUSTER_LOG_CLEANUP_ENABLED == true}
                    }
                    steps {
                        script {
                            catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                                withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                                 string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                                 usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                                    arm.setUrl('https://arm.seli.gic.ericsson.se/', "$API_TOKEN_EEA")

                                    Map args = [
                                        "repo": "proj-eea-reports-generic-local",
                                        "path": "clusterlogs/*",
                                        "createdBefore": "1mo",
                                        "limit": params.REPORTS_FILTER_LIMIT,
                                        "dryRun": params.LIST_ONLY
                                    ]

                                    def failCount = arm.cleanupArtifact(args)
                                    if (failCount) {
                                        currentBuild.result = "UNSTABLE"
                                        currentBuild.description = "There are ${failCount} error while deleting artifacts on ARM. (REPORTS - int chart)"
                                        echo(currentBuild.description)
                                    }
                                }
                            }
                        }
                    }
                }
                stage('Cleanup Artifactory - REPORTS - cluster logs - big files') {
                    when {
                        expression {params.REPORTS_CLUSTER_LOG_CLEANUP_ENABLED == true}
                    }
                    steps {
                        script {
                            catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                                withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                                 string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                                 usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                                    arm.setUrl('https://arm.seli.gic.ericsson.se/', "$API_TOKEN_EEA")

                                    Map args = [
                                        "repo": "proj-eea-reports-generic-local",
                                        "path": "clusterlogs/*",
                                        "createdBefore": "21d",
                                        "sizeGreaterThan": "10000000",
                                        "limit": params.REPORTS_FILTER_LIMIT,
                                        "dryRun": params.LIST_ONLY
                                    ]

                                    def failCount = arm.cleanupArtifact(args)
                                    if (failCount) {
                                        currentBuild.result = "UNSTABLE"
                                        currentBuild.description = "There are ${failCount} error while deleting artifacts on ARM. (REPORTS - int chart)"
                                        echo(currentBuild.description)
                                    }
                                }
                            }
                        }
                    }
                }

                stage('Cleanup Artifactory - eea4-dimensioning-tool folder') {
                    when {
                        expression {params.CLEANUP_DIMTOOL_FOLDER == true}
                    }
                    steps {
                        script {
                            catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                                withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                                 string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                                 usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                                    arm.setUrl('https://arm.seli.gic.ericsson.se/', "$API_TOKEN_EEA")

                                    Map args = [
                                        "repo": "proj-eea-internal-generic-local",
                                        "path": "eea4-dimensioning-tool",
                                        "createdBefore": "30d",
                                        "limit": params.REPORTS_FILTER_LIMIT,
                                        "dryRun": params.LIST_ONLY
                                    ]

                                    def failCount = arm.cleanupArtifact(args)
                                    if (failCount) {
                                        currentBuild.result = "UNSTABLE"
                                        currentBuild.description = "There are ${failCount} error while deleting artifacts on ARM. (REPORTS - int chart)"
                                        echo(currentBuild.description)
                                    }
                                }
                            }
                        }
                    }
                }

                stage('Cleanup Artifactory - Application Dashboard Backups') {
                    when {
                        expression { params.APPLICATION_DASHBOARD_CLEANUP_ENABLED == true }
                    }
                    steps {
                        script {
                            catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                                withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                                 string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                                 usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                                    arm.setUrl('https://arm.seli.gic.ericsson.se/', "$API_TOKEN_EEA")

                                    Map args = [
                                        "repo": "proj-eea-internal-generic-local",
                                        "path": "application-dashboard-backups",
                                        "name": "*",
                                        "createdBefore": "1mo",
                                        "artifactsToKeep": 5,
                                        "limit": params.APPLICATION_DASHBOARD_FILTER_LIMIT,
                                        "dryRun": params.LIST_ONLY
                                    ]

                                    def failCount = arm.cleanupArtifact(args)
                                    if (failCount) {
                                        currentBuild.result = "UNSTABLE"
                                        currentBuild.description = "There are ${failCount} error while deleting artifacts on ARM. (Application Dashboard Backups)"
                                        echo(currentBuild.description)
                                    }
                                }
                            }
                        }
                    }
                }

            }
        }
    }

    post {
        unstable {
            script{
                if ((params.EMAIL_ALERT_ENABLED == true) && (env.MAIN_BRANCH == 'master')) {
                    // Jenkins alerts - EEA4 CI <42a7977a.ericsson.onmicrosoft.com@emea.teams.ms>
                    def recipient = '42a7977a.ericsson.onmicrosoft.com@emea.teams.ms'
                    mail subject: "${env.JOB_NAME} (${env.BUILD_NUMBER}) artifactory cleanup alert: ${currentBuild.result}",
                    body: "${env.BUILD_URL} artifactory cleanup has result: ${currentBuild.result}\n ${currentBuild.description}.",
                    to: "${recipient}",
                    replyTo: "${recipient}",
                    from: 'eea-seliius27190@ericsson.com'
                }
            }
        }
        failure {
            script{
                if ((params.EMAIL_ALERT_ENABLED == true) && (env.MAIN_BRANCH == 'master')) {
                    // Jenkins alerts - EEA4 CI <42a7977a.ericsson.onmicrosoft.com@emea.teams.ms>
                    def recipient = '42a7977a.ericsson.onmicrosoft.com@emea.teams.ms'
                    mail subject: "${env.JOB_NAME} (${env.BUILD_NUMBER}) artifactory cleanup failed",
                    body: "${env.BUILD_URL} artifactory cleanup failed to finish, check the logs.",
                    to: "${recipient}",
                    replyTo: "${recipient}",
                    from: 'eea-seliius27190@ericsson.com'
                }
            }
        }
        cleanup {
            cleanWs()
        }
    }
}
