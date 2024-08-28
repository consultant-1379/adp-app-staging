@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field
import com.ericsson.eea4.ci.GlobalVars
import com.ericsson.eea4.ci.CiDashboard
import com.ericsson.eea4.ci.ClusterLockUtils

@Field def vars = new GlobalVars()
@Field def gitadp = new GitScm(this, 'EEA/adp-app-staging')
@Field def git_inv = new GitScm(this, 'EEA/inv_test')
@Field def dashboard = new CiDashboard(this)
@Field def clusterLockUtils = new ClusterLockUtils(this)

@Field def vars_ProdCI_Clusters = GlobalVars.Clusters.values().findAll{ it.owner.contains('product_ci') }.collect { it.resource }.sort()

def clusterNameWithHyphens = "${params.CLUSTER_NAME}".replaceAll('_','-')

pipeline {
    options {
        buildDiscarder(logRotator(daysToKeepStr: '30', artifactNumToKeepStr: "30"))
    }
    agent {
        node {
            label 'productci'
        }
    }
    parameters {
        choice(
            name: 'CLUSTER_NAME',
            description: 'Cluster to validate - credential ID needed',
            choices: ['-'] + vars_ProdCI_Clusters
        )
        choice(
            name: 'CCD_VERSION',
            description: 'Select CCD version to install',
            choices: [
                '2.27.0',
                '2.26.0',
                '2.25.0',
                '2.28.0'
            ]
        )
       choice(
            name: 'ROOK_VERSION',
            description: """Select ROOK version to install.
                <table>
                  <tr>
                    <th>Rook version</th>
                    <th>Ceph version</th>
                    <th>CCD version</th>
                  </tr>
                  <tr>
                    <td>1.13.7</td>
                    <td>18.2.2</td>
                    <td>CCD >= 2.27.0</td>
                  </tr>
                  <tr>
                    <td>1.13.1</td>
                    <td>18.2.1</td>
                    <td>CCD >= 2.27.0</td>
                  </tr>
                  <tr>
                    <td>1.11.4</td>
                    <td>17.2.6</td>
                    <td>CCD < 2.27.0</td>
                  </tr>
                  <tr>
                    <td>ccd-built-in</td>
                    <td>-</td>
                    <td>CCD >= 2.27.0. Deploy the rook and ceph versions which are delivered in CCD package</td>
                  </tr>
                </table>""",
            choices: [
                '1.11.4',
                'ccd-built-in',
                '1.13.1',
                '1.13.7'
            ]
        )
        choice(
            name: 'MAX_PODS',
            choices: [
                '200',
                '170'
            ],
            description: 'Increase the maximum number of allocable pods per worker nodes (default is 200).<br> <p style="color:red">IMPORTANT: Set this to 200 if having 4 or less workers in your cluster. Otherwise leave on the default value.</p>'
        )
        string(
            name: 'REFSPEC',
            defaultValue: '',
            description: '[ADVANCED OPTION] e.g. refs/changes/36/12185636/1'
        )
        string(
            name: 'OS_INSTALL_TARGETS',
            defaultValue: 'master,worker',
            description: '[ADVANCED OPTION] DO NOT USE IT. If changing default value, then job will only install SLES SPx OS on the specified nodes, then exit. Otherwise OS install will happen on all the k8s nodes right before CCD re-installation'
        )
        string(name: 'REINSTALL_LABEL', description: 'Cluster label to be set during reinstall process', defaultValue: 'reinstall')
        booleanParam(name: 'EXECUTE_CLUSTER_VALIDATE', description: 'This parametr used by test new CCD version. Do not change it manualy!', defaultValue: true)
        booleanParam(name: 'EXECUTE_RV_CCD_INSTALL', defaultValue: true, description: 'Execute RV CCD install job or not')
        booleanParam(
            name: 'SET_CEPH_MIN_DIMENSIONING',
            defaultValue: true,
            description: """Minimize Rook/Ceph dimensioning values.
            Recommended for small development clusters to save resources.<br>
            <p style="color:red">This option is ignored if using ccd-built-in Rook/Ceph.</p>
            """
        )
        choice(
            name: 'OS_INSTALL_METHOD',
            choices: [
                'parallel',
                'one-by-one'
            ],
            description: 'How to do the OS install when execute RV_CCI_INSTALL job'
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

        stage('Cluster param check') {
            when {
                expression { params.CLUSTER_NAME == '' }
            }
            steps {
                script {
                    currentBuild.result = 'ABORTED'
                    error("CLUSTER_NAME is empty")
                }
            }
        }

        stage('Checkout') {
            steps {
                script {
                    gitadp.checkout('master', '')
                }
            }
        }

        stage('inv_test Checkout') {
            steps {
                script {
                    git_inv.checkout(env.MAIN_BRANCH, 'inv_test')
                }
            }
        }

        stage('Resource locking - Cluster reinstall') {
            options {
                lock resource: "${clusterNameWithHyphens}", quantity: 1, variable: 'system'
            }
            stages {
                stage('Log locked resource') {
                    steps {
                        echo "Locked cluster: $system"
                        script {
                            currentBuild.description = "Locked cluster: $system"
                        }
                    }
                }

                stage('Change cluster label') {
                    steps {
                        build job: 'lockable-resource-label-change',
                        parameters: [
                            stringParam(name: 'DESIRED_CLUSTER_LABEL', value: "${params.REINSTALL_LABEL}"),
                            stringParam(name: 'CLUSTER_NAME', value: "${clusterNameWithHyphens}"),
                            booleanParam(name: 'RESOURCE_RECYCLE', value: false)
                        ]
                    }
                }

                stage('Get CLUSTER_INV_NAME') {
                    steps {
                        script {
                            def clusterItem = GlobalVars.Clusters.values().find{ it.resource.contains(params.CLUSTER_NAME ) }
                            env.CLUSTER_INV_NAME = clusterItem.inv_name
                        }
                    }
                }

                stage('RV CCD install - OS install parallel way') {
                    when {
                        expression { params.EXECUTE_RV_CCD_INSTALL == true && params.OS_INSTALL_METHOD == 'parallel'}
                    }
                    steps {
                            build job: 'rv-ccd-install',
                            parameters: [
                                stringParam(name: 'CLUSTER_NAME', value: "${env.CLUSTER_INV_NAME}"),
                                stringParam(name: 'CCD_VERSION', value: "${params.CCD_VERSION}"),
                                stringParam(name: 'ROOK_VERSION', value: "${params.ROOK_VERSION}"),
                                stringParam(name: 'MAX_PODS', value: "${params.MAX_PODS}"),
                                stringParam(name: 'REFSPEC', value: "${params.REFSPEC}"),
                                stringParam(name: 'OS_INSTALL_TARGETS', value: "${params.OS_INSTALL_TARGETS}"),
                                booleanParam(name: 'UPDATE_CREDENTIALS', value: false),
                                booleanParam(name: 'SET_CEPH_MIN_DIMENSIONING', value: "${params.SET_CEPH_MIN_DIMENSIONING}")
                            ]
                    }
                }

                stage('RV CCD install - OS Install one-by-one') {
                    when {
                        expression { params.EXECUTE_RV_CCD_INSTALL == true && params.OS_INSTALL_METHOD == 'one-by-one' }
                    }
                    steps {
                        script {
                            sh """
                            docker run  -v \$(pwd):/container/jenkins_job_home \
                            armdocker.rnd.ericsson.se/dockerhub-ericsson-remote/willhallonline/ansible:2.9-alpine-3.16 \
                            sh -c  "
                             ansible all -i /container/jenkins_job_home/inv_test/eea4/cluster_inventories/"\$CLUSTER_INV_NAME"/hosts --list-hosts --limit=master | grep -v 'hosts.*' | sed -E 's/^[[:space:]]+//g' - > /container/jenkins_job_home/hosts.txt
                             ansible all -i /container/jenkins_job_home/inv_test/eea4/cluster_inventories/"\$CLUSTER_INV_NAME"/hosts --list-hosts --limit=worker | grep -v 'hosts.*' | sed -E 's/^[[:space:]]+//g' - >> /container/jenkins_job_home/hosts.txt
                            "
                            """
                            def hostFile = readFile "hosts.txt"
                            def hostFileLines = hostFile.readLines()
                            hostFileLines.each { String hostFileLine ->
                                println hostFileLine
                                // first install ONLY the OS (without CCD) for every node, one-by-one
                                build job: 'rv-ccd-install',
                                parameters: [
                                    stringParam(name: 'CLUSTER_NAME', value: "${env.CLUSTER_INV_NAME}"),
                                    stringParam(name: 'CCD_VERSION', value: "${params.CCD_VERSION}"),
                                    stringParam(name: 'ROOK_VERSION', value: "${params.ROOK_VERSION}"),
                                    stringParam(name: 'MAX_PODS', value: "${params.MAX_PODS}"),
                                    stringParam(name: 'REFSPEC', value: "${params.REFSPEC}"),
                                    stringParam(name: 'OS_INSTALL_TARGETS', value: hostFileLine),
                                    booleanParam(name: 'SKIP_OS_INSTALL', value: false),
                                    booleanParam(name: 'UPDATE_CREDENTIALS', value: false)
                                ]
                            }

                            // then install ONLY the CCD (without OS) to the whole cluster
                            build job: 'rv-ccd-install',
                            parameters: [
                                stringParam(name: 'CLUSTER_NAME', value: "${env.CLUSTER_INV_NAME}"),
                                stringParam(name: 'CCD_VERSION', value: "${params.CCD_VERSION}"),
                                stringParam(name: 'ROOK_VERSION', value: "${params.ROOK_VERSION}"),
                                stringParam(name: 'MAX_PODS', value: "${params.MAX_PODS}"),
                                stringParam(name: 'REFSPEC', value: "${params.REFSPEC}"),
                                stringParam(name: 'OS_INSTALL_TARGETS', value: "master,worker"),
                                booleanParam(name: 'SKIP_OS_INSTALL', value: true),
                                booleanParam(name: 'UPDATE_CREDENTIALS', value: false),
                                booleanParam(name: 'SET_CEPH_MIN_DIMENSIONING', value: "${params.SET_CEPH_MIN_DIMENSIONING}")
                            ]
                        }
                    }
                }

                stage('Apply jenkins service account user RBAC to cluster') {
                    steps {
                        script {
                            def k8sMasterHost = sh (script: '''
                            grep -FA1 [master] inv_test/eea4/cluster_inventories/${CLUSTER_INV_NAME}/hosts | tail -1
                            ''',
                            returnStdout: true).trim()
                            env.MASTER_IP = sh (script: """
                            getent hosts $k8sMasterHost | awk '{ print \$1 }'
                            """,
                            returnStdout: true).trim()
                        }
                        withCredentials([usernamePassword(credentialsId: 'k8s-master-workers-default-user-pass', usernameVariable: 'K8S_USER', passwordVariable: 'K8S_PASSWORD')]) {
                            sh '''
                            ssh-keygen -R ${MASTER_IP}
                            sshpass -p $K8S_PASSWORD scp -o StrictHostKeyChecking=no cluster_tools/jenkins_rbac.yml ${K8S_USER}@${MASTER_IP}:
                            sshpass -p $K8S_PASSWORD ssh -o StrictHostKeyChecking=no ${K8S_USER}@${MASTER_IP} 'kubectl apply -f jenkins_rbac.yml'
                            '''

                            sh '''
                            function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\\n", $1,$2,$3,$4); }'; }

                            kubernetesVersion_=$(sshpass -p $K8S_PASSWORD ssh -o StrictHostKeyChecking=no ${K8S_USER}@${MASTER_IP} 'kubectl version -o json | jq -r ".serverVersion.gitVersion"')
                            kubernetesVersion="${kubernetesVersion_:1}"
                            echo "kubernetesVersion: ${kubernetesVersion}"

                            if [ $(version $kubernetesVersion) -gt $(version "1.24.999") ]; then
                                sshpass -p $K8S_PASSWORD scp -o StrictHostKeyChecking=no cluster_tools/jenkins_secret.yml ${K8S_USER}@${MASTER_IP}:
                                sshpass -p $K8S_PASSWORD ssh -o StrictHostKeyChecking=no ${K8S_USER}@${MASTER_IP} 'kubectl apply -f jenkins_secret.yml'
                            fi
                            '''
                        }
                    }
                }

                stage('Update kubeconfig in Jenkins') {
                    steps {
                        build job: 'credentials-update-job',
                        parameters: [
                            stringParam(name: 'MASTER_IP', value: "${env.MASTER_IP}"),
                            stringParam(name: 'CREDENTIAL_ID', value: "${clusterNameWithHyphens}"),
                            booleanParam(name: 'JENKINS_CREDENTIAL', value: true)
                        ]

                        step([$class: 'RemoteBuildConfiguration',
                            auth2 : [$class: 'CredentialsAuth', credentials:'test-jenkins-token' ],
                            remoteJenkinsName : 'test-jenkins',
                            remoteJenkinsUrl : 'https://seliius27102.seli.gic.ericsson.se:8443/',
                            job: 'credentials-update-job',
                            parameters: "MASTER_IP=${env.MASTER_IP}\nCREDENTIAL_ID=${clusterNameWithHyphens}\nJENKINS_CREDENTIAL=true",
                            token : 'kakukk',
                            overrideTrustAllCertificates : true,
                            trustAllCertificates : true,
                            blockBuildUntilComplete : true
                            ]
                        )
                    }
                }

                stage('Keep cluster inventory on the master node') {
                    steps {
                        withCredentials([usernamePassword(credentialsId: 'k8s-master-workers-default-user-pass', usernameVariable: 'K8S_USER', passwordVariable: 'K8S_PASSWORD')]) {
                            sh '''
                            sshpass -p $K8S_PASSWORD scp -o StrictHostKeyChecking=no -r inv_test/eea4/cluster_inventories/${CLUSTER_INV_NAME} ${K8S_USER}@${MASTER_IP}:cluster_inventory
                            '''
                        }
                    }
                }
            }
        }

        stage('Validate cluster') {
            when {
                expression { params.EXECUTE_CLUSTER_VALIDATE == true }
            }
            steps {
                build job: 'cluster-validate',
                parameters: [
                    stringParam(name: 'CLUSTER', value: "${clusterNameWithHyphens}"),
                    stringParam(name: 'AFTER_CLEANUP_DESIRED_CLUSTER_LABEL', value: "cluster_reinstall_" + env.BUILD_NUMBER)
                ], wait: true
            }
        }

        stage('Validate cluster with baseline install') {
            when {
                expression { params.EXECUTE_CLUSTER_VALIDATE == true }
            }
            steps {
                build job: "eea-application-staging-product-baseline-install",
                parameters: [
                    booleanParam(name: 'DRY_RUN', value: false),
                    stringParam(name: "GIT_BRANCH", value: 'latest'),
                    stringParam(name: "SPINNAKER_ID", value: ''),
                    stringParam(name: "PIPELINE_NAME", value: ''),
                    stringParam(name: "CLUSTER_LABEL", value: ''),
                    stringParam(name: "CLUSTER_NAME", value: "${clusterNameWithHyphens}"),
                    booleanParam(name: "SKIP_CLEANUP", value: true)
                ], wait: true
            }
        }

        stage ('Upload cluster to dashboard') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    script {
                        sendClusterResourceToDashboard(clusterNameWithHyphens)
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
