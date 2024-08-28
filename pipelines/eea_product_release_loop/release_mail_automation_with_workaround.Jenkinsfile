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
def csarExceptionList = [  'eric-eea-mxe',
                        'eric-eea-mxe-data-document-database-pg',
                        'eric-mesh-controller',
                        'eric-mesh-gateways',
                        'eric-mxe-pm-server'
                        ] // workaround for no-mxe csar

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
    }

    environment {
        INT_CHART_NAME = 'eric-eea-int-helm-chart'
        INT_CHART_REPO = 'https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-generic-local/'
        RELEASE_MAIL_FILENAME = 'release-mail-content.html'
        RELEASE_RULESET_FILENAME = 'ruleset2.0_product_release.yaml'
        HELM_REPO_URL = 'https://arm.seli.gic.ericsson.se'
        HELM_REPO = 'proj-eea-drop-helm-local'
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
                    gitcnint.checkout(env.INT_CHART_VERSION, 'cnint')
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
                        msList = msList.findAll{csarExceptionList.contains(it.key) == false }.each { key_, value_ ->
                            value_['alias'] = value_['alias'].minus(csarExceptionList)
                        } // workaround for no-mxe csar
                    }
                }
            }
        }

        stage('Parse csar_exception_list') {
            steps {
                dir ('csarworkdir') {
                    script {
                        if (params.INT_CHART_VERSION == '') {
                            CHART_VER = 'master'
                        } else {
                            CHART_VER = params.INT_CHART_VERSION
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
                    // process microservices list
                    def msListLines = ""
                    def statusLines = ""
                    def exepListLine = ""
                    csarExceptionList.each {
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
    <a href="https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm-local/eric-eea-int-helm-chart/${env.INT_CHART_NAME}-${env.INT_CHART_VERSION}.tgz">
        Product CI Helm chart version ${INT_CHART_VERSION}
    </a>
</p>
<p>
    <a href=" https://arm.seli.gic.ericsson.se/artifactory/proj-eea-reports-generic-local/eea4/test_run_result-${env.INT_CHART_VERSION}.pdf">
        Integration test report ${INT_CHART_VERSION}
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
<p><strong>Note 1</strong>: CSAR (without MXE) file can be found here:</p>
<ul>
    <li><a href="${env.INT_CHART_REPO}csar-package-no-mxe-${INT_CHART_VERSION}.csar">
        ${env.INT_CHART_REPO}csar-package-no-mxe-${INT_CHART_VERSION}.csar</a>
    </li>
    <ul>
        <li>
            This package can be used without MXE only. MXE 2.7 version does not have security approval to release. CPI is still having MXE references. Also test reports, integration helm chart descriptions, content files may have MXE related information, but the MXE images are not released, so those cannot be deployed and used.
        </li>
        <li>
            Installation is possible only with same additional Install Scenario B that was released in 4.9 PRA.
        </li>
        <li>
            It is not possible to upgrade a baseline with MXE included. MXE upgrade steps will require same MXE disabling steps as the install steps.
        </li>
    </ul>
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

        stage('Send release mail') {
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
