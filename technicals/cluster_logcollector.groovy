pipelineJob('cluster-logcollector') {
    description('<a href="https://eteamspace.internal.ericsson.com/display/ECISE/Cluster+log+collector">Cluster log collector in Product CI</a>')
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
                        scriptPath('technicals/cluster_logcollector.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
