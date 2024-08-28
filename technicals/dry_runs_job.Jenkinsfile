@Library('ci_shared_library_eea4') _

pipeline {
    agent {
        node {
            label 'productci'
        }
    }

    options {
      disableConcurrentBuilds()
      buildDiscarder(logRotator(daysToKeepStr: "7"))
    }

    parameters {
        string(name: 'JOB_NAMES', description: 'List of changed job names', defaultValue:"")
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

        stage('Run dry runs') {
            steps {
                script{
                    def branches = [:]
                    def index = 0
                    "${params.JOB_NAMES}".split(' ').each {name->
                        def jobname = "${name}".trim()
                        if ("${jobname}" != 'dry-runs-job') {
                            branches["branch${index}"] = {
                                build job: "${jobname}", parameters: [booleanParam(name: 'DRY_RUN', value: true)], propagate: true, wait: true
                            }
                            index = index+1
                        }
                    }
                    parallel branches
                }
            }
        }
    }
}
