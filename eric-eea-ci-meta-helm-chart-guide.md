# EEA Meta Base Helm Chart

**Table of contents:**

<!-- START doctoc
...
END doctoc -->

## The EEA Meta Base Helm Chart

### Description

This document describe the EEA Meta Base Helm Chart and the the validation and versioning processes

### Helm chart

Helm chart path: EEA/adp-app-staging/eric-eea-ci-meta-helm-chart/
eric-eea-ci-meta-helm-chart is an apiversion v2 (helm3) integration helm chart,
the dependencies described in the Chart.yaml and other parameters in values.yaml

This helm chart connects EEA4 product integration helm chart with testing tools (data loader, utf service, nmp server) and ci code. These testing tools are deployed to the same utf-service namespace separated from the product itself.

Example:

```
apiVersion: v2
appVersion: 1.0.0
dependencies:
- condition: eric-eea-ci-code-helm-chart.enabled
  name: eric-eea-ci-code-helm-chart
  repository: https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm
  version: 1.0.0-196
- condition: eric-eea-int-helm-chart.enabled
  name: eric-eea-int-helm-chart
  repository: https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm
  version: 0.0.0-278
- condition: eric-eea-utf-application.enabled
  name: eric-eea-utf-application
  repository: https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm
  version: 1.0.22-0

...

description: EEA Meta Base Helm Chart
name: eric-eea-ci-meta-helm-chart
version: 1.0.0-221
```

#### Dependencies

- eric-eea-ci-code-helm-chart: The dependency of the ci code version. After the a version increase happens in ci code, the version it's triggering an increase in eric-eea-ci-meta-helm-chart there is no validation process only helm linting and design rule check.
- new UTF version: The dependency of eric-eea-utf-application
- new CPI change: The dependency of eric-eea-documentation-helm-chart-ci
- new JENKINS DOCKER version: The dependency of eric-eea-jenkins-docker
- new RVROBOT version: The dependency of eric-eea-robot

#### Values

```
eric-eea-ci-code-helm-chart:
  enabled: false
eric-eea-utf-application:
  enabled: true
eric-eea-int-helm-chart:
  enabled: false
eric-eea-documentation-helm-chart-ci:
  enabled: false
eric-data-loader:
  enabled: true
eric-eea-snmp-server:
  enabled: true
eric-eea-sftp-server:
  enable: true
eric-eea-jenkins-docker:
  enabled: false
eric-eea-robot:
  enabled: false
```

### Validation and versioning

#### Manual flow

This pipeline triggered by someone give +2 to a change in the EEA/adp-app-stagin/eric-eea-ci-meta-helm-chart/

Steps:

- eea-product-ci-meta-baseline-loop-manual-job Jenkins job
  - prepare helm chart
  - linting the helm chart
  - design rule checking for the helm chart
  - save as artifact the necessary parameters for ihc in artifact.properties
- successful jenkins job run triggers in Spinnaker eea-app-meta-baseline-manual-flow pipeline
  - propery file: artifact.properties
- successful manual flow run triggers in Spinnaker the Prod Ci Infrastructure Staging - eea-product-ci-meta-baseline-loop
  - parameters
    - GERRIT_REFSPEC

##### Spinnaker pipelines

<https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/configure/7e5a30db-f095-4c13-94a9-11967ce44a8c>

##### Jenkins jobs

<https://seliius27190.seli.gic.ericsson.se:8443/view/EEA%20Product%20CI%20Infrastructure%20Staging%20-%20meta-baseline/job/eea-product-ci-meta-baseline-loop-manual-job/>

#### CI code version increase flow

This pipeline triggered by a new ci code version published

Steps:

- eea-product-ci-code-loop-publish successful run triggers is Spinnaker eea-metabaseline-product-ci-version-change pipeline
  - propery file: artifact.properties
- in Spinnaker eea-metabaseline-product-ci-version-change triggers Prod Ci Infrastructure Staging pipeline - eea-product-ci-meta-baseline-loop
  - parameters
    - CHART_NAME
    - CHART_REPO
    - CHART_VERSION

##### Spinnaker pipelines

<https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/configure/944e2d7c-b967-4a81-a21a-cbf904850fb8>

#### UTF code version increase flow

This pipeline triggered by a new UTF code version published

Steps:

