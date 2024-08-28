pipelineJob('eea-cdd-manual-flow-verify-cr') {
    description("<a href=\"https://eteamspace.internal.ericsson.com/display/ECISE/CDD+in+Product+CI\">https://eteamspace.internal.ericsson.com/display/ECISE/CDD+in+Product+CI</a>")
    parameters {
        booleanParam('DRY_RUN', false)
    }
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        name 'adp-app-staging'
                        url 'https://eceagit@${GERRIT_HOST}/a/EEA/adp-app-staging'
                        credentials('git-functional-http-user')
                        scriptPath('pipelines/eea_cdd/eea_cdd_manual_flow_verify_cr.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
