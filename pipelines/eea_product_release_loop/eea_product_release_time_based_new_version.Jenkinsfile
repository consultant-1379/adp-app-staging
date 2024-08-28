@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.Artifactory
import com.ericsson.eea4.ci.CommonUtils
import com.ericsson.eea4.ci.ClusterLockUtils
import groovy.transform.Field

@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def gitmeta = new GitScm(this, 'EEA/project-meta-baseline')
@Field def gitdoc = new GitScm(this, 'EEA/eea4_documentation')
@Field def gitcdd = new GitScm(this, 'EEA/cdd')
@Field def gitdeployer = new GitScm(this, 'EEA/deployer')
@Field def arm = new Artifactory(this, "https://arm.seli.gic.ericsson.se/",  "API_TOKEN_EEA")
@Field def cmutils = new CommonUtils(this)

properties([
    parameters([
        [$class: 'DynamicReferenceParameter',
            choiceType: 'ET_FORMATTED_HTML',
            description: 'Chart version, format: <year>.<week>.<patch/EP number>-<build number>; e.g. 23.40.0-1',
            name: 'CHART_VERSION',
            omitValueField: true,
            script: [$class: 'GroovyScript',
                fallbackScript: [
                    classpath: [],
                    sandbox: false,
                    script: ''
                ],
                script: [
                    classpath: [],
                    sandbox: false,
                    script: '''
                        Date now = new Date();
                        def year = now.format('yy');
                        def week = now.format('w');
                        def patchNumber = '0';
                        def buildNumber = '1';
                        return "<input name='value' value='${year}.${week}.${patchNumber}-${buildNumber}' class='setting-input' type='text'>"
                    '''.stripIndent()
                ]
            ]
        ]
    ])
])

