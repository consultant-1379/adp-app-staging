# Cluster label automation

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

This is a documentation about the automated labeling workflow present during the install and upgrade deployments, log collection, cluster cleanup, baseline install, labeling clusters as faulty, ceph-error, etc.

The job that changes cluster (or other lockable resources) labels is '[lockable-resource-label-change](https://seliius27190.seli.gic.ericsson.se:8443/job/lockable-resource-label-change/)' job. It can be built manually as well as is triggered in this automated workflow.

Cluster label is also changed by `setLockableResourceLabels()` call defined in ci_shared_library repo in some places.

## Log collection

Calling `prepareClusterForLogCollection()` usually precedes triggering 'cluster-logcollector' job.

Cluster label is changed to 'cluster-logcollector-job' by [prepareClusterForLogCollection()](https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master/src/com/ericsson/eea4/ci/ClusterLogUtils.groovy#92) call defined in ci_shared_library repo.

prepareClusterForLogCollection() is called by the following jobs (unless `params.SKIP_COLLECT_LOG` is true where supported):

* pipelines/eea_adp_staging/eea_adp_staging_adp_nx1_loop.Jenkinsfile
* pipelines/eea_application_staging/eea_application_staging_batch.Jenkinsfile
* pipelines/eea_application_staging/eea_application_staging_nx1.Jenkinsfile
* pipelines/eea_application_staging/eea_application_staging_product_baseline_install.Jenkinsfile
* pipelines/eea_application_staging/eea_application_staging_product_upgrade.Jenkinsfile
* pipelines/eea_product_ci_meta_baseline_loop/eea_product_ci_meta_baseline_loop_test.Jenkinsfile
* pipelines/eea_product_ci_meta_baseline_loop/eea_product_ci_meta_baseline_loop_upgrade.Jenkinsfile
* pipelines/eea_product_release_loop/eea_product_release_loop_bfu_gate_upgrade.Jenkinsfile
* technicals/cluster_validate.Jenkinsfile

## Cluster cleanup

The next step is setting 'cleanup-job' label before triggering 'cluster-cleanup' job.

When 'cluster-cleanup' job is triggered, either `params.DESIRED_CLUSTER_LABEL` label on job success, when we have ceph issue on cluster than 'ceph-error', when all other failure case 'faulty' label is assigned to the cluster.

The 'cluster-cleanup' job is called when:

1. 'cluster-logcollector' job is built with `CLUSTER_CLEANUP == true` (true by default), it triggers the 'cluster-cleanup' job in its post section.
2. 'cluster-cleanup' job is always triggered twice in post stages of 'functional-test-with-cluster-wrapper' job.

## CUSTOM_CLUSTER_LABEL parameter

Alternative flow of automated labeling workflow is achieved by passing `CUSTOM_CLUSTER_LABEL` parameter that is possible in one of the following pipelines:

* pipelines/eea_adp_staging/eea_adp_staging_adp_nx1_loop.Jenkinsfile
* pipelines/eea_application_staging/eea_application_staging_batch.Jenkinsfile
* pipelines/eea_application_staging/eea_application_staging_nx1.Jenkinsfile
* pipelines/eea_application_staging/eea_application_staging_product_baseline_install.Jenkinsfile
* pipelines/eea_application_staging/eea_application_staging_product_upgrade.Jenkinsfile
* pipelines/eea_product_ci_meta_baseline_loop/eea_product_ci_meta_baseline_loop_test.Jenkinsfile
* pipelines/eea_product_ci_meta_baseline_loop/eea_product_ci_meta_baseline_loop_upgrade.Jenkinsfile

This actually is intended to prevent further automated labeling workflow (triggering 'cluster-logcollector' and/or 'cluster-cleanup' jobs) and leave the cluster untouched for some investigation.

## Redeploying baselines

The cluster label is changed to 'bob-ci-baseline-redeploy' in the `pipelines/eea_application_staging/eea_application_staging_validate_baseline.Jenkinsfile` pipeline in 'Redeploy product baseline' and 'Redeploy meta baseline' stages.
'Redeploy product baseline' stage triggers 'cluster-cleanup' job then as mentioned above.

## NOTE Manual label change

In case the lockable-resource-label-change is started manually (has no upstream trigger, retrriggered, or has SPINNAKER_TRIGGER_URL), the job will fail if the resource is already locked, and RESOURCE_RECYCLE is true. This can be overruled by checking IGNORE_LOCK, but should be only done if it is justifiable - in this case it will only print a warning to the log.

## Product CI cluster install labeling workflow

![Cluster install labeling workflow](https://eteamspace.internal.ericsson.com/download/attachments/1558119973/cluster_install_labeling_workflow.drawio.png)

[Cluster reinstall documentation](https://eteamspace.internal.ericsson.com/display/ECISE/Cluster+reinstall)

[Cluster reinstall automation documentation](https://eteamspace.internal.ericsson.com/display/ECISE/Cluster-reinstall-automation)

## Product install labeling workflow

![Product install labeling workflow](https://eteamspace.internal.ericsson.com/download/attachments/1558119973/product_install_labeling_workflow.drawio.png)

![Product install labeling workflow PLAN](https://eteamspace.internal.ericsson.com/download/attachments/1558119973/product_install_labeling_workflow_PLAN.drawio.png)

## Product upgrade labeling workflow

![Product upgrade labeling workflow](https://eteamspace.internal.ericsson.com/download/attachments/1558119973/product_upgrade_labeling_workflow.drawio.png)
![Product upgrade labeling workflow PLAN](https://eteamspace.internal.ericsson.com/download/attachments/1558119973/product_upgrade_labeling_workflow_PLAN.drawio.png)

[Product upgrade documentation](https://eteamspace.internal.ericsson.com/display/ECISE/EEA4+Common+ONLINE+and+OFFLINE+Product+Upgrade)

## Product CI functional test labeling workflow

![Functional test labeling workflow](https://eteamspace.internal.ericsson.com/download/attachments/1558119973/functional_test_labeling_workflow.drawio.png)

[Functional test documentation](https://eteamspace.internal.ericsson.com/display/ECISE/Developing+and+running+functional+test+on+product+CI+code+base)
