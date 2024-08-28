# General structure of Product CI loops

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Prepare baseline

    Creation of integration chart for the testing using the IHC baseline from ARM (cnint repo) and the triggering change from ARM/Gerrit.

## Locking test cluster resource

    By reserving Jenkins lockable resource dedicated for a test environment ensure that no other process will be able to reach this test environment till this loop has not finished.

## CRD install

    Deployment of CRDs from the integration helm chart for EEA4.

## Test tool deployment from metabaseline helm chart

    Deployment of the following tools used during testing in Product CI loops:

* UTF
* Data loader

## EEA4 product deployment

    Deployment of EEA4 from the integration helm chart.

## Loading reference data

    Loading reference data stored at Product CI NFS using procedure in cnint repo's ruleset file.

## Start PCAP data loading

    Loading PCAP data with data loader service to the deployed EEA4 instance from Product CI NFS using UTF TC.

## E2E test execution with UTF

    Execution of E2E tests delivered in UTF Docker image for the deployed EEA4 instance.

## Stop PCAP data loading

    Stopping PCAP data loading after E2E tests have finished with UTF TC.

## Log collection from the test cluster

    Collecting logs from the test environment using ADP log collector from a separated job. /wait for result: false/
    Job name: [cluster-logcollector](https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-logcollector)
    Job doc [link](https://eteamspace.internal.ericsson.com/display/ECISE/Cluster+Log+Collector)

## Cleanup of the test cluster

    Cleanup of the eea4 product namespace, utf namespace and the used CRDs from the test environment from a separated job. /wait for result: true/
    Job name: [cluster-cleanup](https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-cleanup)
    Job doc [link](https://eteamspace.internal.ericsson.com/display/ECISE/Cluster+cleanup)

## Release cluster locking

    Release reservation of the lockable resource in Jenkins for the test environment.
