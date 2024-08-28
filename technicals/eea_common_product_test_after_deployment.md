# Description of eea_common_product_test_after_deployment job

## Purpose of this job

This is a common test runner job which intentionally execute the test stages after the deployment.

**Note:**  This job cannot be used for any test which is planned to be executed before or during the deployment.

## Input parameters

```
        string(name: 'AGENT_LABEL', description: 'The Jenkins build node label', defaultValue: 'productci')
        string(name: 'CLUSTER_NAME', description:'The cluster where the tests need to be run. It must be locked by parent job or reserved manually', defaultValue: '')
        string(name: 'CHART_NAME', description: 'Chart name e.g.: eric-ms-b', defaultValue: '')
        string(name: 'CHART_REPO', description: 'Chart repo e.g.: https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm', defaultValue: '')
        string(name: 'CHART_VERSION', description: 'Chart version e.g.: 1.0.0-1', defaultValue: '')
        string(name: 'INT_CHART_NAME_PRODUCT', description: 'Chart name e.g.: eric-ms-b', defaultValue: 'eric-eea-int-helm-chart')
        string(name: 'INT_CHART_REPO_PRODUCT', description: 'Chart repo e.g.: https://arm.seli.gic.ericsson.se/artifactory/proj-eea-ci-internal-helm/', defaultValue: 'https://arm.seli.gic.ericsson.se/artifactory/proj-eea-ci-internal-helm/')
        string(name: 'INT_CHART_VERSION_PRODUCT', description: 'Version to upgrade. Format: 1.0.0-1 Set value "latest" to automaticaly define and use latest INT chart version', defaultValue: '')
        string(name: 'GERRIT_REFSPEC', description: 'Gerrit Refspec of the cnint, for example refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'META_GERRIT_REFSPEC', description: 'Gerrit Refspec of the project-meta-baseline, for example refs/changes/87/4641487/1', defaultValue: '')
        string(name: 'PIPELINE_NAME', description: 'The spinnaker pipeline name', defaultValue: 'eea-application-staging')
        string(name: 'SPINNAKER_TRIGGER_URL', description: 'Spinnaker pipeline triggering url', defaultValue: '')
        string(name: 'SPINNAKER_ID', description: "The spinnaker execution's id", defaultValue: '')
        string(name: 'INT_CHART_NAME_META', description: 'Chart name e.g.: eric-ms-b', defaultValue: 'eric-eea-ci-meta-helm-chart')
        string(name: 'INT_CHART_REPO_META', description: 'Chart repo e.g.: https://arm.seli.gic.ericsson.se/artifactory/proj-eea-ci-internal-helm/', defaultValue: 'https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/')
        string(name: 'INT_CHART_VERSION_META', description: 'meta-baseline version to install. Format: 1.0.0-1', defaultValue: '')
        choice(name: 'DEPLOYMENT_TYPE', description: 'Type of the deployment: INSTALL or UPGRADE. Mandatory, if parent job is not used.', choices: ['','INSTALL', 'UPGRADE'])
        booleanParam(name: 'RUN_ROBOT_TESTS', description: 'Run the robot tests if spotfire is deployed.', defaultValue: true)
```

**NOTE: The test execution after Installation is not yet working properly. It has issue in at the "Pre-activites after deployment" stage in the "runPreActivitiesAfterInstall(stageResults)" function. It need to be fixed before the job start to be used after installation.**

## Stages

+ Params DryRun check
+ Check params and set cluster
+ Cleanup workspace
+ Checkout cnint master
+ Checkout project-meta-baseline master
+ Ruleset change checkout
+ Checkout adp-app-staging
+ Init vars and get charts
+ Init BRO Test Variables
+ Execute BRO tests
+ Init UTF Test Variables
+ Pre-activites after deployment
+ Testing after deployment
  + Decisive Nx1 Staging UTF Cucumber Tests
  + Decisive Batch Staging UTF Cucumber Tests
  + Non-decisive Nx1 Staging UTF Cucumber Tests (only in eea-product-ci-meta-baseline-loop)
  + Non-decisive Batch Staging UTF Cucumber Tests (only in eea-product-ci-meta-baseline-loop)
+ Decisive robot Tests
+ Non_decisive Robot Tests
+ UTF Post-activities