pipeline {
    options {
        skipDefaultCheckout()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(daysToKeepStr: "30", artifactDaysToKeepStr: "7"))
    }
    agent {
        node {
            label 'productci'
        }
    }
    triggers { cron('00 00 * * 1') } // run every Monday at 00:00
    parameters {
        booleanParam(name: 'DRY_RUN', description: 'Dry run', defaultValue: false)
        string(name: 'GIT_COMMENT', description: 'Comment for the version increase change', defaultValue: '', trim: true)
        booleanParam(name: 'SKIP_VERSION_UPDATE_CNINT', description: 'skip updating cnint version', defaultValue: false)
        booleanParam(name: 'SKIP_VERSION_UPDATE_META', description: 'skip updating meta version', defaultValue: false)
        booleanParam(name: 'SKIP_VERSION_UPDATE_DOCUMENTATION', description: 'skip updating documentation VERSION_PREFIX', defaultValue: false)
        booleanParam(name: 'SKIP_VERSION_UPDATE_CDD', description: 'skip updating cdd PRODUCT_VERSION', defaultValue: false)
        booleanParam(name: 'SKIP_VERSION_UPDATE_DEPLOYER', description: 'skip updating deployer PRODUCT_VERSION', defaultValue: false)
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
            when {
                expression { env.MAIN_BRANCH == 'master' }
            }
            steps {
                script {
                    if (!env.CHART_VERSION) {
                        env.CHART_VERSION = getDefaultTimeBasedVersion()
                    }
                    currentBuild.description = "CHART_VERSION: ${env.CHART_VERSION}"
                    def match = (env.CHART_VERSION =~ /[0-9]+\.[0-9]+\.[0-9]+[-\+][A-Za-z0-9]+/)
                    if (!match.find()) {
                        error("CHART_VERSION has wrong input format: ${env.CHART_VERSION}!\nFormat must be: <year>.<week>.<patch/EP number>+<build number>; e.g. 23.40.0+1")
                    }
                    if (!env.GIT_COMMENT) {
                        env.GIT_COMMENT = "Increase time based helm chart version ${env.CHART_VERSION}"
                    }
                }
            }
        }

        stage('Parse input version') {
            when {
                expression { env.MAIN_BRANCH == 'master' }
            }
            steps {
                script {
                    env.VERSION_SEPARATOR = getVersionSeparator(env.CHART_VERSION)
                    env.REVISION_NUMBER = env.CHART_VERSION.split(env.VERSION_SEPARATOR)[0]
                    env.MAJOR_NUMBER = env.REVISION_NUMBER.split("\\.")[0]
                    env.MINOR_NUMBER = env.REVISION_NUMBER.split("\\.")[1]
                    env.PATCH_NUMBER = env.REVISION_NUMBER.split("\\.")[2]
                    env.BUILD_NUMBER = env.CHART_VERSION.split(env.VERSION_SEPARATOR)[1]
                    echo "New IHC version: ${env.CHART_VERSION}\n - MAJOR_NUMBER: ${env.MAJOR_NUMBER}\n - MINOR_NUMBER: ${env.MINOR_NUMBER}\n - PATCH_NUMBER: ${env.PATCH_NUMBER}\n - BUILD_NUMBER: ${env.BUILD_NUMBER}\n - REVISION_NUMBER: ${env.REVISION_NUMBER}"
                }
            }
        }

        stage('cnint version updater') {
            when {
                expression { env.MAIN_BRANCH == 'master' && !env.SKIP_VERSION_UPDATE_CNINT.toBoolean() }
            }
            environment {
                CHART_NAME = 'eric-eea-int-helm-chart'
                CHART_PATH="${env.CHART_NAME}/Chart.yaml"
                VALUES_PATH="${env.CHART_NAME}/values.yaml"
            }
            stages {
                stage('cnint - Checkout') {
                    steps {
                        script {
                            gitcnint.checkout('master', 'cnint')
                        }
                    }
                }

                stage('cnint - Check if version is already merged') {
                    steps {
                        dir('cnint') {
                            script {
                                env.CHART_VERSION_ON_MASTER = cmutils.getChartVersion("${env.CHART_NAME}", "Chart.yaml")
                                env.SKIP_VERSION_UPDATE_CNINT = !checkVersion(env.CHART_VERSION_ON_MASTER, 'cnint IHC')
                                if (env.SKIP_VERSION_UPDATE_CNINT.toBoolean()) {
                                    unstable("${STAGE_NAME}")
                                }
                            }
                        }
                    }
                }

                stage('cnint - Create and Push patchset') {
                    when {
                        expression { !env.SKIP_VERSION_UPDATE_CNINT.toBoolean() }
                    }
                    steps {
                        dir('cnint') {
                            script {
                                echo "Replace version in ${env.CHART_PATH} ..."
                                def data = readYaml file: "${env.CHART_PATH}"
                                def oldVersion = "version: ${data.version}"
                                def newVersion = "version: ${env.CHART_VERSION}"
                                echo " - oldVersion: ${oldVersion}"
                                echo " - newVersion: ${newVersion}"
                                sh """sed -i "s/$oldVersion/$newVersion/" ${CHART_PATH}"""

                                echo "Replace revision(s) in ${env.VALUES_PATH} ..."
                                def values = readYaml file: "${env.VALUES_PATH}"
                                def oldRevision = ""
                                if (values?.productInfo) {
                                    echo "Checking revision in path: values.productInfo ..."
                                    oldRevision = "revision: ${values.productInfo.revision}"
                                }
                                if (values.global?.productInfo) {
                                    echo "Checking revision in path: values.global.productInfo ..."
                                    oldRevision = "revision: ${values.global.productInfo.revision}"
                                }
                                if (oldRevision) {
                                    def newRevision = "revision: ${env.REVISION_NUMBER}"
                                    echo " - oldRevision: ${oldRevision}"
                                    echo " - newRevision: ${newRevision}"
                                    sh """sed -i "s/$oldRevision/$newRevision/" ${VALUES_PATH}"""
                                }

                                echo "createPatchset ..."
                                if (oldRevision) {
                                    gitcnint.createPatchset("${env.CHART_PATH} ${env.VALUES_PATH}", "${env.GIT_COMMENT}")
                                } else {
                                    gitcnint.createPatchset("${env.CHART_PATH}", "${env.GIT_COMMENT}")
                                }

                                env.COMMIT_ID= gitcnint.getCommitHashLong()
                                echo "COMMIT_ID: ${COMMIT_ID}"

                                env.GERRIT_REFSPEC_CNINT = gitcnint.getCommitRefSpec(env.COMMIT_ID)
                                echo "GERRIT_REFSPEC_CNINT: ${env.GERRIT_REFSPEC_CNINT}"

                                currentBuild.description += "<br>GERRIT_REFSPEC cnint: " + getGerritLink(env.GERRIT_REFSPEC_CNINT)
                            }
                        }
                    }
                }

                stage('cnint - Prepare') {
                    when {
                        expression { !env.SKIP_VERSION_UPDATE_CNINT.toBoolean() }
                    }
                    steps {
                        dir('cnint') {
                            checkoutGitSubmodules()
                        }
                    }
                }

                stage('cnint - Publish Helm Chart') {
                    when {
                        expression { !env.SKIP_VERSION_UPDATE_CNINT.toBoolean() }
                    }
                    steps {
                        dir('cnint') {
                            withCredentials([
                                            usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                            usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD'),
                                            string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                            string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                                script {
                                    gitcnint.archiveFile('EEA/cnint', 'HEAD repositories.yaml.template')
                                }
                                withEnv(["GERRIT_REFSPEC=${env.GERRIT_REFSPEC_CNINT}", "CHART_NAME=''", "CHART_VERSION=''"]) {
                                    sh 'bob/bob -r ruleset2.0.yaml publish'
                                }
                            }
                        }
                    }
                }

            }
        }

        stage('project-meta-baseline version updater') {
            when {
                expression { env.MAIN_BRANCH == 'master' && !env.SKIP_VERSION_UPDATE_META.toBoolean() }
            }
            environment {
                CHART_NAME = 'eric-eea-ci-meta-helm-chart'
                CHART_PATH="${env.CHART_NAME}/Chart.yaml"
            }
            stages {
                stage('project-meta-baseline - Checkout') {
                    steps {
                        script {
                            gitmeta.checkout('master', 'project-meta-baseline')
                        }
                    }
                }

                stage('project-meta-baseline - Check if version is already merged') {
                    steps {
                        dir('project-meta-baseline') {
                            script {
                                env.CHART_VERSION_ON_MASTER = cmutils.getChartVersion("${env.CHART_NAME}", "Chart.yaml")
                                env.SKIP_VERSION_UPDATE_META = !checkVersion(env.CHART_VERSION_ON_MASTER, 'meta IHC')
                                if (env.SKIP_VERSION_UPDATE_META.toBoolean()) {
                                    unstable("${STAGE_NAME}")
                                }
                            }
                        }
                    }
                }

                stage('project-meta-baseline - Create and Push patchset') {
                    when {
                        expression { !env.SKIP_VERSION_UPDATE_META.toBoolean() }
                    }
                    steps {
                        dir('project-meta-baseline') {
                            script {
                                echo "Replace version in ${env.CHART_PATH} ..."
                                def data = readYaml file: "${env.CHART_PATH}"
                                def oldVersion = "version: ${data.version}"
                                def newVersion = "version: ${env.CHART_VERSION}"
                                echo " - oldVersion: ${oldVersion}"
                                echo " - newVersion: ${newVersion}"
                                sh """sed -i "s/$oldVersion/$newVersion/" ${CHART_PATH}"""

                                echo "createPatchset ..."
                                gitmeta.createPatchset("${env.CHART_PATH}", "${env.GIT_COMMENT}")

                                env.COMMIT_ID= gitmeta.getCommitHashLong()
                                echo "COMMIT_ID: ${COMMIT_ID}"

                                env.GERRIT_REFSPEC_META = gitcnint.getCommitRefSpec(env.COMMIT_ID)
                                echo "GERRIT_REFSPEC_META: ${env.GERRIT_REFSPEC_META}"

                                currentBuild.description += "<br>GERRIT_REFSPEC meta: " + getGerritLink(env.GERRIT_REFSPEC_META)
                            }
                        }
                    }
                }

                stage('project-meta-baseline - Prepare') {
                    when {
                        expression { !env.SKIP_VERSION_UPDATE_META.toBoolean() }
                    }
                    steps {
                        dir('project-meta-baseline') {
                            checkoutGitSubmodules()
                        }
                    }
                }

                stage('project-meta-baseline - Publish Helm Chart') {
                    when {
                        expression { !env.SKIP_VERSION_UPDATE_META.toBoolean() }
                    }
                    steps {
                        dir('project-meta-baseline') {
                            withCredentials([
                                            usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                            usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD'),
                                            string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                            string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                                script {
                                    gitcnint.archiveFile('EEA/cnint', 'HEAD repositories.yaml.template')
                                }
                                withEnv(["GERRIT_REFSPEC=${env.GERRIT_REFSPEC_META}", "CHART_NAME=''", "CHART_VERSION=''"]) {
                                    sh 'bob/bob -r ruleset2.0.yaml publish-meta'
                                }
                            }
                        }
                    }
                }

            }
        }

        stage('documentation version updater') {
            when {
                expression { env.MAIN_BRANCH == 'master' && !env.SKIP_VERSION_UPDATE_DOCUMENTATION.toBoolean() }
            }
            options {
                lock resource: null, label: "doc-build", quantity: 1, variable: 'resource'
            }
            environment {
                VERSION_PREFIX_PATH="VERSION_PREFIX"
            }
            stages {
                stage('Set note - eea4_documentation doc-build lockable resource') {
                    steps {
                        script {
                            lock('resource-relabel') {
                                resource_lock = new ClusterLockUtils(this)
                                resource_lock.setReserved('eea4_documentation-new-version-ongoing', env.resource)
                                def note = "eea-product-release-time-based-new-version - " +  env.BUILD_NUMBER
                                echo 'Note: ' + note
                                resource_lock.setNoteForResource( env.resource, note )
                            }
                        }
                    }
                }

                stage('eea4_documentation - Checkout') {
                    steps {
                        script {
                            gitdoc.checkout('master', 'eea4_documentation')
                        }
                    }
                }

                stage('eea4_documentation - Check if version is already merged') {
                    steps {
                        dir('eea4_documentation') {
                            script {
                                env.CHART_VERSION_ON_MASTER = readFile file: "${env.VERSION_PREFIX_PATH}"
                                env.REVISION_NUMBER_ON_MASTER = env.CHART_VERSION_ON_MASTER // VERSION_PREFIX contains only major.minor.patch
                                env.SKIP_VERSION_UPDATE_DOCUMENTATION = !checkVersion(env.CHART_VERSION_ON_MASTER, 'doc VERSION_PREFIX')
                                if (env.SKIP_VERSION_UPDATE_DOCUMENTATION.toBoolean()) {
                                    unstable("${STAGE_NAME}")
                                }
                            }
                        }
                    }
                }

                stage('eea4_documentation - Create and Push patchset') {
                    when {
                        expression { !env.SKIP_VERSION_UPDATE_DOCUMENTATION.toBoolean() }
                    }
                    steps {
                        dir('eea4_documentation') {
                            script {
                                echo "Replace version in ${env.VERSION_PREFIX_PATH} ..."
                                def oldRevision = "${env.REVISION_NUMBER_ON_MASTER}"
                                def newRevision = "${env.REVISION_NUMBER}"
                                echo " - oldRevision: ${oldRevision}"
                                echo " - newRevision: ${newRevision}"
                                sh """sed -i "s/$oldRevision/$newRevision/" ${VERSION_PREFIX_PATH}"""

                                echo "createPatchset ..."
                                gitdoc.createPatchset("${env.VERSION_PREFIX_PATH}", "${env.GIT_COMMENT}")

                                env.COMMIT_ID= gitdoc.getCommitHashLong()
                                echo "COMMIT_ID: ${COMMIT_ID}"

                                env.GERRIT_REFSPEC_DOCUMENTATION = gitdoc.getCommitRefSpec(env.COMMIT_ID)
                                echo "GERRIT_REFSPEC_DOCUMENTATION: ${env.GERRIT_REFSPEC_DOCUMENTATION}"

                                currentBuild.description += "<br>GERRIT_REFSPEC doc: " + getGerritLink(env.GERRIT_REFSPEC_DOCUMENTATION)
                            }
                        }
                    }
                }

                stage('eea4_documentation - merge') {
                    when {
                        expression { !env.SKIP_VERSION_UPDATE_DOCUMENTATION.toBoolean() }
                    }
                    steps {
                        dir('eea4_documentation') {
                            script {
                                gitdoc.gerritReviewAndSubmit(env.COMMIT_ID, '--verified +1 --code-review +2 --submit', 'EEA/eea4_documentation')
                            }
                        }
                    }
                }
            }
            post {
                always {
                    script {
                        lock('resource-relabel') {
                            def manager = org.jenkins.plugins.lockableresources.LockableResourcesManager.get()
                            def resources =  manager.getResourcesWithLabel('doc-build', null)
                            def note = "eea-product-release-time-based-new-version - " +  env.BUILD_NUMBER
                            resources.each {
                                if (it.getNote() == note) {
                                    echo "Reserved resource found ${it}"
                                    echo "isReserved: ${it.isReserved()}"
                                    it.setNote('')
                                }
                            }
                            manager.recycle(resources)
                        }
                    }
                }
            }
        }

        stage('cdd version updater') {
            when {
                expression { env.MAIN_BRANCH == 'master' && !env.SKIP_VERSION_UPDATE_CDD.toBoolean() }
            }
            environment {
                CDD_UPGRADE_SCRIPT_PATH="product/source/pipeline_package/swdp-cdd/product/scripts/upgrade.sh"
                CDD_DEPLOY_SCRIPT_PATH="product/source/pipeline_package/swdp-cdd/product/scripts/deploy.sh"
            }
            stages {
                stage('cdd - Checkout') {
                    steps {
                        script {
                            gitcdd.checkout('master', 'cdd')
                        }
                    }
                }

                stage('cdd - Check if version is already merged') {
                    steps {
                        dir('cdd') {
                            script {
                                env.CDD_DEPLOY_PRODUCT_VERSION_ON_MASTER = sh(
                                    script: $/cat ${CDD_DEPLOY_SCRIPT_PATH} | grep -oP '^PRODUCT_VERSION="\K[^"]+'/$,
                                    returnStdout : true
                                )trim()
                                env.SKIP_VERSION_UPDATE_CDD = !checkVersion(env.CDD_DEPLOY_PRODUCT_VERSION_ON_MASTER, 'cdd PRODUCT_VERSION')
                                if (env.SKIP_VERSION_UPDATE_CDD.toBoolean()) {
                                    unstable("${STAGE_NAME}")
                                }
                            }
                        }
                    }
                }

                stage('cdd - Create and Push patchset') {
                    when {
                        expression { !env.SKIP_VERSION_UPDATE_CDD.toBoolean() }
                    }
                    steps {
                        dir('cdd') {
                            script {
                                if ( fileExists("${CDD_UPGRADE_SCRIPT_PATH}") ) {
                                    echo "Replace version in ${env.CDD_UPGRADE_SCRIPT_PATH} ..."
                                    sh """sed -i 's/^PRODUCT_VERSION=\"[^\"]*\"/PRODUCT_VERSION=\"${REVISION_NUMBER}\"/g' ${CDD_UPGRADE_SCRIPT_PATH}"""
                                }
                                echo "Replace version in ${env.CDD_DEPLOY_SCRIPT_PATH} ..."
                                sh """sed -i 's/^PRODUCT_VERSION=\"[^\"]*\"/PRODUCT_VERSION=\"${REVISION_NUMBER}\"/g' ${CDD_DEPLOY_SCRIPT_PATH}"""

                                echo "createPatchset ..."
                                if ( fileExists("${CDD_UPGRADE_SCRIPT_PATH}") ) {
                                    gitcdd.createPatchset("${env.CDD_DEPLOY_SCRIPT_PATH} ${env.CDD_UPGRADE_SCRIPT_PATH}", "${env.GIT_COMMENT}")
                                } else {
                                    gitcdd.createPatchset("${env.CDD_DEPLOY_SCRIPT_PATH}", "${env.GIT_COMMENT}")
                                }

                                env.COMMIT_ID= gitcdd.getCommitHashLong()
                                echo "COMMIT_ID: ${COMMIT_ID}"

                                env.GERRIT_REFSPEC_CDD = gitcdd.getCommitRefSpec(env.COMMIT_ID)
                                echo "GERRIT_REFSPEC_CDD: ${env.GERRIT_REFSPEC_CDD}"

                                currentBuild.description += "<br>GERRIT_REFSPEC cdd: " + getGerritLink(env.GERRIT_REFSPEC_CDD)
                            }
                        }
                    }
                }

                stage('cdd - merge') {
                    when {
                        expression { !env.SKIP_VERSION_UPDATE_CDD.toBoolean() }
                    }
                    steps {
                        dir('cdd') {
                            script {
                                gitcdd.gerritReview(env.COMMIT_ID, '--verified +1 --code-review +1 --message "skip-testing"', 'EEA/cdd')
                            }
                        }
                    }
                }
            }
        }

        stage('deployer version updater') {
            when {
                expression { env.MAIN_BRANCH == 'master' && !env.SKIP_VERSION_UPDATE_DEPLOYER.toBoolean() }
            }
            environment {
                DEPLOYER_UPGRADE_SCRIPT_PATH="product/source/pipeline_package/eea-deployer/product/scripts/upgrade.sh"
                DEPLOYER_DEPLOY_SCRIPT_PATH="product/source/pipeline_package/eea-deployer/product/scripts/deploy.sh"
            }
            stages {
                stage('deployer - Checkout') {
                    steps {
                        script {
                            gitdeployer.checkout('master', 'deployer')
                        }
                    }
                }

                stage('deployer - Check if version is already merged') {
                    steps {
                        dir('deployer') {
                            script {
                                env.DEPLOYER_DEPLOY_PRODUCT_VERSION_ON_MASTER = sh(
                                    script: $/cat ${DEPLOYER_DEPLOY_SCRIPT_PATH} | grep -oP '^PRODUCT_VERSION="\K[^"]+'/$,
                                    returnStdout : true
                                )trim()
                                env.SKIP_VERSION_UPDATE_DEPLOYER = !checkVersion(env.DEPLOYER_DEPLOY_PRODUCT_VERSION_ON_MASTER, 'deployer PRODUCT_VERSION')
                                if (env.SKIP_VERSION_UPDATE_DEPLOYER.toBoolean()) {
                                    unstable("${STAGE_NAME}")
                                }
                            }
                        }
                    }
                }

                stage('deployer - Create and Push patchset') {
                    when {
                        expression { !env.SKIP_VERSION_UPDATE_DEPLOYER.toBoolean() }
                    }
                    steps {
                        dir('deployer') {
                            script {
                                if ( fileExists("${DEPLOYER_UPGRADE_SCRIPT_PATH}") ) {
                                    echo "Replace version in ${env.DEPLOYER_UPGRADE_SCRIPT_PATH} ..."
                                    sh """sed -i 's/^PRODUCT_VERSION=\"[^\"]*\"/PRODUCT_VERSION=\"${REVISION_NUMBER}\"/g' ${DEPLOYER_UPGRADE_SCRIPT_PATH}"""
                                }
                                echo "Replace version in ${env.DEPLOYER_DEPLOY_SCRIPT_PATH} ..."
                                sh """sed -i 's/^PRODUCT_VERSION=\"[^\"]*\"/PRODUCT_VERSION=\"${REVISION_NUMBER}\"/g' ${DEPLOYER_DEPLOY_SCRIPT_PATH}"""

                                echo "createPatchset ..."
                                if ( fileExists("${DEPLOYER_UPGRADE_SCRIPT_PATH}") ) {
                                    gitdeployer.createPatchset("${env.DEPLOYER_DEPLOY_SCRIPT_PATH} ${env.DEPLOYER_UPGRADE_SCRIPT_PATH}", "${env.GIT_COMMENT}")
                                } else {
                                    gitdeployer.createPatchset("${env.DEPLOYER_DEPLOY_SCRIPT_PATH}", "${env.GIT_COMMENT}")
                                }

                                env.COMMIT_ID= gitdeployer.getCommitHashLong()
                                echo "COMMIT_ID: ${COMMIT_ID}"

                                env.GERRIT_REFSPEC_DEPLOYER = gitdeployer.getCommitRefSpec(env.COMMIT_ID)
                                echo "GERRIT_REFSPEC_DEPLOYER: ${env.GERRIT_REFSPEC_DEPLOYER}"

                                currentBuild.description += "<br>GERRIT_REFSPEC deployer: " + getGerritLink(env.GERRIT_REFSPEC_DEPLOYER)
                            }
                        }
                    }
                }

                stage('deployer - merge') {
                    when {
                        expression { !env.SKIP_VERSION_UPDATE_DEPLOYER.toBoolean() }
                    }
                    steps {
                        dir('deployer') {
                            script {
                                gitdeployer.gerritReview(env.COMMIT_ID, '--verified +1 --code-review +1 --message "skip-testing"', 'EEA/deployer')
                            }
                        }
                    }
                }

            }
        }


        stage('Archive artifact.properties') {
            when {
                expression { env.MAIN_BRANCH == 'master' }
            }
            steps {
                script {
                    sh "echo 'CHART_VERSION=${env.CHART_VERSION}' >> artifact.properties"
                    sh "echo 'REVISION_NUMBER=${env.REVISION_NUMBER}' >> artifact.properties"
                    sh "echo 'MAJOR_NUMBER=${env.MAJOR_NUMBER}' >> artifact.properties"
                    sh "echo 'MINOR_NUMBER=${env.MINOR_NUMBER}' >> artifact.properties"
                    sh "echo 'PATCH_NUMBER=${env.PATCH_NUMBER}' >> artifact.properties"
                    sh "echo 'BUILD_NUMBER=${env.BUILD_NUMBER}' >> artifact.properties"
                    sh "echo 'GERRIT_REFSPEC_CNINT=${env.GERRIT_REFSPEC_CNINT}' >> artifact.properties"
                    sh "echo 'GERRIT_REFSPEC_META=${env.GERRIT_REFSPEC_META}' >> artifact.properties"
                    sh "echo 'GERRIT_REFSPEC_DOCUMENTATION=${env.GERRIT_REFSPEC_DOCUMENTATION}' >> artifact.properties"
                    sh "echo 'GERRIT_REFSPEC_CDD=${env.GERRIT_REFSPEC_CDD}' >> artifact.properties"
                    archiveArtifacts 'artifact.properties'
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

def getVersionSeparator(String version, boolean raiseIfSeparatorNotExists=true) {
    if (version.contains('+')) {
        return '\\+'
    } else if (version.contains('-')) {
        return '-'
    } else {
        if (raiseIfSeparatorNotExists) {
            error("version has wrong input format: ${version}!")
        } else {
            return ''
        }
    }
}

def getDefaultTimeBasedVersion() {
    script {
        Date now = new Date();
        def year = now.format('yy');
        def week = now.format('w');
        def patchNumber = '0';
        def buildNumber = '1';
        return "${year}.${week}.${patchNumber}-${buildNumber}"
    }
}

def checkVersion(String versionFull, String labelInfo) {
    script {
        def revisionNumber = versionFull
        def buildNumber = ''
        def versionSeparator = getVersionSeparator(versionFull, false)
        if (versionSeparator) {
            revisionNumber = versionFull.split(versionSeparator)[0]
            buildNumber = versionFull.split(versionSeparator)[1]
        }
        def majorNumber = revisionNumber.split("\\.")[0]
        def minorNumber = revisionNumber.split("\\.")[1]
        def patchNumber = revisionNumber.split("\\.")[2]

        echo "Master state of the ${labelInfo}: ${versionFull}\n - MAJOR_NUMBER: ${majorNumber}\n - MINOR_NUMBER: ${minorNumber}\n - PATCH_NUMBER: ${patchNumber}\n - BUILD_NUMBER: ${buildNumber}\n - REVISION_NUMBER: ${revisionNumber}"
        normalizedVersionOld = String.format('%03d', majorNumber.toInteger()) + String.format('%03d', minorNumber.toInteger()) + String.format('%03d', patchNumber.toInteger())
        normalizedVersionNew = String.format('%03d', env.MAJOR_NUMBER.toInteger()) + String.format('%03d', env.MINOR_NUMBER.toInteger()) + String.format('%03d', env.PATCH_NUMBER.toInteger())

        if (normalizedVersionOld == normalizedVersionNew) {
            echo "Master state of the ${labelInfo} already contains the same version:\n - CHART_VERSION: ${env.CHART_VERSION}"
            return false
        } else if (normalizedVersionOld.toInteger() > normalizedVersionNew.toInteger()) {
            echo "Master state of the ${labelInfo} version (${revisionNumber}) is greater then new input version (${env.REVISION_NUMBER}) --> skipping version update\n - CHART_VERSION: ${env.CHART_VERSION}"
            return false
        }
        return true
    }
}
