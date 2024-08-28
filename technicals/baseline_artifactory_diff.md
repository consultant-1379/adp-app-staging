# Regular checking of the EEA4 baseline helm chart and the latest PRA version in ARM

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Description

Product CI should be notified via Teams/email/Jira ticket if an ADP GS PRA drop fails in EEA Application Staging loop after it has passed the ADP Staging pipelines
 (so towards ADP we gave feedback that the drop is OK, but it's not part of EEA4 baseline)

## Jenkins job for nightly diff

Job name: baseline-artifactory-diff
Triggered by : cron @mindnight

Steps:

* get all the versions from artifactory <https://arm.sero.gic.ericsson.se/artifactory/proj-adp-gs-all-helm> wit helm search command (with 'get-gs-versions' bob rule in cnint ruleset)
* get all baseline versions from Chart.yaml
* compare the versions
* in case of difference, send email sent to Spinnaker - ADP notification - EEA4 CI <0b4b5be9.ericsson.onmicrosoft.com@emea.teams.ms> with the result
