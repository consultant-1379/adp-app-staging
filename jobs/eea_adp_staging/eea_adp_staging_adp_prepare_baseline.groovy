pipelineJob('eea-adp-staging-adp-prepare-baseline') {
    description("<a href=\"https://eteamspace.internal.ericsson.com/display/ECISE/Information+about+eea_adp_staging+loop+in+Product+CI#Informationabouteea_adp_stagingloopinProductCI-1.1.eea-adp-staging\">EEA ADP STAGING CI pipelines in Jenkins and Spinnaker</a>")
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
                        scriptPath('pipelines/eea_adp_staging/eea_adp_staging_adp_prepare_baseline.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
