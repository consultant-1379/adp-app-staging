pipelineJob('ruleset_change-notification') {
    description("<a href=\"https://eteamspace.internal.ericsson.com/display/ECISE/Product+CI+ruleset+validation\">https://eteamspace.internal.ericsson.com/display/ECISE/Product+CI+ruleset+validation</a>")
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
                        scriptPath('technicals/ruleset_change_notification.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
