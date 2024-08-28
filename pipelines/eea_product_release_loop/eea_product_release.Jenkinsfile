@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.Artifactory
import com.ericsson.eea4.ci.CiDashboard
import com.ericsson.eea4.ci.CsarUtils
import groovy.transform.Field

@Field def git = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def gitmeta = new GitScm(this, 'EEA/project-meta-baseline')
@Field def arm = new Artifactory(this, "https://arm.seli.gic.ericsson.se/", "API_TOKEN_EEA")
@Field def dashboard = new CiDashboard(this)
@Field def csarutils = new CsarUtils(this)

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
        string(name: 'DOC_RELEASE_CANDIDATE', description: '[OPTIONAL] If not specified, the version will be defined auctomatically based on the CHART_VERSION parameter. The documentation helm chart release candidate version (e.g. 1.0.0-7)', defaultValue: '')
    }

    environment {
        HELM_REPOPATH_CI_INTERNAL='proj-eea-ci-internal-helm-local'
        HELM_REPOPATH_DROP='proj-eea-drop-helm-local'
        HELM_REPOPATH_RELEASED='proj-eea-released-helm-local'
        GENERIC_REPOPATH_CI_INTERNAL='proj-eea-internal-generic-local'
        GENERIC_REPOPATH_DROP='proj-eea-drop-generic-local'
        GENERIC_REPOPATH_RELEASED='proj-eea-released-generic-local'
        CHART_NAME='eric-eea-int-helm-chart'
        CHART_REPO="https://arm.seli.gic.ericsson.se/artifactory/${env.HELM_REPOPATH_DROP}/"
        CHART_REPO_RELEASED="https://arm.seli.gic.ericsson.se/artifactory/${env.HELM_REPOPATH_RELEASED}/"
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

        stage('Read versions from meta') {
            steps {
                script {
                    gitmeta.checkout(env.META_CHART_VERSION, 'project-meta-baseline')
                    dir('project-meta-baseline') {
                        // get CHART_VERSION
                        env.CHART_VERSION = ''
                        def chart = readYaml file: 'eric-eea-ci-meta-helm-chart/Chart.yaml'
                        chart.dependencies.each { dependency ->
                            if (dependency.name == env.CHART_NAME) {
                                env.CHART_VERSION = dependency.version
                            }
                        }
                        // get DOC_RELEASE_CANDIDATE version if input value is empty
                        if (!env.DOC_RELEASE_CANDIDATE) {
                            docReleaseCandidateStringFull = sh(script: 'git log --oneline --grep="CPI and product:.*${CHART_VERSION}$" --max-count=1', returnStdout: true).trim()
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
                    }
                    echo "env.CHART_VERSION: ${env.CHART_VERSION}"
                    echo "env.DOC_RELEASE_CANDIDATE: ${env.DOC_RELEASE_CANDIDATE}"

                    def match = (env.DOC_RELEASE_CANDIDATE =~ /[0-9]+\.[0-9]+\.[0-9]+[-\+][A-Za-z0-9]+/)
                    if (!match.find()) {
                        error("DOC_RELEASE_CANDIDATE has wrong format: ${env.DOC_RELEASE_CANDIDATE}!\nFormat must be: <major>.<<minor>.<<patch>+<build number>; e.g. 1.2.3-1")
                    }
                }
            }
        }

        stage('Init versions') {
            steps {
                script {
                    env.CHART_VERSION_PRA = sh(script: "echo ${env.CHART_VERSION} | sed 's/-/+/g'", returnStdout: true).trim()
                    env.CHART_VERSION_NONPRA = sh(script: "echo ${env.CHART_VERSION} | sed 's/+/-/g'", returnStdout: true).trim()
                    echo "env.CHART_VERSION (original): ${env.CHART_VERSION}"
                    echo "env.CHART_VERSION_PRA: ${env.CHART_VERSION_PRA}"
                    echo "env.CHART_VERSION_NONPRA: ${env.CHART_VERSION_NONPRA}"

                    echo "--> Meta chart version: ${env.META_CHART_VERSION}"
                    echo "--> Released product version: ${env.CHART_VERSION_PRA}"
                    echo "--> Documentation version: ${env.DOC_RELEASE_CANDIDATE}"
                    echo "--> Git tag: ${env.GIT_TAG_STRING}"

                    currentBuild.description = "Meta chart version: ${env.META_CHART_VERSION}"
                    currentBuild.description += '<br>' + "Released product version: ${env.CHART_VERSION_PRA}"
                    currentBuild.description += '<br>' + "Documentation version: ${env.DOC_RELEASE_CANDIDATE}"
                    currentBuild.description += '<br>' + "Git tag: ${env.GIT_TAG_STRING}"
                }
            }
        }

        stage('Checkout adp-app-staging') {
            steps {
                script {
                    git.checkout('master', '')
                }
            }
        }

        stage('Prepare bob') {
            steps {
                checkoutGitSubmodules()
            }
        }

        stage('Checkout cnint') {
            steps {
                script {
                    gitcnint.checkout(env.CHART_VERSION, 'cnint')
                }
            }
        }

        stage('Generate and Upload Helm Chart - NONPRA') {
            when {
                expression { env.CHART_VERSION == env.CHART_VERSION_NONPRA }
            }
            steps {
                // Generate integration helm chart
                withCredentials([
                                usernamePassword(credentialsId: 'arm-functional-user', usernameVariable: 'HELM_USER', passwordVariable: 'HELM_TOKEN'),
                                usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD'),
                                string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                    // replace repositories.yaml.template with the one from cnint repo
                    script {
                        gitcnint.archiveFile('EEA/cnint', 'HEAD repositories.yaml.template')
                    }
                    sh 'bob/bob -r ruleset2.0_product_release.yaml publish-released-helm-chart'
                }
            }
        }

        stage('Upload Helm Chart - PRA') {
            when {
                expression { env.CHART_VERSION == env.CHART_VERSION_PRA }
            }
            steps {
                withCredentials([
                                usernamePassword(credentialsId: 'arm-functional-user', usernameVariable: 'HELM_USER', passwordVariable: 'HELM_TOKEN'),
                                usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD'),
                                string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                    // prepare bob variables
                    sh 'mkdir -p .bob/released-charts'
                    sh 'bob/bob -r ruleset2.0_product_release.yaml publish-released-helm-chart:generate-released-version'
                    script {
                        def helmChartPackage="${env.CHART_NAME}/${env.CHART_NAME}-${env.CHART_VERSION}.tgz"
                        echo "helmChartPackage: |${helmChartPackage}|"
                        arm.setUrl("https://arm.seli.gic.ericsson.se/", "$API_TOKEN_EEA")
                        if ( arm.checkIfArtifactExists("${env.HELM_REPOPATH_DROP}", "${helmChartPackage}") ) {
                            echo "PRA version already exists in drop repo --> copy helm chart package from drop repo to released repo"
                            arm.copyArtifact("${helmChartPackage}", "${env.HELM_REPOPATH_DROP}", "${helmChartPackage}", "${env.HELM_REPOPATH_RELEASED}")
                            // download helm chart package from released repo (the dashboard need it)
                            arm.setRepo("${env.HELM_REPOPATH_RELEASED}")
                            arm.downloadArtifact(helmChartPackage, ".bob/released-charts/${env.CHART_NAME}-${env.CHART_VERSION}.tgz")
                        } else {
                            echo "PRA version not exists in drop repo repo --> generate integration helm chart"
                            gitcnint.archiveFile('EEA/cnint', 'HEAD repositories.yaml.template')
                            sh 'bob/bob -r ruleset2.0_product_release.yaml publish-released-helm-chart'
                        }
                    }
                }
            }
        }

        stage('Release git branch') {
            steps {
                script {
                    dir('cnint') {
                        withCredentials([usernameColonPassword(credentialsId: 'git-functional-http-user', variable: 'ECEAGIT_TOKEN')]) {

                            echo "Get git branch name from git tag: ${params.GIT_TAG_STRING} ..."
                            def gitBranchName = sh(
                                script: """echo "${params.GIT_TAG_STRING}" | sed "s/_pra//"
                                """,
                                returnStdout: true).trim()

                            echo "Check if git branch: ${gitBranchName} exists in cnint repo ..."
                            env.GIT_BRANCH_EXISTS = sh(
                                script: """git ls-remote --heads "https://${ECEAGIT_TOKEN}@${GERRIT_HOST}/a/EEA/cnint.git" "${gitBranchName}"
                                """,
                                returnStdout: true).trim()

                            if (env.GIT_BRANCH_EXISTS != "") {
                                echo "git branch: ${gitBranchName} already exists in cnint repo, sending e-mail ..."
                                try {
                                    def rv_recipient = 'eea_rv_integration@mailman.lmera.ericsson.se'
                                    def ci_recipient = 'PDLEEA4PRO@pdl.internal.ericsson.com'
                                    mail subject: "Issue checking git branch with name: ${gitBranchName} for ${env.CHART_VERSION_PRA} in Product Release job",
                                    body: """
                                        The git branch: ${gitBranchName} already exist in cnint repo.\n
                                        You can found the details in: ${BUILD_URL}""",
                                    to: "${rv_recipient}",
                                    cc: "${ci_recipient}",
                                    replyTo: "${rv_recipient}",
                                    from: 'eea-seliius27190@ericsson.com'
                                } catch (err) {
                                    echo "Caught: ${err}"
                                }
                            } else {
                                echo "git branch: ${gitBranchName} doesn't exists in cnint repo, creating ..."
                                try {
                                    sh (script: """#!/bin/bash
                                        baseCommit=\$(git log --format="%H" -n 1)
                                        git push https://${ECEAGIT_TOKEN}@${GERRIT_HOST}/a/EEA/cnint.git ${'$'}baseCommit:refs/heads/${gitBranchName}
                                    """)
                                } catch (err) {
                                    echo "Caught: ${err}"
                                    error "Error creating git branch: ${gitBranchName} in cnint repo!"
                                }

                                echo "Check if git branch: ${gitBranchName} exists in cnint repo (after creating) ..."
                                try {
                                    env.GIT_BRANCH_EXISTS = sh(
                                        script: """git ls-remote --heads "https://${ECEAGIT_TOKEN}@${GERRIT_HOST}/a/EEA/cnint.git" "${gitBranchName}"
                                        """,
                                        returnStdout: true).trim()
                                    if (env.GIT_BRANCH_EXISTS == '') {
                                        error "Cannot find created git branch for git tag: ${params.GIT_TAG_STRING}!"
                                    }
                                } catch (err) {
                                    echo "Caught: ${err}"
                                    error "Error checking git branch: ${gitBranchName} in cnint repo!"
                                }
                            }
                        }
                    }
                }
            }
        }

        stage('Generate and Upload CSAR files - NONPRA') {
            when {
                expression { env.CHART_VERSION == env.CHART_VERSION_NONPRA }
            }
            steps {
                script {
                    build job: "csar-build",
                    parameters: [
                        stringParam(name: 'INT_CHART_REPO', value: "${env.CHART_REPO_RELEASED}"),
                        stringParam(name: 'INT_CHART_VERSION', value: "${env.CHART_VERSION_PRA}")
                    ],
                    wait : true

                   withCredentials([string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                        // Download the CSAR from internal repository
                        sh """curl -H "X-JFrog-Art-Api: $API_TOKEN_EEA" -fO https://arm.seli.gic.ericsson.se/artifactory/proj-eea-internal-generic-local/csar-package-${env.CHART_VERSION_PRA}.csar"""
                        csarutils.extractImagesTxtAndCreateContentTxtBesideCsar("csar-package-${env.CHART_VERSION_PRA}.csar")
                        arm.setUrl("https://arm.seli.gic.ericsson.se/", "$API_TOKEN_EEA")
                        catchError(stageResult: 'FAILURE', buildResult: 'SUCCESS') {
                            // for comparison, download the - CSAR images.txt from drop repository
                            def minusversionimages = 'csar-package-' + env.CHART_VERSION_PRA.replace("+", "-") + '.images.txt'
                            arm.setRepo("${env.GENERIC_REPOPATH_DROP}")
                            arm.downloadArtifact(minusversionimages, minusversionimages)
                            // check for already extracted images.txt and downloaded one, should be no diffs
                            if (comparePlusAndMinusCsarVersionForDifferentImages(minusversionimages, 'images.txt'))
                                error ("CSAR + and - version mismatch!")
                            // Upload the CSAR to the released repository
                            arm.setRepo("${env.GENERIC_REPOPATH_RELEASED}")
                            arm.deployArtifact("csar-package-${env.CHART_VERSION_PRA}.csar", "csar-package-${env.CHART_VERSION_PRA}.csar")
                            csarutils.fetchAndProcess3ppListJsonsToCsv()
                            // Upload images.txt, content.txt and 3pplist.csv next to the CSAR
                            arm.deployArtifact('images.txt', "csar-package-${env.CHART_VERSION_PRA}.images.txt")
                            arm.deployArtifact('content.txt', "csar-package-${env.CHART_VERSION_PRA}.content.txt")
                            arm.deployArtifact('3pplist.csv', "csar-package-${env.CHART_VERSION_PRA}.3pp_list.csv")
                        }
                    }
                }
            }
        }

        stage('Upload CSAR files - PRA') {
            when {
                expression { env.CHART_VERSION == env.CHART_VERSION_PRA }
            }
            steps {
                script {
                    catchError(stageResult: 'FAILURE', buildResult: 'SUCCESS') {
                        withCredentials([string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                            arm.setUrl("https://arm.seli.gic.ericsson.se/", "$API_TOKEN_EEA")
                            // copy csar and related files from drop repo to released repo (without downloading)
                            arm.copyArtifact("csar-package-${env.CHART_VERSION}.csar", "${env.GENERIC_REPOPATH_DROP}", "csar-package-${env.CHART_VERSION}.csar", "${env.GENERIC_REPOPATH_RELEASED}")
                            arm.copyArtifact("csar-package-${env.CHART_VERSION}.images.txt", "${env.GENERIC_REPOPATH_DROP}", "csar-package-${env.CHART_VERSION}.images.txt", "${env.GENERIC_REPOPATH_RELEASED}")
                            arm.copyArtifact("csar-package-${env.CHART_VERSION}.content.txt", "${env.GENERIC_REPOPATH_DROP}", "csar-package-${env.CHART_VERSION}.content.txt", "${env.GENERIC_REPOPATH_RELEASED}")
                            arm.copyArtifact("csar-package-${env.CHART_VERSION}.3pp_list.csv", "${env.GENERIC_REPOPATH_DROP}", "csar-package-${env.CHART_VERSION}.3pp_list.csv", "${env.GENERIC_REPOPATH_RELEASED}")
                        }
                    }
                }
            }
        }

        stage('Upload dimtool') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                        arm.setUrl("https://arm.seli.gic.ericsson.se/", "$API_TOKEN_EEA")
                        // Copy '-' version of dimtool from drop repo to released repo replacing - to + in its version
                        arm.copyArtifact("eea4-dimensioning-tool/eea4-dimensioning-tool-${env.CHART_VERSION}.zip", "${env.GENERIC_REPOPATH_DROP}", "eea4-dimensioning-tool/eea4-dimensioning-tool-${env.CHART_VERSION_PRA}.zip", "${env.GENERIC_REPOPATH_RELEASED}")
                    }
                }
            }
        }

        stage('Create PRA Git Tag') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')])
                {
                    sh './bob/bob -r ruleset2.0_product_release.yaml create-pra-git-tag:git-tag'
                }
            }
        }

        stage('Set dashboard last PRA') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {
                    script {
                        def chart_path = ".bob/released-charts/${env.CHART_NAME}-${env.CHART_VERSION_PRA}.tgz"
                        dashboard.publishHelm( chart_path, "${env.CHART_VERSION_PRA}","${env.BUILD_URL}","${env.BUILD_ID}","last-pra")
                    }
                }
            }
        }

        stage('Exec eea-meta-baseline-release-job') {
            steps {
                catchError(stageResult: 'FAILURE', buildResult: 'SUCCESS') {
                    script {
                        build job: 'eea-meta-baseline-release-job',
                        parameters: [
                            booleanParam(name: 'DRY_RUN', value: false),
                            stringParam(name: 'CHART_VERSION', value: "${env.CHART_VERSION}"),
                            stringParam(name: 'GIT_TAG_STRING', value: "${params.GIT_TAG_STRING}")
                        ], wait: true
                    }
                }
            }
        }

        stage('Exec documentation-release') {
            steps {
                catchError(stageResult: 'FAILURE', buildResult: 'SUCCESS') {
                    script {
                        build job: 'documentation-release',
                        parameters: [
                            booleanParam(name: 'DRY_RUN', value: false),
                            stringParam(name: 'RELEASE_CANDIDATE', value: "${env.DOC_RELEASE_CANDIDATE}"),
                            stringParam(name: 'GIT_TAG_STRING', value: "${params.GIT_TAG_STRING}")
                        ], wait: true
                    }
                }
            }
        }

        stage('Exec deployer release') {
            steps {
                catchError(stageResult: 'FAILURE', buildResult: 'SUCCESS') {
                    script {
                        build job: 'eea-deployer-release',
                        parameters: [
                            booleanParam(name: 'DRY_RUN', value: false),
                            stringParam(name: 'META_CHART_VERSION', value: "${params.META_CHART_VERSION}"),
                            stringParam(name: 'DEPLOYER_GIT_TAG_STRING', value: "${params.GIT_TAG_STRING}"),
                        ], wait: true
                    }
                }
            }
        }

        stage('Check product version compatibility') {
            steps {
                script {
                    def helmRepo = "proj-eea-released-helm"
                    def deployerPkgRepo = "proj-eea-released-generic-local"
                    //Download released eric-eea-ci-meta-helm-chart
                    env.META_CHART_VERSION_PRA = sh(script: "echo ${params.META_CHART_VERSION} | sed 's/-/+/g'", returnStdout: true).trim()
                    def metaHelmChartPkg = "eric-eea-ci-meta-helm-chart-${env.META_CHART_VERSION_PRA}.tgz"

                    withCredentials([string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                        arm.setUrl("https://arm.seli.gic.ericsson.se", "$API_TOKEN_EEA")
                        arm.setRepo(helmRepo)
                        arm.downloadArtifact("eric-eea-ci-meta-helm-chart/${metaHelmChartPkg}", "${metaHelmChartPkg}")
                    }
                    sh "tar -xvf ${metaHelmChartPkg}"
                    checkProdVersionCompatibility(deployerPkgRepo)
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

def comparePlusAndMinusCsarVersionForDifferentImages(String minusversionimagelist, String plusversionimagelist) {
    def minusversions = readFile(minusversionimagelist).readLines()
    def plusversions = readFile(plusversionimagelist).readLines()
    def extrainplusversion = plusversions.minus(minusversions)
    def missingfromplusversion = minusversions.minus(plusversions)
    if (extrainplusversion)
        echo "CSAR + version has the following extra images:\n" + extrainplusversion.join("\n")
    if (missingfromplusversion)
        echo "CSAR + version has the following missing images:\n" + missingfromplusversion.join("\n")
    return extrainplusversion || missingfromplusversion
}
