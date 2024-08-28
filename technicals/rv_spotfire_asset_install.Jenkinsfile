@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.GlobalVars
import com.ericsson.eea4.ci.CommonUtils
import com.ericsson.eea4.ci.ClusterLockUtils
import groovy.transform.Field

@Field def vars = new GlobalVars()
@Field def vars_Clusters = GlobalVars.Clusters.values().findAll{!it.resource.equals(' ')}.collect{it.resource}.sort()

@Field def gitinv_test = new GitScm(this, 'EEA/inv_test')
@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def cmutils = new CommonUtils(this)
@Field def clusterLockUtils =  new ClusterLockUtils(this)

pipeline {
    options {
        buildDiscarder(logRotator(daysToKeepStr: '15', artifactDaysToKeepStr: '15'))
        // only 2 jobs can be run at a time and only 1 execution per build node, because ansible controller /etc/hosts file is modified during job execution
        throttleJobProperty(
            maxConcurrentTotal: 8,
            throttleEnabled: true,
            throttleOption: 'project'
        )
        timeout(time: 57, unit: "MINUTES")
    }
    parameters {
        string(
            name: 'AGENT_LABEL',
            description: 'Jenkins agent with the label will be used for the build',
            defaultValue: 'productci'
        )
        choice(
            name: 'CLUSTER_NAME',
            description: 'Select cluster',
            choices: ['-'] + vars_Clusters,
        )
        string(
            name: 'EEA4_NS_NAME',
            description: 'Namespace where EEA4 will be/is deployed',
            defaultValue: 'eric-eea-ns'
        )
        string (
            name: 'OAM_POOL',
            defaultValue: 'pool0',
            description: """IP Pool name where eric-ts-platform-haproxy service will get LoadBalancer IP from.<br>
                RV clusters: pool0'
                """
        )
        string(
            name: 'SF_ASSET_VERSION',
            defaultValue: 'auto',
            description: """Select Spotfire asset version. Value refers to a directory on Jenkins agent node, where package is already extracted to.
                By default the value is extracted from <a href="https://gerrit-stg.seli.gic.ericsson.se/plugins/gitiles/EEA/cnint/+/master/spotfire_platform.yml">spotfire_platform.yml</a> file from cnint repository.
                If it's needed to specify another version, it can be done by pointing one manually, e.g.
                <b>spotfire-platform-asset-12.5.0-1.5.0-120124</b>
                """
        )
        booleanParam(
            name: 'CLEANUP_SPOTFIRE',
            defaultValue: 'false',
            description: """Cleanup deployed Spotfire from k8s cluster. Cleanup method is automatically called also when INSTALL_SPOTFIRE_PLATFORM is selected."""
        )
        booleanParam(
            name: 'INSTALL_SPOTFIRE_PLATFORM',
            defaultValue: 'false',
            description: """The followings will be performed in this stage:
                <ul>
                    <li>Install Spotfire BI Visualization Platform in spotfire-platform namespace</li>
                    <li>Install PostgreSQL DB & Vertica DB Data Source Templates</li>
                    <li>Import the selected EEA4 Dashboard Data Source ZIP file</li>
                    <li>Trust custom scripts and allow Ericsson brand styling</li>
                    <li>Deploy and start Web player and Python services</li>
                </ul>
                """
        )
        booleanParam(
            name: 'DEPLOY_STATIC_CONTENT',
            defaultValue: 'false',
            description: """Install or re-install the specified static content (SC) version.<br>
                Can be re-executed anytime, can be used to upgrade existing SC version to a new one.
                """
        )
        string(
            name: 'STATIC_CONTENT_PKG',
            defaultValue: 'auto',
            description: """Value is taken into account when <b>DEPLOY_STATIC_CONTENT</b> checkbox is selected.
                By default the value is extracted from <a href="https://gerrit-stg.seli.gic.ericsson.se/plugins/gitiles/EEA/cnint/+/master/spotfire_platform.yml">spotfire_platform.yml</a> file from cnint repository.
                If it's needed to specify another version, it can be done by pointing one manually, e.g.
                <b>proj-eea4-other-dev-local/com/ericsson/eea4/spotfire-static-content/1.1.44/spotfire-static-content-1.1.44.tar.gz</b>
                """
        )
        booleanParam(
            name: 'SETUP_TLS_AND_SSO',
            defaultValue: 'false',
            description: """The followings will be performed in this stage:
                <ul>
                    <li>Set Up TLS Connection Between Spotfire and OLAP (Vertica) Database</li>
                    <li>Configure IAM in EEA namespace for Spotfire and create new Spotfire users in IAM</li>
                    <li>Enable IAM Authentication in Spotfire config</li>
                </ul>
                Select this checkbox only if
                <ol type="1">
                    <li>Spotfire platform is installed earlier</li>
                    <li>EEA4 helm chart is installed earlier</li>
                    <li>Certificates are loaded to EEA namespace</li>
                """
        )
        booleanParam(
            name: 'ENABLE_CAPACITY_REPORTER',
            defaultValue: 'false',
            description: """Configure and enable capacity reporter"""
        )
        string(
            name: 'PREVIOUS_JOB_BUILD_ID',
            defaultValue: '',
            description: """Value is required if <b>ENABLE_CAPACITY_REPORTER</b> checkbox is selected.
                Value should be the build ID of the previous job, where the Spotfire platform was installed on the selected cluster.
                E.g. 234.
                """
        )
        booleanParam(
            name: 'ENABLE_OPTIONAL_FEATURES',
            defaultValue: 'false',
            description: """Activate optional features, that are required for development purposes only.
                <ul>
                    <li>Create LoadBalancer service for PSQL DB: use together with <b>INSTALL_SPOTFIRE_PLATFORM</b> parameter</li>
                    <li>Add admin rights for admin-sf user: use together with <b>SETUP_TLS_AND_SSO</b> parameter</li>
                </ul>
            """
        )
        string(
            name: 'ADP_APP_STAGING_GERRIT_REFSPEC',
            defaultValue: '',
            description: 'Gerrit refspec of the adp-app-staging repo e.g.: refs/changes/87/4641487/1'
        )
        string (
            name: 'CNINT_GERRIT_REFSPEC',
            defaultValue: '',
            description: 'Gerrit refspec of the cnint repo, e.g. refs/changes/87/4641487/1'
        )
        booleanParam(
            name: 'DRY_RUN',
            defaultValue: 'false',
            description: 'To run DryRun check.'
        )
    }
    agent {
        node {
            label "${params.AGENT_LABEL}"
        }
    }
    environment {
        PLAYBOOK_DIR = "${WORKSPACE}/adp-app-staging/ansible/spotfire_asset_install"
        REGISTRY_CA_CERT_INV_REPO = "${WORKSPACE}/inv_test/eea4/cluster_inventories/ca_files/ca.crt"
        EXTERNAL_CA_KEY = "${WORKSPACE}/cnint/eric-eea-int-helm-chart-ci/static/eea4-certs/external_ca.key"
        EXTERNAL_CA_PEM = "${WORKSPACE}/cnint/eric-eea-int-helm-chart-ci/static/eea4-certs/external_ca.pem"
        // The below ones will be created by job in the preparation stage
        EXTRA_VARS_YAML_FILE = "${WORKSPACE}/${params.CLUSTER_NAME}_extra_vars.yml"
        KUBECONFIG_FILE = "${WORKSPACE}/${params.CLUSTER_NAME}_kubeconfig.txt"
    }
    stages {
        stage('DryRun') {
            when {
                expression { params.DRY_RUN }
            }
            steps {
                script {
                    dryRun()
                }
           }
        }
        stage('RUN') {
            when {
                expression { !params.DRY_RUN }
            }
            stages {
                stage('Validate params') {
                    steps {
                        script {
                            if (!params.CLUSTER_NAME?.trim() || params.CLUSTER_NAME == "-") {
                                error "CLUSTER_NAME input parameter is mandatory and should be specified!"
                            }
                            if (params.INSTALL_SPOTFIRE_PLATFORM && params.SETUP_TLS_AND_SSO) {
                                error "INSTALL_SPOTFIRE_PLATFORM and SETUP_TLS_AND_SSO actions cannot be selected at the same time!"
                            }
                            if (params.CLEANUP_SPOTFIRE && params.DEPLOY_STATIC_CONTENT) {
                                error("CLEANUP_SPOTFIRE and DEPLOY_STATIC_CONTENT actions are incompatible and cannot be used simultaneously!")
                            }
                            if (params.INSTALL_SPOTFIRE_PLATFORM && params.PREVIOUS_JOB_BUILD_ID.trim() != '') {
                                error "PREVIOUS_JOB_BUILD_ID value should be empty if installing Spotfire platform!"
                            }
                            // TODO: later on any stage that requires helm upgrade should be added to the below check
                            if (params.ENABLE_CAPACITY_REPORTER) {
                                if (params.PREVIOUS_JOB_BUILD_ID.trim() == '' || !(params.PREVIOUS_JOB_BUILD_ID.trim() ==~ /[0-9]+/)) {
                                    error "PREVIOUS_JOB_BUILD_ID value should be populated and contain only digits!"
                                }
                            }
                        }
                    }
                }
                stage('Check if ProductCI cluster is locked or reserved') {
                    when {
                        expression {params.CLUSTER_NAME && params.CLUSTER_NAME.contains('kubeconfig-seliics0')}
                    }
                    steps {
                        script {
                            def isBuildCalledByUpstreamJob = cmutils.isCurrentBuildCalledByUpstreamJob()
                            def statusCheck = clusterLockUtils.getResourceLabelStatus("${params.CLUSTER_NAME}")
                            echo("Cluster status is " + statusCheck)
                            if ( (isBuildCalledByUpstreamJob) && statusCheck != "Locked" ) {
                                error("Current build was called by upstream job. Cluster should be locked by upstream pipeline to prevent collisions!")
                            }
                            else if ( !(isBuildCalledByUpstreamJob) && statusCheck != "Reserved" ) {
                                error("Current build is manual and cluster ${CLUSTER_NAME} should be reserved to prevent being caught by other jobs at the same time!")
                            }
                        }
                    }
                }
                stage('CleanWorkspace') {
                    steps {
                        cleanWs()
                    }
                }
                stage('Checkout repos') {
                    steps {
                        script {
                            gitcnint.checkout('master', 'cnint')
                            gitinv_test.checkout('master', 'inv_test')
                            if ( params.ADP_APP_STAGING_GERRIT_REFSPEC != '' ) {
                                gitadp.checkoutRefSpec("${params.ADP_APP_STAGING_GERRIT_REFSPEC}", "FETCH_HEAD", "adp-app-staging")
                            }else {
                                gitadp.checkout("${MAIN_BRANCH}", "adp-app-staging")
                            }
                            if (params.CNINT_GERRIT_REFSPEC != '') {
                                dir('cnint') {
                                    gitcnint.fetchAndCherryPick('EEA/cnint', "${params.CNINT_GERRIT_REFSPEC}")
                                }
                            }
                        }
                    }
                }
                stage('Jenkins Desc.') {
                    steps {
                        script {
                            currentBuild.displayName = "#${env.BUILD_NUMBER} ${params.CLUSTER_NAME}"
                        }
                    }
                }
                stage('Prepare extra vars input file') {
                    steps {
                        script {
                            dir('cnint') {
                                if (params.SF_ASSET_VERSION == 'auto') {
                                    def data = readYaml file: 'spotfire_platform.yml'
                                    env.SF_ASSET_VERSION = data.spotfire_platform.spotfire_asset.version
                                } else {
                                    env.SF_ASSET_VERSION = params.SF_ASSET_VERSION
                                }

                                if (params.STATIC_CONTENT_PKG == 'auto') {
                                    def data = readYaml file: 'spotfire_platform.yml'
                                    env.SF_STATIC_CONTENT_PATH = data.spotfire_platform.spotfire_static_content.download_url.split('artifactory/')[1]
                                    env.SF_STATIC_CONTENT_VERSION = data.spotfire_platform.spotfire_static_content.version
                                    env.STATIC_CONTENT_PKG = env.SF_STATIC_CONTENT_PATH + env.SF_STATIC_CONTENT_VERSION + "/spotfire-static-content-" + env.SF_STATIC_CONTENT_VERSION + ".tar.gz"
                                } else {
                                    env.STATIC_CONTENT_PKG = params.STATIC_CONTENT_PKG
                                }
                            }

                            echo("SPOTFIRE_ASSET_VERSION: " + env.SF_ASSET_VERSION)
                            echo("STATIC_CONTENT_PACKAGE: " + env.STATIC_CONTENT_PKG)

                            withCredentials([file(credentialsId: params.CLUSTER_NAME, variable: 'mykubefile')]) {
                                writeFile file: "${env.KUBECONFIG_FILE}", text: readFile(mykubefile)
                            }
                            def extraVars = [:]
                            extraVars['project_work_dir'] = env.WORKSPACE.toString()
                            extraVars['kubeconfig'] = env.KUBECONFIG_FILE.toString()
                            extraVars['asset_version'] = env.SF_ASSET_VERSION.trim()
                            extraVars['eea_namespace'] = params.EEA4_NS_NAME.trim()
                            extraVars['cr_url'] = 'auto'
                            extraVars['cr_ip'] =  'auto'
                            extraVars['cr_port'] = 'auto'
                            extraVars['cr_user'] = 'admin'
                            extraVars['cr_pass'] = 'EvaiKiO1'
                            extraVars['cr_cacert'] = env.REGISTRY_CA_CERT_INV_REPO.toString()
                            extraVars['oam_pool_name'] = params.OAM_POOL.trim()
                            extraVars['root_ca_key'] = env.EXTERNAL_CA_KEY.toString()
                            extraVars['root_ca_cert'] = env.EXTERNAL_CA_PEM.toString()
                            extraVars['arm_url_postfix'] = env.STATIC_CONTENT_PKG.trim()
                            extraVars['enable_optional_features'] = params.ENABLE_OPTIONAL_FEATURES.toBoolean()
                            // create yaml file
                            writeYaml file: "${env.EXTRA_VARS_YAML_FILE}", data: extraVars, overwrite: true
                        }
                    }
                    post {
                        always {
                            script {
                                archiveArtifacts artifacts: "*_extra_vars.yml", allowEmptyArchive: false
                            }
                        }
                    }
                }
                stage('Prepare WORK DIR') {
                    steps {
                        script {
                            if (params.ENABLE_CAPACITY_REPORTER) {
                                println("Copy YAML files from earlier installation job to work directory ${env.WORKSPACE}")
                                copyArtifacts(
                                    projectName: "${env.JOB_NAME}",
                                    selector: specific("${params.PREVIOUS_JOB_BUILD_ID}"),
                                    filter: "*.yaml,*.txt",
                                    flatten: true,
                                    target: "${env.WORKSPACE}/",
                                    fingerprintArtifacts: true
                                )
                            }
                            sh('ls -la $WORKSPACE')
                        }
                    }
                }
                stage('Spotfire Platform Cleanup') {
                    when {
                        anyOf {
                            expression { params.CLEANUP_SPOTFIRE == true }
                            expression { params.INSTALL_SPOTFIRE_PLATFORM == true }
                        }
                    }
                    steps {
                        script {
                            sh('ansible-playbook $PLAYBOOK_DIR/sf-00-uninstall.yml --extra-vars="@$EXTRA_VARS_YAML_FILE"')
                        }
                    }
                }
                stage('Spotfire Platform Install') {
                    when {
                        expression { params.INSTALL_SPOTFIRE_PLATFORM == true }
                    }
                    steps {
                        script {
                            sh('ansible-playbook $PLAYBOOK_DIR/sf-01-install-spotfire-asset.yml --extra-vars="@$EXTRA_VARS_YAML_FILE"')
                        }
                    }
                    post {
                        always {
                            script {
                                archiveArtifacts artifacts: "*.yaml", allowEmptyArchive: false
                                archiveArtifacts artifacts: "chart_file_path.txt", allowEmptyArchive: false
                            }
                        }
                    }
                }
                stage('Deploy Static content') {
                    when {
                        expression { params.DEPLOY_STATIC_CONTENT == true }
                    }
                    steps {
                        script {
                            withCredentials([string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN')]){
                                sh('ansible-playbook $PLAYBOOK_DIR/sf-03-install_static_content.yml --extra-vars="@$EXTRA_VARS_YAML_FILE" -e seli_arm_api_token="$API_TOKEN"')
                            }
                        }
                    }
                }
                stage('Connect to EEA4 (Vertica + IAM)') {
                    when {
                        expression { params.SETUP_TLS_AND_SSO == true }
                    }
                    steps {
                        script {
                            sh('ansible-playbook $PLAYBOOK_DIR/sf-02-connect_to_eea.yml --extra-vars="@$EXTRA_VARS_YAML_FILE"')
                        }
                    }
                    post {
                        always {
                            script {
                                // save Selenium screenshot files for debugging purposes
                                archiveArtifacts artifacts: "*.png", allowEmptyArchive: true
                            }
                        }
                    }
                }
                stage('Enable Capacity reporter') {
                    when {
                        expression { params.ENABLE_CAPACITY_REPORTER == true }
                    }
                    steps {
                        script {
                            sh('ansible-playbook $PLAYBOOK_DIR/sf-04-enable-capacity-reporter.yml --extra-vars="@$EXTRA_VARS_YAML_FILE"')
                        }
                    }
                    post {
                        always {
                            script {
                                archiveArtifacts artifacts: "*.yaml", allowEmptyArchive: false
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
                emailext body: "${env.JOB_NAME} build ${env.BUILD_NUMBER}: ${currentBuild.currentResult}\nMore info at: ${env.BUILD_URL}",
                  to: "${env.BUILD_USER_EMAIL}",
                  subject: "${env.JOB_NAME}: ${currentBuild.currentResult}"

                env.UPSTREAM_JOB_NAME = getLastUpstreamBuildEnvVarValue('JOB_NAME').trim()
                env.UPSTREAM_BUILD_NUMBER = getLastUpstreamBuildEnvVarValue('BUILD_NUMBER').trim()
                echo "Upstream job: ${env.UPSTREAM_JOB_NAME} ${env.UPSTREAM_BUILD_NUMBER}"

                echo "Execute cleanup-jenkins-agent-label job"
                try {
                    build job: "cleanup-jenkins-agent-label", parameters: [
                        stringParam(name: "LABEL_TO_REMOVE_LIST", value: "spotfire-asset-install-${env.UPSTREAM_JOB_NAME}-${env.UPSTREAM_BUILD_NUMBER}"),
                        stringParam(name: "JENKINS_AGENTS_LIST", value: env.NODE_NAME)
                    ], wait: false
                } catch (err) {
                    echo "cleanup-jenkins-agent-label pipeline caught ERROR: ${err}"
                }
            }
        }
    }
}
