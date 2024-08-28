@Library('ci_shared_library_eea4') _

import groovy.transform.Field
import hudson.util.Secret
import com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl
import com.cloudbees.plugins.credentials.SystemCredentialsProvider
import com.cloudbees.plugins.credentials.domains.Domain
import com.ericsson.eea4.ci.MimerUtils

def refresh_token_file = 'refreshToken.json'

pipeline {

    agent{
        node {
            label 'master'
        }
    }

    options { buildDiscarder(logRotator(daysToKeepStr: '7')) }

    parameters {
        choice(name: 'JENKINS_CREDENTIAL', choices: ['eea-mimer-user-token', 'scasuser-token'], description: 'Jenkins credential of the token to refresh')
    }

    triggers { cron('0 0 1 * *') }

    stages {
        stage('Params DryRun check') {
            when {
                expression { params.DRY_RUN }
            }
            steps {
                script {
                    dryRun()
                }
            }
        }

        stage('Set build description') {
            steps {
                script {
                    currentBuild.description = "Credential: ${params.JENKINS_CREDENTIAL}"
                }
            }
        }

        stage('Refresh Token') {
            steps {
                catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                    script {
                        try {
                            switch(params.JENKINS_CREDENTIAL) {
                                case 'eea-mimer-user-token':
                                    echo "Get refresh token for ${params.JENKINS_CREDENTIAL}"
                                    mimer_utils = new MimerUtils(this)
                                    mimer_utils.getToken(refresh_token_file, '', true)
                                    break
                                case 'eea-scas-user-pass':
                                    // todo: implement SCAS token refresh flow
                                    error "Not Implemented: get refresh token for ${params.JENKINS_CREDENTIAL}"
                                    break
                            }
                        } catch (err) {
                            error "${STAGE_NAME} FAILED: ${err}"
                        }
                        finally {
                            echo "Archive artifacts: ${refresh_token_file}"
                            archiveArtifacts artifacts: refresh_token_file, allowEmptyArchive: true
                        }
                    }
                }
            }
        }

        stage('Update credentials') {
            when {
                expression { refresh_token_file }
            }
            steps {
                catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
                    script {
                        try {
                            def refresh_token_str = readJSON file: refresh_token_file
                            refresh_token = refresh_token_str.results.data.refresh_token.get(0)
                            // echo "Refresh token: ${refresh_token}"
                            updateUsernamePasswordCredentials(params.JENKINS_CREDENTIAL, refresh_token)
                            if ( params.JENKINS_CREDENTIAL == 'eea-mimer-user-token' ) {
                                updateSecretTextCredentials('mimer-token-production', refresh_token)
                            }
                        } catch (err) {
                            error "${STAGE_NAME} FAILED:\n${err}"
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

void updateUsernamePasswordCredentials(credential_id, new_password) {
    def creds = com.cloudbees.plugins.credentials.CredentialsProvider.lookupCredentials(
        com.cloudbees.plugins.credentials.common.StandardUsernamePasswordCredentials.class,
        jenkins.model.Jenkins.instance
    )
    def credential = creds.findResult { it.id == credential_id ? it : null }
    if ( credential ) {
        echo "Found credential ${credential.id}."
        def credentials_store = Jenkins.instance.getExtensionList(
            'com.cloudbees.plugins.credentials.SystemCredentialsProvider'
            )[0].getStore()

        def result = credentials_store.updateCredentials(
            com.cloudbees.plugins.credentials.domains.Domain.global(),
            credential,
            new UsernamePasswordCredentialsImpl(credential.scope, credential.id, credential.description, credential.username, new_password)
            )
        if (result) {
            echo "Credential changed for ${credential_id} SUCCESSFULLY."
        } else {
            error "Failed to change credential for ${credential_id}"
        }
    } else {
        error "Could not find credential for ${credential_id}"
    }
}

void updateSecretTextCredentials(credential_id, new_secret_text) {
    def creds = com.cloudbees.plugins.credentials.CredentialsProvider.lookupCredentials(
        org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl,
        jenkins.model.Jenkins.instance
    )
    def credential = creds.findResult { it.id == credential_id ? it : null }
    if ( credential ) {
        echo "Found credential ${credential.id}"
        def credentials_store = Jenkins.instance.getExtensionList(
            'com.cloudbees.plugins.credentials.SystemCredentialsProvider'
            )[0].getStore()

        def result = credentials_store.updateCredentials(
            com.cloudbees.plugins.credentials.domains.Domain.global(),
            credential,
            new StringCredentialsImpl(credential.scope, credential.id, credential.description, Secret.fromString(new_secret_text))
            )
        if (result) {
            echo "Credential changed for ${credential.id} SUCCESSFULLY."
        } else {
            echo "Failed to change credential for ${credential.id}"
        }
    } else {
        error "Could not find credential for ${credential_id}"
    }
}