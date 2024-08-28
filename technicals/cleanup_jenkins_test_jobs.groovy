pipelineJob('cleanup-jenkins-test-jobs') {
    description('<a href="https://eteamspace.internal.ericsson.com/display/ECISE/Automated+test+job+cleanup+at+live+Jenkins">Automated test job cleanup at live Jenkins</a>')
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
                        scriptPath('technicals/cleanup_jenkins_test_jobs.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
