# Input sanity check

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Wrapper for sanity check

Jenkins job eea-application-staging-input-sanity-wrapper collect the ms version changes from the parameters and trigger the job input-sanity-check for each microservices which not whitelisted.
Sanity wrapper job also sets the value of the WAIT_FOR_CLUSTER_LOG_COLLECTOR_RESULT in artifact.properties. It can be false, if only microservice versions changed, and those microservices were validated for cleanup in the non-PRA executions.
Functionality of wrapper is working both for + and - version of microservices.

For a manual change, if the Chart.yaml contains version changes against the master, the microservice name will be listed to validation.

For bundled ms changes in drops, all the chart names and versions will be listed for validation.

Triggering the validation will be skipped if the ms or the repo path whitelisted.

The artifacts will be copied and archived from the triggered input-sanity-check job.

Jenkins job files are:

* [`pipelines/eea_application_staging/eea_application_staging_input_sanity_wrapper.Jenkinsfile`](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/pipelines/eea_application_staging/eea_application_staging_input_sanity_wrapper.Jenkinsfile)
* [`jobs/eea_application_staging/eea_application_staging_input_sanity_wrapper.groovy`](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/jobs/eea_application_staging/eea_application_staging_input_sanity_wrapper.groovy)
*

Whitelist :
[`technicals/input_sanity_check_whitelist.yaml`](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/technicals/input_sanity_check_whitelist.yaml)

Example for whitelist:

```
services:
  - eric-csm-st
  - eric-lcm-smart-helm-hooks
  - dimensioning-framework
  - eric-si-application-sys-info-handler
  - eric-adp-gui-aggregator-service
  - eric-oss-schema-registry-sr
repos:
  - proj-adp-gs-all-helm
```

## Sanity check

