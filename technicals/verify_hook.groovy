pipelineJob('verify-hook-job') {
    description("<a href=\"https://eteamspace.internal.ericsson.com/display/ECISE/Validation+of+CI+environment+changes\">Validation of CI environment changes </a>")
    parameters {
        booleanParam('DRY_RUN', false)
    }
    description('Testing jenkinsfile syntax validator')
    definition {
        cpsScm {
            scm{
                git {
                    remote {
                        name 'adp-app-staging'
                        url 'https://eceagit@${GERRIT_HOST}/a/EEA/adp-app-staging'
                        credentials('git-functional-http-user')
                        scriptPath('technicals/verify_hook.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
