# Guide for developers how to implement new functions in the shared library

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Description

Pipeline has support for creating "Shared Libraries" which can be defined in external source control repositories and loaded into existing Pipelines.
[Jenkins documentation for using shared libraries](https://www.jenkins.io/doc/book/pipeline/shared-libraries/)

## How to use shared lib in Jenkins

Teams can use shared libraies in their Jenkins and pipelines different ways, it depends on their needs hoe they do the configurations.

Most important configurations for Global Shared Lib in Jenkins:

+ Name: you will use in your Jenkinsfile the @Library annotation with this name
+ Default version: Might be a branch name, tag, commit hash, etc., according to the SCM
+ Allow default version to be overridden: with this enabled you can overwite the Jenkins default in your Jenkinsfiles

Examples:

```
/* Using a Jenkins default config */
@Library('ci_shared_library_eea4') _
/* Using a version specifier, such as branch, tag, etc */
@Library('ci_shared_library_eea4@1.0') _
/* Accessing multiple libraries with one statement */
@Library(['ci_shared_library_eea4', 'otherlib@abc1234']) _
/* Using a gerrit refspec for testing change
@Library('ci_shared_library_eea4@changes/53/15084153/2') _
```

### Using latest

+ (-) not the same what Prodct CI using
+ (+) a new change merged sooner then the Product CI starts using it

### Using fix version

+ (-) if you have your own Jenkins easy to configure and safer then use the latest
+ (+) it can be hard to upgrade from a very old version

### Using Product CI tags

+ (+) safest option, the same what the Product CI loops using (all of them)
+ (-) can be long time until the tag moving (even a day)

### How Product CI using shared lib in own Jenkins

Product CI configured the ci-shared-lib as Global Shared Library in the Jenkins instances with the

+ Main Jenkins:
Name: ci_shared_library_eea4
Default version: LATEST_CI_LIB  (git tag)
+ Test Jenkins:
Name: ci_shared_library_eea4
Default version: LATEST_CI_LIB_TEST (git tag)

In our Jenkinsfiles we alway using the default Jenkins configurations

```
@Library('ci_shared_library_eea4') _
```

## How to develop new funtions in this shared library

### How to document

In Product CI shared Library we using [JavaDoc comments as documentation](https://www.baeldung.com/javadoc)
The changes

### How to create tests

Functional tests:

Functional testing can be done by creating new stages and call the new or changed functions from a Jenkins job.
You can add new stages [here](https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master/jenkins/pipelines/functional_test_shared_lib.Jenkinsfile), or later you can even add nem Jenkinsfiles.
The new tests should be pushed to the repo together with the new functions.
These tests will be run on a test Jenkins instatnce and the git changes will be run on a test branch what will be deleted at the end of the validation. (e.g in tests like stage 'git createPatchset (with push)')
The result of the validations will be commented to your change.

Unit tests:

Dvelopment ongoing...

### Workflow to have a new change validated and merged

+ When your patchset was validated by the patchset hooks (see chapter "How a change validated and when the Product Ci starts using it") and you have Verified +1, you can ask for review from the Product CI team in [mail](pdleea4pro@pdl.internal.ericsson.com) or on the [CI Cop Channel](https://teams.microsoft.com/l/channel/19%3a023a58c23b184852b8bb1c2c27677517%40thread.skype/EEA4%2520CI%2520CoP?groupId=940ac9a1-d4ab-41e1-872f-2a021caa4922&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f)
+ After you got +1 to your change an automated workflow will run functional tests, merge the change if the test were successful and tag the change with the new verion number. The merge will trigger an other validation process, where the new library version will be tested with Product CI pipelines. After that validation, the latest tag will be moved to the new version.

## How a change validated and when the Product Ci starts using it

The changes will be vaidated automatically or during code review

+ validate if functional tests created for new functions: patchset hooks will be triggered for every non-draft changes  (in patchset hooks or CR)
+ documentation added or modified (in patchset hooks or CR)
+ with unit tests (in patchset hooks WIP)
+ with functional tests : (after code review)
+ with E2E tests with staging pipelines (in Product CI code base functional tests loop befor movig LATEST_CI_LIB tag)
