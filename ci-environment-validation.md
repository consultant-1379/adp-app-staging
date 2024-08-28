# Validation of CI environment changes

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Parts of validation

+ Before adding changes to the production pipelines we need to validate the CI code changes
+ Validation levels:
  + Static code analysis on Gerrit patchset level
    + integration in SonarQube if possible to define Quality levels there - TBA
    + CI code repo
      + [Validating jobDSL code](https://wcdma-jira.rnd.ki.sw.ericsson.se/browse/EEAEPP-40666) - [patchset-verify-jobs](https://seliius27190.seli.gic.ericsson.se:8443/view/Technicals/job/patchset-verify-jobs/)
      + [Validating that jobDSL code contains only allowed steps as the pipeline logic has to be defined in the Jenkinsfiles](https://wcdma-jira.rnd.ki.sw.ericsson.se/browse/EEAEPP-40668) - TBA
      + [Validating Jenkinsfile code](https://wcdma-jira.rnd.ki.sw.ericsson.se/browse/EEAEPP-40671) - [verify-hook-job](https://seliius27190.seli.gic.ericsson.se:8443/view/Technicals/job/verify-hook-job/)
      + [Validating external scripts (bash, python 3- integrated in bob lint (flake8, pylint)](https://wcdma-jira.rnd.ki.sw.ericsson.se/browse/EEAEPP-40712) - [Gerrit loops](https://eteamspace.internal.ericsson.com/display/ECISE/Gerrit+loops)
      + [pre-flake8](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/refs/changes/49/7263649/3/technicals/hooks_static/pre_flake8.sh)
      + [pre-shellcheck](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/refs/changes/49/7263649/3/technicals/hooks_static/pre_shellcheck.sh)
    + [Validating CI code base structure](https://wcdma-jira.rnd.ki.sw.ericsson.se/browse/EEAEPP-40667) - [patchset-verify-jobs](https://seliius27190.seli.gic.ericsson.se:8443/job/patchset-verify-jobs/)
    + Validating markdown files (CI documentation, integrated in bob lint) - TBA
      + [pre-pmd-java](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/refs/changes/49/7263649/3/technicals/hooks_static/pre_pmd_java.sh)
    + [Validations of hooks to be reused from ans](https://wcdma-jira.rnd.ki.sw.ericsson.se/browse/EEAEPP-40713) - TBA
      + [pre-authorname](https://gerrit.ericsson.se/plugins/gitiles/EEA/ans/+/HEAD/ci/hooks/pre-authorname)
      + [pre-largefile](https://gerrit.ericsson.se/plugins/gitiles/EEA/ans/+/HEAD/ci/hooks/pre-largefile)
      + [pre-nobinary](https://gerrit.ericsson.se/plugins/gitiles/EEA/ans/+/HEAD/ci/hooks/pre-nobinary)
      + [pre-whitespace](https://gerrit.ericsson.se/plugins/gitiles/EEA/ans/+/HEAD/ci/hooks/pre-whitespace)
+ Integration repo
  + Validating helm charts (integrated in bob lint)
+ Functional validation of CI jobs
  + JobDSL code:
    + Validation of pipeline triggering (if needed)
  + Pipelines
    + Functional tests of pipelines should be done with [dry runs of the pipelines](https://eteamspace.internal.ericsson.com/display/ECISE/Pipeline+guideline#Pipelineguideline-dry_run)
    + If parameter or trigger change occurs in the Jenkinspipeline a dry-run is needed for the pipeline, this will read the new Jenkinsfile from the repository, without this the pipeline will be broken at the next execution so it's mandatory in case of these changes
      + Dry-run parameter has to be defined in all the pipelines as build paramter from the jobDSL code (as input parameter)

## Workflow for developing in CI enviroment

```
Test folder patchset created → Static code analysis → Generate jobs → Manual test → Patchset created → Static code analysis → Code review +1 → Generate job → Functional tests → Version increase / Submit → End
              ^                            v                v                 v                                       v                              v                  v  
              |                            |                |                 |                                       |                              |                  |  
              +----------------------------+----------------+-----------------+---------------------------------------+------------------------------+------------------+
```

| Repository          | Event                             | Triggered event                                                                                                           |                              |
|---------------------|-----------------------------------|---------------------------------------------------------------------------------------------------------------------------|------------------------------|
| adp-app-staging     | test folder patchset created      | Job DSL build, check Jenkinsfile reference, syntax validate Jenkinsfile, static validations, Dry Run                      |                              |
| adp-app-staging     | jobs folder patchset created      | Job DSL build, check if related Jenkinsfile exists in the repo                                                            | +1/-1                        |
| adp-app-staging     | pipelines folder patchset created | syntax validate for Jenkinsfiles (Pipeline CLI linter)                                                                    | +1/-1                        |
| adp-app-staging     | scripts folder patchset created   | static validations                                                                                                        | +1/-1                        |
| adp-app-staging     | verifications, code review +1     | JobDSL build, check Jenkinsfile reference, syntax validate Jenkinsfile, static validations, Dry Run, Functional test loop | version increase, submit     |
| ci_shared_libraries | patchset created                  | unit tests run, static validations                                                                                        | +1/-1                        |
| ci_shared_libraries | verifications +2                  | Increase version in test Jenkins config                                                                                   | Lib version increase, submit |

| HOOKS                                             | jobs/script                                                                                                                                       | Approvals need          |
|---------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------|
| ```jobs/**/*.groovy patchset created```           | patchset-verify: verify_build, validate_dry_run_param, check_pipeline_reference, validate_triggers_tests                                          |                         |
| ```jobs/**/*.groovy +2```                         | seed_job: JobDSL build, run_dry_run                                                                                                               | TODO                    |
| ```tests/*.groovy commit```                       | patchset-verify: verify_build, validate_dry_run_param, check_pipeline_reference, validate_triggers_tests Test_seed_job: JobDSL build, run_dry_run |                         |
| ```tests/*.Jenkinsfile +2```                      | patchset-verify: validate_syntax, validate_shared_libs, validate_triggers_pipeline Test_seed_job: run_dry_run                                     |                         |
| ```pipelines/**/*.Jenkinsfile patchset created``` | patchset-verify: validate_syntax, validate_shared_libs, validate_triggers_pipeline                                                                |                         |
| ```pipelines/***.Jenkinsfile +2```                | seed_job: run_dry_run                                                                                                                             | TODO                    |
| ```library_commit```                              | build, run_unit_tests                                                                                                                             |                         |
| ```library +2```                                  | build, increase version, tag, run_unit_tests, check_version_raise, check tag                                                                      | Product CI Team Approve |
| ```view commit, submit```                        | Same as Jenkins 1 TODO                                                                                                                            | Same as Jenkins 1       |
| ```script commit, submit```                       | Same as Jenkins 1 TODO                                                                                                                            | Same as Jenkins 1       |

validate_dry_run_param

+ Check DRY_RUN parameter config ok
+ Check no other parameters

check_pipeline_reference

+ check referendce given
+ check referenced jenkinsfile exists

validate_triggers_tests

+ check no timer/automated trigger in test job
+ check no other content in job beside params and swcm

validate_syntax

+ jenkinsfile syntax validation on CLI

validate_shared_libs

+ validate shared library existm with the given name, and version

validate_triggers_pipeline

+ validate, that no automated triggers in jenkinsfile

run_dry_run

+ run a jenkins job with DRY_RUN=true parameter
