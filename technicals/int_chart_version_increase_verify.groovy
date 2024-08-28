pipelineJob('int-chart-version-increase-verify') {
    description("This job is a validation for preventing manual version increases in the integration chart at cnint repo.")
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
                        scriptPath('technicals/int_chart_version_increase_verify.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
