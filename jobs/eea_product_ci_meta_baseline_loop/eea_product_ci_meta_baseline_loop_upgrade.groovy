pipelineJob('eea-product-ci-meta-baseline-loop-upgrade') {
    description("<a href=\"https://eteamspace.internal.ericsson.com/display/ECISE/Information+about+eea_product_ci_meta_baseline_loop+in+Product+CI\">https://eteamspace.internal.ericsson.com/display/ECISE/Information+about+eea_product_ci_meta_baseline_loop+in+Product+CI</a>")
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
                        scriptPath('pipelines/eea_product_ci_meta_baseline_loop/eea_product_ci_meta_baseline_loop_upgrade.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
