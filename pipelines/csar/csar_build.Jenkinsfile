@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.Artifactory
import groovy.transform.Field
import com.ericsson.eea4.ci.YamlOperations
import com.ericsson.eea4.ci.GlobalVars

@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def git_adp_gs_snmp_ap = new GitScm(this, 'adp-gs/adp-gs-snmp-ap')
@Field def arm = new Artifactory(this, "https://arm.seli.gic.ericsson.se/", "API_TOKEN_EEA")
@Field def yaml = new YamlOperations(this)
@Field def vars = new GlobalVars()

pipeline {
    options {
        buildDiscarder(logRotator(daysToKeepStr: "14", artifactDaysToKeepStr: "7"))
        skipDefaultCheckout()
    }
    agent {
        node {
            label 'productci'
        }
    }
    parameters {
        string(name: 'INT_CHART_REPO', description: 'Chart repo e.g.: https://arm.seli.gic.ericsson.se/artifactory/proj-eea-internal-generic-local', defaultValue: 'https://arm.seli.gic.ericsson.se/artifactory/proj-eea-internal-generic-local')
        string(name: 'INT_CHART_VERSION', description: 'Chart version e.g.: 1.0.0-1', defaultValue: '')
        string(name: 'CUSTOM_FOLDER', description: 'Custom folder to include in package', defaultValue: '')
        string(name: 'GERRIT_REFSPEC', description: 'Gerrit Refspec of the integration chart git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'SPINNAKER_ID', description: "The spinnaker execution's id", defaultValue: 'test')
    }
    environment{
        SEP_CHART_NAME = "eric-cs-storage-encryption-provider"
        SEP_CHART_REPO = "https://arm.sero.gic.ericsson.se/artifactory/proj-adp-rs-storage-encr-released-helm"
        TLS_PROXY_NAME = "eric-tm-tls-proxy-ev"
        TLS_PROXY_REPO = "https://arm.sero.gic.ericsson.se/artifactory/proj-adp-tm-tls-proxy-ev-released-helm"
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

        stage('Gerrit message') {
            steps {
                script {
                    if(params.GERRIT_REFSPEC != '') {
                        env.GERRIT_MSG = "Build Started ${BUILD_URL}"
                        sendMessageToGerrit(params.GERRIT_REFSPEC, env.GERRIT_MSG)
                    }
                }
            }
        }

        stage('Set Spinnaker link') {
            steps {
                script {
                    if ( params.SPINNAKER_ID != '' ) {
                        currentBuild.description = '<a href="https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/details/' + params.SPINNAKER_ID + '">Spinnaker URL: ' + params.SPINNAKER_ID + '</a>'
                    }
                }
            }
        }

        stage('Checkout adp-app-staging') {
            steps {
                script{
                    gitadp.checkout(env.MAIN_BRANCH, 'adp-app-staging')
                }
            }
        }

        stage('Prepare') {
            steps {
                dir('adp-app-staging') {
                    script {
                        checkoutGitSubmodules()
                        sh './bob/bob clean'  //simple bob command to init vars
                    }
                }
            }
        }

        stage('Checkout cnint') {
            steps {
               script {
                    if (params.INT_CHART_VERSION.contains('-')) {
                        gitcnint.checkout('master', 'cnint')
                    } else {
                        gitcnint.checkoutRefSpec("refs/tags/" + params.INT_CHART_VERSION.replace('+', '-'), 'FETCH_HEAD', 'cnint')
                    }
                }
            }
        }

        stage('Ruleset and config change checkout') {
            when {
                expression {params.GERRIT_REFSPEC}
            }
            steps {
                dir('cnint') {
                    script {
                        gitcnint.fetchAndCherryPick('EEA/cnint', "${params.GERRIT_REFSPEC}")
                    }
                }
            }
        }

        stage('Prepare CSAR build') {
            steps {
                // Preparation
                script {
                    sh 'mkdir -p csarworkdir/charts'
                    sh 'mkdir -p csarworkdir/scripts/configurations/eea4-default-dataflow/dataflow-configuration'
                    sh 'mkdir -p csarworkdir/scripts/configurations/sep'
                }

                withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                 string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                 string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                 usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {

                    // save utils docker image with install crd script
                    dir('cnint') {
                        script {
                            // get utils image version from the refspec
                            def rulesetDatas = readYaml file: 'ruleset2.0.yaml'
                            def images=rulesetDatas['docker-images']
                            def imagePath = ""
                            images.each {image ->
                                if (image['eea4-utils'] != null){
                                    imagePath += image['eea4-utils']
                                }

                            }
                            env.UTILS_PATH_VERSION = imagePath
                            env.UTILS_VERSION = imagePath.substring(imagePath.lastIndexOf(':') + 1)

                        }
                    }
                }
            }
        }

        stage('copy content to script folder') {
            steps {
                // Checkout eric-eea-utils image to scripts folder
                dir('csarworkdir/scripts') {
                    script {
                        sh 'docker pull ${UTILS_PATH_VERSION}'
                        sh 'docker save -o eric-eea-utils_${UTILS_VERSION}.tar ${UTILS_PATH_VERSION}'
                    }
                }

                // Copy csar_exception_list to csarworkdir and scripts folders
                dir('csarworkdir') {
                    script {
                        sh "cp -Rv ${WORKSPACE}/cnint/csar-scripts/* scripts/"
                        sh "cp ${WORKSPACE}/cnint/helm-values/additional_csar_values.yaml ."
                        sh "cp -v ${WORKSPACE}/cnint/csar_exception_list ."
                        sh "cp -v ${WORKSPACE}/cnint/csar_exception_list scripts/"
                        sh "rsync -av --exclude-from=${WORKSPACE}/cnint/csar_blacklist ${WORKSPACE}/cnint/dataflow-configuration scripts/configurations/eea4-default-dataflow/"
                        sh "cp -v ${WORKSPACE}/cnint/helm-values/sep_values.yaml scripts/configurations/sep/"
                        sh 'mkdir -p scripts/cma/'
                        sh "cp -v ${WORKSPACE}/cnint/helm-values/disable-cma-values.yaml scripts/cma/"
                    }
                }
                // Copy custom directory
                script {
                    if (params.CUSTOM_FOLDER != '') {
                        sh '''
                            if [ -e $CUSTOM_FOLDER ]
                                then cp -r $CUSTOM_FOLDER csarworkdir/scripts
                            else
                                echo "Copying of $CUSTOM_FOLDER into package failed!"
                                exit 1
                            fi
                        '''
                    }
                }
            }
        }

        stage('Remove disabled services') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                 string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                 string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                 usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                        // Download integration helm chart
                        sh 'curl -H "X-JFrog-Art-Api: $API_TOKEN_EEA" $INT_CHART_REPO/eric-eea-int-helm-chart/eric-eea-int-helm-chart-$INT_CHART_VERSION.tgz --fail -o csarworkdir/charts/eric-eea-int-helm-chart-$INT_CHART_VERSION.tgz'
                        // Extract integration helm chart
                        sh 'cd $WORKSPACE/csarworkdir/charts; tar xf eric-eea-int-helm-chart-$INT_CHART_VERSION.tgz '
                        // Clean charts folder and remove old .tgz
                        sh 'cd $WORKSPACE/csarworkdir/charts; rm -rf eric-eea-int-helm-chart/charts/*; rm -rf eric-eea-int-helm-chart-$INT_CHART_VERSION.tgz'
                        script {
                            echo "Remove disabled services"
                                def servicesList = readFile("$WORKSPACE/csarworkdir/csar_exception_list").readLines()
                                yaml.ihcData = readYaml file: "$WORKSPACE/csarworkdir/charts/eric-eea-int-helm-chart/Chart.yaml"
                                yaml.removeServicesFromChart(yaml.ihcData, servicesList)
                                sh ''' rm -f "$WORKSPACE/csarworkdir/charts/eric-eea-int-helm-chart/Chart.yaml" '''
                                writeYaml file: "$WORKSPACE/csarworkdir/charts/eric-eea-int-helm-chart/Chart.yaml", data: yaml.ihcData
                        }
                    }
                }
            }
        }

        stage('Checkout and copy eric-fh-snmp-alarm-provider MIB files') {
            steps {
                script {
                    env.ERIC_FH_SNMP_ALARM_PROVIDER_VERSION = sh(
                        script: '''< $WORKSPACE/csarworkdir/charts/eric-eea-int-helm-chart/Chart.yaml grep -A 2 eric-fh-snmp-alarm-provider |  grep version | awk -F' ' '{print $2}' |  tr -d '\\n'
                        ''',
                        returnStdout : true)
                    echo 'ERIC_FH_SNMP_ALARM_PROVIDER_VERSION:' + env.ERIC_FH_SNMP_ALARM_PROVIDER_VERSION
                    git_adp_gs_snmp_ap.checkoutRefSpec("v"+env.ERIC_FH_SNMP_ALARM_PROVIDER_VERSION, "FETCH_HEAD", 'adp_gs_snmp_ap')

                    // If exist than remove cnint/csar-scripts/snmp/
                    sh '''#!/bin/bash
                        set -x
                        [[ -d $WORKSPACE/csarworkdir/scripts/snmp/ ]] && rm -rf $WORKSPACE/csarworkdir/scripts/snmp/ || echo "Unnecessary csarworkdir/scripts/snmp/ delete skipped."
                    '''
                    sh ' ls -la $WORKSPACE/csarworkdir/scripts/'
                    // Copy the mib file from adp_gs_snmp_ap checkout
                    sh '''#!/bin/bash
                        set -x; mkdir -p $WORKSPACE/csarworkdir/scripts/snmp/; cp $WORKSPACE/adp_gs_snmp_ap/src/api/ERICSSON-ALARM-MIB/*.mib $WORKSPACE/csarworkdir/scripts/snmp/
                    '''
                    sh '''#!/bin/bash
                         ls -la $WORKSPACE/csarworkdir/scripts/*
                    '''
                }
            }
        }

        stage('Re-package eric-eea-int-helm-chart') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                 string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                 string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                 usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                        // Re-package integration helm chart
                        dir('csarworkdir/charts') {
                            sh '$WORKSPACE/adp-app-staging/bob/bob -r $WORKSPACE/cnint/bob-rulesets/csar_build.yaml package-ihc'
                        }
                        sh 'cd $WORKSPACE/csarworkdir/charts; rm -rf eric-eea-int-helm-chart'
                    }
                }
            }
        }

        stage('Download SEP and TLS Proxy') {
            steps {
               script {
                    withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                 string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                 string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                 usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                        // Download SEP and TLS Proxy helm charts
                        sh '''cd $WORKSPACE/csarworkdir; tar xf charts/eric-eea-int-helm-chart-$INT_CHART_VERSION.tgz eric-eea-int-helm-chart/Chart.yaml --strip-components=1'''
                        script {
                            env.SEP_CHART_VERSION = sh(
                                script: '''cat $WORKSPACE/csarworkdir/Chart.yaml |grep -A 2 storage-encryption-provider | grep version | awk -F' ' '{print $2}' | tr -d '\\n'
                                ''',
                                returnStdout : true)
                            env.TLS_PROXY_VERSION = sh(
                                script: '''cat $WORKSPACE/csarworkdir/Chart.yaml |grep -A 2 eric-tm-tls-proxy-ev | grep version | awk -F' ' '{print $2}' | tr -d '\\n'
                                ''',
                                returnStdout : true)
                        }
                        sh 'curl -H "X-JFrog-Art-Api: $API_TOKEN_ADP" $SEP_CHART_REPO/$SEP_CHART_NAME/$SEP_CHART_NAME-$SEP_CHART_VERSION.tgz --fail -o csarworkdir/charts/$SEP_CHART_NAME-$SEP_CHART_VERSION.tgz'
                        sh 'curl -H "X-JFrog-Art-Api: $API_TOKEN_ADP" $TLS_PROXY_REPO/$TLS_PROXY_NAME/$TLS_PROXY_NAME-$TLS_PROXY_VERSION.tgz --fail -o csarworkdir/charts/$TLS_PROXY_NAME-$TLS_PROXY_VERSION.tgz'
                    }
                }
            }
        }

        stage('Build CSAR package') {
            steps {
               // Extract values.yaml and enable all services
                    sh '''cd $WORKSPACE/csarworkdir; tar xf charts/eric-eea-int-helm-chart-$INT_CHART_VERSION.tgz eric-eea-int-helm-chart/values.yaml --strip-components=1; sed -i "s/enabled: false/enabled: true/g" values.yaml'''
                    // Extract crd helm charts
                    sh '''cd $WORKSPACE/csarworkdir/charts; for crdhelm in $(tar tf eric-eea-int-helm-chart-$INT_CHART_VERSION.tgz | grep -E 'crd.*tgz'); do stripnumber=$(echo $crdhelm | awk -F"/" '{print NF-1}'); tar xf eric-eea-int-helm-chart-$INT_CHART_VERSION.tgz $crdhelm --strip-components $stripnumber; done'''
                    sh '$WORKSPACE/adp-app-staging/bob/bob -r $WORKSPACE/cnint/bob-rulesets/csar_build.yaml build-csar'
            }
        }

        stage('Publish CSAR package') {
            steps {
                script {
                    // Upload to artifactory
                    withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                            string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                            string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                            usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                        arm.setUrl("https://arm.seli.gic.ericsson.se/", "$API_TOKEN_EEA")
                        arm.setRepo('proj-eea-internal-generic-local')
                        arm.deployArtifact( 'csarworkdir/csar-package-$INT_CHART_VERSION.csar', 'csar-package-$INT_CHART_VERSION.csar')
                    }
                }
            }
        }

        stage('Run tests') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    sh '''
                        #!/bin/bash
                        rm -f $WORKSPACE/image_properties.yaml
                        rm -f $WORKSPACE/chart_names
                        rm -f $WORKSPACE/csar_contents
                        rm -f $WORKSPACE/csar_images
                        rm -f $WORKSPACE/docker_images
                        unzip -p $WORKSPACE/csarworkdir/csar-package-${INT_CHART_VERSION}.csar Files/images.txt > $WORKSPACE/csar_images
                        unzip -l $WORKSPACE/csarworkdir/csar-package-${INT_CHART_VERSION}.csar > $WORKSPACE/csar_contents
                        if grep -q Files/images.txt $WORKSPACE/csar_contents; then
                            echo "Files/images.txt found!"
                        else
                            echo "Files/images.txt not found!"
                            exit 1
                        fi
                        if grep -q  Files/images/docker.tar $WORKSPACE/csar_contents; then
                            echo " Files/images/docker.tar found!"
                        else
                            echo " Files/images/docker.tar not found!"
                            exit 1
                        fi
                        cd $WORKSPACE/csarworkdir/scripts
                        ls -l
                        for filename in $(find .  -type f -print )
                        do
                            echo "$filename"
                            if grep -q $filename $WORKSPACE/csar_contents; then
                                echo "$filename found in the CSAR package!"
                            else
                                echo "$filename is not found in the CSAR package!"
                                exit 1
                            fi
                        done
                        CHART_LOC=$WORKSPACE/csarworkdir/charts
                        for charts in $(find $CHART_LOC -name '*crd*.tgz' -exec basename {} \\;); do
                            for prodinfo in $(tar -tf $CHART_LOC/eric-eea-int-helm-chart-*.tgz --wildcards */$charts); do
                                YAML_TO_UNTAR=$(echo $prodinfo | sed -e 's/\\/eric-crd.*$//');
                                tar -C $CHART_LOC/ -xzf $CHART_LOC/eric-eea-int-helm-chart-*.tgz $YAML_TO_UNTAR/eric-product-info.yaml;
                                echo $charts $YAML_TO_UNTAR >> $WORKSPACE/chart_names;
                            done
                        done
                    '''
                    script {
                        def list = readFile("$WORKSPACE/chart_names").readLines()
                        list.each {
                            env.CHART_NAME = "$WORKSPACE/csarworkdir/charts/" + it.split(/ /)[0].trim()
                            env.PRODUCT_INFO_LOCATION = "$WORKSPACE/csarworkdir/charts/" + it.split(/ /)[1].trim()
                            sh "$WORKSPACE/adp-app-staging/bob/bob -r $WORKSPACE/cnint/bob-rulesets/csar_build.yaml csar-validation"
                        }
                    }
                    sh '''
                        for chartname in `cat $WORKSPACE/docker_images`; do
                            if grep -q $chartname $WORKSPACE/csar_images; then
                                echo "found"
                            else
                                echo "$chartname not found"
                                exit 1
                            fi
                        done
                    '''
                }
            }
        }
    }

    post {
        failure {
            script {
                if (params.GERRIT_REFSPEC != '') {
                    env.GERRIT_MSG = "Build Failed ${BUILD_URL}: FAILURE"
                    sendMessageToGerrit(params.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }
        success {
            script {
                if (params.GERRIT_REFSPEC != '') {
                    env.GERRIT_MSG = "Build Successful ${BUILD_URL}: SUCCESS"
                    sendMessageToGerrit(params.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }
        cleanup {
            cleanWs()
        }
    }
}
