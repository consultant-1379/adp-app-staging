# Product CI cluster reinstall automation

## Desctiption

Product CI clusters can be automatically reinstalled with [cluster-reinstall-automation](https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-reinstall-automation/) Jenkins job for the various scenario types mentioned below.

The goal is to run automated reinstall job at least once per day, after the working hours for cluster labels `faulty` and `ceph-error` - in general for those clusters that are already out of the pool.
Except for clusters label `ceph-error-admin-require` which is used for rook ceph problems that are related to disk/other issues and requiring admin intervention/verification.
Automated reinstallation of clusters that are still in the pool only allowed in a specified time frame (from Friday 6PM to Monday midnight).
If necessary those clusters can be removed manually from the pool anytime.

## Triggering

* Job runs every day at 10PM by cron `(triggers { cron('00 22 * * *') })`
* It can be started manually anytime. BUT only 1 running instance is alowed at the same time.

## Parameters

* DUMMY_RUN - If true, execute all the build jobs with DRY_RUN=true and do not send email notification, defaultValue: false
* CHECK_PERMITTED_TIME_FRAME - If true, reinstall for the clusters in the pool only allowed in a specific time frame (from Friday 6PM to Monday 0AM), defaultValue: true
* MAXIMUM_NUMBER_OF_RETRIES - The maximum number of cluster reinstall retries, defaultValue: '3'
* REINSTALL_TIMEOUT - Timeout value for every single reinstallation, default 10 hours = 600 minutes
* REINSTALL_TIMEOUT_UNIT - Timeout unit, HOURS/MINUTES/SECONDS/etc., defaultValue: 'MINUTES'
* REINSTALL_TIMEOUT_LOCKED - Timeout value for reinstallation for locked clusters, default 15 hours = 900 minutes
* REINSTALL_TIMEOUT_LOCKED_UNIT - Timeout unit, HOURS/MINUTES/SECONDS/etc., defaultValue: 'MINUTES'
* SLEEP_CYCLE_WAITING_FOR_FREE_RESOURCE_STATUS_TIME - Sleep time value between checking of cluster status, default 5 minutes
* SLEEP_CYCLE_WAITING_FOR_FREE_RESOURCE_STATUS_UNIT - Sleep time unit, HOURS/MINUTES/SECONDS/etc., defaultValue: 'MINUTES'

## Steps

### Check if run in Jenkins prod

This stage is responsible to check if the job is executed on the prod Jenkins or not.
Because it can start with cron and we need to avoid running from Jenkins test.

### Check Concurrent Builds

This job can run for a very long time, even more than 24 hours.
However, we need it to run every day, but it's unfortunate if it's just waiting in the queue.
So it's better to execute it when needed, but if another instance is already running, this stage will stop the latest run with proper logging.
By the way, this solution also solves stuck dry-runs-job executions.

### Collect clusters to reinstall

* Get list of all clusters with owner `product_ci`.
* Get the cluster resource labels and filter for next values: `ceph-error`, `faulty`, `bob-ci`, `bob-ci-upgrade-ready`, because only clusters with these labels can be reinstalled automatically.
* Get the cluster rook ceph status and [validate](https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master/vars/validateRookCephStatus.groovy) it.
  * If critical rook ceph health problem(s) detected on the cluster it assigns a priority number based on thresholds extracted from the rook ceph messages.
  * If the cluster has `ceph-error` label, then it is given a priority of 2000 + its CEPH threshold.
  * If the cluster has `faulty` label, then it is given a priority of 1000 + its CEPH threshold.
  * The priority of the others is formed depending on their CEPH threshold.
* TODO: create logic to get priority based on the cluster's age (to reinstall cluster if its age is too old)
* The order in which the reinstallation is performed is based on this priority number. The logic always proceeds from the highest priority to the lowest.
* Create a map object with the following content.

```
[
  'kubeconfig-seliics02681':[name:'kubeconfig-seliics02681', label:'ceph-error',           priority:2001, tryCount:0, lastBuildResult:'Not build yet'],
  'kubeconfig-seliics04535':[name:'kubeconfig-seliics04535', label:'faulty',               priority:1001, tryCount:0, lastBuildResult:'Not build yet'],
  'kubeconfig-seliics03116':[name:'kubeconfig-seliics03116', label:'bob-ci',               priority:10,   tryCount:0, lastBuildResult:'Not build yet'],
]
```

