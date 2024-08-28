pipelineJob('markdown-precodereview') {
    description("<a href=\"https://eteamspace.internal.ericsson.com/display/ECISE/Markdown+precodereview\">Markdown precodereview in Product CI</a>")
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
                        scriptPath('technicals/markdown_precodereview.Jenkinsfile')
                    }
                    branch('${MAIN_BRANCH}')
                }
            }
        }
    }
    logRotator {numToKeep 10}
}
