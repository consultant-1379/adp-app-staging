# Developing and running functional test on product CI code base

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## When we want to run functional tests:

* Jenkins or plugin updates
* other environment changes eg. node updates
* shared library changes

## Parts of the testing

* Test environment
* Functional test loop
* Functional tests

## Our current (fix) test environment

* Current test jenkins: <https://seliius27102.seli.gic.ericsson.se:8443/>
more information here:  <https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/jenkins.md>
* For now, we use "prod-ci-test" as test branch

## How to setup a test environment

### Create, install jenkins (later phase we can setup jenkins in docker)

### Setup nodes see : <https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/ansible/ansible-usage.md>

### Check plugins - Check and update plugins if necessary

Every plugin version has to be the same  on main and test Jenkins, except if we want to test new plugin version

Check it from script:

```
        Jenkins.instance.pluginManager.plugins.each{
            plugin ->  println ("${plugin.getDisplayName()} (${plugin.getShortName()}): ${plugin.getVersion()}")
        }
```

or through api:

```
        wget https://seliius27190.seli.gic.ericsson.se:8443//pluginManager/api/xml?depth=1&xpath=/*/*/shortName|/*/*/version&wrapper=plugins
```

### Setup seed job

* Scp the content of [config_all_seed_jobs](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/config_all_seed_jobs/) to Test-Jenkins (seliius27102) and reload configuration from disk
  * [all_jobs_seed_config.xml](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/config_all_seed_jobs/all_jobs_seed_config.xml) --> seliius27102:/local/jenkins-home/jobs/all-jobs-seed/config.xml
  * [all_jobs_seed_shared_lib__config.xml](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/config_all_seed_jobs/all_jobs_seed_shared_lib__config.xml) --> seliius27102:/local/jenkins-home/jobs/all-jobs-seed-shared-lib/config.xml

Using API:

```
https://seliius27102.seli.gic.ericsson.se:8443/manage#
```

Using cli:

```
java -jar jenkins-cli.jar -s https://jenkins.example.com/ reload
```

### Check seed job availability

* We should have <https://seliius27102.seli.gic.ericsson.se:8443/job/all-jobs-seed/> at this point, check with api, if it's available or not

```
curl --silent '${TEST_JOB_URL}/api/json'  --user ${TEST_USER}:${TEST_USER_PASSWORD} --insecure
```

### Create global Jenkins enviroment varianle "MAIN_BRANCH" value "prod-ci-test" in test Jenkins

## Functional test loop

This loop is a pipeline job with gerrit trigger

* technicals/functional_test/functional_test_loop.groovy
* technicals/functional_test/functional_test_loop.Jenkinsfile

The job can be triggered from

* [`eea-product-ci-code-loop`](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/configure/390c5aae-f48d-424d-9195-74bed4bf0e73) Spinnaker pipeline from `Functional tests` stage
  * Trigger of this validation pipeline is the code review +2 event for a commit which contains change in adp-app-staging/pipelines/ or in adp-app-staging/jobs
