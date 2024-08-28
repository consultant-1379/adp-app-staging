pipelineJob('eea-application-staging-product-baseline-install') {
    description("<a href=\"https://eteamspace.internal.ericsson.com/display/ECISE/Information+about+eea-application-staging+loop+in+Product+CI\">Information about eea-application-staging loop in Product CI</a>")
    parameters {
        booleanParam('DRY_RUN', false)
        stringParam('JENKINSFILE_GERRIT_REFSPEC', '${MAIN_BRANCH}', 'Git ref in EEA/adp-app-staging repo to eea_application_staging_product_baseline_install.Jenkinsfile change. E.g:refs/changes/62/16470962/2')
    }
    definition {
        cpsScm {
            scm{
                git {
                    remote {
                        name 'adp-app-staging'
                        url 'https://eceagit@${GERRIT_HOST}/a/EEA/adp-app-staging'
                        credentials('git-functional-http-user')
                        scriptPath('pipelines/eea_application_staging/eea_application_staging_product_baseline_install.Jenkinsfile')
                        refspec("\$JENKINSFILE_GERRIT_REFSPEC")
                    }
                    branch('FETCH_HEAD')
                }
            }
        }
    }
}
