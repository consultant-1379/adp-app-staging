pipelineJob('ruleset-change-validate') {
    description('<a href="https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/product-ci-bob-ruleset.md#Product-CI-bob-rulesets-design-rules">Ruleset Change validation in Product CI</a>')
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
                        scriptPath('technicals/ruleset_change_validate.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
