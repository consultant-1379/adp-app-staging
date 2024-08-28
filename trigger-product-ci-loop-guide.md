# How to add/remove microservice trigger for Product CI loops

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Add ADP generic microservice into Product CI

### **Before** you push any change into the helm chart inform product CI team about the needed change in product CI.  -  **Microservice Team**

#### Prerequisites  -  **Microservice Team**

- Releaseable + version of the service is available (check your 3pps, vulnerabilities, etc..., check the + version checklist with Program Team)
- ADP DRs are checked for your service

#### Opening ticket for Product CI team  -  **Microservice Team**

- Clone template task for the Product CI team: [EEAEPP-49206](https://eteamproject.internal.ericsson.com/browse/EEAEPP-49206) If your team need a task create an other one for yourself.
- Inform the team via e-mail to proceed: EEA4 Product CI <PDLEEA4PRO@pdl.internal.ericsson.com>
- After the initial information about the integration request all requests related to the integration process should go via the integration tickets. Also dev teams should connect their tickets to the integration ticket for Product CI so Product CI team will be able to track the changes via the integration tickets.

### Implement change in Product CI  -  **Product CI Team**

- Implement the necessary changes based on the cloned template task.
- CI clusters have the hardware requirements for the new microservice (vCPU, memory, storage). If there are insufficient resources, please order the required infrastructural changes. (free resources can be checked at the k8s cluster health dashboard at Grafana)
- Perform the necessary changes in the install/upgrade/rollback scripts if there is any.
- Implement environment changes : **Please be aware that it can take weeks** if hardware resource not available or in case of complex install/upgrade/rollback/environment procedure. In ideal cases the task can be closed in days.
- Add the new service to the exception list for GL-D1121-033 at input-sanity-check-rules.yaml in cnint repo.

### Update ci helm chart  -  **Microservice Team**

- [eric-eea-int-helm-chart-ci](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/eric-eea-int-helm-chart-ci/) is a helm chart for ci specific configs located in the [cnint](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/) repository.
- Follow the [Developer Guide](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/documentation/userGuidesForHelmChartModification.md#Developer-Guide) to update the helm chart.

### Prepare dimensioning tool plugin - **Microservice Team**

- Please follow the [guide](https://gerrit.ericsson.se/plugins/gitiles/EEA/dimensioning-tool/+/master/plugin_developer_guide.md) from Dimensioning Group to prepare the dimensioning plugin for the new service.

### Update umbrella helm chart  -  **Microservice Team**

- [eric-eea-int-helm-chart](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/eric-eea-int-helm-chart/) is an umbrella helm chart located in the [cnint](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/) repository.
- Follow the [Developer Guide](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/documentation/userGuidesForHelmChartModification.md#Developer-Guide) to update an umbrella helm chart.
- After EEA 4.0 PRA new services should be introduced in disabled state first!

### Ensure that new microservice is in [ADP drop repository](https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-gs-all-helm/).  -  **Microservice Team**

- Check that the version of your microservice which has been added to the integration helm chart is available at the ADP drop repository in ARM.

### +1 for ci helm chart  -  **Product CI Team**

- When the above conditions are met, the Code Review +1 can be given to the commit updating ci helm chart.

### +1 for umbrella helm chart  -  **Product CI Team**

- When the above conditions are met, the Code Review +1 can be given to the integration commit.

### Configure the new service to be enabled at Product CI loops -  **Product CI Team**

- The new service has to be added to the helm-values/custom_deployment_values.yaml file in the cnint repo
- This change will enable deployment of the new service in Product CI loops.

### Create Spinnaker trigger   -  **Product CI team**

- Create ticket for ADP Spider team to add a new ADP GS to EEA at ADP Dashboard and create trigger for EEA App Staging by setting up automated trigger for eea-adp-staging Spinnaker pipeline.
- A ticket should be written for ADP Spider team with the following data [here](https://eteamspace.internal.ericsson.com/pages/viewpage.action?pageId=1134647306):
  - Name of the ADP GS which has been added to EEA.
  - Name of the Spinnaker Stage which should be added to ADP G2 E2E pipeline (aka EEA App Staging)
  - Name of the Spinnaker application (eea)
  - Spinnaker pipeline to be triggered by the new stage (eea-adp-staging)
- If E2E Spinnaker pipeline is not available for a service the following process shall be followed.
  - Microservice team has to ensure that a Jenkins job is available which can trigger a Spinnaker pipeline in case of new drop with the needed parameters. Example [here](https://udm5gjenkins.seli.gic.ericsson.se/view/ADP%20KVDB%20AG/job/adp_gs_geode_operator_generate_artifacts/).
  - Create drop pipeline in eea Spinnaker project with the following naming convention: 'microservice name-drop'
    - Automated trigger:
      - Type: Jenkins
      - Controller - Select the Jenkns instance which contains the trigger job
      - Job - Select the Jenkins job from the Microservice team mentioned above.
      - Property File - The output file from the Jenkins file mentioned above which contains the needed parameters.
      - Select Trigger Enabled box.
    - Add a new stage to trigger EEA ADP Staging pipeline.
      - Stage Name: EEA-ADP-Staging, Application: eea, Pipeline: eea-adp-staging
      - Add all pipeline parameters from the property file. (e.g. CHART_NAME=${trigger.properties['CHART_NAME']})
      - If the stage fails entire pipeline should halt.

### Add new service to component ownership page at JIRA   -  **Microservice Team**

- ScM of the microservice team has to fill in the [component ownership page at JIRA](https://eteamproject.internal.ericsson.com/projects/EEAEPP?selectedItem=com.atlassian.jira.jira-projects-plugin:components-page) with the requested data for the new service.
- e.g. for the description field

`component_helm_name:"eric-eea-analysis-system-overview-install" | cxc/cxd:"CXD 101 0849" | drop_pipeline:"spotfire-dashboard-drop" | team_mailing_list:"PDLCRUMINS@pdl.internal.ericsson.com" | jira_team_label:"Insights_Dashboard" | project:"EEA" | track:"EEA4"`

### Testing   -  **Product CI Team**

- Testing with the latest version of the uS which was added to the [Chart.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/eric-eea-int-helm-chart/Chart.yaml/). Manually start [eea-adp-staging](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-adp-staging) spinnaker pipeline with the latest version from Chart.yaml.

#### A remark:

eea-adp-staging triggers already configured EEA ADP Drop and EEA Application Staging loops.

**EEA ADP Drop Loops** - for Non - PRA uS the sequential order is as follows:

1. Prepare Baseline
2. EEA ADP Staging Install
3. EEA ADP Staging Upgrade

**EEA ADP Drop Loops and EEA Application Staging** - for PRA uS the sequential order is as follows:

1. Prepare Baseline
2. EEA ADP Staging Install
3. EEA ADP Staging Upgrade
4. EEA Application Staging (as at the moment only 1 test environment is available this would cause that one of these has to wait for the other)

## Add EEA microservice into Product CI

### Inform product CI team about the needed change in product CI.  -  **Microservice Team**

- Clone template task: [EEAEPP-49206](https://eteamproject.internal.ericsson.com/browse/EEAEPP-49206)
- Inform the team via e-mail to proceed EEA4 Product CI <PDLEEA4PRO@pdl.internal.ericsson.com>

### Implement change in product CI  -  **Product CI Team**

- Implement the necessary changes based on the cloned template task.
- CI clusters have the hardware requirements for the new microservice (vCPU, memory, storage).If there are insufficient resources, please order the required infrastructural changes. (free resources can be checked at the k8s cluster health dashboard at Grafana)
- Perform the necessary changes in the install/upgrade/rollback scripts if there is any.
- Implement environment changes:  **Please be aware that it can take weeks** if hardware resource not available or in case of complex install/upgrade/rollback/environment procedure. In ideal cases the task can be closed in days.
- Add the new service to the exception list for GL-D1121-033 at input-sanity-check-rules.yaml in cnint repo.

### Update CI helm chart (EEA service) -  **Microservice Team**

- [eric-eea-int-helm-chart-ci](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/eric-eea-int-helm-chart-ci/) is a helm chart for ci specific configs located in the [cnint](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/) repository.
- Follow the [Developer Guide](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/documentation/userGuidesForHelmChartModification.md#Developer-Guide) to update the helm chart.

### Update umbrella helm chart (EEA service) -  **Microservice Team**

- [eric-eea-int-helm-chart](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/eric-eea-int-helm-chart/) is an umbrella helm chart located in the [cnint](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/) repository.
- Follow the [Developer Guide](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/documentation/userGuidesForHelmChartModification.md#Developer-Guide) to update an umbrella helm chart.
- After EEA 4.0 PRA new services should be introduced in disabled state first!

### Ensure that new microservice is in [EEA drop repository](https://arm.seli.gic.ericsson.se/artifactory/proj-eea/).  -  Microservice Team

- Check that the version of your microservice which has been added to the integration helm chart is available at the EEA drop repository in ARM.

### +1 for CI helm chart (EEA service) -  **Product CI Team**

- Check if the commit contains + version only for the new microservice.
- If this is not available yet, the service has to be added to the csar exception list following [this guide](https://eteamspace.internal.ericsson.com/display/ECISE/CSAR+build), and to the [exemption list](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/technicals/input_sanity_check.Jenkinsfile#558) for upgrade test report checks. This should be merged to the cnint master before integrating the new service.
- When the previous steps are done the Code Review +1 can be given to the commit updating ci helm chart.

### +1 for umbrella helm chart (EEA service) -  **Product CI Team**

- When the above conditions are met, the Code Review +1 can be given to the integration commit.

### Configure the new service to be enabled at Product CI loops -  **Product CI Team**

- The new service has to be added to the helm-values/custom_deployment_values.yaml file in the cnint repo
- This change will enable deployment of the new service in Product CI loops.

### Create Spinnaker drop and release pipelines  -  **Microservice Team**

- Create drop Spinnaker pipeline for the new microservice which should cover the publish of the microservice versions and all the deliverables towards Product CI.
  - Select eea application in Spinnaker
  - Click on Pipelines tab
  - Click Create button
  - Create new pipeline with the following settings:
  - Type = Pipeline
  - Pipeline Name = < EEA microservice name >-drop
  - Create From = Pipeline
  - Copy from = dummy-e2e-flow
  - Select the new pipeline from the list on the left side and click on Configure button
  - Select Configuration tab and click on the Automated Triggers section
  - Update Jenkins job to the drop Jenkins job given for the new EEA microservice (this job has to publish the new microservice version to the ARM drop repo)
  - Click Save Changes button
- Release pipeline has to be similar for each service, but the triggering Jenkins job should be the microservice release job in Jenkins of your service.
- Inform Product CI team about the new drop pipelines in Spinnaker.

Please note: the monitoring of the Spinnaker drop pipeline is microservice responsibility! It is advisable to create an email notification for the 'EEA Application Staging' stage, which would send an email notification in case the pipeline fails, thus the microservice team can act on failed pipelines. By default concurrent builds should be disabled for drop pipelines in Spinnaker to avoid flooding Product CI loops. In urgent cases this configuration can be changed at the execution options section in Spinnaker for some triggers, but right after that this has to be disabled!

### Create Spinnaker triggers  - **Product CI Team**

- Connect the drop Spinnaker pipeline for the new microservice to EEA Application Staging PRA by setting up automated trigger for [eea-application-staging-wrapper](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-application-staging-wrapper) (it's a linear pipeline that wraps eea-aplication-staging one for the opportunity to comply FIFO (first IN first OUT) during prioritization) Spinnaker pipeline.
  Configure "Conditional on Expression : ${trigger.properties['CHART_VERSION'].contains("+")} " This condition ensures that this stage will run only for release version.
- Connect the drop Spinnaker pipeline for the new microservice to EEA Application Staging Non PRA by setting up automated trigger for [eea-application-staging-non-pra](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-application-staging-non-pra) Spinnaker pipeline. Configure "Conditional on Expression : ${trigger.properties['CHART_VERSION'].contains("-")} " This condition ensures that this stage will run only for non release version.

### Add new service to component ownership page at JIRA   -  **Microservice Team**

- ScM of the microservice team has to fill in the [component ownership page at JIRA](https://eteamproject.internal.ericsson.com/projects/EEAEPP?selectedItem=com.atlassian.jira.jira-projects-plugin:components-page) with the requested data for the new service.
- e.g. for the description field

`component_helm_name:"eric-eea-analysis-system-overview-install" | cxc/cxd:"CXD 101 0849" | drop_pipeline:"spotfire-dashboard-drop" | team_mailing_list:"PDLCRUMINS@pdl.internal.ericsson.com" | jira_team_label:"Insights_Dashboard" | project:"EEA" | track:"EEA4"`

### Testing  -  **Product CI Team**

- Testing connection sequence between the drop pipeline and [eea-application-staging-wrapper](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-application-staging-wrapper), [eea-application-staging](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-application-staging) Spinnaker pipelines
  can be done with a new microservice drop version.

### Integrate first + version of the service

- As the first + version of the service is available it has to be removed from the [exemption list](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/technicals/input_sanity_check.Jenkinsfile#558) of the upgrade test report validation at input sanity.

#### A remark:

eea-application-staging triggers already configured EEA Application Staging loops.
**EEA Application Staging Loops** - for Non - PRA uS the sequential order is as follows:

- Sanity Check
- Prepare Baseline
- EEA App Staging Nx1
- EEA App Staging Batch
- Publish Baseline

## Add new CRD to Product CI

### Inform Product CI team about the needed change in Product CI.  -  **Microservice Team**

- Clone template task: [EEAEPP-49206](https://eteamproject.internal.ericsson.com/browse/EEAEPP-49206)
- Inform the team via e-mail to proceed EEA4 Product CI <PDLEEA4PRO@pdl.internal.ericsson.com>

### Implement change in product CI  -  Product CI Team

- Implement the necessary changes based on the cloned template task.
- CI clusters have the hardware requirements for the new microservice (vCPU, memory, storage). If there are insufficient resources, please order the required infrastructural changes. (free resources can be checked at the k8s cluster health dashboard at Grafana)
- Perform the necessary changes in the install/upgrade/rollback scripts if there is any.
- Implement environment changes:  **Please be aware that it can take weeks** if hardware resource not available or in case of complex install/upgrade/rollback/environment procedure. In ideal cases the task can be closed in days.

### Update ruleset file in cnint  -  **Microservice Team**

- [Ruleset file in cnint repository](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/ruleset2.0.yaml) has to be updated, k8s-test-crd rule should contain tasks for setting the new CRD's name and path.
E.g. for sip-tls-crd

```
    - task: set-sip-tls-crd-name
      cmd: echo "eric-sec-sip-tls-crd" > .bob/var.crd-name
    - task: set-sip-tls-crd-path
      cmd:
        - find .bob/chart -name 'eric-sec-sip-tls-crd-*tgz' > .bob/var.crd-path
```

### Ensure that new CRD is in [ADP drop repository](https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-gs-all-helm/).  -  **Microservice Team**

- Check that the version of your CRD which has been added to the integration helm chart is available at the ADP drop repository in ARM.

### +1 for ruleset change  -  **Product CI Team**

- When the above conditions are met, the Code Review +1 can be given to the ruleset change commit. This change will trigger ruleset validation pipelnie in Product CI and if it passes your change will be merged automatically tos the master.

Please note: For CRDs there won't be a dedicated drop pipeline in Spinnaker towards Product CI. New version of a CRD will reach product CI when the relevant ADP generic service will trigger roduct CI with a new version containing the updated CRD version.

## Rename EEA microservice

To be able to rename you microservice the drop pipeline of the microservice has to be green and latest version of your microservice has to be part of the EEA integration helm chart.

Renaming of the microservice has 2 steps:

- First you have to prepare a new drop version with your drop pipeline from the microservice with the new name. This will trigger the Product CI but it will fail at the prepareBaseline phase as the integration helm chart contains a different name.
- After that prepare a commit for updating manually the integration helm chart. In this commit you have to update the name of the microservice and update the version to the latest drop version. When CR+1 is given for this change by Product CI team eea-app-baseline-manual-flow will validate your change in Product CI using the new drop version and the new microservice name. If the prerequisite to have a green drop has been fullfilled this pipeline should update the integration helm chart with the new microservice name and version automatically and later drop pipelines can pass the prepareBaseline phase again.

## Remove ADP/EEA microservice from Product CI

### Inform product CI team about the needed change in product CI. (EEA service)  -  **Microservice Team**

- Clone template task: [EEAEPP-49206](https://eteamproject.internal.ericsson.com/browse/EEAEPP-49206)
- Inform the team via e-mail to proceed EEA4 Product CI <PDLEEA4PRO@pdl.internal.ericsson.com>

### Prepare and schedule the change in product CI  -  **Product CI Team**

- Prepare and schedule (before/after disabling microservice in chart.yaml) for the necessary changes based on the cloned template task.
- Changes in the install/upgrade/rollback scripts if there is any.
- Environment changes

### Disable microservice in the [Chart.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/eric-eea-int-helm-chart/Chart.yaml/).  -  **Product CI Team**

### Remove automated trigger from Spinnaker pipeline by removing the stage where the trigger was set.  -  **Product CI Team**

- For EEA microservices remove the dedicated drop Spinnaker pipeline of the microservice. (< EEA microservice name >-drop)
- For ADP GSs Spider team has to be contacted as it’s done at addition via JIRA ticket.

### Perform all changes in product CI  -  **Product CI Team**

- Changes in the install/upgrade/rollback scripts if there is any.
- Environment changes
