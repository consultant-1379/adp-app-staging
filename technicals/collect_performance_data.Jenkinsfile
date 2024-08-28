@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import java.text.SimpleDateFormat
import com.ericsson.eea4.ci.Notifications
import com.ericsson.eea4.ci.ClusterLogUtils

@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def notif = new Notifications(this)

@Field def clusterLogUtilsInstance = new ClusterLogUtils(this)

def upStreamJob

properties([ [ $class: 'ThrottleJobProperty',
              categories: ['simpleThrottleCatagory'],
              limitOneJobWithMatchingParams: false,
              maxConcurrentPerNode: 1,
              maxConcurrentTotal: 3,
              paramsToUseForLimit: '',
              throttleEnabled: true,
              throttleOption: 'project' ] ])

pipeline {
    options {
        buildDiscarder(logRotator(daysToKeepStr:'14', artifactDaysToKeepStr: '7'))
        skipDefaultCheckout()
    }
    agent {
        node {
            label 'productci'
        }
    }
    parameters {
        string(name: 'CLUSTER', description: 'cluster resource id', defaultValue: '')
        string(name: 'START_EPOCH', description: 'The start epoch time in sec', defaultValue: '')
        string(name: 'END_EPOCH', description: 'The end epoch time in sec', defaultValue: '')
        string(name: 'SPINNAKER_TRIGGER', description: 'Spinnaker pipeline triggering execution id', defaultValue: '')
        string(name: 'ADP_APP_STAGING_GERRIT_REFSPEC', description: 'EEA/adp-app-staging gerrit refspec. If not set than will checked out the master', defaultValue: '')
    }

    environment {
        OUTPUT_DIR = "/home/eceabuild/seliius27190/ci_resource_usage/"
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

        stage('Cleanup workspace') {
            steps {
                script {
                    cleanWs()
                }
            }
        }

        stage('Checkout'){
            steps{
                script {
                    if ( env.ADP_APP_STAGING_GERRIT_REFSPEC ) {
                        gitadp.checkoutRefSpec("${env.ADP_APP_STAGING_GERRIT_REFSPEC}", "FETCH_HEAD", '')
                    } else {
                        gitadp.checkoutRefSpec("master", "FETCH_HEAD", '')
                    }
                }
            }
        }


        stage('Check params') {
            steps {
                script {
                    currentBuild.description = "Cluster name: $params.CLUSTER"
                    if (!params.CLUSTER?.trim()) {
                        error "CLUSTER resource should be specified!"
                    }
                    currentBuild.description += "<br>startEpoc: $params.START_EPOCH"
                    if (!params.START_EPOCH?.trim()) {
                        error "START_EPOCH resource should be specified!"
                    }
                    currentBuild.description += "<br>endEpoc: $params.END_EPOCH"
                    if (!params.END_EPOCH?.trim()) {
                        error "END_EPOCH resource should be specified!"
                    }

                }
            }
        }

        stage('Prepare bob') {
            steps {
                checkoutGitSubmodules()
            }
        }

        stage('Get port') {
            steps {
                timeout(time: 1, unit: 'MINUTES') {
                    script {
                        withCredentials([ file(credentialsId: params.CLUSTER, variable: 'KUBECONFIG')]){
                            sh 'bob/bob get-load-balancer-service -r rulesets/performance_db_rules.yaml > get-port.log'
                            def data = readYaml file: ".bob/loadbalancer.yaml"
                            env.VICTORIA_PORT= "${data.status.loadBalancer.ingress.ip[0]}:${data.spec.ports.port[0]}/select/0/prometheus"
                            archiveArtifacts  artifacts:".bob/loadbalancer.yaml", allowEmptyArchive: true
                            archiveArtifacts  artifacts:"get-port.log", allowEmptyArchive: true
                            echo "port param: ${env.VICTORIA_PORT}"
                        }
                    }
                }
            }
        }

        stage('Set BUILD_NAME') {
            steps {
                script {
                  upStreamJob = currentBuild.getFullDisplayName().replace(' #', '__')
                  currentBuild.upstreamBuilds?.each { b ->
                      upStreamJob = b.getFullDisplayName().replace(' #', '__')
                  }
                  env.BUILD_NAME =  "${params.SPINNAKER_TRIGGER}_" + upStreamJob
                }
            }
        }

        stage('Call eea4_perf_report.sh') {
            steps {
                script {
                    catchError(stageResult: 'FAILURE', buildResult: 'FAILURE') {
                        withCredentials([ usernamePassword(credentialsId: 'seliics00309_logstash_system', usernameVariable: 'LOGSTASH_SYSTEM_USERNAME', passwordVariable: 'LOGSTASH_SYSTEM_PASSWORD'),
                            usernamePassword(credentialsId: 'seliics00309_logstash_writer', usernameVariable: 'LOGSTASH_WRITER_USERNAME', passwordVariable: 'LOGSTASH_WRITER_PASSWORD')
                        ]){
                            sh '''sed -i "s#^logstash_etc_files_dir=.*#logstash_etc_files_dir=\"${WORKSPACE}/cluster_tools/perf_dashboard/logstash\"/#" technicals/shellscripts/eea4_perf_report.sh  '''
                            sh '''sed -i "s#^logstash_config=.*#logstash_config=\"${WORKSPACE}/cluster_tools/perf_dashboard/eea4_metrics.conf\"#" technicals/shellscripts/eea4_perf_report.sh '''
                            sh '''mkdir -p \"${WORKSPACE}/performance/logs\" '''
                            sh '''sed -i "s#^perf_logs_dir=.*#perf_logs_dir=\"${WORKSPACE}/performance/logs\"#" technicals/shellscripts/eea4_perf_report.sh '''
                            sh '''sed -i "s#ELASTICSEARCH_PASSWORD#${LOGSTASH_SYSTEM_PASSWORD}#" cluster_tools/perf_dashboard/logstash/logstash.yml '''
                            sh '''sed -i "s#NODE_HOSTNAME#$(hostname)#" cluster_tools/perf_dashboard/logstash/logstash.yml '''
                            sh '''sed -i "s#ELASTICSEARCH_PASSWORD#${LOGSTASH_WRITER_PASSWORD}#" cluster_tools/perf_dashboard/eea4_metrics.conf '''
                            sh '''./technicals/shellscripts/eea4_perf_report.sh -s ${START_EPOCH} -e ${END_EPOCH} -o ${WORKSPACE}/performance/logs -b ${BUILD_NAME} -c ${CLUSTER} -y'''
                            sh '''tar czf "eea4_perf_report_${BUILD_NAME}.tgz" performance/ '''
                            archiveArtifacts artifacts: "eea4_perf_report_${env.BUILD_NAME}.tgz", allowEmptyArchive: true
                        }
                    }
                }
            }
        }

        stage('Add Grafana url') {
            steps {
                script {
                    clusterLogUtilsInstance.addGrafanaUrlToJobDescription(env.START_EPOCH, env.END_EPOCH, params.SPINNAKER_TRIGGER, upStreamJob)
                }
            }
        }
    }
     post {
        failure {
            script {
                try {
                    notif.sendMail("${env.JOB_NAME} (${env.BUILD_NUMBER}) performance data collection failed","${env.BUILD_URL} performance data collections failed on cluster ${params.CLUSTER}","b973ce22.ericsson.onmicrosoft.com@emea.teams.ms")
                }
                catch (err) {
                    echo "Caught: ${err}"
                }
            }
        }
    }
}
