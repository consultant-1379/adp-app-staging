# Running UTF tests in Product CI

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Description

This documentation is about running UTF and Backup Restart Orchestration (BRO) tests in the Product CI pipelines.
For UTF service usage documentation see: [UTF-service usage](https://eteamspace.internal.ericsson.com/display/EInVAut/UTF-service+usage)

## UTF test running steps

### 1. Preparations

#### 1.1. Import and instantiate UTF trigger from the ci\_shared\_libraries

[CI Shared Libraries](https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master) is a [Jenkins global shared library](https://www.jenkins.io/doc/book/pipeline/shared-libraries/) where the most common funcitonalities - accessible globally for all the pipelines - are implemented.

For UTF and BRO testing the pipelines can load and utilize the [UtfTrigger](https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master/src/com/ericsson/eea4/ci/UtfTrigger2.groovy) class from CI Shared Libraries. `UtfTrigger2` constructor requires a `script` as input - to provide the necessary context to the object.

UtfTrigger2 uses the environment of the injected pipeline script and runs tests according to bob rules [ruleset2.0.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/ruleset2.0.yaml)

Instantiating UtfTrigger2 in a Jenkinsfile:

```

@Library('ci_shared_library_eea4') _
...
import com.ericsson.eea4.ci.UtfTrigger2
...
@Field def utf = new UtfTrigger2(this)
...

```

#### 1.2. Setting environment variables for the tests

These parameters from bob rule are configured in the Jenkins pipeline environment and passed as an environment variables for every test run through the shell.

* `UTF_META_FILTER` - **list of labels**:
  * These filters will be passed to the UTF service as `cucumberFilterTags`
  * decisive/non-decisive - every time we are running tests, we might run them in two stages: decisive or non-decisive. In decisive stage there should be only the stable test runs, and the newly introduced or non-stable tests should be under non-decisive label. A failed decisive test will fail the final result of the pipeline.
  * staging - the pipeline type (former @adp filter deprecated and will be removed from utf)
  * nx1/batching - the test type
  * These labels on the tests *are managed by the test owner*
* `UTF_PRODUCT_NAMESPACE` - *e.g.: eric-eea-ns*
* `UTF_TEST_NAME` - name of the test
* `UTF_TEST_TIMEOUT` - On the utf-service REST API we can start the tests asynchronous, and after that we try to get the result with an other request but with a timeout. Different test collection can take different time, so this timeout should be configured for every test stage.
* `UTF_DATASET_ID` - *e.g.: PROD\_CI\_2021\_11\_09\_v1*
* `UTF_REPLAY_SPEED` - data loading speed multiplier during UTF tests
* `UTF_REPLAY_COUNT` - data loading replay count during UTF tests
* `RVROBOT_VERSION` - *e.g.: 0.1.0-0*
* `K8_SFTP_SERVICE_NAME` - sftp service name from the utf-service kubernetes namespace that's used in BRO tests
* `WORKSPACE` - Jenkins environment variable contains an absolute path of workspace

*Note: Some of these variables will be set or overridden at later stages, according to the actual test parameters. Variables UTF_REPLAY_SPEED and UTF_REPLAY_COUNT have been implemented to regulate UTF data loading speed and replay count. A default value of the UTF_REPLAY_SPEED is 1 (to multiply all throttle values in a given [dataset](https://gerrit.ericsson.se/plugins/gitiles/EEA/eea4-bbt/+/master/unified-test-framework/utf-plugins-parent/utf-plugin-config-loader/src/main/resources/configs/data_sets.yml)), the default one of the UTF_REPLAY_COUNT is -1 (it stands for repeat infinite). Documentation for reference is [here](https://eteamspace.internal.ericsson.com/display/EInVAut/DataSets)*

// todo: These environment variables are initialized in pipelines, but not used.

* `UTF_TEMPLATE_SUBTYPE`
* `UTF_TEMPLATE_TYPE`
* `UTF_TEMPLATE_ID`
* `UTF_TEMPLATE_NAME`
* `UTF_INCLUDED_STORIES`

Example for the parameter setting in Jenkinsfile

```
    environment {
        UTF_META_FILTER_DECISIVE = "groovy:decisive&&staging&&nx1&&!tc_under_development"
        UTF_META_FILTER_NON_DECISIVE = "groovy:non_decisive&&staging&&nx1&&!tc_under_development"
        UTF_PRODUCT_NAMESPACE = "eric-eea-ns"
        UTF_TEST_NAME = "DemoUTFTestCase"

        // for start/stop data loading
        UTF_START_DATA_LOADING_TEST_EXECUTION_ID = 1111 + "${env.BUILD_NUMBER}"
        UTF_START_DATA_LOADING_META_FILTER = "@startRefData or @startData"
        UTF_START_DATA_LOADING_TEST_TIMEOUT = 1800
        UTF_START_DATA_LOADING_CHECK_TEST_EXECUTION_ID = 1112 + "${env.BUILD_NUMBER}"
        UTF_START_DATA_LOADING_CHECK_META_FILTER = "@startDataCheck"
        UTF_START_DATA_LOADING_CHECK_TEST_TIMEOUT = 1800
        UTF_STOP_DATA_LOADING_TEST_EXECUTION_ID = 9999 + "${env.BUILD_NUMBER}"
        UTF_STOP_DATA_LOADING_META_FILTER = "@stopData"
        UTF_STOP_DATA_LOADING_TEST_TIMEOUT = 1800
    }

```

### 2. Deployment of UTF service with eea-product-ci-meta-baseline-loop-utf-and-data-loader-deploy job

Currently, the preferred way to deploy UTF is running eea-product-ci-meta-baseline-loop-utf-and-data-loader-deploy job (, [Jenkins](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-ci-meta-baseline-loop-utf-and-data-loader-deploy/), [Git](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/pipelines/eea_product_ci_meta_baseline_loop/eea_product_ci_meta_baseline_loop_utf_and_data_loader_deploy.Jenkinsfile)) which deploys UTF service and dataset for UTF testing.

#### 2.1. eea-product-ci-meta-baseline-loop-utf-and-data-loader-deploy job input parameters

* `CHART_NAME` - Chart name of the actual microservice e.g.: eric-ms-b, defaultValue: ''
* `CHART_REPO` - Chart repo of the actual microservice e.g.: <https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm> defaultValue: '')
* `CHART_VERSION` - Chart version e.g.: 1.0.0-1, defaultValue: ''
* `INT_CHART_NAME` - Chart name of the integration chart (the product itself) e.g.: eric-ms-b, defaultValue: ''
* `INT_CHART_REPO` - Chart repo of the integration chart e.g.: <https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-helm>, defaultValue: ''. When left unspecified (''), the latest will be deployed from master)
* `INT_CHART_VERSION` - Chart version e.g.: 1.0.0-1, defaultValue: ''
* `RESOURCE` - Jenkins resource lock variable, defaultValue: ''

Example of invoking eea-product-ci-meta-baseline-loop-utf-and-data-loader-deploy job from Jenkinsfile:

```
stage('utf and data loader deploy-deploy') {
    steps{
        script {
            def utf_build = build job: "eea-product-ci-meta-baseline-loop-utf-and-data-loader-deploy", parameters: [
                booleanParam(name: 'dry_run', value: false),
                stringParam(name: 'INT_CHART_NAME', value : "eric-eea-ci-meta-helm-chart"),
                stringParam(name: 'INT_CHART_REPO', value : "https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm"),
                stringParam(name: 'RESOURCE', value : "${env.CLUSTER_NAME}")
            ], wait: true
            sh """wget ${env.JENKINS_URL}/job/eea-product-ci-meta-baseline-loop-utf-and-data-loader-deploy/${utf_build.number}/artifact/meta_baseline.groovy --auth-no-challenge"""
            archiveArtifacts artifacts: "meta_baseline.groovy", allowEmptyArchive: true
            load "meta_baseline.groovy"
        }
    }
}

```

#### 2.2. Running deployment

* `eea-product-ci-meta-baseline-loop-utf-and-data-loader-deploy` job does the following steps:
  * `get meta version stage`:
    * check or set `env.UTF_DATASET_ID`, details: [Environment variables in the deployment stage](#23-environment-variables-in-the-deployment-stage)
    * construct and write a `meta_baseline.groovy file` and save it as an artifact, where:
      * for `env.META_BASELINE_NAME` write the value of param `INT_CHART_NAME`
      * for `env.META_BASELINE_VERSION` write the value of env variable `INT_CHART_VERSION`
      * for `env.UTF_DATASET_ID` write the value of env variable `UTF_DATASET_ID`
      * for `env.UTF_REPLAY_SPEED` write the value of env variable `UTF_REPLAY_SPEED`
      * for `env.UTF_REPLAY_COUNT` write the value of env variable `UTF_REPLAY_COUNT`
      * for `env.RVROBOT_VERSION` write the value of env variable `RVROBOT_VERSION`

      `meta_baseline.groovy file` example:

      ```
      env.META_BASELINE_NAME="eric-eea-ci-meta-helm-chart"
      env.META_BASELINE_VERSION="4.5.4-168"
      env.UTF_DATASET_ID="PROD_CI_20220801_4h"
      env.UTF_REPLAY_SPEED="1"
      env.UTF_REPLAY_COUNT="-1"
      env.RVROBOT_VERSION="0.1.0-0"
      ```

  * `utf-deploy` stage:
    * run bob init with [project-meta-baseline/ruleset2.0.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/project-meta-baseline/+/master/ruleset2.0.yaml) ruleset
    * download the chart `<INT_CHART_NAME>-<int-chart-version>.tgz` from `<INT_CHART_REPO>`
    * install meta baseline with test.py (included in the k8-test docker image) from the `k8-test-utf` rule of the [project-meta-baseline/ruleset2.0.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/project-meta-baseline/+/master/ruleset2.0.yaml)
    * cleanup workspace with cleanWs() (from the workspace Jenkins plugin)
* after the eea-product-ci-meta-baseline-loop-utf-and-data-loader-deploy download the generated meta-baseline.groovy from the artifact url of the currently ran deploy job (url is constructed from the `number` of the utf deploy job), which contains the previously written `META_BASELINE_NAME`, `META_BASELINE_VERSION` and `UTF_DATASET_ID` environment variables - see [Environment variables in the deployment stage](#23-environment-variables-in-the-deployment-stage), and **load** its content to the environment.

#### 2.3. Environment variables in the deployment stage

* `UTF_DATASET_ID` - If dataset id value is not set in env, set it from \["dataset-information"\]\[dataset-version\] field of [project-meta-baseline/eric-eea-ci-meta-helm-chart/values.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/project-meta-baseline/+/master/eric-eea-ci-meta-helm-chart/values.yaml)
* `META_BASELINE_NAME`
* `META_BASELINE_VERSION`
* `INT_CHART_REPO`
* `INT_CHART_MAME`
* `INT_CHART_VERSION`

#### 2.4. Logs/output files in the deployment stage

* meta-baseline.groovy artifact is generated to `https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-ci-meta-baseline-loop-utf-and-data-loader-deploy/<utf_build.number>/meta_baseline.groovy` which contains the following env variables:

  ```
      env.META_BASELINE_NAME="eric-eea-ci-meta-helm-chart"
      env.META_BASELINE_VERSION="4.5.4-168"
      env.UTF_DATASET_ID="PROD_CI_20220801_4h"
      env.UTF_REPLAY_SPEED="1"
      env.UTF_REPLAY_COUNT="-1"
      env.RVROBOT_VERSION="0.1.0-0"
  ```

### 3. Constructing the utf trigger json parameter

#### 3.1 The content of the utf trigger API call "-d" data parameter

* `parameters` : parameters of the test running, the different test types required different parameters
* `configurations' : for us it's always`"sendLogsToSearchEngine": true` (isn't used in BRO tests)
* `ciPayload` :  parameters of the validation job, they are set only once before the test runs, and will not be changed later in the Jenkins job (isn't used in BRO tests)
* `nfsDir` - path on nfs to save the utf logs  \<pipeline name\>-\<build id\>
**This step constructs the json parameter of the utf trigger curl** using the [UtfTrigger2](https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master/src/com/ericsson/eea4/ci/UtfTrigger2.groovy) class.

#### 3.1.1 The json data variable initialization

For initializing UTF test variables `init...` methods of the CI Shared Libraries [UtfTrigger2](https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master/src/com/ericsson/eea4/ci/UtfTrigger2.groovy) class should be used.

#### 3.1.2 The `parameters` tag initialization

The content of the `parameters` different for each of the following test types

* running test by a testNg xml file for testing pre and post activities, e.g. start data loading and stop data loading
* running test filtered by metafilter tags (there are included BRO tests as well)

Example for initializing UTF test parameters in the json

running test by a testNg xml file:

```
        "parameters": {
            "additionalParameters": {
                "value": {
                    "dataSet": "PROD_CI_20220801_4h",
                    "replaySpeed": "1",
                    "replayCount": "-1"
                }
            },
            "cucumberFeatures": {
                "value": "classpath:/features/"
            },
            "productNamespace": {
                "value": "eric-eea-ns"
            },
            "testNgClass": {
                "value": "com.ericsson.eea.inv.cucumber.TestNGClassOfCucumberTests"
            },
            "testNgXml": {
                "value": "PreActivities.xml"
            },
            "testNgThreadCount": {
                "value": "5"
            }
        }
```

running test filtered by metafilter tags:

```
        "parameters": {
            "additionalParameters": {
                "value": {
                    "dataSet": "PROD_CI_20220801_4h",
                    "replaySpeed": "1",
                    "replayCount": "-1"
                }
            },
            "cucumberFeatures": {
                "value": "classpath:/features/"
            },
            "productNamespace": {
                "value": "eric-eea-ns"
            },
            "testNgThreadCount": {
                "value": "12"
            },
            "cucumberFilterTags": {
                "value": "@decisive and @nx1 and @staging and not @onlyUpgrade and not @tc_under_development"
            }
        }
```

running the BRO tests looks like below:

```
        "parameters": {
            "additionalParameters": {
                "value": {
                    "dataSet": "PROD_CI_20220801_4h",
                    "replaySpeed": "1",
                    "replayCount": "-1",
                    "backupAndRestore.externalSftpServerHostname": "seliics03113",
                    "backupAndRestore.externalSftpPort":"31247",
                    "backupAndRestore.sftpServerNamespace": "utf-service",
                    "backupAndRestore.externalSftpUserName": "sftpuser",
                    "backupAndRestore.externalSftpUserPass": "sftp@pass1"
                }
            },
            "cucumberFeatures": {
                "value": "classpath:/features/accessMgmt/access_mgmt_no_delete.feature"
            },
            "productNamespace": {
                "value": "eric-eea-ns"
            },
            "testNgThreadCount": {
                "value": "1"
            }
        }
```

#### 3.1.2 The ciPayload tag initialization

* call loadJsonFile(String jsonPath) to load the default json into a groovy Map object `testParametersFromJson` The default json file: [utf_test_parameters.json](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/technicals/utf_test_parameters.json)
* call `initTestParametesJenkins( String jobName, String buildNum )` method of the UtfTrigger2 with values of standard jenkins environment variables `JOB_NAME` and `BUILD_NUMBER`. This is a setter for `test_exec_metadata.jenkins` in the testParametersFromJson
* call `initTestParametesTestExecMetadata( String spinnakerId, String clusterName, String nameSpace )` to set values of spinnaker_id, cluster_ID, eea4_namespace in testParametersFromJson
* read and parse [eric-eea-int-helm-chart/Chart.yaml]
* call `initTestParametesMetabaselineChart( String name, String version )` to set to product chart name and version from the previously parsed `Chart.yaml`
* construct a dependency list from the `dependencies` section of the parsed `Chart.yaml` and set the values `msList` field of the utf instance with the `appendMsList ( String msName, String msVersion ) method`. This list of key/value pairs will contain the microservice dependencies.
* call `initMetaChart( String name, String version )` to set the `metaChart` field of the utf instance with values of `META_BASELINE_NAME`, `META_BASELINE_VERSION` environment variables

A wrapper created in the class, to call all the init functions : initUtfTestVariables(GlobalVars vars, String jsonPath="adp-app-staging/utf_test_parameters.json")

Example for initializing UTF test variables in Jenkinsfile:

```
    stage('init UTF Test Variables') {
        steps {
            dir('cnint') {
                script {
                    utf.initUtfTestVariables(vars, "adp-app-staging/technicals/utf_test_parameters.json")
                }
            }
        }
    }
```

JSON Example of the CI payload:

```
"ciPayload":
{
    "test_exec_metadata":
    {
        "spinnaker_id": "",
        "jenkins":
        {
            "job":
            {
                "name": "test-efikgyo-eea-product-ci-meta-baseline-loop-upgrade",
                "build_num": "2"
            }
        },
        "cluster_ID":
        {
            "name": "kubeconfig-seliics03116"
        },
        "eea4_namespace":
        {
            "name": "eric-eea-ns"
        }
    },
    "metabaseline_chart":
    {
        "name": "eric-eea-ci-meta-helm-chart",
        "version": "4.4.1-52-h6ab286b"
    },
    "product_integration_chart":
    {
        "name": "eric-eea-int-helm-chart",
        "version": "4.4.1-15"
    },
    "csar_package": [],
    "elk":
    {
        "host": "seliics00309.ete.ka.sw.ericsson.se",
        "port": "9200"
    },
    "microservice_list": [
    {
        "msName": "eric-sec-sip-tls",
        "msVersion": "5.2.0+20"
    },
    {
        "msName": "eric-sec-key-management",
        "msVersion": "3.6.0+7"
    },

    (...)

    {
        "msName": "dimensioning-framework",
        "msVersion": "0.2.0-0"
    }]
}
```

* Note: `ciPayload` and `configuration` tags are not mandatory for the BRO tests, and they're removed from json structure
Unlike UTF test BRO ones have their own sequence of calls:
* call loadJsonFile(String jsonPath) to load the default json into a groovy Map object `testParametersFromJson` The default json file: [utf_test_parameters.json](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/technicals/utf_test_parameters.json)
* call `getK8sServiceProperties(String nameSpace, String serviceName)` this method from UtfTrigger2 class accepts utf namespace name as well as sftp service name in a given namespace to return sftp service hostname and port (it's used during BRO tests)
* call `initBroSpecificParams()` this method from UtfTrigger2 class as well. It sets specific BRO values such as: `backupAndRestore.externalSftpServerHostname, backupAndRestore.externalSftpPort, backupAndRestore.sftpServerNamespace, backupAndRestore.externalSftpUserName, backupAndRestore.externalSftpUserPass`
* call `initTestParametersCucumberFilterTagsBRO(String metafilter)` this method from UtfTrigger2 class. In accordance with metafilters assigns BRO specific cucumber features values and remove `ciPayload` and `configurations` tags as mentioned above
* call `execCleanupIamCacheAfterRollback()` method, it locates in CommonUtils class and implies to clean up of IAM cache during BRO tests. This method in turn calls `clean_cache_iam.sh` shell script that resides in the adp-app-staging repository

#### 3.2. Environment variables used in the UTF variable initialization

* `JOB_NAME`
* `BUILD_NUMBER`
* `META_BASELINE_NAME`
* `META_BASELINE_VERSION`
* `UTF_CI_PAYLOAD`

### 4. Execute UTF tests

The tests can be run by calling [UtfTrigger.execUtfTests](https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master/src/com/ericsson/eea4/ci/UtfTrigger.groovy) method, which is implemented in the CI Shared Libraries.

#### 4.1. Input parameters

 `execUtfTests()` accepts a list of tests as input, where every list element is a map of the following key-value parameters for each individual test:

* `name` - name of the test
* `build_result` - Used as `buildResult` in `catchError` step ([Details on Jenkins catchError construct](https://www.jenkins.io/doc/pipeline/steps/workflow-basic-steps/#pipeline-basic-steps)). If an error is caught, the overall build result will be set to this value.
* `stage_result` - If an error is caught, the stage result will be set to this value. ([Details on Jenkins catchError construct](https://www.jenkins.io/doc/pipeline/steps/workflow-basic-steps/#pipeline-basic-steps)).
* `exec_id` - id of the test execution
* `metafilter` - list of metafilter labels
* `timeout` - how long until the current execution is considered timed out.
* `logfile` - logfile name
* `report_folder` - name of the report folder

These parameters will be used to construct environment variables for each individual tests. For details see: [Environment variables used in the tests](#42-environment-variables-used-in-the-tests)

example parameters:

```
def cucumber_tests = [
    [name: 'Decisive Nx1 Staging UTF Cucumber Tests',
    build_result: 'FAILURE',
    stage_result: 'FAILURE',
    exec_id: "101",
    metafilter: "@decisive and @nx1 and @staging and not @onlyInstall and not @tc_under_development",
    timeout: "1800",
    logfile: "utf_decisive_nx1_staging_cucumber_upgrade.log",
    report_folder: "report_decisive_and_nx1_and_staging_and_not_onlyInstall_and_not_tc_under_development"
    ],
    [name: 'Decisive Batch Staging UTF Cucumber Tests',
    build_result: 'FAILURE',
    stage_result: 'FAILURE',
    exec_id: "103",
    metafilter: "@decisive and @slow and @staging and not @onlyInstall and not @tc_under_development",
    timeout: "3600",
    logfile: "utf_decisive_batch_staging_cucumber_upgrade.log",
    report_folder: "report_decisive_and_slow_and_staging_and_not_onlyInstall_and_not_tc_under_development"
    ]
]
utf.execUtfTests(cucumber_tests)
```

**The test parameters for each test are set in as environment variables by iterating over the input list**.

#### 4.2. Environment variables used in the tests

`ExecUtfTests` method makes use of environment variables of the caller pipeline.

execUtfTests **reads** the following env variables:

* `UTF_DATASET_ID` - If UTF\_DATASET\_ID env variable is set, `testing-with-utf-cucumber-dataset`] [bob rule](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/ruleset2.0.yaml) runs, else `testing-with-utf-cucumber-dataset` is called.
* `UTF_PRODUCT_NAMESPACE`
* `BUILD_TAG` - used for constructing the NFS path
* `UTF_CI_PAYLOAD` - the payload JSON constructed in step [Constructing the CI payload](#312-the-cipayload-tag-initialization)

execUtfTests **sets** the following env variables according to current test's parameters:

* `UTF_TEST_EXECUTION_ID`
  * constructed from the `exec_id` value of the current test element of the input list, plus the the standard Jenkins environment variable `BUILD_NUMBER`.
  * Used for constructing the test api call endpoint for the actual test (*e.g.: 10.196.123.71:32476/v2/test_execution/111122*)
  * Used to construct filename of the dedicated logfile of the actual test
  * Used for referencing pod dedicated to the actual test
* `UTF_META_FILTER` - set from the  `metafilter` value of the current test element of the input list; used as `cucumberFilterTags` value the test api call
* `UTF_TEST_TIMEOUT` - set from the `timeout` value of the current test element of the input list. After a test starts running, we start polling the service to see whether our test has been finished yet. UTF\_TEST\_TIMEOUT tells how long to wait for the answer until our test execution is considered to be timed out.

#### 4.3. Execution of the tests through bob rules

For every test of the input list `execUtfTests` runs the following steps from [bob rules](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/ruleset2.0.yaml):

* `testing-with-utf-cucumber-dataset-testNG`
  * For every test execution create a temporary docker container to call the API from
  * call the utf test API endpoint `<utf_ip>:<utf_port>/v2/test_execution/<UTF_TEST_EXECUTION_ID>`  with curl with the following payload,
    * where -d is set to `TESTNG_PARAMETERS` environment variable.

  Example of one full the HTTP request to the API:

  ```
  curl - sS - X POST - H 'content-type:application/json' 10.196 .123 .71: 32476 / v2 / test_execution / 1012 - d '{"template":{"parameters":{"additionalParameters":{"value":{"dataSet":"PROD_CI_2021_12_17_v1"}},"cucumberFeatures":{"value":"classpath:/features/"},"cucumberFilterTags":{"value":"@decisive and @nx1 and @staging and not @onlyInstall and not @tc_under_development"},"productNamespace":{"value":"eric-eea-ns"},"testNgThreadCount":{"value":"12"}}},"configurations":{"sendLogsToSearchEngine":true},"ciPayload":{"test_exec_metadata":{"spinnaker_id":"","jenkins":{"job":{"name":"test-efikgyo-eea-product-ci-meta-baseline-loop-upgrade","build_num":"2"}},"cluster_ID":{"name":"kubeconfig-seliics03116"},"eea4_namespace":{"name":"eric-eea-ns"}},"metabaseline_chart":{"name":"eric-eea-ci-meta-helm-chart","version":"4.4.1-52-h6ab286b"},"product_integration_chart":{"name":"eric-eea-int-helm-chart","version":"4.4.1-15"},"csar_package":[],"elk":{"host":"seliics00309.ete.ka.sw.ericsson.se","port":"9200"},"microservice_list":[{"msName":"eric-sec-sip-tls","msVersion":"5.2.0+20"},{"msName":"eric-sec-key-management","msVersion":"3.6.0+7"},{"msName":"eric-data-distributed-coordinator-ed","msVersion":"4.1.0+25"},{"msName":"eric-log-shipper","msVersion":"10.1.0+13"},{"msName":"eric-log-transformer","msVersion":"9.0.0+20"},{"msName":"eric-data-search-engine","msVersion":"10.3.0+25"},{"msName":"eric-data-search-engine-curator","msVersion":"2.12.0+11"},{"msName":"eric-data-coordinator-zk","msVersion":"1.31.0+14"},{"msName":"eric-data-message-bus-kf","msVersion":"1.28.0+38"},{"msName":"eric-fh-alarm-handler","msVersion":"8.6.0+28"},{"msName":"eric-data-document-database-pg","msVersion":"7.7.0+27"},{"msName":"eric-pm-server","msVersion":"10.4.0+26"},{"msName":"eric-data-object-storage-mn","msVersion":"1.26.0+24"},{"msName":"eric-eea-fh-rest2kafka-proxy","msVersion":"1.8.0+67"},{"msName":"eric-fh-snmp-alarm-provider","msVersion":"6.6.0+35"},{"msName":"eric-eea-analytical-processing-database","msVersion":"1.19.0+7"},{"msName":"eric-oss-correlator","msVersion":"1.3.73+17"},{"msName":"eric-eea-db-manager","msVersion":"2.11.0+1"},{"msName":"eric-csm-st","msVersion":"1.4.9+27"},{"msName":"eric-csm-p","msVersion":"1.3.74+42"},{"msName":"eric-csm-st","msVersion":"1.4.9+27"},{"msName":"eric-csm-p","msVersion":"1.3.74+42"},{"msName":"eric-csm-st","msVersion":"1.4.9+27"},{"msName":"eric-csm-p","msVersion":"1.3.74+42"},{"msName":"eric-data-message-bus-kf","msVersion":"1.28.0+38"},{"msName":"eric-data-message-bus-kf","msVersion":"1.28.0+38"},{"msName":"eric-data-coordinator-zk","msVersion":"1.31.0+14"},{"msName":"eric-schema-registry-sr","msVersion":"1.1.11+3"},{"msName":"eric-eea-stream-aggregator","msVersion":"3.31.0+8"},{"msName":"eric-eea-db-loader","msVersion":"3.11.0+14"},{"msName":"eric-eea-spotfire-manager","msVersion":"2.18.0+14"},{"msName":"eric-oss-stream-exporter","msVersion":"1.5.13+3"},{"msName":"eric-data-document-database-pg","msVersion":"7.7.0+27"},{"msName":"eric-data-kvdb-ag","msVersion":"7.0.0+51"},{"msName":"eric-data-kvdb-ag-operator","msVersion":"7.0.0+22"},{"msName":"eric-eea-privacy-service","msVersion":"1.10.0+25"},{"msName":"eric-eea-privacy-service-token-generator","msVersion":"1.9.0+24"},{"msName":"eric-eea-detokenizer","msVersion":"1.12.0+136"},{"msName":"eric-data-document-database-pg","msVersion":"7.7.0+27"},{"msName":"eric-sec-access-mgmt","msVersion":"12.3.0+17"},{"msName":"eric-sec-ldap-server","msVersion":"10.3.0+25"},{"msName":"eric-lm-combined-server","msVersion":"7.2.0+60"},{"msName":"eric-sec-certm","msVersion":"6.3.0+30"},{"msName":"eric-eea-refdata-provisioner","msVersion":"1.14.0+18"},{"msName":"eric-eea-refdata-fetch","msVersion":"1.10.0+98"},{"msName":"eric-data-document-database-pg","msVersion":"7.7.0+27"},{"msName":"eric-cm-mediator","msVersion":"7.19.0+8"},{"msName":"eric-cm-mediator","msVersion":"7.19.0+8"},{"msName":"eric-tm-ingress-controller-cr","msVersion":"11.1.0+18"},{"msName":"eric-tm-ingress-controller-cr","msVersion":"11.1.0+18"},{"msName":"eric-tm-ingress-controller-cr","msVersion":"11.1.0+18"},{"msName":"eric-data-document-database-pg","msVersion":"7.7.0+27"},{"msName":"eric-data-document-database-pg","msVersion":"7.7.0+27"},{"msName":"eric-adp-gui-aggregator-service","msVersion":"1.6.0+47"},{"msName":"eric-cs-storage-encryption-provider","msVersion":"3.0.0+9"},{"msName":"eric-tm-tls-proxy-ev","msVersion":"1.3.0+5"},{"msName":"eric-eea-analysis-system-overview-install","msVersion":"0.3.10+10"},{"msName":"eric-ctrl-bro","msVersion":"6.3.0+35"},{"msName":"eric-eea-scoring-proxy","msVersion":"0.6.0+7"},{"msName":"eric-eea-scoring-proxy","msVersion":"0.6.0+7"},{"msName":"eric-si-application-sys-info-handler","msVersion":"1.16.0+19"},{"msName":"eric-eea-incident-ratio-calculator","msVersion":"0.2.0+23"},{"msName":"dimensioning-framework","msVersion":"0.2.0-0"}]},"nfsDir":"jenkins-test-efikgyo-eea-product-ci-meta-baseline-loop-upgrade-2"}'
  ```

#### 4.4. Test results response

When the `status` from polling `<utf_ip>:<utf_port>/v2/test_execution/<UTF_TEST_EXECUTION_ID>` is not `running` any more, we create a subsequent call to the API and save its output temporarily to file `utf_response_file_<UTF_TEST_EXECUTION_ID>`, *e.g.: utf\_response\_file_1012*. The results will be [validated later](#46-validate-results).

Example response in case of failure:

```
{"reason":"GENERAL_ERROR","status":"failed"}
```

#### 4.5. Collect and archive test results and logs from pod, cleanup

After test execution, from `UtfTrigger.execUtfTests` method the `utf-post-step` rule from [ruleset2.0.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/ruleset2.0.yaml) runs to collect logs and clean up pod

Cleanup steps:

* `utf-post-step` - cleanup and logging task, that runs regardless of the test success/failure
  * collects logs with `kubectl logs` from eric-eea-utf-docker-`<UTF_TEST_EXECUTION_ID>` (*e.g.: eric-eea-utf-docker-1012*)
  * gets pod data from eric-eea-utf-docker-`<UTF_TEST_EXECUTION_ID>` (with `kubectl describe pod`)
  * deletes the pod eric-eea-utf-docker-`<UTF_TEST_EXECUTION_ID>`
  * the output streams of the above are saved to a file named `utf_post_step_<UTF_TEST_EXECUTION_ID>.log` with `tee`

#### 4.6. Validate results

AFter running `utf-post-step` from ruleset, `UtfTrigger.execUtfTests` reads the `utf_response_file_<UTF_TEST_EXECUTION_ID>` for the current test to `utf_test_result` variable.

* If `utf_test_result` does not contain the status message "passed", the current UTF test is considered FAILED.
  * Since every test run is closed within a [catchError](https://www.jenkins.io/doc/pipeline/steps/workflow-basic-steps/#pipeline-basic-steps) construct, if the test FAILED and `build_result` input parameter for the current test was set to `FAILURE`, the overall build result will be FAILED, and the `utf_response_file_<UTF_TEST_EXECUTION_ID>` will be saved to artifacts.
  * Regardless of the `build_result` parameter, the script raises an error with shell command `exit 1`, however, since the test is run in `catchError`, the validation steps continue.

* Last validation step checks for @startData metafilter - this step is to ensure when some dedicated tests fail, the script exits and no further logic is executed
  * If the `build_result` parameter for the current test was set to `FALIURE`,
  * **and** the `utf_test_result` did not contain the status message "passed"
  * **and** the string given in the current test's `metafilter` parameter matches the regex pattern `/@startData\b/` (*which means it matches the exact word: @startData, but not startDataCheck*) it causes the injected script to raise an [error](https://www.jenkins.io/doc/pipeline/steps/workflow-basic-steps/#error-error-signal) and abort further steps of execution.

#### 4.7. Logging / output artifacts during the test runs

* `UtfTrigger.execUtfTests` method redirects output of the run commands to a logfile. Log file name for the current test comes from the `logfile` value from the current iteration of the input list (*eg: utf\_decisive\_nx1\_staging\_cucumber.log*).
* `utf_response_file_<UTF_TEST_EXECUTION_ID>` - Contains the result of the current test execution. This file **only gets archived as an artifact if the test failed**!
* `utf-post-step` rule step saves log to `utf_post_step_<UTF_TEST_EXECUTION_ID>.log` (*e.g.: utf\_post\_step\_1012.log*)

## Execution order of UTF tests

### 1. Execute Start Data Loading

Before running the tests, **some dedicated cases of UTF tests must be run**: `start_data_loading` and `start_data_loading_check`.

As with any other UTF tests in general, these can be started by the [UtfTrigger.execUtfTests()](https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master/src/com/ericsson/eea4/ci/UtfTrigger.groovy) method, which is implemented in the CI Shared Libraries.

**Detailed information on EEA4 CI data loading** [here](https://eteamspace.internal.ericsson.com/display/ECISE/Common+EEA4+CI+data+loading)

**For steps and input params of a UTF test execution in general, see**: [Execute UTF tests](#4-execute-utf-tests)

### 2. Execute Cucumber Tests

**For steps of a UTF test execution in general, see**: [Execute UTF tests](#4-execute-utf-tests)

### 3. Execute Stop Data loading

After running the tests, **some dedicated cases of UTF tests must be run**: `stop_data_loading`.

As with any other UTF tests in general, these can be started by the [UtfTrigger.execUtfTests()](https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master/src/com/ericsson/eea4/ci/UtfTrigger.groovy) method, which is implemented in the CI Shared Libraries.

**Detailed information on EEA4 CI data loading** [here](https://eteamspace.internal.ericsson.com/display/ECISE/Common+EEA4+CI+data+loading)

**For steps of a UTF test execution in general, see**: [Execute UTF tests](#4-execute-utf-tests)

Example of calling `stop_data_loading` in Jenkinsfile:

```
def stop_data_loading = [
    [name: 'Stop data loading',
    build_result: 'SUCCESS',
    stage_result: 'FAILURE',
    exec_id: "${UTF_STOP_DATA_LOADING_TEST_EXECUTION_ID}",
    metafilter: "${env.UTF_STOP_DATA_LOADING_META_FILTER}",
    timeout: "${UTF_STOP_DATA_LOADING_TEST_TIMEOUT}",
    logfile: "utf_stop_data_loading.log"
    ]]
    utf.execUtfTests(stop_data_loading)
    cmutils.getInotifyWatchCounters("${STAGE_NAME}", k8s_master, watch_counts_log)

```

## Jobs using this UTF execution

* eea-application-staging-nx1 ([Jenkins](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-nx1/), [Git](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/pipelines/eea_application_staging/eea_application_staging_nx1.Jenkinsfile))
* eea-product-ci-meta-baseline-loop-test ([Jenkins](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-ci-meta-baseline-loop-test/), [Git](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/pipelines/eea_product_ci_meta_baseline_loop/eea_product_ci_meta_baseline_loop_test.Jenkinsfile))
* eea-product-ci-meta-baseline-loop-upgrade ([Jenkins](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-ci-meta-baseline-loop-upgrade/), [Git](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/pipelines/eea_product_ci_meta_baseline_loop/eea_product_ci_meta_baseline_loop_upgrade.Jenkinsfile))
* eea-application-staging-batch ([Jenkins](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-batch/), [Git](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/pipelines/eea_application_staging/eea_application_staging_batch.Jenkinsfile))
* eea-application-staging-product-upgrade ([Jenkins](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-product-upgrade/), [Git](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/pipelines/eea_application_staging/eea_application_staging_product_upgrade.Jenkinsfile))
* eea-adp-staging-adp-nx1-loop([Jenkins](https://seliius27190.seli.gic.ericsson.se:8443/view/EEA%20ADP%20Staging%20View/job/eea-adp-staging-adp-nx1-loop/), [Git](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/pipelines/eea_adp_staging/eea_adp_staging_adp_nx1_loop.Jenkinsfile))
* eea_product_release_loop_bfu_gate_upgrade ([Jenkins](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-release-loop-bfu-gate-upgrade/), [Git](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/pipelines/eea_product_release_loop/eea_product_release_loop_bfu_gate_upgrade.Jenkinsfile))
* adp-app-staging/technicals/cluster_validate.Jenkinsfile ([Jenkins](https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-validate/), [Git](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/technicals/cluster_validate.Jenkinsfile))
