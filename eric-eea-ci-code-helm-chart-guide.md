# EEA Code Base Helm Chart

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## The product CI code helm chart

### Description

This document describe the EEA Code Base Helm Chart and the the ci code validation and versioning process

### Helm chart

eric-eea-ci-code-helm-chart is an apiversion v2 (helm3) integration helm chart,
the dependencies described in the Chart.yaml and

Example:

```
apiVersion: v2
appVersion: 1.0.0
dependencies:
- condition: eric-eea-int-helm-chart.enabled
  name: eric-eea-int-helm-chart
  repository: https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm
  version: 0.0.0-81
description: EEA Code Base Helm Chart
name: eric-eea-ci-code-helm-chart
version: 1.0.0-37
```

(The eric-eea-int-helm-chart.enabled only just for the example are here, at this moment it heas no dependency)

#### Dependencies

-

#### Values

-

### Validation and versioning

The validation and versioning workflow triggered by someone give +1 to a change

- eea-product-ci-code-manual-flow-codereview-ok Jenkins job
  - prepare helm chart
  - linting the helm chart
  - design rule checking for the helm chart
  - save as artifact the necessary parameters for ihc in artifact.properties
- successfull jenkins job run triggers in Spinnakker  eea-product-ci-code-manual-flow pipeline
  - <https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/configure/0cc201f7-1b6f-4b4f-a737-a1c57e41f058>
  - propery file: artifact.properties
- successfull manual flow run triggers in Spinnakker the EEA Product CI Code Staging - eea-product-ci-code-loop
  - <https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/configure/390c5aae-f48d-424d-9195-74bed4bf0e73>
  - parameters
    - GERRIT_REFSPEC
    - GIT_COMMIT_ID
    - SPINNAKER_TRIGGER_URL
  - stages
    - Prepare jenkins job eea-product-ci-code-loop-prepare
    - Functional test jenkins job functional-test-loop
    - Publish jenkins job eea-product-ci-code-loop-publish

#### Spinnakker pipelines

- <https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/configure/0cc201f7-1b6f-4b4f-a737-a1c57e41f058>
- <https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/configure/390c5aae-f48d-424d-9195-74bed4bf0e73>

#### Jenkins jobs

- <https://seliius27190.seli.gic.ericsson.se:8443/view/all/job/eea-product-ci-code-manual-flow-codereview-ok/>
- <https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-ci-code-loop-prepare/>
- <https://seliius27190.seli.gic.ericsson.se:8443/job/functional-test-loop/>
- <https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-ci-code-loop-publish/>
