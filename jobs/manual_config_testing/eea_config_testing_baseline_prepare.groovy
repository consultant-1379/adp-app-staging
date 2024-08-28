pipelineJob('eea-config-testing-baseline-prepare') {
    description("Manually triggered config change testing loop in Product CI")
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
                        scriptPath('pipelines/manual_config_testing/eea_config_testing_prepare_baseline.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}