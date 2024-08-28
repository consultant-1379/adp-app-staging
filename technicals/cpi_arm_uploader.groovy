pipelineJob('cpi-arm-uploader') {
    description('<a href="https://eteamspace.internal.ericsson.com/display/ECISE/CPI+ARM+uploader">CPI ARM uploader</a>')
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
                        scriptPath('technicals/cpi_arm_uploader.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
