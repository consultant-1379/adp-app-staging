@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def git = new GitScm(this, 'EEA/adp-app-staging')

pipeline {
    agent{
        node {
            label 'master'
        }
    }

    options{
      skipDefaultCheckout()
      buildDiscarder(logRotator(daysToKeepStr: "7"))
    }

    triggers {
        gerrit (
            serverName: 'GerritCentral',
            gerritProjects: [[
                compareType: 'PLAIN',
                pattern: 'EEA/adp-app-staging',
                branches: [[ compareType: 'PLAIN', pattern: env.MAIN_BRANCH ]],
                filePaths: [[ compareType: 'ANT', pattern: 'pipelines/**' ],
                    [ compareType: 'ANT', pattern: 'technicals/**/*.Jenkinsfile' ],
                    [ compareType: 'ANT', pattern: 'tests/**/*.Jenkinsfile' ]],
                disableStrictForbiddenFileVerification: false,
                topics: [[ compareType: 'REG_EXP', pattern: '^((?!^inca$).)*$' ]]
            ]],
            triggerOnEvents:  [
                [
                    $class              : 'PluginPatchsetCreatedEvent',
                    excludeDrafts       : true,
                    excludeTrivialRebase: false,
                    excludeNoCodeChange : false
                ],
                [
                    $class                      : 'PluginDraftPublishedEvent'
                ]
            ]
        )
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

        stage('Checkout'){
            steps{
                script{
                    git.checkoutRefSpec("${GERRIT_REFSPEC}","FETCH_HEAD", 'adp-app-staging')
                }
            }
        }

        stage('Jenkins file linter') {
            steps {
                dir('adp-app-staging') {
                    sh './technicals/shellscripts/jenkinsfile_validator.sh'
                }
            }
        }

        stage('Validate daysToKeep or numToKeep') {
            steps {
                dir('adp-app-staging') {
                    script {
                        sh(
                            script: "git diff-tree --no-commit-id --name-only -r HEAD --diff-filter=ACMRT -- *.Jenkinsfile > changed_Jenkinsfiles"
                        )
                        def changedJenkinsFiles = readFile("changed_Jenkinsfiles")
                        if (changedJenkinsFiles.size() != 0){
                            echo "changedJenkinsFiles not null"
                            def files = changedJenkinsFiles.split("\\r?\\n")
                            def result_validation = 0
                            for (filename in files) {
                                try {
                                    sh  """./technicals/shellscripts/validate_numToKeep_or_daysToKeep.sh "${filename}" """
                                }
                                catch (err) {
                                    result_validation = 1
                                    echo "Caught: ${err}"
                                }
                            }
                            if (result_validation != 0){
                                error "${result_validation}"
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
    }
}
