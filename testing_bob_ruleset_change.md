# How to test your bob ruleset changes before merging it to cnint

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

Example commit: <https://gerrit.ericsson.se/#/c/7804245/>

In case of implementing changes in bob rulesets stored in cnint repo you have to prepare a test pipeline to be able to test your changes before merging it to Product CI.

## Preparing the pipeline

TODO review tis file
For this you have to prepare commit with the followings to adp-app-staging (it's important that both the groovy and the Jenkinsfile has to be at tests directory, ruleset should be at the root of the repo):

1. a Jenkinsfile which will trigger your ruleset changes using the patchset as input from adp-app-staging repository. The Jenkinsfile should have 2 checkouts : 1 for cnint, 1 for the patchset using the Gerrit Refspec build parameter. Most of the Product CI jobs already contains these rows

        stage('Checkout cnint'){
                steps {
                    script {
                        gitcnint.checkout('master', '')
                    }
                }
            }
            stage('Checkout commit'){
                steps {
                    script {
                        gitcnint.fetchAndCherryPick('EEA/cnint', "${params.GERRIT_REFSPEC}")
                    }
                }
            }
1. a groovy file for triggering your Jenkinsfile.

        git {
                            remote {
                                refspec 'refs/changes/45/7804245/51'
                                name 'adp-app-staging'
                                url 'https://eceagit@gerrit.ericsson.se/a/EEA/adp-app-staging'
                                credentials('git-functional-http-user')
                                scriptPath('tests/name_of_your_jenkinsfile.Jenkinsfile')
                            }
                            branch('FETCH_HEAD')
                        }
1. Ruleset file what you would like to add/change in cnint

### Difference between the live pipeline and this test one:

With this solution you can also skip some steps during ruleset development which is not important at that time, like the default timeout, etc… Please specify a timeout every time to avoid blocking of other pipelines which would use the test environment.
For defining timeout, use the  --helm-timeout  parameter in case you are using the k8-test docker-image, and the test.py script in it. The default timeout here is 2000s, but if there is an error, it will come up in a few minutes.

## Testing your ruleset

### Resource locking, Triggering the rule

* Here you have to lock the cluster resource in Jenkins to be able to access one of our test enironments:
* After prepare stage include a new stage for testing your ruleset.

    stage('testing ruleset') {
                steps {
                    lock(resource: null, label: 'bob-ci', quantity: 1, variable: 'system') {
                        withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
                                         usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA'),
                                         file(credentialsId: env.system, variable: 'KUBECONFIG')]) {
        sh 'bob/bob prepare'
                            sh 'bob/bob -r /your-repo/your-rule.yaml your-new-rule'
                        }
                    }
                }
            }

### Executing the test pipeline

After your commit is ready you just have to push it to Gerrit. This will trigger the job generation and your test pipeline should be visible in Jenkins GUI. At the pipeline triggering  you have to refer to your commit's Gerrit refspec to test your ruleset changes.(this is easier if you set it as default gerrit refspec parameter, like here : string(name: 'GERRIT_REFSPEC',  description: 'Gerrit Refspect', defaultValue: 'refs/changes/45/7804245/52')

You should monitor your test runs in Jenkins that they are working as you expected and the test environment is not locked by it when your tests has finished.

## Pushing your change to repo

When you have finished your tests you should create a commit with similar content for the repo and ask Product CI Team to review your commit. Please include your test results to this review request.
CR+1 vote has to be given by the Product CI Team, this will trigger the related CI pipelines and if they pass your change will be merged to the repo's master branch. THe whole flow is described at [this page](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/documentation/userGuidesForHelmChartModification.md)
