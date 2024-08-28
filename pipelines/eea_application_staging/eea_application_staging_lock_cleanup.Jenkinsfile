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
        buildDiscarder(logRotator(daysToKeepStr: "14", artifactDaysToKeepStr: "7"))
    }

    parameters {
        string(name: 'DOC_COMMIT_ID', description: 'commit id of the doc repo change', defaultValue: '')
        string(name: 'SPINNAKER_ID', description: "The spinnaker execution's id of eea-application-staging", defaultValue: '')
        string(name: 'STAGING_RESULT', description: "The result of eea-application-staging", defaultValue: '')
        string(name: 'PIPELINE_NAME', description: "The spinnaker pipeline name", defaultValue: '')
        booleanParam(name: 'RESOURCE_TIMEOUT', description: 'CPI build faild with resource timeout', defaultValue: false)
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

        //after 3 hour wawiting the build gone timeout, there is a high chance, that the resource stucked, so we just reset that
        stage('Stucked resource release') {
            when {
                expression { params.RESOURCE_TIMEOUT == true }
            }
            //to make sure nobody works on jenkins config
            options {
                lock resource: null, label: "resource-relabel", quantity: 1, variable: 'system'
            }
            steps {
                script {
                    def manager = org.jenkins.plugins.lockableresources.LockableResourcesManager.get()
                    def resources =  manager.getResourcesWithLabel('doc-build', null)
                    resources.each {
                        it.setNote('')
                    }
                    manager.recycle(resources)
                }
            }
        }


        stage('Release reservation on resource'){
            when {
                expression { params.RESOURCE_TIMEOUT == false }
            }
            options {
                lock resource: null, label: "resource-relabel", quantity: 1, variable: 'system'
            }
            steps{
                script {
                    def manager = org.jenkins.plugins.lockableresources.LockableResourcesManager.get()
                    def resources =  manager.getResourcesWithLabel('doc-build', null)
                    def note = params.PIPELINE_NAME + ' - ' + params.SPINNAKER_ID
                    resources.each {
                        if (it.getNote() == note) {
                            echo "Reserved resource found ${it}"
                            echo "isReserved: ${it.isReserved()}"
                            it.setNote('')
                            manager.recycle([it])
                        }
                    }
                }
            }
        }

        stage('Abandon change if it was not published'){
            when {
                expression { (params.STAGING_RESULT == 'CANCELED'|| params.STAGING_RESULT == 'TERMINAL') && (params.PIPELINE_NAME == 'eea-application-staging') && (params.RESOURCE_TIMEOUT == false) && (params.DOC_COMMIT_ID) }
            }
            steps {
                script {
                    git.abandon("${params.DOC_COMMIT_ID}")

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
