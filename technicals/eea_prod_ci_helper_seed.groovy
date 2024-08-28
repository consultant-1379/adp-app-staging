pipelineJob('eea-prod-ci-helper-seed') {
    description("<a href=\"https://eteamspace.internal.ericsson.com/display/ECISE/eric-eea-prod-ci-helper+docker+image+drop\"><a href=\"https://eteamspace.internal.ericsson.com/display/ECISE/eric-eea-prod-ci-helper docker image drop</a>")
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
                        scriptPath('technicals/eea_prod_ci_helper_seed.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
    logRotator {numToKeep 10}
}
