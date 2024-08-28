pipelineJob('release-mail-automation-with-workaround') {
    description('<a href="https://eteamspace.internal.ericsson.com/display/ECISE/EEA4+Automated+RC+and+Early+Drop+tagging+and+mail+sending">EEA4 Automated RC and Early Drop tagging and mail sending with a workaround for no-mxe csar</a>')
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
                        scriptPath('pipelines/eea_product_release_loop/release_mail_automation_with_workaround.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
