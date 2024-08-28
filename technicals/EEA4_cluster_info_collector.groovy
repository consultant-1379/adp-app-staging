pipelineJob('EEA4-cluster-info-collector') {
    description('''This job automatically collects EEA4 cluster informations<br>
                <a href="https://eteamspace.internal.ericsson.com/display/ECISE/EEA4+Product+CI+cluster+information+and+validation+job">EEA4 Product CI cluster information and validation job</a>''')
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
                        scriptPath('technicals/EEA4_cluster_info_collector.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
