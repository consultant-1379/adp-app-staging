pipelineJob('eea-ci-dashboard-stage-controller') {
    parameters {
        booleanParam('DRY_RUN', false)
    }
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        name 'eea-app-staging'
                        url 'https://eceagit@${GERRIT_HOST}/a/EEA/adp-app-staging'
                        credentials('git-functional-http-user')
                        scriptPath('technicals/eea_ci_dashboard_stage_controller.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
