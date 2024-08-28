pipelineJob('documentation_publish') {
    description("<a href=\"https://eteamspace.internal.ericsson.com/display/ECISE/EEA4+documentation+workflow\">EEA4 documentation workflow</a>")
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
                        scriptPath('pipelines/documentation/documentation_publish.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
