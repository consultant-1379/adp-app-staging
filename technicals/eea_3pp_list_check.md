# EEA 3pp List Check

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Description

The goal of the job is to automatically check invalid CAX numbers, names or versions differences between ms 3pp list and SCAS.
The job itself is essentially a comparison of two json files and looking for differences in names or versions

Job name: [3pp-list-check](https://seliius27190.seli.gic.ericsson.se:8443/job/3pp-list-check)

## Jenkins job description

### Parameters

* CHART_NAME
* CHART_REPO
* CHART_VERSION
* SPINNAKER_TRIGGER_URL
* PIPELINE_NAME
* SPINNAKER_ID

### Steps

* Checkout adp-app-staging
  * adp-app-staging:technicals/ci_config_default is used by this job
* Prepare
  * load bob
* Replace + to - in Chart version
  * We need it because 3ppList is stored with the - in the arm
* Init
  * Update Jenkins build description
* Clean
* Read properties
  * Import adp-app-staging:technicals/ci_config_default to the build environment
* 3pp list check
  * Check if the 3pp list is available for the ms and download it
* Download data from SCAS
  * Download data about 3pps listed in the ms 3pp list from the SCAS
* Check 3PPs
  * Compare 3pp names from the ms 3pp list with the SCAS values
    * If names mismatch found - the compare without special characters will be started. The build will be marked as UNSTABLE
  * Compare 3pp versions from the ms 3pp list with the SCAS values
    * If versions mismatch found - the compare without special characters will be started. The build will be marked as UNSTABLE
  * Compare CAX versions from the ms 3pp list with the SCAS values
    * If CAX version not found in the SCAS - the build will be completed with FAILURE
  * If no mismatch was found during the comparison, the build will be completed with SUCCESS
