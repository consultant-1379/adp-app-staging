pipelineJob('eea-product-ci-shared-libraries-seed-job') {
    description("<a href=\"https://eteamspace.internal.ericsson.com/display/ECISE/%5BStudy%5D+EEA4+Workflow+for+Product+CI+Shared+Library+implementation\">https://eteamspace.internal.ericsson.com/display/ECISE/%5BStudy%5D+EEA4+Workflow+for+Product+CI+Shared+Library+implementation</a>")
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
                        scriptPath('technicals/eea_product_ci_shared_libraries_seed_job.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
   logRotator {numToKeep 10}
}
