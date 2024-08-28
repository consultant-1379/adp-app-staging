pipelineJob('spinnaker-report') {
    description("<a href=\"https://eteamspace.internal.ericsson.com/display/ECISE/Developing+and+integrating+Spinnaker+pipelines+in+Product+CI\">https://eteamspace.internal.ericsson.com/display/ECISE/Developing+and+integrating+Spinnaker+pipelines+in+Product+CI</a>")
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
                        scriptPath('technicals/spinnaker_report.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
