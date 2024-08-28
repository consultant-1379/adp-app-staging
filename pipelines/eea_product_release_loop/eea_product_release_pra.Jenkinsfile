@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.Artifactory
import com.ericsson.eea4.ci.CiDashboard
import groovy.transform.Field

@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def gitmeta = new GitScm(this, 'EEA/project-meta-baseline')
@Field def gitdoc = new GitScm(this, 'EEA/eea4_documentation')
@Field def gitdeployer = new GitScm(this, 'EEA/deployer')

pipeline {
    options {
        disableConcurrentBuilds()
        buildDiscarder(logRotator(daysToKeepStr: '30', artifactDaysToKeepStr: '7'))
    }
    agent {
        node {
            label 'productci'
        }
    }

    parameters {
        string(name: 'META_CHART_VERSION', description: 'Chart version of the metachart, eg: 4.4.0-1', defaultValue: '')
        string(name: 'GIT_TAG_STRING', description: 'PRA git tag, e.g.: eea4_4.4.0_pra', defaultValue: '')
        string(name: 'DOC_RELEASE_CANDIDATE', description: '[OPTIONAL] If not specified, the version will be defined auctomatically based on the INT_CHART_VERSION. The documentation helm chart release candidate version (e.g. 1.0.0-7)', defaultValue: '')
        booleanParam(name: 'SKIP_RELEASE_PRODUCT', description: 'Skip releasing product', defaultValue: false)
        booleanParam(name: 'SKIP_RELEASE_DOCUMENTATION', description: 'Skip releasing documentation', defaultValue: false)
        booleanParam(name: 'SKIP_RELEASE_DEPLOYER', description: 'Skip releasing deployer', defaultValue: false)
        booleanParam(name: 'SKIP_RELEASE_META', description: 'Skip releasing meta', defaultValue: false)
        booleanParam(name: 'PUBLISH_DRY_RUN', description: 'Enable dry-run for git tagging and create branches', defaultValue: false)
    }

    environment {
        INT_CHART_NAME='eric-eea-int-helm-chart'
        META_CHART_NAME='eric-eea-ci-meta-helm-chart'
        DOC_CHART_NAME='eric-eea-documentation-helm-chart-ci'
        EEA_DEPLOYER_CHART_NAME='eric-eea-deployer'
        HELM_REPOPATH_VIRTUAL='proj-eea'
    }

    stages {
        stage('Params DryRun check') {
            when {
                expression { params.DRY_RUN == true }
            }
            steps {
                dryRun()
            }
        }

        stage('Check params') {
            steps {
                script {
                    if (!params.META_CHART_VERSION) {
                        error "META_CHART_VERSION input parameter is mandatory and should be specified!"
                    }
                    if (!params.GIT_TAG_STRING) {
                        error "GIT_TAG_STRING input parameter is mandatory and should be specified!"
                    }
                }
            }
        }

        stage('Checkout meta') {
            steps {
                script {
                    gitmeta.checkout(env.META_CHART_VERSION, 'project-meta-baseline')
                }
            }
        }

        stage('Read versions from meta') {
            steps {
                script {
                    dir('project-meta-baseline') {
                        // get chart versions
                        env.INT_CHART_VERSION = ''
                        env.DOC_CHART_VERSION = ''
                        env.EEA_DEPLOYER_CHART_VERSION = ''

                        def chart = readYaml file: "${env.META_CHART_NAME}/Chart.yaml"
                        chart.dependencies.each { dependency ->
                            if (dependency.name == env.INT_CHART_NAME) {
                                env.INT_CHART_VERSION = dependency.version
                                echo "env.INT_CHART_VERSION: ${env.INT_CHART_VERSION}"
                            }
                            if (dependency.name == env.DOC_CHART_NAME) {
                                env.DOC_CHART_VERSION = dependency.version
                                echo "env.DOC_CHART_VERSION: ${env.DOC_CHART_VERSION}"
                            }
                            if (dependency.name == env.EEA_DEPLOYER_CHART_NAME) {
                                env.EEA_DEPLOYER_CHART_VERSION = dependency.version
                                echo "env.EEA_DEPLOYER_CHART_VERSION: ${env.EEA_DEPLOYER_CHART_VERSION}"
                            }
                        }

                        // get DOC_RELEASE_CANDIDATE version if input value is empty
                        if (!env.DOC_RELEASE_CANDIDATE) {
                            docReleaseCandidateStringFull = sh(script: 'git log --oneline --grep="CPI and product:.*${INT_CHART_VERSION}$" --max-count=1', returnStdout: true).trim()
                            echo "docReleaseCandidateStringFull: ${docReleaseCandidateStringFull}"

                            // remove all items before the search pattern because any git tag information can cause problems
                            docReleaseCandidateString = docReleaseCandidateStringFull.substring(docReleaseCandidateStringFull.indexOf("CPI and product:"))
                            echo "docReleaseCandidateString: ${docReleaseCandidateString}"

                            def docReleaseCandidateMatch = (docReleaseCandidateString =~ /[0-9]+\.[0-9]+\.[0-9]+[-\+][A-Za-z0-9]+/)
                            echo "docReleaseCandidateMatch: ${docReleaseCandidateMatch}"
                            if (docReleaseCandidateMatch.find()) {
                                echo "docReleaseCandidateMatch[0]: ${docReleaseCandidateMatch[0]}"
                                env.DOC_RELEASE_CANDIDATE = docReleaseCandidateMatch[0]
                            } else {
                                error "Cannot determine DOC_RELEASE_CANDIDATE automatically!\ndocReleaseCandidateStringFull: ${docReleaseCandidateStringFull}\ndocReleaseCandidateMatch: ${docReleaseCandidateMatch}"
                            }
                        }
                        echo "env.DOC_RELEASE_CANDIDATE: ${env.DOC_RELEASE_CANDIDATE}"
                        def match = (env.DOC_RELEASE_CANDIDATE =~ /[0-9]+\.[0-9]+\.[0-9]+[-\+][A-Za-z0-9]+/)
                        if (!match.find()) {
                            error("DOC_RELEASE_CANDIDATE has wrong format: ${env.DOC_RELEASE_CANDIDATE}!\nFormat must be: <major>.<<minor>.<<patch>+<build number>; e.g. 1.2.3-1")
                        }
                    }
                }
            }
        }

        stage('Init versions') {
            steps {
                script {
                    env.INT_CHART_VERSION_PRA = sh(script: "echo ${env.INT_CHART_VERSION} | sed 's/-/+/g'", returnStdout: true).trim()
                    env.GIT_BRANCH_NAME = "${env.GIT_TAG_STRING}".replaceAll('_pra', '')
                    echo "env.INT_CHART_VERSION (original): ${env.INT_CHART_VERSION}"
                    echo "env.INT_CHART_VERSION_PRA: ${env.INT_CHART_VERSION_PRA}"

                    echo "--> Meta chart version: ${env.META_CHART_VERSION}"
                    echo "--> Product version: ${env.INT_CHART_VERSION_PRA}"
                    echo "--> Git tag: ${env.GIT_TAG_STRING}"
                    echo "--> Git branch: ${env.GIT_BRANCH_NAME}"

                    currentBuild.description = "Meta chart version: ${env.META_CHART_VERSION}"
                    currentBuild.description += '<br>' + "Product version: ${env.INT_CHART_VERSION}"
                    currentBuild.description += '<br>' + "Git tag: ${env.GIT_TAG_STRING}"
                    currentBuild.description += '<br>' + "Git branch: ${env.GIT_BRANCH_NAME}"
                }
            }
        }

        stage('Init arm') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                        arm = new Artifactory(this)
                        arm.setUrl(Artifactory.defaultUrl, "$API_TOKEN_EEA")
                    }
                }
            }
        }

        stage('Release product') {
            when {
                expression { params.SKIP_RELEASE_PRODUCT == false }
            }
            stages {
                stage('Checkout adp-app-staging') {
                    steps {
                        script {
                            gitadp.checkout(env.MAIN_BRANCH, 'master-adp-app-staging')
                        }
                    }
                }
                stage('Prepare bob adp-app-staging') {
                    steps {
                        dir('master-adp-app-staging') {
                            checkoutGitSubmodules()
                        }
                    }
                }
                stage('Checkout cnint') {
                    steps {
                        script {
                            gitcnint.checkout(env.INT_CHART_VERSION, 'cnint')
                        }
                    }
                }
                stage('Release git branch product') {
                    steps {
                        catchError(stageResult: 'FAILURE', buildResult: 'FAILURE') {
                            script {
                                dir('cnint') {
                                    withCredentials([usernameColonPassword(credentialsId: 'git-functional-http-user', variable: 'ECEAGIT_TOKEN')]) {

                                        echo "Check if git branch: ${env.GIT_BRANCH_NAME} exists in cnint repo ..."
                                        env.GIT_BRANCH_EXISTS = sh(
                                            script: """git ls-remote --heads "https://\${ECEAGIT_TOKEN}@${GERRIT_HOST}/a/EEA/cnint.git" "${env.GIT_BRANCH_NAME}"
                                            """,
                                            returnStdout: true).trim()

                                        if (env.GIT_BRANCH_EXISTS != "") {
                                            echo "git branch: ${env.GIT_BRANCH_NAME} already exists in cnint repo, skip creating!"
                                            return
                                        }

                                        echo "git branch: ${env.GIT_BRANCH_NAME} doesn't exists in cnint repo, creating ..."
                                        if (env.PUBLISH_DRY_RUN.toBoolean() == true) {
                                            echo "git push skipped - DRY_RUN: ${env.PUBLISH_DRY_RUN}"
                                            return
                                        }

                                        try {
                                            sh (script: """#!/bin/bash
                                                baseCommit=\$(git log --format="%H" -n 1)
                                                git push https://\${ECEAGIT_TOKEN}@${GERRIT_HOST}/a/EEA/cnint.git ${'$'}baseCommit:refs/heads/${env.GIT_BRANCH_NAME}
                                            """)
                                        } catch (err) {
                                            echo "Caught: ${err}"
                                            error "Error creating git branch: ${env.GIT_BRANCH_NAME} in cnint repo!"
                                        }

                                        echo "Check if git branch: ${env.GIT_BRANCH_NAME} exists in cnint repo (after creating) ..."
                                        try {
                                            env.GIT_BRANCH_EXISTS = sh(
                                                script: """git ls-remote --heads "https://\${ECEAGIT_TOKEN}@${GERRIT_HOST}/a/EEA/cnint.git" "${env.GIT_BRANCH_NAME}"
                                                """,
                                                returnStdout: true).trim()
                                            if (env.GIT_BRANCH_EXISTS == '') {
                                                error "Cannot find created git branch for git tag: ${env.GIT_TAG_STRING}!"
                                            }
                                        } catch (err) {
                                            echo "Caught: ${err}"
                                            error "Error checking git branch: ${env.GIT_BRANCH_NAME} in cnint repo!"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                stage('Create PRA Git Tag product') {
                    steps {
                        catchError(stageResult: 'FAILURE', buildResult: 'FAILURE') {
                            dir('master-adp-app-staging') {
                                withCredentials([usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                                    withEnv([
                                        "CHART_NAME=${env.INT_CHART_NAME}",
                                        "CHART_VERSION=${env.INT_CHART_VERSION}"
                                    ]) {
                                        sh './bob/bob -r ruleset2.0_product_release.yaml create-pra-git-tag:git-tag'
                                    }
                                }
                            }
                        }
                    }
                }
                stage('Upload Integration Helm Chart to App dashboard last-pra') {
                    steps {
                        catchError(stageResult: 'FAILURE', buildResult: 'SUCCESS') {
                            dir('master-adp-app-staging') {
                                script {
                                    def releasedPackage = "${env.INT_CHART_NAME}-${INT_CHART_VERSION_PRA}.tgz"
                                    if (arm.checkIfArtifactExists("${env.HELM_REPOPATH_VIRTUAL}", "${env.INT_CHART_NAME}/${releasedPackage}")) {
                                        error "${releasedPackage} NOT exists in ${HELM_REPOPATH_VIRTUAL} repo"
                                    }
                                    echo "${releasedPackage} already exists in ${HELM_REPOPATH_VIRTUAL} repo --> trying to download it ..."
                                    arm.downloadArtifact("${env.INT_CHART_NAME}/${releasedPackage}", releasedPackage, "${env.HELM_REPOPATH_VIRTUAL}")
                                    if (fileExists(releasedPackage) && env.PUBLISH_DRY_RUN.toBoolean() == false) {
                                        def dashboard = new CiDashboard(this)
                                        dashboard.publishHelm(releasedPackage, "${env.INT_CHART_VERSION_PRA}", "${env.BUILD_URL}", "${env.BUILD_ID}", "last-pra")
                                    } else {
                                        echo "Upload Integration Helm Chart to App dashboard skipped - DRY_RUN: ${env.PUBLISH_DRY_RUN}"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        stage('Release documentation') {
            when {
                expression { params.SKIP_RELEASE_DOCUMENTATION == false }
            }
            stages {
                stage('Checkout documentation') {
                    steps {
                        script {
                            gitdoc.checkout(env.MAIN_BRANCH, 'master-eea4_documentation')
                            gitdoc.checkout(env.DOC_RELEASE_CANDIDATE, 'build-eea4_documentation')
                        }
                    }
                }
                stage('Prepare bob documentation') {
                    steps {
                        dir('build-eea4_documentation') {
                            checkoutGitSubmodules()
                        }
                    }
                }
                stage('Create PRA Git Tag documentation') {
                    steps {
                        catchError(stageResult: 'FAILURE', buildResult: 'FAILURE') {
                            dir('build-eea4_documentation') {
                                withCredentials([usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                                    withEnv([
                                        "RELEASE_CANDIDATE=${env.DOC_RELEASE_CANDIDATE}"
                                    ]) {
                                        sh './bob/bob -r ${WORKSPACE}/master-eea4_documentation/bob-rulesets/documentation_release.yaml doc-init:generate-released-version'
                                        sh './bob/bob -r ${WORKSPACE}/master-eea4_documentation/bob-rulesets/documentation_release.yaml create-pra-git-tag'
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        stage('Release deployer') {
            when {
                expression { params.SKIP_RELEASE_DEPLOYER == false }
            }
            stages {
                stage('Checkout deployer') {
                    steps {
                        script {
                            gitdeployer.checkout(env.MAIN_BRANCH, 'master-deployer')
                            gitdeployer.checkout(env.EEA_DEPLOYER_CHART_VERSION, 'build-deployer')
                        }
                    }
                }
                stage('Prepare bob deployer') {
                    steps {
                        dir('master-deployer') {
                            checkoutGitSubmodules()
                        }
                    }
                }
                stage('Release git branch deployer') {
                    steps {
                        catchError(stageResult: 'FAILURE', buildResult: 'FAILURE') {
                            script {
                                dir('build-deployer') {
                                    withCredentials([usernameColonPassword(credentialsId: 'git-functional-http-user', variable: 'ECEAGIT_TOKEN')]) {

                                        echo "Check if git branch: ${env.GIT_BRANCH_NAME} exists in deployer repo ..."
                                        env.GIT_BRANCH_EXISTS = sh(
                                            script: """git ls-remote --heads "https://\${ECEAGIT_TOKEN}@${GERRIT_HOST}/a/EEA/deployer.git" "${env.GIT_BRANCH_NAME}"
                                            """,
                                            returnStdout: true).trim()

                                        if (env.GIT_BRANCH_EXISTS != "") {
                                            echo "git branch: ${env.GIT_BRANCH_NAME} already exists in deployer repo, skip creating!"
                                            return
                                        }

                                        echo "git branch: ${env.GIT_BRANCH_NAME} doesn't exists in deployer repo, creating ..."
                                        if (env.PUBLISH_DRY_RUN.toBoolean() == true) {
                                            echo "git push skipped - DRY_RUN: ${env.PUBLISH_DRY_RUN}"
                                            return
                                        }

                                        try {
                                            sh (script: """#!/bin/bash
                                                baseCommit=\$(git log --format="%H" -n 1)
                                                git push https://\${ECEAGIT_TOKEN}@${GERRIT_HOST}/a/EEA/deployer.git ${'$'}baseCommit:refs/heads/${env.GIT_BRANCH_NAME}
                                            """)
                                        } catch (err) {
                                            echo "Caught: ${err}"
                                            error "Error creating git branch: ${env.GIT_BRANCH_NAME} in deployer repo!"
                                        }

                                        echo "Check if git branch: ${env.GIT_BRANCH_NAME} exists in deployer repo (after creating) ..."
                                        try {
                                            env.GIT_BRANCH_EXISTS = sh(
                                                script: """git ls-remote --heads "https://\${ECEAGIT_TOKEN}@${GERRIT_HOST}/a/EEA/deployer.git" "${env.GIT_BRANCH_NAME}"
                                                """,
                                                returnStdout: true).trim()
                                            if (env.GIT_BRANCH_EXISTS == '') {
                                                error "Cannot find created git branch for git tag: ${env.GIT_TAG_STRING}!"
                                            }
                                        } catch (err) {
                                            echo "Caught: ${err}"
                                            error "Error checking git branch: ${env.GIT_BRANCH_NAME} in deployer repo!"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                stage('Create PRA Git Tag deployer') {
                    steps {
                        catchError(stageResult: 'FAILURE', buildResult: 'FAILURE') {
                            dir('master-deployer') {
                                withCredentials([usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                                    withEnv([
                                        "EEA_DEPLOYER_CHART_VERSION=${env.EEA_DEPLOYER_CHART_VERSION}",
                                        "EEA_DEPLOYER_GIT_TAG_STRING=${env.GIT_TAG_STRING}"
                                    ]) {
                                        sh './bob/bob -r bob-rulesets/ruleset2.0_deployer_release.yaml create-pra-git-tag:git-tag'
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        stage('Release meta') {
            when {
                expression { params.SKIP_RELEASE_META == false }
            }
            stages {
                stage('Checkout meta') {
                    steps {
                        script {
                            gitmeta.checkout(env.MAIN_BRANCH, 'master-project-meta-baseline')
                        }
                    }
                }
                stage('Prepare bob meta') {
                    steps {
                        dir('master-project-meta-baseline') {
                            checkoutGitSubmodules()
                        }
                    }
                }
                stage('Create PRA Git Tag meta') {
                    steps {
                        catchError(stageResult: 'FAILURE', buildResult: 'FAILURE') {
                            dir('master-project-meta-baseline') {
                                withCredentials([usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                                    withEnv([
                                        "META_CHART_VERSION=${env.META_CHART_VERSION}"
                                    ]) {
                                        sh './bob/bob -r bob-rulesets/ruleset2.0_product_release.yaml create-pra-git-tag'
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
        cleanup {
            cleanWs()
        }
    }
}
