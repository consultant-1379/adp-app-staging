pipelineJob('collect-performance-data-from-cluster') {
    description("<a href=\"https://eteamspace.internal.ericsson.com/display/ECISE/EEA+4+Product+CI+Jenkins+and+Test-Jenkins\">https://eteamspace.internal.ericsson.com/display/ECISE/</a>")
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
                        scriptPath('technicals/collect_performance_data.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
