pipelineJob('eea-3pp-list-check') {
    description('<a href="https://eteamspace.internal.ericsson.com/display/ECISE/EEA+3pp+List+Check">3pp List Check in Product CI</a>')
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
                        scriptPath('technicals/eea_3pp_list_check.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
