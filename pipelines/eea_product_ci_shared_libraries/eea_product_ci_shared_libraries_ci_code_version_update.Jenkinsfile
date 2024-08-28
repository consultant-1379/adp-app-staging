@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def git_shared_lib = new GitScm(this, 'EEA/ci_shared_libraries')
@Field def git_adp = new GitScm(this, 'EEA/adp-app-staging')

pipeline {
    options {
        disableConcurrentBuilds()
        skipDefaultCheckout()
        buildDiscarder(logRotator(daysToKeepStr: '14', artifactDaysToKeepStr: '7'))
    }
    agent {
        node {
            label 'productci'
        }
    }
    parameters {
        string(name: 'CI_LIB_VERSION', description: 'The new CI Shared Libraries Version')
    }
    environment {
        CHART_YAML_PATH="${WORKSPACE}/adp-app-staging/eric-eea-ci-code-helm-chart/Chart.yaml"
        // WA to avoid helm error - until we decide how eric-eea-ci-code-helm-chart/ci_shared_libraries/Chart.yaml will be handled
        SUB_CHART_YAML_PATH="${WORKSPACE}/adp-app-staging/eric-eea-ci-code-helm-chart/charts/ci_shared_libraries/Chart.yaml"
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
        stage('Checkout - adp-app-staging') {
           steps {
                script {
                    git_adp.checkout(env.MAIN_BRANCH, 'adp-app-staging')
                }
            }
        }
        stage('Update Chart.yaml') {
            steps {
                dir('adp-app-staging') {
                    script {
                        log.infoMsg "Updating ${env.CHART_YAML_PATH}"
                        def data = readYaml file: "${env.CHART_YAML_PATH}"
                        data.dependencies.each { dependency ->
                            if (dependency.name == 'ci_shared_libraries') {
                                dependency.version = "${params.CI_LIB_VERSION}"
                            }
                        }
                        writeYaml file: "${env.CHART_YAML_PATH}", data: data, overwrite: true
                        // WA to avoid helm error - until we decide how eric-eea-ci-code-helm-chart/ci_shared_libraries/Chart.yaml will be handled
                        log.infoMsg "Updating ${env.SUB_CHART_YAML_PATH}"
                        data = readYaml file: "${env.SUB_CHART_YAML_PATH}"
                        data.version = "${params.CI_LIB_VERSION}"
                        writeYaml file: "${env.SUB_CHART_YAML_PATH}", data: data, overwrite: true
                    }
                }
            }
        }
        stage('Prepering a new commit and push changes') {
            steps {
                dir('adp-app-staging') {
                    script {
                        git_adp.createPatchset(".", "Updating ci_shared_libraries.version in charts")
                        def git_id = git_adp.getCommitHashLong()
                        env.GERRIT_REFSPEC = git_adp.getCommitRefSpec(git_id)
                        currentBuild.description = "Gerrit refspec: " + getGerritLink(env.GERRIT_REFSPEC)
                    }
                }
            }
        }
        stage('Archive artifact.properties') {
            steps {
                script {
                    sh """
                    cat > artifact.properties << EOF
GERRIT_REFSPEC=${env.GERRIT_REFSPEC}
CI_LIB_VERSION=${params.CI_LIB_VERSION}
EOF
"""
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
