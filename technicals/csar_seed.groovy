pipelineJob('csar-seed-job') {
    description("<a href=\"https://eteamspace.internal.ericsson.com/display/ECISE/Information+about+eea_adp_staging+loop+in+Product+CI#Informationabouteea_adp_stagingloopinProductCI-1.3.Common\">EEA ADP STAGING CI pipelines in Jenkins and Spinnaker Common files</a>")
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
                        scriptPath('technicals/csar_seed.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
    logRotator {numToKeep 10}
}
