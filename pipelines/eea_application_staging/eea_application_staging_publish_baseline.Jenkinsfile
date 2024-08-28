@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import com.ericsson.eea4.ci.Artifactory
import groovy.transform.Field
import com.ericsson.eea4.ci.CiDashboard
import com.ericsson.eea4.ci.CsarUtils

@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def arm = new Artifactory(this, "https://arm.seli.gic.ericsson.se/", "API_TOKEN_EEA")
@Field def dashboard = new CiDashboard(this)
@Field def gitdoc = new GitScm(this, 'EEA/eea4_documentation')
@Field def csarutils = new CsarUtils(this)

pipeline {
    options {
        disableConcurrentBuilds()
        buildDiscarder(logRotator(daysToKeepStr: "14", artifactDaysToKeepStr: "7"))
    }
    agent {
        node {
            label 'productci'
        }
    }
    parameters {
        string(name: 'CHART_NAME', description: 'Chart name e.g.: eric-ms-b', defaultValue: '')
        string(name: 'CHART_REPO', description: 'Chart repo e.g.: https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm', defaultValue: '')
        string(name: 'CHART_VERSION', description: 'Chart version e.g.: 1.0.0-1', defaultValue: '')
        string(name: 'INT_CHART_VERSION', description: 'Chart version e.g.: 1.0.0-1', defaultValue: '')
        string(name: 'GERRIT_REFSPEC',  description: 'Gerrit Refspec of the integration chart git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'SPINNAKER_TRIGGER_URL', description: 'Spinnaker pipeline triggering url', defaultValue: '')
        string(name: 'SPINNAKER_ID', description: "The spinnaker execution's id", defaultValue: '')
        string(name: 'DOC_BUILD_NUMBER', description: "Build number of the job eea-application-staging-documentation-build", defaultValue: '')
        string(name: 'SKIP_TESTING', description: "Ability to skip testing stage for certain commit", defaultValue: 'false')
    }
    environment {
        // SYSTEM can be selected e.g. using Lockable Resources
        SYSTEM = "hoff130"
        INT_CHART_NAME = "eric-eea-int-helm-chart"
    }
    stages {
        stage('Params DryRun check') {
            when {
                expression { params.DRY_RUN == true }
            }
            steps {
                dryRun()
            }
        }

        stage('Gerrit message') {
            when {
              expression { params.GERRIT_REFSPEC != '' }
            }
            steps {
                script {
                    env.GERRIT_MSG = "Build Started ${BUILD_URL}"
                    sendMessageToGerrit(params.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }

        stage('Validate patchset changes') {
            when {
                expression { params.GERRIT_REFSPEC }
            }
            steps {
                script {
                    def result = gitcnint.verifyNoNewPathSet(params.GERRIT_REFSPEC)
                    if (!result) {
                        error ('New patchset created since stage Prepare')
                    }
                }
            }
        }

        stage('Checkout') {
            steps {
                script {
                    gitcnint.checkout('master', '')
                }
            }
        }

        stage('Ruleset change checkout'){
            when {
                expression { params.GERRIT_REFSPEC != '' }
            }
            steps{
                script{
                    def gitId = sh(
                        script: "echo ${GERRIT_REFSPEC} | cut -f4 -d'/'",
                        returnStdout : true
                    ).trim()
                    echo "${gitId}"   //DEBUG
                    def git_result = sh(
                        script: "ssh -o StrictHostKeyChecking=no -p ${GERRIT_PORT} ${GERRIT_HOST} gerrit query --current-patch-set ${gitId} --format json --files > gerrit_result"
                    )
                    def filePath = readFile "${WORKSPACE}/gerrit_result"
                    def lines = filePath.readLines()
                    def data = readJSON text: lines[0]

                    data.currentPatchSet.files.each { file_rec ->
                        print file_rec
                        if (file_rec.file  == "ruleset2.0.yaml") {
                            withCredentials([usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
                            sh 'git fetch https://${GERRIT_USERNAME}:${GERRIT_PASSWORD}@${GERRIT_HOST}/a/EEA/cnint ${GERRIT_REFSPEC} && git cherry-pick FETCH_HEAD'
                            }
                        }
                        echo "${file_rec.file} changed"
                    }
                }
            }
        }

        stage('Prepare') {
            steps {
                checkoutGitSubmodules()
            }
        }

        stage('Init') {
            steps {
                script {
                    env.VERSION_WITHOUT_HASH = sh(script: 'echo "$INT_CHART_VERSION" | rev | cut -d"-" -f2-  | rev', returnStdout: true).trim()
                    if (params.GERRIT_REFSPEC != null && params.GERRIT_REFSPEC != '') {
                        def tokens = params.GERRIT_REFSPEC.split("/")
                        if (tokens.length == 5) {
                            def link = getGerritLink(params.GERRIT_REFSPEC)
                            currentBuild.description = link
                        } else {
                            def link = '<a href="' + env.BUILD_NUMBER + '/console">' + params.GERRIT_REFSPEC + '</a>'
                            currentBuild.description = link
                        }
                    } else {
                        def link = '<a href="' + env.BUILD_NUMBER + '/console">' + params.CHART_NAME + ':' + params.CHART_VERSION + '</a>'
                        currentBuild.description = link
                    }
                    if ( params.SPINNAKER_ID != '' ) {
                        currentBuild.description += '<br><a href="https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/details/' + params.SPINNAKER_ID + '">Spinnaker URL: ' + params.SPINNAKER_ID + '</a>'
                    }
                }
            }
        }

        stage('Init documentation ') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    dir ('eea4_documentation') {
                        script {
                            gitdoc.checkout(env.MAIN_BRANCH,'')
                            checkoutGitSubmodules()
                        }

                        dir ('doc_publish') {
                            echo "Copy artifacts from eea-application-staging-documentation-build"
                            copyArtifacts(projectName: 'eea-application-staging-documentation-build', selector: specific("${DOC_BUILD_NUMBER}"))

                            script {
                                echo "Extract artifacts"
                                sh (
                                    script: '''
                                        for file in $(tar tf doc_build_*.tar.gz | egrep -i '(dxp|zip|xml)$'); do stripnumber=$(echo $file | awk -F"/" '{print NF-1}'); tar xf doc_build_*.tar.gz $file --strip-components=$stripnumber; done
                                    '''
                                )
                                readProperties(file: 'artifact.properties').each {key, value -> env[key] = value }
                            }
                            echo "${env.DOC_COMMIT_ID}"
                        }
                    }
                }
            }
        }

        stage('Resource locking - Publish Helm Chart') {
            options {
                lock resource: null, label: "baseline-publish", quantity: 1, variable: "system"
            }
            stages {
                stage('Publish Helm Chart') {
                    steps {
                        // Generate integration helm chart
                        withCredentials([
                                        usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                                        usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD'),
                                        string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                                        string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                            script {
                                sh 'bob/bob publish'
                            }
                        }
                    }
                }
            }
        }

        stage('Upload CSAR') {
            when {
                expression { params.SKIP_TESTING != 'true' }
            }
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    script {
                        // Upload the CSAR package: first download it from internal and then upload to drop repo
                        withCredentials([string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                            // Download the CSAR from internal repository
                            try {
                                echo "CSAR DOWNLOAD ..."
                                arm.setUrl("https://arm.seli.gic.ericsson.se", "$API_TOKEN_EEA")
                                arm.downloadArtifact("csar-package-${INT_CHART_VERSION}.csar","csar-package-${INT_CHART_VERSION}.csar","proj-eea-internal-generic-local")
                            } catch (err) {
                                error "CSAR DOWNLOAD FAILED:\n${err}"
                            }

                            try {
                                echo "CSAR PROCESSING ..."
                                csarutils.extractImagesTxtAndCreateContentTxtBesideCsar('csar-package-$INT_CHART_VERSION.csar')
                                csarutils.fetchAndProcess3ppListJsonsToCsv()
                            } catch (err) {
                                error "CSAR PROCESSING FAILED:\n${err}"
                            }

                            // Upload the CSAR to the drop repository
                            try {
                                echo "CSAR UPLOAD ..."
                                arm.setUrl("https://arm.seli.gic.ericsson.se/", "$API_TOKEN_EEA")
                                arm.setRepo('proj-eea-drop-generic-local')
                                // Upload CSAR package
                                arm.deployArtifact('csar-package-$INT_CHART_VERSION.csar', 'csar-package-$VERSION_WITHOUT_HASH.csar')
                                // Upload images.txt, content.txt and 3pplist.csv next to the CSAR
                                arm.deployArtifact('content.txt', 'csar-package-$VERSION_WITHOUT_HASH.content.txt')
                                arm.deployArtifact('images.txt', 'csar-package-$VERSION_WITHOUT_HASH.images.txt')
                                arm.deployArtifact('3pplist.csv', 'csar-package-$VERSION_WITHOUT_HASH.3pp_list.csv')
                            } catch (err) {
                                error "CSAR UPLOAD FAILED:\n${err}"
                            }

                        }
                    }
                }
            }
        }

        stage('Upload dimtool') {
            when {
                expression { params.SKIP_TESTING != 'true' }
            }
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    withCredentials([string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                        script {
                            try {
                                arm.setUrl("https://arm.seli.gic.ericsson.se/", "$API_TOKEN_EEA")
                                // Copy dimtool from internal to drop repo
                                arm.copyArtifact("eea4-dimensioning-tool/eea4-dimensioning-tool-${INT_CHART_VERSION}.zip", 'proj-eea-internal-generic-local', "eea4-dimensioning-tool/eea4-dimensioning-tool-${VERSION_WITHOUT_HASH}.zip", 'proj-eea-drop-generic-local')
                            }
                            catch (err) {
                                error "DIMTOOL UPLOADING FAILED:\n${err}"
                            }
                        }
                    }
                }
            }
        }

        stage('Submit documentation changes') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    dir ('eea4_documentation'){
                        // Commit changes
                        script {
                            // Submit changes
                            withCredentials([usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_USER_PASSWORD')]){
                                sh(
                                    script: """
                                    sshpass -p $GIT_USER_PASSWORD ssh -o StrictHostKeyChecking=no -p ${GERRIT_PORT} $GIT_USER@${GERRIT_HOST} gerrit review --verified +1 --code-review +2 --submit --project EEA/eea4_documentation ${env.DOC_COMMIT_ID}
                                    """
                                )
                            }
                        }
                    }
                }
            }
        }

        stage('Generate and Publish Documentation Helm Chart version') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    dir ('eea4_documentation') {
                        script {
                            def docbuilderjob = build job: "documentation_publish", parameters: [
                                stringParam(name: "BUILD_NUMBER", value: params.DOC_BUILD_NUMBER),
                                stringParam(name: "DOC_COMMIT_ID", value: env.DOC_COMMIT_ID),
                                stringParam(name: "DOC_BUILD_JOBNAME", value: "eea-application-staging-documentation-build"),
                                booleanParam(name: "MANUAL_RECOVER_AFTER_FAILED_PUBLISH", value: false)
                                ], wait: true
                            copyArtifacts filter: 'artifact.properties', fingerprintArtifacts: true, projectName: 'documentation_publish', selector: specific(docbuilderjob.number.toString())
                            env.DOC_VERSION = sh (script: "grep DOC_VERSION <artifact.properties | cut -f2 -d=", returnStdout: true).trim()
                        }
                    }
                }
            }
        }

        stage('Archive artifact.properties') {
            steps {
                // Archive artifact.properties generated by product and documentation build so Spinnaker can read the parameters
                sh "echo '\nDOC_VERSION=${env.DOC_VERSION}' >> artifact.properties"
                archiveArtifacts 'artifact.properties'
            }
        }

        stage('Init dashboard execution') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    script {
                        readProperties(file: 'artifact.properties').each {key, value -> env[key] = value }
                        def chart_path = ".bob/${env.INT_CHART_NAME}-${env.INT_CHART_VERSION}.tgz"
                        echo "upload chart to dashboard"
                        //dashboard.publishHelm(chart_path, "${env.INT_CHART_VERSION}", "${env.BUILD_URL}", "${params.SPINNAKER_ID}")
                        dashboard.uploadHelm(chart_path, "${env.INT_CHART_VERSION}")

                        def ihcChangeType = dashboard.ihcChangeTypeNewMicroserviceVersion
                        if (params.GERRIT_REFSPEC) {
                            ihcChangeType = dashboard.ihcChangeTypeManual
                        }
                        echo "init IHC change type: ${ihcChangeType}"
                        dashboard.setIhcChangeType(ihcChangeType)

                        echo "set execution"
                        dashboard.startExecution("product-baseline","${env.BUILD_URL}","${params.SPINNAKER_ID}")
                        dir('notincsar_service_handling') {
                            dashboard.uploadNotInCsarPackages(params.SPINNAKER_ID,"${env.INT_CHART_NAME}","${env.VERSION_WITHOUT_HASH}")
                        }
                        dashboard.finishExecution("product-baseline","SUCCESS","${params.SPINNAKER_ID}","${env.INT_CHART_VERSION}")
                    }
                }
            }
        }

    }

    post {
        always {
            script {
                if (params.GERRIT_REFSPEC != '') {
                    env.GERRIT_MSG = "Build result ${BUILD_URL}: ${currentBuild.result}"
                    sendMessageToGerrit(params.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }
        success {
            script {
                if (params.SKIP_TESTING != 'true') {
                    // download and archive test report
                    echo "Saving test results"
                    try {
                        def time_range = "from=now-30d&to=now"
                        env. URL_TO_CAPTURE = "http://10.61.197.97:3000/d/ZQ3FtMW7k/annotations-and-alerts-copy?orgId=1&${time_range}&var-spinnaker_id=${params.SPINNAKER_ID}&var-cluster=All&var-logtype=All&var-story=All&var-scenario=All&var-step=All&var-result=All&var-story_name=All&var-story_id=All&var-scenario_name=All&var-scenario_id=All&var-step_name=All&var-step_id=All"
                        withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                            usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA')]) {
                            sh 'bob/bob -r bob-rulesets/technical_ruleset.yaml url2pdf-bob'
                        }
                        archiveArtifacts artifacts: "out/test_run_result.pdf", allowEmptyArchive: true

                        // Upload the PDF to the drop repository
                        withCredentials([string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                            arm.setUrl("https://arm.seli.gic.ericsson.se/",  "$API_TOKEN_EEA")
                            arm.setRepo('proj-eea-reports-generic-local/eea4')
                            arm.deployArtifact( 'out/test_run_result.pdf', 'test_run_result-${INT_CHART_VERSION}.pdf')
                        }
                    }
                    catch (err) {
                        echo "Caught: ${err}"
                    }
                }
            }
        }
        cleanup {
            cleanWs()
        }
    }
}
