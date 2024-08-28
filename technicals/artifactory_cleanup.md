# EEA4 Product CI Automated cleanup of ARM repositories used by EEA4 CI flow

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Description

The goal of the job is to automatically cleanup ARM repositories used by EEA4 CI flow.
The logic was implemented in the EEA/ci_shared_libraries's Artifactory object.
Collecting the repo files suited to retention policy we are using the [Artifactory RESTAPI](https://www.jfrog.com/confluence/display/JFROG/Artifactory+REST+API#ArtifactoryRESTAPI-aql) and [Artifactory Query Language](https://www.jfrog.com/confluence/display/JFROG/Artifactory+Query+Language) libraries.

+ The default retention policy is 1 month. It means that files older than this will be deleted!
+ Helm drop, Docker drop, Docs drop and Reports repo files can be only deleted if related + versions of artifacts in [released helm repo](https://arm.seli.gic.ericsson.se/artifactory/proj-eea-released-helm-local/) are not reachable.
+ Helm drop, Docker drop, Docs drop repo files can be only deleted if they were not downloaded in the last 30 days.
+ For the files in CSAR drop, HELM drop, DOCKER drop, DOCS drop, Application Dashboard Backups repo at least the latest 5 files/versions will be kept.
+ There is a special option/logic for HELM drop, DOCKER drop repo files to skip cleaning certain artifacts. To achieve this, you need the following special manually set key-value pair in ARM. Setting the artifact file properties may require additional rights, so if there are files/directories in ARM that should NOT be deleted during cleanup, please send your request to the ENV team.
  + ARM property which need to be set for an artifact if you need to preserve it from cleanup:
    + Property: 'skip-cleanup', Value: 'true'

### Reports cleanup scenarios:

+ dimensioning tool plugins: path: 'dimtool/'
+ microservice reports: path started with: 'eric-*'
+ integration chart reports: path: 'eea4/' with filenames: 'test_run_result*'
+ cluster logs (collected by [data_collector.sh](https://arm.sero.gic.ericsson.se/artifactory/proj-adp-data-collector-released-generic-local/adp-data-collector/) declared in [eric-eea-utils docker-image](https://gerrit.ericsson.se/plugins/gitiles/EEA/eea4-utils/+/master/docker/eric-eea-utils-ci/) )
+ security reports cannot deleted!!!

## Jenkins job for nightly cleanup

Job name: [artifactory-cleanup](https://seliius27190.seli.gic.ericsson.se:8443/job/artifactory-cleanup)
Triggered by: cron at 9PM every day

### Steps:

+ Cleanup Artifactory CSAR internal <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-internal-generic-local>
+ Cleanup Artifactory CSAR drop <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-generic-local>
+ Cleanup Artifactory HELM dev <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-dev-helm-local>
+ Cleanup Artifactory HELM internal <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-ci-internal-helm-local>
+ Cleanup Artifactory HELM drop <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm-local>
+ Cleanup Artifactory DOCKER dev <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-dev-docker-global/proj-eea-dev/>
+ Cleanup Artifactory DOCKER internal <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-ci-internal-docker-global/proj-eea-ci-internal/>
+ Cleanup Artifactory DOCKER drop <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-docker-global/proj-eea-drop/>
+ Cleanup Artifactory DOCS drop <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-docs-drop-generic-local/>
+ Cleanup Artifactory REPORTS <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-reports-generic-local/>
+ Cleanup Artifactory Application Dashboard Backups <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-internal-generic-local/application-dashboard-backups/>

## Parameters

### Retention policy can be defined in different parameters:

+ 'HELM_CLEANUP_ENABLED' parameter can be used to enable/disbale execution on helm repos. By default the value is true
+ 'CSAR_CLEANUP_ENABLED' parameter can be used to enable/disbale execution on csar repos. By default the value is true
+ 'DOCKER_CLEANUP_ENABLED' parameter can be used to enable/disbale execution on docker repos. By default the value is true
+ 'DOCS_CLEANUP_ENABLED' parameter can be used to enable/disbale execution on docs repos. By default the value is true
+ 'REPORTS_DIMTOOL_CLEANUP_ENABLED' parameter can be used to enable/disbale execution on reports for dimensioning tool plugins. By default the value is true
+ 'REPORTS_MICROSERVICE_CLEANUP_ENABLED' parameter can be used to enable/disbale execution on reports for microservices. By default the value is true
+ 'REPORTS_INT_CHART_CLEANUP_ENABLED' parameter can be used to enable/disbale execution on reports for integration charts. By default the value is true
+ 'REPORTS_CLUSTER_LOG_CLEANUP_ENABLED' parameter can be used to enable/disbale execution on reports for cluster log cleanup. By default the value is true
+ 'APPLICATION_DASHBOARD_CLEANUP_ENABLED' parameter can be used to enable/disbale execution on reports for application dashboard backups cleanup. By default the value is true
+ 'HELM_FILTER_LIMIT' parameter can be used to limit number of resulted rows for AQL. By default the limmit is 5000.
+ 'CSAR_FILTER_LIMIT' parameter can be used to limit number of resulted rows for AQL. By default the limmit is 5000.
+ 'DOCKER_FILTER_LIMIT' parameter can be used to limit number of resulted rows for AQL. By default the limmit is 5000.
+ 'DOCS_FILTER_LIMIT' parameter can be used to limit number of resulted rows for AQL. By default the limmit is 5000.
+ 'REPORTS_FILTER_LIMIT' parameter can be used to limit number of resulted rows for AQL. By default the limmit is 5000.
+ 'APPLICATION_DASHBOARD_FILTER_LIMIT' parameter can be used to limit number of resulted rows for AQL. By default the limmit is 5000
+ 'LIST_ONLY' parameter can be used to disable the deleting, so in this mode artifacts cannot be deleted, only printed out. By default the value is false.
+ 'EMAIL_ALERT_ENABLED' parameter can be used to send email to "Jenkins alerts" teams channel if execution is failing. By default the value is true.
