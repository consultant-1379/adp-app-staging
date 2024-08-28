pipelineJob('eea-common-product-upgrade') {
    parameters {
        booleanParam('DRY_RUN', false)
        stringParam('JENKINSFILE_GERRIT_REFSPEC', '${MAIN_BRANCH}', 'Git ref in EEA/adp-app-staging repo to technicals/eea_common_product_upgrade.Jenkinsfile change. E.g: refs/changes/80/16735380/3')
    }
    definition {
        cpsScm {
            scm{
                git {
                    remote {
                        name 'adp-app-staging'
                        url 'https://eceagit@${GERRIT_HOST}/a/EEA/adp-app-staging'
                        credentials('git-functional-http-user')
                        scriptPath('technicals/eea_common_product_upgrade.Jenkinsfile')
                        refspec("\$JENKINSFILE_GERRIT_REFSPEC")
                    }
                    branch('FETCH_HEAD')
                }
            }
        }
    }
}
