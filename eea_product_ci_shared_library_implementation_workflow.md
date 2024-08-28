# [Study] EEA4 Workflow for Product CI Shared Library implementation

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Description

A shared library helps to re-use parts of pipeline allowing pipeline code to be small and easy to maintain. This solution has been added to [ci_shared_libraries](https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master) repository. This study covers plan for implementation and validation workflow of Jenkins shared library.

### Defining Shared Libraries

A Shared Library is defined with a name, a source code retrieval method such as by SCM, and optionally a default version. The name should be a short identifier as it will be used in scripts. The version could be anything understood by that SCM; for example, branches, tags, and commit hashes all work for Git.

### Global Shared Libraries

There are several places where Shared Libraries can be defined, depending on the use-case. Manage Jenkins » Configure System » Global Pipeline Libraries as many libraries as necessary can be configured. Since these libraries will be globally usable, any Pipeline in the system can utilize functionality implemented in these libraries.

## Who and how can implement new features to the CI shared libraries

Gerrit permission must be set that everybody can commit to the library source BUT only Product CI Team member should give +1 for code review.

**Important:**
Shared libraries are considered "trusted:" they can run any methods in Java, Groovy, Jenkins internal APIs, Jenkins plugins, or third-party libraries. This allows you to define libraries which encapsulate individually unsafe APIs in a higher-level wrapper safe for use from any Pipeline.
Beware that anyone able to push commits to this SCM repository could obtain unlimited access to Jenkins.
You need the Overall/RunScripts permission to configure these libraries (normally this will be granted to Jenkins administrators).

## How can we use fixed version of the library in Jenkins?

In our current Product CI pipelines we are always using CI shared libraries from the master branch HEAD.

BUT the new WoW should use specified git tag to load different library version, eg. "LATEST_CI_LIB".

This git tag should created once and updated when a change in CI shared library successfully tested by:

* Patchset level static validation (syntax and unit tests)
* Functional validation of CI Shared Library functions
* Functional validation of CI Jenkins pipelines (ex. with nx1 job)

The advantage of this method is that we don't need to modify the pipeline sources.
We have to modify only some git tag reference and the central configuration of Jenkins library used by the pipelines.

This "LATEST_CI_LIB" git tag should also be configured only once at Manage Jenkins » Configure System » Global Pipeline Libraries for the item: "ci_shared_library_eea4" with modifying "Default version" property from the current value: "master" to "LATEST_CI_LIB". From then on, pipelines that use `@Library ('ci_shared_library_eea4')` annotation should load this specific version.

## Using libraries

Shared Libraries marked Load implicitly allows Pipelines to immediately use classes or global variables defined by any such libraries. To access other shared libraries, the Jenkinsfile needs to use the `@Library` annotation, specifying the library’s name.

A default version of the library will load if a script does not select another.
But if necessary we can also use fixed tags (ex. "LATEST_CI_LIB"), fixed version numbers (ex. "2.0") or branches (ex. "prod-ci-test") in pipeline scripts to identify the exact version to be used. Only constant values are accepted in Jenkinsfiles.

```groovy
// Using the default version configured in Global Pipeline Libraries
@Library('ci_shared_library_eea4') _

// Using a version specifier, such as branch, tag, commitId
@Library('ci_shared_library_eea4@test-branch') _
@Library('ci_shared_library_eea4@latest') _
@Library('ci_shared_library_eea4@1.0') _

// Accessing multiple libraries with one statement
@Library(['ci_shared_library_eea4', 'otherlib@abc1234']) _
```

### Development / testing workflow

