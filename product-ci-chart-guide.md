# Setting up chart for Product CI

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Setting up chart for Product CI

### Description

This document outlines the process of adding a helm chart to the Product CI, which is necessary to be able to version Product CI code.

### Useful link collection

* [**Bob user guide**](https://gerrit.ericsson.se/plugins/gitiles/adp-cicd/bob/+/HEAD/USER_GUIDE_2.0.md)

* [**ADP int helm chart**](https://gerrit.ericsson.se/plugins/gitiles/adp-cicd/adp-int-helm-chart-auto)

* [**Helm chart design rules and guidelines**](https://confluence.lmera.ericsson.se/pages/viewpage.action?spaceKey=AA&title=Helm+Chart+Design+Rules+and+Guidelines)

* [**Walktrough in a dummy service**](https://eteamspace.internal.ericsson.com/display/AP/4.+Walk-through+in+a+dummy+service)  **Keep in mind, that this is for services.**

### Prerequisites

* The Integration Helm Charts is stored in a Gerrit Central Repository

* At least one helm chart repository is created in an Artifactory

* The functional user should have the following rights on the repository :

```
Reference: refs/*
    Edit Topic Name
Reference: refs/for/refs/heads/master
    Push
Reference: refs/heads/*
    Create Reference
    Label Code-Review -2 +2
    Push
    Submit
Reference: refs/tags/*
    Create Reference
    Push
```

* Functional user should have a valid e-mail address under the contact settings, or the Forge Committer Identity permission has to be granted for it on ```Reference: refs/heads/*```
  * Otherwise gerrit will refuse the push attempt.
    * remote: ERROR:  committer email address ****@ericsson.com
    * remote: ERROR:  does not match your user account.

### File setup

#### Files in root

* ruleset2.0.yaml
  * Find our example ruleset below in Examples
  * [**Create your first ruleset file**](https://gerrit.ericsson.se/plugins/gitiles/adp-cicd/bob/+/HEAD/USER_GUIDE_2.0.md#Create-the-first-ruleset-file)
* repositories.yaml.template
  * Config file template for artifactory access
  * Api tokens are coming from jenkinsfile, with the help of Credentials Binding plugin
  * Example of credentials binding in jenkinsfile :

```
stage('Prepare Helm Chart') {
    steps {
        // Generate integration helm chart
        withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                         string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                         string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA'),
                         usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD')]) {
            sh 'bob/bob prepare'
        }
    }
}
```

* Example in ruleset how it uses the credentials :

```
  prepare-common:
    - task: prepare-repositories-yaml
      cmd:
        - cp repositories.yaml.template ${repositories-yaml-path}
        - sed -i "s/USERNAME/${env.USER_ARM}/" ${repositories-yaml-path}
        - sed -i "s/API_TOKEN_ADP/${env.API_TOKEN_ADP}/" ${repositories-yaml-path}
        - sed -i "s/API_TOKEN_EEA/${env.API_TOKEN_EEA}/" ${repositories-yaml-path}
```

* Example how the new version is published from a jenkinsfile to the repository :

```
stage('Publish Helm Chart') {
    steps {
        // Generate integration helm chart
        withCredentials([
                        usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'USER_PASSWORD'),
                        usernamePassword(credentialsId: 'git-functional-http-user', usernameVariable: 'GERRIT_USERNAME', passwordVariable: 'GERRIT_PASSWORD'),
                        string(credentialsId: 'arm-adpgs-eceaart-api-token', variable: 'API_TOKEN_ADP'),
                        string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
            sh 'bob/bob publish'
        }
    }
}
```

#### Files in chart directory

* Chart.yaml
  * Contains chart name and version
  * Version is increased automatically by the 'ihc-auto publish' task
  * Contains the list of dependencies of the chart
  * An integration helm chart is defined to be a helm chart which pulls together a number of other helm charts, referred to as sub-charts, for ease of integration and deployment.
  * **This file will contain for example the jenkins docker chart reference in future.**
* values.yaml
  * config file for dependency charts

### Examples

```
* Chart.yaml
```

apiVersion: v2
appVersion: 1.0.0
dependencies:

* condition: eric-eea-int-helm-chart.enabled
  name: eric-eea-int-helm-chart
  repository: <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm>
  version: 0.0.0-81
description: EEA Code Base Helm Chart
name: eric-eea-ci-code-helm-chart
version: 1.0.0-22

```
* values.yaml
```

eric-eea-int-helm-chart:
  enabled: true
```
