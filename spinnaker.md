# Developing and integrating Spinnaker pipelines in Product CI

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Create one or more pipelines in Jenkins according to [./jobs/jobs.md](./jobs/jobs.md) and [./pipelines/pipeline.md](./pipelines/pipeline.md)

Access Spinnaker at the following link: <https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions>

## Create

* Click on "Create"
* Type: pipeline
* Name: should follow the naming convention
  (It is possible to copy an existing spinnaker pipeline, by selecting Copy From \<existing pipeline\>)

## Configure

* Search your new spinnaker pipeline on the board
* Click "Configure"
* Start with "Configuration", set up the input parameters for your spinnaker pipeline
  **Automated triggers should be set in the pipeline which would trigger the new pipeline, NOT in the new pipeline! This is when we are talking about 2 spinnaker pipelines, not triggers from jenkins.**
* To add new stage, click on "Add stage"
  * The type can be "Jenkins" in case of a Jenkins pipeline, or "Pipeline" which is another Spinnaker pipeline.
* Click on your newly added stage to add custom settings to it, like
  * Stage Name (stage name should represent the called Jenkins job or Spinnaker pipeline)
    * e.g. for eea-app-staging-nx1 Jenkins job the stage name is Staging Nx1 (we don't add EEA here to the beginning)
    * e.g. for eea-adp-batch-loop Spinnaker pipeline the stage name is EEA ADP Batch loop (EEA is at the beginning for these stages)
  * Controller ( eea-aispinn-seliius27190 )
  * Job ( \<your jenkins pipeline\> )
  * Property File (if you have a file in your jenkins job, you can read that file into spinnaker, so you can use the variables in that property file in later steps)

```
stage('Archive artifact.properties') {
            steps {
                // Archive artifact.properties so Spinnaker can read the parameters
                archiveArtifacts 'artifact.properties'
            }
        }
```

* Job Parameters (if there is no parameter, but you would like to add some, click on "Edit stage as JSON", and add parameters like this):

```
"parameters": {    "CHART_NAME": "${parameters['CHART_NAME']}",
    "CHART_REPO": "${parameters['CHART_REPO']}",
    "CHART_VERSION": "${parameters['CHART_VERSION']}",
    "GERRIT_REFSPEC": "${parameters['GERRIT_REFSPEC']}"
}
```

* Other options

## Example how to use condition on trigger:

```
This example shows that how you can trigger based on a parameter value, to set up the condition, click "Conditional on Expression", and set up the value for example : ${#stage('AdpStaging')['context']['CHART_VERSION'].contains("-")}
This example checks the value of CHART_VERSION parameter from the AdpStaging stage, if it contains "-" character.
```

**Important!!!
In E2E pipelines such conditions are not allowed.
Details of all stages of the E2E spinnaker pipelines must be visible on the dashboard.**

## Example how to use a parameter from different stage:

```
"<param name in current pipeline>": "${#stage('<stage where to copy the parameter from>')['context']['<parameter name in that stage where to copy from>']}"
```

## Manual triggering spinnaker pipeline:

* Click on "Start Manual Execution"
* Set up your parameters
* Check the results both in jenkins and spinnaker

## Request for adding new jenkins server to spinnaker:

```
https://confluence.lmera.ericsson.se/display/ACD/How+to+request+adding+new+Jenkins+server+to+Spinnaker

Example https://cc-jira.rnd.ki.sw.ericsson.se/browse/ADPDEVENV-4925

Type: Request
Component/s: Jenkins
Labels: BDGS-OSS
Product:Spinnaker

Hi,

please add our new Jenkins to the spinnaker as we will use ADP.

Jenkins Master: https://seliius27190.seli.gic.ericsson.se:8443/
PDU Name: PDU OSS PDG EEA
Name in Spinnaker: eea-aispinn-seliius27190
Product Owner (PO): ebatist
CSRF enabled: Yes with configured 'Strict Crumb Issuer' plugin
aispinn access: Yes

overall/read
job/build,read
Based on: https://confluence.lmera.ericsson.se/x/_yVYBg
```

## Automatic backup of Spinnaker pipelines

The Jenkins pipeline named 'spinnaker-backup' is able to automatically fetch every Spinnaker pipeline configuration in the 'EEA' application, and is configured to run at midnight every day. It saves the Spinnaker pipelines' configuration in json format, archived in a .tar.gz file with the current date and time so the exact backup is easy to identify later. The backup archives are stored in the NFS, at the productci/spinnaker-backup folder.

## Restoration of a Spinnaker pipeline from backup

Identify the pipeline by name, that needs to be restored. The 'spin' tool must be installed and preconfigured (see the "Preconfiguration of 'spin' tool" step below). Extract the pipeline json file from the backup archive (explanation in the "Automatic backup of Spinnaker pipelines" step above) to a local directory (for example: ```~/json/```), then issue the restore command:

```
<adp-app-staging repository>/technicals/shellscripts/spinnaker_configuration_update.sh <pipeline-name>
```

Note: do not specify the ".json" extension.

### Preconfiguration of 'spin' tool

Install the 'spin' tool from the [official homepage](https://spinnaker.io/setup/spin/)
A configuration file must be created to run the tool. By default, the tool searches for it at the ~/.spin/config location. Example configuration:

```
gate:
  endpoint: https://spinnaker-api.rnd.gic.ericsson.se
auth:
  enabled: true
  basic:
    username: <username>
    password: <password>
```
