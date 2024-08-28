pipelineJob('eea-cdd-release-job') {
    description("<a href=\"https://eteamspace.internal.ericsson.com/display/ECISE/Information+about+eea-cdd-release-loop+in+Product+CI\">https://eteamspace.internal.ericsson.com/display/ECISE/Information+about+eea-cdd-release-loop+in+Product+CI</a>")
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
                        scriptPath('pipelines/eea_product_release_loop/eea_cdd_release.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
