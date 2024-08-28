# Cluster cleanup

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Purpose

The job was created to cleanup the cluster

## Jenkins job

Job name: [cluster-cleanup](https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-cleanup)

## Parameters

+ `CLUSTER_NAME` - cluster name to cleanup. A cleanup will be performed for the specified cluster name
+ `PARENT_JOB_BUILD_RESULT` - check if parent job has successful result
+ `DESIRED_CLUSTER_LABEL` - The desired new resource label after successful run when the job success
+ `GERRIT_REFSPEC` - Gerrit Refspec of the integration chart git repo e.g.: refs/changes/87/4641487/1. Default values is empty
+ `LOCAL_REGISTRY_CLEANUP` - A boolean parameter to make it possible to turn off the "K8S cleanup local registry" stage for RV team. Has a default value is true. This parameter has been introduced as a quick temporary solution
+ `SPOTFIRE_CLEANUP` - A boolean parameter to give option to turn off spotfire cleanup. Defauilt value is true.

## Steps

1. Params check

    + `CLUSTER_NAME` must be specified

1. Lock cluster

    + If `CLUSTER_NAME` specified, then the cluster will be clocked by the name

1. Check Ceph health status

    Runs health check with specified label/name before starting the cleanup and removes the resource from the pool on critical rook ceph failures.
    Critical failure condition means that the rook ceph status has either the HEALTH_ERR - or - any of major HEALTH_WARN patterns defined [here](https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master/vars/validateRookCephStatus.groovy)
    The goal is to not run Product CI pipeline validations on faulty clusters if possible, and that the faulty cluster resources can be returned to the pool as soon as possible, preferably automatically.
    To achieve this [cluster-reinstall-automation](https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-reinstall-automation/) Jenkins job is executed every day, after the working hours for cluster labels `faulty` and `ceph-error` - in general for those clusters that are already out of the pool.
    Except for clusters label `ceph-error-admin-require` which is used for rook ceph problems that are related to disk/other issues and requiring admin intervention/verification.
    Because these kinds of problems usually cannot be solved by a simple reinstallation. In this case the driver sould check the root cause.
    TODO: link to the ceph-dashboard should be included in eea4-cluster-info-collector, like in the [rv-cluster-info-collector](https://seliius27190.seli.gic.ericsson.se:8443/job/rv-cluster-info-collector/Cluster_5finfo_5ftable/)

1. k8s cleanup
    Calls a new k8s_cleanup.sh script from adp-app-staging repository to clean up eric-eea-ns namespace
    Runs an utf namespaces cleanup

1. crd cleanup

    Runs a crd cleanup

1. Delete product-baseline-install configmap

1. Delete meta-baseline-install configmap

1. K8S cleanup local registry

1. K8S cleanup containerd registry

    Removes unused docker images from every cluster node (master+workers)

1. Restart SEP mount cleanup

1. Check and force cleanup

    Runs after the cluster cleanup. Checking if there are pods in the utf-service, eric-eea-ns or eric-crd-ns. If there are then run the post-cleanup bob rule to force cleanup them.
    If this rule is failing the cluster-cleanup Jenkins job's buildResult will be FAILURE and the cluster cannot moved back to the pool!
    Text files (stuck-pods-${env.NAMESPACE}.txt) containing the list of stuck pods are always archived for the jobs.

1. Spotfire cleanup

    Runs spotfire-asset-install with cleanup.

1. Check if namespace exists

    Executes `checkIfNameSpaceExists` ci_shared_libraries' function which calls `check-namespaces-not-exist` bob rule to check if any of utf-service, eric-eea-ns, spotfire-platform, eric-crd-ns namespace is still exists on the cluster after cleanup. The same checks are executing before all install processes.
    If any of the above namespace still exists on the cluster, the cluster-cleanup Jenkins job's buildResult will be FAILURE and the cluster cannot be moved back to the pool!
    In this case a notification email will be sent to the Teams `Driver channel` and the current driver should check what happened there.

## Post steps

1. Success

    If successful completion of the cleanup, the cluster will be assigned `bob-ci` label

1. Failure

    If Ceph health check fails, the cluster will be assigned `ceph-error` or `ceph-error-admin-required` label and a notification send to the team channel.
    For any other reason, if the cleanup fails, the cluster will be assigned `faulty` label and thus we remove it from the pool.

## Jobs calling cluster-cleanup

+ [cluster-logcollector](https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-logcollector/)

## Manual cleanup job

When a cluster needs to be cleaned up independently from any loops, do the following:

+ if the cluster has the label: 'bob-ci', change the cluster label to e.g.: 'bob-cleanup'.
  + always use the [lockable-resource-label-change](https://seliius27190.seli.gic.ericsson.se:8443/job/lockable-resource-label-change/) jenkins pipeline to change cluster labels.
  + ensure that only one cluster has this label (if multiple clusters have this label, only the first free will be cleaned up)
+ run the cluster-cleanup job and monitor the console log.

## Cleanup function in k8s-test

To be able to validate the uninstall process during Product CI loop run, we added the uninstall phase from the beginning of the pipelines to the end as a last step as well.

At the beginning of the helm install process, the cleanup is done by the test.py script from the armdocker.rnd.ericsson.se/proj-adp-cicd-drop/bob-py3kubehelmbuilder image.

test.py has no options to run the cleanup only, so the wrapper script [k8s_cleanup.py](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/technicals/pythonscripts/k8s_cleanup.pyscript) was added to call the cleanup function from test.py.

In the cnint [bob ruleset](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/ruleset2.0.yaml), the k8s-cleanup rule runs copies k8s-cleanup.py next to test.py and runs the cleanup on the eric-eea-ns
and utf-service namespaces of the cluster.

## Manual cleanup for crd-s

After the  crd charts uninstalled the crd-s has to be deleted. But deleting all of the crd-s ruins the cluster, so in a loop they are checked one by one, and if deleted it was installed by the helm.

## Retrigger cluster-cleanup when cancelled by Spinnaker

cluster-cleanup-retrigger-when-cancelled job checks the user who cancels or aborts cluster-cleanup job and if the user is Spinnaker system user "eceaspin" or status of Interrupted Build Action is "Calling Pipeline was canceled" then it automatically restarts cluster-cleanup with the same parameters. If a user from Jenkins aborts the job it will not be triggered that is works only when cluster-cleanup was forced aborted from Spinnaker or by user "eceaspin".

+ [cluster-cleanup-retrigger-when-cancelled](https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-cleanup-retrigger-when-cancelled/)