Jenkins job input-sanity-check validates microservice drops against ADP requiremenets validated by DR checker tools and EEA requirements documented in the relevant [study](https://eth-wiki.rnd.ki.sw.ericsson.se/pages/viewpage.action?spaceKey=ECISE&title=Requirements+for+microservice+level+CI).

Jenkins job files are:

* [`technicals/input_sanity_check.{groovy,Jenkinsfile}`](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/technicals/input_sanity_check.Jenkinsfile).

Whitelist of microservices in [`technicals/coverage_report/input_sanity_check_whitelist.yaml`](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/technicals/coverage_report/input_sanity_check_whitelist.yaml).

Related bob rules in [`bob-rulesets/input-sanity-check-rules.yaml`](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/bob-rulesets/input-sanity-check-rules.yaml) of `cnint` repo.

## Whitelist for input-sanity-check

The whitelist is a list of microservices that can be exempted from checking stages.

Each checking stage in input-sanity-check has a separate list in the whitelist `input_sanity_check_whitelist.yaml`

```
validations:
  non_pra_whitelist:
    services:
  non_pra_upgrade_whitelist:
    services:
    - eric-eea-analysis-system-overview-install
  non_pra_with_helm_whitelist:
    services:
  non_pra_upgrade_with_helm_whitelist:
    services:
    - eric-eea-analysis-system-overview-install
  documentation_deliverables_whitelist:
    services:
...
```

For example,the microservice `eric-eea-analysis-system-overview-install` is skipped by stage `Non-PRA execution check`, because `non_pra_whitelist` lists this service as an exemption.

Repo path: [`adp-app-staging/technicals/coverage_report/input_sanity_check_whitelist.yaml`]

**Note**: For the [CMA transition](https://eteamspace.internal.ericsson.com/display/ECISE/EEAEPP-81492+Integrate+CMA+to+Product+CI) we introduced new stages and new whitelists for input sanity check, so that CMA- and Helm based configuration can be handled and whitelisted separately.

* `non_pra_whitelist` and `non_pra_upgrade_whitelist` checks previous CMA based PRA executions
* `non_pra_with_helm_whitelist` and `non_pra_upgrade_with_helm_whitelist` checks previous Helm based executions

Link: <https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/technicals/coverage_report/input_sanity_check_whitelist.yaml>

## Non-PRA execution check

Validate the pra versions of EEA µServices if both the upgrade and install was successful for the non-PRA version of the drop.
Time limit for these validations how long are they valid in days :

```
def nonPraAge = 10
```

List for the stages for validate

```
def stagesToCheck = ["Staging Nx1", "Staging Nx1 Upgrade"]
```

## Non-PRA execution check with helm configuration

For the [CMA transition](https://eteamspace.internal.ericsson.com/display/ECISE/EEAEPP-81492+Integrate+CMA+to+Product+CI) a new stage `Non-PRA execution check with helm configuration` got introduced.

List for the stages for validate:

[During transition period](https://eteamspace.internal.ericsson.com/display/ECISE/EEAEPP-81492+Integrate+CMA+to+Product+CI#EEAEPP81492IntegrateCMAtoProductCI-DuringtransitionperiodweneedtovalidatebothhelmandCMAbasedconfiguration,notjustproductchangesbuttestandcicodechangesalso.):

```
def stagesToCheck = ["Staging Nx1 with Helm configuration"]
```

For the transition period `Non-PRA execution check with helm configuration` stage is set to undecisive (`buildResult: 'FAILURE', stageResult: 'FAILURE'`), later when we have executions for all types of configurations, it can be set to decisive.

After [4.9 release](https://eteamspace.internal.ericsson.com/display/ECISE/EEAEPP-81492+Integrate+CMA+to+Product+CI#EEAEPP81492IntegrateCMAtoProductCI-Upgrademodificationsduringtransitionperiod(fromRC4.9toph3)eTeamProjectb51c6b84-e2bf-3ba1-9749-694aa4153517EEAEPP-91945):

```
def stagesToCheck = ["Staging Nx1 with Helm configuration", "Staging Nx1 Upgrade with Helm configuration"]
```

## Check for documentation deliverables

Validate that dev team has delivered documentation for a microservice drop.

Check details:

* Documentation path: <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-docs-drop-generic-local/microservice-name/microservice-drop-version/filename.dxp>
* There is no filename check
* BUT at least one dxp file has to be in the directory for the microservice drop version, but there can be multiple
* For release versions no separate documentation is delivered, the related drop version's documentation is used for the release drop. (e.g. for 3.2.0+11 the 3.2.0-11 version)

## Microservice helm design rule check

Checks the ADP Helm design rule compliance of the new chart.

## Helm Design Rule checker

[ADP documentation](https://eteamspace.internal.ericsson.com/display/ACD/Helm+Design+Rule+Checker)

Using latest adp-helm-dr-check Docker image validating helm chart of the triggering microservice drop to be in-line with ADP helm DRs.

Exemption can be found [here](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/bob-rulesets/input-sanity-check-rules.yaml#43).

## Image Design Rule Validation                                                                                                                                                                |

[ADP documentation](https://eteamspace.internal.ericsson.com/display/ACD/Image+Checker?src=contextnavpagetreemode)

The DR-D1123-122 is skipped until the tribes fix the images.

HTLM report is available in the job workspace at the moment, not saved as artifact yet.

## Image Repo Checking

This validation ensures that if the CHART-VERSION is "+," the repoPath with "-released" will pass the input-sanity test.
If the chart version is "-," then the repo path with both "-released" and "-drop" will pass the input sanity.
If either of the preceding conditions is not met, the input-sanity will fail.

## CRD check

This validation checks if the CRD implementation for an EEA µService follows the [CRD Helm Chart Delivery and Integration Guidelines](https://confluence.lmera.ericsson.se/display/AA/CRD+Helm+Chart+Delivery+and+Integration+Guidelines) or not. Failing if the guideline is not followed.

## CBOS Age Report

Input sanity validates that the Common Base OS of the drop is not too old.
The check fails if there are images with more than 6 weeks old CBOS version or if faces any runtime errors.
Information on [running CBOS Age Tool](https://confluence.lmera.ericsson.se/pages/viewpage.action?spaceKey=ACD&title=How+to+run+CBOS+Age+Tool) can be found on Confluence.
Exit codes of `cbos-age-tool` are documented on Confluence as well as they are dumped and clarified in the console log.
Exit codes other than 0 and 1 fail this check.

The CBO Age Report check produces the report in HTML and JSON formats named `cbos-age-report-<microservice name>-<version>-<date time>.{html,json}` that are archived as artifacts.

Additionally, age of CBOS is verified nightly using the baseline of integration helm chart by [eea-cbos-verify](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-cbos-verify/) Jenkins job.

## Test reports

Several test reports are validated for structure and mandatory keys existence, against json schema files located in the technicals/json_templates folder. List of reports validated currently:

* Sonarqube
* Service Level CI test reports for non security tests
* Security report checks

### Non-security report checks

Service level CI's has to deliver a test report listing their non security tests covered for the microservice drop at the microservice CI. This has to include upgrade test as well.

For newly introduced microservices exception can be added at the whitelist in [service_level_CI_test_report_whitelist](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/technicals/coverage_report/input_sanity_check_whitelist.yaml) till they deliver their first upgradeable version.

### Security report checks

This stage checks for existance and performs schema validation of the following reports:

* Xray
* Trivy
* Grype / Anchor
  * vulnerability
  * detail
  * grype
* OWASP ZAP
  * OWASP ZAP checking is configured by [`technicals/ci_config_default`](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/technicals/ci_config_default)
* NMAP&Unicornscan
  * EEA µServices can provides multiple nmap reports. It can be uploaded into the ARM in tgz format with the following naming convetions
    * In case of single report file: `<microservice name>_<version>_nmap_report.xml`
    * In case of multiple report files: `<microservice name>_<version>_nmap_report.tgz`
  * The validation process need to check if either the xml or tgz nmap report file exists
    * In case of tgz extract it and validate all the xml files inside that with the xsd schema
    * Naming of xml inside the tgz file shouldn't be in-line with the naming mentioned above

Checks are controlled by boolean variables in [`technicals/ci_config_default`](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/technicals/ci_config_default) that are read during the previous 'Read properties' stage.

First, images to check are read from `eric-product-info.yaml` of the chart.
Then, reports from the list above are checked for each image inside of the loop on all images of the chart.
For each report:

* It's existance in [artifactory](https://arm.seli.gic.ericsson.se/artifactory/proj-eea-reports-generic-local) is checked
* JSON is validated against respective JSON schema file in `technicals/json_templates/` with `jsonschema` tool.
* XML is validated against respective XSD schema file in `technicals/xml_template/` with `xmlschema-validate` tool.

All checks are expected to be executed despite any failures of individual reports of specific images, i.e. failure of trivy report check of image-1 doesn't abort following report checks on image-1 as well as checks on image-2 and further ones.

While stage always fails on errors, Jenkins build as a whole gets failed only for PRA releases.

## Send notification about change whitelist

Sends a notification email to the Security Team in case of changes to any list for Security checks in [`input_sanity_check_whitelist.yaml`](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/technicals/coverage_report/input_sanity_check_whitelist.yaml) for stage `Security report checks`.

Path: [`technicals/coverage_report/input_sanity_check_whitelist.yaml`](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/technicals/coverage_report/input_sanity_check_whitelist.yaml)

Lists that are used for `Security report checks` stage:

* owasp_zap_report_whitelist
* xray_report_whitelist
* trivy_report_whitelist
* grype_report_whitelist
* details_report_whitelist
* nmap_report_whitelist

## Interface coverage report check

Following microservices are skipped during this verification:

Insights Area:

* eric-oss-stream-exporter
* eric-eea-stream-aggregator
* eric-eea-scoring-proxy
* eric-eea-analysis-system-overview-install
* eric-eea-incident-ratio-calculator

Presentation Area:

* eric-eea-db-manager
* eric-eea-analytical-processing-database
* eric-eea-db-loader
* eric-eea-analytics-open-api
* eric-eea-post-processor

Data Collection:

* eric-oss-correlator
* eric-oss-4g-pm-event-parser
* eric-oss-4g-pm-event-termination
* eric-oss-5g-pm-event-termination
* eric-oss-mobility-mgmt-ebm-parser
* eric-oss-mobility-mgmt-ebm-termination
* eric-oss-session-mgmt-ebm-parser
* eric-oss-session-mgmt-ebm-termination
* eric-oss-user-plane-ebm-parser
* eric-oss-user-plane-ebm-termination
* eric-eea-ctum-parser

Platform area:

* eric-eea-privacy-service-converter
* eric-eea-refdata-fetch

## Release documentation check

* SOC
* SOV
* 3pp list

Release documentations are validated for structure and mandatory keys existence, against json schema files located in the technicals/json_templates folder.

## Schema files

* the required json schema for SoC and SoV are stored in adp-app-staging/technicals/json_templates/soc_schema.json and sov_schema.json
* the required json schema for changelog is stored in adp-app-staging/technicals/json_templates/changelog_schema.json

## Sonarqube sanity check

SonarQube test stored in <https://arm.seli.gic.ericsson.se/artifactory/webapp/#/artifacts/browse/tree/General/proj-eea-reports-generic-local>
`<microservice name>_<version>_sonarqube_report.json`

SonarQube result has to be checked, if test coverage is below a configurable limit (e.g. 70%) the check should fail the whole input sanity phase.
If limit 0%, test coverage shouldn't be checked.

## Configuration

* SANITY_CHECK_SONAR : validation required or not, default value 'true'
* SANITY_CHECK_SONAR_COVERAGE: percent value of the required minimum percent of sonarqube coverage metric value, default value  '70'

## Schema file

* the required json schema for sonarqube report is stored in adp-app-staging/technicals/json_templates/sonarqube_schema.json

## Steps

* download the report file
* validating the json format in command line
* run technicals/pythonscripts/sonar_json_sanity_check.py for content validation
  * with jsonschema tool validating the shcema
  * validating the coverage percent value reach

## Validate microservice in mimer

This stage checks the following use cases:

## Product number does NOT exist in Mimer

The stage fails and prints the following error message:

`ERROR: [Read product version for product 'APR201061' failed. Probable cause: product does not exist]`

## Product version does NOT exist in Mimer

The stage fails and prints the following error message:

`ERROR: [Read product 'APR201058', version '3.27.0' failed. Probable cause: Entity Or product version does not exist]`

## Product version is NOT released in Mimer.

In case of + versions the stage fails and prints the following error message:

`ERROR: APR201058 2.27.0 is not released in Mimer`

In case of - versions the stage succeeds and prints the following message:

`[WARN]: APR201058 2.27.0 is not released in Mimer`

## Product version is released in Mimer

The stage succeeds and prints the following message:

`[INFO] APR201058 2.26.0 is released in Mimer`

## Sending Mimer status to Application Dashboard

The following data is collected and sent to the Application Dashboard as JSON to [this](http://eea4-application-dashboard.seli.gic.ericsson.se:61616/api/v1/stages/executions/mimer) endpoint:

* serviceName, e.g. "eric-oss-correlator"
* serviceVersion, e.g. "1.3.121-23"
* serviceMimerStatus, e.g. "product is not in Mimer"

## 3pp list check

This is a stage that Spinnaker runs in parallel with Sanity Check to check invalid CAX numbers, names or versions differences between ms 3pp list and SCAS.

Jenkins job: [eea-3pp-list-check](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-3pp-list-check/)

Jenkins job documentation: [eea-3pp-list-check documentation](https://eteamspace.internal.ericsson.com/display/ECISE/EEA+3pp+List+Check)
