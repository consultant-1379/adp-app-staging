@Library('ci_shared_library_eea4') _

import com.cloudbees.plugins.credentials.*;
import com.cloudbees.plugins.credentials.domains.Domain;
import org.jenkinsci.plugins.plaincredentials.impl.FileCredentialsImpl;
import com.ericsson.eea4.ci.CommonUtils
import org.jenkins.plugins.lockableresources.LockableResourcesManager

properties([
    parameters([
        [$class: 'ChoiceParameter',
            choiceType: 'PT_SINGLE_SELECT',
            name: 'CREDENTIAL_ID',
            description: 'ID of credential from the Global Credentials page',
            filterable: true,
            filterLength: 1,
            script: [$class: 'GroovyScript',
                script: [
                    classpath: [],
                    sandbox: true,
                    script: """
                        def creds = com.cloudbees.plugins.credentials.CredentialsProvider.lookupCredentials(
                            org.jenkinsci.plugins.plaincredentials.impl.FileCredentialsImpl
                        ).sort()
                        return (creds.id)
                    """
                ],
                fallbackScript: [
                    classpath: [],
                    sandbox: true,
                    script: 'return ["Error during getting credentials list"]'
                ]
            ]
        ]
    ])
])

pipeline {
    options { buildDiscarder(logRotator(daysToKeepStr: "30")) }
    agent { node { label "master" }}
    parameters {
        string(name: 'MASTER_IP', description: 'Virtual IP of the cluster master node', defaultValue: '')
        booleanParam(name: 'JENKINS_CREDENTIAL', description: '[ADVANCED PROD_CI OPTION] DO NOT USE THIS IF YOU DONT UNDERSTAND THE PURPOSE. If it is set, the kubernetes-admin credentials will be replaced with the jenkins token.', defaultValue: false)
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

        stage("Check if verify parameters required") {
            steps {
                script {
                    env.CURRENT_USER_ID = getBuildUser(currentBuild).trim()
                    echo "env.CURRENT_USER_ID: ${env.CURRENT_USER_ID}"

                    env.UPSTREAM_JOB_NAME = getLastUpstreamBuildEnvVarValue('JOB_NAME').trim()
                    echo "env.UPSTREAM_JOB_NAME: ${env.UPSTREAM_JOB_NAME}"

                    env.VALID_TIMER_STARTED_UPSTREAM_JOB_NAMES = [
                        'cluster-reinstall',
                        'rv-helm-configuration-upgrade-test-job'
                    ]

                    env.VERIFY_PARAMETERS_REQUIRED = "true"

                    def lockableResourcesManager = org.jenkins.plugins.lockableresources.LockableResourcesManager.get()
                    def lockableResource = lockableResourcesManager.fromName(env.CREDENTIAL_ID)
                    def lockableResourceDescription = lockableResource.getDescription()
                    if ( !lockableResource.getDescription().contains("Product CI") ) {
                        echo "The ${env.CREDENTIAL_ID} premission check is skippable, because the description is \"${lockableResourceDescription}\""
                        env.VERIFY_PARAMETERS_REQUIRED = "false"
                    } else {
                        // if the credential update and it's upstream jobs started by cron trigger (user='timer') and
                        // the uptream job is in a specified job list --> parameter verification is not required (because the user for checking real persmissons is N/A)
                        if (env.CURRENT_USER_ID == 'timer' && env.VALID_TIMER_STARTED_UPSTREAM_JOB_NAMES.contains(env.UPSTREAM_JOB_NAME)) {
                            echo "The ${env.CREDENTIAL_ID} owner is the Product CI Team (description is: \"${lockableResourceDescription}\"), but check is skippable because upstream jobs is ${env.UPSTREAM_JOB_NAME}"
                            env.VERIFY_PARAMETERS_REQUIRED = "false"
                        } else {
                            echo "The ${env.CREDENTIAL_ID} owner is the Product CI Team (description is: \"${lockableResourceDescription}\"), permission check is required"
                            env.VERIFY_PARAMETERS_REQUIRED = "true"
                        }
                    }

                    echo "env.VERIFY_PARAMETERS_REQUIRED: ${env.VERIFY_PARAMETERS_REQUIRED}"
                }
            }
        }

        stage("Verify parameters") {
            when {
                expression { env.VERIFY_PARAMETERS_REQUIRED == 'true' }
            }
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_USER_PASSWORD')]){
                        def credentialId = "${CREDENTIAL_ID}"
                        try {
                            // env.CURRENT_USER_ID = currentBuild.rawBuild.getCause(hudson.model.Cause.UserIdCause.class).getUserId()
                            env.CURRENT_USER_ID = getBuildUser(currentBuild)
                            result = com.cloudbees.plugins.credentials.CredentialsProvider.lookupCredentials(
                                org.jenkinsci.plugins.plaincredentials.impl.FileCredentialsImpl
                            ).findResult{ it.id == credentialId ? it : null }.description
                            env.CREDENTIAL_DESCRIPTION = result
                        } catch (err) {
                            error "Caught: ${err}"
                        }
                        if (!result) {
                            error "${credentialId} has no description"
                        }
                        sh '''
                            set +x
                            if ! [[ $MASTER_IP =~ ^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$ ]]
                            then
                                echo "MASTER_IP: $MASTER_IP is invalid. Please, provide a MASTER_IP in the following format: 1.2.3.4"
                            fi
                            IFS=',' read -ra GROUPS_LIST <<< "${CREDENTIAL_DESCRIPTION}"
                            for GROUP in "${GROUPS_LIST[@]}"
                            do
                                count=$((count+1))
                                GROUP=$(echo "${GROUP}" | xargs | sed 's/ /\\\\ /g')
                                sshpass -p $GIT_USER_PASSWORD ssh -o StrictHostKeyChecking=no -p ${GERRIT_PORT} $GIT_USER@${GERRIT_HOST} gerrit ls-members --recursive "${GROUP}" | grep ${CURRENT_USER_ID} && echo "${CURRENT_USER_ID} found in group ${GROUP}" && break
                                echo "${CURRENT_USER_ID} not found in group ${GROUP}. Operation not permitted!"
                                if [ $count == ${#GROUPS_LIST[@]} ]
                                then
                                    echo "${CURRENT_USER_ID} not permitted to update ${CREDENTIAL_ID}"
                                    exit 1
                                fi
                            done
                            set -x
                        '''
                    }
                }
            }
        }

        stage("Set build description") {
            steps {
                script {
                    currentBuild.description = "Credential: ${params.CREDENTIAL_ID}<br>Master IP: ${params.MASTER_IP}"
                }
            }
        }

        stage("Get kubeconfig from the master") {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'master-node-credentials', usernameVariable: 'MASTER_USERNAME', passwordVariable: 'MASTER_PASSWORD')]){
                        // sh "sshpass -p ${MASTER_PASSWORD} scp -o StrictHostKeyChecking=no ${MASTER_USERNAME}@${MASTER_IP}:/root/.kube/config ${WORKSPACE}/${CREDENTIAL_ID}"
                        // sh "sed -i 's/nodelocal-api.eccd.local/${MASTER_IP}/g' ${WORKSPACE}/${CREDENTIAL_ID}"

                        env.KUBECONFIG = sh (script: '''
                        echo "${CREDENTIAL_ID}_$(date '+%F_%H-%M').kubeconfig"
                        ''',
                        returnStdout: true).trim()

                        sh '''
                        sshpass -p ${MASTER_PASSWORD} scp -o StrictHostKeyChecking=no ${MASTER_USERNAME}@${MASTER_IP}:/root/.kube/config ${KUBECONFIG}
                        sed -i "s/nodelocal-api.eccd.local/${MASTER_IP}/g" ${KUBECONFIG}
                        '''

                        if (params.JENKINS_CREDENTIAL) {
                            def jenkins_token = sh (script: '''
                            function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\\n", $1,$2,$3,$4); }'; }
                            kubernetesVersion_=$(sshpass -p $MASTER_PASSWORD ssh -o StrictHostKeyChecking=no ${MASTER_USERNAME}@${MASTER_IP} 'kubectl version -o json | jq -r ".serverVersion.gitVersion"')
                            kubernetesVersion="${kubernetesVersion_:1}"

                            if [ $(version $kubernetesVersion) -gt $(version "1.24.999") ]; then
                                sshpass -p ${MASTER_PASSWORD} ssh ${MASTER_USERNAME}@${MASTER_IP} 'kubectl -n default get secret jenkins-token -o jsonpath='{.data.token}' | base64 --decode'

                            else
                                sshpass -p ${MASTER_PASSWORD} ssh ${MASTER_USERNAME}@${MASTER_IP} 'kubectl -n default get secret $(kubectl -n default get serviceaccount/jenkins -o jsonpath={.secrets[0].name}) -o jsonpath={.data.token} | base64 --decode'
                            fi
                            ''',
                            returnStdout: true).trim()

                            sh """
                            sed -i 's/kubernetes-admin/jenkins/g' ${KUBECONFIG}
                            sed -i 's/^ *client-key-data:.*//g' ${KUBECONFIG}
                            sed -i "s/client-certificate-data:.*/token: ${jenkins_token}/g" ${KUBECONFIG}
                            """
                        }
                    }
                }
            }
        }

        stage("Update credentials") {
            steps {
                script {
                    def updateCredentials = { credential, fileName, secret ->
                        def credentials_store = jenkins.model.Jenkins.instance.getExtensionList(
                                com.cloudbees.plugins.credentials.SystemCredentialsProvider
                        )[0].getStore()

                        try {
                            result = credentials_store.updateCredentials(
                                    com.cloudbees.plugins.credentials.domains.Domain.global(),
                                    credential,
                                    new FileCredentialsImpl(credential.scope, credential.id, credential.description, fileName, secret)
                            )
                            echo "File secret changed for '${credential.id}'"
                        }
                        catch (err) {
                            echo "Failed to change file secret for '${credential.id}'"
                            error "Caught: ${err}"
                        }
                    }

                    def credentialId = "${CREDENTIAL_ID}"
                    // def content = readFile "${WORKSPACE}/${CREDENTIAL_ID}"
                    def content = readFile "${WORKSPACE}/${KUBECONFIG}"
                    def secret = SecretBytes.fromBytes(content.getBytes())
                    def credentials_list = com.cloudbees.plugins.credentials.CredentialsProvider.lookupCredentials(
                            com.cloudbees.plugins.credentials.common.StandardCredentials,
                            Jenkins.instance
                    );
                    def credential = credentials_list.find { it.id == credentialId ? it : null}
                    if (credential) {
                        println "Found credential: '${credential.id}'"
                        println "Credential type: '${credential}'"
                        updateCredentials(credential, env.KUBECONFIG, secret)
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
