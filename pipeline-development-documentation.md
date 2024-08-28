# Developing Product CI test jobs/pipelines

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## 1. Create your pipeline

All **production pipelines should be generated from jobDSL groovy** code to Jenkins.

**Manually created jobs can only be used for testing**, as they can be deleted anytime and manual modification in jobs will be overwritten automatically by any seed job run in Jenkins. All jobDSL script should have a corresponding Jenkinsfile as well.

Detailed information on [pipeline generation via seed jobs](https://eteamspace.internal.ericsson.com/display/ECISE/Generate+jobs+from+groovy+and+Jenkinsfile#GeneratejobsfromgroovyandJenkinsfile-Seedjobs)

More [information on jobDSL Jenkins plugin here](https://plugins.jenkins.io/job-dsl/).

There are currently **3 different options for creating a test pipeline** in the Product CI (see 1.a, 1.b and 1.c):

Test jobs has to be removed manually before you close your relevant JIRA ticket till automated cleanup is not implemented in the scope of [this ticket](https://eteamproject.internal.ericsson.com/browse/EEAEPP-90332).

### 1.a. Create a groovy DSL job in adp-app staging test directory

First, make sure that you **always clone the repositories with "Clone with commit-msg-hook"** option from gerrit. (You can get a link like this for the repository on the Gerrit GUI after clicking on "Clone with commit-msg hook" button.)

example:

```git clone https://efikgyo@gerrit.ericsson.se/a/EEA/adp-app-staging && (cd adp-app-staging && mkdir -p .git/hooks && curl -Lo `git rev-parse --git-dir`/hooks/commit-msg https://efikgyo@gerrit.ericsson.se/tools/hooks/commit-msg; chmod +x `git rev-parse --git-dir`/hooks/commit-msg)```

The recommended (and cleanest) way to develop and test a pipeline is to store it in SCM (git/gerrit): this way you benefit from source control, - and unlike with manually created jobs - your pipelines won't be deleted until you remove your jobDSL script from SCM.

#### **Conventions**:

To generate a pipeline with this method, you should create a commit to adp-app-staging repository with both Your **jobDSL groovy test script** and your **Jenkinsfile** defining your pipeline:

* Your **jobDSL groovy test script** should be placed under the `tests` directory. This will cause the test_seed job (located in the `technicals` directory) to generate your pipeline from the Jenkinsfile that your groovy file refers to)
  * your groovy file name should be prefixed with `test_<your_signum>`, eg.: `test_eholtam_csar_build.groovy`
  * your groovy file name should contain underscores (`_`) (no hyphens)!
  * the pipeline name - must be provided in the `pipelineJob()` row in the groovy file - should contain hyphens (`-`), not underscores!
  * the pipeline name in your groovy file should be prefixed with `test-<your-signum>-...`, eg.: `test-eholtam-csar-build`
  * Instead of hardcoding the gerrit url in the `url` section, please use our Jenkins global variable `${GERRIT_HOST}`
  * For testing, `branch` and `refspec` sections can be used like in the example. The string in the `refspec` section points to the exact refspec you want to use. (In production groovy files refspec mustn't be used, and branch should point to `${MAIN_BRANCH}`)
  * Make sure that you never send your test groovy file to review. JobDSL groovy files **must not be merged** to master!
  * Our groovy job definitions always have a DRY_RUN parameter. This parameter is used to rebuild a seeded job (without running its full logic) in case of change in parameters.

Example `test_signum_<example_name>.groovy` groovy file in the `test` directory:

```
pipelineJob('test-signum-<example name>') {
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
                        scriptPath('pipelines/app_staging/<example name>.Jenkinsfile')
                        refspec 'refs/changes/<35/7172735/11>'
                    }
                    branch('FETCH_HEAD')
                }
            }
        }
    }
}
```

* Your **Jenkinsfile** defining your pipeline
  * should be placed under `the adp-app-staging/pipelines/[appropriate folder]` (the final place where your job is intended to be)
  * for the Jenkinsfile filename you can use the final name, that will be used in production (since it wont override the production pipeline until your commit is merged)
  * your Jenkinsfile filename should contain underscores (`_`) (no hyphens)!
  * Please avoid hardcoding the gerrit url in the in your Jenkinsfiles, instead use our Jenkins global variable ${GERRIT_HOST}

Example Jenkinsfile:

```
@Library('ci_shared_library_eea4') _
pipeline {
    agent{
        node {
            label '<test-node>'
        }
    }
    options{
        skipDefaultCheckout()
    }
    parameters {
        string(name: 'GERRIT_REFSPEC',  description: 'Gerrit Refspect of the integration chart git repo e.g.: refs/changes/<87/4641487/1>', defaultValue: '<refs/changes/35/7172735/11>')
    }
    // use it only when it's accepted by the team, otherwise don't use triggers in job, only manual trigger
    // triggers {
    //     gerrit (
    //         serverName: 'GerritCentral',
    //         gerritProjects: [[
    //             compareType: 'PLAIN',
    //             pattern: 'EEA/adp-app-staging',
    //             branches: [[ compareType: 'PLAIN', pattern: 'master' ]],
    //             filePaths: [[ compareType: 'ANT', pattern: '<directory to trigger if needed>/**' ]],
    //             disableStrictForbiddenFileVerification: false,
    //             topics: [[ compareType: 'REG_EXP', pattern: '^((?!^inca$).)*$' ]]
    //         ]],
    //         triggerOnEvents:  [
    //             [
    //                 $class              : '<event which should trigger your job>',
    //                 excludeDrafts       : true,
    //                 excludeTrivialRebase: false,
    //                 excludeNoCodeChange : false
    //             ]
    //         ]
    //     )
    // }
    // you should run this before triggering your job manually to have every parameter available in your pipeline
    stages {
        stage('Params DryRun check') {
            when {
                expression { params.DRY_RUN == true }
            }
            steps {
                script {
                    dryRun()
                }
            }
        }
        // this is the stage where your patchset is cloned
        stage('Checkout'){
            steps{
                checkout([$class: 'GitSCM',
                    branches: [[name: "FETCH_HEAD"]],
                    doGenerateSubmoduleConfigurations: false,
                    userRemoteConfigs: [[
                        refspec:  "${GERRIT_REFSPEC}",
                        url: "https://eceagit@${GERRIT_HOST}/a/EEA/adp-app-staging",
                        credentialsId: 'git-functional-http-user'
                        ]
                    ]
                ])
            }
        }
        // your custom stage(s) to test your stuff
        stage('Test') {
            steps {
                // you can use your scripts from your patchset if you set up the gerrit refspec
                sh 'code'
            }
        }
    }
    post {
        cleanup {
            cleanWs()
        }
    }
}
```

### 1.b. Clone an already existing pipeline manually on Jenkins GUI

**Warning**: Pipelines created this way may be deleted any time.

* Log in to [Jenkins gui](https://seliius27190.seli.gic.ericsson.se:8443)
* On the top of the left menu choose "**New Item**"
* Enter a pipeline name
  * the pipeline name - should contain hyphens (`-`), not underscores!
  * the pipeline name should be prefixed with `test-<your-signum>-...`, eg.: `test-eholtam-csar-build`
* Scroll down to the bottom of the page to "**Copy from**" section
* Start writing the name of the pipeline you want to copy, when found, select it
* make sure to **leave unselected** the "Add to current view" checkbox
* Click **OK**

**Important!** If the original job contains triggers, other job executions, cluster cleanups, make sure to remove them!

### 1.c. Create a pipeline manually and using Pipeline script written in the job config

**Warning**: Pipelines created this way may be deleted any time.

* Log in to [Jenkins gui](https://seliius27190.seli.gic.ericsson.se:8443)
* On the top of the left menu choose "**New Item**"
* Enter a pipeline name
  * the pipeline name - should contain hyphens (`-`), not underscores!
  * the pipeline name should be prefixed with `test-<your-signum>-...`, eg.: `test-eholtam-csar-build`
* choose **Pipeline** as Item type
* make sure to **leave unselected** the "Add to current view" checkbox
* Click **OK**

On the next screen you can configure your job.

* Either scroll down or use the navigator tabs at the top to get to **Pipeline** section
* In the Definition dropdown select "**Pipeline Script**"
* Here you can copy a pipeline script code from your text editor.

## 2. Develop your pipeline

Here are some **important parameters, options and steps** we use often in our pipelines:

### Node, label

In ProductCI mostly 'productci' label is used, except for some technical jobs (that need to be run at the master jenkins node, for example).

```
pipeline {
    options {
        disableConcurrentBuilds()
    }
    agent {
        node {
            label 'productci'
        }
    }
```

### DRY_RUN parameter and DryRun check stage

Our pipelines utilize a DRY_RUN parameter which is specified in the groovy file of the job.
If the project parameters or properties change in a seeded job's Jenkinsfile as you go, you need to run the job with DRY_RUN = true in order to update project properties (in case you use jobDSL groovy file, this DRY_RUN happens automatically each time you update your groovy file in the tests directory).

The DRY_RUN parameter is used in a mandatory step in our pipelines like this:

dryRun() is defined in [the CI Shared Libraries](https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master/vars/dryRun.groovy). Running the job with `DRY_RUN=true` causes the job to interrupt before running the full job logic.

```
stages {
    stage('Params DryRun check') {
        when {
            expression { params.DRY_RUN == true }
        }
        steps {
            script {
                dryRun()
            }
        }
    }
(...)
```

### buildDiscarder option

[buildDiscarder](https://www.jenkins.io/doc/book/pipeline/syntax/) option can be used to specify how long we keep some build artifacts and console output before they got deleted.

example:

```
pipeline {
    options {
        buildDiscarder(logRotator(daysToKeepStr: '7', artifactNumToKeepStr: '7'))
    }
(...)
```

### skipDefaultCheckout() option

[skipDefaultCheckout](https://www.jenkins.io/doc/book/pipeline/syntax/) can be used to skip the automatic checking out of the pipeline code from SCM to the workspace, as defaultCheckout has some drawbacks,

* you cant specify the ref for this checkout
* this default checkout won't automatically download submodules (bob)
* this default checkout checks out to a location other than the $WORKSPACE

therefore it should be avoided.

example usage:

```
pipeline {
    options {
        skipDefaultCheckout()
    }
```

### disableConcurrentBuilds

Disallow concurrent executions of the same pipeline. Can be useful for preventing simultaneous accesses to shared resources.

example:

```
pipeline {
    options {
        disableConcurrentBuilds()
    }
```

### Jenkins Workspace

Workspace are directories **specific to the particular pipeline**, where work can be done on files or checked out from source control. Workspace can be referenced with $WORKSPACE global variable.
This workspace is reused for each successive build, so there is only ever one workspace directory per project!

Note: On the physical file system workspaces are located in a temporal workspace folder in the directory {JENKINS_HOME}/workspace/{JOBNAME}

### Archiving artifacts

Build artifacts are normally kept for a build as long as the build log itself is kept.

Build artifacts can be archived, so that they can be downloaded later. Archived artifacts will be accessible from the Jenkins webpage.

* You can use wildcards with archiveArtifacts, like below.
* Normally, a build fails if archiving returns zero artifacts. archiveArtifacts option allows the archiving process to return nothing without failing the build.

```
archiveArtifacts artifacts: '**/*.txt',
                   allowEmptyArchive: true,
                   fingerprint: true
```

### Using CI Global shared library

Our most commonly used helpers (like gerrit/git methods, utf-testing, etc) are organized into a global shared library, which is globally accessible across the whole Jenkins instance, which means these helpers can be imported to any pipeline.

* More info on the CI Shared library [here.](https://eteamspace.internal.ericsson.com/display/ECISE/%5BStudy%5D+EEA4+Workflow+for+Product+CI+Shared+Library+implementation)
* CI Shared library [repository](https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master/)

**Make sure to use shared library methods whenever possible** instead of hardcoding the same functionality multiple times.

example for importing shared library and instantiating one of its classes (`GitScm`) at the top of a Jenkinsfile:

```
@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
import groovy.transform.Field

@Field def git = new GitScm(this, 'EEA/adp-app-staging')

pipeline {
    agent {
(...)
```

#### Using a specific refspec of shared libraries

**For testing purposes** you can use a specific refspec of the shared library code in your pipeline: you just change the @Library annotation in the top line. For example, for testing the change with REFSPEC refs/changes/31/12200931/4:

```
// Using REFSPEC (without refs/ prefix) specified after @ sign
@Library('ci_shared_library_eea4@changes/31/12200931/4') _
```

This works because we added Discover other refs: changes/* behavior to 'ci_shared_library_eea4' under Manage Jenkins » Configure System » Global Pipeline Libraries.
Alternative deprecated way was to create a separate library with Legacy SCM configuration and specify the refspec in it. Unfortunately we cannot use dynamic library loading easily because we have to use complex classes (from src/), not only global variables/functions (from the vars/ directory).

### Repository checkout, using extra files

If your commit has some extra files (script, config, etc..) above the pipeline code, your pipeline should checkout your commit to the workspace, so you can use your extra files during testing.
This can be achieved like this with the CI Shared Library `GitScm object`:

First, you instantiate GitScm at the beginning of your file:

```
@Library('ci_shared_library_eea4') _

import com.ericsson.eea4.ci.GitScm
@Field def gitcnint = new GitScm(this, 'EEA/cnint')
```

if you need the whole commit from master branch:

```
stage('Checkout - cnint') {
    steps {
        script {
            gitcnint.checkout('master', 'cnint')
        }
    }
}

```

Where first parameter is the branch to check out, second is the name of the directory where we check out the repository.

If you need the whole commit from a refspec:

```
stage('Checkout - cnint') {
    steps {
        script {
            gitcnint.checkoutRefSpec("${GERRIT_REFSPEC}", "FETCH_HEAD", 'cnint')
        }
    }
}
```

And this way if you need only a specific file (we use git archive) from master:

```
gitcnint.archiveFile('EEA/cnint', 'HEAD repositories.yaml.template')
```

This way if you need a specific file from a refspec:

```
gitcnint.archiveFile('EEA/cnint', "${REFSPEC} csar_exception_list")
```

### Note on using Publish HTML Plugin

It turned out that the Jenkins' publishHTML plugin takes every file and subfolder recursively from the specified reportDir, and the report generated contains many temp files from the pipeline execution, but not related to the actual report.
Therefore if you use this plugin it's advised to:

* generate every report into a separate sub-folder
* and/or use includes parameter to include only files that match a given pattern

```
pipeline {
    ...
    stages { ... }
    post {
        always {
           publishHTML (target: [
                allowMissing: false,
                alwaysLinkToLastBuild: false,
                includes: '**/*.html',
                keepAll: true,
                reportDir: ".bob",
                reportFiles: 'dependencies-report.html',
                reportName: "Dependencies report"
            ])
        }
    }
}
```

### Cleanup

At the end of our pipelines there we use a declarative cleanup post step.
This is to ensure cleaning up the workspace after each build (since a workspace is shared between builds of the same job, its always a good idea to clean up older debris from your workspace).

For details see the [ws-cleanup plugin](https://plugins.jenkins.io/ws-cleanup/)

```
(...)
    post {
        cleanup {
            cleanWs()
        }
    }
```

## 3. Commit your changes and push to Gerrit

If you are done with developing your changes, commit and push your files to a gerrit refspec.

If you test with a seeded job (you use a groovy file), make sure to raise the value of your `refspec` field to the next version in your commit, so that your next pipeline execution uses your last version of the Jenkinsfile you commit.

```
pipelineJob('test-signum-<example name>') {
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
                        scriptPath('pipelines/app_staging/<example name>.Jenkinsfile')
                        refspec 'refs/changes/<35/7172735/11>'
                    }
                    branch('FETCH_HEAD')
                }
            }
        }
    }
}
```

*This case after pushing your new patch set, seed job will automatically run a DRY_RUN on your pipeline*.

Create the commit and push:

* The commit message should start with your `[CI][YOUR-TICKET-ID]` so that Jira can link your changes to your ticket
* Changes have to be pushed to `refs/for/<branchname>` so that Gerrit can register the change record. Details in [Gerrit docs](https://gerrit-review.googlesource.com/Documentation/user-upload.html#_git_push).

```
# stage your changes
git add .
git status
# commit & push
git commit -m "[CI][EEAEPP-11111] <rest of the commit msg>"
git push origin HEAD:refs/for/master
```

This will create a new "Change" in Gerrit, which represents a single commit under review. As you work on your ticket, you will want to make new changes. This case you have to amend your previous commit, and push it to gerrit again.

```
# stage
git add .
# Git `commit --amend` will open your text editor with the commit message
git commit --amend
# close it, and push new patchset
git push origin HEAD:refs/for/master
```

This will generate a new "patch set", which is the Gerrit-way to say "iterations of a commit".

## 4. Test your pipeline

### Validate Jenkinsfile syntax

Changed Jenkinsfiles can be validated through Command Line Pipeline Linter, that can be used via SSH. To use the linter, you should have your SSH public key configured in Jenkins (User menu > Configure > SSH Public Keys).

First, you should query the jenkins server on http to get the random port for the SSH CLI:

```
curl -insecure -Lv https://seliius27190.seli.gic.ericsson.se:8443/ 2>&1 | grep -i 'x-ssh-endpoint'

    # response
    # X-SSH-Endpoint: seliius27190.seli.gic.ericsson.se:38239
    # < X-SSH-Endpoint: seliius27190.seli.gic.ericsson.se:38239
