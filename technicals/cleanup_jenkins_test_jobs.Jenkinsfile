@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.Notifications
import groovy.transform.Field
import jenkins.model.Jenkins
import hudson.model.Job
import java.nio.file.Files
import java.nio.file.Paths

@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field notif = new Notifications(this)

def whitelist = []
def patterns = ["^test-.*", "^e[a-z]{6}-.*", "^x[a-z]{6}-.*", "^z[a-z]{6}-.*", "^eth[a-z]{6}-.*","^test_.*" , "^e[a-z]{6}_.*","^x[a-z]{6}_.*","^z[a-z]{6}_.*","^eth[a-z]{6}_.*" ].join('|')

pipeline {
    agent {
        node {
            label 'productci'
        }
    }

    options {
        skipDefaultCheckout()
    }

    triggers {
        cron('0 10 * * 0')
    }

    parameters {
        booleanParam(name: 'LIST_ONLY', description: 'Do not delete jobs and their artifacts, only listing enabled e.g.: false', defaultValue: false)
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

        stage('Checkout adp-app-staging') {
            steps {
                script{
                    gitadp.checkout('master', '')
                }
            }
        }

        stage('Run when run in Jenkins master') {
            when {
                expression { env.MAIN_BRANCH == 'master' }
            }
            stages {
                stage('Read whitelist') {
                    steps {
                        script {
                            def data = readYaml file: "${WORKSPACE}/technicals/cleanup_jenkins_test_jobs_whitelist.yaml"
                            data.whitelist.each { job ->
                                whitelist.add(job)
                            }
                        }
                    }
                }

                stage('Delete jobs') {
                    steps {
                        script {
                            // Collect all jobes
                            def allJobs = Jenkins.instance.getAllItems(Job.class)

                            // Define the time limit (six months ago)
                            def expirationLimit = 180
                            // Filter and delete jobs
                            allJobs.each { job ->
                                String jobName = job.getName()
                                if (!whitelist.contains(jobName)) {
                                    if (job.name.matches(patterns)) {
                                        def lastBuild = job.getLastBuild()
                                        if (lastBuild) {
                                            def lastBuildTime = lastBuild.getTime()
                                            if (new Date() - lastBuildTime > expirationLimit) {
                                                // Delete artifacts
                                                if (!params.LIST_ONLY) {
                                                    job.getBuilds().each { build ->
                                                        build.getArtifacts().each { artifact ->
                                                            Files.deleteIfExists(Paths.get(artifact.getFile().getPath()))
                                                        }
                                                    }
                                                    job.delete()
                                                }

                                                println (params.LIST_ONLY ? "Test job to delete: ${jobName}" : "Deleted job and artifacts: ${jobName}")
                                            }
                                        } else {
                                            String path = env.JENKINS_HOME + "/jobs/" + jobName
                                            def time = new Date((long) new File(path).lastModified())
                                            if (new Date() - time > expirationLimit) {
                                                if (!params.LIST_ONLY) {
                                                    job.delete()
                                                }
                                                println (params.LIST_ONLY ? "Test job to delete: ${job.name}" : "Deleted job: ${jobName}")
                                            }
                                        }
                                    }
                                } else {
                                    echo "${jobName} is in whitelist"
                                }
                            }
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
        failure {
            script {
                def subject = "${env.JOB_NAME} (${env.BUILD_NUMBER}) FAILURE"
                def body_message = "<a href=\"${env.BUILD_URL}\">${env.BUILD_URL}</a><br>Automated cleanup for Jenkins test jobs FAILED. Please check the build"
                notif.sendMail(subject, body_message, "517d5a14.ericsson.onmicrosoft.com@emea.teams.ms", "text/html")
            }
        }
    }
}
