# Product CI bob rulesets

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Bob ruleset

Documentation: <https://gerrit.ericsson.se/plugins/gitiles/adp-cicd/bob/+/HEAD/USER_GUIDE_2.0.md>

## Product CI rulesets

We have a ruleset2.0.yaml file almost every Product Ci repositories, and some more under bob-rulests directory.
These files used in the product ci loops and other technical Jenkins jobs or from the Product CI shared lib.

### Product CI bob rulesets design rules

#### keep rules simple:

* do not implement logic in ruleset files
* do not import other ruleset yaml files than util (e.g. init config files) or config files
* do not use conditions (<https://gerrit.ericsson.se/plugins/gitiles/adp-cicd/bob/+/HEAD/USER_GUIDE_2.0.md#Using-conditions>)
* do not use adp docker-images for simple helm, shell, kubectl command
* one topic - one ruleset file
* do not call rule from shared libray if not necessary

#### keep rules where they belong

* create ruleset and rules in reporitory where the rule will be used. Eg. a rule used by meta baseline should be in project-meta-baseline
* rules used by product ci only (like cluster maintainenace and log collection other technical rules) should be in the product ci code repo: adp-app-staging
* ruleset changes for baseline install should added to the PRA branch of the cnint TODO

#### always update tests and validations

* always update [test plan](https://eteamspace.internal.ericsson.com/display/ECISE/Test+plan+for+Product+Ci+ruleset+changes+-+EEAEPP-81576) during development, before closing a ticket , TODO this should be part of the template for new Product Ci tasks
* all rule should have a dry-run in patchset hook TODO this should be part of the template for new Product Ci tasks

#### auto image uplift

Documentation: <https://eteamspace.internal.ericsson.com/display/ECISE/EEA4+Product+CI+docker+image+versions+autouplift+weekly+loop+job>

* all imported image should have fixed version
* all yaml files with imported images should be in the config ruleset2.0.version.auto.uplift.yaml

#### kubectl versions

For kubectl commands to be able to use a specific kubectl version, we should pass the KUBECT_VERSION env variable in our rules as a docker flag:

```
env:
  (...)
  - KUBECTL_VERSION (default=1.25.3)

rules:
  create-ns-and-arm-pullsecret:
    - task: create-ns-and-arm-pullsecret
      docker-image: k8-test
      docker-flags:
        - "--network=host"
        - "--env KUBECONFIG=${env.KUBECONFIG}"
        - "--env KUBECTL_VERSION=${env.KUBECTL_VERSION}"
        - "--volume ${env.KUBECONFIG}:${env.KUBECONFIG}:ro"
      cmd:
        - 'kubectl delete ns ${env.NAMESPACE} --ignore-not-found=true'

```

**todo** - `KUBECTL_VERSION` is not yet implemented in all the used images (eg ci-toolbox, eric-eea-utils-ci), however, for the future it's considered best practice to pass the environment variable anyways.

#### Rules validation

Test plan: <https://eteamspace.internal.ericsson.com/display/ECISE/Test+plan+for+Product+Ci+ruleset+changes+-+EEAEPP-81576>

## Validation steps

* Review
* Dry run
* Functional tests

## Code review guide for ruleset changes

### During the review of a ruleset change, reviewer should check:

* the change itself in line with design rules
* if new docker image added, check if it is available in the artifactory

Example:

```
docker manifest inspect armdocker.rnd.ericsson.se/proj-eea-drop/eric-eea-utils-ci:2.21.0-10 > /dev/null ; echo $?
```

* the Jira ticket of the this change and the further steps needed, like :
  * updating the dry-run patchset hooks
  * updating the ruleset2.0.version.auto.uplift.yaml (until this file not automated)
  * updating the manual [test plan](https://eteamspace.internal.ericsson.com/display/ECISE/Test+plan+for+Product+Ci+ruleset+changes+-+EEAEPP-81576) link
  * updating the automated validation tests in patchset hooks patchset hooks or in the validations run by the docker-image-versions-autouplift-weekly-loop or in codereview-ok Jenkins jobs
* if property added or removed, check if it is used anywhere
* if env added or removed it should be updated also in the patchset hook dry-run stages
* if removing rules check if  unused var-s, env-s, properties-s, docker-images removed as well
* if environment variable added or removed, check if it is available in the environment where the ruleset is called | check if it is removed from everywhere or in the ticket if there is an AC to remove/create them later
* existing rules can be modified only backward compatible
* Ruleset removals in cnint have to be announced in advance on CI CoP meetings so that any changes can be made by other teams

## Ruleset change triggered tests

* ruleset_change-notification in cnint, sending teams channel notification about any change in ruleset2.0.yaml
* eea_app_baseline_manual_flow_precodereview, if there is any change next to a ruleset modification, gives -1 to the patchset
* patchset_hooks, testing if the ruleset is executable or not [EEAEPP-83142](https://eteamproject.internal.ericsson.com/browse/EEAEPP-83142)
* the most critical jobs have to be triggered for validation in precodereview or in codereview ok jobs see [test plan](https://eteamspace.internal.ericsson.com/display/ECISE/Test+plan+for+Product+Ci+ruleset+changes+-+EEAEPP-81576)

### Dry run

In patchset_hooks we are running dry-runs for the rules to validate each bob rule whether they are executable or not.

#### Testing the existence of the rules

This can be done by using the following command (produces a list of rules in the ruleset)

```
bob --list -qq
```

This can be further processed by testing the produced value against a predefined list.

#### Testing the rules individually whether they are executable

The following method dry-runs all rules in the ruleset to ensure correct syntax and executability within bob:

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

### Functional tests

If the changed rule used during the staging loop during the validation and publish of the change itself, the change always should be cherry picked, and use that state for the validation.
Other staging pipelines always using the master of that repo.
When the changed rule not used/validated during the loop, the Jenkinsfile which are using those rules should be tested manualy or triggered automaticaly
