@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import com.ericsson.eea4.ci.Notifications
import com.ericsson.eea4.ci.CommonUtils
import com.ericsson.eea4.ci.GlobalVars
import com.ericsson.eea4.ci.Artifactory
import com.ericsson.eea4.ci.ClusterLockUtils

@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def vars = new GlobalVars()
@Field def notif = new Notifications(this)
@Field def arm = new Artifactory(this, "https://arm.seli.gic.ericsson.se/", "API_TOKEN_EEA")
def ceph_fail = false
def ceph_fail_require_admin = false
def cephFailuresWhichRequireAdminControl = ['osds down'] // cases of ceph issues that require administrator control

pipeline{

    options {
        buildDiscarder(logRotator(daysToKeepStr: "7"))
        skipDefaultCheckout()
    }

    agent {
        node {
            label "productci"
        }
    }

    environment {
        PRODUCT_NAMESPACE = "eric-eea-ns"
        SPOTFIRE_NAMESPACE = "spotfire-platform"
    }
    parameters {
        string(name: 'CLUSTER_NAME', description: "Cluster name to cleanup.")
        string(name: 'CNINT_GERRIT_REFSPEC', description: 'cnint Gerrit Refspec of the integration chart git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'ADP_APP_STAGING_GERRIT_REFSPEC', description: 'adp-app-staging Gerrit Refspec of the integration chart git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'DESIRED_CLUSTER_LABEL', description: "The desired new resource label after successful run", defaultValue: "${vars.resourceLabelCommon}")
        booleanParam(name: 'LOCAL_REGISTRY_CLEANUP', description: 'Perform local registry cleanup', defaultValue: true)
        booleanParam(name: 'SPOTFIRE_CLEANUP', description: 'The option for the spotfire cleanup', defaultValue: true)
        string(name: 'LAST_LABEL_SET', description: 'The last cluster lock label set by the automation. Leave empty for manual start')
        booleanParam(name: 'PULL_IMAGE_WITH_CRICTL', description: "Pull image to the cluster nodes with crictl", defaultValue: true)
        string(name: 'SPINNAKER_TRIGGER_URL', description: 'Spinnaker pipeline triggering url', defaultValue: '')
        string(name: 'SPINNAKER_ID', description: "The spinnaker execution's id", defaultValue: '')
        string(name: 'PIPELINE_NAME', description: "The spinnaker pipeline name", defaultValue: '')
    }

    stages {
        stage("Params DryRun check") {
            when {
                expression { params.DRY_RUN == true }
            }
            steps {
                script {
                    dryRun()
                }
            }
        }
        stage('Params check') {
            steps {
                script {
                    env.CLUSTER=""
                    if ( !params.CLUSTER_NAME ) {
                        currentBuild.result = 'ABORTED'
                        error("CLUSTER_NAME must be specified")
                    }
                }
            }
        }
        stage('clean workspace') {
            steps {
                script {
                    cleanWs()
                }
            }
        }
        stage('cnint Checkout') {
            steps {
                script {
                    // CNINT_GERRIT_REFSPEC param was added to checkout new docker images from exact commit to check if they work properly
                    if ( params.CNINT_GERRIT_REFSPEC != '' ) {
                        gitcnint.checkoutRefSpec("${CNINT_GERRIT_REFSPEC}", "FETCH_HEAD", "")
                    }else {
                        gitcnint.checkout("master", "")
                    }
                }
            }
        }
        stage('Init bob submodule') {
            steps {
                checkoutGitSubmodules()
            }
        }

        stage('adp-app-staging Checkout') {
            steps{
                script {
                    dir('adp-app-staging') {
                        if ( params.ADP_APP_STAGING_GERRIT_REFSPEC != '' ) {
                            gitadp.checkoutRefSpec("${ADP_APP_STAGING_GERRIT_REFSPEC}", "FETCH_HEAD", "")
                        }else {
                            gitadp.checkout("master", "")
                        }
                        sh (
                            script: """
                            cp ${WORKSPACE}/adp-app-staging/technicals/pythonscripts/k8s_cleanup.py ${WORKSPACE}/adp-app-staging/
                            cp ${WORKSPACE}/adp-app-staging/technicals/pythonscripts/helm_base.py ${WORKSPACE}/adp-app-staging/
                            cp ${WORKSPACE}/adp-app-staging/technicals/shellscripts/collect_images_to_cleanup.sh ${WORKSPACE}/adp-app-staging/
                            cp ${WORKSPACE}/adp-app-staging/technicals/shellscripts/k8s_cleanup.sh ${WORKSPACE}/adp-app-staging/
                            """
                        )
                    }
                }
            }
        }
        stage('Resource locking - cluster cleanup') {
            stages {
                stage('Wait for lock') {
                    steps {
                        script {
                            sendLockEventToDashboard (transition: "wait-for-lock")
                        }
                    }
                }
                stage('Lock') {
                    options {
                        lock resource: "${params.CLUSTER_NAME}", quantity: 1, variable: 'system'
                    }
                    stages {
                        // To use cluster name in POST stages
                        stage('Set env.CLUSTER') {
                            steps {
                                script {
                                    env.CLUSTER = env.system
                                    env.LASTLABEL = params.LAST_LABEL_SET
                                    sendLockEventToDashboard (transition : "lock", cluster: env.CLUSTER)
                                }
                            }
                        }

                        stage('Check Ceph status') {
                            steps {
                                tee("stage_${STAGE_NAME}.log".replaceAll(' ', '_')) {
                                    script {
                                        catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                                            // get ceph status
                                            env.ROOK_CEPH_HEALTH_STATUS = ""
                                            try {
                                                env.ROOK_CEPH_HEALTH_STATUS = getRookCephStatusFromCluster(env.CLUSTER_NAME, 'rook_ceph_status_before_cleanup.log')
                                                // filter out the status part from the output
                                                if (env.ROOK_CEPH_HEALTH_STATUS) {
                                                    env.ROOK_CEPH_HEALTH_STATUS = env.ROOK_CEPH_HEALTH_STATUS.split('\n').findAll{ it =~ /^\s/ }.join('\n')
                                                }
                                            }
                                            catch (err) {
                                                error "getRookCephStatusFromCluster FAILED.\nERROR: ${err}"
                                            }
                                            echo "env.ROOK_CEPH_HEALTH_STATUS:\n${env.ROOK_CEPH_HEALTH_STATUS}"

                                            // validate ceph status
                                            failureMessageMajor = ""
                                            failureMessageMinor = ""
                                            try {
                                                validationResult = validateRookCephStatus("${env.ROOK_CEPH_HEALTH_STATUS}")
                                                if (validationResult) {
                                                    def failureListMajor = validationResult.get('failureListMajor')
                                                    def failureListMinor = validationResult.get('failureListMinor')
                                                    if (failureListMajor) {
                                                        ceph_fail = true
                                                        ceph_fail_require_admin = cephFailuresWhichRequireAdminControl.any { cephFailure ->
                                                            failureListMajor.toString().contains(cephFailure)
                                                        }
                                                        failureMessageMajor = "Critical/Major rook ceph health problem(s) detected on cluster: ${env.CLUSTER_NAME}"
                                                        failureListMajor.eachWithIndex { failureMajor, idx ->
                                                            failureMessageMajor += "\n - ${failureListMajor.size()}/${idx+1}) ${failureMajor}"
                                                        }
                                                        echo "${failureMessageMajor}"
                                                    }
                                                    if (failureListMinor) {
                                                        failureMessageMinor = "Minor rook ceph health problem(s) detected on cluster: ${env.CLUSTER_NAME}"
                                                        failureListMinor.eachWithIndex { failureMinor, idx ->
                                                            failureMessageMinor += "\n - ${failureListMinor.size()}/${idx+1}) ${failureMinor}"
                                                        }
                                                        echo "${failureMessageMinor}"
                                                    }
                                                } else {
                                                    echo "No major/minor rook ceph health problem detected on cluster: ${env.CLUSTER_NAME}"
                                                }
                                            }
                                            catch (err) {
                                                error "validateRookCephStatus FAILED.\nERROR: ${err}"
                                            }
                                            if (ceph_fail || ceph_fail_require_admin) {
                                                notif.sendMail(
                                                  "${env.JOB_NAME} (${env.BUILD_NUMBER}) cluster-cleanup skipped because rook ceph health problem(s) detected on cluster ${env.CLUSTER_NAME}",
                                                  "rook ceph health problem(s) detected on cluster ${env.CLUSTER_NAME}\n${env.BUILD_URL}\n\n${failureMessageMajor}\n\n${env.ROOK_CEPH_HEALTH_STATUS}",
                                                  "2b661627.ericsson.onmicrosoft.com@emea.teams.ms"
                                                )
                                            }
                                        }
                                        // outside of catchError
                                        if (ceph_fail || ceph_fail_require_admin) {
                                            error "rook ceph health problem(s) detected on cluster ${env.CLUSTER_NAME}\n\n${failureMessageMajor}\n\n${env.ROOK_CEPH_HEALTH_STATUS}"
                                        }
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

                        stage('k8s cleanup') {
                            steps {
                                catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                                    withCredentials([usernamePassword(credentialsId: 'arm-seli-eeaprodart-token', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                                                usernamePassword(credentialsId: 'arm-sero-eeaprodart-token', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
                                                usernamePassword(credentialsId: 'arm-seli-eeaprodart-token', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
                                                file(credentialsId: env.system, variable: 'KUBECONFIG')]) {
                                        sh './bob/bob init'
                                        timeout(time: 15, unit: 'MINUTES') {
                                            script {
                                                currentBuild.description = "Locked cluster: $system"
                                                try {
                                                    sh './bob/bob -r bob-rulesets/cleanup_ruleset.yaml k8s-cleanup:copy-cleanup-sh k8s-cleanup:run-cleanup-sh-to-eea-namespace > cleanup_eea_namespace.log'
                                                }
                                                catch (err) {
                                                    notif.sendMail("${env.JOB_NAME} (${env.BUILD_NUMBER}) cleanup failed","${env.BUILD_URL} cleanup failed to finish on cluster ${env.system}","2b661627.ericsson.onmicrosoft.com@emea.teams.ms")
                                                    withEnv(["NAMESPACE=eric-eea-ns",
                                                             "ADP_APP_STAGING_DIR=${WORKSPACE}/adp-app-staging"]) {
                                                        try {
                                                            sh "./bob/bob get-pods -r ${WORKSPACE}/adp-app-staging/rulesets/describepod.yaml -q > eea_cleanup_failed_stuck_pods_${env.NAMESPACE}.txt 2>&1"
                                                        }
                                                        catch (eea_cleanup_failed_stuck_pods_err) {
                                                            echo("During ${env.NAMESPACE} namespace clean-up failed check pods caught ERROR:\n${eea_cleanup_failed_stuck_pods_err}")
                                                        } finally {
                                                            archiveArtifacts artifacts: "eea_cleanup_failed_stuck_pods_${env.NAMESPACE}.txt", allowEmptyArchive: true
                                                        }
                                                    }
                                                    // collect logs again for cleanup errors
                                                    timeout(time: 30, unit: 'MINUTES') {
                                                        sh './bob/bob -r bob-rulesets/log_collecting.yaml collect-logs-from-cluster > log_collector_cleanup.log'
                                                    }
                                                    error("Caught k8s-cleanup ERROR: ${err}")
                                                } finally {
                                                    sh 'sudo chown -R eceabuild:eceabuild *'
                                                }
                                            }
                                        }
                                    }
                                }
                                archiveArtifacts artifacts: "cleanup_eea_namespace.log", allowEmptyArchive: true
                                archiveArtifacts artifacts: "log_collector_cleanup.log", allowEmptyArchive: true
                                archiveArtifacts artifacts: "logs_${env.PRODUCT_NAMESPACE}*", allowEmptyArchive: true
                                archiveArtifacts artifacts: "stop_stream_aggregators.log", allowEmptyArchive: true


                                catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                                    withCredentials([usernamePassword(credentialsId: 'arm-seli-eeaprodart-token', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                                                usernamePassword(credentialsId: 'arm-sero-eeaprodart-token', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
                                                usernamePassword(credentialsId: 'arm-seli-eeaprodart-token', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
                                                file(credentialsId: env.system, variable: 'KUBECONFIG')]) {
                                        sh './bob/bob init'
                                        script {
                                            currentBuild.description = "Locked cluster: $system"
                                            try {
                                                sh './bob/bob -r bob-rulesets/cleanup_ruleset.yaml k8s-cleanup:copy-cleanup-py k8s-cleanup:run-cleanup-py-to-utf-namespace > cleanup_utf_namespace.log'
                                            }
                                            catch (err) {
                                                notif.sendMail("${env.JOB_NAME} (${env.BUILD_NUMBER}) utf cleanup failed","${env.BUILD_URL} cleanup of utf namespace failed to finish on cluster ${env.system}","2b661627.ericsson.onmicrosoft.com@emea.teams.ms")
                                                // collect logs again for cleanup errors
                                                error("Caught k8s-cleanup ERROR: ${err}")
                                            }
                                        }
                                    }
                                }
                                archiveArtifacts artifacts: "cleanup_utf_namespace.log", allowEmptyArchive: true
                            }
                        }
                        stage('crd cleanup') {
                            steps {
                                 // todo(): WA for EEAEPP-75459, set  buildResult: 'FAILURE' when crd-cleanup fixed
                                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                                    withCredentials([usernamePassword(credentialsId: 'arm-seli-eeaprodart-token', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                                                usernamePassword(credentialsId: 'arm-sero-eeaprodart-token', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
                                                usernamePassword(credentialsId: 'arm-seli-eeaprodart-token', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
                                                file(credentialsId: env.system, variable: 'KUBECONFIG')]) {
                                        script {
                                            try {
                                                sh './bob/bob -r bob-rulesets/cleanup_ruleset.yaml crd-cleanup > crd-cleanup.log'
                                            }
                                            catch (err) {
                                                notif.sendMail("${env.JOB_NAME} (${env.BUILD_NUMBER}) CRD cleanup failed","${env.BUILD_URL} CRD cleanup failed to finish on cluster ${env.system}","2b661627.ericsson.onmicrosoft.com@emea.teams.ms")
                                                timeout(time: 30, unit: 'MINUTES') {
                                                    sh './bob/bob collect-crd-logs-from-cluster > crd_log_collector_cleanup.log'
                                                }
                                                archiveArtifacts artifacts: "crd_log_collector_cleanup.log", allowEmptyArchive: true
                                                archiveArtifacts artifacts: "logs_eric-eea-ns*", allowEmptyArchive: true
                                                error("Caught crd-cleanup ERROR: ${err}")
                                            }
                                        }
                                    }
                                }
                                archiveArtifacts artifacts: "crd-cleanup.log", allowEmptyArchive: true
                            }
                        }

                        stage('Delete product-baseline-install configmap') {
                            steps {
                                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                                    withCredentials([usernamePassword(credentialsId: 'arm-seli-eeaprodart-token', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                                                usernamePassword(credentialsId: 'arm-sero-eeaprodart-token', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
                                                usernamePassword(credentialsId: 'arm-seli-eeaprodart-token', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
                                                file(credentialsId: env.system, variable: 'KUBECONFIG')]) {
                                        script {
                                            withEnv(["NAME_OF_CONFIGMAP='product-baseline-install'"]) {
                                                try {
                                                    sh './bob/bob -r bob-rulesets/technical_ruleset.yaml delete-configmap > delete-product-baseline-install-configmap.log'
                                                }
                                                catch (err) {
                                                    error("Caught delete-configmap ERROR: ${err}")
                                                }
                                            }
                                            withEnv(["NAME_OF_CONFIGMAP='product-baseline-install-perf-data'"]) {
                                                try {
                                                    sh './bob/bob -r bob-rulesets/technical_ruleset.yaml delete-configmap > delete-product-baseline-install-perf-data-configmap.log'
                                                }
                                                catch (err) {
                                                    error("Caught delete-configmap ERROR: ${err}")
                                                }
                                            }
                                        }
                                    }
                                }
                                archiveArtifacts artifacts: "delete-product-baseline-install-configmap.log", allowEmptyArchive: true
                                archiveArtifacts artifacts: "delete-product-baseline-install-perf-data-configmap.log", allowEmptyArchive: true
                            }
                        }

                        stage('Delete mete-baseline-install configmap') {
                            steps {
                                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                                    withCredentials([usernamePassword(credentialsId: 'arm-seli-eeaprodart-token', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                                                usernamePassword(credentialsId: 'arm-sero-eeaprodart-token', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
                                                usernamePassword(credentialsId: 'arm-seli-eeaprodart-token', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
                                                file(credentialsId: env.system, variable: 'KUBECONFIG')]) {
                                        script {
                                            withEnv(["NAME_OF_CONFIGMAP='meta-baseline-install'"]) {
                                                try {
                                                    sh './bob/bob -r bob-rulesets/technical_ruleset.yaml delete-configmap > delete-meta-baseline-install-configmap.log'
                                                }
                                                catch (err) {
                                                    error("Caught delete-configmap ERROR: ${err}")
                                                }
                                            }
                                        }
                                    }
                                }
                                archiveArtifacts artifacts: "delete-meta-baseline-install-configmap.log", allowEmptyArchive: true
                            }
                        }

                        stage('K8S cleanup local registry') {
                            // It's a temporary quick solution to be able to turn off this stage for RV team. More robust solution will be introduced in this ticket EEAEPP-84623
                            when {
                                expression { params.LOCAL_REGISTRY_CLEANUP == true }
                            }
                            steps {
                                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                                    withCredentials([usernamePassword(credentialsId: 'local-image-registry', usernameVariable: 'LOCAL_DOCKER_USERNAME', passwordVariable: 'LOCAL_DOCKER_PASSWORD'),
                                                    usernamePassword(credentialsId: 'hub-root-user', usernameVariable: 'HUB_ROOT_USER', passwordVariable: 'HUB_ROOT_PASSWD'),
                                                    file(credentialsId: env.system, variable: 'KUBECONFIG')]) {
                                        script {
                                            sh './bob/bob -r bob-rulesets/cleanup_ruleset.yaml k8s-cleanup-local-registry > k8s-cleanup-local-registry.log'
                                        }
                                    }
                                }
                                archiveArtifacts artifacts: "k8s-cleanup-local-registry.log", allowEmptyArchive: true
                            }
                        }

                        stage('K8S cleanup containerd registry') {
                            steps {
                                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                                    withCredentials([usernamePassword(credentialsId: 'hub-root-user', usernameVariable: 'HUB_ROOT_USER', passwordVariable: 'HUB_ROOT_PASSWD'),
                                                    file(credentialsId: env.system, variable: 'KUBECONFIG')]) {
                                        script {
                                            sh './bob/bob -r bob-rulesets/cleanup_ruleset.yaml k8s-cleanup-containerd-registry > k8s-cleanup-containerd-registry.log'
                                        }
                                    }
                                }
                                archiveArtifacts artifacts: "k8s-cleanup-containerd-registry.log", allowEmptyArchive: true
                            }
                        }

                        stage('Check clean-up') {
                            steps {
                                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                                    withCredentials([usernamePassword(credentialsId: 'arm-seli-eeaprodart-token', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                                                usernamePassword(credentialsId: 'arm-sero-eeaprodart-token', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
                                                usernamePassword(credentialsId: 'arm-seli-eeaprodart-token', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
                                                file(credentialsId: env.system, variable: 'KUBECONFIG')]) {
                                        script {
                                            env.K8S_POST_CLEANUP_FAILED = false
                                            def pods_in_utf_ns = false
                                            def pods_in_product_ns = false
                                            def pods_in_product_crd = false
                                            def pvcs_in_ns = false

                                            // check resources for utf namespace
                                            withEnv(["NAMESPACE=utf-service",
                                                     "ADP_APP_STAGING_DIR=${WORKSPACE}/adp-app-staging"]) {
                                                try {
                                                    sh "./bob/bob get-pods -r ${WORKSPACE}/adp-app-staging/rulesets/describepod.yaml -q > stuck-pods-${env.NAMESPACE}.txt 2>&1"
                                                    output = readFile("stuck-pods-${env.NAMESPACE}.txt").trim()
                                                    if (output != "No resources found in ${env.NAMESPACE} namespace.") {
                                                        echo "Pods left on ${env.NAMESPACE}: '${output}'"
                                                        pods_in_utf_ns = true
                                                    }
                                                    sh "./bob/bob get-pvcs -r ${WORKSPACE}/adp-app-staging/rulesets/describepv.yaml -q > stuck-pvcs-${env.NAMESPACE}.txt 2>&1"
                                                    output = readFile("stuck-pvcs-${env.NAMESPACE}.txt").trim()
                                                    if (output != "No resources found in ${env.NAMESPACE} namespace.") {
                                                        echo "PVCs left on ${env.NAMESPACE}: '${output}'"
                                                        pvcs_in_ns = true
                                                        sh "./bob/bob -r ${WORKSPACE}/adp-app-staging/rulesets/describepv.yaml cleanup-pvcs cleanup-pvs > cleanup-pvcs-${env.NAMESPACE}.log"
                                                    }
                                                } catch (err) {
                                                    pods_in_utf_ns = true
                                                    echo("Caught check pods for ${env.NAMESPACE} namespace ERROR:\n${err}")
                                                } finally {
                                                    archiveArtifacts artifacts: "stuck-pods-${env.NAMESPACE}.txt", allowEmptyArchive: true
                                                    archiveArtifacts artifacts: "stuck-pvcs-${env.NAMESPACE}.txt", allowEmptyArchive: true
                                                    archiveArtifacts artifacts: "cleanup-pvcs-${env.NAMESPACE}.log", allowEmptyArchive: true
                                                }
                                            }

                                            // check resources for product namespace
                                            withEnv(["NAMESPACE=eric-eea-ns",
                                                     "ADP_APP_STAGING_DIR=${WORKSPACE}/adp-app-staging"]) {
                                                try {
                                                    sh "./bob/bob get-pods -r ${WORKSPACE}/adp-app-staging/rulesets/describepod.yaml -q > stuck-pods-${env.NAMESPACE}.txt 2>&1"
                                                    output = readFile("stuck-pods-${env.NAMESPACE}.txt").trim()
                                                    if (output != "No resources found in ${env.NAMESPACE} namespace.") {
                                                        echo "Pods left on ${env.NAMESPACE}: ${output}"
                                                        pods_in_product_ns = true
                                                    }
                                                    sh "./bob/bob get-pvcs -r ${WORKSPACE}/adp-app-staging/rulesets/describepv.yaml -q > stuck-pvcs-${env.NAMESPACE}.txt 2>&1"
                                                    output = readFile("stuck-pvcs-${env.NAMESPACE}.txt").trim()
                                                    if (output != "No resources found in ${env.NAMESPACE} namespace.") {
                                                        echo "PVCs left on ${env.NAMESPACE}: '${output}'"
                                                        pvcs_in_ns = true
                                                        sh "./bob/bob -r ${WORKSPACE}/adp-app-staging/rulesets/describepv.yaml cleanup-pvcs cleanup-pvs > cleanup-pvcs-${env.NAMESPACE}.log"
                                                    }
                                                }
                                                catch (err) {
                                                    pods_in_product_ns = true
                                                    echo("Caught check pods for ${env.NAMESPACE} namespace ERROR:\n${err}")
                                                } finally {
                                                    archiveArtifacts artifacts: "stuck-pods-${env.NAMESPACE}.txt", allowEmptyArchive: true
                                                    archiveArtifacts artifacts: "stuck-pvcs-${env.NAMESPACE}.txt", allowEmptyArchive: true
                                                    archiveArtifacts artifacts: "cleanup-pvcs-${env.NAMESPACE}.log", allowEmptyArchive: true
                                                }
                                            }

                                            // check resources for crd namespace
                                            withEnv(["NAMESPACE=eric-crd-ns",
                                                     "ADP_APP_STAGING_DIR=${WORKSPACE}/adp-app-staging"]) {
                                                try {
                                                    sh "./bob/bob get-pods -r ${WORKSPACE}/adp-app-staging/rulesets/describepod.yaml -q > stuck-pods-${env.NAMESPACE}.txt 2>&1"
                                                    output = readFile("stuck-pods-${env.NAMESPACE}.txt").trim()
                                                    if (output != "No resources found in ${env.NAMESPACE} namespace.") {
                                                        echo "Pods left on ${env.NAMESPACE}: ${output}"
                                                        pods_in_product_crd = true
                                                    }
                                                    sh "./bob/bob get-pvcs -r ${WORKSPACE}/adp-app-staging/rulesets/describepv.yaml -q > stuck-pvcs-${env.NAMESPACE}.txt 2>&1"
                                                    output = readFile("stuck-pvcs-${env.NAMESPACE}.txt").trim()
                                                    if (output != "No resources found in ${env.NAMESPACE} namespace.") {
                                                        echo "PVCs left on ${env.NAMESPACE}: '${output}'"
                                                        pvcs_in_ns = true
                                                        sh "./bob/bob -r ${WORKSPACE}/adp-app-staging/rulesets/describepv.yaml cleanup-pvcs cleanup-pvs > cleanup-pvcs-${env.NAMESPACE}.log"
                                                    }
                                                }
                                                catch (err) {
                                                    pods_in_product_crd = true
                                                    echo("Caught check pods for ${env.NAMESPACE} namespace ERROR\n:${err}")
                                                } finally {
                                                    archiveArtifacts artifacts: "stuck-pods-${env.NAMESPACE}.txt", allowEmptyArchive: true
                                                    archiveArtifacts artifacts: "stuck-pvcs-${env.NAMESPACE}.txt", allowEmptyArchive: true
                                                    archiveArtifacts artifacts: "cleanup-pvcs-${env.NAMESPACE}.log", allowEmptyArchive: true
                                                }
                                            }

                                            if (pods_in_utf_ns || pods_in_product_ns || pods_in_product_crd || pvcs_in_ns) {
                                                try {
                                                    timeout(time: 30, unit: 'MINUTES') {
                                                        sh './bob/bob -r bob-rulesets/cleanup_ruleset.yaml k8s-post-cleanup > post_cleanup.log 2>&1'
                                                    }
                                                }
                                                catch(err) {
                                                    env.K8S_POST_CLEANUP_FAILED = true
                                                    echo "Caught k8s-post-cleanup ERROR:\n${err}"
                                                } finally {
                                                    archiveArtifacts artifacts: "post_cleanup.log", allowEmptyArchive: true
                                                }
                                                notif.sendMail("${env.JOB_NAME} (${env.BUILD_NUMBER}) Cleanup check failed","${env.BUILD_URL} Cleanup check failed to finish on cluster ${env.system}","2b661627.ericsson.onmicrosoft.com@emea.teams.ms")
                                                error("Cleanup check failed")
                                            }
                                        }
                                    }
                                }

                                script {
                                    if (env.K8S_POST_CLEANUP_FAILED.toBoolean()) {
                                        error("k8s-post-cleanup FAILED!")
                                    }
                                }
                            }
                        }

                        stage('Cleanup stale volume attachments') {
                            steps {
                                withCredentials([file(credentialsId: env.system, variable: 'KUBECONFIG')]) {
                                    script {
                                        // cleanup stale volume attachments
                                        withEnv(["NAMESPACE=eric-eea-ns",
                                                 "ADP_APP_STAGING_DIR=${WORKSPACE}/adp-app-staging"]) {
                                            try {
                                                sh "./bob/bob cleanup-stale-volume-attachments -r ${WORKSPACE}/adp-app-staging/rulesets/describepv.yaml -q > cleanup-stale-volume-attachments.log"
                                            }
                                            catch (err) {
                                                echo("Caught cleanup stale volume attachments ERROR:\n${err}")
                                            }
                                            finally {
                                                archiveArtifacts artifacts: "cleanup-stale-volume-attachments.log", allowEmptyArchive: true
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        stage('Spotfire cleanup') {
                            when {
                                expression { params.SPOTFIRE_CLEANUP }
                            }
                            steps {
                                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                                    script {
                                        try {
                                            def spotfire_install_job = build job: "spotfire-asset-install-assign-label-wrapper", parameters: [
                                                booleanParam(name: 'CLEANUP_SPOTFIRE', value: true),
                                                stringParam(name: 'CLUSTER_NAME', value : env.CLUSTER)
                                            ], wait: true
                                        } catch (err) {
                                            echo "Caught Spotfire cleanup job ERROR: ${err}"
                                            try {
                                                withCredentials([file(credentialsId: env.system, variable: 'KUBECONFIG')]) {
                                                    timeout(time: 10, unit: 'MINUTES') {
                                                        sh './bob/bob -r bob-rulesets/log_collecting.yaml collect-spotfire-logs-from-cluster > spotfire_log_collector.log'
                                                    }
                                                }
                                            } catch (spotfire_log_collector_err) {
                                                echo"Failed log collect from spotfire-platform ERROR: ${spotfire_log_collector_err}"
                                            }
                                            finally {
                                                archiveArtifacts artifacts: "spotfire_log_collector.log", allowEmptyArchive: true
                                                archiveArtifacts artifacts: "logs_${env.SPOTFIRE_NAMESPACE}*", allowEmptyArchive: true
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        stage('Check if namespace exist') {
                            steps {
                                withCredentials([file(credentialsId: env.system, variable: 'KUBECONFIG')]) {
                                    script {
                                        Map args = [
                                            "skipCollectResourceInfo": "true",
                                            "skipChangeResourceLabel": "true",
                                            "notificationEmailText": "Found namespace(s) after cluster-cleanup"
                                        ]
                                        env.EEA_NS_CHECK_FAILED = checkIfNameSpaceExists(args)
                                        if ("${env.EEA_NS_CHECK_FAILED}".toBoolean()) {
                                            error "'${STAGE_NAME}' stage FAILED"
                                        }
                                    }
                                }
                            }
                        }

                        stage('Pull pause image with crictl') {
                            when {
                                expression { params.PULL_IMAGE_WITH_CRICTL == true }
                            }
                            steps {
                                withCredentials([usernamePassword(credentialsId: 'hub-root-user', usernameVariable: 'HUB_ROOT_USER', passwordVariable: 'HUB_ROOT_PASSWD'),
                                                file(credentialsId: "${env.CLUSTER_NAME}", variable: 'KUBECONFIG')]) {
                                    script {
                                        sh "./bob/bob -r bob-rulesets/technical_ruleset.yaml get-pause-image-info-from-containerd-config"
                                    }
                                }
                                script {
                                    env.ARM_IMAGE_NAME = sh(script: "cat arm_pause_image_name", returnStdout: true).trim()
                                    echo "ARM_IMAGE_NAME ${env.ARM_IMAGE_NAME}"
                                    withCredentials([usernamePassword(credentialsId: 'hub-root-user', usernameVariable: 'HUB_ROOT_USER', passwordVariable: 'HUB_ROOT_PASSWD'),
                                        usernamePassword(credentialsId: 'arm-seli-eeaprodart-token', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
                                        file(credentialsId: "${env.CLUSTER_NAME}", variable: 'KUBECONFIG')]) {

                                        sh "./bob/bob -r bob-rulesets/technical_ruleset.yaml crictl-pull-images-from-arm"
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
        always {
            script {
                if ( !params.DRY_RUN && env.CLUSTER?.trim() ) {
                    sendLockEventToDashboard (transition: "release", cluster: env.CLUSTER)
                    try {
                        def new_label
                        def labelmanualchanged = checkLockableResourceLabelManualChange(env.CLUSTER) && new ClusterLockUtils(this).getLockableResourceLabels(env.CLUSTER) != vars.resourceLabelFaulty
                        if (! labelmanualchanged) {
                            if (currentBuild.result != "SUCCESS") {
                                if (ceph_fail_require_admin) {
                                    new_label = "ceph-error-admin-required"
                                } else if (ceph_fail) {
                                    new_label = "ceph-error"
                                } else {
                                    new_label = vars.resourceLabelFaulty
                                }
                            } else if (env.CLUSTER.startsWith("rv-")) {
                                new_label = env.CLUSTER
                            } else {
                                new_label = params.DESIRED_CLUSTER_LABEL
                            }
                            if ( currentBuild.result != 'SUCCESS' ) {
                                description = "${currentBuild.result} ${env.JOB_NAME} ${env.BUILD_NUMBER}"
                            } else {
                                description = ""
                            }
                            build job: "lockable-resource-label-change", parameters: [
                                booleanParam(name: 'DRY_RUN', value: false),
                                stringParam(name: 'DESIRED_CLUSTER_LABEL', value : new_label),
                                stringParam(name: 'CLUSTER_NAME', value : "${env.CLUSTER}"),
                                stringParam(name: 'PIPELINE_NAME', value: params.PIPELINE_NAME),
                                stringParam(name: 'SPINNAKER_ID', value: params.SPINNAKER_ID),
                                stringParam(name: 'SPINNAKER_TRIGGER_URL', value: params.SPINNAKER_TRIGGER_URL),
                                stringParam(name: 'DESCRIPTION', value: description)], wait: true
                            echo "The '${new_label}' label is set for the resource ${env.CLUSTER}"
                        }
                    }
                    catch (err) {
                        error("Caught error in resource label change: ${err}")
                    }
                }
                // Collect all archived artifacts to a folder
                try {
                    if (env.MAIN_BRANCH == 'master') {
                        jenkinsCredentialsId = 'jenkins-api-token' // Master Jenkins API Token Credential
                    } else {
                        jenkinsCredentialsId = 'test-jenkins-token' // Test Jenkins API Token Credential
                    }
                    withCredentials([string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                     usernamePassword(credentialsId: jenkinsCredentialsId, usernameVariable: 'JENKINS_USER', passwordVariable: 'JENKINS_PASSWORD')]){
                        env.ARM_TARGET_PATH = "${JOB_NAME}-${BUILD_NUMBER}/"
                        //create tar.gz file with logs
                        sh """
                            mkdir -p collected_artif
                            curl --user \$JENKINS_USER:\$JENKINS_PASSWORD -k -O ${env.JENKINS_URL}/job/${env.JOB_NAME}/${env.BUILD_NUMBER}/artifact/*zip*/archive.zip
                            unzip archive.zip -d collected_artif
                            tar -czvf collected-artifacts.tar.gz -C collected_artif .
                        """
                        archiveArtifacts artifacts: 'collected-artifacts.tar.gz', allowEmptyArchive: true
                        //upload to ARM
                        arm.setUrl('https://arm.seli.gic.ericsson.se/', "$API_TOKEN_EEA")
                        arm.setRepo('proj-eea-reports-generic-local')
                        arm.deployArtifact('collected-artifacts.tar.gz', "/clusterlogs/${ARM_TARGET_PATH}")
                        //link to ARM in description
                        def link = "https://arm.seli.gic.ericsson.se/artifactory/proj-eea-reports-generic-local/clusterlogs/"
                        def descrToLogs = "<br>Cluster logs: <a href= '${link}${ARM_TARGET_PATH}'>${ARM_TARGET_PATH}</a>"
                        echo "get log folder link ..."
                        currentBuild.description += descrToLogs
                    }
                } catch (err) {
                    error("Caught error in saving logs to Artifactory: ${err}")
                }
            }
        }
    }
}
