pipelineJob('cluster-reinstall-automation') {
    description('<a href="https://eteamspace.internal.ericsson.com/display/ECISE/Product+CI+cluster+reinstall+automation">Product CI cluster reinstall automation</a>')
    parameters {
        booleanParam('DRY_RUN', false)
    }
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        name 'adp-app-staging'
                        url 'https://eceagit@gerrit.ericsson.se/a/EEA/adp-app-staging'
                        credentials('git-functional-http-user')
                        scriptPath('technicals/cluster_reinstall_automation.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
