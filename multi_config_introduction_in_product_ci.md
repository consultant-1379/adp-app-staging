# [Study] Multi-config introduction in Product CI

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

Scope of this study is to create a Product CI test pipeline for multi-config support. Multi-config support means that Product CI needs to be able to handle **multiple product configs** for different validation scenarios ("*value packs*") - by providing different sets of config values for specific services. Therefore we need to prepare our pipelines to be able to operate this services with the specified config values.

## Overview

Staging pipelines shall be able to read and use these configsets from the [values file](https://gerrit.ericsson.se/plugins/gitiles/EEA/project-meta-baseline/+/master/eric-eea-ci-meta-helm-chart/values.yaml) from the meta repository. Config selection is done in the prepare jobs with the `VALIDATION_CONFIG_NAME` input parameter. The prepare jobs also read the `DESIRED_CLUSTER_LABEL` from the config - this value will be passed on for later stages via property file. The install jobs utilize the `DESIRED_CLUSTER_LABEL` value for the cluster locking, and pass the `VALIDATION_CONFIG_NAME` to the meta deploy job, where the utf-, robot, etc.. config values are being loaded and used.

## Multi-config Introduction steps in Product CI

### Meta chart modification - values file

The *config sets* can be defined in the [values file](https://gerrit.ericsson.se/plugins/gitiles/EEA/project-meta-baseline/+/master/eric-eea-ci-meta-helm-chart/values.yaml), that can be found in the project-meta-baseline repository. These config sets may contain configuration values for several services/components.

```
validation-config-A:
  robot-filter: default
  utf-metafilter: default
  dataflow-configuration: all-VPs-configuration
  cluster-label: bob-ci
  config-file-path: utf-configs-tmp/configs
  dataset-version: RV_48_20231025
  replay-speed: 1
  replay-count: -1
  package_category: test tool
validation-config-B:
  robot-filter: default
  utf-metafilter: default
  dataflow-configuration: all-VPs-configuration
  cluster-label: bob-ci
  config-file-path: utf-configs-tmp/configs
  dataset-version: RV_48_20231025
  replay-speed: 1
  replay-count: -1
  package_category: test tool
```

#### TODO

* Validating values file changes: When changing config sets in the values files, only one config change per commit should be allowed.
  * To ensure that configfile structure won't be broken in the future tickets, patchset hook checks should be defined
  * we also need to check changes in prepare:
    * validation logic in prepare is as follows: prepare pipeline is started with `VALIDATION_CONFIG_NAME`. It checks which configset changed in the change (eg: A, B, ..), we override the `VALIDATION_CONFIG_NAME` environment variable with the changed config, and save this change to artifact.properties file. Spinnaker reads this file and uses this validation config.
    * Need to decide what to do if the pipeline started with config A (eg. by default), but the change is in config B? -> we fail the pipeline? Or we continue with config B? (this latter seems to be the better solution)
* shouldn't we include some suffixes for different config entries (eg. eric-eea-utf, ci-, dimtool?), eg:

```
validation-config-A:
  eea-robot-filter: default
  eric-eea-utf-metafilter: default
  eric-eea-utf-dataflow-configuration: all-VPs-configuration
  eric-eea-utf-config-file-path: utf-configs-tmp/configs
  dataset-version: RV_48_20231025
  eric-eea-utf-replay-speed: 1
  eric-eea-utf-replay-count: -1
  ci-cluster-label: bob-ci
  package_category: test tool
```

### CI Shared library changes

#### ChartValuesUtils

New [ChartValuesUtils](https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master/src/com/ericsson/eea4/ci/ChartValuesUtils.groovy) class was created in order to read information from the meta helm chart values.yaml (the file that contains the config sets)

##### TODO

* Add functional tests for the ChartValuesUtils class

### Pipeline changes

Our Spinnaker pipelines need to be updated to handle multi-config according to the example pipelines.

#### Spinnaker pipeline changes

* Pipeline: <https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=multi-config-staging>
* Pipeline config: <https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/configure/2e67f5ab-23f9-4c19-8a75-b9d6c0dbcd8a>

* `VALIDATION_CONFIG_NAME` (see Configuration part of the pipeline) parameter (fixed string or coming from artifact.properties) determines which configset will be used from the `project-meta-baseline/eric-eea-ci-meta-helm-chart/values.yaml` file.
* In the Install/Upgrade stages of the Spinnaker pipeline `CLUSTER_LABEL` should be set up to use the value from the prepare job's artifact.properties file's `DESIRED_CLUSTER_LABEL` field. Expression to get the value:`${execution.stages.?[name == "PrepareBaseline"][0]['context']['DESIRED_CLUSTER_LABEL']?:"bob-ci"}`.

#### Jenkins job changes

The test jobs below can serve as an example on how to introduce the multi-config to our pipelines.

##### Prepare jobs

* `VALIDATION_CONFIG_NAME` input param needs to be added to prepare jobs to determine which config set to use
* `DESIRED_CLUSTER_LABEL` is being read from the meta helm chart values.yaml file. The selected config section of this file is specified in `VALIDATION_CONFIG_NAME` param. `DESIRED_CLUSTER_LABEL` is saved to `artifact.properties`, which will be used by Spinnaker in the Install stage.
* `REPLAY_SPEED`, `REPLAY_COUNT` and `DATASET_ID` are used by [dimtool](https://eteamspace.internal.ericsson.com/display/ECISE/%5BStudy%5D+Multi-config+introduction+in+Product+CI#[Study]Multi-configintroductioninProductCI-Dimensioningtool) generation, so these were removed only from the artifact.properties.
* Example job: Config set prepare test: [Jenkins job](https://seliius27190.seli.gic.ericsson.se:8443/job/test-config-set-prepare/), [gerrit change](https://gerrit.ericsson.se/#/c/17095977/)

##### Sanity check

##### Install jobs

* `DESIRED_CLUSTER_LABEL` value (read by Spinnaker from the artifact.properties that generated by the prepare job) needs to be passed - to `CLUSTER_LABEL` job input parameter
* `VALIDATION_CONFIG_NAME` input param needs to be added to the Install jobs
* `VALIDATION_CONFIG_NAME` needs to be passed to eea-product-ci-meta-baseline-loop-utf-and-data-loader-deploy as input parameter
* `env.DATAFLOW_CONFIGURATION` needs to be set in values-list.txt

e.g file path in values-list.txt now:

```
dataflow-configuration/all-VPs-configuration/refdata-values.yaml
```

with multiconfig - `DATAFLOW_CONFIGURATION` should be replaced in the file with the actual env value

```
dataflow-configuration/DATAFLOW_CONFIGURATION/refdata-values.yaml
```

* Example job: Install with multiconfig [jenkins job](https://seliius27190.seli.gic.ericsson.se:8443/job/test-config-set-install/), [gerrit change](https://gerrit.ericsson.se/#/c/17674579/)

##### Meta prepare refactor

* change: <https://gerrit.ericsson.se/#/c/17116185/> - changed logic to check dataset information change between master and checked out change

##### Meta baseline loop UTF and data loader deploy job changes

* Example job - meta deploy: [Jenkins job](https://seliius27190.seli.gic.ericsson.se:8443/job/test-config-set-meta/), [gerrit change](https://gerrit.ericsson.se/#/c/17730178)
* `VALIDATION_CONFIG_NAME` input param needs to be added to the job
* Robot- and utf values (`ROBOT_FILTER`, `UTF_METAFILTER`, `DATAFLOW_CONFIGURATION`, `UTF_CONFIG_PATH`, `UTF_DATASET_ID`, `UTF_REPLAY_SPEED`, `UTF_REPLAY_COUNT`) being loaded to env (with chartValuesUtils) according to the selected (`params.VALIDATION_CONFIG_NAME`) validation config, and being written to meta_baseline.groovy artifact.

##### Upgrade jobs

## Service specific multi-config introduction steps

Components (and their corresponding config fields) currently used with multi-config

### CI specific config values

* cluster-label - can be used for jobs to select the desired cluster setup (eg: small cluster)
* package_category

### CMA

#### TODO

* Shared lib [GlobalVars](https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master/src/com/ericsson/eea4/ci/GlobalVars.groovy) dataflow configuration handling needs to be updated, `DATAFLOW_CONFIG_PATH` variable has to be replaced in env variable in install and upgrade Jenkinsfiles.
At this moment CMA config is under the dataflow-configuration, so new meta value not needed

instead of this:

```
static def cma_config_path = "dataflow-configuration/all-VPs-configuration/cma/all-in-one.json"
```

this:

```
static def cma_config_path = "dataflow-configuration/DATAFLOW_CONFIG_PATH/cma/all-in-one.json"
```

### UTF

* No change in [UtfTrigger](https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master/src/com/ericsson/eea4/ci/UtfTrigger2.groovy) - the same env variabless are being used (`UTF_DATASET_ID`, `UTF_REPLAY_SPEED`, `UTF_REPLAY_COUNT`).

#### utf specific config values

* utf-metafilter
* dataflow-configuration
* config-file-path
* dataset-version
* replay-speed
* replay-count

#### TODO

The UTF metafilter parameters can differ for every Jenkins jobs, they are currently hardcoded in the Jenkins jobs themselves, but we need to be able change them by using different config sets.
Current proposal is to only *add* extra filter values from the config sets, by concatenating them to the current filters.

examples:

Original filter:

```
"@decisive and @nx1 and @staging and not @onlyUpgrade and not @tc_under_development"
```

filter from config:

```
"and @confA"
```

result:

```
"@decisive and @nx1 and @staging and not @onlyUpgrade and not @tc_under_development and @confA"
```

if filter in config empty, filter from config:

```
""
```

result (same as original):

```
"@decisive and @nx1 and @staging and not @onlyUpgrade and not @tc_under_development"
```

### RV Robot

#### RV Robot specific config values

* robot-filter

#### TODO

Similar to UTF metatags, the proposed solution is to concatenate the values from the config sets to the existing robot tags (currently in [eea_product_ci_meta_baseline_loop_test.Jenkinsfile](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/pipelines/eea_product_ci_meta_baseline_loop/eea_product_ci_meta_baseline_loop_test.Jenkinsfile) [eea_common_product_upgrade.Jenkinsfile](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/technicals/eea_common_product_upgrade.Jenkinsfile).

Details about robot tags: <https://robotframework.org/robotframework/latest/RobotFrameworkUserGuide.html#tag-patterns>

original:

```
env.ROBOT_TAGS = "decisiveNOTdashboard"
```

filter from config:

```
"ANDconfA"
```

result:

```
env.ROBOT_TAGS = "decisiveNOTdashboardANDconfA"
```

empty filter value from config:

```
""
```

result:

```
env.ROBOT_TAGS = "decisiveNOTdashboard"
```

### Dimensioning tool

#### TODO

* dimtool part shouldn't be implemented as of now, as it is expected to change a lot, BUT we are waiting for the changes, and when they are finished, we need to implement it. After Ticket <https://eteamproject.internal.ericsson.com/browse/EEAEPP-98076> is done, a new dimtool job will be triggered from prepare jobs, and we have to be able to pass the followings to this job from the configsets:
  * `dataset-version`
  * `config-file-path` (dimtool config in utf)
    * todo: ticket for refactor config files inside UTF image (current solution cannot detect when change happens)
  * `replay-speed`
  * `replay-count`

## Possible pitfalls during testing

* Before triggering any test runs, make sure to validate that the test config set values are up-to-date.
