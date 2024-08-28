# CDD in Product CI

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## EEA cdd code change validation workflow

The source code stored in the [EEA/cdd](https://gerrit.ericsson.se/#/admin/projects/EEA/cdd) gerrit repo.
This section describe the code change validation process in case of manual changes in the repo.

[ruleset file](https://gerrit.ericsson.se/plugins/gitiles/EEA/cdd/+/master/bob-rulesets/ruleset2.0.yaml)

### EEA cdd validation workflow

+ New patchset uploaded to cdd directory
+ Pre validation Jenkins job ([eea-cdd-manual-flow-precodereview](#eea-cdd-manual-flow-precodereview-jenkins-job)) is triggered which runs Jenkins patchset hooks and generates XMLs if `jenkins/` directory content is changed
  + If validation is successful verification +1 vote given for the patchset in Gerrit
  + If validation fails verification -1 vote given for the patchset in Gerrit
    + This case you should investigate what caused the failure: you can click on the failed job under your commit to see details. When you found the problem, you have to upload a new, fixed patchset or try rebasing the current one if it was an environment issue.
+ Manual code review from the team
  + During the review team members can make suggestions, and if they find everything OK, you are granted with a **CR +1** (Code Review +1).
  + **Reviewer should always wait for Verified +1 before adding Code Review +1**
+ Post validation Jenkins job ([eea-cdd-manual-flow-verify-cr](#eea-cdd-manual-flow-verify-cr-jenkins-job)) is triggered automatically when CR+1 is given for the commit

## eea-cdd-manual-flow-precodereview Jenkins job

This job runs Jenkins patchset hooks and generates XMLs if `jenkins/` directory content is changed

Jenkins job: [eea-cdd-manual-flow-precodereview](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-cdd-manual-flow-precodereview/)

### Input parameters

+ GERRIT_REFSPEC

### Stages

+ Params DryRun check
+ Checkout - cdd
+ Prepare
+ Clean
+ Jenkins patchset hooks
+ Check if jenkins/* changed
  + This stage will check if the `jenkins/` directory content is changes. If yes, it will set `env.GENERATE_XML = true`
+ Generate XMLs
  + If `env.GENERATE_XML = true` the stage will run [eea-jenkins-docker-xml-generator](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-jenkins-docker-xml-generator/) to verify, that XML can be generated from updated groovy/Jenkinsfile
+ Post-stages
  + cleanup
    + cleanWs()

## eea-cdd-manual-flow-verify-cr Jenkins job

This job is responisble for the EEA cdd review process.

Deciding whether a change in the cdd repository can be added to the queue and merged is determined by the [eea-cdd-manual-flow-verify-cr](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-cdd-manual-flow-verify-cr/) Jenknis job based on the config in the repository's root directory

The review config for the EEA/cdd repository is available in the cdd repository [https://gerrit.ericsson.se/plugins/gitiles/EEA/cdd/+/master/cdd_reviewers.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/cdd/+/master/cdd_reviewers.yaml) and is managed by the Product CI team

The review process is the same as described [here](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/documentation/cnintReviewProcess.md)

## eea-cdd-manual-flow-codereview-ok Jenkins job

This job can be triggerded by eea-cdd-manual-flow-verify-cr Jenkins when all checks were successful and the build triggered by a member of the Product CI team.
This job prepares and creates the helm chart package but doesn't upload it to the ARM. If the job finished with success it will execute [eea-cdd-drop](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-cdd-drop) Spinnaker pipeline.

 Jenkins job: [eea-cdd-manual-flow-codereview-ok](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-cdd-manual-flow-codereview-ok/)

### Input parameters

+ GERRIT_REFSPEC
+ GERRIT_CHANGE_ID
+ GERRIT_CHANGE_SUBJECT
+ GERRIT_CHANGE_OWNER_NAME

### Stages

+ Params DryRun check
+ Gerrit message
+ Checkout - scripts
+ Rebase
+ Set LATEST_GERRIT_REFSPEC
  + get and set the latest patchset for the input GERRIT_REFSPEC
+ Checkout LATEST_GERRIT_REFSPEC
  + if there is a newer patchset then the input GERRIT_REFSPEC, we have to checkout and use the latest one
+ Prepare
+ Clean
+ Prepare Helm Chart
  + execute `prepare-without-upload` rule from the ruleset file and doesn't upload chart to the ARM
+ set properties by changed files
+ Archive artifact.properties

#### Stage "Set properties by changed files"

In the cdd drop pipeline different test runs for different Jenkinsfile or groovy changes on path : "jenkins/". [eea-cdd-drop](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-cdd-drop)
The mapping for this logic stored in ccdTestLoopMap, filename as key and the parameter name as value.

```
ccdTestLoopMap = ['eea_software_ingestion':'INGESTION','eea_software_preparation':'PREPARATION','eea_software_upgrade':'UPGRADE','eea_software_validation_and_verification':'VALIDATION','eea_software_rollback':'ROLLBACK'  ]
```

The mapping result will be added to the artifact.properties file
e.g:

```
INGESTION=true
```

## eea-cdd-manual-flow-prepare Jenkins job

This job can be triggered by [eea-cdd-drop](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-cdd-drop) Spinnaker pipeline.
This job prepares and creates the helm chart package and uploads it to the ARM.

Jenkins job: [eea-cdd-manual-flow-prepare](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-cdd-manual-flow-prepare/)

### Input parameters

+ CHART_NAME
+ CHART_REPO
+ CHART_VERSION
+ GERRIT_REFSPEC
+ SPINNAKER_TRIGGER_URL
+ SPINNAKER_ID

### Stages

+ Params DryRun check
+ Gerrit message
+ Set build description
+ Wait for cdd-publish resource is free
+ Checkout - scripts
+ Rebase
+ Set LATEST_GERRIT_REFSPEC
  + get and set the latest patchset for the input GERRIT_REFSPEC
+ Checkout master
+ Fetch And Cherry Pick changes
+ Prepare
+ Clean
+ Prepare Helm Chart
  + execute `prepare` rule from the ruleset file and upload chart to the ARM
+ Archive artifact.properties

## eea-cdd-build-cdd-package Jenkins job

This job can be triggered by [eea-cdd-drop](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-cdd-drop) Spinnaker pipeline. It generates CDD package and uploads it to the [proj-eea-internal-generic-local](https://arm.seli.gic.ericsson.se/artifactory/proj-eea-internal-generic-local/) repo in the ARM

Jenkins job: [eea-cdd-build-cdd-package](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-cdd-build-cdd-package/)

### Input parameters

+ CHART_VERSION
+ TICKET_NUMBER
+ GERRIT_REFSPEC

### Stages

+ Params DryRun check
+ Gerrit message
+ Set build description
+ Checkout
+ EEA/cdd repo change checkout
+ Prepare structure
  + Creates directories to be in line with the CDD package structure
+ Generate pipeline_package
  + Executes [eea-jenkins-docker-xml-generator](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-jenkins-docker-xml-generator/) to generate Jenkins pipelines XML
+ Publish CDD pipeline package
+ Post-stages
  + Cleanup
    + cleanWs()

## eea-cdd-manual-flow-publish Jenkins job

This job can be triggered by [eea-cdd-drop](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-cdd-drop) Spinnaker pipeline. It generates CDD package and uploads it to the [proj-eea-internal-generic-local](https://arm.seli.gic.ericsson.se/artifactory/proj-eea-internal-generic-local/) repo in the ARM. This job publishes Gerrit change to the repo, publishes CDD package and Helm chart to the ARM.

### Input parameters

+ CHART_VERSION
+ GERRIT_REFSPEC
+ SPINNAKER_TRIGGER_URL
+ SPINNAKER_ID

### Stages

+ Params DryRun check
+ Gerrit message
+ Checkout
+ Ruleset change checkout
+ Prepare
+ Init
+ Resource locking - Publish Cdd Helm Chart
  + Publish CDD Helm Chart
+ Publish CDD pipeline package
+ Archive artifact.properties
+ Post-stages
  + always
    + Send notification to the Gerrit Refspec

## EEA cdd specific pipelines in Spinnaker

### eea-cdd-drop Spinnaker pipeline

#### Description

This Spinnaker pipeline is for triggering [EEA CDD Staging](#eea-cdd-drop-spinnaker-pipeline) pipeline in case of manual changes in the EEA/cdd Gerrit repo. Before triggering these patchsets are validated by:

+ [precodereivew job](#eea-cdd-manual-flow-precodereview-jenkins-job) which gives verified +1/-1 voted in Gerrit
+ [codereview-ok job](#eea-cdd-manual-flow-codereview-ok-jenkins-job) which rebases the commit and prepares prerequisites for eea cdd drop triggering.

Spinnaker pipeline:

+ [eea-cdd-drop](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-cdd-drop)
+ [configuration](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/configure/bf94292b-7ad0-420e-8dbd-6590e237e93d)

#### Input parameters

+ There is no parameter for this pipeline

#### Automated Triggers

+ Triggered by the [eea-cdd-manual-flow-codereview-ok](#eea-cdd-manual-flow-codereview-ok-jenkins-job) job from Jenkins. artifact.properties file loaded as incoming parameter from this job's artifacts

#### Stages

+ Prepare, stage type: Jenkins, job: [eea-cdd-manual-flow-prepare](#eea-cdd-manual-flow-prepare-jenkins-job), wait for result: true
  + this will create and upload helm chart to the ARM
+ Build CDD package, stage type: Jenkins, job: [eea-cdd-build-cdd-package](#eea-cdd-build-cdd-package-jenkins-job), wait for result: true
  + this will create and upload CDD package to the ARM
+ Online install
  + TODO: the stage is currently an empty wait in Spinnaker until the unified install epic
+ Offline install
  + TODO: the stage is currently an empty wait in Spinnaker until the unified install epic
+ Online upgrade
  + Triggering the eea-common-product-upgrade pipeline with the latest integration helm chart version (INT_CHART_VERSION_PRODUCT), using the GERRIT_REFSPEC (CDD_GERRIT_REFSPEC) to test the current changes
  + Online upgrade runs when any of the following pipelines change : Ingestion, Preparation, Upgrade, Validation
+ Offline upgrade
  + Triggering the eea-common-product-upgrade pipeline with the latest csar version (CSAR_VERSION), using the GERRIT_REFSPEC (CDD_GERRIT_REFSPEC) to test the current changes
  + Offline upgrade runs when any of the following pipelines change : Preparation, Upgrade, Validation and when the Common Upgrade script changes

## EEA product version check in upgrade.sh

Based on the requirements of [EEAEPP-90598](https://eteamproject.internal.ericsson.com/browse/EEAEPP-90598) ticket,
upgrade.sh fails if the CSAR package version does not match the version in the script itself.
We need this functionality because the users should use both CDD package and CSAR package from the same EEA release, different versions won't match and can cause upgrade failures.
For this, it was absolutely necessary to ensure that the release process always keeps the version in the upgrade.sh script in sync with the product version.

To ignore this version check for certain reason we have introduced a cli option to the upgrade.sh:

```
Upgrade Process Options:
  --ignore-product-version-check              Ignore product version check (Default value: FALSE)
```
