@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.Artifactory
import groovy.transform.Field

@Field def git_meta = new GitScm(this, 'EEA/project-meta-baseline')
@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def arm = new Artifactory(this, "https://arm.seli.gic.ericsson.se/", "API_TOKEN_EEA")

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
        string(name: 'CHART_VERSION', description: 'eric-eea-int-helm-chart version e.g.: 1.0.0-1\nThe job will calculate from this version the metabaseline version', defaultValue: '')
        string(name: 'GIT_TAG_STRING', description: 'PRA', defaultValue: 'PRA release')
    }

    environment {
        HELM_REPOPATH_CI_INTERNAL='proj-eea-ci-internal-helm-local'
        HELM_REPOPATH_DROP='proj-eea-drop-helm-local'
        HELM_REPOPATH_RELEASED='proj-eea-released-helm-local'
        INT_CHART_NAME='eric-eea-int-helm-chart'
        CHART_NAME='eric-eea-ci-meta-helm-chart'
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

        stage('Checkout') {
            steps {
                script {
                    git_meta.checkout('master', '')
                }
            }
        }

        stage('Prepare') {
            steps {
                checkoutGitSubmodules()
            }
        }

        stage('Generate PRA and NONPRA versions') {
            steps {
                script {
                    env.CHART_VERSION_PRA = sh(script: "echo ${env.CHART_VERSION} | sed 's/-/+/g'", returnStdout: true).trim()
                    env.CHART_VERSION_NONPRA = sh(script: "echo ${env.CHART_VERSION} | sed 's/+/-/g'", returnStdout: true).trim()
                    echo "env.CHART_VERSION (original): ${env.CHART_VERSION}"
                    echo "env.CHART_VERSION_PRA: ${env.CHART_VERSION_PRA}"
                    echo "env.CHART_VERSION_NONPRA: ${env.CHART_VERSION_NONPRA}"
                }
            }
        }

        stage('Generate and Upload Helm Chart NONPRA') {
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
                    sh 'bob/bob -r ruleset2.0_product_release.yaml publish-released-meta'
                }
            }
        }

        stage('Upload Helm Chart PRA') {
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
                    sh 'bob/bob -r ruleset2.0_product_release.yaml publish-released-meta:generate-released-version publish-released-meta:helmchart-file-name'
                    script {
                        def releasedVersion = readFile(".bob/var.released-version").trim()
                        echo "releasedVersion: |${releasedVersion}|"
                        def helmChartPackage="${env.CHART_NAME}/${env.CHART_NAME}-${releasedVersion}.tgz"
                        echo "helmChartPackage: |${helmChartPackage}|"
                        arm.setUrl("https://arm.seli.gic.ericsson.se/", "$API_TOKEN_EEA")
                        if ( arm.checkIfArtifactExists("${env.HELM_REPOPATH_DROP}", "${helmChartPackage}") ) {
                            echo "PRA version already exists in drop repo --> copy helm chart package from drop repo to released repo"
                            arm.copyArtifact("${helmChartPackage}", "${env.HELM_REPOPATH_DROP}", "${helmChartPackage}", "${env.HELM_REPOPATH_RELEASED}")
                        } else {
                            echo "PRA version not exists in drop repo repo --> generate integration helm chart"
                            gitcnint.archiveFile('EEA/cnint', 'HEAD repositories.yaml.template')
                            sh 'bob/bob -r ruleset2.0_product_release.yaml publish-released-meta'
                        }
                    }
                }
            }
        }

        stage('Create PRA Git Tag') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')])
                {
                    // Create git tag 'v<released version>'
                    sh './bob/bob -r ruleset2.0_product_release.yaml create-pra-git-tag'
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
