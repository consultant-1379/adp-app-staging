pipelineJob('cluster-reinstall') {
    description('<a href="https://eth-wiki.rnd.ki.sw.ericsson.se/display/ECISE/Cluster+validation">Cluster validation in Product CI</a><br><br><a href="https://eteamproject.internal.ericsson.com/browse/EEAEPP-87543">Template ticket for cluster reinstall</a>')
    parameters {
        booleanParam('DRY_RUN', false)
    }
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        name 'adp-app-staging'
                        url 'https://eceagit@gerrit.ericsson.se/a/EEA/adp-app-staging'
                        credentials('git-functional-http-user')
                        scriptPath('technicals/cluster_reinstall.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
