pipelineJob('eea-ci-config-precodereview') {
    description("<a href=\"https://eteamspace.internal.ericsson.com/display/ECISE/%5Bstudy%5D+Cluster+load+balancing+in+Prod+CI\">https://eteamspace.internal.ericsson.com/display/ECISE/%5Bstudy%5D+Cluster+load+balancing+in+Prod+CI")
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
                        scriptPath('pipelines/eea_ci_config/eea_ci_config_precodereview.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
