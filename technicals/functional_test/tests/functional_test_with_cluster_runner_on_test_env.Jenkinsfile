@Library('ci_shared_library_eea4') _

import groovy.transform.Field
import com.ericsson.eea4.ci.GlobalVars
import com.ericsson.eea4.ci.Notifications

@Field def vars = new GlobalVars()
@Field def notify = new Notifications(this, 'eea-seliius27102@ericsson.com')

@Field def DEFAULT_BASELINE_INSTALL_MODE_IS_HELM = 'HELM'
@Field def DEFAULT_BASELINE_INSTALL_MODE_IS_HELM_AND_CMA = 'HELM_AND_CMA'

def testClusterLabel
def test_job

pipeline {
    options {
        skipDefaultCheckout()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(daysToKeepStr:'14', artifactDaysToKeepStr: '7'))
    }

    agent {
        node {
            label 'productci'
        }
    }

    parameters {
        string(name: 'TEST_CLUSTER', description: 'cluster credential locked for the test eg.: kubeconfig-seliics01600')
        string(name: 'TEST_JOB_NAME', description: 'name of the job to run')
        string(name: 'CHART_NAME', description: 'Chart name e.g.: eric-ms-b', defaultValue: '')
        string(name: 'CHART_REPO', description: 'Chart repo e.g.: https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm', defaultValue: '')
        string(name: 'CHART_VERSION', description: 'Chart version e.g.: 1.0.0-1', defaultValue: '')
        string(name: 'INT_CHART_NAME', description: 'Chart name e.g.: eric-ms-b', defaultValue: '')
        string(name: 'INT_CHART_REPO', description: 'Chart repo e.g.: https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm', defaultValue: '')
        string(name: 'INT_CHART_VERSION', description: 'Chart version e.g.: 1.0.0-1', defaultValue: '')
        string(name: 'GERRIT_REFSPEC',  description: 'Gerrit Refspec of the integration chart git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'SPINNAKER_ID', description: "The spinnaker execution's id", defaultValue: 'test')
        string(name: 'DIMTOOL_OUTPUT_REPO_URL', description: "The url of the artifactory", defaultValue: 'https://arm.seli.gic.ericsson.se')
        string(name: 'DIMTOOL_OUTPUT_REPO', description: "Repo of the chart eg. proj-eea-reports-generic-local/dimtool/prod_ci_artifacts/", defaultValue: 'proj-eea-reports-generic-local/dimtool/prod_ci_artifacts/')
        string(name: 'DIMTOOL_OUTPUT_NAME', description: 'Chart name e.g.: eea-application-staging-baseline-prepare-12695/eea4-dimensioning-tool-output.zip', defaultValue: '')
        string(name: 'HELM_AND_CMA_VALIDATION_MODE', description: "Use HELM values or HELM values and CMA configurations.", defaultValue: 'HELM_AND_CMA')
        choice(name: 'BUILD_RESULT_WHEN_CMA_HEALTH_CHECK_FAILED', choices: ['SUCCESS','FAILURE'], description: 'build result when the CMA health check faild')
    }

    environment {
        EXCPECTED_RESULT = 'SUCCESS'
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

        stage ('Check cluster labels') {
            steps {
                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                    script {
                        def prodCiClusterList = GlobalVars.Clusters.values().findAll{ it.owner == "product_ci" }
                        def clustersWithLabelIssue = []
                        prodCiClusterList.each {
                            echo ("Check current label for cluster: " + it.resource + " ...")
                            def currentClusterLabel = getLockableResourceLabels(it.resource)
                            if (currentClusterLabel != vars.resourceLabelCommon) {
                                echo (it.resource + " cluster current label is: " + currentClusterLabel + ", BUT should be: " + vars.resourceLabelCommon + ", changing...")
                                clustersWithLabelIssue.add(it.resource)
                                relabelClusterResource(it.resource)
                            }
                        }
                        if (! clustersWithLabelIssue.isEmpty())
                            sendEmailNotify("cluster label mismatch in functional test on cluster " + clustersWithLabelIssue + ", please check")
                    }
                }
            }
            post {
                always {
                    script {
                        archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                    }
                }
            }
        }

        stage ('init'){
            steps {
                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                    script {
                        def manager = org.jenkins.plugins.lockableresources.LockableResourcesManager.get()

                        // manage bob-ci resources
                        def resources =  manager.getResourcesWithLabel("${vars.resourceLabelCommon}", null)
                        resources.each {
                            echo("Checking ${it.getName()} ...")
                            if ("${it.getName()}" != "${TEST_CLUSTER}" ) {
                                echo("- exec setReservedBy - test-runner")
                                it.setReservedBy('test-runner')
                            }
                            else {
                                if (it.isReserved()) {
                                    echo("- isReserved: true -> exec unReserve")
                                    it.unReserve()
                                } else {
                                    echo("- isReserved: false -> nothing to do")
                                }
                            }
                        }
                        manager.save()
                   }
                }
            }
            post {
                always {
                    script {
                        archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                    }
                }
            }
        }

        stage('trigger job'){
            steps{
                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                    script {
                        def test_parameters = [
                            stringParam(name: 'CHART_NAME', value: "${params.CHART_NAME}"),
                            stringParam(name: 'CHART_REPO', value: "${params.CHART_REPO}"),
                            stringParam(name: 'CHART_VERSION', value: "${params.CHART_VERSION}"),
                            stringParam(name: 'INT_CHART_NAME', value: "${params.INT_CHART_NAME}"),
                            stringParam(name: 'INT_CHART_REPO', value: "${params.INT_CHART_REPO}"),
                            stringParam(name: 'INT_CHART_VERSION', value: "${params.INT_CHART_VERSION}"),
                            stringParam(name: 'GERRIT_REFSPEC', value: "${params.GERRIT_REFSPEC}"),
                            stringParam(name: 'SPINNAKER_TRIGGER_URL', value: "${params.SPINNAKER_TRIGGER_URL}"),
                            stringParam(name: 'SPINNAKER_ID', value: "ci_code_test"),
                            stringParam(name: 'PIPELINE_NAME', value: "eea-product-ci-code-loop-for-test-jenkins"),
                            booleanParam(name: 'SKIP_COLLECT_LOG', value: true),
                            booleanParam(name: 'SKIP_CLEANUP', value: true),
                            stringParam(name: 'DIMTOOL_OUTPUT_REPO_URL', value: "${params.DIMTOOL_OUTPUT_REPO_URL}"),
                            stringParam(name: 'DIMTOOL_OUTPUT_REPO', value: "${params.DIMTOOL_OUTPUT_REPO}"),
                            stringParam(name: 'DIMTOOL_OUTPUT_NAME', value: "${params.DIMTOOL_OUTPUT_NAME}"),
                            stringParam(name: 'HELM_AND_CMA_VALIDATION_MODE', value: "${params.HELM_AND_CMA_VALIDATION_MODE}"),
                            stringParam(name: 'BUILD_RESULT_WHEN_CMA_HEALTH_CHECK_FAILED', value: "${params.BUILD_RESULT_WHEN_CMA_HEALTH_CHECK_FAILED}"),
                        ]
                        if (TEST_JOB_NAME.contains('cluster-cleanup')) {
                            test_parameters = [
                                stringParam(name: 'CLUSTER_NAME', value: "${params.TEST_CLUSTER}")
                            ]
                        }
                        if (TEST_JOB_NAME.contains('cluster-logcollector')) {
                            test_parameters = [
                                stringParam(name: 'CLUSTER_NAME', value: "${params.TEST_CLUSTER}"),
                                stringParam(name: 'SERVICE_NAME', value: "${params.CHART_NAME}"),
                                booleanParam(name: 'CLUSTER_CLEANUP', value: false)
                            ]
                        }

                        test_job = build job: "${TEST_JOB_NAME}",
                            parameters: test_parameters, wait: true, propagate: false

                        def testJobResult = test_job.getResult()
                        if (testJobResult != 'SUCCESS') {
                            error("Build of '${TEST_JOB_NAME}' failed with result: ${testJobResult}")
                        }
                        def TEST_JOB_ABSOLUTE_URL =  test_job.getAbsoluteUrl()
                        sh "echo 'TEST_JOB_URL=${TEST_JOB_ABSOLUTE_URL}' > test_job_run_info.properties"
                        archiveArtifacts 'test_job_run_info.properties'
                    }
                }
            }
            post {
                always {
                    script {
                        echo("trigger job post.always")
                        echo("Check current label for cluster: ${params.TEST_CLUSTER} ...")
                        testClusterLabel = getLockableResourceLabels("${params.TEST_CLUSTER}")
                        echo("${params.TEST_CLUSTER} cluster current label is: ${testClusterLabel}")
                        archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                    }
                }
                success {
                    script {
                        echo("trigger job post.success")
                        if ( "${TEST_JOB_NAME}" == "eea-application-staging-product-baseline-install" ) {
                            echo("Check current label for cluster: ${params.TEST_CLUSTER} ...")
                            testClusterLabel = getLockableResourceLabels("${params.TEST_CLUSTER}")
                            if ( testClusterLabel != vars.resourceLabelUpgrade ) {
                                error "After success product-baseline-install, ${params.TEST_CLUSTER} cluster current label is: ${testClusterLabel}, BUT it should be: ${vars.resourceLabelUpgrade}!"
                            }
                        }
                        if ( "${TEST_JOB_NAME}" == "cluster-logcollector" && !params.CHART_NAME ) {
                            echo "Validate certs lof exist: ${params.TEST_CLUSTER} ..."
                            env.TEST_JOB_BUILD_NUMBER = test_job.number
                            try {
                                copyArtifacts filter: 'collected-services-cert*', fingerprintArtifacts: true, projectName: 'cluster-logcollector', selector: specific(env.TEST_JOB_BUILD_NUMBER)
                                def collected_services_cert_files = findFiles glob: '**/collected-services-cert*'
                                if ( collected_services_cert_files.length > 0  ) {
                                    echo "Services cert archive exist!"
                                } else {
                                    echo "Services cert archive doesn't exist"
                                }
                            }
                            catch (err) {
                                echo("Artifact could not be copied: " + err)
                            }
                        }
                        archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                    }
                }
                failure {
                    script {
                        echo("trigger job post.failure")
                        echo("Check current label for cluster: ${params.TEST_CLUSTER} ...")
                        testClusterLabel = getLockableResourceLabels("${params.TEST_CLUSTER}")
                        archiveArtifacts artifacts: "stage_${STAGE_NAME}.log".replaceAll(' ', '_'), allowEmptyArchive: true
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                echo("post.always - currentBuild.result: ${currentBuild.result}")
                echo("Check current label for cluster: ${params.TEST_CLUSTER} ...")
                testClusterLabel = getLockableResourceLabels("${params.TEST_CLUSTER}")
                if ( testClusterLabel == vars.resourceLabelCommon ) {
                    echo("${params.TEST_CLUSTER} cluster current label is: ${testClusterLabel}")
                } else {
                    echo "After testing, ${params.TEST_CLUSTER} cluster current label is: ${testClusterLabel}, BUT it should be: ${vars.resourceLabelCommon}!"
                    relabelClusterResource(params.TEST_CLUSTER)
                }

                // reset locks
                def manager = org.jenkins.plugins.lockableresources.LockableResourcesManager.get()

                // manage bob-ci resources
                def resources =  manager.getResourcesWithLabel("${vars.resourceLabelCommon}", null)
                resources.each {
                    echo("Checking ${it.getName()} ...")
                    if (it.isLocked() || it.isReserved()) {
                        echo("- isLocked or isReserved -> exec reset")
                        it.reset()
                    }
                }
                manager.save()
            }
        }
        cleanup {
           cleanWs()
        }
    }
}

void sendEmailNotify(def bodyText) {
    echo("Send warning notification ...")
    def recipient = '517d5a14.ericsson.onmicrosoft.com@emea.teams.ms' // Driver channel - EEA4 CI
    def emailSubject = "${env.JOB_NAME} (${env.BUILD_NUMBER}) cluster label mismatch in functional test"
    def emailBody = "${env.BUILD_URL} " + bodyText
    notify.sendMail (emailSubject, emailBody, recipient, "text/html")
}

void relabelClusterResource (def clusterName) {
    echo("Relabel cluster ... \n - cluster: " + clusterName + "\n - new label: " + vars.resourceLabelCommon)
    build job: "lockable-resource-label-change", parameters: [
        booleanParam(name: 'DRY_RUN', value: false),
        stringParam(name: 'DESIRED_CLUSTER_LABEL', value: vars.resourceLabelCommon),
        stringParam(name: 'CLUSTER_NAME', value: clusterName),
        stringParam(name: 'SPINNAKER_ID', value: params.SPINNAKER_ID),
        booleanParam(name: 'RESOURCE_RECYCLE', value: true)
    ], wait: true
}
