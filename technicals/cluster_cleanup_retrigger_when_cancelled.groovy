pipelineJob('cluster-cleanup-retrigger-when-cancelled') {
    description('<a href="https://eteamspace.internal.ericsson.com/display/ECISE/Cluster+cleanup">Cluster cleanup retrigger when canceled in Product CI</a>')
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
                        scriptPath('technicals/cluster_cleanup_retrigger_when_cancelled.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