### Reinstall clusters

* The first step sorts the map object depending on the priority from higher to lower with the help of separate functions: `getSorted()`.
* Then the step goes through each item in the list and checks its resource status.
  * If the status of the cluster is `FREE` the cluster name is passed to the function that contains the logic of reinstallation: `reinstallCluster()` and call [cluster-reinstall](https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-reinstall/) Jenins job.
  * If the status is `Locked` the map object will be updated and the reinstall will be skipped here.
* There is a timeout of 10 hours for every single reinstallation process here.
* If the cluster is already out of the pool (with labels: `faulty` or `ceph-error`)
  * can be restarted 3 times in case of any failures
  * no need to check the time frame
* For the other clusters, if a reinstallation fails once, the job completes without retrying.
* If the entire process for a cluster reinstallation fails, it will be given a new `need_manual_reinstall` label.
  * This info is stored in the final HTML report (attached to the job as artifact) in the `TODO` column.
  * This also means that the current driver should check what the problem might be here and need to start the reinstall manually.

### Reinstall locked clusters with wait

* After the `normal` reinstallation if there is any cluster with `Locked`  status, a new cycle will be started.
* This loop will wait for the cluster to be free if they are used in ongoing pipelines.
* The job will poll the cluster to get the new status in every 5 minutes.
* There is a timeout of 15 hours for the max waiting and reinstalling time also.
* When the cluster gets the `FREE` status, the reinstallation process can begin.

### Create cluster reinstall report

* Create HTML Report, save it as artifact with name `auto_reinstallation_report.html` to the job and send the report it to Driver channel.

Example of cluster reinstall report

```
Cluster automation report

Cluster                 | Label                | Priority | Last Build Result | Try Count |  Status | TODO                  | Url
------------------------|----------------------|----------|-------------------|-----------|---------|-----------------------|----------------------------------------------------------------------------
kubeconfig-seliics02681 | ceph-error           | 2001     | FAILURE           | 1         |  Failed | Need manual reinstall | https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-reinstall/853/
kubeconfig-seliics02452 | faulty               | 1002     | SUCCESS           | 1         |  DONE   |                       | https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-reinstall/854/
kubeconfig-seliics04535 | faulty               | 1001     | Not build yet     | 0         |  Locked |                       |
kubeconfig-seliics03116 | bob-ci               | 3        | SUCCESS           | 1         |  DONE   |                       | https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-reinstall/855/
kubeconfig-seliics04510 | bob-ci               | 2        | FAILURE           | 1         |  Failed | Need manual reinstall | https://seliius27190.seli.gic.ericsson.se:8443/job/cluster-reinstall/856/
kubeconfig-seliics03117 | bob-ci-upgrade-ready | 1        | Not build yet     | 0         |         |

https://seliius27190.seli.gic.ericsson.se:8443/job/test-etamgal-cluster-reinstall-automation/82/
```

* Cluster - name of the cluster that needs reinstall
* Label - label of the lockable resource. This label doesn't change during or after reinstallation
* Priority - Priority order of the executions. e.g. out of pool clusters with label 'ceph-error' or 'faulty' must be higher prio than others
* Last Build Result - last build result of cluster-reinstall job
  * possible values:
    * Not build yet - cluster has not started reinstall yet
    * SUCCESS|FAILURE|ABORTED|CANCELLED|etc.
* Try Count - number of cluster reinstall retries
* Status: final state of the reinstall
  * possible values:
    * DONE - everything was ok, reinstall finished successfully
    * Failed  - the reinstall was failed, so manual work needed here
    * Skipped - the reinstall was skipped due to current datetime is out of the permitted time frame to reinstall
    * Locked - the cluster was locked, so reinstall could not start automatically
      * the next run will try it again, so there is no need for manual work in the first round
      * of course, this cluster can be manually removed from the pool at any time to avoid a permanent locked state
* TODO:
  * Need manual reinstall - when cluster reinstall was failed
* Url: direct link to the cluster-reinstall Jenkins job
