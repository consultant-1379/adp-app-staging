# EEA4 Product CI docker image versions autouplift weekly loop job

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Description

This scheduled job loops through all the repositories given in an input list, checks the docker image versions in the ruleset files, and replaces the image version strings if newer image versions has been found to ensure that every ruleset uses the latest *stable* docker images.

After updating the docker versions in the ruleset files, it creates a commit in the repository and pushes the changes to a gerrit ref. Then it starts a validation job for the given repository to test if raising the image versions caused any issues.

After the validation of a repository, a message is sent to the driver channel with the results. If the validation was successful, the current driver should approve the commit created in the previous step.

Currently the job is set up for cnint, adp-app-staging, eea4_documentation, project-meta-baseline and ci_shared_libraries repositories, but could be easily set up for others as well.

## Setup

### Prerequisites

The job uses the [CI Toolbox version_updater.py](https://gerrit.ericsson.se/plugins/gitiles/EEA/general_ci/+/refs/heads/master/docker/toolbox/#version_updater_py) for the version update. For more info on this tool, please refer to the [linked](https://gerrit.ericsson.se/plugins/gitiles/EEA/general_ci/+/refs/heads/master/docker/toolbox/#version_updater_py) documentation.

#### Repositories to be uplifted

For every repositories we want to setup to be used with the autouplift job, a configuration file (`version_auto_uplift_config.yaml`) must be defined.
The uplift configuration file with defined name will be generated with the following structure:

```
# EXAMPLE OF THE UPLIFT CONFIG FILE
allowed_types:
  - rulesets

# ruleset paths relative to the git root, not to this file
rulesets:
  - ruleset2.0.yaml:
      path: "ruleset2.0.yaml"
  - ruleset2.0_product_release.yaml:
      path: "ruleset2.0_product_release.yaml"
  - csar_build.yaml:
      path: "rulesets/csar_build.yaml"
  - describepod.yaml:
      path: "rulesets/describepod.yaml"
  - performance_db_rules.yaml:
      path: "rulesets/performance_db_rules.yaml"
  - cnis_test_ruleset2.0.yaml:
      path: "technicals/cnis_test_ruleset2.0.yaml"
```

#### Cnint repository

The [ruleset2.0.version.auto.uplift.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/bob-rulesets/ruleset2.0.version.auto.uplift.yaml) file with rules for running the version_updater.py script can be found in the cnint repository.

Among others, this ruleset tells the script with the `VERSION_UPDATER_CONFIG_PATH` environment variable, where the configuration file that contains the list of the rulesets to be uplifted for a given repository can be found.

```
VERSION_UPDATER_CONFIG_PATH (default=./cnint/bob-rulesets/version_auto_uplift_config.yaml)
```

## Execution steps

### Input parameters

* `DRY_RUN`: dry run
* `DUMMY_RUN`: **For testing purposes!** Running the job with this parameter set to `true`, the job skips the most expensive steps:
  * the job won't commit and push to Gerrit
  * Calls the verification job with `DRY_RUN = True`
* `CNINT_GERRIT_REFSPEC` - Cnint repository refspec - in case we want to make & test changes in the main version updater ruleset `ruleset2.0.version.auto.uplift.yaml`, we can give a specify the refspec of the cnint change, and the script will use this refspec.

### Environment variables used

* `CNINT_WORKDIR` - tells the job which path to clone the cnint repository instance, whose ruleset2.0.version.auto.uplift.yaml will be used by the script (*note: since we do uplift cnint repository too, this instance is cloned separately from the one that shall be uplifted.*)
* `VERSION_UPDATER_CONFIG_PATH` - this is set for every repository according to the `upliftConfigRuleset` field of `repos[]` list to point to the `version_auto_uplift_config.yaml` file in that repository.

## Repository settings

At the beginning of the Jenkinsfile, in the `repos` list we can specify the following settings for every repo we want to uplift:

* `project`: - **mandatory**, name of the git repository (in a format to be used with shared library's GitScm)
* `upliftConfigRuleset` - **mandatory**, path of the `version_auto_uplift_config.yaml` config file in this repository. Will be set in env to be used by bob rule. The config will be automatically generated, the config will be named with the specified name
* `ref` - optional, can be used to specify a refspec of this repo for testing purposes. Default value is master (in case of empty string or if its completely omitted).
* `validatorJob` - optional, the job which can be run to validate if the image image uplift caused any issues. If no validator job was specified (left empty or omitted), a warning is written in the log.
* `validatorJobExtraParams` - optional, in case the job needs some other parameters (above the `currentRepoGerritRefspec` refspec of the generated commit and the `DRY_RUN` option)
* `ignore_images_list` - list of images that WILL NOT BE uplifted in rulesets in this repo

```
def repos = [
    [
        "project": "EEA/cnint",
        "upliftConfigRuleset": "cnint_version_auto_uplift_config.yaml",
        "validatorJob": "eea-application-staging-batch",
        "validatorJobExtraParams":
        [
            ["_class": "StringParameterValue", "name": "PIPELINE_NAME", "value": "eea-application-staging"],
            ["_class": "StringParameterValue", "name": "WAIT_FOR_CLUSTER_LOG_COLLECTOR_RESULT", "value": "true"]
        ]
    ],
    [
        "project": "EEA/eea4_documentation",
        "upliftConfigRuleset": "eea4_documentation_version_auto_uplift_config.yaml",
        // todo: set validatorJob for eea4_documentation after validation logic is clarified
        // "validatorJob": "eea-application-staging-documentation-build"
    ],
    [
        "project": "EEA/adp-app-staging",
        "upliftConfigRuleset": "adp-app-staging_version_auto_uplift_config.yaml"
    ],
    [
        "project": "EEA/project-meta-baseline",
        "upliftConfigRuleset": "project-meta-baseline_version_auto_uplift_config.yaml",
        "ignore_images_list": ["eric-eea-robot"]
    ],
    [
        "project": "EEA/ci_shared_libraries",
        "upliftConfigRuleset": "ci_shared_libraries_version_auto_uplift_config.yaml"
    ],
    [
        "project": "EEA/jenkins-docker",
        "upliftConfigRuleset": "jenkins_docker_version_auto_uplift_config.yaml"
    ]
]
```

*todo: later these repo-specific input data should come from some form of input parameters or config file, especially if this job will be introduced to more repositories*.

## Step-by-step execution

* The script is triggered by schedule.
* First it checks out cnint repository for the latest ruleset2.0.version.auto.uplift.yaml bob ruleset to be used for running the version_updater.py
* checks out submodules (bob)

After these preparation it iterates the script iterates over the input repolist (`repos`), and with the `upliftImage` helper it dynamically generates and returns the steps for every repository, then runs them:

* Checks out the given repository (master by default or any refspec, if specified)
* Generates uplift config and archives generated config as a Jenkins artifact
* Starts the uplifting with the `ruleset2.0.version.auto.uplift.yaml` bob rule defined in cnint repo, removes generated in the previous step uplift config
* If the uplift was successful, (and DUMMY_RUN parameter is false) creates a commit and pushes the changes to gerrit
* If a validator job was specified, it starts the commit validation. First it queries the last successful (not DRY_RUN) build of the validator job, and gives them as input parameters to the upcoming validaton job.
* Important! `GERRIT_REFSPEC` and `DRY_RUN` parameters that came from the last successful job will be overriden with the refspec of the commit created in the previous step, and with `true` in case `DUMMY_RUN` was specified.
* If any `validatorJobExtraParams` was specified, the respective parameters of the last successful run will be overriden too, with the ones in validatorJobExtraParams.
* If validator job was successful too, a message is sent to the driver channel with the result for that repo, and the refspec of the commit to be approved by the driver. In case of an error, an error message is sent.
