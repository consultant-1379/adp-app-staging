pipelineJob('eea-prod-ci-helper-validate-and-publish') {
    description("<a href=\"https://eteamspace.internal.ericsson.com/display/ECISE/eric-eea-prod-ci-helper+docker+image+drop\"><a href=\"https://eteamspace.internal.ericsson.com/display/ECISE/eric-eea-prod-ci-helper Docker image drop</a>")
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
                        scriptPath('pipelines/eea_prod_ci_helper/eea_prod_ci_helper_validate_and_publish.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
