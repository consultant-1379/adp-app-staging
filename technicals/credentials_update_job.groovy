pipelineJob('credentials-update-job') {
    description('<a href="https://eteamspace.internal.ericsson.com/display/ECISE/Credentials+update">Credentials update in Product CI</a>')
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
                        scriptPath('technicals/credentials_update_job.Jenkinsfile')
                    }
                    // otherwise it doesn't work on test Jenkins because MAIN_BRANCH there is 'prod-ci-test'
                    branch('master')
                }
            }
        }
    }
}