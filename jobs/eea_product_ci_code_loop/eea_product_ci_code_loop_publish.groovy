pipelineJob('eea-product-ci-code-loop-publish') {
    description("<a href=\"https://eteamspace.internal.ericsson.com/display/ECISE/EEA+Code+Base+Helm+Chart#EEACodeBaseHelmChart-Jenkinsjobs\">EEA Code Base Helm Chart</a>")
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
                        scriptPath('pipelines/eea_product_ci_code_loop/eea_product_ci_code_loop_publish.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
