@Library('ci_shared_library_eea4') _

import groovy.transform.Field
import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.Notifications
import com.ericsson.eea4.ci.CommonUtils

@Field def gitCnint = new GitScm(this, 'EEA/cnint')
@Field def notif = new Notifications(this)
@Field def commonUtils = new CommonUtils(this)

def repos = [
    [
        "project": "EEA/cnint",
        "upliftConfigRuleset": "cnint_version_auto_uplift_config.yaml",
        "validatorJob": "eea-application-staging-batch",
        "validatorJobExtraParams":
        [
            ["_class": "StringParameterValue", "name": "PIPELINE_NAME", "value": "eea-application-staging"],
            ["_class": "StringParameterValue", "name": "WAIT_FOR_CLUSTER_LOG_COLLECTOR_RESULT", "value": "true"]
        ]
    ],
    [
        "project": "EEA/eea4_documentation",
        "upliftConfigRuleset": "eea4_documentation_version_auto_uplift_config.yaml",
        // todo: set validatorJob for eea4_documentation after validation logic is clarified
        // "validatorJob": "eea-application-staging-documentation-build"
    ],
    [
        "project": "EEA/adp-app-staging",
        "upliftConfigRuleset": "adp-app-staging_version_auto_uplift_config.yaml"
    ],
    [
        "project": "EEA/project-meta-baseline",
        "upliftConfigRuleset": "project-meta-baseline_version_auto_uplift_config.yaml",
        "ignore_images_list": ["eric-eea-robot"]
    ],
    [
        "project": "EEA/ci_shared_libraries",
        "upliftConfigRuleset": "ci_shared_libraries_version_auto_uplift_config.yaml"
    ],
    [
        "project": "EEA/jenkins-docker",
        "upliftConfigRuleset": "jenkins_docker_version_auto_uplift_config.yaml"
    ]
]

def versionAutoUpliftConfig = ''
def rulesetName = ''

