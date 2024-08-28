@NonCPS
def parseJson(def json) {
    new groovy.json.JsonSlurperClassic().parseText(json)
}

pipeline {
    agent {
        label 'productci'
    }
    triggers {
        upstream(upstreamProjects: "cluster-cleanup", threshold: hudson.model.Result.ABORTED)
    }
    stages {
        stage('Check upstream build') {
            when {
                expression { env.MAIN_BRANCH == 'master' }
            }
            steps {
                script {
                    def upstream = currentBuild.rawBuild.getCause(hudson.model.Cause$UpstreamCause)
                    env.UPSTREAM_PROJECT_NAME = upstream?.upstreamProject
                    env.UPSTREAM_PROJECT_BUILD_NUMBER = upstream?.upstreamBuild
                    env.UPSTREAM_PROJECT_BUILD_URL = "${env.JENKINS_URL}job/${env.UPSTREAM_PROJECT_NAME}/${env.UPSTREAM_PROJECT_BUILD_NUMBER}"
                    echo "${env.UPSTREAM_PROJECT_BUILD_URL}"
                }
            }
        }
        stage('Rebuild cluster-cleanup job when ABORTED/CANCEL by Spinnaker') {
            when {
                expression { env.MAIN_BRANCH == 'master' }
            }
            steps {
                script {
                    def jenkinsCredentialsId = 'jenkins-api-token' // Master Jenkins API Token Credential
                    withCredentials([usernamePassword(credentialsId: jenkinsCredentialsId, usernameVariable: 'JENKINS_USER', passwordVariable: 'JENKINS_PASSWORD')]) {
                        def jenkinsBuildUrlJson = sh(script: ''' curl -L --silent --user $JENKINS_USER:$JENKINS_PASSWORD "${UPSTREAM_PROJECT_BUILD_URL}/api/json?tree=actions\\[causes\\[*\\]\\]" ''', returnStdout: true).trim()
                        jenkinsBuildUrlJson = parseJson(jenkinsBuildUrlJson)
                        def causes = jenkinsBuildUrlJson.actions.find { it._class == "jenkins.model.InterruptedBuildAction" }?.causes
                        def abortedBy = causes?.find { it.shortDescription }?.shortDescription
                        if ( abortedBy == "Calling Pipeline was cancelled" || abortedBy == "Aborted by eceaspin" ) {
                            echo "Build was aborted or cancel by upstream job or by Spinnaker user"
                            echo "${abortedBy}"
                            def result_next_build = sh(
                                script: "curl -L -X POST --silent --user $JENKINS_USER:$JENKINS_PASSWORD --insecure ${UPSTREAM_PROJECT_BUILD_URL}/rebuild?autorebuild=true",
                                returnStdout : true
                            )
                        } else {
                            echo "${abortedBy}"
                        }
                    }
                }
            }
        }
    }
}