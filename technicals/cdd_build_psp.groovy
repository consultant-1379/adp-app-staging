pipelineJob('cdd-build-psp') {
    description("<a href=\"https://eteamspace.internal.ericsson.com/display/ECISE/CDD+CI+Developer+Documentation\">https://eteamspace.internal.ericsson.com/display/ECISE/CDD+CI+Developer+Documentation</a>")
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
                        scriptPath('technicals/cdd_build_psp.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}