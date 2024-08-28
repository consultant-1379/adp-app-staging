pipelineJob('release-mail-automation') {
    description('<a href="https://eteamspace.internal.ericsson.com/display/ECISE/EEA4+Automated+RC+and+Early+Drop+tagging+and+mail+sending">EEA4 Automated RC and Early Drop tagging and mail sending</a>')
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
                        scriptPath('pipelines/eea_product_release_loop/release_mail_automation.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
