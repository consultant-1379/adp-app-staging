pipelineJob('docker-image-versions-autouplift-weekly-loop') {
    description("This job intends for uplifting docker image versions in all ruleset files automatically")
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
                        scriptPath('technicals/docker_image_versions_autouplift_weekly_loop.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}