pipelineJob('eea-prod-ci-kubectl-and-helm-version-uplift') {
    description('''<a href="https://eteamspace.internal.ericsson.com/display/ECISE/Uplift+Kubectl+and+helm+versions+in+Product+CI+repos">Uplift Kubectl and helm versions in Product CI repos</a>''')
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
                        scriptPath('technicals/eea_prod_ci_kubectl_and_helm_version_uplift.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
