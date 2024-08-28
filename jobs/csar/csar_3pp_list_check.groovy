pipelineJob('csar-3pp-list-check') {
    description("CSAR 3PP list compare with SCAS data")
    parameters {
        booleanParam('DRY_RUN', false)
    }


    definition {
        cpsScm {
            scm{
                git {
                    remote {
                        name 'adp-app-staging'
                        url 'https://eceagit@${GERRIT_HOST}/a/EEA/adp-app-staging'
                        credentials('git-functional-http-user')
                        scriptPath('pipelines/csar/csar_3pp_list_check.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}