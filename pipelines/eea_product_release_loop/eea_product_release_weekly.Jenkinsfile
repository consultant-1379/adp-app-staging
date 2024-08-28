@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.Artifactory
import com.ericsson.eea4.ci.CommonUtils
import com.ericsson.eea4.ci.CsarUtils
import groovy.transform.Field

@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def gitmeta = new GitScm(this, 'EEA/project-meta-baseline')
@Field def gitdoc = new GitScm(this, 'EEA/eea4_documentation')
@Field def gitdeployer = new GitScm(this, 'EEA/deployer')
@Field def cmutils = new CommonUtils(this)
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
        string(name: 'DOC_RELEASE_CANDIDATE', description: '[OPTIONAL] If not specified, the version will be defined auctomatically based on the INT_CHART_VERSION. The documentation helm chart release candidate version (e.g. 1.0.0-7)', defaultValue: '')
        booleanParam(name: 'SKIP_RELEASE_PRODUCT', description: 'Skip releasing integration helm chart', defaultValue: false)
        booleanParam(name: 'SKIP_RELEASE_CSAR', description: 'Skip releasing csar', defaultValue: false)
        booleanParam(name: 'SKIP_RELEASE_DOCUMENTATION', description: 'Skip releasing documentation', defaultValue: false)
        booleanParam(name: 'SKIP_RELEASE_DEPLOYER', description: 'Skip releasing deployer', defaultValue: false)
        booleanParam(name: 'SKIP_RELEASE_META', description: 'Skip releasing meta', defaultValue: false)
        booleanParam(name: 'SKIP_UPDATE_META_CHART_CONTENT', description: 'Skip updating meta chart content with plus versions', defaultValue: true) // TODO: EEAEPP-100345
        booleanParam(name: 'PUBLISH_DRY_RUN', description: 'Enable dry-run for helm chart publish, arm upload and version increase', defaultValue: false)
    }

    environment {
        INT_CHART_NAME='eric-eea-int-helm-chart'
        META_CHART_NAME='eric-eea-ci-meta-helm-chart'
        DOC_CHART_NAME='eric-eea-documentation-helm-chart-ci'
        EEA_DEPLOYER_CHART_NAME='eric-eea-deployer'

        HELM_REPOPATH_CI_INTERNAL='proj-eea-ci-internal-helm-local'
        HELM_REPOPATH_DROP='proj-eea-drop-helm-local'
        HELM_REPOPATH_RELEASED='proj-eea-released-helm-local'

        GENERIC_REPOPATH_CI_INTERNAL='proj-eea-internal-generic-local'
        GENERIC_REPOPATH_DROP='proj-eea-drop-generic-local'
        GENERIC_REPOPATH_RELEASED='proj-eea-released-generic-local'

        CHART_REPO_DROP="${Artifactory.defaultUrl}/artifactory/${env.HELM_REPOPATH_DROP}/"
        CHART_REPO_RELEASED="${Artifactory.defaultUrl}/artifactory/${env.HELM_REPOPATH_RELEASED}/"
        GENERIC_REPO_RELEASED="${Artifactory.defaultUrl}/artifactory/${env.GENERIC_REPOPATH_RELEASED}/"

        DOC_SOURCE_REPO='proj-eea-docs-drop-generic-local'
        DOC_SOURCE_FOLDER='product-level-docs'
        DOC_RELEASED_REPO='proj-eea-docs-released-generic-local'
        DOC_RELEASED_FOLDER='product-level-docs'
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

                        env.INT_CHART_VERSION_RELEASED = ''
                        env.DOC_CHART_VERSION_RELEASED = ''
                        env.EEA_DEPLOYER_CHART_VERSION_RELEASED = ''
                        env.META_CHART_VERSION_RELEASED = ''

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

        stage('Checkout cnint') {
            steps {
                script {
                    gitcnint.checkout(env.INT_CHART_VERSION, 'cnint')
                }
            }
        }

        stage('Init versions') {
            steps {
                script {
                    env.INT_CHART_VERSION_PRA = sh(script: "echo ${env.INT_CHART_VERSION} | sed 's/-/+/g'", returnStdout: true).trim()
                    env.INT_CHART_VERSION_NONPRA = sh(script: "echo ${env.INT_CHART_VERSION} | sed 's/+/-/g'", returnStdout: true).trim()
                    echo "env.INT_CHART_VERSION (original): ${env.INT_CHART_VERSION}"
                    echo "env.INT_CHART_VERSION_PRA: ${env.INT_CHART_VERSION_PRA}"
                    echo "env.INT_CHART_VERSION_NONPRA: ${env.INT_CHART_VERSION_NONPRA}"

                    echo "--> Meta chart version: ${env.META_CHART_VERSION}"
                    echo "--> Product version: ${env.INT_CHART_VERSION_PRA}"

                    currentBuild.description = "Meta chart version: ${env.META_CHART_VERSION}"
                    currentBuild.description += '<br>' + "Product version: ${env.INT_CHART_VERSION}"
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
                stage('Cleanup product') {
                    steps {
                        catchError(stageResult: 'FAILURE', buildResult: 'FAILURE') {
                            dir('master-adp-app-staging') {
                                sh './bob/bob -r ruleset2.0_product_release.yaml clean'
                            }
                        }
                    }
                }
                stage('Init versions product') {
                    steps {
                        catchError(stageResult: 'FAILURE', buildResult: 'FAILURE') {
                            dir('master-adp-app-staging') {
                                withEnv([
                                    "CHART_NAME=${env.INT_CHART_NAME}",
                                    "CHART_VERSION=${env.INT_CHART_VERSION}",
                                    "CHART_REPO=${env.CHART_REPO_DROP}"]) {
                                    sh './bob/bob -r ruleset2.0_product_release.yaml init-released-version'
                                    script {
                                        releasedVersion = readFile(".bob/var.released-version").trim()
                                        helmChartFileName = readFile(".bob/var.helmchart-file-name").trim()
                                        releasedHelmChartFile = readFile(".bob/var.released-helmchart-file").trim()
                                        echo "${env.INT_CHART_NAME} Released version: ${releasedVersion}"
                                        echo "${env.INT_CHART_NAME} Released url: ${releasedHelmChartFile}"
                                        currentBuild.description += "<br>${env.INT_CHART_NAME} version: ${releasedVersion}, released package: <a href=\"${releasedHelmChartFile}\">${helmChartFileName}</a>"
                                        env.INT_CHART_VERSION_RELEASED = releasedVersion
                                    }
                                }
                            }
                        }
                    }
                }
                stage('Generate and Upload Integration Helm Chart') {
                    steps {
                        catchError(stageResult: 'FAILURE', buildResult: 'FAILURE') {
                            script {
                                def releasedPackage = "${env.INT_CHART_NAME}/${helmChartFileName}"
                                if (arm.checkIfArtifactExists("${env.HELM_REPOPATH_RELEASED}", "${releasedPackage}")) {
                                    echo "${releasedPackage} already exists in ${HELM_REPOPATH_RELEASED} repo --> skip uploading"
                                    return
                                }
                                echo "${releasedPackage} NOT yet exists in ${HELM_REPOPATH_RELEASED} repo --> trying to generate and upload ..."
                                dir('master-adp-app-staging') {
                                    withCredentials([
                                                    usernamePassword(credentialsId: 'arm-functional-user', usernameVariable: 'HELM_USER', passwordVariable: 'HELM_TOKEN'),
                                                    usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                                    usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD'),
                                                    string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                                    string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                                        script {
                                            gitcnint.archiveFile('EEA/cnint', 'HEAD repositories.yaml.template')
                                        }
                                        withEnv([
                                            "CHART_NAME=${env.INT_CHART_NAME}",
                                            "CHART_VERSION=${env.INT_CHART_VERSION}",
                                            "CHART_REPO=${env.CHART_REPO_DROP}"]) {
                                            sh './bob/bob -r ruleset2.0_product_release.yaml publish-released-helm-chart'
                                        }
                                        archiveArtifacts artifacts: '.bob/released-charts/*', allowEmptyArchive: true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        stage('Generate and Upload CSAR files') {
            when {
                expression { params.SKIP_RELEASE_CSAR == false }
            }
            steps {
                script {
                    def csarPackageName = "csar-package-${env.INT_CHART_VERSION_PRA}.csar"
                    currentBuild.description += "<br>csar-package version: ${env.INT_CHART_VERSION_PRA}, released package: <a href=\"${env.GENERIC_REPO_RELEASED}${csarPackageName}\">${csarPackageName}</a>"

                    if (arm.checkIfArtifactExists("${env.GENERIC_REPOPATH_RELEASED}", "${csarPackageName}")) {
                        echo "${csarPackageName} already exists in ${env.GENERIC_REPOPATH_RELEASED} repo --> skip uploading"
                        return
                    }
                    echo "${csarPackageName} NOT yet exists in ${env.HELM_REPOPATH_RELEASED} repo --> trying to generate and upload ..."
                    build job: "csar-build",
                    parameters: [
                        booleanParam(name: 'DRY_RUN', value: env.PUBLISH_DRY_RUN),
                        stringParam(name: 'INT_CHART_REPO', value: "${env.CHART_REPO_RELEASED}"),
                        stringParam(name: 'INT_CHART_VERSION', value: "${env.INT_CHART_VERSION_PRA}")
                    ],
                    wait : true

                    catchError(stageResult: 'FAILURE', buildResult: 'SUCCESS') {

                        if (env.PUBLISH_DRY_RUN.toBoolean()) {
                            // When PUBLISH_DRY_RUN is true, download the CSAR from drop repository as it is not generating again
                            csarPackageNameMinus = "csar-package-${env.INT_CHART_VERSION}.csar"
                            arm.downloadArtifact("${csarPackageNameMinus}", "${csarPackageName}", "${env.GENERIC_REPOPATH_DROP}")
                        } else {
                            // When PUBLISH_DRY_RUN is false, download the CSAR from internal repository as it has just been generated previously
                            arm.downloadArtifact("${csarPackageName}", "${csarPackageName}", "${env.GENERIC_REPOPATH_CI_INTERNAL}")
                        }

                        csarutils.extractImagesTxtAndCreateContentTxtBesideCsar("${csarPackageName}")

                        // for comparison, download the - CSAR images.txt from drop repository
                        def minusversionimages = 'csar-package-' + env.INT_CHART_VERSION_PRA.replace("+", "-") + '.images.txt'
                        arm.downloadArtifact(minusversionimages, minusversionimages, "${env.GENERIC_REPOPATH_DROP}")

                        // check for already extracted images.txt and downloaded one, should be no diffs
                        if (comparePlusAndMinusCsarVersionForDifferentImages(minusversionimages, 'images.txt'))
                            error ("CSAR + and - version mismatch!")

                        // Upload the CSAR to the released repository
                        arm.deployArtifact(
                            "${csarPackageName}",
                            "${csarPackageName}",
                            "${env.GENERIC_REPOPATH_RELEASED}",
                            env.PUBLISH_DRY_RUN.toBoolean()
                        )

                        withCredentials([string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                            csarutils.fetchAndProcess3ppListJsonsToCsv()
                        }

                        // Upload images.txt, content.txt and 3pplist.csv next to the CSAR
                        arm.deployArtifact(
                            'images.txt',
                            "csar-package-${env.INT_CHART_VERSION_PRA}.images.txt",
                            "${env.GENERIC_REPOPATH_RELEASED}",
                            env.PUBLISH_DRY_RUN.toBoolean()
                        )
                        arm.deployArtifact(
                            'content.txt',
                            "csar-package-${env.INT_CHART_VERSION_PRA}.content.txt",
                            "${env.GENERIC_REPOPATH_RELEASED}",
                            env.PUBLISH_DRY_RUN.toBoolean()
                        )
                        arm.deployArtifact(
                            '3pplist.csv',
                            "csar-package-${env.INT_CHART_VERSION_PRA}.3pp_list.csv",
                            "${env.GENERIC_REPOPATH_RELEASED}",
                            env.PUBLISH_DRY_RUN.toBoolean()
                        )
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
                stage('Cleanup documentation') {
                    steps {
                        catchError(stageResult: 'FAILURE', buildResult: 'FAILURE') {
                            dir('build-eea4_documentation') {
                                sh './bob/bob -r ${WORKSPACE}/master-eea4_documentation/bob-rulesets/documentation_release.yaml clean'
                            }
                        }
                    }
                }
                stage('Init versions documentation') {
                    steps {
                        catchError(stageResult: 'FAILURE', buildResult: 'FAILURE') {
                            dir('build-eea4_documentation') {
                                withEnv(["RELEASE_CANDIDATE=${env.DOC_RELEASE_CANDIDATE}"]) {
                                    sh './bob/bob -r ${WORKSPACE}/master-eea4_documentation/bob-rulesets/documentation_release.yaml doc-init'
                                    script {
                                        releasedVersion = readFile(".bob/var.released-version").trim()
                                        helmChartFileName = readFile(".bob/var.helmchart-file-name").trim()
                                        releasedHelmChartFile = readFile(".bob/var.released-helmchart-file").trim()
                                        echo "${env.DOC_CHART_NAME} Released version: ${releasedVersion}"
                                        echo "${env.DOC_CHART_NAME} Released url: ${releasedHelmChartFile}"
                                        currentBuild.description += "<br>${env.DOC_CHART_NAME} version: ${releasedVersion}, released package: <a href=\"${releasedHelmChartFile}\">${helmChartFileName}</a>"
                                        env.DOC_CHART_VERSION_RELEASED = releasedVersion
                                    }
                                }
                            }
                        }
                    }
                }
                stage('Generate and Upload Documentation Helm Chart') {
                    steps {
                        catchError(stageResult: 'FAILURE', buildResult: 'FAILURE') {
                            script {
                                def releasedPackage = "${env.DOC_CHART_NAME}/${helmChartFileName}"
                                if (arm.checkIfArtifactExists("${env.HELM_REPOPATH_RELEASED}", "${releasedPackage}")) {
                                    echo "${releasedPackage} already exists in ${HELM_REPOPATH_RELEASED} repo --> skip uploading"
                                    return
                                }
                                echo "${releasedPackage} NOT yet exists in ${HELM_REPOPATH_RELEASED} repo --> trying to generate and upload ..."
                                dir('build-eea4_documentation') {
                                    withCredentials([usernamePassword(credentialsId: 'arm-functional-user', usernameVariable: 'HELM_USER', passwordVariable: 'HELM_TOKEN')])
                                    {
                                        withEnv(["RELEASE_CANDIDATE=${env.DOC_RELEASE_CANDIDATE}"]) {
                                            sh './bob/bob -r ${WORKSPACE}/master-eea4_documentation/bob-rulesets/documentation_release.yaml publish-released-helm-chart'
                                        }
                                        archiveArtifacts artifacts: '.bob/released-charts/*', allowEmptyArchive: true
                                    }
                                }
                            }
                        }
                    }
                }
                stage('Copy released documentation artifacts') {
                    steps {
                        catchError(stageResult: 'FAILURE', buildResult: 'FAILURE') {
                            dir('build-eea4_documentation') {
                                script {
                                    arm.copyArtifact(
                                        "${env.DOC_SOURCE_FOLDER}/${env.DOC_RELEASE_CANDIDATE}",
                                        "${env.DOC_SOURCE_REPO}",
                                        "${env.DOC_RELEASED_FOLDER}/${env.DOC_RELEASE_CANDIDATE}",
                                        "${env.DOC_RELEASED_REPO}",
                                        env.PUBLISH_DRY_RUN.toBoolean()
                                    )
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
                        dir('build-deployer') {
                            checkoutGitSubmodules()
                        }
                    }
                }
                stage('Init versions deployer') {
                    steps {
                        catchError(stageResult: 'FAILURE', buildResult: 'FAILURE') {
                            dir('build-deployer') {
                                withEnv([
                                    "EEA_DEPLOYER_CHART_NAME=${env.EEA_DEPLOYER_CHART_NAME}",
                                    "EEA_DEPLOYER_CHART_VERSION=${env.EEA_DEPLOYER_CHART_VERSION}",
                                    "EEA_DEPLOYER_CHART_REPO=${env.CHART_REPO_DROP}"]) {
                                    sh './bob/bob -r ${WORKSPACE}/master-deployer/bob-rulesets/ruleset2.0_deployer_release.yaml init-released-version'
                                    script {
                                        releasedVersion = readFile(".bob/var.eea-deployer-released-version").trim()
                                        helmChartFileName = readFile(".bob/var.eea-deployer-helmchart-file-name").trim()
                                        releasedHelmChartFile = readFile(".bob/var.eea-deployer-released-helmchart-file").trim()
                                        echo "${env.EEA_DEPLOYER_CHART_NAME} Released version: ${releasedVersion}"
                                        echo "${env.EEA_DEPLOYER_CHART_NAME} Released url: ${releasedHelmChartFile}"
                                        currentBuild.description += "<br>${env.EEA_DEPLOYER_CHART_NAME} version: ${releasedVersion}, released package: <a href=\"${releasedHelmChartFile}\">${helmChartFileName}</a>"
                                        env.EEA_DEPLOYER_CHART_VERSION_RELEASED = releasedVersion
                                    }
                                }
                            }
                        }
                    }
                }
                stage('Generate and Upload Deployer Helm Chart') {
                    steps {
                        catchError(stageResult: 'FAILURE', buildResult: 'FAILURE') {
                            script {
                                def releasedPackage = "${env.EEA_DEPLOYER_CHART_NAME}/${helmChartFileName}"
                                if (arm.checkIfArtifactExists("${env.HELM_REPOPATH_RELEASED}", "${releasedPackage}")) {
                                    echo "${releasedPackage} already exists in ${HELM_REPOPATH_RELEASED} repo --> skip uploading"
                                    return
                                }
                                echo "${releasedPackage} NOT yet exists in ${HELM_REPOPATH_RELEASED} repo --> trying to generate and upload ..."
                                dir('build-deployer') {
                                    withCredentials([
                                                    usernamePassword(credentialsId: 'arm-functional-user', usernameVariable: 'HELM_USER', passwordVariable: 'HELM_TOKEN'),
                                                    usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                                    usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD'),
                                                    string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                                    string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                                        withEnv([
                                            "EEA_DEPLOYER_CHART_NAME=${env.EEA_DEPLOYER_CHART_NAME}",
                                            "EEA_DEPLOYER_CHART_VERSION=${env.EEA_DEPLOYER_CHART_VERSION}",
                                            "EEA_DEPLOYER_CHART_REPO=${env.CHART_REPO_DROP}"]) {
                                            sh './bob/bob -r ${WORKSPACE}/master-deployer/bob-rulesets/ruleset2.0_deployer_release.yaml publish-eea-deployer-released-helm-chart'
                                        }
                                        archiveArtifacts artifacts: '.bob/eea-deployer-released-charts/*', allowEmptyArchive: true
                                    }
                                }
                            }
                        }
                    }
                }
                stage('DEPLOYER + package build') {
                    steps {
                        catchError(stageResult: 'FAILURE', buildResult: 'FAILURE') {
                            dir('build-deployer') {
                                script {
                                    releasedVersion = readFile(".bob/var.eea-deployer-released-version").trim()
                                    build job: 'eea-deployer-build-deployer-package',
                                    parameters: [
                                        booleanParam(name: 'DRY_RUN', value: env.PUBLISH_DRY_RUN),
                                        stringParam(name: 'CHART_VERSION', value: releasedVersion),
                                        stringParam(name: 'GERRIT_REFSPEC', value: "refs/tags/${env.EEA_DEPLOYER_CHART_VERSION}"),
                                        booleanParam(name: 'IS_RELEASE', value: true)
                                    ], wait : true
                                }
                            }
                        }
                    }
                }
                stage('Exec eea-deployer-release-new-version') {
                    steps {
                        catchError(stageResult: 'FAILURE', buildResult: 'FAILURE') {
                            dir('build-deployer') {
                                script {
                                    masterVersion = cmutils.getChartVersion("${WORKSPACE}/master-deployer/helm/${env.EEA_DEPLOYER_CHART_NAME}", "Chart.yaml")
                                    releasedVersion = readFile(".bob/var.eea-deployer-released-version").trim()
                                    nextVersion = readFile(".bob/var.eea-deployer-next-version").trim()
                                    echo "${env.EEA_DEPLOYER_CHART_NAME} Master version: ${masterVersion}"
                                    echo "${env.EEA_DEPLOYER_CHART_NAME} Released version: ${releasedVersion}"
                                    echo "${env.EEA_DEPLOYER_CHART_NAME} Next version: ${nextVersion}"

                                    if (checkIfDeployerVersionIncreasable(masterVersion, releasedVersion)) {
                                        build job: 'eea-deployer-release-new-version',
                                        parameters: [
                                            booleanParam(name: 'DRY_RUN', value: env.PUBLISH_DRY_RUN),
                                            stringParam(name: 'REVISION_NUM', value: "${nextVersion}"),
                                            stringParam(name: 'GIT_COMMENT', value: "Increase version after ${releasedVersion}")
                                        ], wait: true
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
                            gitmeta.checkout(env.META_CHART_VERSION, 'build-project-meta-baseline')
                        }
                    }
                }
                stage('Prepare bob meta') {
                    steps {
                        dir('build-project-meta-baseline') {
                            checkoutGitSubmodules()
                        }
                    }
                }
                stage('Cleanup meta') {
                    steps {
                        dir('build-project-meta-baseline') {
                            sh './bob/bob -r ${WORKSPACE}/master-project-meta-baseline/bob-rulesets/ruleset2.0_product_release.yaml clean'
                        }
                    }
                }
                stage('Init versions meta') {
                    steps {
                        catchError(stageResult: 'FAILURE', buildResult: 'FAILURE') {
                            dir('build-project-meta-baseline') {
                                withEnv([
                                    "META_CHART_NAME=${env.META_CHART_NAME}",
                                    "META_CHART_VERSION=${env.META_CHART_VERSION}",
                                    "META_CHART_REPO=${env.CHART_REPO_DROP}"]) {
                                    sh './bob/bob -r ${WORKSPACE}/master-project-meta-baseline/bob-rulesets/ruleset2.0_product_release.yaml init-released-version'
                                    script {
                                        releasedVersion = readFile(".bob/var.released-version").trim()
                                        helmChartFileName = readFile(".bob/var.helmchart-file-name").trim()
                                        releasedHelmChartFile = readFile(".bob/var.released-helmchart-file").trim()
                                        echo "${env.META_CHART_NAME} Released version: ${releasedVersion}"
                                        echo "${env.META_CHART_NAME} Released url: ${releasedHelmChartFile}"
                                        currentBuild.description += "<br>${env.META_CHART_NAME} version: ${releasedVersion}, released package: <a href=\"${releasedHelmChartFile}\">${helmChartFileName}</a>"
                                        env.META_CHART_VERSION_RELEASED = releasedVersion
                                    }
                                }
                            }
                        }
                    }
                }
                stage('Replace meta chart -+ versions') {
                    when {
                        expression { params.SKIP_UPDATE_META_CHART_CONTENT == false }
                    }
                    steps {
                        updateMetaChartContent()
                    }
                }
                stage('Generate and Upload Meta Helm Chart') {
                    steps {
                        catchError(stageResult: 'FAILURE', buildResult: 'FAILURE') {
                            script {
                                def releasedPackage = "${env.META_CHART_NAME}/${helmChartFileName}"
                                if (arm.checkIfArtifactExists("${env.HELM_REPOPATH_RELEASED}", "${releasedPackage}")) {
                                    echo "${releasedPackage} already exists in ${HELM_REPOPATH_RELEASED} repo --> skip uploading"
                                    return
                                }
                                echo "${releasedPackage} NOT yet exists in ${HELM_REPOPATH_RELEASED} repo --> trying to generate and upload ..."
                                dir('build-project-meta-baseline') {
                                    withCredentials([
                                                    usernamePassword(credentialsId: 'arm-functional-user', usernameVariable: 'HELM_USER', passwordVariable: 'HELM_TOKEN'),
                                                    usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                                    usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD'),
                                                    string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                                    string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                                        script {
                                            gitcnint.archiveFile('EEA/cnint', 'HEAD repositories.yaml.template')
                                        }
                                        withEnv([
                                            "META_CHART_NAME=${env.META_CHART_NAME}",
                                            "META_CHART_VERSION=${env.META_CHART_VERSION}",
                                            "META_CHART_REPO=${env.CHART_REPO_DROP}"]) {
                                            // TODO: chart building not works with the modified Chart.yaml content,
                                            // must be handled in the improvement ticket: EEAEPP-100345
                                            sh './bob/bob -r ${WORKSPACE}/master-project-meta-baseline/bob-rulesets/ruleset2.0_product_release.yaml publish-released-helm-chart'
                                        }
                                        archiveArtifacts artifacts: '.bob/released-charts/*', allowEmptyArchive: true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        stage('Upload dimtool') {
            steps {
                uploadDimtool(arm)
            }
        }

        stage('Upload spotfire-platform-asset') {
            steps {
                uploadSpotfirePlatformAsset(arm)
            }
        }

        stage('Upload test tools') {
            steps {
                uploadTestTools(arm)
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

def uploadDimtool(Artifactory arm) {
    catchError(stageResult: 'FAILURE', buildResult: 'FAILURE') {
        script {
            def sourceDimtoolPackage = "eea4-dimensioning-tool/eea4-dimensioning-tool-${env.INT_CHART_VERSION}.zip"
            def targetDimtoolPackage = "eea4-dimensioning-tool/eea4-dimensioning-tool-${env.INT_CHART_VERSION_PRA}.zip"
            currentBuild.description += "<br>eea4-dimensioning-tool version: ${env.INT_CHART_VERSION_PRA}, released package: <a href=\"${env.GENERIC_REPO_RELEASED}${targetDimtoolPackage}\">${targetDimtoolPackage}</a>"
            if (arm.checkIfArtifactExists("${env.GENERIC_REPOPATH_RELEASED}", "${targetDimtoolPackage}")) {
                echo "${targetDimtoolPackage} already exists in ${env.GENERIC_REPOPATH_RELEASED} repo --> skip uploading"
            } else {
                echo "${targetDimtoolPackage} NOT exists in ${env.GENERIC_REPOPATH_RELEASED} repo --> uploading ..."
                // Copy '-' version of dimtool from drop repo to released repo replacing - to + in its version
                arm.copyArtifact(
                    "${sourceDimtoolPackage}",
                    "${env.GENERIC_REPOPATH_DROP}",
                    "${targetDimtoolPackage}",
                    "${env.GENERIC_REPOPATH_RELEASED}",
                    env.PUBLISH_DRY_RUN.toBoolean()
                )
            }
        }
    }
}


def uploadSpotfirePlatformAsset(Artifactory arm) {
    catchError(stageResult: 'FAILURE', buildResult: 'FAILURE') {
        script {
            def data = readYaml file: 'cnint/spotfire_platform.yml'
            def assetPackage = "sf-platform-asset/${data.spotfire_platform.spotfire_asset.version}.zip"
            currentBuild.description += "<br>${data.spotfire_platform.spotfire_asset.version}, released package: <a href=\"${env.GENERIC_REPO_RELEASED}${assetPackage}\">${assetPackage}</a>"
            if (arm.checkIfArtifactExists("${env.GENERIC_REPOPATH_RELEASED}", "${assetPackage}")) {
                echo "${assetPackage} already exists in ${env.GENERIC_REPOPATH_RELEASED} repo --> skip uploading"
            } else {
                echo "${assetPackage} NOT exists in ${env.GENERIC_REPOPATH_RELEASED} repo --> uploading ..."
                arm.copyArtifact(
                    "${assetPackage}",
                    "${env.GENERIC_REPOPATH_DROP}",
                    "${assetPackage}",
                    "${env.GENERIC_REPOPATH_RELEASED}",
                    env.PUBLISH_DRY_RUN.toBoolean()
                )
            }
        }
    }
}

def uploadTestTools(Artifactory arm) {
    catchError(stageResult: 'FAILURE', buildResult: 'FAILURE') {
        script {
            List services = [
                ['name': 'eric-data-loader',         'path': 'eric-data-loader'],
                ['name': 'eric-eea-utf-application', 'path': 'eric-eea-utf-application'],
                ['name': 'eric-eea-jenkins-docker',  'path': 'eric-eea-jenkins-docker'],
                ['name': 'eric-eea-robot',           'path': 'eric-eea-robot'],
                ['name': 'eric-eea-snmp-server',     'path': 'eea-internal/eric-eea-snmp-server'],
                ['name': 'eric-eea-sftp-server',     'path': 'eea-internal/eric-eea-sftp-server'],
            ]
            def chart = readYaml file: "project-meta-baseline/${env.META_CHART_NAME}/Chart.yaml"
            services.each { service ->
                def serviceName =  "${service['name']}"
                def servicePath =  "${service['path']}"
                chart.dependencies.each { dependency ->
                    if (dependency.name == serviceName) {
                        def serviceVersion = dependency.version
                        def sourceServicePackage = "${servicePath}/${serviceName}-${serviceVersion}.tgz"
                        def targetServicePackage = "${serviceName}/${serviceName}-${serviceVersion}.tgz"
                        currentBuild.description += "<br>${serviceName} version: ${serviceVersion}, released package: <a href=\"${CHART_REPO_RELEASED}${targetServicePackage}\">${targetServicePackage}</a>"
                        if (arm.checkIfArtifactExists("${env.HELM_REPOPATH_RELEASED}", "${targetServicePackage}")) {
                            echo "${targetServicePackage} already exists in ${env.HELM_REPOPATH_RELEASED} repo --> skip uploading"
                        } else {
                            echo "${targetServicePackage} NOT exists in ${env.HELM_REPOPATH_RELEASED} repo --> uploading ..."
                            arm.copyArtifact(
                                "${sourceServicePackage}",
                                "${env.HELM_REPOPATH_DROP}",
                                "${targetServicePackage}",
                                "${env.HELM_REPOPATH_RELEASED}",
                                env.PUBLISH_DRY_RUN.toBoolean()
                            )
                        }
                    }
                }
            }
        }
    }
}

def updateMetaChartContent() {
    catchError(stageResult: 'FAILURE', buildResult: 'FAILURE') {
        script {
            dir('build-project-meta-baseline') {
                echo "Processing ${env.META_CHART_NAME}/Chart.yaml"
                def repositoryOld='proj-eea-drop-helm'
                def repositoryNew='proj-eea'
                def data = readYaml file: "${env.META_CHART_NAME}/Chart.yaml"
                data.dependencies.each { dependency ->
                    if (dependency.name == env.INT_CHART_NAME && env.INT_CHART_VERSION_RELEASED) {
                        echo "Found ${dependency.name}-${dependency.version}"
                        if (dependency.version != "${env.INT_CHART_VERSION_RELEASED}") {
                            echo "Updating ${dependency.name} version from ${dependency.version} to ${env.INT_CHART_VERSION_RELEASED} ..."
                            dependency.version = "${env.INT_CHART_VERSION_RELEASED}"
                        }
                        if (dependency.repository.contains(repositoryOld)) {
                            echo "Updating ${dependency.name} dependency from ${repositoryOld} to ${repositoryNew} ..."
                            dependency.repository = dependency.repository.replaceAll(repositoryOld, repositoryNew)
                        }
                    }
                    if (dependency.name == env.DOC_CHART_NAME && env.DOC_CHART_VERSION_RELEASED) {
                        echo "Found ${dependency.name}-${dependency.version}"
                        if (dependency.version != "${env.DOC_CHART_VERSION_RELEASED}") {
                            echo "Updating ${dependency.name} version from ${dependency.version} to ${env.DOC_CHART_VERSION_RELEASED} ..."
                            dependency.version = "${env.DOC_CHART_VERSION_RELEASED}"
                        }
                        if (dependency.repository.contains(repositoryOld)) {
                            echo "Updating ${dependency.name} dependency from ${repositoryOld} to ${repositoryNew} ..."
                            dependency.repository = dependency.repository.replaceAll(repositoryOld, repositoryNew)
                        }
                    }
                    if (dependency.name == env.EEA_DEPLOYER_CHART_NAME && env.EEA_DEPLOYER_CHART_VERSION_RELEASED) {
                        echo "Found ${dependency.name}-${dependency.version}"
                        if (dependency.version != "${env.EEA_DEPLOYER_CHART_VERSION_RELEASED}") {
                            echo "Updating ${dependency.name} version from ${dependency.version} to ${env.EEA_DEPLOYER_CHART_VERSION_RELEASED} ..."
                            dependency.version = "${env.EEA_DEPLOYER_CHART_VERSION_RELEASED}"
                        }
                        if (dependency.repository.contains(repositoryOld)) {
                            echo "Updating ${dependency.name} dependency from ${repositoryOld} to ${repositoryNew} ..."
                            dependency.repository = dependency.repository.replaceAll(repositoryOld, repositoryNew)
                        }
                    }
                }
                writeYaml file: "${env.META_CHART_NAME}/Chart.yaml", data: data, overwrite: true
            }
        }
    }
}


def getVersionSeparator(String version) {
    if (version.contains('+')) {
        return '\\+'
    } else if (version.contains('-')) {
        return '-'
    } else {
        error("version has wrong input format: ${version}!")
    }
}

def checkIfDeployerVersionIncreasable(String masterVersion, String releasedVersion) {
    /*
    + new version uplift can happen in deployer repo only if the master version is not bigger than the currently released version, e.g.
      + release: 0.5.0+17, master: 0.5.0-18 -> let's increase to 0.6.0-1
      + release: 0.5.0+17, master: 0.6.0-2 -> skip
    */
    script {
        def masterVersionSeparator = getVersionSeparator(masterVersion)
        def masterRevisionNumber = masterVersion.split(masterVersionSeparator)[0]
        def masterMajorNumber = masterRevisionNumber.split("\\.")[0]
        def masterMinorNumber = masterRevisionNumber.split("\\.")[1]
        def masterPatchNumber = masterRevisionNumber.split("\\.")[2]

        def releasedVersionSeparator = getVersionSeparator(releasedVersion)
        def releasedRevisionNumber = releasedVersion.split(releasedVersionSeparator)[0]
        def releasedMajorNumber = releasedRevisionNumber.split("\\.")[0]
        def releasedMinorNumber = releasedRevisionNumber.split("\\.")[1]
        def releasedPatchNumber = releasedRevisionNumber.split("\\.")[2]

        echo "Master state of the deployer version: ${masterVersion}\n - MAJOR_NUMBER: ${masterMajorNumber}\n - MINOR_NUMBER: ${masterMinorNumber}\n - PATCH_NUMBER: ${masterPatchNumber}\n - REVISION_NUMBER: ${masterRevisionNumber}"
        echo "Released state of the deployer version: ${releasedVersion}\n - MAJOR_NUMBER: ${releasedMajorNumber}\n - MINOR_NUMBER: ${releasedMinorNumber}\n - PATCH_NUMBER: ${releasedPatchNumber}\n - REVISION_NUMBER: ${releasedRevisionNumber}"
        normalizedVersionMaster = String.format('%03d', masterMajorNumber.toInteger()) + String.format('%03d', masterMinorNumber.toInteger()) + String.format('%03d', masterPatchNumber.toInteger())
        normalizedVersionReleased = String.format('%03d', releasedMajorNumber.toInteger()) + String.format('%03d', releasedMinorNumber.toInteger()) + String.format('%03d', releasedPatchNumber.toInteger())

        if (normalizedVersionMaster.toInteger() <= normalizedVersionReleased.toInteger()) {
            echo "Master state of the deployer version (${masterRevisionNumber}) is less than or equal to the released version (${releasedRevisionNumber}) --> executing deployer version increase ..."
            return true
        }
        echo "Master state of the deployer version (${masterRevisionNumber}) is greater than released version (${releasedRevisionNumber}) --> skipping deployer version increase"
        return false
    }
}
