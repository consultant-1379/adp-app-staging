@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import com.ericsson.eea4.ci.Artifactory
import com.ericsson.eea4.ci.ClusterLockUtils

@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitdoc = new GitScm(this, 'EEA/eea4_documentation')
@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def arm = new Artifactory(this, "https://arm.seli.gic.ericsson.se/", "API_TOKEN_EEA")

def resource_lock

pipeline {
    agent {
        node {
            label 'productci'
        }
    }
    options {
        buildDiscarder(logRotator(daysToKeepStr: '14', artifactDaysToKeepStr: '7'))
        disableConcurrentBuilds()
        skipDefaultCheckout()
    }
    parameters {
        string(name: 'GERRIT_REFSPEC',  description: 'Gerrit Refspect of the eea4_documentation git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
    }
    triggers {
        gerrit (
            serverName: 'GerritCentral',
            gerritProjects: [[
                compareType: 'PLAIN',
                pattern: 'EEA/eea4_documentation',
                branches: [[ compareType: 'PLAIN', pattern: env.MAIN_BRANCH ]],
                disableStrictForbiddenFileVerification: false,
                topics: [[ compareType: 'REG_EXP', pattern: '^((?!^inca$).)*$' ]]
            ]],
            triggerOnEvents: [
                [
                    $class: 'PluginCommentAddedContainsEvent',
                    commentAddedCommentContains: '.*MERGE.*'
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

        stage ('Check bob-rulesets/* reviewers') {
            steps {
                script {
                    reviewersList = gitdoc.listGerritMembers('EEA4\\ CI\\ team')
                    changedFiles = gitdoc.getGerritQueryPatchsetChangedFiles("${GERRIT_REFSPEC}")
                    changedFiles.each { file ->
                        print file
                        if ( file.startsWith("bob-rulesets/") && !reviewersList.contains("${GERRIT_EVENT_ACCOUNT_EMAIL}")){
                            error "Need a Code-Review from the EEA4 CI team Gerrit Group member for the bob-rulesets/* changes! Members:\n${reviewersList}"
                        } else {
                            echo "${GERRIT_EVENT_ACCOUNT} found in the EEA4 CI team Gerrit Group"
                        }
                    }
                }
            }
        }

        stage('Checkout - adp-app-staging') {
           steps {
                script {
                    gitadp.checkout(env.MAIN_BRANCH, 'adp-app-staging')
                }
            }
        }

        stage('Prepare') {
            steps {
                dir('adp-app-staging') {
                    script {
                        gitadp.checkoutSubmodules()
                    }
                }
            }
        }

        stage('Checkout - eea4_documentation') {
            options {
                lock resource: null, label: "doc-build", quantity: 1, variable: 'resource'
            }
            steps {
                script {
                    lock('resource-relabel') {
                        resource_lock = new ClusterLockUtils(this)
                        resource_lock.setReserved('publish-ongoing', env.resource)
                        def note = "eea4-documentation - " +  env.BUILD_NUMBER
                        echo 'Note: ' + note
                        resource_lock.setNoteForResource( env.resource, note )
                        gitdoc.checkoutRefSpec('${GERRIT_REFSPEC}','FETCH_HEAD','eea4_documentation')
                    }
                }
            }
        }

        stage('Checkout - cnint') {
            steps {
                script {
                    gitcnint.checkout(env.MAIN_BRANCH,'cnint')
                }
            }
        }

        stage('Rebase - eea4_documentation') {
            steps {
                dir('eea4_documentation') {
                    script {
                        def git_id = sh(
                            script: "git log --format=\"%H\" -n 1",
                            returnStdout : true
                        )trim()
                        echo "git id=${git_id}"
                        env.GIT_ID = "${git_id}"
                        sh 'git fetch'
                        sh 'git rebase origin/master'
                    }
                }
            }
        }

        stage('Build and generate DXP packages') {
            steps {
                dir('adp-app-staging') {
                    script {
                        withCredentials([string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN'),
                            usernamePassword(credentialsId: 'eceadcm', usernameVariable: 'DITACMSAPI_USER', passwordVariable: 'DITACMSAPI_PASSWORD')]){
                            env.CHART_YAML_PATH = "${WORKSPACE}/cnint/eric-eea-int-helm-chart/Chart.yaml"
                            env.HELM_CHART_VERSION = sh(script:"python3 ${WORKSPACE}/adp-app-staging/technicals/pythonscripts/helm_chart_version_parser.py -p \"${env.CHART_YAML_PATH}\"", returnStdout: true).trim()
                            env.DOC_PATH = "${WORKSPACE}/eea4_documentation"
                            sh './bob/bob -r ${WORKSPACE}/eea4_documentation/bob-rulesets/docreviewOK.yaml generate-dxp-docs'
                        }
                    }
                }
            }
        }

        stage('Submit changes') {
            steps {
                dir ('eea4_documentation'){
                    // Commit changes
                    script {
                        // Submit changes
                        withCredentials([usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_USER_PASSWORD')]){
                            sh(
                                script: """
                                sshpass -p $GIT_USER_PASSWORD ssh -o StrictHostKeyChecking=no -p ${GERRIT_PORT} $GIT_USER@${GERRIT_HOST} gerrit review --verified +1 --code-review +2 --submit --project EEA/eea4_documentation ${env.GIT_ID}
                                """
                            )
                        }
                    }
                }
            }
        }

        stage('Archieve build folder') {
            steps {
                dir('eea4_documentation') {
                    script {
                        sh "tar -czvf doc_build_\$(date +%Y%m%d_%H%M).tar.gz doc_build/"
                        archiveArtifacts "doc_build_*.tar.gz"
                    }
                }
            }
        }

        stage('Archive artifact.properties') {
            steps {
                script {
                    /*def logContent = Jenkins.getInstance()
                    .getItemByFullName(env.JOB_NAME)
                    .getBuildByNumber(
                    Integer.parseInt(env.BUILD_NUMBER))
                    .logFile.text*/
                    def logContent = "BUILD_NUMBER=" + env.BUILD_NUMBER + "\n" +
                                     "DOC_COMMIT_ID=" + env.GIT_ID
                    // copy the log in the job's own workspace
                    writeFile file: "artifact.properties", text: logContent
                }
                archiveArtifacts 'artifact.properties'
            }
        }
    }

    post {
        always {
            script {
                lock('resource-relabel') {
                    if (currentBuild.result != 'SUCCESS') {
                        def manager = org.jenkins.plugins.lockableresources.LockableResourcesManager.get()
                        def resources =  manager.getResourcesWithLabel('doc-build', null)
                        def note = "eea4-documentation - " +  env.BUILD_NUMBER
                        resources.each {
                            if (it.getNote() == note) {
                                echo "Reserved resource found ${it}"
                                echo "isReserved: ${it.isReserved()}"
                                it.setNote('')
                            }
                        }
                        manager.recycle(resources)
                    }
                }
            }
        }
        cleanup {
            cleanWs()
        }
    }
}
