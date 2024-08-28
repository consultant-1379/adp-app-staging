@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.Artifactory

pipeline {
    options { buildDiscarder(logRotator(daysToKeepStr: '30', artifactNumToKeepStr: "30"))}
    agent { node { label "productci" }}
    parameters {
        string(name: 'INT_CHART_VERSION', description: 'Chart version e.g.: 1.0.0-1 or master', defaultValue: 'master')
    }
    environment {
        HELM_REPO_URL = 'https://arm.seli.gic.ericsson.se'
        HELM_REPO = 'proj-eea-drop-generic-local'
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

        stage('Checkout cnint') {
            steps {
                script {
                    new GitScm(this, 'EEA/cnint').checkout(env.INT_CHART_VERSION, 'cnint')
                    if (env.INT_CHART_VERSION == 'master') {
                        dir('cnint') {
                            def data = readYaml file: 'eric-eea-int-helm-chart/Chart.yaml'
                            env.INT_CHART_VERSION = data.version
                            echo "env.INT_CHART_VERSION: ${env.INT_CHART_VERSION}"
                        }
                    }
                }
            }
        }

        stage('Prepare Bob') {
            steps {
                dir('cnint') {
                    checkoutGitSubmodules()
                }
            }
        }

        stage('CBO Age Report') {
            steps {
                dir('cnint') {
                    withCredentials([
                        usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                        usernamePassword(credentialsId: 'ECEAART_SEROGIC_API_KEY', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
                        usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
                        string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP')
                    ]) {
                        // the CBOS tool needs this credentials.yaml file, so we create it:
                        sh '''
cat << END > credentials.yaml
repositories:
- url: https://arm.rnd.ki.sw.ericsson.se/artifactory/
  username: ${USER_ARM}
  password: ${API_TOKEN_EEA}
- url: https://arm.sero.gic.ericsson.se/artifactory/
  username: ${DOCKER_USERNAME_SERO}
  password: ${DOCKER_PASSWORD_SERO}
- url: https://armdocker.rnd.ericsson.se/artifactory/
  username: ${USER_ARM}
  password: ${API_TOKEN_EEA}
- url: https://arm.seli.gic.ericsson.se/artifactory/
  username: ${USER_ARM}
  password: ${API_TOKEN_EEA}
- url: https://serodocker.sero.gic.ericsson.se
  username: ${DOCKER_USERNAME_SERO}
  password: ${DOCKER_PASSWORD_SERO}
- url: https://selndocker.mo.sw.ericsson.se
  username: ${DOCKER_USERNAME_SERO}
  password: ${DOCKER_PASSWORD_SERO}
END
                        '''
                        sh './bob/bob init'
                        sh './bob/bob lint-integration-helm:dependency-update -r bob-rulesets/input-sanity-check-rules.yaml'
                        // extract crd charts to the eric-eea-int-helm-chart/charts folder
                        sh '''
                            CHARTS=eric-eea-int-helm-chart/charts
                            for tar in $(ls $CHARTS/); do
                                if (tar tvf $CHARTS/$tar | grep "crd.*tgz"); then
                                    tar -C $CHARTS/ -xvf $CHARTS/$tar --wildcards "*crd*.tgz" --transform="s/.*\\///";
                                fi;
                            done
                        '''
                        sh './bob/bob cbo -r bob-rulesets/input-sanity-check-rules.yaml >cbos_age_tool.log'
                        archiveArtifacts artifacts: "cbos_age_tool.log", allowEmptyArchive: true
                        archiveArtifacts artifacts: "cbos-age-tool_exit-code", allowEmptyArchive: true
                    }
                }
            }
        }

        stage('Adding cbOsVersion') {
            steps {
                dir('cnint') {
                    script {
                    withCredentials([
                        usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                        usernamePassword(credentialsId: 'ECEAART_SEROGIC_API_KEY', usernameVariable: 'DOCKER_USERNAME_SERO', passwordVariable: 'DOCKER_PASSWORD_SERO'),
                        usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
                        string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                        string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')
                        ]) {
                            def json_filename = sh(script: 'ls cbos-age-report-eric-eea-int-helm-chart*json', returnStdout: true).trim()
                            def html_filename = sh(script: 'ls cbos-age-report-eric-eea-int-helm-chart*html', returnStdout: true).trim()
                            println( "#"+json_filename+"#")
                            println( "#"+html_filename+"#")
                            def data = readJSON file: json_filename
                            def arm = new Artifactory(this, "${HELM_REPO_URL}/", "${API_TOKEN_EEA}")
                            arm.setRepo("${HELM_REPO}")
                            arm.downloadArtifact("csar-package-${env.INT_CHART_VERSION}.content.txt", "csar-package-${env.INT_CHART_VERSION}.content.txt")
                            def content_file = readFile "csar-package-${env.INT_CHART_VERSION}.content.txt"
                            def final_data_map = [:]

                            //Read the JSON file and create a MAP of data.
                            data.microServices.each { ms ->
                                if(ms.serviceName != "eric-eea-int-helm-chart") {
                                    ms.imagesInfo.each { imageInfo ->
                                        def imageName = imageInfo.imageName
                                        def imageVersion = imageInfo.imageVersion
                                        def cbosVersion = imageInfo.cbOsVersion
                                        def lineFromContentFile = sh(script: "grep \"${imageName}:${imageVersion}\" csar-package-${env.INT_CHART_VERSION}.content.txt || true", returnStdout: true)
                                        if(lineFromContentFile) {
                                            lineFromContentFile.split("\n").each {
                                                final_data_map.put(it, "$it '$cbosVersion'")
                                            }
                                        }
                                    }
                                }
                            }

                            //Compare the content.txt with the map and update a new file.
                            def fileWriter = []
                            content_file.split("\n").each { line ->
                                if(final_data_map.get(line) != null) {
                                    fileWriter.add(final_data_map.get(line))
                                } else {
                                    fileWriter.add(line)
                                }
                            }
                            def appendingdata = fileWriter.join("\n")
                            writeFile file: "csar-package-${env.INT_CHART_VERSION}.content_updated.txt", text: appendingdata
                            //Uploading content.txt next to the CSAR
                            arm.setRepo('proj-eea-drop-generic-local')
                            arm.deployArtifact("csar-package-${env.INT_CHART_VERSION}.content_updated.txt", "csar-package-${env.INT_CHART_VERSION}.content.txt")

                            //Uploading the Json and HTML files to reports-generic-local
                            arm.setRepo('proj-eea-reports-generic-local/eea4')
                            arm.deployArtifact("$json_filename", "$json_filename")
                            arm.deployArtifact("$html_filename", "$html_filename")
                        }
                    }
                }
            }
        }

        stage('CBOS age tool exit code check') {
            steps {
                dir('cnint') {
                    script {
                      def exitCode = sh script: 'cat cbos-age-tool_exit-code', returnStdout: true
                      exitCode = exitCode.trim()
                      echo "cbos-age-tool exit code: ${exitCode}"
                      archiveArtifacts "cbos-age-report-eric-eea-int-helm-chart*"
                      if (exitCode == '0') {
                      echo "OK: all images are based on the latest CBOS version."
                      } else if (exitCode == '1') {
                      echo "Note: there are images that are less than 6 weeks old CBOS version."
                      } else {
                          switch (exitCode) {
                              case '2':
                                 echo "There are images with more than 6 weeks old CBOS version!"
                                 break
                              case '-1':
                                 echo "There are validation / known runtime errors! Users are responsible to fix these."
                                 break
                              case '-2':
                                 echo "There are unknown runtime errors! CI/CD team is responsible to fix these."
                                 break
                           }
                           error "CBO Age report failed with exit code ${exitCode}"
                        }
                    }
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
