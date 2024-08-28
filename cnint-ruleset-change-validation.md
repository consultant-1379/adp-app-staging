# Product CI ruleset validation

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Bob ruleset

Documentation: <https://gerrit.ericsson.se/plugins/gitiles/adp-cicd/bob/+/HEAD/USER_GUIDE_2.0.md>

## Product CI rulesets

### [ruleset2.0.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/ruleset2.0.yaml)

### [other ruleset files](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/bob-rulesets/)

## Validation steps

* patch-set hooks
* Review
* Dry run
* Functional tests

## Code review guide for ruleset changes

[documentation for ruleset changes](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/product-ci-bob-ruleset.md#Code-review-guide-for-ruleset-changes)

## Ruleset change triggered tests

* ruleset_change-nhotification, sending teams channel notification about any change in ruleset2.0.yaml
* eea_app_baseline_manual_flow_precodereview, if there is any change next to a ruleset modification, gives -1 to the patchset
* patchset_hooks_cnint, testing if the ruleset is executable or not
* patchset_hooks_cnint triggers job ruleset-change-validate to validate automatically some of the design rules

## Things to check

[see here](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/product-ci-bob-ruleset.md#Code-review-guide-for-ruleset-changes)

## Dry run

```
arr=($(bob/bob --list -qq))
export DOCKER_USERNAME="test"
export DOCKER_PASSWORD="test"
export CHART_NAME="test"
export CHART_REPO="test"
export CHART_VERSION="test"
export GERRIT_USERNAME="test"
export GERRIT_PASSWORD="test"
export GERRIT_REFSPEC="test"
export GERRIT_MSG="test"
export GIT_COMMIT_ID="test"
export JENKINS_URL="test"
export JOB_NAME="test"
export BUILD_NUMBER="test"
export INT_CHART_REPO="test"
export KUBECONFIG="test"
export UTF_INCLUDED_STORIES="test"
export UTF_META_FILTER="test"
export UTF_PRODUCT_NAMESPACE="test"
export UTF_TEMPLATE_SUBTYPE="test"
export UTF_TEMPLATE_TYPE="test"
export UTF_TEMPLATE_ID="test"
export UTF_TEMPLATE_NAME="test"
export UTF_TEST_NAME="test"
export UTF_SERVICE_PORT="test"
export UTF_TEST_EXECUTION_ID="test"
export UTF_TEST_TIMEOUT="test"
for cmd in "${arr[@]}"; do bob/bob $cmd --dryrun; done;
```

## Design rule validation

Jenkins job ruleset-change-validate validates some of the design rules for bob ruleset files
A yaml file is bob ruleset file if the first row contains "modelVersion: 2.0"
The validation results commented into the gerrit.

Validations:

### Validate properties bob function

Using bob argument --validate-properties to checks if properties used in rules within the ruleset are declared before usage.

```
bob/bob -r ruleset2.0.yaml --validate-properties
```

### Validate refs

Using bob argument --validate-refs we validate all task, rule and condition references then exit.

```
bob/bob ruleset2.0.yaml --validate-refs

```

### Validate unused variables

Validate if all the declared proprties, env, var, image and imports are used.

### Validate imported files

We don't want to have many ruleset files imported to each other, because that make testing a change more difficult so only white-lited files allowed to import

### Validate docker images available

TODO Validate docker images available with docker manifest inspect
TODO do not use latest , use fix version

### Validate logic implemented

TODO do not implement logic in ruleset files, do not use conditions [see adp documentation](https://gerrit.ericsson.se/plugins/gitiles/adp-cicd/bob/+/HEAD/USER_GUIDE_2.0.md#Using-condition)
TODO do not use adp docker-images for simple helm, shell, kubectl command, jq,yq,

### Validate with shellcheck

TODO validate shell commands with shellcheck

## Functional tests

In case of a rulest change in the stages of [EEA Aplication Stages](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-application-staging) in the Jenkins jobs we cherry picking the triggering change to the master branch and use this state for the validation process.
If the eea-application-stages trigger were the adp loop, an ms drop or other manual change, we use the ruleset from the master.
Special case of the ruleset changes, when we should add the ruleset change to the PRA branch. The validation of the baseline install has to be tested manually at this moment.  TODO add link to the documentation <https://eteamproject.internal.ericsson.com/browse/EEAEPP-83487> and <https://eteamproject.internal.ericsson.com/browse/EEAEPP-83485>
