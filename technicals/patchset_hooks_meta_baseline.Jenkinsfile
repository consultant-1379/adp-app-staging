@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import com.ericsson.eea4.ci.CommonUtils

@Field def gitmeta = new GitScm(this, 'EEA/project-meta-baseline')
@Field def git = new GitScm(this, 'EEA/adp-app-staging')
@Field def cmutils = new CommonUtils(this)

pipeline {
    agent {
        node {
            label 'productci'
        }
    }
    options {
      disableConcurrentBuilds()
      skipDefaultCheckout()
      buildDiscarder(logRotator(daysToKeepStr: "7"))
    }

    triggers {
        gerrit (
            serverName: 'GerritCentral',
            gerritProjects: [[
                    compareType: 'PLAIN',
                    pattern: 'EEA/project-meta-baseline',
                    branches: [[ compareType: 'PLAIN', pattern: env.MAIN_BRANCH ]],
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
                    $class                      : 'PluginCommentAddedContainsEvent',
                    commentAddedCommentContains : '.*rebuild.*'
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

        stage('Checkout - scripts') {
            steps {
                script {
                    git.sparseCheckout("technicals/")
                }
            }
        }

        stage('Checkout - project-meta-baseline') {
            steps {
                script {
                    gitmeta.checkoutRefSpec("${GERRIT_REFSPEC}", "FETCH_HEAD", 'project-meta-baseline')
                }
            }
        }
        stage('Check Ruleset') {
            steps {
                script {
                    dir('project-meta-baseline') {
                        def commitAuthor = gitmeta.getCommitAuthor()
                        if ( "${commitAuthor}".toUpperCase() != "ECEAGIT" ) {
                            echo "Commit Author is ${commitAuthor}\nCheck ruleset files will start:"
                            gitmeta.checkRulesetRepo("${GERRIT_REFSPEC}")
                        } else {
                            echo "Commit Author is ${commitAuthor}\nSkip ruleset files check"
                        }
                    }
                }
            }
        }
        stage('Prepare') {
            steps {
                dir('project-meta-baseline') {
                    checkoutGitSubmodules()
                }
            }
        }
        stage('Rulesets DryRun') {
            steps {
                dir('project-meta-baseline') {
                    script {
                        rulesetsDryRun()
                    }
                }
            }
        }

        stage('Rulesets Validations') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE'){
                    script {
                        build job: "ruleset-change-validate", parameters: [
                            booleanParam(name: 'dry_run', value: false),
                            stringParam(name: 'GERRIT_PROJECT', value : "${env.GERRIT_PROJECT}"),
                            stringParam(name: 'GERRIT_REFSPEC', value : "${env.GERRIT_REFSPEC}"),
                            stringParam(name: 'GERRIT_HOST', value : "${env.GERRIT_HOST}"),
                            stringParam(name: 'GERRIT_BRANCH', value : "${env.GERRIT_BRANCH}"),
                            stringParam(name: 'GERRIT_PORT', value : "${env.GERRIT_PORT}"),
                            stringParam(name: 'GERRIT_CHANGE_URL', value : "${env.GERRIT_CHANGE_URL}"),
                            stringParam(name: 'GERRIT_CHANGE_NUMBER', value : "${env.GERRIT_CHANGE_NUMBER}"),
                        ]
                    }
                }
            }
        }

        stage('Clean') {
            steps {
                dir('project-meta-baseline') {
                    sh 'bob/bob clean'
                }
            }
        }
        stage('Bob - prepare') {
            steps {
                dir('project-meta-baseline') {
                    withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                 string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                 string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                 usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                        sh 'bob/bob prepare-common'
                    }
                }
            }
        }
        stage('Bob lint') {
            steps {
                script {
                    dir('project-meta-baseline') {
                        withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                     string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                     string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                                     usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                            sh 'bob/bob lint-meta:helm'
                        }
                    }
                }
            }
        }

        stage('Check values.yaml package_category') {
            steps{
                dir('project-meta-baseline'){
                    withCredentials([usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GIT_USER', passwordVariable: 'PASSWORD' )]) {
                        script {
                            def changedFiles = getGerritQueryPatchsetChangedFiles(params.GERRIT_REFSPEC)
                            def validCategoryList=["test tool","product package"]
                            def result = true
                            changedFiles.each { file ->
                                if ( file.endsWith("eric-eea-ci-meta-helm-chart/values.yaml" ) ) {

                                    def data = readYaml file: "eric-eea-ci-meta-helm-chart/values.yaml"
                                    data.each { metaValue ->
                                        echo ("metaValue ${metaValue.key}")
                                        if (metaValue.key == "global" ) { return }  // skip file containing commit message
                                        echo("${metaValue.value.package_category}")
                                        if (metaValue.value.package_category == null || !validCategoryList.contains(metaValue.value.package_category)) {
                                            result = false
                                            echo("${metaValue.key} package_category  should be one of these values ${validCategoryList} ")
                                            return
                                        }

                                    }
                                    if (!result){
                                        error ("Validation for package_category failed")
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
            dir('project-meta-baseline') {
                archiveArtifacts artifacts: '.bob/check-helm/design-rule-check-report.*', allowEmptyArchive: true
                publishHTML (target: [
                    allowMissing: true,
                    alwaysLinkToLastBuild: false,
                    keepAll: true,
                    reportDir: '.bob/check-helm/',
                    reportFiles: 'design-rule-check-report.html',
                    reportName: "Helm Design Rule Check"
                ])
            }
        }
        cleanup {
            cleanWs()
        }
    }
}
