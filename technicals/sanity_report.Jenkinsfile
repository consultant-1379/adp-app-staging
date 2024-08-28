@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def git = new GitScm(this, 'EEA/adp-app-staging')

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
                script{
                    git.checkoutRefSpec("${GERRIT_REFSPEC}","FETCH_HEAD", 'adp-app-staging')
                }
            }
        }

        stage('MD convert and upload to confluence'){
            steps {
                dir('adp-app-staging'){
                    script {
                        try{
                            sh "technicals/shellscripts/sanity_report.sh > sanity_report.md"
                            withCredentials([usernamePassword(credentialsId: 'confluence-user', usernameVariable: 'CONFLUENCE_USER', passwordVariable: 'CONFLUENCE_PASSWORD')]) {
                                sh "python3 ${WORKSPACE}/adp-app-staging/technicals/pythonscripts/md_to_conf.py sanity_report.md ECISE -u ${CONFLUENCE_USER} -p ${CONFLUENCE_PASSWORD} -o eteamspace.internal.ericsson.com --nogo -a \"Auto-generated documentation from adp-app-staging\" -w '<p><span style=\"color: rgb(255,0,0);\"><strong>Warning:</strong></span> this page was <span style=\"color: rgb(255,0,0);\"><strong>automatically generated</strong></span> from a dynamic dataset<br/><span style=\"color: rgb(255,0,0);\"><strong>Do not edit!</strong></span></p>'"
                            }
                        }
                        catch (err) {
                            echo "Caught: ${err}"
                            currentBuild.result = 'FAILURE'
                        }
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
