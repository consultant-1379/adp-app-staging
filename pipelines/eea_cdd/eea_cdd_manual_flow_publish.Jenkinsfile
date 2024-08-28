@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.Artifactory
import groovy.transform.Field

@Field def gitcdd = new GitScm(this, 'EEA/cdd')
@Field def arm = new Artifactory(this, "https://arm.seli.gic.ericsson.se/", "API_TOKEN_EEA")

pipeline {
    options {
        disableConcurrentBuilds()
        buildDiscarder(logRotator(daysToKeepStr: '14', artifactDaysToKeepStr: '7'))
    }
    agent {
        node {
            label 'productci'
        }
    }
    parameters {
        string(name: 'CHART_VERSION', description: 'Chart version e.g.: 0.1.0-0', defaultValue: '')
        string(name: 'GERRIT_REFSPEC',  description: 'Gerrit Refspec of the cdd git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'SPINNAKER_TRIGGER_URL', description: 'Spinnaker pipeline triggering url', defaultValue: '')
        string(name: 'SPINNAKER_ID', description: "The spinnaker execution's id", defaultValue: '')
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

        stage('Gerrit message') {
            when {
              expression { params.GERRIT_REFSPEC != '' }
            }
            steps {
                script {
                    env.GERRIT_MSG = "Build Started ${BUILD_URL}"
                    sendMessageToGerrit(params.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }

        stage('Checkout') {
            steps {
                script {
                    gitcdd.checkout('master', '')
                }
            }
        }

        stage('Ruleset change checkout') {
            when {
                expression { params.GERRIT_REFSPEC != '' }
            }
            steps{
                script{
                    def gitId = sh(
                        script: "echo ${GERRIT_REFSPEC} | cut -f4 -d'/'",
                        returnStdout : true
                    ).trim()
                    echo "${gitId}"   //DEBUG
                    def git_result = sh(
                        script: "ssh -o StrictHostKeyChecking=no -p ${GERRIT_PORT} ${GERRIT_HOST} gerrit query --current-patch-set ${gitId} --format json --files > gerrit_result"
                    )
                    def filePath = readFile "${WORKSPACE}/gerrit_result"
                    def lines = filePath.readLines()
                    def data = readJSON text: lines[0]

                    data.currentPatchSet.files.each { file_rec ->
                        print file_rec
                        if (file_rec.file  == "bob-rulesets/ruleset2.0.yaml") {
                            withCredentials([usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                                sh 'git fetch https://${GERRIT_USERNAME}:${GERRIT_PASSWORD}@${GERRIT_HOST}/a/EEA/cdd ${GERRIT_REFSPEC} && git cherry-pick FETCH_HEAD'
                            }
                        }
                        echo "${file_rec.file} changed"
                    }
                }
            }
        }

        stage('Prepare') {
            steps {
                checkoutGitSubmodules()
            }
        }

        stage('Init') {
            steps {
                script {
                    env.VERSION_WITHOUT_HASH = sh(script: 'echo "$CHART_VERSION" | rev | cut -d"-" -f2-  | rev', returnStdout: true).trim()
                    if (params.GERRIT_REFSPEC != null && params.GERRIT_REFSPEC != '') {
                        def tokens = params.GERRIT_REFSPEC.split("/")
                        if (tokens.length == 5) {
                            def link = getGerritLink(params.GERRIT_REFSPEC)
                            currentBuild.description = link
                        } else {
                            def link = '<a href="' + env.BUILD_NUMBER + '/console">' + params.GERRIT_REFSPEC + '</a>'
                            currentBuild.description = link
                        }
                    } else {
                        def link = '<a href="' + env.BUILD_NUMBER + '/console">' + params.CHART_NAME + ':' + params.CHART_VERSION + '</a>'
                        currentBuild.description = link
                    }
                    if ( params.SPINNAKER_ID != '' ) {
                        currentBuild.description += '<br><a href="https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/details/' + params.SPINNAKER_ID + '">Spinnaker URL: ' + params.SPINNAKER_ID + '</a>'
                    }
                }
            }
        }

        stage('Resource locking - Publish Cdd Helm Chart') {
            options {
                lock resource: null, label: "cdd-publish", quantity: 1, variable: "system"
            }
            stages {
                stage('Publish CDD Helm Chart') {
                    steps {
                        // Generate integration helm chart
                        withCredentials([
                                        usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                        usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD'),
                                        string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                        string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                            sh 'bob/bob -r bob-rulesets/ruleset2.0.yaml publish'
                        }
                    }
                }
            }
        }

        stage('Publish CDD package') {
            steps {
                script {
                    // Download the CDD package from internal repository and then upload it to drop one
                    withCredentials([string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                        // Download the CDD from internal repository
                        sh 'curl -H "X-JFrog-Art-Api: $API_TOKEN_EEA" -fO https://arm.seli.gic.ericsson.se/artifactory/proj-eea-internal-generic-local/swdp-cdd-$CHART_VERSION.tar.gz'
                        sh """
                            set -x
                            ls -la
                            tar xzvf "swdp-cdd-\${CHART_VERSION}.tar.gz"
                            currDir=\$(pwd)
                            cd swdp-cdd/product/jenkins/
                            for fileName in \$(ls *.xml)
                            do
                                fileNameWithoutHash="\${fileName/\${CHART_VERSION}/\${VERSION_WITHOUT_HASH}}"
                                fileNameBase="\${fileName/-\${CHART_VERSION}.xml/}"
                                mv "\${fileName}" "\${fileNameWithoutHash}"
                                sed -i "s#<description>\${fileNameBase}:\${CHART_VERSION}</description>#<description>\${fileNameBase}:\${VERSION_WITHOUT_HASH}</description>#" "\${fileNameWithoutHash}"
                            done
                            cd "\${currDir}"
                            tar czvf swdp-cdd-\$VERSION_WITHOUT_HASH.tar.gz swdp-cdd
                        """
                        // Upload the CDD package to the drop repository
                        arm.setUrl("https://arm.seli.gic.ericsson.se/", "$API_TOKEN_EEA")
                        arm.setRepo('proj-eea-drop-generic-local')
                        arm.deployArtifact('swdp-cdd-$VERSION_WITHOUT_HASH.tar.gz', 'swdp-cdd-$VERSION_WITHOUT_HASH.tar.gz')
                    }
                }
            }
        }

        stage('Archive artifact.properties') {
            steps {
                // Archive artifact.properties generated by product and documentation build so Spinnaker can read the parameters
                archiveArtifacts 'artifact.properties'
            }
        }
    }

    post {
        always {
            script {
                if (params.GERRIT_REFSPEC != '') {
                    env.GERRIT_MSG = "Build result ${BUILD_URL}: ${currentBuild.result}"
                    sendMessageToGerrit(params.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }
        cleanup {
            cleanWs()
        }
    }
}
