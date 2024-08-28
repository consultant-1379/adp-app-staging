pipelineJob('spotfire-platform-asset-uploader') {
    description('<a href="https://eteamspace.internal.ericsson.com/display/ECISE/Spotfire+Platform+Asset+Uploader">Spotfire Platform Asset Uploader</a>')
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
                        scriptPath('technicals/spotfire_platform_asset_uploader.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
}
