pipelineJob('eea-ci-config-seed') {
    description("<a href=\"https://eteamspace.internal.ericsson.com/display/ECISE/%5Bstudy%5D+Cluster+load+balancing+in+Prod+CI\">https://eteamspace.internal.ericsson.com/display/ECISE/%5Bstudy%5D+Cluster+load+balancing+in+Prod+CI")
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
                        scriptPath('technicals/eea_ci_config_seed.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
    logRotator {numToKeep 10}
}