```

Then you can run the validation (this command redirects your local Jenkinsfile content to the Jenkins server via SSH and prints its result)

```
ssh -l efikgyo -p 38239 seliius27190.seli.gic.ericsson.se -insecure declarative-linter < test_efikgyo_test_guide_pipeline.Jenkinsfile

    Errors encountered validating Jenkinsfile:
    WorkflowScript: 191: unexpected token: } @ line 191, column 1.
       }
       ^

```

### Build Now (Build with parameters)

If you pushed your last changes to gerrit, you can run Build with parameters to run the pipeline with your latest changes.

If you have updated not only your Jenkinsfile but your groovy file as well with to the next patchset in the refspec field, seed job automatically did a DRY_RUN for you and you can start to run a build of your latest changes with selecting left menu > Build with parameters (menuitem is seen as Build Now if there are no parameters).

### Using Replay

If you don't want commit/amend every time you want to try out some minor changes on your pipeline, you can use **Replay** option. This option allows you to quickly modify and test your changes.

* To use this feature select a previously completed build from the Build History.
* On the builds page, at the end of the left menu you can find and select "Replay"
* Here at the **Main Script** window you can make your changes to the previously run pipeline code
* **Run** the pipeline with your changes
* If you are satisfied with the results, you use Replay to view your changes again and copy them back to your text editor and commit the changes.

**Note**: Please note, that Replay and Rebuild are 2 completely different functionality. Rebuild plugin can be used to rebuild a parameterized build without entering the parameters again, or to edit the parameters.

### General testing guidelines

* While testing during the development phase, make sure to first test your changes only, try to avoid running the whole pipeline every time, especially if the pipeline has some expensive steps
* During the development phase always try to think over what steps are necessary to run in your tests, what steps shouldn't run (eg.: uploading, publishing, git commiting, starting other long running jobs, sending e-mails, etc.) to avoid expensive steps and unnecessary resource locking
* **When you want to send your changes to review, you should always present a test run** to prove your changes are working.
* Your last test that you present with your review request can be a full run if it's necessary.
* Make sure that if you added a test groovy file to the `tests` directory, remove that from the final commit you send to review! **No test job DSL code should be merged to the master branch**!

## 6. Validation

When you push your commit, a non-functional automatic validation jobs start.
If these validations succeed, the patch set gets a +1 vote in Gerrit. (If the validations fail, a -1 is given. This case you should investigate what caused the failure: you can click on the failed job under your commit to see details. When you found the problem, you have to upload a new, fixed patch set or try rebasing the current one if it was an environment issue.). **You should always wait for Verified +1 before sending your changes to review**

Validation jobs and their triggers in details are listed here: [Validation of CI environment changes](https://eteamspace.internal.ericsson.com/display/ECISE/Validation+of+CI+environment+changes).

## 7. Send it to review

When you finished your development and you have a successful test job, you can send your change to the [review channel](https://teams.microsoft.com/l/channel/19%3a3910c0c538c344528181bbce8c3e9698%40thread.tacv2/Review%2520requests?groupId=bc9ea19b-97da-479d-903f-9b003bcba6a4&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f) for manual review.

In the review request include your **gerrit change ID** and your **test job**, like this:

```
Please review:
https://gerrit.ericsson.se/#/c/13553516/
Test job: https://seliius27190.seli.gic.ericsson.se:8443/job/test-efikgyo-docker-image-versions-autouplift-weekly-loop/157/
```

During the review team members can make suggestions, and if they find everything OK, you are granted with a **CR +1** (Code Review +1).
After the **CR +1 a functional validation starts** automatically.

Validation jobs and their triggers in details are listed here: [Validation of CI environment changes](https://eteamspace.internal.ericsson.com/display/ECISE/Validation+of+CI+environment+changes).

* If this last validation succeeds, the code will be merged into the master automatically.
* If this last validation fails (due to the the developer's fault), the commit can't be merged, and the developer has to fix the code in a new patch set.
* If this last validation fails for reasons other than the developer's fault (eg: environment issues), the developer has to **restart the validation job from Spinnaker** as soon as the issue is resolved (instead of asking for a +1 again!)

**Important:** It is always the developer's responsibility to monitor the current state of their commit until it's merged!

## 8. Troubleshooting

### Handling "Method too large" issues

When running a large Jenkins pipeline script, it can give the error:

```
org.codehaus.groovy.control.MultipleCompilationErrorsException: startup failed: General error during class generation: Method code too large!
java.lang.RuntimeException: Method code too large!
```

This is due to a limit between Java and Groovy, requiring that method bytecode be no larger than 64kb. It is not due to the Jenkins Pipeline DSL.
To solve this, instead of using a single monolithic pipeline script, break it up into methods and call the methods.

You can use the following WAs:

* Implement reusable functions in the ci_shared_library.**Recommended** for those functions, which are implemented properly in the shared library(check ci_shared_library documentation linked earlier for how to develop there), and can be reused in other pipelines.
* For a faster and not reusable solution, code parts can be extracted from the pipeline body, and created as a function in the jenkinsfile, but out of the body.**Recommended** for those functions, that we don't plan to reuse elsewhere.
* Creating a script, and use the script, instead of writing the code in the jenkinsfile. **Not recommended**, this would make the codebase a mess.

e.g. for a faster and not reusable solution, instead of having:

```
pipeline {
    stages {
        ...
        stage('Set description (SpinnakerURL and versions)') {
            steps {
                script {
                    if (params.SPINNAKER_ID) {
                        currentBuild.description += '<br><a href="https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/details/' + params.SPINNAKER_ID + '">Spinnaker URL: ' + params.SPINNAKER_ID + '</a>'
                    }
                    if (params.CHART_NAME && params.CHART_VERSION) {
                        currentBuild.description += '<br>' + params.CHART_NAME + ':' + params.CHART_VERSION
                    }
                    currentBuild.description += '<br>' + "Installed meta version: ${env.INT_CHART_VERSION_META}"
                    currentBuild.description += '<br>' + "Installed version: ${env.BASELINE_INT_CHART_VERSION}"
                    currentBuild.description += '<br>' + "Upgraded version: ${env.INT_CHART_VERSION_PRODUCT}"
                }
            }
        }
        ...
    }
}
```

Instead you should organize and move logic into sub functions outside pipeline codes:

```
pipeline {
    stages {
    ...
    stage('Set description (SpinnakerURL and versions)') {
        steps {
            setDescription(k8s_master, watch_counts_log)
        }
    }
    ...
}

void setDescription(k8s_master, watch_counts_log) {
    script {
        if (params.SPINNAKER_ID) {
            currentBuild.description += '<br><a href="https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/details/' + params.SPINNAKER_ID + '">Spinnaker URL: ' + params.SPINNAKER_ID + '</a>'
        }
        if (params.CHART_NAME && params.CHART_VERSION) {
            currentBuild.description += '<br>' + params.CHART_NAME + ':' + params.CHART_VERSION
        }
        currentBuild.description += '<br>' + "Installed meta version: ${env.INT_CHART_VERSION_META}"
        currentBuild.description += '<br>' + "Installed version: ${env.BASELINE_INT_CHART_VERSION}"
        currentBuild.description += '<br>' + "Upgraded version: ${env.INT_CHART_VERSION_PRODUCT}"
    }
}
```

According to other solutions described [here](https://issues.jenkins.io/browse/JENKINS-56500), setting 'RuntimeASTTransformer' parameters did not work in our environment, BUT may cause other problems so their use is **Not recommended**.

## **Related documents**:

* [Pipeline guideline](https://eteamspace.internal.ericsson.com/display/ECISE/Pipeline+guideline)
* [Generate jobs from groovy and Jenkinsfile](https://eteamspace.internal.ericsson.com/display/ECISE/Generate+jobs+from+groovy+and+Jenkinsfile#GeneratejobsfromgroovyandJenkinsfile-Seedjobs)
