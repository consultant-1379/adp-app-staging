@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def git_adp = new GitScm(this, 'EEA/adp-app-staging')
@Field def git_env = new GitScm(this, 'EEA/environment')
@Field def git_inv = new GitScm(this, 'EEA/inv_test')

pipeline {
    agent{
        node {
            label 'productci'
        }
    }
    options {
      skipDefaultCheckout()
      buildDiscarder(logRotator(daysToKeepStr: "7"))
    }

    triggers { cron('*/15 * * * *') }

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
        stage('Run when run in Jenkins master'){
          when {
            expression { env.MAIN_BRANCH == 'master' }
          }
          stages{
            stage('Checkout adp-app-staging'){
                steps{
                    script{
                        git_adp.checkout(env.MAIN_BRANCH, 'adp-app-staging')
                    }
                }
            }
            stage('Checkout inv repo'){
                steps{
                    dir('inv_full_checkout'){
                      script{
                          git_inv.checkout(env.MAIN_BRANCH, 'inv_test')
                      }
                  }
                }
            }
            stage('Collect cluster  infos'){
                steps{
                    script {
                        sh """
                          if [ -d "${WORKSPACE}/product_ci_cluster_infos" ]; then rm -rf "${WORKSPACE}/product_ci_cluster_infos"; fi

                          mkdir -p "${WORKSPACE}/product_ci_cluster_infos/cluster_inventories"
                          cp "${WORKSPACE}/inv_full_checkout/inv_test/eea4/scripts/cluster_info_collector/cluster_info_collector.py" "${WORKSPACE}/product_ci_cluster_infos/"
                          cp -r "${WORKSPACE}"/inv_full_checkout/inv_test/eea4/cluster_inventories/cluster_productci_* "${WORKSPACE}/product_ci_cluster_infos/cluster_inventories"
                          cp "${WORKSPACE}/adp-app-staging/technicals/product_ci_config_eea4.yml" "${WORKSPACE}/product_ci_cluster_infos/"
                          cd product_ci_cluster_infos
                          python3 cluster_info_collector.py --config_file product_ci_config_eea4.yml
                          sed -i 's/&lt;/</g' Output.html
                          sed -i 's/&quot;/"/g' Output.html
                          sed -i 's/&gt;/>/g' Output.html

                          cd "${WORKSPACE}"
                          "${WORKSPACE}/adp-app-staging/technicals/shellscripts/check_clusters_status.sh"
                        """
                        publishHTML (target: [
                          allowMissing: true,
                          alwaysLinkToLastBuild: false,
                          keepAll: false,
                          reportDir: "./product_ci_cluster_infos/",
                          reportFiles: 'Output.html',
                          reportName: "Product_CI_cluster_infos"
                        ])
                        archiveArtifacts artifacts: 'product_ci_cluster_infos/Output.html', allowEmptyArchive: true
                        archiveArtifacts artifacts: 'product_ci_cluster_infos/*.info', allowEmptyArchive: true
                    }
                }
            }

          }
        }
    }
    post {
        always {
            script {
              if(fileExists('clusters.status')) {
                def emailBody = readFile(file: 'clusters.status')
                echo "${emailBody}"
                def recipient = 'PDLEEA4PRO@pdl.internal.ericsson.com'
                mail subject: "${env.JOB_NAME} (${env.BUILD_NUMBER}) issue(s) on ProductCI clusters",
                body:  "${emailBody}",
                mimeType: 'text/html',
                to: "${recipient}",
                replyTo: "${recipient}",
                from: 'eea-seliius27190@ericsson.com'
              }
            }
        }
        failure {
            script{
              if (env.MAIN_BRANCH == 'master') {
                def recipient = 'PDLEEA4PRO@pdl.internal.ericsson.com'
                mail subject: "${env.JOB_NAME} (${env.BUILD_NUMBER}) failed",
                body: "It appears that ${env.BUILD_URL} is failing, somebody should do something about that",
                to: "${recipient}",
                replyTo: "${recipient}",
                from: 'eea-seliius27190@ericsson.com'
              }
            }
        }
        cleanup {
          cleanWs()
        }
    }
}
