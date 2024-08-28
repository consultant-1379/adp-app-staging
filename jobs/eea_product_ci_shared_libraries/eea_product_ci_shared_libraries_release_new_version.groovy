pipelineJob('eea-product-ci-shared-libraries-release-new-version') {
    description("<a href=\"https://eteamspace.internal.ericsson.com/display/ECISE/EEA4+Product+CI+Shared+Libraries+release+new+version\">https://eteamspace.internal.ericsson.com/display/ECISE/EEA4+Product+CI+Shared+Libraries+release+new+version</a>")
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
                        scriptPath('pipelines/eea_product_ci_shared_libraries/eea_product_ci_shared_libraries_release_new_version.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}