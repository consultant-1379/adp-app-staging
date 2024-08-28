# Automated test job cleanup at live Jenkins

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Description

This cleanup job is designed to automate the cleanup of test jobs that have not been triggered in over six months. The purpose of the cleanup is to avoid that test jobs are using huge disk space at live Jenkins.

## Jenkins job

Job name: [cleanup-jenkins-test-jobs](https://seliius27190.seli.gic.ericsson.se:8443/job/cleanup-jenkins-test-jobs)
Triggered by: cron `0 10 * * 0` (every Sunday at 10 AM).

## Parameters

* `LIST_ONLY`: If true, the jobs and their artifacts will be listed without being deleted.

## Steps

1. Params DryRun check

    * Checks if the `DRY_RUN` parameter is set. If it is, the pipeline will run in dry run mode.

2. Read Whitelist

    * Reads a whitelist located in [`technicals/cleanup_jenkins_test_jobs_whitelist.yaml`](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/technicals/cleanup_jenkins_test_jobs_whitelist.yaml).
    * Jobs listed in this whitelist will not be considered for deletion, ensuring that important test jobs that are used rarely will be protected from being accidentally removed.

3. Delete Jobs

    * Collects all jobs in the Jenkins instance.
    * Filters jobs based on the absence in the whitelist and criteria for test jobs.
    * Checks each test job's last build time or last modification time against a six-month threshold.
    * Deletes test jobs that match that not used condition, including their artifacts.

## Filter for test job

The test job criteria are based on job names starting with one of the following pattern:

* `test-` or `test_`. Example: `test-cleanup-job` or `test_cleanup-job`.
* `e[a-z]-` or `e[a-z]_`. Example: `edzhisk-cleanup-job` or `edzhisk_cleanup-job`.
* `x[a-z]-` or `x[a-z]_`. Example: `xdzhisk-cleanup-job` or `xdzhisk_cleanup-job`.
* `z[a-z]-` or `z[a-z]_`. Example: `zdzhisk-cleanup-job` or `zdzhisk_cleanup-job`.
* `eth[a-z]-` or `eth[a-z]_`. Example: `ethdzhisk-cleanup-job` or `ethdzhisk_cleanup-job`.

## Note

If the test job has not been triggered at all, the cleanup job will check the date of the last modification. The test job will be deleted if its last modification was more than six months ago.
