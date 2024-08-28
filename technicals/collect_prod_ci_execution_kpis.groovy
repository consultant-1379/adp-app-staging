pipelineJob('collect-prod-ci-execution-kpis') {
    description('<a href="https://eth-wiki.rnd.ki.sw.ericsson.se/display/ECISE/Product+CI+KPIs+report">https://eth-wiki.rnd.ki.sw.ericsson.se/display/ECISE/Product+CI+KPIs+report</a>')
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
                        scriptPath('technicals/collect_prod_ci_execution_kpis.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
