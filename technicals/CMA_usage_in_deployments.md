# CMA configurations in product deployments

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## CMA integration study

[EEAEPP-81492 Integrate CMA to Product CI](https://eteamspace.internal.ericsson.com/display/ECISE/EEAEPP-81492+Integrate+CMA+to+Product+CI)

## HELM_AND_CMA_VALIDATION_MODE

Until CMA phase 3 product CI has to validate both with CMA and HELM. All install and upgrade can be triggered both way, and is able to run validation using  HELM or CMA configuration.
After this transition period the HELM based steps and variables should be removed.

### CMA validation mode

Stages related to CMA configuration load:

* Create stream-aggregator configmap
* Load config json to CM-Analytics
* Run health check after CM-Analytics config load - run HC as usual
* Run CMA health check after CM-Analytics config load - run only CheckCMA class from HC

For running the validations with CMA configurations, after install the CMA configurations has to be loaded.
Configuration file path in cnint repo:

* dataflow-configuration/all-VPs-configuration/cma/correlator-content-version.json
* dataflow-configuration/all-VPs-configuration/cma/all-in-one.json

Configurations can be loaded using rule load-cm-analytics-config-cubes-into-eea from ruleset2.0.yaml

### Create stream-aggregator configmap

From the dimtool generated output a stream-aggregator value file has to be loaded as configmap

Value file in the dimtool generated output: aggregator_values_cma.yaml
CMA required the file with name stream-aggregator-dimensioning.yam so we are renaming it as workaround util the fix

Shared library function for create the configmap: createAggregatorConfigmapFromDimtoolOutput

Ruleset for creating the configmap: cnint/bob-rulesets/dimtool_ruleset.yaml apply-stream-aggregator-dimensioning

### HELM validation mode

In case of HELM based validation the CMA configuration has to be disabled by adding a helm-values/disable-cma-values.yaml to the install steps in stage Set CMA helm values:

* values-list.txt
* mxe-values-list.txt

CMA load and HC skipped in this mode

### Legacy mode

This mode was used before CMA validation was enabled product level, not used any more
