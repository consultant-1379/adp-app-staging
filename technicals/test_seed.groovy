pipelineJob('test-seed-job') {
    description("<a href=\"https://eteamspace.internal.ericsson.com/display/ECISE/Generate+jobs+from+groovy+and+Jenkinsfile\">https://eteamspace.internal.ericsson.com/display/ECISE/Generate+jobs+from+groovy+and+Jenkinsfile</a>")
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
                        scriptPath('technicals/test_seed.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
