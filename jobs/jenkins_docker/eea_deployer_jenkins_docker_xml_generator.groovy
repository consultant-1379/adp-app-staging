pipelineJob('eea-deployer-jenkins-docker-xml-generator') {
    description("<a href=\"https://eteamspace.internal.ericsson.com/display/ECISE/EEA+Jenkins+Docker+in+Product+CI\">https://eteamspace.internal.ericsson.com/display/ECISE/EEA+Jenkins+Docker+in+Product+CI</a>")
    parameters {
        booleanParam('DRY_RUN', false)
        stringParam('JENKINSFILE_GERRIT_REFSPEC', '${MAIN_BRANCH}', 'Git ref in EEA/adp-app-staging repo to eea_deployer_jenkins_docker_xml_generator.Jenkinsfile change')
    }
    definition {
        cpsScm {
            scm {
                git {
                    remote {
                        name 'adp-app-staging'
                        url 'https://eceagit@${GERRIT_HOST}/a/EEA/adp-app-staging'
                        credentials('git-functional-http-user')
                        scriptPath('pipelines/jenkins_docker/eea_deployer_jenkins_docker_xml_generator.Jenkinsfile')
                        refspec("\$JENKINSFILE_GERRIT_REFSPEC")
                    }
                    branch('FETCH_HEAD')
                }
            }
        }
    }
}