pipeline {

    options {
        ansiColor('xterm')
        skipDefaultCheckout()
        buildDiscarder(logRotator(daysToKeepStr: "7"))
    }

    agent {
        node { label 'productci' }
    }

    parameters {
        booleanParam(name: 'DUMMY_RUN', description: 'Skip commit, push, and validation and e-mail sending', defaultValue: false)
        string(name: 'CNINT_GERRIT_REFSPEC', description: 'Refspec for cnint version - for bob and ruleset2.0.version.auto.uplift.yaml', defaultValue: '')
    }

    environment {
        CNINT_WORKDIR = 'cnint_workdir'
    }

    triggers { cron('H H(6-8) * * 6') }

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

        stage('Checkout cnint for bob and rulesets'){
            steps {
                script {
                    // if param set, checkout specific cnint version for testing ruleset2.0.version.auto.uplift.yaml
                    if (params.CNINT_GERRIT_REFSPEC) {
                        gitCnint.checkoutRefSpec(params.CNINT_GERRIT_REFSPEC, 'FETCH_HEAD', env.CNINT_WORKDIR)
                    } else {
                        gitCnint.checkout('master', env.CNINT_WORKDIR)
                    }
                }
            }
        }

        stage('Prepare') {
            // checkout cnint for bob and rulesets
            steps {
                script {
                    log.infoMsg "Started Prepare stage"
                    dir(env.CNINT_WORKDIR) {
                        checkoutGitSubmodules()
                    }
                    log.infoMsg "Finished Prepare stage"
                }
            }
        }

        stage('Start Uplifting images') {
            steps {
                script {
                    currentBuild.description = ""
                    repos.each { repo ->
                        upliftImage(repo).call()
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

def upliftImage (Map args) {
    def repoName = args.project.split("/")[-1]
    def ignoreImagesList = args.ignore_images_list
    def repoUpliftSuccess = false
    def currentRepoGerritRefspec = ''
    def gitObj = new GitScm(this, args.project)
    return {

        stage("Checkout - ${repoName}") {
            dir(repoName) {
                script {
                    def ref = ''
                    if (args.ref) {
                            gitObj.checkoutRefSpec(args.ref, 'FETCH_HEAD', '.')
                            ref = args.ref
                        } else {
                            ref = 'master'
                            gitObj.checkout('master', '.')
                        }
                    sh "git status"
                    log.infoMsg "Started Checkout - ${repoName} stage -- ${ref}"
                }
            }
        }

        stage("Generate version_auto_uplift_config.yaml - ${repoName}") {
            dir(repoName) {
                script {
                    log.infoMsg "Started generating version_auto_uplift_config.yaml -- ${repoName}"
                    catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                        try {
                            rulesets = sh(script: '''
                                grep -ril --include='*.yaml' 'rules:' * | xargs grep -ril 'docker-images:'
                            ''', returnStdout: true).trim()
                            rulesets = rulesets.split('\n').collect{it as String}
                            versionAutoUpliftConfig = """allowed_types:
  - rulesets

# ruleset paths relative to the git root, not to this file
rulesets:
"""
                            for (ruleset in rulesets) {
                                rulesetName = ruleset.split('/')[-1]
                                versionAutoUpliftConfig = versionAutoUpliftConfig.concat(
"""  - ${rulesetName}:
      path: "${ruleset}"
""")
                            }

                            if (ignoreImagesList) {
                                echo "Ignoring images: ${ignoreImagesList}"
                                versionAutoUpliftConfig = versionAutoUpliftConfig.concat(
"""
ignored_images_list:
"""
                                )
                                ignoreImagesList.each {
                                    versionAutoUpliftConfig = versionAutoUpliftConfig.concat(
"""  - ${it}
"""
                                    )
                                }
                            }
                            sh "rm -f ${args.upliftConfigRuleset}"
                            writeFile file: args.upliftConfigRuleset, text: versionAutoUpliftConfig
                            echo "versionAutoUpliftConfig: ${versionAutoUpliftConfig}"
                        } catch(err) {
                            error "Caught ${err.toString()}"
                        } finally {
                            archiveArtifacts artifacts: "${args.upliftConfigRuleset}", allowEmptyArchive: true
                        }
                    }
                }
            }
        }

        stage("Uplifting of Docker image versions in rulesets - ${repoName}") {
            dir(repoName) {
                script {
                    log.infoMsg "Started uplifting of Docker image versions stage -- ${repoName}"
                    catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                        try {
                            withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'HELM_USER', passwordVariable: 'API_TOKEN'),
                                            usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD'),
                                            string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP')]) {
                                withEnv(["VERSION_UPDATER_CONFIG_PATH=${args.upliftConfigRuleset}"]) {
                                    log.infoMsg "VERSION_UPDATER_CONFIG_PATH: ${env.VERSION_UPDATER_CONFIG_PATH}"
                                    sh "${WORKSPACE}/${env.CNINT_WORKDIR}/bob/bob -r ${WORKSPACE}/${env.CNINT_WORKDIR}/bob-rulesets/ruleset2.0.version.auto.uplift.yaml update-versions > update-versions-${repoName}.log"
                                }
                            }
                            repoUpliftSuccess = true
                            log.infoMsg "Finished uplifting of Docker image versions stage - ${repoName} SUCCESSFULLY."
                        } catch(err) {
                            log.errMsg "Caught: ${err}"
                            log.errMsg "Uplifting repo - ${repoName} FAILED."
                            error "Caught ${err.toString()}"
                        } finally {
                            sh "rm -f ${args.upliftConfigRuleset}"
                            archiveArtifacts artifacts: "update-versions-${repoName}.log", allowEmptyArchive: true
                        }
                    }
                }
            }
        } // Uplifting of Docker image versions in ruleset files

        stage("Preparing a new commit and push changes - ${repoName}") {
            dir(repoName) {
                script {
                    if (repoUpliftSuccess) {
                        if (!params.DUMMY_RUN) {
                            log.infoMsg "Started Preparing a new commit and push changes in ${repoName}"
                            gitObj.createPatchset("-u", "Automatic uplifting of Docker image versions in rulesets")
                            def git_id = gitObj.getCommitHashLong()
                            log.infoMsg "git_id: ${git_id}"
                            currentRepoGerritRefspec = gitObj.getCommitRefSpec(git_id)
                            currentBuild.description += "<br>${repoName} " + getGerritLink(currentRepoGerritRefspec)
                            log.infoMsg "ref: ${currentRepoGerritRefspec}"
                            log.infoMsg "Finished Preparing a new commit and push changes"
                        } else {
                            log.infoMsg "params.DUMMY_RUN is True, commit & push steps skipped in ${repoName}"
                        }
                    } else {
                        log.infoMsg "Stage SKIPPED due to previous errors."
                    }
                }
            }
        } // Preparing a new commit and push changes

        stage("Start commit validation  - ${repoName}") {
            timeout(time: 4, unit: 'HOURS') {
                script {
                    if (repoUpliftSuccess) {
                        log.infoMsg "Started Commit validation stage"
                        // if current repo has validator job in arguments, run that job
                        if (args.validatorJob) {
                            def lastSuccessfulBuildParameters = getJenkinsJobBuildParameters("${args.validatorJob}")
                            def extraParameters = []

                            // set dummy run and gerrit refspec according to params
                            extraParameters.add(["_class": "BooleanParameterValue", "name": "DRY_RUN", "value": params.DUMMY_RUN])
                            extraParameters.add(["_class": "StringParameterValue", "name": "GERRIT_REFSPEC", "value": "$currentRepoGerritRefspec"])
                            if (args.validatorJobExtraParams) {
                                args.validatorJobExtraParams.each { validatorJobExtraParam ->
                                    extraParameters.add(validatorJobExtraParam)
                                }
                            }
                            // add, or override (if param exists in previous job parameters list) extra params for this job
                            def mergedBuildParameters = commonUtils.mergeListOfMapObjects(lastSuccessfulBuildParameters, extraParameters)
                            def buildParameters = createJobBuildParameters("${args.validatorJob}", mergedBuildParameters)

                            log.infoMsg "Started Commit validation stage with job: ${args.validatorJob}, params: ${buildParameters}"
                            catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                                try {
                                    build(job: args.validatorJob, parameters: buildParameters, wait: true)
                                } catch(err) {
                                    log.errMsg "Caught: ${err}"
                                    repoUpliftSuccess = false
                                    error "Caught ${err.toString()}"
                                }
                            }
                        } else {
                            log.warnMsg "No validatorJob specified for ${repoName} repository! Commit validation skipped!"
                        }
                    } else {
                        log.infoMsg "Stage SKIPPED due to previous errors."
                    }
                    log.infoMsg "repoUpliftSuccess: ${repoUpliftSuccess}"
                }
            }
        }

        stage("Post - ${repoName}") {
            def gerritUrl = ''
            if (repoUpliftSuccess) {
                def gtokens = currentRepoGerritRefspec.split("/")
                if (gtokens.length == 5) {
                    gerritUrl = "https://${GERRIT_HOST}/#/c/" + gtokens[3] + '/'
                }

                def body_message = "${env.BUILD_URL}\nNew versions of Docker images were automatically updated in all ruleset files within ${repoName} repository.\nA new commit ${gerritUrl} was prepared and should be approved by driver.\n"

                if (!args.validatorJob) {
                    body_message += "\nImportant: no validatorJob was specified for this repository, please validate the results manually!"
                }
                if (params.DUMMY_RUN || params.DRY_RUN) {
                    // don't send email in case of dummy/dry run
                    log.infoMsg "Message: ${body_message}"
                    log.infoMsg "DUMMY_RUN == True, sending mail skipped"
                } else {
                    notif.sendMail("${env.JOB_NAME} (${env.BUILD_NUMBER}) uplifted ${repoName} SUCCESSFULLY", body_message, "517d5a14.ericsson.onmicrosoft.com@emea.teams.ms")
                }
            } else {
                def body_message = "${env.BUILD_URL}\nUplifting docker images in ${repoName} repository FAILED or something went wrong during the validation of the new commit ${gerritUrl}. It should be checked!"
                if (params.DUMMY_RUN || params.DRY_RUN) {
                    // don't send email in case of dummy/dry run
                    log.infoMsg "Message: ${body_message}"
                    log.infoMsg "currentBuild.currentResult: ${currentBuild.currentResult}"
                    log.infoMsg "DUMMY_RUN == True, sending mail skipped"
                } else {
                    notif.sendMail("${env.JOB_NAME} (${env.BUILD_NUMBER}) for ${repoName} FAILED", body_message, "517d5a14.ericsson.onmicrosoft.com@emea.teams.ms")
                }
            }
        }
    }
}

def createJobBuildParameters(def job, def parameters) {
    script {
        ArrayList buildParameters = []
        try {
            parameters.each { parameter ->
                buildParameters.add([$class: parameter._class, "name": parameter.name, "value": parameter.value])
            }
            echo "Parameter(s) for job: ${job} for test run:\n${buildParameters.toString()}"
            if (!buildParameters){
                echo "EMPTY PARAMETERS"
            }
            return buildParameters
        } catch (err) {
            error "createJobBuildParameters FAILED\n - job: ${job}\n - ERROR: ${err}"
        }
    }
}