For testing purposes you just change the top line in the pipeline, `@Library` annotation. For example, for testing the [change](https://gerrit.ericsson.se/#/c/12200931/) with REFSPEC refs/changes/31/12200931/4:

```groovy
// Using REFSPEC (without refs/ prefix) specified after @ sign
@Library('ci_shared_library_eea4@changes/31/12200931/4') _
```

This works because we added `Discover other refs: changes/*` behaviour to 'ci_shared_library_eea4' under Manage Jenkins » Configure System » Global Pipeline Libraries.

Alternative deprecated way was to create a separate library with Legacy SCM configuration and specify the refspec in it.

Unfortunatelly we cannot use dynamic library loading easily because we have to use complex classes (from src/), not only global variables/functions (from the vars/ directory).

### Loading libraries dynamically

Although it is not necessary to use dynamic loading in our own Prod CI processes, for the sake of completeness, please find details below how can we load shared libraries dynamically.

Using classes from the src/ directory is also possible, but trickier. Whereas the @Library annotation prepares the “classpath” of the script prior to compilation, by the time a library step is encountered the script has already been compiled. Therefore you cannot import or otherwise “statically” refer to types from the library.
However you may use library classes dynamically (without type checking), accessing them by fully-qualified name from the return value of the library step.
More info: [https://www.jenkins.io/doc/book/pipeline/shared-libraries/#loading-libraries-dynamically](https://www.jenkins.io/doc/book/pipeline/shared-libraries/#loading-libraries-dynamically)

#### Static methods can be invoked using a Java-like syntax

```groovy
library('my-shared-library').com.mycorp.pipeline.Utils.someStaticMethod()
```

#### Custom branch loading

```groovy
env.TEST_BRANCH_NAME = 'test-branch'
library(
  identifier: "jenkins-shared-library@${TEST_BRANCH_NAME}",
  retriever: modernSCM(
    [
      $class: 'GitSCMSource',
      remote: 'https://eceagit@gerrit.ericsson.se/a/EEA/ci_shared_libraries',
      credentialsId: 'git-functional-http-user'
    ]
  )
)

@Field def arm = jsl.com.ericsson.eea4.ci.Artifactory.new(this, "https://arm.seli.gic.ericsson.se/",  "API_TOKEN_EEA")
// TODO(): need to find out why got an exeption
// org.jenkinsci.plugins.workflow.cps.CpsCompilationErrorsException: startup failed:
// General error during conversion: Annotation Grab cannot be used in the sandbox.
```

#### Custom patchset loading

```groovy
if (env.GERRIT_PATCHSET_REVISION) {
  echo("Using shared-library for verification.")

  library([
    identifier: 'myLibrary@' + env.GERRIT_PATCHSET_REVISION,
    retriever: modernSCM([
      $class: 'GitSCMSource',
      remote: 'https://eceagit@gerrit.ericsson.se/a/EEA/ci_shared_libraries',
      credentialsId: 'git-functional-http-user',
      traits: [
        [$class: 'jenkins.plugins.git.traits.BranchDiscoveryTrait'],
        [
          $class: 'RefSpecsSCMSourceTrait',
          templates: [
            [value: '+refs/heads/*:refs/remotes/@{remote}/*'],
            [value: "+refs/changes/*:refs/remotes/@{remote}/*"]
          ]
        ]
      ]
    ])
  ])
} else {
  echo("Using shared-library from branch (not a verification).")

  library("myLibrary@" + env.BRANCH_NAME)
}
// TODO(): need to find out why got an exeption
// stderr: fatal: ambiguous argument 'refs/changes/31/12200931/4^{commit}': unknown revision or path not in the working tree.
```

## Validating changes in library without affecting live pipelines

### Patchset level static validation

* New patchset uploaded to ci_shared_libraries directory
  * Validation job (eea-product-ci-shared-libraries-precodereview) triggered
    * check the syntax of the files from the affected directory or directories using [run_verify_hooks_common.sh](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/technicals/shellscripts/run_verify_hooks_common.sh)
        The original run_verify_hooks.sh functionality has to be extended to be usable for any repository (not only for cnint/adp-app-staging)
    * Run unit tests
        **Important:**: in the first round of implementation, only its location would be determined, after that its full implementation could take place
  * If pre validation job is successful verification +1 vote given for the patchset in Gerrit
  * If pre validation job fails verification -1 vote given for the patchset in Gerrit
  * This pre validation is not functional!
* Manual code review from the team -> CR +1

* ci_shared_libraties* seed job (.groovy & .Jenkinsfile): should be placed in technicals/eea_product_ci_shared_libraries_seed_job.groovy technicals/eea_product_ci_shared_libraries_seed_job.Jenkinsfile

* Pre Validation job (.groovy): should be placed in jobs/eea_product_ci_shared_libraries/eea_product_ci_shared_libraries_precodereview.groovy

* Pre Validation job (.Jenkinsfile): should be placed in pipelines/eea_product_ci_shared_libraries/eea_product_ci_shared_libraries_precodereview.Jenkinsfile

* Test job: [https://seliius27190.seli.gic.ericsson.se:8443/job/zsloboh_test_eea_product_ci_shared_libraries_precodereview/](https://seliius27190.seli.gic.ericsson.se:8443/job/zsloboh_test_eea_product_ci_shared_libraries_precodereview/)

* Job contents

**triggers:**

```groovy
triggers {
    gerrit (
        serverName: 'GerritCentral',
        gerritProjects: [[
            compareType: 'PLAIN',
            pattern: 'EEA/ci_shared_libraries',
            branches: [[ compareType: 'PLAIN', pattern: env.MAIN_BRANCH ]],
            disableStrictForbiddenFileVerification: false,
            topics: [[ compareType: 'REG_EXP', pattern: '^((?!^inca$).)*$' ]]
        ]],
        triggerOnEvents:  [
            [
                $class              : 'PluginPatchsetCreatedEvent',
                excludeDrafts       : true,
                excludeTrivialRebase: false,
                excludeNoCodeChange : false
            ],
            [
                $class                      : 'PluginCommentAddedContainsEvent',
                commentAddedCommentContains : '.*rebuild.*'
            ],
            [
                $class                      : 'PluginDraftPublishedEvent'
            ]
        ]
    )
}
```

**stages:**

* Params DryRun check

* Checkout - ci_shared_libraries

```groovy
stage('Checkout - ci_shared_libraries') {
    steps {
        script {
            gitlib.checkoutRefSpec("${GERRIT_REFSPEC}", "FETCH_HEAD", '')
        }
    }
}
```

* Checkout - adp-app-staging repo scripts:

```groovy
stage('Checkout - scripts') {
    steps {
        dir('technicals') {
            withCredentials([usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GIT_USER', passwordVariable: 'PASSWORD' )]) {
                script {
                    gitadp.archive("${GIT_USER}"+"@gerrit.ericsson.se:29418/EEA/adp-app-staging",'HEAD:technicals/')
                }
            }
        }
    }
}
```

* Run Jenkins patchset hooks:

```groovy
stage('Jenkins patchset hooks') {
    steps {
        script {
            try {
                def result = sh(
                    script: "cd ${WORKSPACE} && ./technicals/shellscripts/run_verify_hooks_common.sh \$GERRIT_PATCHSET_REVISION \$BUILD_URL ${WORKSPACE}",
                        returnStatus : true
                )
                sh "echo ${result}"
                if (result != 0) {
                    currentBuild.result = 'FAILURE'
                }
            } catch (err) {
                echo "Caught: ${err}"
                currentBuild.result = 'FAILURE'
            }
        }
    }
}
```

* Run unit tests: this needs to be organized in a separate part, but its location is likely to be here

### Functional validation

* Functional validation (eea-product-ci-shared-libraries-vaildate-and-publish) with dry runs triggered automatically when CR+1 is given for the commit
* For this validation a test Jenkins environment is mandatory, [Product CI test Jenkins](https://seliius27102.seli.gic.ericsson.se:8443)
* Feedback time of this validation should be limited - only smoke tests executed as part of this verification to validate that pipeline is able to execute E2E tests after the change
* If this validation passes merge of the code should happen to master branch, we also need tagging the version in this part.
* If this validation fails the commit can't be merged by the developer, the commit has to be fixed in a new patchset

* Main test design rules:
  * for testing a new library change, first we have to create test branch for the library repo and configure it in jenkins, then run as many test as necessary
  * we should use timeout function in tests, and put the test steps into try-catch blocks to check the results

* CI Shared Library Functional test job:
  * This job is running on test-jenkins, remotely triggered from main-jenkins to checks if the CI shared library functions are working on test-jenkins without affecting production pipelines and codes.
  * This job prepared and configured by executing [all-jobs-seed-shared-lib](https://seliius27102.seli.gic.ericsson.se:8443/job/all-jobs-seed-shared-lib/). See more details for [all-jobs-seed](https://eteamspace.internal.ericsson.com/display/ECISE/Generate+jobs+from+groovy+and+Jenkinsfile#GeneratejobsfromgroovyandJenkinsfile-Seedjobs)
  * Location of the functional test jobs:
    * ci_shared_libraries/jenkins/jobs/functional_test_shared_lib.groovy
    * ci_shared_libraries/jenkins/pipelines/functional_test_shared_lib.Jenkinsfile

* Post Validation job (.groovy): should be placed in jobs/eea_product_ci_shared_libraries/eea_product_ci_shared_libraries_vaildate_and_publish.groovy
* Post Validation job (.Jenkinsfile): should be placed in pipelines/eea_product_ci_shared_libraries/eea_product_ci_shared_libraries_vaildate_and_publish.Jenkinsfile

* Test job: [https://seliius27190.seli.gic.ericsson.se:8443/job/test-etamgal-ci-shared-lib-codereview-ok/](https://seliius27190.seli.gic.ericsson.se:8443/job/test-etamgal-ci-shared-lib-codereview-ok/)

* Job contents

**triggers:**

```groovy
triggers {
    gerrit (
        serverName: 'GerritCentral',
        gerritProjects: [[
            compareType: 'PLAIN',
            pattern: 'EEA/ci_shared_libraries',
            branches: [[ compareType: 'PLAIN', pattern: env.MAIN_BRANCH ]],
            disableStrictForbiddenFileVerification: false,
            topics: [[ compareType: 'REG_EXP', pattern: '^((?!^inca$).)*$' ]]
        ]],
        triggerOnEvents:  [
            [
                $class              : 'PluginCommentAddedEvent',
                verdictCategory       : 'Code-Review',
                commentAddedTriggerApprovalValue: '+1'
            ]
        ]

    )
}
```

**stages:**

* Params DryRun check

* Checkout - adp-app-staging repo scripts:

```groovy
script {
    gitadp.sparseCheckout("technicals/")
}
```

* Checkout - ci_shared_libraries

```groovy
script {
    gitlib.checkoutRefSpec("${GERRIT_REFSPEC}", "FETCH_HEAD", 'ci_shared_libraries')
}
```

* Rebase

* Check Reviewer:
  * when the commit contain .groovy files, it needs a Product CI reviewer:

```groovy
stage ('Check Reviewer') {
    steps {
        script {
            env.CI_GROUP = 'EEA4\\ CI\\ team'
            env.REVIEWERS_LIST = gitlib.listGerritMembers(env.CI_GROUP)
            sh '''
            set +x
            [[ ${REVIEWERS_LIST} =~ ${GERRIT_EVENT_ACCOUNT_EMAIL} ]] && \
                echo "${GERRIT_EVENT_ACCOUNT} found in the EEA4 CI team Gerrit Group" || \
                { echo "Need a Code-Review from the EEA4 CI team Gerrit Group member! Members:\n${REVIEWERS_LIST}" ; exit 1; }
            set -x
            '''
        }
    }
}
```

* Check which files changed
  * to skip testing if only doc files changed

* Check Test Jenkins seed job availability
  * We should have [all-jobs-seed-shared-lib](https://seliius27102.seli.gic.ericsson.se:8443/job/all-jobs-seed-shared-lib/) at this point, check with api, if it's available or not

```groovy
sh '''
    curl -XGET ${TEST_JENKINS_URL}/job/all-jobs-seed-shared-lib/api/json --user $TEST_USER:$TEST_USER_PASSWORD --insecure
'''
```

* Create lock
  * for label: test-jenkins (should be configurable)
    * TO run paralell with the general CI functional test we should create separated lock resource for testing CI sharewd library changes.
    * If we use the existing resource we will probably faced the situation many times when we have to wait for the functional testing of Product CI pipelines (nx1, batch jobs), which is currently running for up to several hours.

* Creating/Recreating test branch
  * with name: prod-ci-test (should be configurable)
    * We can use the existing Jenkins global properties: "MAIN_BRANCH" which has the value "prod-ci-test" in test Jenkins.
    * It will not collide with adp-app-staging, because this will executed in another repo (ci_shared_libraries)

* Setup jobs on test environment

```groovy
stage('Setup jobs on test environment') {
    steps {
        step([$class: 'RemoteBuildConfiguration',
            auth2 : [$class: 'CredentialsAuth', credentials:'test-jenkins-token' ],
            remoteJenkinsName : 'test-jenkins',
            remoteJenkinsUrl : "${TEST_JENKINS_URL}",
            job: 'all-jobs-seed-shared-lib',
            token : 'kakukk',
            overrideTrustAllCertificates : true,
            trustAllCertificates : true,
            blockBuildUntilComplete : true
            ]
        )
    }
}
```

* Run functional test job on test environment

```groovy
stage('Run functional test job on test environment') {
    steps {
        step([$class: 'RemoteBuildConfiguration',
            auth2 : [$class: 'CredentialsAuth' ,credentials:'test-jenkins-token' ],
            remoteJenkinsName : 'test-jenkins',
            remoteJenkinsUrl : "${TEST_JENKINS_URL}",
            job: "functional-test-shared-lib",
            token : 'kakukk',
            overrideTrustAllCertificates : true,
            trustAllCertificates : true,
            blockBuildUntilComplete : true
            ]
        )
    }
}
```

* Increment version in ci_shared_libraries/VERSION_PREFIX
  * using docker-image: adp-release-auto, cmd: version-handler generate

```yaml
generate-version:
    - task: version
      docker-image: adp-release-auto
      cmd: version-handler generate
        --is-release true
        --output version
        --git-repo-path .
    - task: remove-dirty
      cmd:
        - cat .bob/var.version |cut -d "." -f1-3 > .bob/version-tmp
        - cat .bob/version-tmp > .bob/var.version
```

* Submit & merge changes to master

```groovy
stage('Submit & merge changes to master') {
    steps {
        dir ('ci_shared_libraries'){
            script {
                env.COMMIT_ID = gitlib.getCommitHashLong()
                echo "env.COMMIT_ID=${env.COMMIT_ID}"
                gitlib.gerritReviewAndSubmit(env.COMMIT_ID, '--verified +1 --code-review +2 --submit', 'EEA/ci_shared_libraries')
            }
        }
    }
}
```

* Tag the version in ci_shared_libraries repo, using direct git cmds

```bash
git tag -a 1.2.3-45 -m 'ci_shared_libraries-1.2.3-45'
git push origin 1.2.3-45
```

* or using bob rule

```yaml
create-git-tag:
    - task: git-tag
      docker-image: adp-release-auto
      docker-flags:
        - "--env HELM_VERSION=${env.HELM_VERSION}"
        - "--env GERRIT_USERNAME"
        - "--env GERRIT_PASSWORD"
      cmd: version-handler create-git-tag
        --tag "${env.GIT_TAG_STRING}"
        --message "${env.GIT_TAG_STRING}"
        --git-repo-url ${env.GIT_REPO_URL}
        --commitid ${env.COMMIT_ID}
```

* Publish shared library changes to CI code
  * Call job: eea-product-ci-shared-libraries-ci-code-version-update

```groovy
build job: eea-product-ci-shared-libraries-ci-code-version-update,
    parameters: [
        ...
    ],
    wait : true
```

## Publish shared library changes to CI code

* Jenkins: eea-product-ci-shared-libraries-ci-code-version-update:
  * job is triggered directly from job: eea-product-ci-shared-libraries-vaildate-and-publish
  * job is responisble for:
    * update and push change with the value of the ci_shared_libraries.version in adp-app-staging repo in eric-eea-ci-code-helm-chart/Chart.yaml --> GERRIT_REFSPEC
    * extend artifact.propeties with GERRIT_REFSPEC and CI_LIB_VERSION that contains shared library version information

* Spinnaker: eea-product-ci-code-manual-flow
  * existing trigger: eea-app-baseline-manual-flow-codereview-ok
  * new trigger should add: eea-product-ci-shared-libraries-ci-code-version-update

* Spinnaker: eea-product-ci-code-loop
  * "Functional tests" stage / "functional-test-loop" job modification
    * required condition: if CI_LIB_VERSION exists with value of ci_shared_libraries.version
    * required action 1: "LATEST_CI_LIB_TEST" git tag should point to the change of the new lib version commit tag
    * required action 2: run eea-adp-staging-adp-nx1-loop job validating CI shared library code changes on test jenkins with a real pipeline

* Spinnaker: eea-product-ci-code-loop
  * "Publish" stage / "eea-product-ci-code-loop-publish" job modification
    * required condition: if CI_LIB_VERSION exists with value of ci_shared_libraries.version
    * required action: "LATEST_CI_LIB" git tag should point to CI_LIB_VERSION in the git repo

## Implement unit testing for shared library

Running unit tests should be the part of the Patchset level static validation.

**Important:**
This needs to be organized in a separate part. In the first round of implementation, only its location would be determined, after that its full implementation could take place.

### Prerequisites

Jenkins must be configured to run Maven using Jenkins Tools under "Managing Jenkins" → "Global Tool Configuration".

* JDK / JDK installations / Add JDK
  * Name: jre11
  * JAVA_HOME: /usr/lib64/jvm/jre-11-openjdk
  * Install automatically: FALSE

* Maven / Maven installations / Add Maven
  * Name: Maven 3.8.5
  * Install automatically: TRUE

### Define job for executing unit tests

To run CI shared library unit tests using Maven we should create a Declarative Pipeline.

* Test job: [https://seliius27102.seli.gic.ericsson.se:8443/job/test-etamgal-mvn](https://seliius27102.seli.gic.ericsson.se:8443/job/test-etamgal-mvn)

```groovy
pipeline {
    agent any
    tools {
        maven 'Maven 3.8.5'
        jdk 'jre11'
    }
    stages {
        stage ('Initialize') {
            steps {
                sh '''
                    echo "PATH = ${PATH}"
                    echo "M2_HOME = ${M2_HOME}"
                '''
            }
        }

        stage ('Test') {
            steps {
                sh 'mvn --version'
                // sh 'mvn test' // TODO(): execute unit tests
            }
        }
    }
}
```

* For more details to define and run Maven projects, check links:
  * [https://www.jenkins.io/blog/2017/02/07/declarative-maven-project/](https://www.jenkins.io/blog/2017/02/07/declarative-maven-project/)
  * [https://plugins.jenkins.io/pipeline-maven/](https://plugins.jenkins.io/pipeline-maven/)

* Useful links for testing:
  * My Jenkins Shared Library Series
    * [What Are Jenkins Shared Libraries](https://itnext.io/jenkins-shared-libraries-part-1-5ba3d072536a)
    * [How To Build Your Own Jenkins Shared Library](https://itnext.io/how-to-build-your-own-jenkins-shared-library-9dc129db260c)
    * [Unit Testing a Jenkins Shared Library](https://itnext.io/unit-testing-a-jenkins-shared-library-9bfb6b599748)
    * [Collecting Code Coverage for a Jenkins Shared Library](https://itnext.io/collecting-code-coverage-for-a-jenkins-shared-library-c2d8f502732e)
  * Pipeline Development Tools ([https://www.jenkins.io/doc/book/pipeline/development/](https://www.jenkins.io/doc/book/pipeline/development/))
  * Pipeline Unit Testing Framework ([https://github.com/jenkinsci/JenkinsPipelineUnit](https://github.com/jenkinsci/JenkinsPipelineUnit))
  * Writing Testable Libraries ([https://github.com/jenkinsci/JenkinsPipelineUnit#writing-testable-libraries](https://github.com/jenkinsci/JenkinsPipelineUnit#writing-testable-libraries))
  * [The README](https://github.com/jenkinsci/JenkinsPipelineUnit/blob/master/README.md) for that project contains examples and usage instructions.
      The Pipeline Unit Testing Framework allows you to unit test Pipelines and Shared Libraries before running them in full.
      It provides a mock execution environment where real Pipeline steps are replaced with mock objects that you can use to check for expected behavior.
      New and rough around the edges, but promising.
  * pipelineUnit ([https://github.com/macg33zr/pipelineUnit](https://github.com/macg33zr/pipelineUnit))
  * Pipeline Testing ([https://confluence-oss.seli.wh.rnd.internal.ericsson.com/display/CICD/Testing](https://confluence-oss.seli.wh.rnd.internal.ericsson.com/display/CICD/Testing))

* Developer test environment install
  * [http://groovy-lang.org/install.html](http://groovy-lang.org/install.html))
  * [https://maven.apache.org/install.html](https://maven.apache.org/install.html))
  * [https://gradle.org/install](https://gradle.org/install))
  * [https://www.jetbrains.com/help/idea/installation-guide.html](https://www.jetbrains.com/help/idea/installation-guide.html))

## Code review process changes after automatic validation is activated

Important change after the new automated [Functional validation](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-ci-shared-libraries-vaildate-and-publish/) job is ativated, that reviewers of the ci shared library code should add only +1 instead of +2 in Gerrit. In that case the ci shared library functional test will be executed and the changes will be merged automatically, like in our existing application staging loop.

## Related JIRA items

* [EEAEPP-41052 - study: Workflow for shared library implementation](https://eteamproject.internal.ericsson.com/browse/EEAEPP-41052)
* [EEAEPP-40739 - Implement CI shared lib - Part I: Implement patchset validation for shared libraries](https://eteamproject.internal.ericsson.com/browse/EEAEPP-40739)
* [EEAEPP-44191 - Implement CI shared lib - Part II: Implement functional validation for shared libraries](https://eteamproject.internal.ericsson.com/browse/EEAEPP-44191)
* [EEAEPP-73961 - Implement CI shared lib - Part III: Implement logic to publish shared library changes to CI code](https://eteamproject.internal.ericsson.com/browse/EEAEPP-73961)
* [EEAEPP-73962 - Implement CI shared lib - Part IV: Implement unit testing for shared library](https://eteamproject.internal.ericsson.com/browse/EEAEPP-73962)
* [EEAEPP-44190 - Implement CI shared lib - Part V: Collecting Code Coverage for shared libraries](https://eteamproject.internal.ericsson.com/browse/EEAEPP-44190)
* [EEAEPP-44192 - Implement CI shared lib - Part VI: Check/set gerrit permission to enable committing into shared library repo](https://eteamproject.internal.ericsson.com/browse/EEAEPP-44192)
* [EEAEPP-44193 - Implement CI shared lib - Part VII: Guide for developers how to implement new functions in the shared library](https://eteamproject.internal.ericsson.com/browse/EEAEPP-44193)

## Useful links:

* EEA4 Product CI Shared Library page: [https://eteamspace.internal.ericsson.com/display/ECISE/The+Library+-+EEA4](https://eteamspace.internal.ericsson.com/display/ECISE/The+Library+-+EEA4)

### Shared Library documentations

* [https://www.jenkins.io/doc/book/pipeline/shared-libraries/](https://www.jenkins.io/doc/book/pipeline/shared-libraries/)
* [https://www.codurance.com/publications/2019/05/25/private-jenkins-shared-libraries](https://www.codurance.com/publications/2019/05/25/private-jenkins-shared-libraries)
* [https://dustinoprea.com/2018/07/25/jenkins-how-to-verify-gerrit-crs-to-your-jenkins-pipeline-shared-libraries/](https://dustinoprea.com/2018/07/25/jenkins-how-to-verify-gerrit-crs-to-your-jenkins-pipeline-shared-libraries/)
* [https://github.com/jenkinsci/JenkinsPipelineUnit#testing-shared-libraries](https://github.com/jenkinsci/JenkinsPipelineUnit#testing-shared-libraries)
* [https://devopscube.com/create-jenkins-shared-library/](https://devopscube.com/create-jenkins-shared-library/)
* [https://tomd.xyz/articles/jenkins-shared-library/](https://tomd.xyz/articles/jenkins-shared-library/)
* [https://www.cloudbees.com/blog/top-10-best-practices-jenkins-pipeline-plugin](https://www.cloudbees.com/blog/top-10-best-practices-jenkins-pipeline-plugin)
* [https://wiki.jenkins.io/display/JENKINS/Pipeline+Shared+Groovy+Libraries+Plugin](https://wiki.jenkins.io/display/JENKINS/Pipeline+Shared+Groovy+Libraries+Plugin)
* [https://stackoverflow.com/questions/41742237/working-with-versions-on-jenkins-pipeline-shared-libraries](https://stackoverflow.com/questions/41742237/working-with-versions-on-jenkins-pipeline-shared-libraries)

### Pipeline Testing

* My Jenkins Shared Library Series
  * [What Are Jenkins Shared Libraries](https://itnext.io/jenkins-shared-libraries-part-1-5ba3d072536a)
  * [How To Build Your Own Jenkins Shared Library](https://itnext.io/how-to-build-your-own-jenkins-shared-library-9dc129db260c)
  * [Unit Testing a Jenkins Shared Library](https://itnext.io/unit-testing-a-jenkins-shared-library-9bfb6b599748)
  * [Collecting Code Coverage for a Jenkins Shared Library](https://itnext.io/collecting-code-coverage-for-a-jenkins-shared-library-c2d8f502732e)

### Developer test environment install

* [http://groovy-lang.org/install.html](http://groovy-lang.org/install.html))
* [https://maven.apache.org/install.html](https://maven.apache.org/install.html))
* [https://gradle.org/install](https://gradle.org/install))
* [https://www.jetbrains.com/help/idea/installation-guide.html](https://www.jetbrains.com/help/idea/installation-guide.html))

## Suggestions for the future tasks

* Code review process (automatic or manual) should check if functions are documented using [JavaDoc](https://en.wikipedia.org/wiki/Javadoc)
