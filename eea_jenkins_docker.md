# EEA Jenkins Docker in Product CI

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## EEA Jenkins Docker code change validation workflow

### Description

The general purpose of this docker project is to unify install and upgrade process in EEA from Product CI till the customer site (the Docker image itself won't be delivered to the customers).

The source code stored in the [jenkins-docker](https://gerrit.ericsson.se/#/admin/projects/EEA/jenkins-docker) gerrit repo.
This section describe the code change validation process in case of manual changes in the repo.

[ruleset file](https://gerrit.ericsson.se/plugins/gitiles/EEA/jenkins-docker/+/master/bob-rulesets/ruleset2.0.yaml)

### EEA/jenkins-docker validation Workflow

+ New patchset uploaded to jenkins-docker directory
+ Pre validation Jenkins job ([eea-jenkins-docker-manual-flow-precodereview](#eea-jenkins-docker-manual-flow-precodereview-jenkins-job)) is triggered which build and test the docker image
  + If validation is successful verification +1 vote given for the patchset in Gerrit
  + If validation fails verification -1 vote given for the patchset in Gerrit
    + This case you should investigate what caused the failure: you can click on the failed job under your commit to see details. When you found the problem, you have to upload a new, fixed patchset or try rebasing the current one if it was an environment issue.).
+ Manual code review from the team
  + During the review team members can make suggestions, and if they find everything OK, you are granted with a **CR +1** (Code Review +1).
  + **Reviewer should always wait for Verified +1 before adding Code Review +1**
+ Post validation Jenkins job ([eea-jenkins-docker-manual-flow-codereview-ok](#eea-jenkins-docker-manual-flow-codereview-ok-jenkins-job)) is triggered automatically when CR+1 is given for the commit
  + This will rebase the commit and execute the same validations as the precodereview job.
  + If validation passes the [eric-eea-jenkins-docker-drop Spinnaker pipeline](#eea-jenkins-docker-drop-spinnaker-pipeline) will be triggered automatically.
  + If validation fails the commit can't be merged by the developer, the commit has to be fixed in a new patchset.
+ [eric-eea-jenkins-docker-drop Spinnaker pipeline](#eea-jenkins-docker-drop-spinnaker-pipeline) will be triggered when codereview-ok Jenkins job finished with SUCCESS.
  + This will read the artifact.properties file generated by the Jenkins job and forward it's values as input parameres for the Prepare jenkins-docker stage
+ Prepare jenkins-docker stage will be executed to build docker image and helm chart, and push them to the internal arm repo
+ Prepare meta stage will be executed to build meta helm chart with the internal jenkins-docker version to test new version with the upgrade job
+ Test upgrade stage will be executed to make sure, that product upgrade can be executed with the new jenkins-docker verion
+ Publish stage will be executed to publish jenkins-docker to the repo master, build and upload docker image and jenkins-docker helm chart
+ eea-metabaseline-jenkins-docker-version-change Spinnaker pipeline will be executed to publish new jenkins-docker version to the meta chart

## eea-jenkins-docker-manual-flow-precodereview Jenkins job

This job builds the docker image, tests it then remove, when a commit is published to gerrit for review.

Jenkins job: [eea-jenkins-docker-manual-flow-precodereview](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-jenkins-docker-manual-flow-precodereview/)

### Input parameters

+ GERRIT_REFSPEC

### Stages

+ Params DryRun check
+ Checkout - jenkins-docker
+ Prepare
+ Clean
+ Init
+ build-docker-image
  + Build Dockerfile
  + this stage executes the bob rules 'build-docker-image' defined in the [ruleset file](https://gerrit.ericsson.se/plugins/gitiles/EEA/jenkins-docker/+/master/bob-rulesets/ruleset2.0.yaml)
+ build-docker-image
  + Test docker image: starts and tests the docker image built by the previous step
  + this stage executes the bob rule 'test-docker-image' defined in the [ruleset file](https://gerrit.ericsson.se/plugins/gitiles/EEA/jenkins-docker/+/master/bob-rulesets/ruleset2.0.yaml)
  + this starts and tests the docker image built by the previous step
+ cleanup-docker-image
  + Docker cleanup: removes the docker image
  + this stage executes the bob rule 'cleanup-docker-image' defined in the [ruleset file](https://gerrit.ericsson.se/plugins/gitiles/EEA/jenkins-docker/+/master/bob-rulesets/ruleset2.0.yaml)

## eea-jenkins-docker-manual-flow-codereview-ok Jenkins job

This job builds the docker image, tests it before triggering [eric-eea-jenkins-docker-drop Spinnaker pipeline](#eea-jenkins-docker-drop-spinnaker-pipeline), to make sure that the new docker image can be tested with the product upgrade job and published

Jenkins job: [eea-jenkins-docker-manual-flow-codereview-ok](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-jenkins-docker-manual-flow-codereview-ok/)

### Stages

+ Params DryRun check
+ Gerrit message
+ Check Reviewer
  + ckecks that the reviewer is in proper reviewer group or not
+ Checkout - scripts
+ Rebase
+ Set LATEST_GERRIT_REFSPEC
  + get and set the latest patchset for the input GERRIT_REFSPEC
+ Checkout LATEST_GERRIT_REFSPEC
  + if there is a newer patchset then the input GERRIT_REFSPEC, we have to checkout and use the latest one
+ Prepare
+ Clean
+ Init
+ Build Docker Image
+ Test Docker Image
+ Cleanup Docker image
+ Check skip-testing comment exist
+ Check which files changed to skip testing
  + if only *.md files are changed, the testing with the product upgrade will be skipped
+ Archive artifact.properties

## eea-jenkins-docker-manual-flow-prepare Jenkins job

This job builds the docker image, tests it, builds helm chart and publishing it to the internal repos

Jenkins job: [eea-jenkins-docker-manual-flow-prepare](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-jenkins-docker-manual-flow-prepare/)

### Parameters

+ GERRIT_REFSPEC
+ PIPELINE_NAME
+ SPINNAKER_TRIGGER_URL
+ SPINNAKER_ID

### Stages

+ Params DryRun check
+ Gerrit message
+ Set build description
+ Checkout - scripts
+ Rebase
+ Set LATEST_GERRIT_REFSPEC
  + get and set the latest patchset for the input GERRIT_REFSPEC
+ Checkout LATEST_GERRIT_REFSPEC
  + if there is a newer patchset then the input GERRIT_REFSPEC, we have to checkout and use the latest one
+ Prepare
+ Clean
+ Init
+ Build Docker Image
+ Test Docker Image
+ Publish Docker Image
+ Cleanup Docker image
+ Package Helm Chart
+ Publish Helm Chart
+ Archive artifact.properties

## eea-jenkins-docker-manual-flow-publish Jenkins job

This job builds the docker image, tests it, builds helm chart and publishing it to the drop repos

Jenkins job: [eea-jenkins-docker-manual-flow-publish](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-jenkins-docker-manual-flow-publish/)

### Parameters

+ GERRIT_REFSPEC
+ PIPELINE_NAME
+ SPINNAKER_TRIGGER_URL
+ SPINNAKER_ID

### Stages

+ Params DryRun check
+ Gerrit message
+ Set build description
+ Checkout jenkins-docker
+ Prepare
+ Clean
+ Init
+ Build Docker Image
+ Test Docker Image
+ Package Helm Chart
+ Submit & merge changes to master
+ Create Git Tag
+ Publish Docker Image
+ Cleanup Docker image
+ Publish Helm Chart
+ Archive artifact.properties

## EEA Jenkins Docker drop pipeline in Spinnaker

### eea-jenkins-docker-drop Spinnaker pipeline

#### Description

This Spinnaker pipeline is for triggering eea-product-ci-meta-baseline-loop pipeline in case of manual changes in the jenkins-docker Gerrit repo.

The helm chart of the jenkins-docker has been added to the [project-meta-baseline/eric-eea-ci-meta-helm-chart/Chart.yaml umbrella chart|<https://gerrit.ericsson.se/plugins/gitiles/EEA/project-meta-baseline/+/master/eric-eea-ci-meta-helm-chart/Chart.yaml#28>] and disabled in [project-meta-baseline/eric-eea-ci-meta-helm-chart/values.yaml|<https://gerrit.ericsson.se/plugins/gitiles/EEA/project-meta-baseline/+/master/eric-eea-ci-meta-helm-chart/values.yaml#24>] as it won't be installed on the clusters.

This pipeline executes a flow to prepare jenkins-docker helm chart and docker image, prepare meta chart, test it with the product upgrade and publish jenkins-docker changes to the master branch. After successful flow execution, the eea-metabaseline-jenkins-docker-version-change Spinnaker pipeline is triggered to upgrade the jenkins-docker version in the meta chart

Before triggering the eea-product-ci-meta-baseline-loop these patchsets are validated by:

+ [precodereivew job](#eea-jenkins-docker-manual-flow-precodereview-jenkins-job) which gives verified +1/-1 voted in Gerrit
+ [codereview-ok job](#eea-jenkins-docker-manual-flow-codereview-ok-jenkins-job) which rebases the commit and prepares prerequisites

Spinnaker pipeline:

+ [eea-jenkins-docker-drop](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?q=dash&pipeline=eea-jenkins-docker-drop)
+ [configuration](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/configure/2575e2ac-4083-41b5-82b5-0448ac1efa76)

#### Input parameters

+ There is no parameter for this pipeline

#### Automated Triggers

+ Triggered by the [eea-jenkins-docker-manual-flow-codereview-ok](#eea-jenkins-docker-manual-flow-codereview-ok-jenkins-job) job from Jenkins.

#### Stages

+ Prepare jenkins-docker
+ Prepare meta
+ Test upgrade
+ Publish

## eea-jenkins-docker-executor Jenkins job

This job starts jenkins-docker image on the Jenkins build node, imports Jenkins job to the docker containers and executes the imported job.

Jenkins job: [eea-jenkins-docker-executor](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-jenkins-docker-executor/)

### Input parameters

+ CSAR_NAME
+ CSAR_REPO
+ CSAR_VERSION
+ DOCKER_EXECUTOR_IMAGE_NAME
+ DOCKER_EXECUTOR_IMAGE_VERSION
+ CDD_PSP_URL
+ CDD_PSP_REPO
+ CDD_PSP_NAME
+ CDD_PSP_VERSION
+ CDD_GERRIT_REFSPEC
+ PIPELINE_NAME
+ SKIP_COLLECT_LOG
+ SKIP_CLEANUP
+ CUSTOM_CLUSTER_LABEL
+ CLUSTER_LABEL
+ CLUSTER_NAME

### Stages

+ Params DryRun check
+ Cluster params check
    > Only one of CLUSTER_LABEL or CLUSTER_NAME must be specified
+ Checkout jenkins-docker
+ Checkout adp-app-staging
+ Init variables
    > env.DOCKER_EXECUTOR_IMAGE_VERSION will get the params.DOCKER_EXECUTOR_IMAGE_VERSION value if the parameter is specified.
    > If params.DOCKER_EXECUTOR_IMAGE_VERSION is not specified, the env.DOCKER_EXECUTOR_IMAGE_VERSION will get the value from the project-meta-baseline:/eric-eea-ci-meta-helm-chart/Chart.yaml master branch
+ Get Jenkins jobs XML
    > If params.CDD_PSP_VERSION specified, then CDD_PSP_PACKAGE will be downloaded from arm and Jenkins jobs XML will be taken from the package
    > If params.CDD_GERRIT_REFSPEC specified, then Jenkins jobs XML will be generated using [eea-jenkins-docker-xml-generator](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-jenkins-docker-xml-generator/)
+ Get latest CSAR_VERSION
+ Download CSAR package
+ Resource locking
  + Wait for cluster
  + Lock
    + Log lock
    + Run DinD and Jenkins docker
            > Before running jenkins-docker, a free port on the build node will be determined. Checking for free ports starts at 8080, incrementing the port by 1 if the port is unavailable
            > After running jenkins-docker, a check will be launched that Jenkins inside the container is running
    + Get jenkins-cli.jar
            > jenkins-cli.jar is available at ${JENKINS_URL}/jnlpJars/jenkins-cli.jar on any Jenkins instance
    + Import Jenkins jobs
            > Imports specified Jenkins jobs into the jenkins-docker
    + Execute Software Ingestion
    + Post-Stages
            > Collect docker log from the jenkins-docker and save as a build artifact
            > Cleanup docker-related resources created in the previous steps
            > Prepare cluster for log collection
  + Post-Stages
        > Runs cluster-logcollector (if params.SKIP_COLLECT_LOG == false)
        > Runs cluster-cleanup (if params.SKIP_CLEANUP == false)
+ Post-Stages
    > Update build description with log collection folder
    > Upload artifacts to the log collection folder

## eea-jenkins-docker-version-uplift

This job checks the version difference between Live Jenkins and the contents of the EEA/jenkins-docker repository. If differences are found, a commit will be created to update the EEA/jenkins-docker repository

Jenkins job: [eea-jenkins-docker-version-uplift](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-jenkins-docker-version-uplift/)

### Input parameters

+ PLUGINS_TO_ADD

> In case a new plugin from Live Jenkins needs to be added to jenkins-docker, it can be selected here and added to the commit that will be created as a result of the build

### Stages

+ Params DryRun check
+ Checkout jenkins-docker
+ Prepare
+ Clean
+ Keep original versions

> Keeps original versions of jenkins-docker:docker/plugins.txt and jenkins-docker:bob-rulesets/ruleset2.0.yaml to check if versions were changed during the build process

+ Update Jenkins version

> Updates Jenkins version in bob-rulesets/ruleset2.0.yaml in case a difference was found with Live Jenkins

+ Update plugins versions

> Updates plugins versions in docker/plugins.txt in case a difference was found with Live Jenkins

+ Add new plugins

> Adds new plugins if they have been selected for the params.PLUGINS_TO_ADD

+ Check for difference

> Compares bob-rulesets/ruleset2.0.yaml docker/plugins.txt with their versions saved at the beginning of the build

+ Create Gerrit change

> If differences were found in the previous step, a new commit will be created with these changes

+ Post-Stages
  + Success
    > Send an email to the Driver Channel about the successful build and the created commit
  + Failure
    > Send an email to the Driver Channel about the failed build

## eea-jenkins-docker-xml-generator Jenkins job

This job generates Jenkins jobs in the XML format based on the jenkins/*.groovy files in the EEA/cdd repository.

Jenkins job: [eea-jenkins-docker-version-uplift](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-jenkins-docker-xml-generator/)

### Input parameters

+ GIT_BRANCH
+ GERRIT_REFSPEC

### Stages

+ Params DryRun check
+ Gerrit message
    > Send a build started notification to the GERRIT_REFSPEC
+ Checkout - EEA/adp-app-staging
    > Checkouts EEA/adp-app-staging master to use scripts in future steps
+ Checkout - EEA/cdd
    > Checkouts EEA/cdd GIT_BRANCH or GERRIT_REFSPEC to generate XML jobs base on the jenkins/*.groovy files
+ Generate xml
  + Get list of *.groovy files from cdd:jenkins/ directory
  + Generate XMLs using functions from `build.gradle`
  + Validate generated XMLs with the python script
  + Archive generated XMLs as a Jenkins artifacts
+ Post-Stages
  + Success
        > Send a build finished with SUCCESS notification to the GERRIT_REFSPEC
  + Failure
        > Send a build finished with FAILURE notification to the GERRIT_REFSPEC

### Usage

Below are places and explanation how the job should be used. This section should be removed after the related tickets are done.

+ eea-jenkins-docker-executor job
    > The eea-jenkins-docker-xml-generator job should be called to generate XMLs during docker-executor build run. Generated XMLs will be imported to the jenkins-docker and after that executed
+ CDD package generation [EEAEPP-86451](https://eteamproject.internal.ericsson.com/browse/EEAEPP-86451)
    > The cdd package generator job should use eea-jenkins-docker-xml-generator job to generate Jenkins jobs XML to add them to the cdd package

## Documents and Links

+ Studies / Epic
  + [EEAEPP-79523](https://eteamproject.internal.ericsson.com/browse/EEAEPP-79523)
  + [EEAEPP-79521](https://eteamproject.internal.ericsson.com/browse/EEAEPP-79521)
  + [EEAEPP-79635](https://eteamproject.internal.ericsson.com/browse/EEAEPP-79635)
  + [EEAEPP-79636](https://eteamproject.internal.ericsson.com/browse/EEAEPP-79636)
+ Source:
  + [jenkins-docker Gerrit Repo](https://gerrit.ericsson.se/#/admin/projects/EEA/jenkins-docker)
