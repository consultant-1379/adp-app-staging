pipelineJob('eea-config-testing-trigger') {
    description("<a href=\"https://eteamspace.internal.ericsson.com/display/ECISE/Information+about+eea-manual-config-testing+loop+in+Product+CI\">https://eteamspace.internal.ericsson.com/display/ECISE/Information+about+eea-manual-config-testing+loop+in+Product+CI</a>")
    parameters {
        booleanParam('DRY_RUN', false)
    }
    definition {
        cpsScm {
            scm{
                git {
                    remote {
                        name 'adp-app-staging'
                        url 'https://eceagit@gerrit.ericsson.se/a/EEA/adp-app-staging'
                        credentials('git-functional-http-user')
                        scriptPath('pipelines/manual_config_testing/eea_config_testing_trigger.Jenkinsfile')
                     }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}