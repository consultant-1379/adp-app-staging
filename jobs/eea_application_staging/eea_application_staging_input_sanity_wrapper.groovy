pipelineJob('eea-application-staging-input-sanity-wrapper') {
    description("<a href=\"https://eteamspace.internal.ericsson.com/display/ECISE/Input+sanity+check+wrapper\">Input sanity check</a>")
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
                        scriptPath('pipelines/eea_application_staging/eea_application_staging_input_sanity_wrapper.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
