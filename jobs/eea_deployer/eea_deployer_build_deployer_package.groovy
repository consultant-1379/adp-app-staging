pipelineJob('eea-deployer-build-deployer-package') {
    description("<a href=\"https://eteamspace.internal.ericsson.com/display/ECISE/DEPLOYER+in+Product+CI\">https://eteamspace.internal.ericsson.com/display/ECISE/DEPLOYER+in+Product+CI</a>")
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
                        scriptPath('pipelines/eea_deployer/eea_deployer_build_deployer_package.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
