@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def git = new GitScm(this, 'EEA/adp-app-staging')

def confluence_pages = []

pipeline {
    agent {
        node {
            label 'productci'
        }
    }

    options {
      skipDefaultCheckout()
      buildDiscarder(logRotator(daysToKeepStr: "7"))
    }

    tools{
        gradle "Default"
    }

    parameters{
        string(name: 'GERRIT_REFSPEC', description: 'Specify Refspec of the change, or LEAVE EMPTY to generate ALL documents!', defaultValue:"")
    }

    environment {
        CONFLUENCE_ANCESTOR= 'Auto-generated documentation from adp-app-staging'
        CONFLUENCE_API_URL = 'https://eteamspace.internal.ericsson.com/rest/api'
        CONFLUENCE_SPACE_KEY='ECISE'
    }

    triggers {
        gerrit (
            serverName: 'GerritCentral',
            gerritProjects: [[
                compareType: 'PLAIN',
                pattern: 'EEA/adp-app-staging',
                branches: [[ compareType: 'PLAIN', pattern: env.MAIN_BRANCH ]],
                filePaths: [[ compareType: 'ANT', pattern: '**/*.md' ]]
            ]],
            triggerOnEvents:  [
                [
                    $class              : 'PluginChangeMergedEvent',
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

        stage('Checkout') {
            steps {
                script {
                    if ( env.GERRIT_REFSPEC ) {
                        git.checkoutRefSpec("${env.GERRIT_REFSPEC}", "FETCH_HEAD", 'adp-app-staging')
                    } else {
                        git.checkoutRefSpec("master", "FETCH_HEAD", 'adp-app-staging')
                    }
                }
            }
        }

        stage('MD convert and upload to Confluence') {
            steps {
                dir('adp-app-staging') {
                    script {
                        def errors = []
                            def files
                            echo "env.GERRIT_REFSPEC: ${env.GERRIT_REFSPEC}"
                            if ( env.GERRIT_REFSPEC ) {
                                // generate only files in this patschet
                                sh 'git diff-tree --no-commit-id --name-only -r HEAD --diff-filter=ACMRT -- | grep .md$ | tee md_files'
                                def result = readFile("md_files")
                                if (result.size() != 0) {
                                    files = result.split("\\r?\\n")
                                }
                            } else {
                                // if no refspec, generate all files
                                sh 'find . -name "*.md" -printf "%P\n" | tee md_files'
                                def result = readFile("md_files")
                                if (result.size() != 0) {
                                    files = result.split("\\r?\\n")
                                }
                            }
                            echo "List of md_files: ${files}"
                            if (files) {
                                for (filename in files) {

                                    try {
                                        def gitiles_link = "https://${GERRIT_HOST}/plugins/gitiles/EEA/adp-app-staging/+/refs/heads/master/" + filename
                                        def confluence_preface=$/<p><span style="color: rgb(255,0,0);"><strong>Warning:</strong></span> this page was <span style="color: rgb(255,0,0);"><strong>automatically generated</strong></span> from <a class="external-link" href="${gitiles_link}" rel="nofollow" style="text-decoration: underline;">${gitiles_link}</a><br/><span style="color: rgb(255,0,0);"><strong>Do not edit!</strong></span></p>/$
                                        withCredentials([string(credentialsId: 'confluence-api-token', variable: 'CONFLUENCE_API_TOKEN')]) {
                                            echo """python3 ${WORKSPACE}/adp-app-staging/technicals/pythonscripts/markdown_to_confluence.py --host "${CONFLUENCE_API_URL}" --token "${CONFLUENCE_API_TOKEN}" --space "${CONFLUENCE_SPACE_KEY}" --parent-title "${CONFLUENCE_ANCESTOR}" --preface-markdown '${confluence_preface}' "${filename}" --debug"""
                                            sh """python3 ${WORKSPACE}/adp-app-staging/technicals/pythonscripts/markdown_to_confluence.py --host "${CONFLUENCE_API_URL}" --token "${CONFLUENCE_API_TOKEN}" --space "${CONFLUENCE_SPACE_KEY}" --parent-title "${CONFLUENCE_ANCESTOR}" --preface-markdown '${confluence_preface}' "${filename}" --debug"""
                                            confluence_pages.add(filename)
                                        }
                                    } catch (err) {
                                        echo "Caught Error: ${err}"
                                        errors.add(filename)
                                    }
                                }
                            }
                        // check collected errors and fail stage if there are any
                        if ( errors ) {
                            error "There were ERRORS in the following documentations: " + errors.join(', ')
                        }
                    }
                }
            }
        }
    }
    post {
        success {
            dir('adp-app-staging') {
                script {
                    try {
                        if ( env.GERRIT_REFSPEC ) {
                            def confluence_pages_list = confluence_pages.join(', ')
                            def gerrit_message = "Generated page(s): ${confluence_pages_list}"
                            sendMessageToGerrit(env.GERRIT_REFSPEC,  gerrit_message)
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
