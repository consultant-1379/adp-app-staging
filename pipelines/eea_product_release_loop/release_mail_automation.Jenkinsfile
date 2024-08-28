@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.Artifactory
import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import com.ericsson.eea4.ci.CiDashboard

@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def gitcnint = new GitScm(this, 'EEA/cnint')
@Field def dashboard = new CiDashboard(this)

Map msList = [:]
Map servMap = [:]
def servicesList = []
def taggedIntChartVersion = ""

pipeline{
    agent{
        node {
            label 'productci'
        }
    }
    options {
      skipDefaultCheckout()
      buildDiscarder(logRotator(daysToKeepStr: "30"))
    }

    parameters {
        string(name: 'RELEASE_NAME', description: 'Name of the RC or Weekly Drop as string (e.g. eea4_4.2_rc1, eea4_23_w47_wd1)', defaultValue: '')
        string(name: 'EXTENDED_RELEASE_NAME', description: 'An extended version of the release name (e.g. EEA4 4.8.0 Release Candidate 2)', defaultValue: '')
        string(name: 'INT_CHART_VERSION', description: 'Chart version e.g.: 4.2.2-176', defaultValue: '')
        string(name: 'LINUX_SPOTFIRE_PLATFORM', description: 'Link for Spotfire Linux platform', defaultValue: '')
        string(name: 'SPOTFIRE_DASHBOARD_DATA_SOURCE', description: 'Link for Spotfire dashboard data sources', defaultValue: '')
        string(name: 'SPOTFIRE_STATIC_CONTENT', description: 'Link for Spotfire static content', defaultValue: '')
        string(name: 'SPOTFIRE_UTILS', description: 'Link for Spotfire Utils', defaultValue: '')
        string(name: 'DEPLOYER_PACKAGE_URL', description: 'Link for EEA Deployer package', defaultValue: '')
        string(name: 'DIMTOOL_PACKAGE_URL', description: 'Link for Dimensioning Tool package', defaultValue: '')
        booleanParam(name: 'SKIP_EMAIL_SENDING', description: 'Checking this stops the job in sending out the generated release mail', defaultValue: false)
        booleanParam(name: 'SKIP_GIT_TAGGING', description: 'Checking this stops the job in creating the git tag', defaultValue: false)
        booleanParam(name: 'SKIP_DASHBOARD_SENDING', description: 'Checking this stops the job in sending data to the application dashboard', defaultValue: false)
    }

    environment {
        INT_CHART_NAME = 'eric-eea-int-helm-chart'
        CSAR_DROP_REPO = 'https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-generic-local/'
        CSAR_RELEASED_REPO = 'https://arm.seli.gic.ericsson.se//artifactory/proj-eea-released-generic-local/'
        RELEASE_MAIL_FILENAME = 'release-mail-content.html'
        RELEASE_RULESET_FILENAME = 'ruleset2.0_product_release.yaml'
        HELM_REPO_URL = 'https://arm.seli.gic.ericsson.se'
        HELM_DROP_REPO = 'proj-eea-drop-helm-local'
        HELM_RELEASED_REPO = 'proj-eea-released-helm-local'
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

        stage('Checkout adp-app-staging master') {
            steps {
                script {
                    gitadp.checkout('master', 'adp-app-staging')
                }
            }
        }

        stage('Checkout cnint release tag') {
            steps {
                script {
                    taggedIntChartVersion = env.INT_CHART_VERSION.replaceAll(/\+/, '-')
                    gitcnint.checkout(taggedIntChartVersion, 'cnint')
                }
            }
        }

        stage('Get git commit ID for RC or Weekly Drop') {
            steps {
                dir('cnint') {
                    script {
                        env.GIT_COMMIT_ID = getCommitIdFromLastCommitMessage()
                        echo "env.GIT_COMMIT_ID=${GIT_COMMIT_ID}"
                    }
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

        stage('Parse RC or Weekly Drop microservice list') {
            steps {
                dir('cnint') {
                    script {
                        def data = readYaml file: "${env.INT_CHART_NAME}/Chart.yaml"
                        data.dependencies.each { dependency ->
                          if (msList[dependency.name]) {
                            alias = msList[dependency.name].alias
                          } else {
                            alias = []
                          }
                          if (dependency.alias) {
                            alias += dependency.alias
                          } else {
                            alias += dependency.name
                          }
                          msList[dependency.name] = ["version": dependency.version, "alias": alias]
                        }
                        def data1 = readYaml file: "${env.INT_CHART_NAME}/values.yaml"
                        msList.each { key_, value_ ->
                            if (key_ != "eric-cs-storage-encryption-provider") {
                                value_['alias'].each { alias_val ->
                                    servMap["${alias_val}"] = ["status": data1[alias_val]['enabled']]
                                }
                            }
                        }
                    }
                }
            }
        }

        stage('Parse csar_exception_list') {
            steps {
                dir ('csarworkdir') {
                    script {
                        if (taggedIntChartVersion == '') {
                            CHART_VER = 'master'
                        } else {
                            CHART_VER = taggedIntChartVersion
                        }
                        servicesList = dashboard.getServicesListFromFile("EEA/cnint","${CHART_VER}","csar_exception_list")
                    }
                }
            }
        }

        stage('Get utils image version') {
            steps {
                dir('cnint') {
                    script {
                        def rulesetDatas = readYaml file: 'ruleset2.0.yaml'
                        def images=rulesetDatas['docker-images']
                        def imagePath = ""
                        images.each {image ->
                            if (image['eea4-utils'] != null) {
                                imagePath = image['eea4-utils']
                            }
                        }
                        env.UTILS_IMAGE_NAME = imagePath.substring(0, imagePath.lastIndexOf(':'))
                        env.UTILS_VERSION = imagePath.substring(imagePath.lastIndexOf(':') + 1)
                    }
                }
            }
        }

        stage('Create release mail content') {
            steps {
                script {
                    def helmChartLink = "https://arm.seli.gic.ericsson.se/artifactory/${env.HELM_DROP_REPO}/eric-eea-int-helm-chart/${env.INT_CHART_NAME}-${env.INT_CHART_VERSION}.tgz"
                    def csarRepo = env.CSAR_DROP_REPO
                    if (env.INT_CHART_VERSION.contains('+')){
                        helmChartLink = "https://arm.seli.gic.ericsson.se/artifactory/${env.HELM_RELEASED_REPO}/eric-eea-int-helm-chart/${env.INT_CHART_NAME}-${env.INT_CHART_VERSION}.tgz"
                        csarRepo = env.CSAR_RELEASED_REPO
                    }

                    // process microservices list
                    def msListLines = ""
                    def statusLines = ""
                    def exepListLine = ""
                    servicesList.each {
                        exepListLine += """
                <tr style='mso-yfti-irow:8'>
                    <td width=217 valign=top style='width:163.1pt;border-top:none;border-left:
                        solid black 1.0pt;border-bottom:solid black 1.0pt;border-right:solid black 1.0pt;
                        padding:0cm 5.4pt 0cm 5.4pt'>
                      <p class=servName>
                        <span style='font-size:11.0pt;font-family:"Ericsson Hilda"'>$it</span>
                        <span style='font-size:11.0pt'>
                          <o:p></o:p>
                        </span>
                      </p>
                    </td>
                </tr>
                        """
                    }
                    servMap.each {k, v ->
                        if (v.status == false) {
                            statusLines += """
                <tr style='mso-yfti-irow:8'>
                    <td width=217 valign=top style='width:163.1pt;border-top:none;border-left:
                        solid black 1.0pt;border-bottom:solid black 1.0pt;border-right:none;
                        padding:0cm 5.4pt 0cm 5.4pt'>
                      <p class=servName>
                        <span style='font-size:11.0pt;font-family:"Ericsson Hilda"'>$k</span>
                        <span style='font-size:11.0pt'>
                          <o:p></o:p>
                        </span>
                      </p>
                    </td>
                    <td width=217 valign=top style='width:163.1pt;border-top:none;border-left:
                        none;border-bottom:solid black 1.0pt;border-right:solid black 1.0pt;
                        padding:0cm 5.4pt 0cm 5.4pt'>
                      <p class=servStatus align=center style='text-align:center'>
                        <span style='font-size:11.0pt;font-family:"Ericsson Hilda"'>disabled</span>
                        <span style='font-size:11.0pt'>
                          <o:p></o:p>
                        </span>
                      </p>
                    </td>
                </tr>
                        """
                        }
                    }
                    msList.each { key, value ->
                        def aliasLines = ""
                        // create microservice alias
                        if (value.alias) {
                            value.alias.eachWithIndex { alias, index ->
                                aliasLines += """
          <p class=MsoNormal>
            <span style='font-size:11.0pt;font-family:"Ericsson Hilda";
             color:black'>$alias</span>
            <span style='font-size:11.0pt'>
              <o:p></o:p>
            </span>
          </p>
                                """
                            }
                        }
                        // create html table colums for microservices
                        msListLines += """
      <tr style='mso-yfti-irow:8'>
        <td width=378 valign=top style='width:283.2pt;border-top:none;border-left:
            solid black 1.0pt;border-bottom:solid black 1.0pt;border-right:none;
            background:white;padding:0cm 5.4pt 0cm 5.4pt'>
          <p class=MsoNormal>
            <span style='font-size:11.0pt;font-family:"Ericsson Hilda";
             color:black'>$key</span>
            <span style='font-size:11.0pt'>
              <o:p></o:p>
            </span>
          </p>
        </td>
        <td width=217 valign=top style='width:163.1pt;border-top:none;border-left:
            none;border-bottom:solid black 1.0pt;border-right:none;
            padding:0cm 5.4pt 0cm 5.4pt'>
          <p class=MsoNormal align=center style='text-align:center'>
            <span style='font-size:11.0pt;font-family:"Ericsson Hilda"'>$aliasLines</span>
            <span style='font-size:11.0pt'>
              <o:p></o:p>
            </span>
          </p>
        </td>
        <td width=217 valign=top style='width:163.1pt;border-top:none;border-left:
            none;border-bottom:solid black 1.0pt;border-right:solid black 1.0pt;
            padding:0cm 5.4pt 0cm 5.4pt'>
          <p class=MsoNormal align=center style='text-align:center'>
            <span style='font-size:11.0pt;font-family:"Ericsson Hilda"'>$value.version</span>
            <span style='font-size:11.0pt'>
              <o:p></o:p>
            </span>
          </p>
        </td>
      </tr>
                        """
                    }
                    def packagesOutsideOfCSARLines = ""
                    // Listing packages outside of CSAR
                    def missingParameterMarkerList = ["N/A", "n/a", "", "NA", "na", "N/a", "n/A", "Na", "nA"]
                    Map packagesOutsideOfCSARList = [
                        "Spotfire Platform (Linux)": LINUX_SPOTFIRE_PLATFORM,
                        "Spotfire Dashboard Data Source": SPOTFIRE_DASHBOARD_DATA_SOURCE,
                        "Spotfire Static Content": SPOTFIRE_STATIC_CONTENT,
                        "Spotfire Utils": SPOTFIRE_UTILS,
                        "Deployer": DEPLOYER_PACKAGE_URL,
                        "Dimensioning Tool": DIMTOOL_PACKAGE_URL
                    ]
                    packagesOutsideOfCSARList.each { key, value ->
                        if(missingParameterMarkerList.contains(value) == false){
                            packagesOutsideOfCSARLines+= "<li><p> $key: <a href=\"$value\">$value</a></p></li>"
                        } else {
                            packagesOutsideOfCSARLines+= "<li><p> $key: N/A</p></li>"
                        }
                    }
                    def mailContent = """<!DOCTYPE html>
<html>
<head>
<style>
<!--
 /* Style Definitions */
 p.MsoNormal, li.MsoNormal, div.MsoNormal
    {mso-style-unhide:no;
    mso-style-qformat:yes;
    mso-style-parent:"";
    margin:0cm;
    mso-pagination:widow-orphan;
    font-size:10.0pt;
    font-family:"Calibri",sans-serif;
    mso-fareast-font-family:Calibri;
    mso-fareast-theme-font:minor-latin;}
-->
</style>
</head>
<body>
<p>Hi All,
<br>
<br>
This is an internal communication that <a href="https://${GERRIT_HOST}/plugins/gitiles/EEA/cnint/+/${RELEASE_NAME}">
    ${RELEASE_NAME}</a> (${EXTENDED_RELEASE_NAME}) with the below package versions was built from
    <a href="${helmChartLink}">
        Product CI Helm chart version ${INT_CHART_VERSION}
    </a>
</p>
<p>
    <a href=" https://arm.seli.gic.ericsson.se/artifactory/proj-eea-reports-generic-local/eea4/test_run_result-${taggedIntChartVersion}.pdf">
        Integration test report ${taggedIntChartVersion}
    </a>
</p>
<p class=MsoNormal><span style='font-size:11.0pt'>&nbsp;<o:p></o:p></span></p>
<table class=MsoNormalTable border=0 cellspacing=0 cellpadding=0 width="58%" style='width:58.02%;border-collapse:collapse;mso-yfti-tbllook:1184;mso-padding-alt:0cm 0cm 0cm 0cm'>
    <tr style='mso-yfti-irow:0;mso-yfti-firstrow:yes'>
        <td width=378 valign=top style='width:283.2pt;border-top:solid black 1.0pt;
            border-left:solid black 1.0pt;border-bottom:none;border-right:none;
            background:#00B0F0;padding:0cm 5.4pt 0cm 5.4pt'>
            <p class=MsoNormal align=center style='text-align:center'>
                <span style='font-size:11.0pt;font-family:"Ericsson Hilda";color:white'>Microservice(s)</span>
                <span style='font-size:11.0pt'>
                    <o:p></o:p>
                </span>
            </p>
        </td>
        <td width=378 valign=top style='width:283.2pt;border-top:solid black 1.0pt;
            border-left:none;border-bottom:none;border-right:none;
            background:#00B0F0;padding:0cm 5.4pt 0cm 5.4pt'>
            <p class=MsoNormal align=center style='text-align:center'>
                <span style='font-size:11.0pt;font-family:"Ericsson Hilda";color:white'>Alias(es)</span>
                <span style='font-size:11.0pt'>
                    <o:p></o:p>
                </span>
            </p>
        </td>
        <td width=217 valign=top style='width:163.1pt;border-top:solid black 1.0pt;
            border-left:none;border-bottom:none;border-right:solid black 1.0pt;
            background:#00B0F0;padding:0cm 5.4pt 0cm 5.4pt'>
            <p class=MsoNormal align=center style='text-align:center'>
                <span style='font-size:11.0pt;font-family:"Ericsson Hilda";color:white'>Package version</span>
                <span style='font-size:11.0pt'>
                    <o:p></o:p>
                </span>
            </p>
        </td>
    </tr>
    ${msListLines}
</table>
<br>
<table class=MsoNormalTable1 border=0 cellspacing=0 cellpadding=0 width="58%" style=''width:58.02%;border-collapse:collapse;mso-yfti-tbllook:1184;mso-padding-alt:0cm 0cm 0cm 0cm'>
    <tr>
        <td colspan="2" width=217 valign=top style='width:163.1pt;border-top:solid black 1.0pt;
            border-left:solid black 1.0pt;border-bottom:none;border-right:solid black 1.0pt;
            background:#00B0F0;padding:0cm 5.4pt 0cm 5.4pt'>
            <p class=MsoNormal align=center style='text-align:center'>
                <span style='font-size:11.0pt;font-family:"Ericsson Hilda";color:white'>List of disabled services based on the values.yaml of the integration helm chart, which can be overwritten with the dataflow and reference configurations of EEA</span>
                <span style='font-size:11.0pt'>
                    <o:p></o:p>
                </span>
            </p>
        </td>
    </tr>
    ${statusLines}
</table>
<br>
<table class=MsoNormalTable2 border=0 cellspacing=0 cellpadding=0 width="58%" style=''width:58.02%;border-collapse:collapse;mso-yfti-tbllook:1184;mso-padding-alt:0cm 0cm 0cm 0cm'>
    <tr>
        <td width=217 valign=top style='width:163.1pt;border-top:solid black 1.0pt;
            border-left:solid black 1.0pt;border-bottom:none;border-right:solid black 1.0pt;
            background:#00B0F0;padding:0cm 5.4pt 0cm 5.4pt'>
            <p class=MsoNormal align=center style='text-align:center'>
                <span style='font-size:11.0pt;font-family:"Ericsson Hilda";color:white'>Services that are not part of the CSAR package</span>
                <span style='font-size:11.0pt'>
                    <o:p></o:p>
                </span>
            </p>
        </td>
    </tr>
    ${exepListLine}
</table>
<br>
<table class=MsoNormalTable3 border=0 cellspacing=0 cellpadding=0 width="58%" style=''width:58.02%;border-collapse:collapse;mso-yfti-tbllook:1184;mso-padding-alt:0cm 0cm 0cm 0cm'>
    <tr>
        <td colspan="2" width=217 valign=top style='width:163.1pt;border-top:solid black 1.0pt;
            border-left:solid black 1.0pt;border-bottom:none;border-right:solid black 1.0pt;
            background:#00B0F0;padding:0cm 5.4pt 0cm 5.4pt'>
            <p class=MsoNormal align=center style='text-align:center'>
                <span style='font-size:11.0pt;font-family:"Ericsson Hilda";color:white'>eea4-utils image and version</span>
                <span style='font-size:11.0pt'>
                    <o:p></o:p>
                </span>
            </p>
        </td>
    </tr>
    <tr style='mso-yfti-irow:8'>
        <td width=217 valign=top style='width:163.1pt;border-top:none;border-left:
            solid black 1.0pt;border-bottom:solid black 1.0pt;border-right:none;
            padding:0cm 5.4pt 0cm 5.4pt'>
          <p class=servName>
            <span style='font-size:11.0pt;font-family:"Ericsson Hilda"'>${env.UTILS_IMAGE_NAME}</span>
            <span style='font-size:11.0pt'>
              <o:p></o:p>
            </span>
          </p>
        </td>
        <td width=217 valign=top style='width:163.1pt;border-top:none;border-left:
            none;border-bottom:solid black 1.0pt;border-right:solid black 1.0pt;
            padding:0cm 5.4pt 0cm 5.4pt'>
          <p class=servStatus align=center style='text-align:center'>
            <span style='font-size:11.0pt;font-family:"Ericsson Hilda"'>${env.UTILS_VERSION}</span>
            <span style='font-size:11.0pt'>
              <o:p></o:p>
            </span>
          </p>
        </td>
    </tr>
</table>
<br>
<p><strong>Note 1</strong>: CSAR file can be found here:</p>
<ul>
    <li><a href="${csarRepo}csar-package-${INT_CHART_VERSION}.csar">
        ${csarRepo}csar-package-${INT_CHART_VERSION}.csar</a>
    </li>
</ul>
<p><strong>Note 2</strong>: Packages outside of the CSAR file can be found here:</p>
<ul>
    ${packagesOutsideOfCSARLines}
</ul>
<p>If you have any questions, please contact EEA Release Team (<a href="mailto:pdleearele@pdl.internal.ericsson.com">pdleearele@pdl.internal.ericsson.com</a>) directly as EEA Release Information mailbox is rarely checked for incoming messages.
<br>
<br>
Best regards,<br>
EEA Release Team</p>
</body>
</html>
                    """
                    // write content to file and archive it
                    writeFile(file: "${WORKSPACE}/${env.RELEASE_MAIL_FILENAME}", text: mailContent)
                    archiveArtifacts "*.html"
                }
            }
        }

        stage('Create RC or Weekly Drop git tag') {
            when {
                expression { params.RELEASE_NAME && "${GIT_COMMIT_ID}" && !params.SKIP_GIT_TAGGING}
            }
            steps {
                dir('adp-app-staging') {
                    withCredentials([usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')])
                    {
                        withEnv(["GIT_TAG_STRING=${RELEASE_NAME}","CHART_VERSION=${taggedIntChartVersion}"]){
                            sh "./bob/bob -r ${WORKSPACE}/adp-app-staging/${env.RELEASE_RULESET_FILENAME} create-git-tag-rc"
                        }
                    }
                }
            }
        }

        stage('Send release data to App Dashboard') {
            when {
                expression { params.RELEASE_NAME && "${GIT_COMMIT_ID}" && !params.SKIP_DASHBOARD_SENDING}
            }
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    script {
                        def chartPath = "${env.INT_CHART_NAME}-${env.INT_CHART_VERSION}.tgz"
                        echo "download helm chart"
                        withCredentials([string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
                            def arm = new Artifactory(this, "${HELM_REPO_URL}/", "${API_TOKEN_EEA}")
                            if (env.INT_CHART_VERSION.contains('+')){
                                arm.setRepo("${env.HELM_RELEASED_REPO}")
                            } else {
                                arm.setRepo("${env.HELM_DROP_REPO}")
                            }
                            arm.downloadArtifact("${env.INT_CHART_NAME}/${chartPath}", "${chartPath}")
                        }
                        echo "upload chart to dashboard"
                        dashboard.uploadHelm("${chartPath}", "${env.INT_CHART_VERSION}")
                        echo "start execution"
                        dashboard.startExecution("eea-rc", "${env.BUILD_URL}", "${params.RELEASE_NAME}")
                        dashboard.finishExecution("eea-rc", "SUCCESS", "${params.RELEASE_NAME}", "${env.INT_CHART_VERSION}")
                    }
                }
            }
        }

        stage('Send release mail') {
            when { expression { !params.SKIP_EMAIL_SENDING } }
            steps {
                script{
                    def recipientList = ['PDLEEARELE@pdl.internal.ericsson.com',  // EEA Release Team
                                        ]
                    def recipient = recipientList.join(', ')
                    def emailSubject = "${RELEASE_NAME} (v${INT_CHART_VERSION})"
                    def emailBody = readFile(file: "${WORKSPACE}/${env.RELEASE_MAIL_FILENAME}")
                    mail subject: "${emailSubject}",
                        body: "${emailBody}",
                        mimeType: 'text/html',
                        to: "${recipient}",
                        replyTo: "${recipient}",
                        from: 'eea-seliius27190@ericsson.com'
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
