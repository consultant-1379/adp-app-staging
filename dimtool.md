# Dimtool in Product CI

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## General

Dimtool ruleset stored in the [cnint repo](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/bob-rulesets/dimtool_ruleset.yaml)

## Usage in Product CI

### The Dimensioning Tool output is created in Prepare jobs:

+ [eea-adp-staging-adp-prepare-baseline](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-adp-staging-adp-prepare-baseline/) [source](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/pipelines/eea_adp_staging/eea_adp_staging_adp_prepare_baseline.Jenkinsfile)
+ [eea-application-staging-baseline-prepare](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-baseline-prepare/) [source](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/pipelines/eea_application_staging/eea_application_staging_prepare_baseline.Jenkinsfile)
+ [eea-product-ci-meta-baseline-loop-prepare](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-ci-meta-baseline-loop-prepare/) [source](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/pipelines/eea_product_ci_meta_baseline_loop/eea_product_ci_meta_baseline_loop_prepare.Jenkinsfile)
+ [eea-application-staging-product-baseline-install](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-product-baseline-install/) [source](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/pipelines/eea_application_staging/eea_application_staging_product_baseline_install.Jenkinsfile)

In Product CI install pipelines we are using the Dimensioning Tool output for EEA4 Product Installation.
Install pipelines download automatically the Dimensioning Tool output from ${DIMTOOL_OUTPUT_REPO_URL/artifactory/${DIMTOOL_OUTPUT_REPO}/${DIMTOOL_OUTPUT_NAME} and use the extracted eea4-dimensioning-tool-output/Cluster name/values.yaml - as helm-values/eea4-dimensioning-tool-output-values.yaml - during install.

The [eea-application-staging-product-baseline-install](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-product-baseline-install/) is the special case, in this job we store the genarated file (eea4-dimensioning-tool-output-values.yaml) in "install-configvalues.tar.gz" as Jenkins artifact. This file will be used during Software Upgrade as well.

### Install job where we are using the Dimensioning Tool Output

+ [eea-adp-staging-adp-nx1-loop](https://seliius27190.seli.gic.ericsson.se:8443/view/EEA%20ADP%20Staging%20View/job/eea-adp-staging-adp-nx1-loop/) [source](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/pipelines/eea_adp_staging/eea_adp_staging_adp_nx1_loop.Jenkinsfile)
+ [eea-application-staging-batch](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-batch/) [source](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/pipelines/eea_application_staging/eea_application_staging_batch.Jenkinsfile)
+ [eea-application-staging-nx1](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-nx1/) [source](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/pipelines/eea_application_staging/eea_application_staging_nx1.Jenkinsfile)
+ [eea-product-ci-meta-baseline-loop-test](https://seliius27190.seli.gic.ericsson.se:8443/view/EEA%20Product%20CI%20Meta-baseline%20loop%20View/job/eea-product-ci-meta-baseline-loop-test/) [source](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/pipelines/eea_product_ci_meta_baseline_loop/eea_product_ci_meta_baseline_loop_test.Jenkinsfile)
+ [eea-application-staging-product-baseline-install](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-product-baseline-install/) [source](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/pipelines/eea_application_staging/eea_application_staging_product_baseline_install.Jenkinsfile)

## Dimtool bob-rule WoW

1. Prepare namespace
    > Сopies dimtool dependencies (integrations) and creates a directory with examples
1. Download dimtool
    > Downloads and unpacks dimtool from arm
1. Download plugins
    > Downloads and unpacks dimtool plugins from arm
1. Get UTF configs
    > Gets utf-configs from the eric-eea-utf-docker image
1. Test example configs
    > Tests dimtool configs provided as an example
1. Generate input
    > Generates dummy dimtool input and updates it with the python script
1. Test dimtool
    > Generates dimtool output using input from the previous step
1. Filter output
    > Filters non-upgradable Helm configs
1. Validate output
    > Validates generated output
1. Archive artifacts
    > Archives user_input, output and dimtool itself

### Requirements

+ We have to get utf configs (data_sets.yml, pcap_metadata.yml, network_function_metadata.yml) from the eric-eea-utf-docker docker image before calling dimtool-trigger to get the dataset description (configs) used by Product CI. We should use a versioned source. To get those configs we have to execute a few steps. All these steps are implemented in the dimtool bob-ruleset

1. Get `eric-eea-utf-application` chart version from the project-meta-baseline git repository
1. Download and extract the received version of the `eric-eea-utf-application` helm chart
1. Get `eric-eea-utf-docker` docker image version from the values.yaml inside the `eric-eea-utf-application` helm chart
1. Get utf-configs from received docker image

+ We have to generate a dummy dimtool configuration using `deployment.js` from the EEA/cnint:dimensioning-tool-ci/user_input repo before running input generation script and dimtool output generation in order to have the correct format of dimtool input files.

## Dimtool input/output generation

To generate the dimtool input, we use the [dimtool-input-generator.py](https://gerrit.ericsson.se/plugins/gitiles/EEA/general_ci/+/master/docker/toolbox/tools/dimtool-input-generator.py) script.

+ CONFIG_PATH - UTF configs checked out from the eea4-bbt repo ***#TODO: We can't checkout those configs from the master branch, so this will be updated to use a versioned source***
+ DATASET_NAME - the name of the dataset that is used for Product CI. Sometimes the dataset changes, so we must update the dataset name in the cnint repository if necessary.
+ JS_FILE - path to `dc.js` file obtained from the dummy dimtool config

        usage: dimtool-input-generator.py [-h] -c CONFIG_PATH -d DATASET_NAME -r
                                          REPLAY_SPEED -j JS_FILE

        A script to calculate input parameters for the dimensioning tool, based on the
        selected traffic.

        optional arguments:
          -h, --help            show this help message and exit
          -c CONFIG_PATH, --config_path CONFIG_PATH
                                Config directory full path, where the dataset related
                                YAML files are stored: data_sets.yml,
                                pcap_metadata.yml, network_function_metadata.yml.
          -d DATASET_NAME, --dataset_name DATASET_NAME
                                Dataset name, (available in the data_sets.yml file),
                                e.g. EEA43_20211217
          -r REPLAY_SPEED, --replay_speed REPLAY_SPEED
                                Replay speed, e.g. 0.5
          -j JS_FILE, --js_file JS_FILE
                                The fullpath of parameters js file (generated by
                                dim.tool) that should be modified. The new js files
                                (params.js and deployment.js) will be created in the
                                same directory. If -j is not specified, then script
                                will only print the calculated values for the given
                                data set to standard output.

## Dimtool output usage during Upgrade

### Prepare upgrade values files step

Getting Dimensioning Tool output from eea-application-staging-product-baseline-install job for Software upgrade steps

+ Get the product-baseline-install configmap from locked cluster and read the content to Jenkins enviroment variables.
++ the BASELINE_BUILD_URL will be avaiable as Jenkins enviroment variables
+ save from the eea-application-staging-product-baseline-install the install-configvalues.tar.gz
+ rename to baseline-install-configvalues.tar.gz and extract it to baseline_install_configvalues
+ archive as Jenkins artifact the "baseline-install-configvalues.tar.gz"

### Dimensioning Tool output usage for Config upgrade steps

#### Jenkins DIMTOOL_OUTPUT_NAME params is set

If the Dimensioning Tool was executed during the Prepare job then the output file path will be set into DIMTOOL_OUTPUT_NAME

+ Download from Artifactory the eea4-dimensioning-tool-output.zip and extract it
+ copy values.yaml to helm-values as eea4-dimensioning-tool-output-values.yaml

#### Jenkins DIMTOOL_OUTPUT_NAME params is empty

Some cases we won't execute Prepare Job before the eea-common-product-upgrade execution.
In this case we will generate Dimensioning Tool output during the eea-common-product-upgrade execution.

+ in eea-common-product-upgrade we pull from Gerrit the project-meta-baseline master state and get from there the Dataset information's: dataset-version, replay-speed, replay-count and configuration which is store inside the utf docker image
+ for the Dimensioning Tool output generation use the already downloaded eric-eea-int-helm-chart*.tgz
+ copy values.yaml to helm-values as eea4-dimensioning-tool-output-values.yaml

### What's remains:

Handle the case when by helm unchangeable - e.g: persistentVolumeClaim - values change between baseline and new release

#### What can we do now

In this case the integration will fail with helm issue.
We have to find differences between helm values and add greater value into helm-values/custom_prod_ci_dimensioning_values.yaml or helm-values/custom_prod_ci_mxe_dimensioning_values.yaml and comment why it's necessary

+ if the greater value in the master than apply to the fix to cnint release branch
+ if the greater value in the cnint release branch than apply to the fix to cnint master

### Dimtool output filtering for Upgrade - will be implemented later on

As Dimtool output contains non-upgradeable configs for Helm, so Prod CI has to filter out these from the Dimtool output before starting upgrades.
The filtering uses [cnint/dimensioning-tool-ci/black.list](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/dimensioning-tool-ci/black.list) as input.

The filtered output values_filtered_by_blacklist.yaml stored beside the non-filtered values.yml at ARM.
e.g:
<https://arm.seli.gic.ericsson.se/artifactory/proj-eea-reports-generic-local/dimtool/prod_ci_artifacts/eea-adp-staging-adp-prepare-baseline-8366/eea4-dimensioining-tool-output.zip>

When the [cnint/dimensioning-tool-ci/black.list](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/dimensioning-tool-ci/black.list) is changed by a patchset then validation in the [eea-application-staging-baseline-prepare](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-baseline-prepare/) job checks out the contect from the latest patchset.

## Dimtool output validation

Dimtool output validation is the optional step which can by enabled by passing "DIMTOOL_VALIDATE_OUTPUT" environment variable into dimtool bob-rule execution.

Validation implemented with the `helm template` command

    helm template .bob/eric-eea-int-helm-chart*.tgz --values "$custom_value_file" || exit 1;

## Verify dimtool resource requests match ProdCI capacity

1. Validation is done in the eea-application-staging-baseline-prepare Jenkins job
1. Below is the verification script usage

        python3 verify_productci_capacity.py -ih <html_cluster_infos_path> -id <dimtool_output_values_yaml_path> -x <clusters_to_exclude>

        usage: verify_productci_capacity.py [-h] [-ih INPUT_HTML] [-id INPUT_DIMTOOL]
                         [-x [EXCLUDE [EXCLUDE ...]]]

        This script compares free resources from the Product_CI_cluster_infos HTML page with dimtool requests to verify that ProductCI has enough capacity.
        As an output, we can get different exit codes:
        0 - ProductCI has enough resources
        10 - Not enough CPU resources in ProductCI
        20 - Not enough Memory resources in ProductCI
        30 - Not enough CPU and Memory resources in ProductCI

        optional arguments:
        -h, --help            show this help message and exit
        -ih INPUT_HTML, --input_html INPUT_HTML
                                Path of the html input file
        -id INPUT_DIMTOOL, --input_dimtool INPUT_DIMTOOL
                                Path to the values.yaml generated by the dimtool
        -x [EXCLUDE [EXCLUDE ...]], --exclude [EXCLUDE [EXCLUDE ...]]
                                Cluster or list of clusters to exclude. Eg.:
                                cluster_productci_appdashboard cluster_productci_2452

1. Script output is an exit code:

    + 0 - ProductCI has enough resources
    + 10 - Not enough CPU resources in ProductCI
    + 20 - Not enough Memory resources in ProductCI
    + 30 - Not enough CPU and Memory resources in ProductCI

## Dimtool artifacts

The generated input is stored in ARM in the <https://arm.epk.ericsson.se/artifactory/proj-eea-reports-generic-local/dimtool/prod_ci_artifacts/> directory

The generated output is stored in ARM in the <https://arm.epk.ericsson.se/artifactory/proj-eea-reports-generic-local/dimtool/prod_ci_artifacts/> directory

The dimtool itself is stored in the ARM in the <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-internal-generic-local/eea4-dimensioning-tool/> directory

## Additional values for Product CI usage

Currently the Dimensioning Tool output is not in-line with the Product CI testing requirements, because few values are under or over dimensioned.
And for some µService  Dimensioning Tool output does not contains generator plugins.
In such cases it is possible to add additional values to [helm-values/custom_prod_ci_dimensioning_values.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/helm-values/custom_prod_ci_dimensioning_values.yaml) to overwrite Dimensioning tool output which would fix the issue at Product CI pipelines.
If such change is needed this should be delivered by the relevant developer team and has to be reviewed by RV TAs and Dimensioning Tool team before introducing the change to the master or release branch.
Ticket or TR about this issue has to be opened at JIRA and link for that has to be included to the values file in a comment.

## Contacts

+ [EEA_RV_TestArchitects](mailto:PDLEEAINVT@pdl.internal.ericsson.com)
+ [EEA Dimensioning Tool Reviewers](mailto:PDLEEADIME@pdl.internal.ericsson.com)
