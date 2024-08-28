# EEA4 Automated RC and Weekly Drop tagging and mail sending

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Description

The goal of the job is to automatically send release (RCs and Weekly Drops, further WDs) mail for EEA organization and put git tag for RC / WD at cnint repo.
Release data is also sent to the [Application Dashboard](http://eea4-application-dashboard.seli.gic.ericsson.se:61616/dashboard?stage=15&last=1).

RC / WD mail will be sent to the following recipients:

* [EEA Release Team <PDLEEARELE@pdl.internal.ericsson.com>](mailto:PDLEEARELE@pdl.internal.ericsson.com)

## Content

* RC / WD Integration helm chart version (e.g. 4.1.0-146)
* Link for the RC / WD version of the integration helm chart in cnint repo. e.g. [link](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/5343b013280fdba53111bc86bdd803abfa4b456f/eric-eea-int-helm-chart/Chart.yaml)
* List of microservices with versions in the RC / WD integration helm chart version
* List of disabled services
* List of services that are not part of the CSAR package
* Link for CSAR package for the RC / WD at ARM e.g. [link](https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-generic-local/csar-package-4.1.0-146.csar)
* Spotfire links: Platform (Linux), Dashboard Data Source, Static Content

## Git tagging

* The job tags the commit in cnint repo for the given integration helm chart version, where git tag name will be the RC / WD name (e.g. eea4_4.1_rc1, eea4_4.5_wd1).

## Jenkins job

Job name: [release-mail-automation](https://seliius27190.seli.gic.ericsson.se:8443/job/release-mail-automation)

## Parameters

* `RELEASE_NAME` – name of the RC or Weekly Drop as string (e.g. eea4_4.2_rc1, eea4_23_w47_wd1)
* `EXTENDED_RELEASE_NAME` - An extended version of the release name (e.g. EEA4 4.8.0 Release Candidate 2)
* `INT_CHART_VERSION` – integration helm chart version which would get the RC / WD label (e.g. 4.2.2-176)
* `LINUX_SPOTFIRE_PLATFORM` – link for Spotfire Linux platform
* `SPOTFIRE_DASHBOARD_DATA_SOURCE` – link for Spotfire dashboard data sources
* `SPOTFIRE_STATIC_CONTENT` – link for Spotfire static content
* `SPOTFIRE_UTILS` – link for Spotfire Utils
* `DEPLOYER_PACKAGE_URL` – link for DEPLOYER package
* `DIMTOOL_PACKAGE_URL` – link for Dimensioning Tool package

### Steps

* Checkout master branch of adp-app-staging repo
* Checkout cnint release tag
* Get git commit ID for RC / WD
* Prepare bob
* Parse RC / WD microservice list
* Parse csar_exception_list
* Create release mail content
* Create RC / WD git tag
* Send release data to App Dashboard
* Send release mail
