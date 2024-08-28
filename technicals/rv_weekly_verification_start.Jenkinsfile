@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import com.ericsson.eea4.ci.CiDashboard
import com.ericsson.eea4.ci.CommonUtils

@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def dashboard = new CiDashboard(this)


properties([
    parameters([
        [$class: 'DynamicReferenceParameter',
            choiceType: 'ET_FORMATTED_HTML',
            description: 'weekly_drop_<year>_<week number> e.g. weekly_drop_2023_w7',
            name: 'WEEKLY_DROP_TAG',
            visibleItemCount: 1,
            omitValueField: true,
            script: [$class: 'GroovyScript',
                fallbackScript: [
                    classpath: [],
                    sandbox: false,
                    script: '''<input name='value' value='weekly_drop_2003_w' class='setting-input' type='text'>"'''
                ],
                script: [
                    classpath: [],
                    sandbox: false,
                    script: '''
                        Date now = new Date();
                        int year = now.getYear() + 1900;
                        int week = now.getAt(Calendar.WEEK_OF_YEAR);
                        return "<input name='value' value='weekly_drop_${year}_w${week}' class='setting-input' type='text'>"
                    '''.stripIndent()
                ]
            ]
        ]
    ])
])

pipeline {
    agent {
        node {
            label 'productci'
        }
    }
    options {
        skipDefaultCheckout()
        buildDiscarder(logRotator(daysToKeepStr:'14', artifactDaysToKeepStr: '10'))
    }
    parameters {
        string(name: 'CHART_NAME', description: 'Chart name e.g.: ', defaultValue: 'eric-eea-int-helm-chart')
        string(name: 'CHART_REPO', description: 'Chart repo e.g.: https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm', defaultValue: 'https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/')
        string(name: 'CHART_VERSION', description: 'Chart version e.g.: 1.0.0-1', defaultValue: '')
        string(name: 'WEEKLY_DROP_TAG_MSG', description: 'comment for git tag', defaultValue: 'message for the weekly drop tag')
        booleanParam(name: 'TAG_LATEST', defaultValue: true, description: 'move latest_weekly_drop tag')
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

        stage('Checkout master') {
            steps {
                script {
                    gitadp.checkout(env.MAIN_BRANCH, 'adp-app-staging')
                    gitcnint.checkoutRefSpec("refs/tags/${params.CHART_VERSION}", 'FETCH_HEAD', 'cnint')
                }
            }
        }

        stage('Prepare bob') {
            steps {
                dir('adp-app-staging') {
                    checkoutGitSubmodules()
                }
            }
        }

        stage('Init dashboard execution') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    script {

                        //TODO enable after dasboard release
                        //dashboard.setIhcChangeType(dashboard.ihcChangeTypeNewWeeklyDropRv)
                        dashboard.setIhcChangeType('')
                        echo "start execution"
                        dashboard.startExecution("rv-loops","${env.BUILD_URL}","${params.WEEKLY_DROP_TAG}","${params.CHART_VERSION}")
                    }
                }
            }
        }

        stage('Set weekly drop tag') {
            steps {
                dir('cnint') {
                    script {
                        // set WEEKLY_DROP_GIT_TAG tag to the version being tested
                        gitcnint.createOrMoveRemoteGitTag(env.WEEKLY_DROP_TAG, env.WEEKLY_DROP_TAG_MSG)
                        weeklyTag = gitcnint.checkRemoteGitTagExists(env.WEEKLY_DROP_TAG)
                        echo "WEEKLY_DROP_TAG commit: ${weeklyTag}"
                    }
                }
            }
        }

        stage('Set latest_weekly_drop tag') {
            when {
                expression { params.TAG_LATEST == true }
            }
            steps {
                dir('cnint') {
                    script {
                        def latestTag = 'latest_weekly_drop'
                        // set  tag to the version
                        gitcnint.createOrMoveRemoteGitTag(latestTag, env.WEEKLY_DROP_TAG_MSG)
                        getLatestTag = gitcnint.checkRemoteGitTagExists(latestTag)
                        echo "WEEKLY_DROP_GIT_TAG commit: ${getLatestTag}"
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
