pipelineJob('eea-app-baseline-manual-flow-codereview-ok') {
    description("<a href=\"https://eteamspace.internal.ericsson.com/display/ECISE/Information+about+eea-application-staging+loop+in+Product+CI\">Information about eea-application-staging loop in Product CI</a>")
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
                        scriptPath('pipelines/eea_app_baseline_manual_flow/eea_app_baseline_manual_flow_codereview_ok.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
