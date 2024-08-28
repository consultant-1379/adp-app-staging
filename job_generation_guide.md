# Generate jobs from groovy and Jenkinsfile

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Workflow for groovy

+ New patchset uploaded to jobs directory
  + Validation job triggered which generates in the job workspace the jobs defined in the job DSL code from the affected directory or directories
  + If generation is successful verification +1 vote given for the patchset in Gerrit
  + If generation fails verification -1 vote given for the patchset in Gerrit
  + This validation is not functional! Validation checks the content of the dsl groovy files to prevent adding extra logic to the DSL jobs. Logic should be implemented in the Jenkinsfile part of the jobs.
+ Manual code review from the team -> CR +1
  + Merge of the commit to master triggers the related seed job(s) and the jobs defined in that directory (or directories) are regenerated to Jenkins (only the jobs from the affected directories)

## Workflow for jenkinsfile

+ New patchset uploaded to pipelines directory
+ Validation job triggered which checks the syntax of the Jenkinsfile code from the affected directory or directories
  + If generation is successful verification +1 vote given for the patchset in Gerrit
  + If generation fails verification -1 vote given for the patchset in Gerrit
  + This validation is not functional!
+ Manual code review from the team -> CR +1
+ Functional validation of the pipelines with dry runs triggered automatically when CR+1 is given for the commit
  + For this validation a test Jenkins environment is mandatory, [Product CI test Jenkins](https://seliius27102.seli.gic.ericsson.se:8443)
  + Feedback time of this validation should be limited  - only smoke tests executed as part of this verification to validate that pipeline is able to execute E2E tests after the change
  + If this validation passes merge of the code should happen with automated version increase for the CI code
  + If this validation fails the commit can't be merged by the developer, the commit has to be fixed in a new patchset
  + During the validation we should test both flows of the Product CI
    + Triggering by new microservice versions
    + Triggering by change in integration (umbrella) helm chart in cnint Git repository)
    + This validation part will be described later in details during implementation of the pipelines

## Validations

Validation jobs are listed here: [Validation of CI environment changes](https://eteamspace.internal.ericsson.com/display/ECISE/Validation+of+CI+environment+changes).

### Validate job DSL syntax

Changed groovy files will be validated through [patchset-verify-jobs](https://seliius27190.seli.gic.ericsson.se:8443/job/patchset-verify-jobs/).

Syntax validation of the jobDSL code triggered for the jos which are affected by the change in the patchset.

### Validate Jenkinsfile syntax

Changed Jenkinsfiles will be validated through Command Line Pipeline Linter

```
ssh -l eceaproj -p 34291 seliius27190.seli.gic.ericsson.se:8443 -insecure declarative-linter < Jenkinsfile
```

## Seed jobs

+ every E2E CI loop's jobs are in separate folder named by the loop, and every loop has it's own seed job
+ All the seed and verification job's files (groovy, Jenkinsfile, scripts) located in the technicals/ folder.
+ technicals folder also has a seed job, and special tests triggered by the change on them
+ seed jobs are named by the folder (loop), they are responsible for e.g: [eea-application-staging-seed-job](https://seliius27190.seli.gic.ericsson.se:8443/job/patchset-verify-jobs/search/?q=eea-application-staging-seed-job), [tests-seed-job](https://seliius27190.seli.gic.ericsson.se:8443/job/patchset-verify-jobs/search/?q=test-seed-job), [technicals-seed-job](https://seliius27190.seli.gic.ericsson.se:8443/job/patchset-verify-jobs/search/?q=technicals-seed-job)

There are special jobs without groovy

+ [all-jobs-seed](https://seliius27190.seli.gic.ericsson.se:8443/job/all-jobs-seed)
+ [all-jobs-seed-shared-lib](https://seliius27190.seli.gic.ericsson.se:8443/job/all-jobs-seed-shared-lib)

These jobs can be loaded into an empty Jenkins by copying the configs into the workspace of the new Jenkins instance from [here](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/config_all_seed_jobs/)

+ [all_jobs_seed_config.xml](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/config_all_seed_jobs/all_jobs_seed_config.xml) --> seliius27102:/local/jenkins-home/jobs/all-jobs-seed/config.xml
+ [all_jobs_seed_shared_lib__config.xml](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/config_all_seed_jobs/all_jobs_seed_shared_lib__config.xml) --> seliius27102:/local/jenkins-home/jobs/all-jobs-seed-shared-lib/config.xml

These jobs are not triggered by git, it can run manually or from a script and it builds all the jobs under the adp-app-staging repository (CI codebase repository). It's made for the initial run on a test enviroment.

Every time when a groovy file changed in it's folder the seed job will

+ build all the job in the folder
+ validate that the Jenkinsfile exists  (The jenkinsfile has to be pushed to Gerrit in an earlier commit)
+ call dry-run on the jobs

### Call dry run

If the project parameters or properties changed in the Jenkinsfile,  job need to run with DRY_RUN = true in order to update project properties:

More information on [dry run](https://eteamspace.internal.ericsson.com/display/ECISE/Pipeline+guideline#Pipelineguideline-dry_run)

```
parameters { }
properties()
triggers { }
```

```
pipelineJob('test-eea-app-staging-precodereview') {
    parameters {
        booleanParam('DRY_RUN', false)
    }
      definition {
        cpsScm {
            scm{
                git {
                    remote {
                        name 'adp-app-staging'
                        url 'https://eceagit@gerrit.ericsson.se/a/EEA/adp-app-staging'
                        credentials('git-functional-http-user')
                        scriptPath('jobs/test_example.Jenkinsfile')
                    }
                    branch('master')
                }
            }
        }
    }
}
```

```
pipeline {
    agent {
        node {
            label 'docker'
        }
    }
    triggers {
        gerrit (
      serverName: 'SEKA_artifactory',
      gerritProjects: [[
        compareType: 'PLAIN',
        pattern: 'EEA/cnint',
        branches: [[ compareType: 'PLAIN', pattern: 'master' ]],
        disableStrictForbiddenFileVerification: false
      ]],
      triggerOnEvents: [
        patchsetCreated()
      ]
    )
    }
    parameters {
        string(name: 'PARAM1', description: 'Param 1?', defaultValue: '')
        string(name: 'PARAM2', description: 'Param 2?', defaultValue: '')
    }
    stages {
        stage('Params check') {
            steps{
                script {
                    if ("${params.DRY_RUN}" == "Yes") {
                        currentBuild.result = 'ABORTED'
                        currentBuild.displayName = "DRY_RUN_COMPLETED"
                        error('DRY RUN COMPLETED. JOB PARAMETERIZED.')
                    }
                }
            }
        }
        stage('Second stage') {
            steps {
                echo "Second stage TODO "
            }
        }
    }
}
```

## Jenkins view generation

View generation is described at [this page](https://eteamspace.internal.ericsson.com/display/ECISE/Jenkins+views+in+Product+CI).