- [eric-eea-utf-application-drop](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eric-eea-utf-application-drop) triggered by [UTF drop](https://seliius27190.seli.gic.ericsson.se:8443/job/eric-eea-utf-application-drop/) Jenkins job
  - property file: artifact.properties
- in Spinnaker eea-metabaseline-product-ci-version-change triggers Prod Ci Infrastructure Staging pipeline - eea-product-ci-meta-baseline-loop
  - parameters
    - CHART_NAME
    - CHART_REPO
    - CHART_VERSION

#### CPI version increase flow

This pipeline triggered by a new CPI version published

Steps:

- [eea4-documentation-version-change](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea4-documentation-version-change) triggered by Spinnaker when the [documentation_publish](https://seliius27190.seli.gic.ericsson.se:8443/job/documentation_publish/) job has sucessfully finished.
  - property file: artifact.properties
- in Spinnaker eea-metabaseline-product-ci-version-change triggers Prod Ci Infrastructure Staging pipeline - eea-product-ci-meta-baseline-loop
  - parameters
    - CHART_NAME
    - CHART_REPO
    - CHART_VERSION

#### JENKINS DOCKER version increase flow

This pipeline triggered by a new JENKINS DOCKER drop version published

Steps:

- [eric-eea-jenkins-docker-drop](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eric-eea-jenkins-docker-drop) triggered by Spinnaker when the [eea-jenkins-docker-manual-flow-codereview-ok](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-jenkins-docker-manual-flow-codereview-ok/) job has sucessfully finished.
  - property file: artifact.properties
- in Spinnaker eea-metabaseline-product-ci-version-change triggers Prod Ci Infrastructure Staging pipeline - eea-product-ci-meta-baseline-loop
  - parameters
    - CHART_NAME
    - CHART_REPO
    - CHART_VERSION

#### RVROBOT version increase flow

This pipeline triggered by a new RVROBOT drop version published

Steps:

- [eea_robot_drop](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea_robot_drop) triggered by Spinnaker when the [eea_robot_drop](https://seliius27190.seli.gic.ericsson.se:8443/job/eea_robot_drop/) job has sucessfully finished.
  - property file: artifact.properties
  - stages
    - Batching robot version
      - based on the new given robot drop version a new patchset will be created, increasing the robot version of [eric-eea-ci-meta-helm-chart](https://gerrit.ericsson.se/plugins/gitiles/EEA/project-meta-baseline/+/master/eric-eea-ci-meta-helm-chart/Chart.yaml) and the robot docker image version in the relevant [ruleset file](https://gerrit.ericsson.se/plugins/gitiles/EEA/project-meta-baseline/+/master/bob-rulesets/eea-robot.yaml) as a manual change.
      - it executes [eea-product-ci-meta-baseline-loop-merge](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-ci-meta-baseline-loop-merge/) Jenkins job
        - parameters
          - ROBOT_VERSION
    - Meta Baseline Staging
      - after creating the new patchset it will be validated by [eea-product-ci-meta-baseline-loop](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?q=eea-product-ci-meta-baseline-loop)
        - parameters
          - GERRIT_REFSPEC

#### Product Ci Infrastructure Staging pipeline

This pipeline responsible for the validation and version increase of eric-eea-ci-meta-helm-chart. Can be triggered manually or by a product ci code version increase

Steps:

- In Spinnaker eea-product-ci-meta-baseline-loop triggered by eea-metabaseline-product-ci-version-change or eea-app-meta-baseline-manual-flow pipeline
  - parameters
    - CHART_NAME+CHART_REPO+CHART_VERSION
    - or GERRIT_REFSPEC
  - stages
    - Sanity Check linting and design rule check (later other checks)
    - Prepare
    - Test (UTF test)
    - Publish: version increase and publish new chart

#### UTF evaluation release version checking

- In Spinnaker eea-product-ci-meta-baseline-loop in the stage "Prepare" the Jenkins job "eea-product-ci-meta-baseline-loop-prepare" triggered

  - Steps
    - get incoming UTF Apllication version and from UTF Apllication in meta baseline
    - compare UTF Application version from a new drop and from the meta baseline
      - if incoming parameter "EVALUATION" is "true"
      - if incoming parameter "CHART_NAME" is "eric-eea-utf-application"
      - if major,minor,patch UTF Apllication version is higher than version from meta baseline UTF dependency
      - prevent continue pipeline if version of incoming UTF Apllication is lower than version from meta baseline UTF dependency

#### UTF test

- In Spinnaker eea-product-ci-meta-baseline-loop in the stage "Test" the Jenkins job "eea-product-ci-meta-baseline-loop-test" triggered

  - parameters

    - CHART_NAME
    - CHART_REPO
    - CHART_VERSION
    - INT_CHART_NAME
    - INT_CHART_REPO
    - INT_CHART_VERSION

  - Steps
    - deploys the meta helm chart from the INT_CHART_NAME, INT_CHART_REPO and INT_CHART_VERSION parameters
    - deploys the product from the meta helm chart (should be the latest)
    - runs all staging, nx1 and batch tests