* manually from [`functional-test-loop`](https://seliius27190.seli.gic.ericsson.se:8443/job/functional-test-loop/) Jenkins job

### Functional test loop parameters

* GERRIT_REFSPEC (only in case of adp-app-staging testing)
* CHART_NAME (only in case of shared library testing)
* CHART_REPO (only in case of shared library testing)
* CHART_VERSION (only in case of shared library testing)
* SPINNAKER_TRIGGER_URL
* SPINNAKER_ID

The job can currently test adp-app-staging commits or ci_shared_libraries changes - depending on the input parameters.

* In case of testing adp-app-staging commits `GERRIT_REFSPEC` parameter must be used, and `CHART_...` parameters should remain empty.
* In case of testing Ci Shared Libraries, `CHART_NAME`, `CHART_REPO`, `CHART_VERSION` parameters (generated during the `eea-product-ci-shared-libraries-validate-and-publish job`) must be used, and `GERRIT_REFSPEC` should remain empty.

### Stages of the test loop

* Params DryRun check Checkout - same as every pipeline
* Check for shared library changes
* Gerrit message
* Set Spinnaker link
* Validate patchset changes
* Check which files changed - .md
* Collect changed files to validate
  * This stage collects information about which validation should be performed for which changed files.
  * There is a limitation how many independent validation can run in the same round. It's defined in the `maximumNumberOfFilesToValidate` with current value: 2
  * If you prepare a commit and it gets CR+2 which contains more validation request than this limit, the following error will be raised:
    * `Too many files are changed in the patchset, which must be validated in the functional test loop.\nPlease split the commit. ...`
* Run when not just .md file in the change
  * Set LATEST_CI_LIB_TEST tag
  * Test Jenkins setup
    * Jenkins setup - In later phase we can setup here a dockerized jenkins, now we use our fix test jenkins
      * setting jenkins url
      * setting test branch name
      * check all-jobs-seed availability on test jenkins through api
    * Running test - with resource locking
      * Creating/recerating test branch
        * checking out the change we want to test
        * from that change creating a new branch
      * Setup jobs on test environment
        * checking out test branch
        * build all jobs with all-jobs-seed on test-jenkins //TODO grooming :later with versioning we can modify to build only the changed jobs until the last version
        * run dry-runs for every job, this can take more than 5 minutes now
        * Run tests - running the specified test
      * Running tests from wrapper
        * Execute functional test(s) for the predefined wrapperJob and validatorJob one by one
        * You can define those parameters in the validationParams object at the beginning of the [source](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/technicals/functional_test/functional_test_loop.Jenkinsfile)
        * This List of Maps object contains the following values
          * fileName: the file name from the repo to validate
          * validatorJob: this job will be executed on test Jenkins by the wrapper job
          * wrapperJob: this is the name of the wrapper job on master Jenkins
            * if not defined 'wrapperJobWithCluster' will be used
            * possible values:
              * wrapperJobWithoutCluster
              * wrapperJobWithCluster
          * deployType": in case of install jobs both HELM and CMA configurations need to be validated
            * this means that 2 install test validation will be executed:
              * one with HELM_AND_CMA_VALIDATION_MODE=false
              * one with HELM_AND_CMA_VALIDATION_MODE=true
            * possible values:
              * deployTypeInstall
              * deployTypeUpgrade
* Declarative: Post Actions
  * Delete test branch
  * Notify the authors in mail if any failure occurs

## Functional tests

Jenkins pipeline jobs executed by the functional test loop
Location of the test jobs: technicals/functional_test/tests/

### How this test works:

This test is running on main-jenkins, and from there checks if the jobs or functions are working on test-jenkins correctly.

### Main test design rules:

* The functional test loop and functional test should not be tested this way (with themself)
* If we want to test a jenkins version or a jenkins plugin update, we have to set our jenkins first then run as many test as necessary
* for a pipeline change test we may need configure test artifactories and test branches for the drop repositories //TODO link documentation or example later
* for testing a new library, first we have to create test branch for the library repo and configure it in jenkins, then run as many test as necessary //TODO link documentation or example later
* we should use timeout function in tests, and put the test steps into try-catch blocks to check the results

### How can we start loops or jobs on test-jenkins

* With making changes on test branch, we can test the jobs triggered on test jenkins. Steps of this kind of test can be:

1. get the next build number from the tested job through api
2. checkout test branch, push changes
3. polling test jenkins, check if job with the new build number finished on test-jenkins
4. check the result
see example test : ```technicals/functional_test/tests/dummy_test.Jenkinsfile```

* Remote trigger plugin:
* On test jenkins we can start jobs using remote trigger plugin. For this, the object job has to be setup as remote triggered. See <https://plugins.jenkins.io/Parameterized-Remote-Trigger/>
* In this case we can simple start the job, and polling the result or set wait=true to wait and check the result. In the second case the step will fail if the remote job fail by default.

### Example stages of a test:

* Declarative: Checkout SCM -  same as every pipeline
* Params DryRun check Checkout  same as every pipeline
* init set test parameters like job name, nest build number, required result
* push patchset to test branch - as described before
* check job in test jenkins -as described before

## CMA related stages and steps

See page [CMA configurations in product deployments](https://eteamspace.internal.ericsson.com/display/ECISE/CMA+configurations+in+product+deployments)
