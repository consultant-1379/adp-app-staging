@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import com.ericsson.eea4.ci.GlobalVars
import com.ericsson.eea4.ci.UtfTrigger2
import com.ericsson.eea4.ci.ClusterLockUtils
import com.ericsson.eea4.ci.ArchiveLogs
import com.ericsson.eea4.ci.ClusterLogUtils
import com.ericsson.eea4.ci.CommonUtils

@Field def gitRepo = new GitScm(this, '')
@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def vars = new GlobalVars()
@Field def utf = new UtfTrigger2(this)
@Field def clusterLogUtilsInstance = new ClusterLogUtils(this)
@Field def cmutils = new CommonUtils(this)

def gitInstance
def rulesetFileList

pipeline {
    options {
        ansiColor('xterm')
        buildDiscarder(logRotator(daysToKeepStr: '7', artifactNumToKeepStr: "7"))
    }
    agent {
        node {
            label 'productci'
        }
    }
    parameters {
        string(name: 'GERRIT_PROJECT', description: 'Gerrit project name like EEA/cnint ', defaultValue: '')
        string(name: 'GERRIT_REFSPEC',  description: 'Gerrit Refspec of the integration chart git repo e.g.: refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'GERRIT_HOST', description: 'Gerrit host e.g: gerrit.ericsson.se', defaultValue: '')
        string(name: 'GERRIT_BRANCH', description: 'Gerrit branch e.g: master', defaultValue: '') // master
        string(name: 'GERRIT_PORT', description: 'Gerrit port e.g: 29418', defaultValue: '')
        string(name: 'GERRIT_CHANGE_URL', description: 'Gerrit change url e.g: https://gerrit.ericsson.se/15419290', defaultValue: '')
        string(name: 'GERRIT_CHANGE_NUMBER', description: 'Gerrit change number e.g: 15419290', defaultValue: '')
    }

    environment {
        BOB_LOG_PATH = ""  //relative
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
                script {
                    gitInstance = new GitScm(injectedScript=this, project="${params.GERRIT_PROJECT}", gerritHost="${params.GERRIT_HOST}", gerritPort="${env.GERRIT_PORT}")
                    gitInstance.checkoutRefSpec("${GERRIT_REFSPEC}","FETCH_HEAD", "${params.GERRIT_PROJECT}")
                }
            }
        }

        stage('Init job description') {
            steps {
                script {
                    currentBuild.description = "<a href="+"${params.GERRIT_CHANGE_URL}"+">gerrit change: "+"${params.GERRIT_CHANGE_URL}"+"</a>"
                }
            }
        }

        stage('Init bob submodule') {
            steps {
                script {
                    dir("${params.GERRIT_PROJECT}") {
                        checkoutGitSubmodules()
                    }
                }
            }
        }

        stage('Collect ruleset file list') {
            steps {
                script {
                    dir("${params.GERRIT_PROJECT}") {
                        def changedFileList = gitInstance.getGerritQueryPatchsetChangedFiles("${params.GERRIT_CHANGE_NUMBER}",true)
                        echo("${changedFileList}")
                        rulesetFileList = []
                        changedFileList.each { changedFile ->
                            // without this job fails on directory changes (eg. bob submodule status change)
                            def isDir = sh(script: "[ -d ${changedFile} ]", returnStatus: true)
                            if (isDir.toInteger() != 0) {
                                result = sh ( script: "head -n 1 ${changedFile}", returnStdout: true ).trim()
                                if (result == "modelVersion: 2.0") {
                                    rulesetFileList.add(changedFile)
                                }
                            } else {
                                echo "${changedFile} is a directory, skipping."
                            }
                        }
                    }
                    echo("ruleset files ${rulesetFileList}")
                }
            }
        }

        stage('Ruleset validations ') {
            when {
                expression { rulesetFileList.size() > 0  }
            }
            stages{
                stage('dry-run') {
                    steps {
                        script {
                            echo('TODO https://eteamproject.internal.ericsson.com/browse/EEAEPP-83142')
                        }
                    }
                }

                stage('Bob validate-properties') {
                    steps {
                        script {
                            dir("${params.GERRIT_PROJECT}") {
                                echo ("Checks if properties used in rules within the ruleset are declared before usage.")

                                catchError(buildResult: 'FAILURE', stageResult: 'FAILURE' ) {
                                    def result = true
                                    String resultStr
                                    rulesetFileList.each { rulesetFile ->
                                        String rulesetName = rulesetFile.take(rulesetFile.lastIndexOf('.'))

                                        withEnv(["BOB_LOG_PATH=validate-properties/${rulesetName}"]) {
                                            try {
                                                sh ( script: "bob/bob --ruleset ${rulesetFile} --validate-properties", returnStdout: true)
                                            }
                                            catch (err) {
                                                result = false
                                                resultStr = sh ( script: "grep -ri ERROR validate-properties/${rulesetName}/", returnStdout: true)
                                                sendMessageToGerrit(params.GERRIT_REFSPEC, "validate-properties failed for ${rulesetFile} with ${resultStr}")
                                                echo "validate-properties failed for ${rulesetFile} with ${resultStr}"
                                            }
                                        }
                                    }
                                    if (!result) {
                                        error ("validate-properties failed")
                                    }
                                }
                            }
                        }
                    }
                }

                stage('Bob validate-refs') {
                    steps {
                        script {
                            dir("${params.GERRIT_PROJECT}") {
                                echo ("Validate all task, rule and condition references then exit.")
                                catchError(buildResult: 'FAILURE', stageResult: 'FAILURE' ) {
                                    def result = true
                                    String resultStr
                                    rulesetFileList.each { rulesetFile ->
                                        String rulesetName = rulesetFile.take(rulesetFile.lastIndexOf('.'))
                                        withEnv(["BOB_LOG_PATH=validate-properties/${rulesetName}"]) {
                                            try {
                                                sh ( script: "bob/bob --ruleset ${rulesetFile} --validate-refs")
                                            }
                                            catch (err) {
                                                result = false
                                                resultStr = sh ( script: "grep -ri ERROR validate-properties/${rulesetName}/", returnStdout: true)
                                                sendMessageToGerrit(params.GERRIT_REFSPEC, "validate-properties failed for ${rulesetFile} with ${resultStr}")
                                                echo "validate-refs failed for ${rulesetFile} with ${resultStr}"
                                            }
                                        }
                                    }
                                    if (!result) {
                                        error ("validate-refs failed")
                                    }
                                }
                            }
                        }
                    }
                }

                stage('Ruleset content validations') {
                    stages{
                        stage('Validate unused variables') {
                            steps {
                                echo("Validate if unused properties, var, env, images declared") // var, env, images
                                script {
                                    dir("${params.GERRIT_PROJECT}") {
                                        echo ("Validate all task, rule and condition references then exit.")
                                        catchError(buildResult: 'FAILURE', stageResult: 'FAILURE' ) {
                                            def result = true
                                            rulesetFileList.each { rulesetFile ->
                                                env.BOB_LOG_PATH = "validate-unused-vars/${rulesetFile}"
                                                echo "try"
                                                try {
                                                    validateUnusedVariable(rulesetFile)
                                                }
                                                catch (err) {
                                                    result = false
                                                    echo "validate for unused variables failed for ${rulesetFile} with ${err}"
                                                }
                                            }
                                            if (!result) {
                                                error ("validate for unused variables failed")
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        stage('Validate imported files'){
                            steps {
                                script {
                                    def fileImportWhitelistMap = [
                                        [repo: "EEA/cnint", file:"ruleset2.0.yaml", imports: ["bob-rulesets/dimtool_ruleset.yaml",]]
                                    ]
                                    dir("${params.GERRIT_PROJECT}") {
                                        echo("Validate if only white listed files imported and imported files are used")
                                        catchError(buildResult: 'FAILURE', stageResult: 'FAILURE' ) {
                                            def result = true
                                            rulesetFileList.each { rulesetFile ->
                                                try {
                                                    validateImportedFiles(rulesetFile, fileImportWhitelistMap)
                                                }
                                                catch (err) {
                                                    result = false
                                                    echo "validate for imported files failed for ${rulesetFile} with ${err}"
                                                }
                                            }
                                            if (!result) {
                                                error ("validate imported files failed")
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        stage('Validate docker images available') {
                            steps {
                                script {
                                    dir("${params.GERRIT_PROJECT}") {
                                        echo("Validate if docker images available")
                                        catchError(buildResult: 'FAILURE', stageResult: 'FAILURE' ) {
                                            def result = true
                                            rulesetFileList.each { rulesetFile ->
                                                try {
                                                    checkImportedImagesAvailability(rulesetFile)
                                                }
                                                catch (err) {
                                                    result = false
                                                    sendMessageToGerrit(params.GERRIT_REFSPEC, "validate-refs failed for ${rulesetFile} with ${err}")
                                                    echo "validate for imported files failed for ${rulesetFile} with ${err}"
                                                }
                                            }
                                            if (!result) {
                                                error ("validate imported files failed")
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        stage('Validate used docker images') {
                            steps {
                                echo ("do not use adp docker-images for simple helm, shell, kubectl command, jq,yq, validate if exists, whitelist for latest ")
            //                    docker manifest inspect armdocker.rnd.ericsson.se/proj-eea-drop/eric-eea-utils-ci:2.21.0-10 > /dev/null ; echo $?
                            }
                        }

                        stage('Validate logic implemented') {
                            steps {
                                echo ("do not implement logic in ruleset files, do not use conditions (https://gerrit.ericsson.se/plugins/gitiles/adp-cicd/bob/+/HEAD/USER_GUIDE_2.0.md#Using-conditions)")
                            }
                        }

                        stage('Validate with shellcheck') {
                            steps {
                                echo ("if a shall block validate shellcheck (  cmd write to file )")
                            }
                        }
                    }
                }

                stage('Archive artifact.properties') {
                    steps {
                         archiveArtifacts artifacts: 'artifact.properties', allowEmptyArchive: true
                    }
                }
            }
        }
    }

    post {
        failure {
            script {
                if(params.GERRIT_REFSPEC != '') {
                    env.GERRIT_MSG = "Build Failed ${BUILD_URL}: FAILURE"
                    sendMessageToGerrit(params.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }
        success {
            script {
                if(params.GERRIT_REFSPEC != '') {
                    env.GERRIT_MSG = "Build Successful ${BUILD_URL}: SUCCESS"
                    sendMessageToGerrit(params.GERRIT_REFSPEC, env.GERRIT_MSG)
                }
            }
        }
        cleanup {
            cleanWs()
        }
    }
}

def checkImportedImagesAvailability(rulesetFile){
    def data = readYaml file: "${rulesetFile}"
    def imageList = data["docker-images"]
    def imageNameList = []
    def message = ""
    def result = true
    imageList.each {image ->
        image.each { k,v ->
            try {
                sh ( script:"docker manifest inspect $v > /dev/null")
            }
            catch (err) {
                result = false
                echo ("$err")
                sendMessageToGerrit(params.GERRIT_REFSPEC, "${rulesetFile} validation for image ${v} failed with ${err} ")
            }
        }
    }
    return result
}

def validateImportedFiles(String rulesetFile, def fileImportWhitelistMap){
    def importOK = true
    def resultCheck = true
    def importUsed = true
    def data = readYaml file: "${rulesetFile}"
    def importsList = data["import"]
    def message = ""
    echo ("imported files in ${rulesetFile}: $importsList")
    importsList.each {name,filePath ->
        resultCheck = checkImportWhitelist( rulesetFile , params.GERRIT_PROJECT, filePath, fileImportWhitelistMap)
        if (!resultCheck) {
            importOK = false
            message += "imported file not in whitelist: $filePath\n"
        }

        importUsed = checkImportUsed(rulesetFile, name)
         if (!importUsed) {
            importOK = false
            message += "In ${rulesetFile} imported file not used: $name: $filePath\n"
        }
    }
    if (!importOK){
        sendMessageToGerrit(params.GERRIT_REFSPEC, "ERROR: ${rulesetFile} validation failed ${message}")
        error ("ERROR: Validation failed ${message}")
    }
}

def checkImportUsed(def rulesetFile, String importName){
    echo "${rulesetFile}"
    def result = sh (script: "grep '$importName\\.' ${rulesetFile}", returnStatus: true)
    return ("$result" == "0")
}

def checkImportWhitelist(String rulesetFile , String projectName, String filePath, def fileImportWhitelistMap){
    echo "${rulesetFile}, $projectName, $filePath"

    def whitelisted = false
    fileImportWhitelistMap.each{ fileMap  ->
        if ("$fileMap.repo" == "$projectName" && "$fileMap.file" == "${rulesetFile}" ){
            whitelisted = fileMap.imports.contains(filePath)
        }
    }
    return whitelisted
}

def validateUnusedVariable(String rulesetFile) {
    echo "------Validation of ruleset file: ${rulesetFile}"
    def data = readYaml file: "${rulesetFile}"
    def result = true
    String message = ""
    try {
        checkImages(data, rulesetFile)
    }
    catch (err) {
        result = false
        message += "$err \n"
    }
    try {
        checkProperties(data, rulesetFile)
    }
    catch (err) {
        result = false
        message += "$err \n"
    }
    try {
        checkEnvs(data, rulesetFile)
    }
    catch (err) {
        result = false
        message += "$err \n"
    }
    try {
        checkVars(data, rulesetFile)
    }
    catch (err) {
        result = false
        message += "$err \n"
    }
    if (!result) {
        error "$message"
    }
}

def checkImages(def data, String rulesetFile){
    def imageList = data["docker-images"]
    def imageNameList = []
    def message = ""
    imageList.each {image ->
        image.each { k,v ->
            imageNameList.add ("$k")
        }
    }

    def imageNameUsed = true
    def result
    imageNameList.each { imageName ->
        result = findDockerImage(imageName, data)
        if (!result) {
            imageNameUsed = false
             message +=  "docker image: $imageName not used\n"
        }
    }
    if (!imageNameUsed) {
        sendMessageToGerrit(params.GERRIT_REFSPEC, "ERROR: ${rulesetFile} validation failed $message")
        error ("ERROR: Validation failed $message")
    }
}

def findDockerImage(String imageName, def data) {
    echo "image name: $imageName"
    def rules = data["rules"]
    def tasks
    def ruleName
    def result = false
    rules.each { rule ->
        ruleName = rule.key
        tasks = rule.value
        tasks.each { task ->
            task.each { k,v ->
                if ("$k" == "docker-image" && "$v" == "$imageName") {
                    result = true
                }
            }
        }
        return result
    }
}

def checkProperties(def data, String rulesetFile){
    def propertiesList = data["properties"]
    def message = ""
    def propertiesNameList = []
    propertiesList.each {prop ->
        prop.each { k,v ->
            propertiesNameList.add ("$k")
        }
    }
    echo "propertiesNameList $propertiesNameList"

    def propertyNameUsed = true
    def resultPropertyFind = true
    propertiesNameList.each {prop ->
        resultPropertyFind = findProperty(prop, rulesetFile)
        if (!resultPropertyFind) {
            propertyNameUsed = false
            message += "property named: $prop not used\n"
        }
    }
    if (!propertyNameUsed) {
        sendMessageToGerrit(params.GERRIT_REFSPEC, "ERROR: ${rulesetFile} validation failed $message")
        error ("ERROR: Validation failed $message")
    }
}

def findProperty(String propertyName, String fileName) {
    def result = sh (script: "grep {$propertyName} $fileName", returnStatus: true)
    return ("$result" == "0")
}

def checkEnvs(data, String rulesetFile){
    def envList = data["env"]
    def envNameList = []
    envList.each {envVar ->
        envNameList.add(envVar.split('\\(')[0].trim())
    }
    echo "env variables $envNameList"
    def message = ""
    def envNameUsed = true
    def resultEnvFind = true
    envNameList.each {env ->
        resultEnvFind = findEnvVariable("${env}", "${rulesetFile}")
        if (!resultEnvFind) {
            envNameUsed = false
            message += "env variable named: $env not used\n"
        }
    }
     if (!envNameUsed) {
        sendMessageToGerrit(params.GERRIT_REFSPEC, "ERROR: ${rulesetFile} validation failed $message")
        error ("ERROR: Validation failed $message")
    }
}

def findEnvVariable(String envName, String fileName){
    def result = sh (script: "grep -E '(\\-\\-env $envName|{env.$envName})' $fileName", returnStatus: true)
    return ("$result" == "0")
}

def checkVars(def data, String rulesetFile){
    def varsList = data["var"]
    echo "$varsList"

    def varNameUsed = true
    def resultVarFind = true
    def message = ""
    varsList.each {var ->
        resultVarFind = findVar("${var}", "${rulesetFile}")
          if (!resultVarFind) {
            varNameUsed = false
            message +=  "var named: $var not used\n"
        }
    }
    if (!varNameUsed) {
        sendMessageToGerrit(params.GERRIT_REFSPEC, "ERROR: ${rulesetFile} validation failed $message")
        error ("ERROR: Validation failed $message")
    }
}

def findVar(String varName, String fileName){
    def result = sh (script: "grep {var.$varName} $fileName", returnStatus: true)
    return ("$result" == "0")
}
