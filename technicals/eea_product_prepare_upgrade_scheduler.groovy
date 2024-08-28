pipelineJob('eea-product-prepare-upgrade-scheduler') {
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
                        scriptPath('technicals/eea_product_prepare_upgrade_scheduler.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
