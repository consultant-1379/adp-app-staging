@Library('ci_shared_library_eea4') _
import com.ericsson.eea4.ci.Artifactory
import groovy.transform.Field

@Field def arm = new Artifactory(this, "https://arm.seli.gic.ericsson.se/",  "API_TOKEN_EEA")

pipeline{
    options {
      buildDiscarder(logRotator(daysToKeepStr: '14', artifactDaysToKeepStr: '7'))
    }
    agent {
      node { label "productci" }
    }
    parameters {
        string(name: 'INT_CHART_REPO', description: 'Chart repo e.g.: https://arm.seli.gic.ericsson.se/artifactory/proj-eea-internal-generic-local', defaultValue: 'https://arm.seli.gic.ericsson.se/artifactory/proj-eea-internal-generic-local')
        string(name: 'INT_CHART_VERSION', description: 'Chart version e.g.: 1.0.0-1', defaultValue: '')
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
        stage("Delete artifact") {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                     string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                     usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                        // check if the file exists (200 is OK)
                        def csar_filename = "csar-package-" + "$INT_CHART_VERSION" + ".csar"
                        def return_code = sh(script: 'curl -o /dev/null --silent -Iw "%{http_code}" -H "X-JFrog-Art-Api: $API_TOKEN_EEA" ' + "$INT_CHART_REPO" + "/" + csar_filename, , returnStdout: true).trim()

                        if (return_code == '200') {
                            println('item exists, deleting')
                            arm.setUrl("https://arm.seli.gic.ericsson.se/",  "$API_TOKEN_EEA")
                            arm.setRepo('proj-eea-internal-generic-local')
                            arm.deleteArtifact(csar_filename)
                        }
                        if (return_code == '404') {
                            println('item does not exist')
                        }
                        println('item check return code: ' + return_code)

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
