pipelineJob('functional-test-spinnaker-drop') {
    description("<a href=\"https://eteamspace.internal.ericsson.com/display/ECISE/Functional+tests+-+Spinnaker+-+Jenkins+connection+test\">Functional tests - Spinnaker - Jenkins connection test</a>")
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
                        scriptPath('technicals/functional_test/tests/functional_test_spinnaker_jenkins_drop.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
