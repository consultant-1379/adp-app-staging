# Information about eea-product-release-loop in Product CI

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Documentations

+ [Release-Helm-Package](https://gerrit.ericsson.se/plugins/gitiles/adp-cicd/bob-adp-release-auto/+/HEAD/helm/README.md#Release-Helm-Package)
+ [version_handler](https://gerrit.ericsson.se/plugins/gitiles/adp-cicd/bob-adp-release-auto/+/master/utils/#version_handler)

## Seed job

+ technicals/eea_product_release_loop_seed.Jenkinsfile
+ technicals/eea_product_release_loop_seed.groovy

## Product release

### eea-product-release-weekly

This automation intends for building the weekly plus versions releases of EEA4 product.
It creates the release version of the metabaseline/integration/documentation and deployer helm charts, builds the csar and deployer packages and uploads everything to the relevant released artifactory repository.

[This job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-release-weekly/) can be triggered manually.

According to previous agreements, this will be launched weekly by the CDM every Wednesday.
Prod CI Driver should support it if needed.

#### Files

+ jobs/eea_product_release_loop/eea_product_release_weekly.groovy
+ pipelines/eea_product_release_loop/eea_product_release_weekly.Jenkinsfile

#### Input parameters

+ META_CHART_VERSION - Chart version of the metachart. This meta version will be used to determine integration helm chart version
+ DOC_RELEASE_CANDIDATE - [OPTIONAL] Value of this parameter is the version of eric-eea-documentation-helm-chart-ci chart in eric-eea-ci-meta-helm-chart, from the latest meta chart version where eric-eea-int-helm-chart version equals with CHART_VERSION input parameter of this job.
+ SKIP_RELEASE_PRODUCT - Skip releasing integration helm chart, defaultValue: false
+ SKIP_RELEASE_CSAR - Skip releasing csar, defaultValue: false
+ SKIP_RELEASE_DOCUMENTATION - Skip releasing documentation, defaultValue: false
+ SKIP_RELEASE_DEPLOYER - Skip releasing deployer, defaultValue: false
+ SKIP_RELEASE_META - Skip releasing meta, defaultValue: false
+ SKIP_UPDATE_META_CHART_CONTENT - Skip updating meta chart content with plus versions, defaultValue: true // TODO: EEAEPP-100345!!!
+ PUBLISH_DRY_RUN - Enable dry-run for helm chart publish, arm upload and version increase, defaultValue: false

#### Stages

+ Params DryRun check
+ Check params
+ Checkout meta
  + checkout git tag identified in the META_CHART_VERSION parameter
+ Read versions from meta
  + Get the version from the meta [Chart.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/project-meta-baseline/+/master/eric-eea-ci-meta-helm-chart/Chart.yaml) for the following services:
    + eric-eea-int-helm-chart
    + eric-eea-ci-meta-helm-chart
    + eric-eea-documentation-helm-chart-ci
    + eric-eea-deployer
  + If DOC_RELEASE_CANDIDATE is not specified for the build, the version will be extracted from the EEA/project-meta-baseline repository commits in this stage
+ Checkout cnint
+ Init versions
+ Init arm
+ Release product: recreates and publish product helm chart
  + Checkout adp-app-staging
  + Prepare bob adp-app-staging
  + Cleanup product
  + Init versions product
  + Generate and Upload Integration Helm Chart
    + It first checks whether the helm package already exists in the released repo or not. Skips the stage once it's there
    + Recreates the integration helm chart with plus version and then uploads it to the released repo:
      + Executes the bob rule 'publish-released-helm-chart' defined in
      the [EEA/adp-app-staging ruleset2.0_product_release.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/ruleset2.0_product_release.yaml) ruleset file
+ Generate and Upload CSAR files
  + It first checks whether the csar package already exists in the released repo or not. Skips the stage once it's there
  + Executes the [csar-build job](https://seliius27190.seli.gic.ericsson.se:8443/job/csar-build/) with the released plus version
  + Dowloads the generated plus version csar package locally
  + Generates sidecar files such as 3pp_list.csv, content.txt and images.txt
  + Downloads the minus version CSAR images.txt from drop repository
  + Compares the already extracted images.txt and downloaded one, should be no diffs
  + Uploads the generated plus version csar package package, images.txt, content.txt and 3pplist.csv to the released repo
+ Release documentation: recreates and publish documentation helm chart
  + Checkout documentation
  + Prepare bob documentation
  + Cleanup documentation
  + Init versions documentation
  + Generate and Upload Documentation Helm Chart
    + It first checks whether the helm package already exists in the released repo or not. Skips the stage once it's there
    + Recreates the documentation helm chart with plus version and then uploads it to the released repo:
      + Executes the bob rule 'publish-released-helm-chart' defined in
      the [EEA/eea4_documentation documentation_release.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/eea4_documentation/+/master/bob-rulesets/documentation_release.yaml) ruleset file
  + Copy released documentation artifacts
    + Copies relevant documentation artifacts from 'proj-eea-docs-drop-generic-local/product-level-docs' to the 'proj-eea-docs-released-generic-local/product-level-docs' ARM folder
+ Release deployer: recreates and publish deployer helm chart
  + Checkout deployer
  + Prepare bob deployer
  + Cleanup deployer
  + Init versions deployer
  + Generate and Upload Deployer Helm Chart
    + It first checks whether the helm package already exists in the released repo or not. Skips the stage once it's there
    + Recreates the deployer helm chart with plus version and then uploads it to the released repo:
      + Executes the bob rule 'publish-released-helm-chart' defined in
      the [EEA/deployer ruleset2.0_deployer_release.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/deployer/+/master/bob-rulesets/ruleset2.0_deployer_release.yaml) ruleset file
      + Generates a next version for the deployer helm chart
  + DEPLOYER + package build
    + Executes the [eea-deployer-build-deployer-package job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-deployer-build-deployer-package/) with the released plus version
    + This job prepares and uploads the DEPLOYER package with a "+" version to the [proj-eea-released-generic-local Artifactory repository](https://arm.seli.gic.ericsson.se/artifactory/proj-eea-released-generic-local/)
  + Exec eea-deployer-release-new-version
    + Executes the [eea-deployer-release-new-version job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-deployer-release-new-version/) with the next version generated by the ruleset previously
    + new version uplift can happen in repo only if the master version is not bigger than the currently released version, e.g.
      + release: 0.5.0+17, master: 0.5.0-18 -> let's increase to 0.6.0-1
      + release: 0.5.0+17, master: 0.6.0-2 -> skip
+ Release meta: recreates and publish meta helm chart
  + Checkout meta
  + Prepare bob meta
  + Cleanup meta
  + Init versions meta
  + Replace meta chart -+ versions
    + TODO: [EEAEPP-100345](https://eteamproject.internal.ericsson.com/browse/EEAEPP-100345)!!!
  + Generate and Upload Meta Helm Chart
    + It first checks whether the helm package already exists in the released repo or not. Skips the stage once it's there
    + Recreates the meta helm chart with plus version and then uploads it to the released repo:
      + Executes the bob rule 'publish-released-helm-chart' defined in
      the [EEA/project-meta-baseline ruleset2.0_product_release.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/bob-rulesets/ruleset2.0_product_release.yaml) ruleset file
+ Upload dimtool
  + Copies relevant dimtool package file from drop to released ARM repo
    + source path: <https://arm.seli.gic.ericsson.se//artifactory/proj-eea-drop-generic-local/eea4-dimensioning-tool/>
    + target path: <https://arm.seli.gic.ericsson.se//artifactory/proj-eea-released-generic-local/eea4-dimensioning-tool/>
+ Upload spotfire-platform-asset
  + Copies relevant spotfire-platform-asset package file from drop to released ARM repo
    + source path: <https://arm.seli.gic.ericsson.se//artifactory/proj-eea-drop-generic-local/sf-platform-asset/>
    + target path: <https://arm.seli.gic.ericsson.se//artifactory/proj-eea-released-generic-local/sf-platform-asset/>
+ Upload test tools
  + Copies relevant test tool packages used in the [eric-eea-ci-meta-helm-chart/Chart.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/project-meta-baseline/+/master/eric-eea-ci-meta-helm-chart/Chart.yaml) from drop to released ARM repo (e.g. eric-data-loader, eric-eea-utf-application, eric-eea-robot, etc.)
    + source path: <https://arm.seli.gic.ericsson.se//artifactory/proj-eea-drop-helm-local/>
    + target path: <https://arm.seli.gic.ericsson.se//artifactory/proj-eea-released-helm-local/>

#### Ruleset files

+ [EEA/adp-app-staging ruleset2.0_product_release.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/ruleset2.0_product_release.yaml)
+ [EEA/eea4_documentation documentation_release.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/eea4_documentation/+/master/bob-rulesets/documentation_release.yaml)
+ [EEA/deployer ruleset2.0_deployer_release.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/deployer/+/master/bob-rulesets/ruleset2.0_deployer_release.yaml)
+ [EEA/project-meta-baseline ruleset2.0_product_release.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/bob-rulesets/ruleset2.0_product_release.yaml)

#### Direct access for released packages

In summary, you can find the reference of each released package with the version info and ARM repo link in the description of the executed job. e.g.:

```
Build #3 (Wed May 29 11:21:28 CEST 2024)

Meta chart version: 24.22.0-49
Product version: 24.22.0-13
eric-eea-int-helm-chart version: 24.22.0+13, released package: eric-eea-int-helm-chart-24.22.0+13.tgz
csar-package version: 24.22.0+13, released package: csar-package-24.22.0+13.csar
eric-eea-documentation-helm-chart-ci version: 24.22.0+15, released package: eric-eea-documentation-helm-chart-ci-24.22.0+15.tgz
eric-eea-deployer version: 0.5.0+19, released package: eric-eea-deployer-0.5.0+19.tgz
eea4-dimensioning-tool version: 24.22.0+13, released package: eea4-dimensioning-tool/eea4-dimensioning-tool-24.22.0+13.zip
spotfire-platform-asset-12.5.0-1.5.0-120124, released package: sf-platform-asset/spotfire-platform-asset-12.5.0-1.5.0-120124.zip
eric-data-loader version: 1.3.170-66, released package: eric-data-loader/eric-data-loader-1.3.170-66.tgz
eric-eea-utf-application version: 1.843.0-0, released package: eric-eea-utf-application/eric-eea-utf-application-1.843.0-0.tgz
eric-eea-jenkins-docker version: 1.0.0-35, released package: eric-eea-jenkins-docker/eric-eea-jenkins-docker-1.0.0-35.tgz
eric-eea-robot version: 0.50.0-0, released package: eric-eea-robot/eric-eea-robot-0.50.0-0.tgz
eric-eea-snmp-server version: 0.1.0-734, released package: eric-eea-snmp-server/eric-eea-snmp-server-0.1.0-734.tgz
eric-eea-sftp-server version: 0.1.0-39, released package: eric-eea-sftp-server/eric-eea-sftp-server-0.1.0-39.tgz
eric-eea-ci-meta-helm-chart version: 24.22.0+49, released package: eric-eea-ci-meta-helm-chart-24.22.0+49.tgz
```

The newly released [eric-eea-ci-meta-helm-chart/Chart.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/project-meta-baseline/+/master/eric-eea-ci-meta-helm-chart/Chart.yaml) also always contains the same released packages.

#### Jenkins view

Release specific Jenkins Jobs related to package lifecycle not part of the automated Prod CI pipelines (weekly and PRA release job, time based version change, etc) collected in the 'EEA Product Release' stage inside the [EEA Application Staging View](https://seliius27190.seli.gic.ericsson.se:8443/) Jenkins default view.

### eea-product-release-pra

This Jenkins job is the PRA release job for EEA4 product which adds the PRA tag to the released versions and creates git branches.
It creates the git tagging and branching for the metabaseline/integration/documentation and deployer released versions.

[This job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-release-pra/) can be triggered manually.

#### Files

+ jobs/eea_product_release_loop/eea_product_release_weekly.groovy
+ pipelines/eea_product_release_loop/eea_product_release_weekly.Jenkinsfile

#### Input parameters

+ META_CHART_VERSION - Chart version of the metachart. This meta version will be used to determine integration helm chart version
+ GIT_TAG_STRING - PRA git tag, e.g.: eea4_4.4.0_pra
+ DOC_RELEASE_CANDIDATE - [OPTIONAL] Value of this parameter is the version of eric-eea-documentation-helm-chart-ci chart in eric-eea-ci-meta-helm-chart, from the latest meta chart version where eric-eea-int-helm-chart version equals with CHART_VERSION input parameter of this job.
+ SKIP_RELEASE_PRODUCT - Skip releasing product, defaultValue: false
+ SKIP_RELEASE_CSAR - Skip releasing csar, defaultValue: false
+ SKIP_RELEASE_DOCUMENTATION - Skip releasing documentation, defaultValue: false
+ SKIP_RELEASE_DEPLOYER - Skip releasing deployer, defaultValue: false
+ SKIP_RELEASE_META - Skip releasing meta, defaultValue: false
+ PUBLISH_DRY_RUN - Enable dry-run for git tagging and create branches, defaultValue: false

#### Stages

+ Params DryRun check
+ Check params
+ Checkout meta
  + checkout git tag identified in the META_CHART_VERSION parameter
+ Read versions from meta
  + Get the version from the meta [Chart.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/project-meta-baseline/+/master/eric-eea-ci-meta-helm-chart/Chart.yaml) for the following services:
    + eric-eea-int-helm-chart
    + eric-eea-ci-meta-helm-chart
    + eric-eea-documentation-helm-chart-ci
    + eric-eea-deployer
  + If DOC_RELEASE_CANDIDATE is not specified for the build, the version will be extracted from the EEA/project-meta-baseline repository commits in this stage
+ Init versions
+ Init arm
+ Release product: recreates and publish product helm chart
  + Checkout adp-app-staging
  + Prepare bob adp-app-staging
  + Checkout cnint
  + Release git branch product
    + Creates git branch in the [cnint](https://gerrit.ericsson.se/#/admin/projects/EEA/cnint,branches) repo using the tag identified with the eric-eea-int-helm-chart released version
    + The branch name comes from GIT_TAG_STRING parameter, part before "_pra" (e.g. eea4_4.4.0_pra => eea4_4.4.0).
  + Create PRA Git Tag product
    + Creates git tag in the [cnint](https://gerrit.ericsson.se/#/admin/projects/EEA/cnint,tags) repo using the tag identified with the eric-eea-int-helm-chart released version
  + Upload Integration Helm Chart to App dashboard last-pra
+ Release documentation
  + Checkout documentation
  + Prepare bob documentation
  + Create PRA Git Tag documentation
    + Creates git tag in the [eea4_documentation](https://gerrit.ericsson.se/#/admin/projects/EEA/eea4_documentation,tags) repo using the tag identified with the eric-eea-documentation-helm-chart-ci released version
+ Release deployer
  + Checkout deployer
  + Prepare bob deployer
  + Release git branch deployer
    + Creates git branch in the [deployer](https://gerrit.ericsson.se/#/admin/projects/EEA/deployer,branches) repository using the tag tag identified with the eric-eea-deployer released version
    + The branch name comes from the GIT_TAG_STRING parameter, a part before "_pra" (e.g. eea4_4.4.0_pra => eea4_4.4.0)
  + Create PRA Git Tag deployer
    + Creates git tag in the [deployer](https://gerrit.ericsson.se/#/admin/projects/EEA/deployer,tags) repo using the tag identified with the eric-eea-deployer released version
+ Release meta
  + Checkout meta
  + Prepare bob meta
  + Create PRA Git Tag meta
    + Creates git tag in the [project-meta-baseline](https://gerrit.ericsson.se/#/admin/projects/EEA/project-meta-baseline,tags) repo using the tag identified with the eric-eea-ci-meta-helm-chart released version

### eea-deployer-build-deployer-package

This job makes the DEPLOYER package and uploads it with "+" version to Artifactory

[This job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-deployer-build-deployer-package/) is triggered automatically from the [eea-product-release-weekly](#eea-product-release-weekly) Jenkins job or can be run manually

#### Input parameters

+ CHART_VERSION - Chart version
+ GERRIT_REFSPEC - A Gerrit refspec to check out changes from
+ SPINNAKER_TRIGGER_URL - Spinnaker pipeline triggering url
+ SPINNAKER_ID - The spinnaker execution's id
+ IS_RELEASE - Please check it when want to upload the package to proj-eea-released-generic-local. In this case the GERRIT_REFSPEC will be Cherry Picked

#### Stages

+ Params DryRun check
+ Gerrit message
+ Set build description
+ Checkout
+ EEA/deployer repo change checkout
+ Prepare structure
+ Generate pipeline_package
+ Publish DEPLOYER pipeline package

### eea-deployer-release-new-version

This automation intends for a preparation of a new deployer helm chart version with the increased version number (e.g. 4.1.0-0) after the release has been created with eea-deployer-release-loop job. This job is creates a chart with this new version and publishes it to ARM, and it updates the deployer helm chart in the deployer Git repository as well.

[This job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-deployer-release-new-version/) is triggered automatically from the [eea-product-release-weekly](#eea-product-release-weekly) Jenkins job and can be triggered manually.

#### Input parameters

+ REVISION_NUM - Next version output to replace revision in a helm/eric-eea-deployer/Chart.yaml.
  New version for the deployer helm chart in the helm/eric-eea-deployer/Chart.yaml is derived from it. If Next version=4.1.0, then new version=4.1.0-1
+ GIT_COMMENT - the comment of the git tag

#### Stages

+ Params DryRun check
+ Checkout
+ Push patchset with PRA version to Gerrit
+ Prepare
+ Publish DEPLOYER Helm Chart

## Bfu gate release

### eea-product-release-loop-bfu-gate-change

This Jenkins job is used to trigger the [eea-product-release-loop-bfu-gate-upgrade](#eea-product-release-loop-bfu-gate-upgrade) Jenkins job five times in a loop to validate new upgrade baseline before changing it in our live upgrade pipelines (in app staging and meta baseline loops). If the validation process is success we should trigger manually [eea-product-release-loop-bfu-gate-tagging](#eea-product-release-loop-bfu-gate-tagging) Jenkins job to create the `latest_release` and `latest_BFU_gate` git tags. If any error occurs during execution of bfu upgrade test, email notification is sent to [EEA4 Product CI](mailto:PDLEEA4PRO@pdl.internal.ericsson.com).

[This job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-release-loop-bfu-gate-change/) can be triggered manually.

#### Files

+ jobs/eea_product_release_loop/eea_product_release_loop_bfu_gate_change.groovy
+ pipelines/eea_product_release_loop/eea_product_release_loop_bfu_gate_change.Jenkinsfile

#### Input parameters

+ NEW_BFU_GATE - Git tag of the new BFU gate e.g: eea4_4.4.0_pra
+ GIT_TAG_STRING - The commit message for the latest_release and latest_BFU_gate Git tags. E.g: EEA 4.4.0 PRA release
+ BFU_GATE_VALIDATION_RUNS_NUMBER - This parameter sets a number of how many times should be run the eea-product-release-loop-bfu-gate-upgrade loop to validate the new BFU gate version. Currently, the default value is 5
+ BASELINE_INSTALL_JENKINSFILE_GERRIT_REFSPEC - This parameter sets the JENKINSFILE_GERRIT_REFSPEC eea-application-staging-product-baseline-install Jenkins job
+ UPGRADE_JENKINSFILE_GERRIT_REFSPEC - This parameter sets the JENKINSFILE_GERRIT_REFSPEC eea-common-product-upgrade

#### Stages

+ Params DryRun check
+ bfu-gate validating - triggers [eea-product-release-loop-bfu-gate-upgrade](#eea-product-release-loop-bfu-gate-upgrade) Jenkins job
+ bfu-gate validating check latest runs - this stage is under development and intends to analyze if the previous 5 validations were successful and have the same BFU gate version. If these conditions are met it has to assign a true value to RUN_BFU_GATE_TAGGING environment variable. See comments in the EEAEPP-84706 ticket
+ bfu-gate tagging - triggers [eea-product-release-loop-bfu-gate-tagging](#eea-product-release-loop-bfu-gate-tagging) Jenkins job if the RUN_BFU_GATE_TAGGING has the true value based on a result of the previous stage
+ post failure action - send notification email from the failure

### eea-product-release-loop-bfu-gate-upgrade

This Jenkins job is used to validate new upgrade baseline before changing it in our live upgrade pipelines (in app staging and meta baseline loops)

The upgrade job triggers the [eea-application-staging-product-baseline-install](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-product-baseline-install/) Jenkins job to install the version of the newly created git branch created by the release job. (with wait option: true)

[This job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-release-loop-bfu-gate-upgrade/) can be triggered manually from [eea-product-release-loop-bfu-gate-change](#eea-product-release-loop-bfu-gate-change) Jenkins job.

#### Files

+ jobs/eea_product_release_loop/eea_product_release_loop_bfu_gate_upgrade.groovy
+ pipelines/eea_product_release_loop/eea_product_release_loop_bfu_gate_upgrade.Jenkinsfile

#### Input parameters

+ NEW_BFU_GATE - Git tag of the new BFU gate e.g: eea4_4.4.0_pra
+ SPINNAKER_TRIGGER_URL - Spinnaker pipeline triggering url
+ SPINNAKER_ID - The spinnaker execution's id
+ PIPELINE_NAME - The spinnaker pipeline name, default: 'eea-application-staging'
+ SKIP_COLLECT_LOG - skip the log collection pipeline, default: false
+ SKIP_CLEANUP - skip the cleanup pipeline. Used when SKIP_COLLECT_LOG is false, default: false
+ BASELINE_INSTALL_JENKINSFILE_GERRIT_REFSPEC - This parameter sets the JENKINSFILE_GERRIT_REFSPEC eea-application-staging-product-baseline-install Jenkins job
+ UPGRADE_JENKINSFILE_GERRIT_REFSPEC - This parameter sets the JENKINSFILE_GERRIT_REFSPEC eea-common-product-upgrade
+ HELM_AND_CMA_VALIDATION_MODE - Use HELM values or HELM values and CMA configurations. valid options ("true":  use helm values, cma is disabled / "false": use helm values and load CMA configurations)

#### Stages

+ Params DryRun check
+ Init
+ Check params
+ Determine git branch for product-baseline install
  + Get git branch name in cnint repo using the tag passed as NEW_BFU_GATE parameter
+ product-baseline install
  + Executed job name: [eea-application-staging-product-baseline-install](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-product-baseline-install/)
  + Executed job doc [link](https://eteamspace.internal.ericsson.com/display/ECISE/Application+staging+product-baseline+install)
+ Execute upgrade
  + Execute [eea-common-product-upgrade](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-common-product-upgrade/) Jenkins job to validate changes using the generic common upgrade job.
  + Job doc [link](https://eteamspace.internal.ericsson.com/display/ECISE/EEA4+Common+Product+Upgrade)
+ Copy artifacts
+ Archive artifacts

### eea-product-release-loop-bfu-gate-tagging

This Jenkins job is used to move git tags `latest_release` and `latest_BFU_gate` to the new position.
After the tagging cluster-cleanup Jenkins job will be executed on pre-installed clusters that already have product-baseline installation with the previous pra version. Baseline installations and upgrade that may already be in progress will not be interrupted.

[This job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-release-loop-bfu-gate-tagging/) has to be triggered manually!

#### Files

+ jobs/eea_product_release_loop/eea_product_release_loop_bfu_gate_tagging.groovy
+ pipelines/eea_product_release_loop/eea_product_release_loop_bfu_gate_tagging.Jenkinsfile

#### Input parameters

+ NEW_BFU_GATE - Git tag of the new BFU gate e.g: eea4_4.4.0_pra
+ GIT_TAG_STRING - The commit message for the latest_release and latest_BFU_gate Git tags. E.g: EEA 4.4.0 PRA release

#### Stages

+ Params DryRun check
+ Checkout
+ Prepare
+ Create latest_release & latest_BFU_gate git tag
+ Cleanup pre-installed clusters

## Time based versioning

### eea-product-release-time-based-new-version

To support time based internal versioning of EEA, an automated umbrella job was created which would change the following helm chart versions on time based triggers:

+ EEA integration helm chart
+ Metabaseline helm chart
+ Documentaiton helm chart
+ Deployer helm chart

[This job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-release-time-based-new-version/) is triggered automatically from cron every Monday at 00:00 or can be run manually

+ Input parameter
  + CHART_VERSION - Chart version, format: `<year>.<week>.<patch/EP number>-<build number>`; e.g. `23.40.0-1`
    + default value would get the year and week number automatically, BUT can be override in case of manual trigger
  + GIT_COMMENT - The comment of the git tag
  + SKIP_VERSION_UPDATE_CNINT - to skip updating cnint version, default: `false`
  + SKIP_VERSION_UPDATE_META - to skip updating meta version, default: `false`
  + SKIP_VERSION_UPDATE_DOCUMENTATION - to skip updating documentation VERSION_PREFIX, default: `false`
  + SKIP_VERSION_UPDATE_DEPLOYER - to skip updating deployer PRODUCT_VERSION, default: `false`

#### Files

+ jobs/eea_product_release_loop/eea_product_release_time_based_new_version.groovy
+ pipelines/eea_product_release_loop/eea_product_release_time_based_new_version.Jenkinsfile

#### Time based internal versioning flow of EEA

+ new version format: `<year>.<week>.<patch/EP number>-<build number>`
  + e.g.: 23.44.0-1
+ at each Monday 0:00 CET version updater would change the versions to the following: yy.ww.0-1
+ last digit will be increased only by EPs, on the master branch it should be continuously 0
+ weekly drops, RCs and PRAs won't change the actual version of the charts, just add git tags
