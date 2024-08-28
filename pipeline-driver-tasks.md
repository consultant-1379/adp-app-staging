# Product CI Operations tasks for pipeline drivers

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Weekly driver rotation

* Weekly [driver rotation](https://eteamspace.internal.ericsson.com/display/ECISE/CI+operations+-+support+rotation)
* At the beginning of the week, the driver should also assign the [CI Operations support driver role](https://eteamproject.internal.ericsson.com/browse/EEAEPP-53241) to themselves in JIRA.

## Driver Checklist

A quick checklist with the most important tasks

|                 When                 |                                                 Task                                                 |                                                                                           Links                                                                                       |
|--------------------------------------|------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Beginning of the week                | Assign the CI Operations support driver role to yourself                                             | * <https://eteamproject.internal.ericsson.com/browse/EEAEPP-53241>                                                                                                                        |
|                                      | Review the results of [docker-image-versions-autouplift-weekly-loop job](file:///tmp/16.html#8-checking-docker-image-versions-autouplift-weekly-loop-job-results) | * <https://seliius27190.seli.gic.ericsson.se:8443/job/docker-image-versions-autouplift-weekly-loop/>                          |
| 3 times per day (Morning, Noon, EoB) | Check clusters status, remove cluster from pool if needed and create JIRA ticket for reinstallation) | *<http://eea4-application-dashboard.seli.gic.ericsson.se/view/ci-resources>* *<https://seliius27190.seli.gic.ericsson.se:8443/job/EEA4-cluster-info-collector/Product_5fCI_5fcluster_5finfos/>* <https://seliius27190.seli.gic.ericsson.se:8443/lockable-resources/> |
|                                      | Check ADP Dashboards | *<https://cicd-ng.web.adp.gic.ericsson.se/view/1/dashboard/1?columnFilter=eea>* <https://cicd-ng.web.adp.gic.ericsson.se/view/1/dashboard/2?columnFilter=EEA> |
|                                      | Check App staging ADP runs | *<https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-adp-staging>* <https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-application-staging> |
|                                      | Create or comment JIRA tickets for the failed runs, retrigger the run if possible (e.g. temporary env issues) | * <https://eteamproject.internal.ericsson.com/secure/RapidBoard.jspa?rapidView=14674> |
|                                      | Check requests in mail ||
|                                      | Handle review requests from dev teams ||
|                                      | Check [‘CI CoP’ channel](https://teams.microsoft.com/l/channel/19%3a023a58c23b184852b8bb1c2c27677517%40thread.skype/EEA4%2520CI%2520CoP?groupId=940ac9a1-d4ab-41e1-872f-2a021caa4922&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f) and Prod CI mail list ||
|                                      | Check Prod CI Drivers & CDM chat ||
|                                      | Notify the Prod CI team in [Driver channel](https://teams.microsoft.com/l/channel/19%3acad1b85796e4400996f54c65c32aee9f%40thread.tacv2/Driver%2520channel?groupId=bc9ea19b-97da-479d-903f-9b003bcba6a4&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f), if necessary ||
|                                      | Check Jenkins jobs, abort the stucked ones (e.g. something is onging for more than 1 day) | * <https://eteamproject.internal.ericsson.com/secure/RapidBoard.jspa?rapidView=14674> |
| + at EoB                             | Validate tickets on "Product and Test Baseline issues" board ||

## Driver Tasks

### 1. Monitoring notification channels

We have many notification channels for different purposes, the most important are listed below Product CI pipeline driver shall monitor these channels to be able to inform the team in case of issues quickly:

**Channels/Chat for teams**:

* [EEA4 CI General channel](https://teams.microsoft.com/l/team/19%3ae96debee66964644aa7c042fa2393365%40thread.tacv2/conversations?groupId=bc9ea19b-97da-479d-903f-9b003bcba6a4&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f) - general channel for CI Team
* [Driver channel](https://teams.microsoft.com/l/channel/19%3acad1b85796e4400996f54c65c32aee9f%40thread.tacv2/Driver%2520channel?groupId=bc9ea19b-97da-479d-903f-9b003bcba6a4&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f) - CI Team's internal channel about the driving
* [‘CI CoP’ channel](https://teams.microsoft.com/l/channel/19%3a023a58c23b184852b8bb1c2c27677517%40thread.skype/EEA4%2520CI%2520CoP?groupId=940ac9a1-d4ab-41e1-872f-2a021caa4922&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f) - communicate issues that impactgs other teams here (not integration issues)
* [Integration issues and blockers channel](https://teams.microsoft.com/l/channel/19%3A4afbe38b69804512b9604ceaae089b32%40thread.skype/Integration%20issues%20and%20Blockers?groupId=940ac9a1-d4ab-41e1-872f-2a021caa4922&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f) - communicate integration issues and blockers for EEA organization
* Prod CI Drivers & CDM chat
* Driver should monitor [ADP Teams channels](https://teams.microsoft.com/l/team/19%3aed0a261d69df4fcda3e700b9b0938d3c%40thread.skype/conversations?groupId=f7576b61-67d8-4483-afea-3f6e754486ed&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f)  to inform the team about important changes or in case of ADP tool issue you can ask help
* The same as [EWS support Teams channels](https://teams.microsoft.com/l/team/19%3af459caa2d305490ca0adf356b356a44e%40thread.tacv2/conversations?groupId=360b371e-68bf-4848-890a-0c398e5142b4&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f) or [Ericsson Web Services Support page](https://confluence.lmera.ericsson.se/pages/viewpage.action?spaceKey=AD&title=Support) for help.

**Automatic notifications**:

* [Spinnaker - ADP notifications](https://teams.microsoft.com/l/channel/19%3ac0ef0e9f08244c1b83e27358d4419a33%40thread.tacv2/Spinnaker%2520-%2520ADP%2520notification?groupId=bc9ea19b-97da-479d-903f-9b003bcba6a4&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f): issues with ADP staging pipeline - (obsolete, preferably use the [Application dashboard](#application-dashboard) instead)
* [Spinnaker - Batching notification](https://teams.microsoft.com/l/channel/19%3ad1a365ec7a13441d947e6c953459e664%40thread.tacv2/Spinnaker%2520-%2520Batching%2520notification?groupId=bc9ea19b-97da-479d-903f-9b003bcba6a4&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f) - the application staging PRA notification loop
* [Spinnaker / PublishBaseline notification](https://teams.microsoft.com/l/channel/19%3ae0ba4052081849da89825a037ca82b82%40thread.tacv2/Spinnaker%2520-%2520PublishBaseline%2520notification?groupId=bc9ea19b-97da-479d-903f-9b003bcba6a4&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f) - issues with the baseline publish at EEA App Staging pipeline
* [Ruleset Change(cnint) notification](https://teams.microsoft.com/l/channel/19%3a396a993ed66d4c7d9e88164daf5b192c%40thread.tacv2/Ruleset%2520Change(cnint)%2520notification?groupId=bc9ea19b-97da-479d-903f-9b003bcba6a4&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f) - ruleset changes always required +1 from a member of the CI team
* [Jenkins alerts](https://teams.microsoft.com/l/channel/19%3ace00451d0db54ed7bc0f985a2bb8e61e%40thread.tacv2/Jenkins%2520alerts?groupId=bc9ea19b-97da-479d-903f-9b003bcba6a4&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f) - issues with the Product CI Jenkins instances (e.g. seed job fails to generate a Product CI pipeline, this means that the newly merged Product Ci code change has an issue, and it can cause pipeline failures so these issues has to be reported for the team with high priority!)
* [CI clusters environment alerts](https://teams.microsoft.com/l/channel/19%3acaf4010f1e404ab08863288d10b029e0%40thread.tacv2/ELK%2520environment%2520alerts?groupId=bc9ea19b-97da-479d-903f-9b003bcba6a4&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f) - alarms of issues relate to Product CI test clusters
* [ELK environment alerts](https://teams.microsoft.com/l/channel/19%3acaf4010f1e404ab08863288d10b029e0%40thread.tacv2/ELK%2520environment%2520alerts?groupId=bc9ea19b-97da-479d-903f-9b003bcba6a4&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f) - alerts relate to ELK stack nodes, e.g. high CPU load, low free memory, high inode usage, high disk space usage, host is down, etc. [guide for troubleshooting](https://eteamspace.internal.ericsson.com/display/ECISE/Troubleshooting+guide+for+Product+CI+ELK+cluster)
* [Jenkins build nodes environment alerts](https://teams.microsoft.com/l/channel/19%3aee5322f666fd45d28c95b44e75321019%40thread.tacv2/Jenkins%2520build%2520nodes%2520environment%2520alerts?groupId=bc9ea19b-97da-479d-903f-9b003bcba6a4&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f) - notification relate to Jenkins build nodes, e.g. high CPU load, low free memory, high inode usage, high disk space usage, host is down, etc.

### 2. Monitoring Spinnaker pipelines

* [EEA application at Spinnaker](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/)
* [Our most important Spinnaker pipelines, filtered here](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-adp-staging,eea-application-staging,eea-application-staging-non-pra,eea-application-staging-wrapper,eea-product-ci-code-manual-flow,eea4-documentation,eric-eea-utf-application-drop)
* Product CI driver's task is to **filter out environment and Product CI code related issues from the failures**.
* If the driver can't fix these alone, escalate them towards Product CI team or in case of external environment issues towards EEA Environment team.
  * **Every issue that happens at least once, should be investigated with a ticket**, even if it looks like an environment issue.

#### 2.1. [eea-adp-staging pipeline](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-adp-staging)

**Important! ADP issues should be prioritized in the organization as we have deadline for feedback and fix for ADP!**

* **Priority**: **Highest**
* **Monitor**:
  * [ADP General Services (GS) dashboard](https://cicd-ng.web.adp.gic.ericsson.se/view/1/dashboard/1?columnFilter=EEA)
  * [ADP Reusable Services (RS) dashboard](https://cicd-ng.web.adp.gic.ericsson.se/view/1/dashboard/2?columnFilter=EEA)
  * [Spinnaker pipeline](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-adp-staging)
* **Actions**:
  * If a service version **turns red** in the ADP dashboards
    * do the **root cause analysis from EEA side** - see [details](#3-root-cause-analysis-and-jira-ticket-creation).
      * check if issue for this ticket already exists in the [integration issue board in JIRA](https://eteamproject.internal.ericsson.com/secure/RapidBoard.jspa?rapidView=14674) - with the help of [jira queries](#31-jira-queries-for-driving)
      * if no ticket exists for this issue, **open an integration ticket** for the relevant EEA team.  See [details](#3-root-cause-analysis-and-jira-ticket-creation).
      * If a ticket already exists, **comment the new occurence** with link to that ticket
* **Notify**:
  * When the ticket is created, notify the relevant team:
    * development team via [Integration issues and Blockers channel](https://teams.microsoft.com/l/channel/19%3A4afbe38b69804512b9604ceaae089b32%40thread.skype/Integration%20issues%20and%20Blockers?groupId=940ac9a1-d4ab-41e1-872f-2a021caa4922&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f) by tagging their CI expert or ScM.
    * In case of issue rooted to RV please use [this channel](https://teams.microsoft.com/l/channel/19%3ad0de7c3e1af14fb0b086477483ac508a%40thread.skype/EEA4%2520RV%2520and%2520CI?groupId=940ac9a1-d4ab-41e1-872f-2a021caa4922&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f) and @RV tag.
* **Follow up**:
  * When the **problem is fixed, driver has to rerun EEA stage from the ADP E2E Spinnaker pipeline**. To do this:
    * open the **Spinnaker pipeline by clicking into the red box** at the ADP dashboard
    * select the **failed EEA stage, and select  the 'Actions'** button below
    * then click on **'Restart EEA APP Staging'** - *Note*: Permissions for this is **limited**, if you don't have rights to perform this action Product CI PO or ScM shall contact [ADP SPOC](chunhui.liu@ericsson.com) to grant acces for you.*
  * If after 2 failed run we have 1 successful run in ADP staging pipeline, the ticket priority can be lowered to Critical
  * If an existing General blocker test issue is updated with a TR tag, the priority can be lowered

![Screenshot: restart from the ADP board](https://eteamspace.internal.ericsson.com/download/attachments/1373121790/red_on_adp_board.png)

![Screenshot: Open failed_stage](https://eteamspace.internal.ericsson.com/download/attachments/1373121790/failed_stage.png)

![Screenshot: Restart EEA APP Staging stage](https://eteamspace.internal.ericsson.com/download/attachments/1373121790/restart_stage.png)

**Notes**:

* In case of failures ADP development teams can reach out to Product CI Team to ask for information about the failure. This can happen via email to our mailing list, or via [this MS Teams channel](https://teams.microsoft.com/l/channel/19%3a84ee07cc2ec84f778e179a2b62512f2a%40thread.skype/CICD%2520-%2520Microservice%2520and%2520Staging%2520Operations?groupId=f7576b61-67d8-4483-afea-3f6e754486ed&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f). Product CI pipeline driver has to monitor these channels and inform ADP side about actions taken on these failures on our side.
* Continuos Delivery Manager should follow-up these issues with the teams and should ensure that these are fixed as soon as possible.
  * This role is fulfilled by Balázs Németh <balazs.nemeth@ericsson.com> at the Release Program Team at the moment.

#### 2.2. [eea-application-staging](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-application-staging)

* **Priority**: **Very High**/Low, depending on the trigger
  * If the trigger is an
    * **ADP service**
    * or **any µService with PRA** (+) version, the issue should be handled as an eea-adp-staging issue** by the Product CI pipeline driver
    * trigger can be seen in Spinnaker pipeline in the "Parent Execution lines"
    * version can be seen by opening the Execution Details dropdown

![Screenshot: Check parent execution](https://eteamspace.internal.ericsson.com/download/attachments/1373121790/parent_execution.png)

* **Monitor**: [Spinnaker pipeline](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-application-staging])
* **Actions**:
  * In case of **ADP or PRA** trigger:
    * do the **root cause analysis from EEA side** - see [details](#3-root-cause-analysis-and-jira-ticket-creation).
      * check if issue for this ticket already exists in the [integration issue board in JIRA](https://eteamproject.internal.ericsson.com/secure/RapidBoard.jspa?rapidView=14674) - with the help of [jira queries](#31-jira-queries-for-driving)
      * if no ticket exists for this issue, **open an integration ticket** for the relevant EEA team.  See [details](#3-root-cause-analysis-and-jira-ticket-creation).
      * If a ticket already exists, **comment the new occurence** with link to that ticket
  * In case of **other trigger**:
    * if the root cause is external (not related to Product CI code or environment) **no action is needed from Product CI Team, µS dev team should handle it**
      * If the µS dev team finds an issue unrelated to their drop they should inform CI CoP via [Teams channel](https://teams.microsoft.com/l/channel/19%3A4afbe38b69804512b9604ceaae089b32%40thread.skype/Integration%20issues%20and%20Blockers?groupId=940ac9a1-d4ab-41e1-872f-2a021caa4922&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f)
        * This case the driver from Product CI team should check if we have an open ticket for the issue at the integration [issue board](https://eteamproject.internal.ericsson.com/secure/RapidBoard.jspa?rapidView=14674) as described in the previous chapters
        * If it's not yet at the board the driver should create a new integration ticket. See [details](#3-root-cause-analysis-and-jira-ticket-creation).
    * If the problem is caused by the Product CI pipeline itself driver should notify the team and work on the fix, these fixes should have **high priority in the team**. Product CI team shall be notified via [team channel at MS Teams](https://teams.microsoft.com/l/channel/19%3ae96debee66964644aa7c042fa2393365%40thread.tacv2/General?groupId=bc9ea19b-97da-479d-903f-9b003bcba6a4&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f) with tagging the team (@EEA4 CI)!
    * Whenever the driver notices that product upgrade time changes drastically (eg.: new logics were introduced to the pipeline), timing for the CPI build stage shall be updated to ensure that CPI build stage finish approximately together with the upgrade stage in application staging pipeline at Spinnaker, not earlier or later. With this we can ensure that doc-build resource is not locked unnecessarily and application-staging pipeline length is kept short. Change shall be done in Spinnaker updating the Wait stage before CPI build, wait has to be given in seconds for the stage. See picture below.

![Screenshot: Wait stage](https://eteamspace.internal.ericsson.com/download/attachments/1373121790/wait_stage.png)

* **Notify**:
  * When the ticket is created, notify the relevant team:
    * development team via [Integration issues and blockers channel](https://teams.microsoft.com/l/channel/19%3A4afbe38b69804512b9604ceaae089b32%40thread.skype/Integration%20issues%20and%20Blockers?groupId=940ac9a1-d4ab-41e1-872f-2a021caa4922&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f) by tagging their CI expert or ScM.
    * In case of issue rooted to RV please use [this channel](https://teams.microsoft.com/l/channel/19%3ad0de7c3e1af14fb0b086477483ac508a%40thread.skype/EEA4%2520RV%2520and%2520CI?groupId=940ac9a1-d4ab-41e1-872f-2a021caa4922&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f) and @RV tag.
* **Follow up**:
  * See [Rerunning EEA Application staging pipelines](#221-rerunning-eea-application-staging-pipelines) below
  * If an existing General blocker test issue is updated with a TR tag, the priority can be lowered

##### 2.2.1. Rerunning EEA Application staging pipelines

Driver has to rerun EEA Application staging pipelines from **different stages depending on the trigger**:

* If [eea-application-staging](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-application-staging) pipeline is triggered by a **µService drop** pipeline (e.g. [correlator drop pipeline](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?q=corr&pipeline=eric-oss-correlator-drop)
  * click on the parent drop pipeline
  * and select the failed 'EEA App staging' Spinnaker stage,
  * then click on 'Actions' and then on 'Restart EEA-App Staging' button.

![Screenshot: Rerun µService drop](https://eteamspace.internal.ericsson.com/download/attachments/1373121790/rerun_microservice_drop_1.png)

[<https://eteamspace.internal.ericsson.com/download/attachments/1373121790/rerun_microservice_drop_2.png>)

* If the failed run is triggered by  [eea-app-baseline-manual-flow pipeline](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?q=manual&pipeline=eea-app-baseline-manual-flow) **you must** retrigger from [eea-application-staging-wrapper](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-application-staging-wrapper) by rerunning the failed execution of the **wrapper pipeline**:
  * Start from the [eea-app-baseline-manual-flow pipeline], here click on the failed run
  * at the bottom of the dropdown section click **View Pipeline Execution**
  * Here go to the eea-application-staging-wrapper stage
    * under the failed execution on the right side there is a refresh arrow icon (*hover text: Re-run execution with same params*)
    * re-run the failed execution by clicking this arrow

![Screenshot: Rerun manual trigger](https://eteamspace.internal.ericsson.com/download/attachments/1373121790/rerun_manual1.png)

![Screenshot: Rerun manual trigger](https://eteamspace.internal.ericsson.com/download/attachments/1373121790/rerun_manual2.png)

* If the trigger came from [eea-adp-staging pipeline](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?q=ad&pipeline=eea-adp-staging) you can retrigger from [eea-application-staging-wrapper](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-application-staging-wrapper) pipeline with similar steps as in the previous point.

For a better understanding of triggers and pipelines check this [flowchart](#our-pipelines-flowchart).

#### 2.3. [Metabaseline pipeline](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-product-ci-meta-baseline-loop)

[eea-product-ci-meta-baseline-loop](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-product-ci-meta-baseline-loop) is for validating test environment changes in Product CI. (e.g. UTF drops, dataset, etc.) Driver has to **create an issue if RV specifically asks**. It's **RV**-s task to **monitors** this pipeline.

* **Priority**: Low, only when asked
* **Monitor**: [eea-product-ci-meta-baseline-loop](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-product-ci-meta-baseline-loop)
* **Actions**:
  * If RV specifically asks, create [JIRA issue](#331-ticket-creation-for-test-issues) based on the data given by RV
    * Detected at parameter should be **EEA Metabaseline loop**
  * **Product CI driver is not responsible for doing the RCA** in this case.
  * If **UTF Fails for 3 days** in a row, all ticket which blocks the utf delivery should be set to **blocker**!
* **Follow up**:
  * If the issue turns out to be a **baseline issue**, RV reports it at the [Integration issues and Blockers channel](https://teams.microsoft.com/l/channel/19%3A4afbe38b69804512b9604ceaae089b32%40thread.skype/Integration%20issues%20and%20Blockers?groupId=940ac9a1-d4ab-41e1-872f-2a021caa4922&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f), and the ticket priority should be raised to **General blocker**!

##### 2.3.1 Rerunning metabaseline loop pipeline

How to the `eea-product-ci-meta-baseline-loop` Spinnaker pipeline can be restarted depends on the parent trigger.

* for drops (eric-eea-utf-application-drop) eea-product-ci-meta-baseline-loop must be retriggered from the drop pipeline
* for other cases it can be restarted from the eea-product-ci-meta-baseline-loop itself.

#### 2.4 Spinnaker issues

* In cases when something is not right there (e.g the tile is red after successful retrigger) find the "?" icon on the up right corner of the dasboard to create ticket for the ADP team.
* [EWS Spinnaker FAQ](https://eteamspace.internal.ericsson.com/display/EWS/Spinnaker+FAQ)

### 3. Root cause analysis and JIRA ticket creation

* Pipeline driver has to decide whether the failure is related to a
  * **[deployment problem](#32-deployment-issues)** during install or upgrade,
  * or it occurred during E2E validation phase: [test issue](#32-deployment-issues)
  * **environment issue**

#### 3.1 Jira queries for driving

When the driver finds an issue, it is mandatory to check on the driver board whether a ticket has already been created. To to this, they can use jira queries (JQL).

* Atlassian documentation for JQL: <https://support.atlassian.com/jira-service-management-cloud/docs/use-advanced-search-with-jira-query-language-jql/>

##### 3.1.1. Typical fields and values that can be useful in the search:

Notes:

* For custom (text search fields) the `=` operator won't work, instead use the `~` "contains" operator.
* Query terms in JIRA are case insensitive

fields (and values) most commonly used in queries:

* `summary`: search in title of the ticket (with `~`)
* `description`: search in the description of the ticket (with `~`)
* `comment`: search in the comments (with `~`)
* `issuetype`: eg: `"Integration Issue"` - find integration issues
* `"Detected at"`: search by detected at, eg: `"EEA Application Staging Nx1 Loop"`
* `"Affected Area"`, eg: `"Product CI"`
* `resolution`: eg: `Unresolved`
* `label`: eg: `general_blocker`

* `ORDER BY` - order of the results
  * eg: `createdDate DESC` - by creation date, descending order
  * eg: `"Date of last Progress status update" createdDate DESC`
  * eg: `priority`

##### 3.1.2. Jira Filters

Open [General blocker]<https://eteamproject.internal.ericsson.com/issues/?filter=178822> tickets with integration issues, where affected area is Product CI

##### 3.1.3. JQL Examples

* Find open Integration issues, where ticket title (summary) **contains specific text** (eg: microsesrvice name - eric-sec-access-mgmt), issue type is integration issue, and affected area is Product CI.

`summary ~ "eric-sec-access-mgmt" AND issuetype = "Integration Issue" AND "Affected Area" = "Product CI" AND resolution = Unresolved ORDER BY createdDate DESC`

* Find open Integration issues, where ticket title **description or comment contains a specific text** (eg: jenkins job execution, spinnaker ID, "without TR tag" log section, etc.). This is useful to check if that specific occurence has already addressed somewhere:

`(description ~ "eea-adp-staging-adp-nx1-loop/8434/" OR comment ~ "eea-adp-staging-adp-nx1-loop/8434/") AND issuetype = "Integration Issue" AND "Affected Area" = "Product CI" AND resolution = Unresolved ORDER BY createdDate DESC`

* Find open Integration tickets, that contains bracketed notation (eg:**general blockers**, that have [G] in summary - *brackets must be escaped with* `\\`):

`summary ~ "\\[G\\]" AND issuetype = "Integration Issue" AND "Affected Area" = "Product CI" AND resolution = Unresolved ORDER BY createdDate DESC`

* Search via labels - Find **general blockers via label**

`labels in (general_blocker) AND issuetype = "Integration Issue" AND "Affected Area" = "Product CI" AND resolution = Unresolved ORDER BY createdDate DESC`

* Find open integration issues that are **detected at** a specific pipeline:

`issuetype = "Integration Issue" and "Detected at" = "EEA Application Staging Nx1 Loop"  and "Affected Area" = "Product CI" and resolution = "Unresolved"  ORDER BY createdDate DESC`

#### 3.2. Deployment issues

* You can use the [flowgraph view](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-product-upgrade/999/flowGraphTable/) in Jenkins to find the failed pipeline step(s).
  * If an install or upgrade step failed you have to open the relevant log file among the Jenkins artifacts (each Jenkins stage has it's own log file, with the same name as the stage in Jenkins) and look for an error in the log.
  * For **failed services, a separate log file** is added for easier understanding which service had the problem during the deployment, but if you can't find the problematic service from this you have to open the **cluster logs** collected from the namespaces of the test clusters.
    * These are available at [ARM](https://arm.seli.gic.ericsson.se/artifactory/proj-eea-reports-generic-local/clusterlogs/) for each run till 30 days, the name of the log file shows the namespace name.
    * In the .tgz file, look for the **pods.txt in describe/PODS/** directory for the summary of pod(s) state. The log for **each pod is available in YAML format** in the same folder.
* **Important! The driver has to rule out cluster issues**. If a pipeline failure occurs multiple times (especially - but not only - in case of strange timeouts, docker issues), the driver **must first check** if it happened on the same cluster.
If so, they should check whether its cluster specific. If the issue is proven to be cluster-related, they have to remove the cluster from the pool.
* All install process executes `checkIfNameSpaceExists` ci_shared_libraries's function which calls `check-namespaces-not-exist` bob rule from `cnint` repo. This checks if any of utf-service, eric-eea-ns or eric-crd-ns namespace exists on the cluster before installation.
  * If any of the above namespace exists on the cluster, the install process will be aborted and the cluster's label will get `faulty-non-empty-ns` value to avoid similar situation again.
  * This situation can be occured, e.g.:
    * after the Jenkins application restart
    * after the Jenkins - 'Manage Jenkins' - 'System' configuration is executed without reserving the [`resource-relabel`](https://seliius27190.seli.gic.ericsson.se:8443/lockable-resources/resource-relabel) lockable resource [here](https://seliius27190.seli.gic.ericsson.se:8443/lockable-resources/)
    * when 2 different pipelines were started on the same cluster at the same time for any reason
  * In this case a notification email will be sent to the Teams `Driver channel` and the current driver should check what happened there.

##### 3.2.1. Ticket creation for deployment issues

**Mandatory parameters**:

* **Project**: EEA Development Lifecycle
* **Issue Type**: Integration Issue
* **Priority**: Blocker by default (*if issue blocks at least one service from integrating*)
* **Summary** (*"title of the ticket"*):
  * add to the **summary field the name of the failed service**,
    * in case one service failed the integration: `<service name and version> <stage>` Failed service: `<service that caused the faliure>` - eg: "*eric-tm-tls-proxy-ev: 2.7.0-22 INSTALL Failed service: eric-data-search-engine-curator*"
    * in case several services: `<service name and version> <stage>` FAILED due to multiple services, eg: "*eric-data-search-engine: 11.5.0-10 INSTALL FAILED with multiple services*"
* **Labels**:EEA4
* **Affected Area**: Product CI
* **Description**:
  * Copy the url of the relevant the **Jenkins log** from the failed run
  * Copy the info section from the page of the failed Jenkins job (which µService version, Spinnaker URL, Locked cluster, etc..)
  * Copy relevant section of the logfile, that contains the error and the failed services
* **Cluster** - Copy the cluster name from the failed job page
* **EEA Tribe/Team**:
  * for issues caused by **EEA µServices** (ones that start with eric-eea-...), root ticket to the **relevant µService team**, according to [Product CI loop triggers](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/refs/heads/master/product-ci-loop-triggers.md)
  * For Product CI or environment issues create blocker ticket assigned to Product CI team.
* **Component/s** (*At the root cause analysis tab*) - add the failed components (that was added to the summary also) here
  * [EEA4 component ownership](https://eteamspace.internal.ericsson.com/display/EEAEP/EEA+4+Microservices) maintained by Release Handling Team
  * [Filterable components list in JIRA](https://eteamproject.internal.ericsson.com/projects/EEAEPP?selectedItem=com.atlassian.jira.jira-projects-plugin:components-page)

**Optional parameters**:

* **Detected at** (Which part of the pipelines the problem occured):
  * Install: legacy for 18x, not used in EEA4
  * Build: legacy for 18x, not used in EEA4
  * Upgrade: legacy for 18x, not used in EEA4
  * EEA Application Staging Nx1 Loop
    * in Spinnaker: **Staging Nx1 stage**, usually at [eea-application-staging-non-pra](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-application-staging-non-pra)
    * related jenkins job: [eea-application-staging-nx1](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-nx1/)
  * EEA Application Staging Slow Loop:
    * in Spinnaker: [eea-application-staging pipeline](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-application-staging) / Staging Batch step
    * related Jenkins job: [eea-application-staging-batch job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-batch/)
  * ADP Staging Nx1 Loop:
    * In Spinnaker: [eea-adp-staging pipeline](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-adp-staging) / EEA ADP Nx1 Loop step
    * related Jenkins job: [eea-adp-staging-adp-nx1-loop](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-adp-staging-adp-nx1-loop/)
  * ADP Staging Slow Loop
    * [eea-adp-staging pipeline](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-adp-staging) / EEA Application Staging step / Staging Batch step
    * related Jenkins job: [eea-application-staging-batch](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-batch)
    * this only runs at "+"" versions of ADP services, otherwise Nx1 runs.
  * EEA Metabaseline Loop:
    * Spinnaker: several stages of [eea-product-ci-meta-baseline-loop](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?q=meta&pipeline=eea-product-ci-meta-baseline-loop)
    * related Jenkins jobs: eea-product-ci-meta-... jobs, eg: [eea-product-ci-meta-baseline-loop-prepare](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-ci-meta-baseline-loop-prepare), [eea-product-ci-meta-baseline-loop-test](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-ci-meta-baseline-loop-test/)

**Example**:

![Screenshot: Deployment issue ticket](https://eteamspace.internal.ericsson.com/download/attachments/1373121790/deployment_ticket.png)

#### 3.3. E2E validation (UTF test) issues

* Not all of the executed E2E validation tests can fail the pipeline, as some of them are ignored because of known issues with TR tags in UTF, or some of them are not yet in decisive status in UTF. For the pipeline drivers **only the decisive tests without TR tags are relevant** as these can fail the pipeline.
* To find the failed test cases, look for the **failed Jenkins stage** first and then open the relevant [UTF console log](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-product-upgrade/974/artifact/utf_decisive_nx1_staging_cucumber_upgrade.log) among the Jenkins artifacts.
  * In this search for the following string: '**without TR tags**' At this section you will see list of the failed TCs. You have to **add name of the failed scenario to the summary of the opened integration ticket** and paste this list to the description field beside the link for the full log file.
  * Please note, that there can be more than one "without TR tags" section in a logfile
* RVRobot tests are handled in a similar way as UTF tests in our pipelines, TCs with decisive label in the package can fail our pipelines but they can be TR tagged in the package to be ingnored during the test execution. In case of RVRobot related failures similar integration tickets has to be opened in JIRA as for UTF related problems.

```
06/22-14:39:16.031 [main] INFO ParallelSuiteTestNGCucumberTests:87 init - ==============================================================================
06/22-14:39:16.032 [main] INFO ParallelSuiteTestNGCucumberTests:88 init - Number of Scenarios with unknown issues (without TR tags): 5
Failed Scenario without TR tag: gui_aggregator.feature/GUI aggregator PM counter check - OWNER:RV
Failed Scenario without TR tag: gui_aggregator.feature/GUI aggregator PM counter check - OWNER:RV
Failed Scenario without TR tag: gui_aggregator.feature/GUI aggregator PM counter check - OWNER:RV
Failed Scenario without TR tag: gui_aggregator.feature/GUI aggregator PM counter check - OWNER:RV
Failed Scenario without TR tag: gui_aggregator.feature/GUI aggregator PM counter check - OWNER:RV
```

* Further HTML report available at the Jenkins run page from UTF: [HTML report about UTF run](http://seliics02376.seli.gic.ericsson.se:9999/commonci/ci_logs/jenkins-eea-application-staging-nx1-6541/1016541_1/report_decisive_and_nx1_and_staging_and_not_onlyUpgrade_and_not_tc_under_development/extent_report.html), [HTML report summary](http://seliics02376.seli.gic.ericsson.se:9999/commonci/ci_logs/jenkins-eea-application-staging-nx1-6541/1016541_1/report_decisive_and_nx1_and_staging_and_not_onlyUpgrade_and_not_tc_under_development.html)

* [Dedicated channel for reporting UTF issues](https://teams.microsoft.com/l/channel/19%3A7fc33271247d4fe79675cfcb5e460a30%40thread.skype/UTF%20-%20Automation%20Services%20QnA%20n%20Potential%20Issues?groupId=d5a4ea50-7446-4fff-910b-bdc220c83c35&tenantId=)

* [Dedicated channel for reporting RVRobot issues](https://teams.microsoft.com/l/channel/19%3A01f4f6b84aca482eafba21ab6da9b268%40thread.skype/Robot%20-%20Automation%20Services%20QnA%20n%20Potential%20Issues?groupId=d5a4ea50-7446-4fff-910b-bdc220c83c35&tenantId=)

##### 3.3.1. Ticket creation for test issues

###### Mandatory parameters

* **Project**: EEA Development Lifecycle
* **Issue Type**: Integration Issue
* **Priority**: Blocker by default (*if issue blocks at least one service from integrating*)
  * **Note**: If an alerady existing General blocker issue is updated with a TR tag, the priority can be lowered
* **Summary**:
  * If one test case failed: "Failed Scenario without TR tag: `<scenario>`" - eg: "*Failed Scenario without TR tag: gui_aggregator.feature/GUI aggregator PM counter check*"
  * If multiple test cased failed: "Multiple TCs failed: `<scenarios>`" eg: "*Multiple TCs failed: external_syslog_check.feature*"
* **Labels**:EEA4
* **Affected Area**: Product CI
* **Description**:
  * Copy the **Jenkins log** of the failed run
  * Copy the info section from the page of the failed Jenkins job (µService version, Spinnaker URL, Locked cluster, etc..)
  * Copy the relevant UTF log section (which contains the summary with the TR tags)
* **Cluster**: Copy the cluster name from the failed job page
* **EEA Tribe/Team**:
  * Ticket should be mapped to the team which is the owner of the test case. (**owner is listed for each failed TC in the UTF log summary**).
  * EEA teams and services mapping available:
    * [Product CI loop triggers](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/refs/heads/master/product-ci-loop-triggers.md) maintained by Product CI team,
    * [EEA4 component ownership](https://eteamspace.internal.ericsson.com/display/EEAEP/EEA+4+Microservices) - maintained by Release Handling Team
    * *Note - These 2 documents shall be merged in the future*
  * In case of **multiple owners please add all** the teams to the EEA Tribe/Team field.
  * For Product CI or environment issues create blocker ticket assigned to Product CI team.

**Optional parameters**:

* **Detected at** (Which part of the pipelines the problem occured):
  * Install: legacy for 18x, not used in EEA4
  * Build: legacy for 18x, not used in EEA4
  * Upgrade: legacy for 18x, not used in EEA4
  * EEA Application Staging Nx1 Loop
    * in Spinnaker: **Staging Nx1 stage**, usually at [eea-application-staging-non-pra](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-application-staging-non-pra)
    * related jenkins job: [eea-application-staging-nx1](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-nx1/)
  * EEA Application Staging Slow Loop:
    * in Spinnaker: [eea-application-staging pipeline](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-application-staging) / Staging Batch step
    * related Jenkins job: [eea-application-staging-batch job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-batch/)
  * ADP Staging Nx1 Loop:
    * In Spinnaker: [eea-adp-staging pipeline](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-adp-staging) / EEA ADP Nx1 Loop step
    * related Jenkins job: [eea-adp-staging-adp-nx1-loop](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-adp-staging-adp-nx1-loop/)
  * ADP Staging Slow Loop
    * [eea-adp-staging pipeline](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-adp-staging) / EEA Application Staging step / Staging Batch step
    * related Jenkins job: [eea-application-staging-batch](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-batch)
    * this only runs at "+"" versions of ADP services, otherwise Nx1 runs.
  * EEA Metabaseline Loop:
    * Spinnaker: several stages of [eea-product-ci-meta-baseline-loop](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?q=meta&pipeline=eea-product-ci-meta-baseline-loop)
    * related Jenkins jobs: eea-product-ci-meta-... jobs, eg: [eea-product-ci-meta-baseline-loop-prepare](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-ci-meta-baseline-loop-prepare), [eea-product-ci-meta-baseline-loop-test](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-ci-meta-baseline-loop-test/)

**Example**:

![Screenshot: Test issue ticket](https://eteamspace.internal.ericsson.com/download/attachments/1373121790/failed_scenario.png)

### 3.4. Environment issues

* In case of suspected environment issues (like timeouts and other unknown errors), driver should
  * Check if the job ran on a cluster with health warnings
  * If yes, it may be an environment issue, and cluster reinstall tickets are needed. See [Fixing the cluster](#54-fixing-the-cluster)

### 4. Jenkins management

#### 4.1. Jenkins user handling

* For this you'll need **Jenkins administrational** rights!
* At Jenkins main page select 'Manage Jenkins' button and then click on 'Configure Global Security' button.
* At the authorization matrix you need to find the user which you need to change or at the bottom add a new user with giving the E/// ID (signum).
* **Administrational rights can be given ONLY for Product CI team members and András Hóbár** from Environment Team. For **others only job create and configuration right is given, and if needed view configuration rights**.
* When the change is ready please click on **'Save' or 'Apply'** button.

#### 4.2. Lockable resource management

Our clusters are being handled in Jenkins as lockable resources. *Note* that for every lockable resource we also have matching credentials (kubeconfig files for handling the cluster) stored in Jenkins, so in case of adding/removing lockable resources, we also have to take care of its [credentials](#43-credentials-management)!

*Note* - If you need detailed description of Product CI cluster setup, its available [here](https://eteamspace.internal.ericsson.com/display/ECISE/Product+CI+cluster+setup).

##### 4.2.1. Add new lockable resource

* If Product CI gets new clusters, these need to be added to Jenkins as lockable resources
* Also, adding **new non Product CI team clusters to Jenkins is a task of the Product CI pipeline driver**
* for this you'll need **Jenkins administrational rights**!
* First go to [lockable resources](https://seliius27190.seli.gic.ericsson.se:8443/lockable-resources/) page, and **reserve the resource-relabel** resource!
* Navigate to `Manage Jenkins` > `System`
  * Here scroll to `Lockable resources manager` section
  * Press `Add lockable Resource` button
  * In `Name` field add the cluster name (eg: kubeconfig-seliics07837) - this need to be the same as the credential name that will be added as well (See [Add new credential](#431-add-new-credential))
  * In `Description` add the requested description for the resource (For Product CI clusters we use "Product CI", for other teams we use what they specified in the request)
  * Press `Save` button and close the page
  * You can check the lockable resource page if the resource was really added
* When all the necessary lockable resources were added, go to lockable resource page, and **unreserve the resource-relabel** resource!
* If the lockable resource is added, **make sure to add the corresponding [Jenkins credential](#431-add-new-credential) as well**!
* **Only in case of Product CI clusters**: we need to add the clusters (and their credentials) from the **test Jenkins** as well!
* Create a shared library commit to [GlobalVars.groovy](https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master/src/com/ericsson/eea4/ci/GlobalVars.groovy) to include the new lockable resource in Clusters!
  * **Important**: When adding a new lockable resource, make sure that you **first you add the lockable resource- and the credential to Jenkins, and only when they are defined you can create and +1 the shared library change** in the [GlobalVars.groovy](https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master/src/com/ericsson/eea4/ci/GlobalVars.groovy). If you do these steps in a different order, functional tests will fail because of the non-existing resource!

##### 4.2.2. Change lockable resource manually

* There is a [jenkins pipeline](https://seliius27190.seli.gic.ericsson.se:8443/job/lockable-resource-label-change/) which can change cluster labels. It is used by the Product CI pipelines, and should be used in most cases.
* If there is a different use case, and the job itself can't be used for some reason, the following workflow should be followed:

1. **reserve** the **resource-relabel** jenkins resource in order to block the pipeline run
2. change the desired jenkins resource(s)
3. unreserve the resource-relabel jenkins resource

##### 4.2.3. Delete lockable resource

* In case a lockable resource is dismantled, we need to remove it from Jenkins
* First you need to delete it from the [GlobalVars.groovy](https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master/src/com/ericsson/eea4/ci/GlobalVars.groovy) Clusters, create a commit, +1 it, and **wait with the next steps until the** `LATEST_CI_LIB` **tag moves** to this commit.
* Than go to [lockable resources](https://seliius27190.seli.gic.ericsson.se:8443/lockable-resources/) page, and **reserve the resource-relabel** resource!
* Navigate to `Manage Jenkins` > `System`
  * Here scroll to `Lockable resources manager` section
  * Find the lockable resource that needs to be deleted, and with the red "x" icon delete the resource
  * When all the necessary lockable resources were deleted, press `Save` button and close the page
  * You can check the lockable resource page if the resource was really deleted
* When all the necessary lockable resources were removed, go to lockable resource page, and **unreserve the resource-relabel** resource!
* If the lockable resource was deleted, **make sure to delete the corresponding [Jenkins credential](#433-delete-credential) as well**!
* **Only in case of Product CI clusters**: we need to remove the clusters (and their credentials) from the **test Jenkins** as well!
* **Important**: When deleting a lockable resource, **make sure that first you remove it from the shared library and wait until the** `LATEST_CI_LIB` **tag points to the removal commit. Only when its done you can delete the resource from Jenkins**! If you do these steps in a different order, functional tests will fail because of the non-existing resource!

#### 4.3. Credentials management

Credentials are mostly used for authentication. In case of kubernetes clusters (which are handled as lockable resources in Jenkins) we store the kubeconfig files in Jenkins "secretfile" type credentials, so that jobs can reach the clusters API and authenticate with them. So whenever a new cluster is added or changed (reinstalled), the corresponding credentials need to be added/modified as well.

##### 4.3.1. Add new credential

* Adding a new credential for Product CI or other teams if requested is a **task for the Product CI pipeline driver**,
* for this you'll need **Jenkins administrational** rights!
* Credentials can be added at the [credentials menu](https://seliius27190.seli.gic.ericsson.se:8443/credentials/) of Jenkins.
  * The credential should be on **global** domain (click on the `global` domain under the `Stores scoped to Jenkins section`)
  * Click `Add credentials`
  * in case of a cluster credential, credential name has to be exactly the same as the lockable resource
  * In case of adding a credential with kind "secret file" (usually this is the case for clusters), you must upload any non-empty file to create the credentials, otherwise Jenkins will throw an error. (If we don't have the credential file - eg. the owner of the credential will update it later - you should upload any arbitrary **non-empty dummy file** - *eg. dummy.txt with one 'a' character in the filie.*
  * In case of secret file type credentials, the `Description` field should contain the name of the valid gerrit group(s) who own/manage the cluster. This shall be given by the requester! When in doubt, check other credentials of the cluster owner and copy those.
    * If necessary, more than one manager group can be added to the description (comma separated, eg: "EEA CDS, EEA4 CI team")
    * **Only for Prod CI**:
      * for Prod CI cluster credentials we use "EEA4 CI team" in the master Jenkins
      * and "EEA4 CI team functional" for the test Jenkins
* If adding a new credential requires lockable resource editing, don't forget to reserve the "resource-relabel" jenkins resource to avoid any overwriting during the config edit! After the editing is finished, unreserve this label, and the labeling job will continue to work as intended. For details See [Lockable resource management](#42-lockable-resource-management)
* **Only for Prod CI cluster credentials**: make sure to add the same credentials to the [Test jenkins](https://seliius27102.seli.gic.ericsson.se:8443/manage/credentials/) as well! (Don't do this with other teams' cluster credentials!)
* When the credential is added, send a response email to the requesting team to run a credentials-update job for the new cluster

##### 4.3.2. Update credential

* **Credential update** for test clusters is automated already with [this job](https://seliius27190.seli.gic.ericsson.se:8443/job/credentials-update-job/)
  * Only an existing credential can be updated, so first we have to create the credential with a dummy file. See [Add new credential](#431-add-new-credential)
  * teams can update credential only for their own clusters (for clusters owned by other teams it's prohibited by the job)!

##### 4.3.3. Delete credential

* Deleting a credential can be done at the [credentials menu](https://seliius27190.seli.gic.ericsson.se:8443/credentials/) of Jenkins.
* Select the `global` domain
* Search for the credential
* press the `update` button (wrench icon)
* in the next page `delete` the credential with the bin icon
* **Only for Prod CI cluster credentials**: make sure to delete the same credentials from the [Test jenkins](https://seliius27102.seli.gic.ericsson.se:8443/manage/credentials/) as well!

#### 4.4 Check if technical cluster jobs has stuck labels

* Look for `faulty`, `cleanup-job`, or `cluster-logcollector-job` labels **with status: FREE** (without *locked by... or other notes*.).
* If any of these exist for more than just a few seconds, the reason should be investigated, **cluster validate** or cluster reinstall should be done, see [Fixing the cluster](#54-fixing-the-cluster).
  * Driver can check the following resources for troubleshooting:
    * Check in which step was caught an error in the [lockable-reource](https://seliius27190.seli.gic.ericsson.se:8443/lockable-resources/) page. For most cases, the reason for faulty is stored in the note place of the cluster.
ster_note.png](<https://eteamproject.internal.ericsson.com/secure/attachment/5980683683_image-2024-03-04-14-51-20-069.png>)
    * Check in the history of the [lockable-resource-label-change](https://seliius27190.seli.gic.ericsson.se:8443/job/lockable-resource-label-change/) - if there is no trace of the cluster with the stuck label, most likely someone changed the labels manually.
    * Check the [lockable-resource-label-change](https://seliius27190.seli.gic.ericsson.se:8443/job/lockable-resource-label-change/) JSON in the console log. Which in the future will be stored at [Application dashboard](http://10.223.227.167:61616/view/ci-resources).

```
13:41:01  CI Dashboard payload:
13:41:01  [
13:41:01      {
13:41:01          "user": "Dmytro Stolbovyi (EXT)",
13:41:01          "jobName": "lockable-resource-label-change",
13:41:01          "jobBuildId": 74784,
13:41:01          "description": "FAILURE cluster-logcollector 38855 triggered manually: Dmytro Stolbovyi (EXT) user",
13:41:01          "resourceName": "kubeconfig-seliics04493-10G",
13:41:01          "newLabel": "faulty"
13:41:01      }
13:41:01  ]
```

#### 4.5. Jenkins plugins

* In case of **plugin request** from the users we should add the request to the **next Jenkins upgrade ticket** in out JIRA backlog. (Jenkins update is performed in every month by Product CI team)

### 5. Handling clusters

#### 5.1. Monitoring test clusters and handling issues

* [Cluster overview page](https://seliius27190.seli.gic.ericsson.se:8443/job/EEA4-cluster-info-collector/Product_5fCI_5fcluster_5finfos/)
* Lockable resources [main Jenkins](https://seliius27190.seli.gic.ericsson.se:8443/lockable-resources/)
* Lockable resources [test Jenkins](https://seliius27102.seli.gic.ericsson.se:8443/lockable-resources/)

* Hourly runned job collecting cluster information and status - [EEA4-cluster-info-collector](https://seliius27190.seli.gic.ericsson.se:8443/job/EEA4-cluster-info-collector)
* Validation job for cluster - [cluster-validate](https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-validate/)
* Pods can be stucked and cause cleanup failing, see details [here](https://eteamspace.internal.ericsson.com/display/ECISE/Cluster+cleanup+in+product+test+jobs)
* [EEA4 Product CI Inventory - Clusters](https://eteamspace.internal.ericsson.com/display/ECISE/EEA4+Product+CI+Inventory#EEA4ProductCIInventory-Clusters)
* Always keep up-to-date [Jenkins Lockable Resources](#42-lockable-resource-management) both main and test Jenkins
  * Product CI code validation using clusters to run tests. The functional-test-loop jop attempt to lock the same cluster both main and test Jenkins at the same time, so always keep the two Jenkins lockable resources in sync
* Monitoring cluster health at Grafana dashboard for the clusters (link available at the [overview page for the clusters](https://seliius27190.seli.gic.ericsson.se:8443/job/EEA4-cluster-info-collector/Product_5fCI_5fcluster_5finfos/) below)
* With automated re-labeling introduced to our pipelines the driver shall check periodically if the lockable resources has proper labels or not. If a resource gets 'faulty' label the driver shall check what happened and inform the team via [MS Teams](https://teams.microsoft.com/l/channel/19%3ae96debee66964644aa7c042fa2393365%40thread.tacv2/General?groupId=bc9ea19b-97da-479d-903f-9b003bcba6a4&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f),
* If needed create a ticket at JIRA for cluster reinstall. (this [example](https://eteamproject.internal.ericsson.com/browse/EEAEPP-80966) can be cloned)
* If pool size has decreased because some clusters had to be removed from it temporarily driver shall update configuration of pipelines as describe [here](#52-updating-cluster-lock-config)

#### 5.2. Updating cluster lock config

Cluster lock configuration is stored in a version controlled file named [cluster_lock_params.json](https://gerrit.ericsson.se/plugins/gitiles/EEA/eea4-ci-config/+/master/config/cluster_lock_params.json), hosted in [eea4-ci-config](https://gerrit.ericsson.se/plugins/gitiles/EEA/eea4-ci-config) external repo.

* This configuration should prioritize application staging pipeline over others!
* You can define how many of each pipeline/job instances can run in parallel (`maxJobCount`)
* It can be requested as a basic prioritization technique, that the cluster lock wait times are set to a different value, thus giving some runs a higher or lower chance to start earlier (`lockRetryDelay`)

##### 5.2.1 Configurable locking parameters

* timeoutFree: maximum wait time for free resource before timeout (in seconds)
* freeCount: lock only when at least this number of specified resource becomes available
* maxJobCount: maximum number of pipeline/job instances that can run in parallel
* lockRetryDelay: wait time between free resource checks (seconds)

##### 5.2.2 cluster_lock_params validation workflow

* New patchset of config/cluster_lock_params.json is uploaded to eea4-ci-config repo
* Pre-validation [eea-ci-config-precodereview](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-ci-config-precodereview/) Jenkins job is triggered
  * Validate .json file with [JSON schema](https://gerrit.ericsson.se/plugins/gitiles/EEA/eea4-ci-config/+/master/schema/cluster_lock_params.schema.json)
  * If pre-validation is successful verification +1 vote given for the patchset in Gerrit
  * If pre-validation fails verification -1 vote given for the patchset in Gerrit
* Manual code review from the team
  * During the review team members can make suggestions, and if they find everything OK, you are granted with a **CR +1** (Code Review +1).
  * **Reviewer should always wait for Verified +1 before adding Code Review +1**
* Post-validation [eea-ci-config-validate-and-publish](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-ci-config-validate-and-publish/) Jenkins job is triggered automatically when CR+1 is given for the commit
  * If validation is OK the change will be merged and submitted to master
  * After it takes effect every pipeline will immediately use the new updated values via [waitForLockableResource](https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master/vars/waitForLockableResource.groovy) function from ci_shared_libraries

#### 5.3. Removing a cluster

Action for removing the cluster and reporting it:

1. remove cluster from the pool by rename bob-ci label adding issue description with [this job](https://seliius27190.seli.gic.ericsson.se:8443/job/lockable-resource-label-change/)
2. use [cluster validate job](https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-validate/) and create ticket to Product CI JIRA board if reinstallation is needed
3. add the ticket ID to the label of the cluster or as description in Jenkins Lockable Resources

Relabelling can be also happened during validation, log collection and cluster cleanup phase. If the relabel happens before cleanup, the cleanup will be completely skipped. IMPORTANT: if a validation is running on the cluster, then it is recommended to uncheck Recycling option in lockable-resource-label-change job (set by default) as the option will reset the resource to a free status and can cause confusion. Any new label set with relabel job will be recognized during the run and preserved.

#### 5.4. Fixing the cluster

* **Cluster cleanup**
  * Most cases [cluster cleanup](https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-cleanup/) can help, description is available [here](https://eteamspace.internal.ericsson.com/display/ECISE/Cluster+Cleanup)

* **Cluster reinstall automation**
  * Every weekend from Friday evening to Sunday midnight run [cluster-reinstall-automation](https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-reinstall-automation/)
    After finished this job has been generated Cluster status report and send it to [Driver channel](https://teams.microsoft.com/l/channel/19%3acad1b85796e4400996f54c65c32aee9f%40thread.tacv2/Driver%2520channel?groupId=bc9ea19b-97da-479d-903f-9b003bcba6a4&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f) it should be check every Monday.

#### 5.5 Example of cluster reinstall report

```
    Cluster       |          Label         |   Last Build Status    |    Try Count    |  Status After Reinstall
    kubeconfig-seliics04510  bob-ci            SUCCESS                       1           Reinstalled
```

* Cluster - name of cluster that was under reinstall
* Label - label of cluster, can be `faulty`, `bob-ci`, `bob-ci-upgrade-ready`. This label doesn't changes during or after reinstall
* Last Build Status - status of cluster-reinstall job
  * Status Type:
    * Not build yet - cluster has not reinstall yet
    * SUCCESS
    * FAILED
    * Locked - cluster is locked now and can not reinstall
* Try Count - number of retry cluster reinstall
* Status After Reinstall:
  * Status Type:
    * Reinstalled - cluster reinstall is successfully
    * Need manual reinstall - cluster reinstall fail or cluster is locked

* **Cluster reinstall Manually**
  * If a cluster needs to be reinstalled manually, driver has to create a ticket at JIRA for cluster reinstall. (this [example](https://eteamproject.internal.ericsson.com/browse/EEAEPP-80966) can be cloned)
  * the driver has to ensure that it is removed from the cluster pool ASAP
    * and report the issue for the Product CI team via [MS Teams](https://teams.microsoft.com/l/channel/19%3ae96debee66964644aa7c042fa2393365%40thread.tacv2/General?groupId=bc9ea19b-97da-479d-903f-9b003bcba6a4&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f)
  * reinstalling a faulty cluster can happen with the [cluster-reinstall](https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-reinstall/) jenkins job

### 6. Reviews

#### 6.1. Spinnaker Skip-testing logic for cnint commits

The logic is as follows:

* When the reviewer realizes that a commit doesn't need to be tested, he puts a +1 in Gerrit and adds a "skip-testing" comment in Reply section.
  * This can be valid for newly introduced bob rules, which are not called yet from any pipelines.
  * Configuration files which are not used by any pipelines.
  * Documentation updates (for md and txt files skip is automated without this skip-testing comment)
* The reviewer needs to be a member of the "cnint-manual-commit-reviewers" group, otherwise the check will give an error and the staging will not run.
* After that run [this](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-application-staging) Spinnaker pipeline.
* After starting [this job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-app-baseline-manual-flow-codereview-ok/), it checks if there is a comment, and if it is successful, the variable "skip-testing" with the value of "true" is written to the property file, (otherwise the value will be "false").
* The value of this variable is checked during testing, and if Spinnaker detects that the variable holds the value "true", it skips testing (install, upgrade, CSAR build) and moves on to the CPI build stage and publishes.

### 7. µService Integration

#### 7.1. Classification of µServices

##### ADP:

* ADP Generic Services
  * These services can be used by any application in ADP and they have ADP side support
* ADP Reusable Services
  * They may not have support available at the moment to fix issues immediately

There is only business differences between the 2 types of ADP µServices, **from driving perspective our workflow is the same for both types**.

##### EEA and other µServices

* EEA µServices (starting with *eric-eea-*...)
* Other services (other than ADP or EEA, eg.: eric-csm-..., eric-oss-..., etc... also eea- owners, but different organizational units)

#### 7.2. µService integration / removal

* Process for µService integration and removal is described at the following [guide](https://eteamspace.internal.ericsson.com/pages/viewpage.action?pageId=82971031)
* We shouldn't integrate multiple new componets in parallel, or the same person should handle all the open ones to ensure that parallel integration tracks won't block each other.

#### 7.3. Batching changes or drops to decrease the queue lenght

When the queue is long for the application staging in the [eea-application-staging-wrapper](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-application-staging-wrapper), it can be shortened by batching changes together. E.g. 8 drops or manual changes in the queue means more then 1 day lead time.
Drivers can batch together µService changes or ask developer teams to batch together their manual changes.

#### 7.4. Manual change batching for dev teams

* The driver should check if there are more than one manual changes in the queue from the same developer team. You can check the µService - team mapping [here](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/refs/heads/master/product-ci-loop-triggers.md).
* If there are more than one manual changes for a team, ask the team to merge the changes if possible.
* In that case, the original changes should always be cancelled in the queue and the new change should be reviewed again.

#### 7.5. ADP µService drops batching

Sometimes we have more µService drops in the [eea-application-staging-wrapper](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-application-staging-wrapper), that can also be batched together in one manual change.

Steps:

* collect the µService chart names and versions
* create a manual change in **eric-eea-int-helm-chart/Chart.yaml** where update the version information for **all the occurances of the service names** (it can be more then one for one general service - as there are aliases)
* cancel the µService drops in the [eea-application-staging-wrapper](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-application-staging-wrapper)
* ask review for your change

### 8. Checking docker-image-versions-autouplift-weekly-loop job results

1. This [job](https://seliius27190.seli.gic.ericsson.se:8443/job/docker-image-versions-autouplift-weekly-loop/) is run every Saturday between 6 and 9 am by Jenkins scheduler,
    checks if new docker image versions exist and then automatically changes them in all ruleset files locally under the given repositories (at the moment: cnint, adp-app-staging and eea4_documentation).
    Also, it prepares the appropriate commits, pushes changes to these repositories and optionally runs a verification job for each commit to test the changes. It then sends per repository notifications to [EEA4 CI Driver Channel](https://teams.microsoft.com/l/channel/19%3acad1b85796e4400996f54c65c32aee9f%40thread.tacv2/Driver%2520channel?groupId=bc9ea19b-97da-479d-903f-9b003bcba6a4&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f) (in case of success/failure results).
2. Current driver should check driver channel on Monday morning to find a links to the commits in case of success result and manually approve it if everything looks good.
3. **Note**: At the moment there is no active validation job set up for the following repositories: eea4_documentation (should be validated by eea-application-staging-documentation-build job) and adp-app-staging. After accepting the commits in these repositories the driver should make sure to check if the uplift won't break the related pipelines.
4. **Note**: As of now to merge the commit in **eea4_documentation repository**, we need to give CR +1 and comment `MERGE` in to the textbox!

### 9. Priority List

* Sometimes befora a PRA its necessary to prioritize pipeline tasks.
* For this purpuse a priority list can be found [here](https://pad.lmera.ericsson.se/p/eea_prio).
* When a priority list is active, some integrations might need to be cancelled in the pipelines, and we should allow to run the ones on the priority list instead.
* When a priority list is active and some groups would like to integrate something (eg. commit to cnint), driver has to check if the service is on the priority list. If not, we can't allow the integration by default.

### 10. Maintenance weekends

* During maintenance weekends central E/// services can be unavailable for some time which can cause random issues in our pipelines. So pipeline drivers has to ensure that the following steps are done before the maintenance starts:
  * remove runs from our staging pipeline queue which won't finish before the maintenance, these has to be restarted manually after the maintenance has finished
  * disable time triggered jobs in Jenkins, these should be re-enabled after the maintenance has finished:
    * <https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-reinstall-automation/>
    * <https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-product-baseline-install/>

### 11. ASAP tickets handling

Sometimes we get tickets, the essence of which is to urgently change one value in several places

#### 11.1 Helm install/upgrade timeouts changes

* cnint
  * ruleset2.0.yaml
    > Update HELM_TIMEOUT value with requested value for install
  * bob-rulesets/upgrade.yaml
    > Update HELM_SERVICE_UPGRADE_TIMEOUT, HELM_CONFIG_UPGRADE_TIMEOUT values with requested values for upgrade
* ci_shared_library
  * k8sInstallTest()
    > Find the mentioned function in the code and update HELM_TIMEOUT value with requested value for install
* adp-app-staging
  * Install
    > Find the k8sInstallTest() function calls in the code and update arg.helmTimeout with requested value for install
  * Upgrade
    > Find the HELM_SERVICE_UPGRADE_TIMEOUT, HELM_CONFIG_UPGRADE_TIMEOUT variables in the code and update values with requested values for upgrade

* Pipeline logic is using parameter values form the places above in the following order:
  * Pipeline code at adp-app-staging repo
  * ci_shared_library
  * bob ruleset at cnint

This means that in case of urgent changes we need to change only the pipeline code as it will overwrite both shared lib and ruleset parameter values! Of course to have clear info in the repos later those parts should be updated as well.

### 12. Disabling/enabling automated integration of ADP + versions

In case of content control for EEA releases we may need to disable automated integration of ADP + versions to EEA integration helm chart. To do this you need to modify [eea-adp-staging Spinnaker pipeline](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/configure/4cf92d8c-cbea-4dc7-a899-6ed601433dd6) configuration. Last stage of this pipeline is to trigger EEA Application Staging and this trigger has a conditional expression where we filter by defult for versions which contains '+' character. This conditional expression should be changed to search for some characters which can't be in the version, so ADP + versions won't trigger EEA Application Staging pipeline and these won't be integrated automatically to EEA integration helm chart.

e.g. for the changed contional expression:

```
${parameters['CHART_VERSION'].contains("++")}
```

When content control has finished this conditional expression has to be changed back to the original config.

```
${parameters['CHART_VERSION'].contains("+")}
```

### 13. Dimensioning Tool usage in Product CI Install pipelenes

[Dimtool in Product CI](https://eteamspace.internal.ericsson.com/display/ECISE/Dimtool+in+Product+CI)

### 14. CCD release validation

New CCD releases should be validated with [ccd_validation](https://seliius27190.seli.gic.ericsson.se:8443/job/ccd_validation/) job, before we reinstall all of our clusters with the new release. At least 4-4 installs and upgrades should be executed on 1 cluster successfully in a row to ensure that new CCD version won't cause new blocker baseline issues for us.

Wiki page about the job is available [here](https://eteamspace.internal.ericsson.com/display/ECISE/Test+new+version+of+CCD+pipeline).

### 14. Recovering from failed publish pipelines

See documentation [here](https://eteamspace.internal.ericsson.com/display/ECISE/Manual+recovery+from+publish+job+failures).

### 15. Investigate NeLS license issues

Currently just the eric-oss-correlator uses the licenses, therefore when we have NeLS license issue, we just saw that in eric-oss-correlator.
One tippical issue occurrence in check-pods-state-with-wait.log

```
2023-11-10 19:47:55,785 [1;37mINFO    [1;0m [CheckPodsStatuses] ========================================
2023-11-10 19:47:55,786 [1;37mINFO    [1;0m [CheckPodsStatuses] Executing checker: CheckPodsStatuses
2023-11-10 19:47:55,786 [1;37mINFO    [1;0m [CheckPodsStatuses] ========================================
2023-11-10 19:47:55,786 [1;34mDEBUG   [1;0m [CheckPodsStatuses] Executing command [kubectl --namespace eric-eea-ns get pods --output yaml]...
2023-11-10 19:48:30,538 [1;33mWARNING [1;0m [CheckPodsStatuses] Container eric-eea-ns/eric-oss-correlator-node-0/correlator-node is Restarting too frequently (11/10)
2023-11-10 19:48:30,540 [1;33mWARNING [1;0m [CheckPodsStatuses] Check Pods Statuses
```

Logs from logs_eric-eea-ns_$(date).tgz
in logs/eric-oss-correlator-node-0_correlator-node.txt

```
starting rsyslogd
starting license tester
starting mgr
Mgr started, PID=46876
Client could not connect to 'dns:Unknown:7777'
Client could not connect to 'dns:Unknown:7777'
Client could not connect to 'dns:Unknown:7777'
Client could not connect to 'dns:command:7777'
Client could not connect to 'dns:command:7777'
Client could not connect to 'dns:command:7777'
Client could not connect to 'dns:Unknown:7777'
Client could not connect to 'dns:Unknown:7777'
Client could not connect to 'dns:Unknown:7777'
MGR exited with code 0
Client could not connect to 'dns:command:7777'
Client could not connect to 'dns:command:7777'
Client could not connect to 'dns:command:7777'
terminating pod
```

in logs/eric-lm-combined-server-license-server-client-78d7fd5d6-cp2nb_eric-lm-license-server-client.txt

```
{"version": "1.2.0", "timestamp": "2023-11-10T19:52:40.920Z", "severity": "error", "service_id": "eric-lm-combined-server", "metadata": {"container_name": "eric-lm-license-server-client", "pod_name": "eric-lm-combined-server-license-server-client-78d7fd5d6-cp2nb", "namespace": "eric-eea-ns"}, "message": "29@ProcessFunction.java::process:49@Internal error processing nelsGetLicenseKeysResponse java.lang.IllegalArgumentException: End date before start date. licenseKey: FAT1024238/1, start date: Wed Nov 08 23:00:00 UTC 2023, end date: Tue Aug 01 22:00:00 UTC 2023// at com.ericsson.adp.lm.core.InternalLicense.<init>(InternalLicense.java:66)// at com.ericsson.adp.lm.core.InternalLicense.<init>(InternalLicense.java:44)// at com.ericsson.adp.lm.license_server.thrift.NelsLicenseServerConnector.updateAllLicenses(NelsLicenseServerConnector.java:930)//  at com.ericsson.adp.lm.license_server.thrift.session.HandlerFromLicenseServer.nelsGetLicenseKeysResponse(HandlerFromLicenseServer.java:205)// at com.ericsson.licensing.nels.thrift.client.fromNels$Processor$nelsGetLicenseKeysResponse.getResult(fromNels.java:1240)//  at com.ericsson.licensing.nels.thrift.client.fromNels$Processor$nelsGetLicenseKeysResponse.getResult(fromNels.java:1218)//  at org.apache.thrift.ProcessFunction.process(ProcessFunction.java:40)// at org.apache.thrift.TBaseProcessor.process(TBaseProcessor.java:40)// at com.ericsson.adp.lm.license_server.thrift.session.MessageReceiver.run(MessageReceiver.java:44)// at java.base/java.lang.Thread.run(Thread.java:829)"}
```

Important part

```java.lang.IllegalArgumentException: End date before start date. licenseKey: FAT1024238/1, start date: Wed Nov 08 23:00:00 UTC 2023, end date: Tue Aug 01 22:00:00 UTC 2023```

If you found similar log messages, it means we have NeLS license issue.
In this case we have to ask help from [Enviroment Team in email](mailto:pdlceaenvc@pdl.internal.ericsson.com)

If the issue still persists after they tried to solve it, than we have to ask help from [Ericsson License Key Management](mailto:ericsson.license.key.management@ericsson.com)

#### WA when the issue solving takes long time

We have [license load shell script](https://gerrit.ericsson.se/plugins/gitiles/EEA/eea4-ci-worklogs/+/master/ezdobar/license_hack.sh) which loads correlator related licences onto  eric-eea-license-data-document-database-pg-0.

So you have to scp this script onto ProductCI clusters control-plane nodes and put there onto crontab with ```crontab -e``` command usage

```
#License load hack
*/5 * * * * /root/license_hack.sh
```

##### A way how can you apply the license_hack.sh to all Product CI clusters

Please check out these repos:

* git clone ssh://ezdobar@gerrit.ericsson.se:29418/EEA/eea4-ci-worklogs
* git clone ssh://ezdobar@gerrit.ericsson.se:29418/EEA/inv_test

Than execute these shall commands:

```
#Get Product CI cluster control planes host name from inv_test/eea4/cluster_inventories
IFS=$'\n'
clusters=($(find /local/ezdobar/inv_test/eea4/cluster_inventories/cluster_productci_* -name hosts  -not -path '*/cluster_productci_appdashboard/*' -exec grep -A 1 '\[master\]' {} \;  | grep -v '\[master\]'))
unset IFS

#Check the list of the Product CI clusters
echo "${clusters[@]}"

#Copy ssh keys to all Product CI control planes
for cluster in "${clusters[@]}"; do echo $cluster; ssh-copy-id -i ~/.ssh/id_rsa.pub root@$cluster; done

#Copy license_hack.sh all Product CI control planes
for cluster in "${clusters[@]}"; do echo $cluster; scp license_hack.sh root@$cluster:; done

#Add license_hack.sh to all Product CI control planes
for cluster in "${clusters[@]}";
do
echo $cluster;
ssh root@$cluster 'if (( license_hack_in_crontab < 1 )); then echo -e "#License load hack\n*/5 * * * * /root/license_hack.sh" | crontab  -; fi'
done

#Check back the license_hack.sh already added to all Product CI control planes crontab or not
for cluster in "${clusters[@]}";  do  echo $cluster;  ssh root@$cluster 'crontab  -l'; done
```

### 16. PVC change workflow in baseline

On some occasions there may be necessary to apply a fix to the current baseline that involves changing certain kubernetes resources (eg: persistent volume claim), which once created and provisioned cannot be changed on the fly without recreating them.

Therefore if such resource needs change in the baseline for some reason, we need to cleanup the clusters where previously installed baseline is present and check the currently running baseline install and upgrade jobs.

The workflow is as follows:

#### 16.1. Check currently running upgrade jobs

Check the running [eea-common-product-upgrade](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-common-product-upgrade/) jobs.

* If an upgrade job build is running, and it's already **after** the `Checkout cnint` stage, but **before** the `Lock` stage, that job needs to be **cancelled** (as this job started with a previous baseline requirement, and the new, changed baseline won't be suitable for it)!
* Job builds that already aquired a cluster in the `lock` stage **can remain running**, as they are already running on a cluster that was installed with the the old baseline, so they are not affected by the baseline change.

#### 16.2. Check ongoing baseline installs

If there are ongoing [eea-application-staging-product-baseline-install](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-product-baseline-install) job builds, these need to be **stopped**, and the clusters which they ran on need to be **cleaned up** to remove the old baseline!

*Note*: we need to check which upstream job started the baseline install - if it was a started by an upgrade, that upgrade will also need to be fixed later. (If it was started by the prepare-upgrade-scheduler, this case we have only to clean-up the cluster.)

#### 16.3. Disable prepare upgrade job

In Jenkins temporarily disable the [eea-product-prepare-upgrade](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-prepare-upgrade/) job, as this job is called by the [eea-product-prepare-upgrade-scheduler](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-prepare-upgrade-scheduler/), which automatically starts baseline installs. During the change we don't want new baseline installs to start.

#### 16.4. Clean-up  bob-ci-upgrade-ready clusters

We have to [clean-up](https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-cleanup/) all clusters where the previous baseline version was pre-installed.

#### 16.5. Cherry pick commit to cnint

Cherry-pick the cnint commit to all necessary branches (eg: <https://gerrit.ericsson.se/#/c/18042903/>, <https://gerrit.ericsson.se/#/c/18042931/>, <https://gerrit.ericsson.se/#/c/18042922/> - this needs to be done by someone with +2 rights in cnint)

#### 16.6. Re-enable prepare upgrade job

In Jenkins re-enable the [eea-product-prepare-upgrade](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-prepare-upgrade/) job, so that it can start baseline installs with the new baseline.

## Other tools

### Artifactories

On some occasions it may be necessary to check if a version is present in the artifactories.

#### Helm:

* eea µS "-":[proj-eea-drop-helm-local](https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm-local)
* eea µS "+": [proj-eea-released-helm-local](https://arm.seli.gic.ericsson.se/artifactory/proj-eea-released-helm-local/)
* adp - "+/-": [proj-adp-gs-all-helm](https://arm.sero.gic.ericsson.se/artifactory/proj-adp-gs-all-helm/)
* int chart "temp" : [proj-eea-ci-internal-helm](https://arm.seli.gic.ericsson.se/artifactory/proj-eea-ci-internal-helm)
* int chart "-": [proj-eea-drop-helm](https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm)
* int chart + : [proj-eea-released-helm-local](https://arm.seli.gic.ericsson.se/artifactory/proj-eea-released-helm-local)

#### Docker registry

##### Query docker registries with curl

To check image tags in a given repository with curl (*For these queries to work, you need to use a valid API key in the place of `<api-key>`*):

```
curl -s -H X-JFrog-Art-Api:<api-key> https://armdocker.rnd.ericsson.se/v2/proj-adp-cicd-dev/adp-dashboard-ng/postgres/tags/list
```

##### In the browser

* <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-docker-global/proj-eea-drop/>
  * [tree view](https://arm.seli.gic.ericsson.se/ui/repos/tree/General/proj-eea-drop-docker-global/proj-eea-drop)
* <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-released-docker-global/proj-eea-released/>
  * [tree view](https://arm.seli.gic.ericsson.se/ui/repos/tree/General/proj-eea-released-docker-global/proj-eea-released)

### Dashboards used in driving

#### ADP Dashboards

This dashboard always shows the latest builds.

* [ADP Dashboard for GS](https://cicd-ng.web.adp.gic.ericsson.se/view/1/dashboard/1?columnFilter=eea) (Generic services)
* [ADP Dashboard for RS](https://cicd-ng.web.adp.gic.ericsson.se/view/1/dashboard/2?columnFilter=EEA) (Reusable services)
* [CSM services from EIAP](https://dashboard.pilot.hahn107.rnd.gic.ericsson.se/view/21/dashboard/64?columnFilter=EEA) (CSM Services)

### Application dashboard

* App dashboard can be found at: <http://eea4-application-dashboard.seli.gic.ericsson.se:61616/stages>
* Application dashboard documentation: <https://eteamspace.internal.ericsson.com/display/ECISE/Application+Dashboard+in+Product+CI>

* Input for this is the **EEA Integration Chart**
* Therefore it contains
  * adp-,
  * eea-,
  * and "other"-type µServices

* The appliation dashboard can be used (instead of the [Spinnaker - ADP notifications](https://teams.microsoft.com/l/channel/19%3ac0ef0e9f08244c1b83e27358d4419a33%40thread.tacv2/Spinnaker%2520-%2520ADP%2520notification?groupId=bc9ea19b-97da-479d-903f-9b003bcba6a4&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f) channel) to diff baseline and ADP PRA versions in the artifactory more accurately.
  * Good to know that the (legacy) ADP notification channel may - in some cases - send faulty "Baseline and artifactiory version mismatch" alarms, eg: when a new release fails in a stage before reaching our pipelines (they uploaded the version to ARM, but it never got released, we never tested it)
  * The Application dashboard correctly shows the last release (the version that in fact got released) in the "Latest µService release" column

#### Usage

* On the [stage list page](http://eea4-application-dashboard.seli.gic.ericsson.se:61616/stages) you can select with the checkbox which columns you want to compare on the dashboard.
* and with the slide you can set how many previous runs to show

In driving you usually want to check:

![Screenshot: Application Dashboard](https://eteamspace.internal.ericsson.com/download/attachments/1373121790/app_dashboard1.png)

* The legend at the top of the site explains the colors, and can also be used as a filter (eg. show only failed):

![Screenshot: Application Dashboard Filter](https://eteamspace.internal.ericsson.com/download/attachments/1373121790/application_dashboard_filter.png)

* The search field can be used to search for eg. a specific service:

![Screenshot: Application Dashboard Search](https://eteamspace.internal.ericsson.com/download/attachments/1373121790/app_dashboard_search.png?api=v2)

### EEA4 µService drop status

This dashboard can be used to track **services that does not have a chart and/or not contained in the product** too (eg.: utf drops!)

**Note**: This tool is **obsolete** and won't be maintained in the future! Functionality is being moved to the App dashboard.

[EEA4 µService drop status](https://seliius27190.seli.gic.ericsson.se:8443/job/drop-status/lastSuccessfulBuild/artifact/drop_status.html)

### Spinnaker Pipeline report dashboard

**Note**: This tool is **obsolete** and won't be maintained in the future! Functionality is being moved to the App dashboard.

[Spinnaker pipelines report](https://seliius27190.seli.gic.ericsson.se:8443/job/spinnaker-report/lastSuccessfulBuild/artifact/report.html)

### Cluster info page

This dashboard is used to check cluster health statuses.

[EEA4-cluster-info-collector](https://seliius27190.seli.gic.ericsson.se:8443/job/EEA4-cluster-info-collector/Product_5fCI_5fcluster_5finfos/)

## Other operational WoWs

### Helm values related modifications on release branches

On some occasions due to certain [changes](https://gerrit.ericsson.se/#/c/16739430/2/helm-values/custom_dimensioning_values.yaml) - that modfify the persistentVolumeClaim values, the currently installed baseline version can become invalid, therefore we need to cleanup the preinstalled clusters. This can happen often during new BFU validation when we test the new upgrade path before introducing it to the live upgrade pipelines.

These cases however we cannot simply run the cleanup while the cluster still has the bob-ci-upgrade-ready label, because this way other upgrade jobs can lock the cluster before the cleanup job relabels it to bob-ci, and causes problems with the upgrade, eg:

```
10:10:18  Error from server (NotFound): configmaps "product-baseline-install" not found
```

**So the proper way of working in these cases is**:

* Lock the cluster manually
* Rename with lockable-resource-label-change to unusual label (e.g. PUPPY)
* start the clean-up

## Legacy Operational manual

[This](https://eteamspace.internal.ericsson.com/display/ECISE/Operational+Manual) legacy manual has some random topics for Product CI drivers what to do in case of issues during issues with the pipelines.

## Our pipelines flowchart

For a better understanding of our pipelines, check this flowchart.

![Screenshot: Pipelines](https://eteamspace.internal.ericsson.com/download/attachments/1373121525/EEA4%20Product%20CI.drawio-2022_06_07.png)
