pipelineJob('eea-jenkins-docker-manual-flow-codereview-ok') {
    description("<a href=\"https://eteamspace.internal.ericsson.com/display/ECISE/EEA+Jenkins+Docker+in+Product+CI\">https://eteamspace.internal.ericsson.com/display/ECISE/EEA+Jenkins+Docker+in+Product+CI</a>")
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
                        scriptPath('pipelines/jenkins_docker/eea_jenkins_docker_manual_flow_codereview_ok.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
