@Library('ci_shared_library_eea4') _

import groovy.json.JsonSlurperClassic
import groovy.transform.Field
import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.Notifications

@Field def gitConfig = new GitScm(this, 'EEA/eea4-ci-config')
@Field def notif = new Notifications(this)
def config

pipeline {
    agent {
        node {
            label 'productci'
        }
    }
    options {
        skipDefaultCheckout()
    }

    parameters {
        string(name: 'KUBECTL_VERSION', description: 'Update repos with specified kubectl version. Can be empty, this case update is skipped.', defaultValue: '')
        string(name: 'HELM_VERSION', description: 'Update repos with specified helm version. Can be empty, this case update is skipped.', defaultValue: '')
        string(name: 'PYTHON_KUBERNETES_VERSION', description: 'Update repos with specified kubernetes python package version. Can be empty, this case update is skipped.', defaultValue: '')
        booleanParam(name: 'DUMMY_RUN', description: 'Skip commit, push and notifications', defaultValue: false)
        string(name: 'CONFIG_REFSPEC', description: "Specify eea4-ci-config refspec for TESTING", defaultValue: '')
    }
    environment {
        YQ_PATH = "yq-4.x"
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

        stage('Get params') {
            steps {
                echo "params.KUBECTL_VERSION: ${params.KUBECTL_VERSION}"
                echo "params.HELM_VERSION: ${params.HELM_VERSION}"
                echo "params.PYTHON_KUBERNETES_VERSION: ${params.PYTHON_KUBERNETES_VERSION}"
                echo "params.DRY_RUN: ${params.DRY_RUN}"
                echo "params.DUMMY_RUN: ${params.DUMMY_RUN}"
            }
        }

        stage('Initial cleanup') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout config') {
            steps {
                script {
                    if (params.CONFIG_REFSPEC) {
                        gitConfig.checkoutRefSpec(params.CONFIG_REFSPEC, 'FETCH_HEAD', 'eea4-ci-config')
                    } else {
                        gitConfig.checkout('master', 'eea4-ci-config')
                    }
                }
            }
        }

        // get projects
        stage('Read uplift config') {
            steps {
                dir('eea4-ci-config') {
                    script {
                        def configStr = readFile "config/kubectl_helm_uplift.json"
                        config = new groovy.json.JsonSlurperClassic().parseText(configStr)
                        echo "config: ${config}"
                    }
                }
            }
        }

        stage('Process repos') {
            steps {
                script {
                    currentBuild.description = ""
                    config.projects.each { project ->
                        processRepos(project).call()
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

// inplace update with yq would cause the whitespaces to be removed (problem with the underlying yaml lib)
// so its necessary to do a diff/patch with tempfiles to preserve them after the change
def updateYaml (String yqPath, String yqSelector, String updateValue, String filePath) {
    // remove whitespaces from original file and save as a tempfile
    sh(script: """${yqPath} eval '.' ${filePath} | tee tmp1.yaml > /dev/null""")
    // update the necessary values and save result as a tempfile
    sh(script: """${yqPath} eval \'(${yqSelector}) = \"${updateValue}\"\' ${filePath} | tee tmp2.yaml > /dev/null""")
    // diff the 2 tempfiles to a patchfile
    sh(script: """diff tmp1.yaml tmp2.yaml | tee patch.patch > /dev/null""")
    // apply the patch to the ORIGINAL file (whitespace changes will be ignored)
    sh(script: """patch -l -i patch.patch ${filePath}""")
    // remove temporary files
    sh(script: """rm -f tmp1.yaml tmp2.yaml patch.patch ${filePath}.orig ${filePath}.rej""")
}

def processRepos (Map project) {
    echo "Processing repo ${project.repo}"
    def repoUpliftResult = "FAILED"
    def repoDir = project.repo.split('/').last()
    def currentRepoGerritRefspec = ''
    def gitObj = new GitScm(this, project.repo)

    return {
        stage("Checkout - ${project.repo}") {
            gitObj.checkout('master', repoDir)
            echo "${project.repo} checked out to ${WORKSPACE}/${repoDir}"
        }

        stage("Uplift versions in ${project.repo}") {
            // get fields from files to be updated by evaluating yq expressions from configfile
            dir(repoDir) {
                catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                    try {
                        def err_msg
                        if (params.KUBECTL_VERSION) {
                            def cmd_kubectl_version = "${env.YQ_PATH} eval \'${project.properties.kubectl_default_version}\' ${project.file_path}"
                            def kubectlVersion = sh(script: cmd_kubectl_version, returnStdout: true).trim()
                            echo "Read current kubectlVersion: ${kubectlVersion}"
                            if (kubectlVersion && kubectlVersion != "null") {
                                if (kubectlVersion!= params.KUBECTL_VERSION) {
                                    updateYaml(env.YQ_PATH, project.properties.kubectl_default_version, params.KUBECTL_VERSION, project.file_path)
                                    echo "Updated ${project.file_path} kubectl version from ${kubectlVersion} to ${params.KUBECTL_VERSION}"
                                } else {
                                    echo "No change in kubectlVersion."
                                }
                            }
                            def cmd_kubectl_versions = "${env.YQ_PATH} eval \'${project.properties.kubectl_versions}\' ${project.file_path}"
                            def kubectlVersions = sh(script: cmd_kubectl_versions, returnStdout: true).trim()
                            echo "Read current kubectlVersions: ${kubectlVersions}"
                            if (kubectlVersions && kubectlVersions != "null") {
                                newKubectlVersions = kubectlVersions + " " + params.KUBECTL_VERSION
                                if (newHelmVersions.trim() != kubectlVersions.trim()) {
                                    updateYaml(env.YQ_PATH, project.properties.kubectl_versions, newKubectlVersions, project.file_path)
                                    echo "Updated ${project.file_path} kubectl versions from ${kubectlVersions} to ${newKubectlVersions}"
                                } else {
                                    echo "No change in kubectlVersions"
                                }
                            }
                        }
                        if (params.HELM_VERSION) {
                            def cmd_helm_version = "${env.YQ_PATH} eval \'${project.properties.helm_default_version}\' ${project.file_path}"
                            def helmVersion = sh(script: cmd_helm_version, returnStdout: true).trim()
                            echo "Read current helmVersion: ${helmVersion}"
                            if (helmVersion && helmVersion != "null") {
                                if (helmVersion != params.HELM_VERSION) {
                                    updateYaml(env.YQ_PATH, project.properties.helm_default_version, params.HELM_VERSION, project.file_path)
                                    echo "Updated ${project.file_path} helm version from ${helmVersion} to ${params.HELM_VERSION}"
                                } else {
                                    echo "No change in helmVersion"
                                }
                            }
                            def cmd_helm_versions = "${env.YQ_PATH} eval \'${project.properties.helm_versions}\' ${project.file_path}"
                            def helmVersions = sh(script: cmd_helm_versions, returnStdout: true).trim()
                            echo "Read current helmVersions: ${helmVersions}"
                            if (helmVersions && helmVersions != "null") {
                                newHelmVersions = helmVersions + " " + params.HELM_VERSION
                                if (newHelmVersions.trim() != helmVersions.trim()) {
                                    updateYaml(env.YQ_PATH, project.properties.helm_versions, newHelmVersions, project.file_path)
                                    echo "Updated ${project.file_path} helm versions from ${helmVersions} to ${newHelmVersions}"
                                } else {
                                    echo "No change in helmVersions"
                                }
                            }
                        }
                        if (params.PYTHON_KUBERNETES_VERSION) {
                            def cmd_python_kubernetes_version = "${env.YQ_PATH} eval \'${project.properties.python_kubernetes_version}\' ${project.file_path}"
                            def pythonKubernetesVersion = sh(script: cmd_python_kubernetes_version, returnStdout: true).trim()
                            echo "Read current pythonKubernetesVersion: ${pythonKubernetesVersion}"
                            if (pythonKubernetesVersion && pythonKubernetesVersion != "null") {
                                if (pythonKubernetesVersion != params.PYTHON_KUBERNETES_VERSION) {
                                    updateYaml(env.YQ_PATH, project.properties.python_kubernetes_version, params.PYTHON_KUBERNETES_VERSION, project.file_path)
                                    echo "Updated ${project.file_path} python kubernetes package version from ${pythonKubernetesVersion} to ${params.PYTHON_KUBERNETES_VERSION}"
                                } else {
                                    echo "No change in pythonKubernetesVersion"
                                }
                            }
                        }
                        // check for empty commit
                        def gitStatus = sh(script: "git status --short", returnStdout: true).trim()
                        echo "git status: ${gitStatus}"
                        if (gitStatus) {
                            repoUpliftResult = "SUCCESS"
                        } else {
                            repoUpliftResult = "SKIPPED"
                            err_msg = "No changes to be commited in ${project.repo}, commit SKIPPED."
                            echo "${err_msg}"
                        }
                    } catch (err) {
                        repoUpliftResult = "FAILED"
                        err_msg = "ERROR uplifting ${project.repo}, details: ${err}"
                        error "${err_msg}"
                    }
                }
            }
        }

        stage("Commit and push changes - ${project.repo}") {
            dir(repoDir) {
                catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                    try {
                        if (repoUpliftResult == "SUCCESS") {
                            if (!params.DUMMY_RUN) {
                                echo "Preparing new commit in ${project.repo}"
                                // -u pathspec: only add updates, not new files
                                gitObj.createPatchset("-u", "[CI] Automated uplift of helm and kubectl versions")
                                def git_id = gitObj.getCommitHashLong()
                                echo "git_id: ${git_id}"
                                currentRepoGerritRefspec = gitObj.getCommitRefSpec(git_id)
                                currentBuild.description += "<br>${project.repo} " + getGerritLink(currentRepoGerritRefspec)
                                echo "ref: ${currentRepoGerritRefspec}"
                                if (project.merge == true) {
                                    echo "merge == True, merging commit"
                                    gitObj.gerritReviewAndSubmit(git_id, '--verified +1 --code-review +2 --submit', project.repo)
                                }
                            } else {
                                echo "params.DUMMY_RUN == True, commit & push skipped for ${project.repo}"
                            }
                        } else if (repoUpliftResult == "SKIPPED") {
                            echo "Stage SKIPPED due to previously skipped stage."
                        } else {
                            echo "Stage SKIPPED due to previous errors for ${project.repo}"
                        }
                    } catch (err) {
                        repoUpliftResult = "FAILED"
                        def err_msg = "ERROR creating commit and pushing to repository in ${project.repo}, details: ${err}"
                        error "Caught: ${err_msg}"
                    }
                }
            }
        }

        stage("Post - ${project.repo}") {
            def bodyMessage = ""
            def header = ""
            if (repoUpliftResult == "SUCCESS") {
                header = "${env.JOB_NAME} (${env.BUILD_NUMBER}) - Kubectl/helm versions updated in ${project.repo} SUCCESSFULLY"
                bodyMessage = "<a href=\"${env.BUILD_URL}\">${env.BUILD_URL}</a><br>Kubectl/helm versions updated in ${project.repo} repository.<br><br>"
                if (!params.DUMMY_RUN) {
                    def gtokens = currentRepoGerritRefspec.split("/")
                    def gerritUrl = "https://${GERRIT_HOST}/#/c/" + gtokens[3] + '/'
                    bodyMessage += "Commit: <a href=\"${gerritUrl}\">${gerritUrl}</a>"
                    if (project.merge == true) {
                        bodyMessage += "Merged: ${project.merge}"
                    }
                }
            } else if (repoUpliftResult == "SKIPPED") {
                bodyMessage == "${env.BUILD_URL}\nKubectl and helm version update SKIPPED in ${project.repo} repository."
            } else {
                header = "${env.JOB_NAME} (${env.BUILD_NUMBER}) - Kubectl and helm versions update FAILED in ${project.repo}"
                bodyMessage = "<a href=\"${env.BUILD_URL}\">${env.BUILD_URL}</a><br>Kubectl and helm version update FAILED in ${project.repo} repository."
            }
            if (!params.DUMMY_RUN && repoUpliftResult != "SKIPPED") {
                if (project.notification_email && project.notification_email != "null") {
                    notif.sendMail(header, bodyMessage, project.notification_email, "text/html")
                }
            } else {
                echo "${bodyMessage}"
            }
        }
    }
}