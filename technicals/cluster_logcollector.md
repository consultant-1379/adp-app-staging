# Cluster log collector

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Description

The logcollector has been separated from the pipelines (e.g. eea-application-staging-batch or upgrade jobs) to reduce the execution time.
In this case the next eea-application-staging spinnaker pipeline can be started if there are enough free clusters without wasting time on log collection and cleanup.
The log collector job(s) can be triggered as a post action from pipeline jobs or via cron job or manually.

## The processes, step-by-step

+ The parent/caller jobs (e.g. eea-application-staging-batch or upgrade jobs) will do the following:
  + add arm log repo link to the Jenkins job page which contains the folder of the cluster logs in the arm artifactory with the job name and the build number (e.g. eea-application-staging-batch-2239 or eea-application-staging-product-upgrade-589)
  + change the label of the lockable resource to 'cluster-logcollector-job'
  + set note for the lockable resource with the arm log repo folder
  + execute the cluster-logcollector job with nowait option (wait: false)

+ The logcollector jobs will do the following:
  + lock the resource using given CLUSTER_NAME or CLUSTER_LABEL
  + get the arm log folder from the note of the lockable resource, if the note field is empty then the log collector job should use its job name and build number to store the logs in arm
  + upload the information about cluster to dashboard
    + check if the cluster is Product CI
    + upload name and the cluster health info as details to [dashboard](http://10.223.227.167:61616/swagger-ui/index.html#/cluster-controller/getClusterResources)
  + Add page info
    + add the parent Jenkins job link to the collector Jenkins job page. e.g:
      + Parent job: [eea-application-staging-batch/2239/](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-batch/)
    + add arm log repo link to the Jenkins job page. e.g:
      + Cluster logs: [eea-application-staging-batch-2239/](https://arm.seli.gic.ericsson.se//artifactory/proj-eea-reports-generic-local/clusterlogs/)
      + Cluster logs: [cluster-logcollector-79/](https://arm.seli.gic.ericsson.se//artifactory/proj-eea-reports-generic-local/clusterlogs/)
  + collects the logs from cluster:
    + summary_eric-eea-ns_$datetime.txt - summary on all  k8s objects in the cluster
    + logs_$namespace_$datetime.tgz - describes, logs and helm info on k8s objects in the cluster (namespaces: eric-eea-ns, eric-crd-ns, utf-service)
    + eea_logs_eric-eea-ns_$datetime.tgz - extra logs for eric-eea-ns
    + (crd_,utf_)log_collector.log - logs of each log collection itself
  + Collect coredumps:
    + coredumps.tar.xz
    + systemd_coredump.tar.xz
    + collect_coredumps script log
  + store logs to Jenkins jobs
  + upload logs to arm
  + change the label of the lockable resource to 'cleanup-job'
  + clear the note from the lockable resource
  + execute cluster-cleanup job with wait option (wait: true)
  + send notification if failure occurs containing the parent job link and the arm log repo link

## Jenkins job

Job name: [cluster-logcollector](https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-logcollector)

## Steps

+ Params DryRun check
+ Params check
+ Clean workspace
+ Checkout cnint
+ Bob Prepare
+ Bob Init
+ Resource locking - logcollector
  + Log lock
  + Get lockable resource note
  + Upload cluster to dashboard
  + Add page info
  + Init performance data collection
  + Collect performance data from cluster
  + Collect logs from cluster
  + Publish logs to job
  + Publish logs to arm
  + Lock Post actions: always
    + Set label for the lockable resource
    + Clear note for the lockable resource
    + Execute cluster-cleanup job
+ Post actions: failure
  + Send failure notification

## Parameters

+ 'CLUSTER_NAME' parameter is used to specify the Logcollector resource name to execute on. Don't specify if CLUSTER_LABEL specified
+ 'CLUSTER_LABEL' parameter is used to specify the Logcollector resource label to execute on. Don't use 'bob-ci' label to avoid running logcollect on clusters from CI pool. Don't specify if CLUSTER_NAME specified
+ 'DESIRED_CLUSTER_LABEL parameter is used to specify the desired new resource label to be set after execution is finished with any results (success/failure/abort as well). By default the value is: 'cleanup-job'
+ 'PUBLISH_LOGS_TO_JOB' parameter can be used to enable/disbale execution of publishLogsToJob stage. By default the value is true.
+ 'PUBLISH_LOGS_TO_ARM' parameter can be used to enable/disbale execution of publishLogsToArm stage. By default the value is true.

## Jobs calling cluster-logcollector

+ [eea-adp-staging-adp-nx1-loop](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-adp-staging-adp-nx1-loop/)
+ [eea-application-staging-batch](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-batch/)
+ [eea-application-staging-nx1](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-nx1/)
+ [eea-application-staging-product-upgrade](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-product-upgrade/)
+ [eea-product-ci-meta-baseline-loop-test](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-ci-meta-baseline-loop-test/)
+ [eea-product-ci-meta-baseline-loop-upgrade](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-ci-meta-baseline-loop-upgrade/)
+ [eea-product-release-loop-bfu-gate-upgrade](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-release-loop-bfu-gate-upgrade/)
+ [cluster-validate](https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-validate/)

## Special use cases

+ In case of manual changes in cnint
  + eea-application-staging-batch and eea-application-staging-product-upgrade Jenkins job will start cluster-logcollector job with 'wait' option having TRUE value
  + in this case, any manual changes can only be integrated after a successful logcollection and cluster cleaning process has been completed
+ In case of microservice changes
  + eea-application-staging-batch and eea-application-staging-product-upgrade Jenkins job will start cluster-logcollector job with 'wait' option having FALSE value
  + in this case, any changes will be integrated regardless of the results of the log collection and cluster cleanup processes
+ The currently used 'wait' option's value for the logcollector can be calculated in the [eea-application-staging-baseline-prepare](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-baseline-prepare/) Jenkins job and stored at the artifact.properies file. This file is processed by the Spinnaker and the value is passed to the eea-application-staging-batch and eea-application-staging-product-upgrade jobs.

## Troubleshooting with accessing to the arm log repo

+ The log folder link to arm repo may not be available immediately right after running the CI pipeline (even for success or fail results), as logcollect can take up to 6-10 minutes. So when you click on the arm log link and get a "404" error, you need to try a little bit later again.
+ If you have privilege problmes accessing arm repo, check [this link](https://eteamspace.internal.ericsson.com/display/ECISE/Newcomers+guide#Newcomersguide-Artifactory)

## Code examples

This code snippets demonstrates how to call cluster-logcollector job from any pipeline.

+ Store the locked cluster name to use it in POST stages:

```groovy
    stage('Lock') {
        options {
            lock resource: null, label: 'bob-ci', quantity: 1, variable: 'system'
        }
        stages {
            stage('log lock') {
                steps {
                    echo "Locked cluster: $system"
                    script {
                        currentBuild.description += "<br> $system"

                        // To use cluster name in POST stages
                        env.CLUSTER = env.system
                    }
                }
            }
        }
    }
    ...
```

+ Preparing and executing logcollector from POST always action:

```groovy

    post {
        always {
            script {
                try {
                    prepareClusterForLogCollection("${env.CLUSTER}", "${env.JOB_NAME}", "${env.BUILD_NUMBER}")
                }
                catch (err) {
                    echo "Caught prepareClusterForLogCollection ERROR: ${err}"
                }

                try {
                    echo "Execute cluster-logcollector job ... \n - cluster: ${env.CLUSTER}"
                    build job: "cluster-logcollector", parameters: [
                        stringParam(name: "CLUSTER_NAME", value: env.CLUSTER)
                        ], wait: false
                }
                catch (err) {
                    echo "Caught cluster-logcollector-job ERROR: ${err}"
                }

            }
        }
    }
```

## Performance data collection triggering

### Init performance data collection

In case of the triggering job was any of

+ [eea-adp-staging-adp-nx1-loop](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-adp-staging-adp-nx1-loop/)
+ [eea-application-staging-batch](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-batch/)
+ [eea-application-staging-nx1](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-nx1/)
+ [eea-application-staging-product-upgrade](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-product-upgrade/)

we get the performance_data.properties file from the triggering job and the ip and port of the cluster.

### Collect performance data from cluster

If parameters needed for the data collection succesfully initiated, the we trigger the [collect-performance-data-from-cluster job](https://seliius27190.seli.gic.ericsson.se:8443/job/collect-performance-data-from-cluster)i with wait option
