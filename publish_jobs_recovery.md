# Manual recovery from publish job failures

## Recover from eea-application-staging-publish-baseline failures

### Failed stage: initial stages

#### Failure

If for some reason (eg. network issues) the first stages fail (`Gerrit message, Checkout, Ruleset change checkout, Prepare, Init, Init documentation` stages) we generally have to retrigger the whole spinnaker pipeline.

##### Action

For details on how to rerun the spinnaker pipeline, see [Rerunning EEA Application staging pipelines](https://eteamspace.internal.ericsson.com/pages/viewpage.action?spaceKey=ECISE&title=Product+CI+Operations+tasks+for+pipeline+drivers#221-rerunning-eea-application-staging-pipelines) in the driver documentation.

### Failed stage: Resource locking - Publish Helm Chart

If Publish Helm Chart stage failes, it raises an error and the pipeline fails.
When this stage fails, the **action needed depends on which part of the publish rule** (which part of `ihc_auto publish`) failed.

#### Failure before the helm chart was uploaded

If the failure happened before the next version of the helm chart was uploaded (eg. connection error), the pipeline can be restarted without risk.

##### Action

At this point the Spinnaker pipeline can be restarted. For details on how to rerun the spinnaker pipeline, see [Rerunning EEA Application staging pipelines](https://eteamspace.internal.ericsson.com/pages/viewpage.action?spaceKey=ECISE&title=Product+CI+Operations+tasks+for+pipeline+drivers#221-rerunning-eea-application-staging-pipelines) in the driver documentation.

#### Failure after the chart upload, before git push

If a failure happened **after the chart version was uploaded, but before the commit with the updated Chart.yaml was pushed to git**, rerunning the Spinnaker pipeline cause the eea-application-staging-publish-baseline job to throw the exception:

`ERROR: Next calculated version \<version_number\> is already uploaded. Make sure version in Chart.yaml is correctly stepped`

This is because [ihc-auto script](https://gerrit.ericsson.se/plugins/gitiles/adp-cicd/adp-int-helm-chart-auto/+/master/src/python3/bin/ihc-auto) calculates the next version to be published from the helm chart Chart.yaml file downloaded to the workspace from git. It also checks whether the next version is already present in the arm with `_get_new_version` function. If for some reason (eg: some previous pipeline run was interruppted) the the new version was already uploaded to the arm, but the updated Chart.yaml file didn't get commited and merged into git, this error is raised.

##### Action

* The **easiest, preferred** solution to this is to delete the problematic version from the ARM.
  * For now this should be done by someone who has the right permissions to do this.
  * In the future this can be done in an automated way: A post action stage can check if publish helm chart failed at this part of the stage. If it is the case, it runs the automatic job, that cleans up the problematic package from arm.
    * todo: to be implemented in ticket: <https://eteamproject.internal.ericsson.com/browse/EEAEPP-90262>
* When the fix is done, the Spinnaker pipeline can be restarted. For details on how to rerun the spinnaker pipeline, see [Rerunning EEA Application staging pipelines](https://eteamspace.internal.ericsson.com/pages/viewpage.action?spaceKey=ECISE&title=Product+CI+Operations+tasks+for+pipeline+drivers#221-rerunning-eea-application-staging-pipelines) in the driver documentation.

* *As a sidenote: If for some reason the preferred solution is not applicable, the other option we have is to make sure that the problematic version (which is already uploaded to arm, but not present in the Chart.yaml file) is reflected in Chart.yaml file as well. This can be done by raising the version in Chart.yaml file in a manual commit, and the commit must be approved with* **CR +2**. *This case the pipeline cannot be restarted, we have to finish the remaining steps manually*.

#### Faliure after the chart upload and git push, before git tag

If the failure happened when `ihc-auto` script pushed the new git commit already, but pushing the git tag failed, the python script raises a `Git tag failed` exception.

##### Action

**Starting with this stage if the pipeline fails, it's not recommended to restart the whole pipeline from the beginning, rather fix the individual failed stages manually, if needed**.

This case we have to manually create and push (with eceagit service user) the git tag to gerrit with the chart version calculated by ihc-auto. This can be done in the gerrit GUI, under Projects / selected project / Tags menu.

The version to be tagged can be seen in the job log:

```
10:45:12  2023-09-18 08:45:08,547 [ihc-auto][INFO] Stepped version from 4.6.2-60 to 4.6.2-61
```

We have to create an annotated tag for this version:

* where the tag is the version itself (eg: 4.6.2-61)
* the message for the annotated tag is the same as the commit message, eg: `"[ADP] Integrate ADP uS into 4.7: SHH, PM, BRO, IAM"`

### Failed stage: Upload CSAR

#### Error: CSAR DOWNLOAD / CSAR PROCESSING / CSAR UPLOAD FAILED

Due to the `catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE')`, if any part of `Upload CSAR` stage fails, only the stage will fail, the pipeline will continue execution. The error message in the log will show which part of the CSAR processing failed. This case `csar-package-$VERSION_WITHOUT_HASH.csar`, `csar-package-$VERSION_WITHOUT_HASH.content.txt`, `csar-package-$VERSION_WITHOUT_HASH.images.txt` and `csar-package-$VERSION_WITHOUT_HASH.3pp_list.csv` won't be present in the ARM!

##### Action

Since CSAR packages are not affecting Product CI pipelines (not using CSAR packages as input artifacts), if the CSAR package is not uploaded, it won't break the pipelines, so it's usually **not necessary for the pipeline driver to do any further steps in case of this failure**.

However if for some reason they want to fix it, it can be done by downloading the CSAR version from ARM manually (authenticating with `arm-eea-eceaart-api-token` found in Jenkins credentials) and repeating the steps in the `Upload CSAR` stage and the undderlying `CsarUtils` shared library methods.

### Failed stage: Upload dimtool

#### Failure

Due to the `catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE')`, if `Upload dimtool` stage fails, only the stage will fail, the pipeline will continue execution. However, this case dimensioning tool version `eea4-dimensioning-tool-${VERSION_WITHOUT_HASH}.zip` won't be present in ARM.

##### Action

Since the dimtool upload is not affecting Product CI pipelines directly, if this step fails, the pipelines won't break, so it's usually not necessary  so it's usually **not necessary for the pipeline driver to do any further steps in case of this failure**.

However if for some reason they want to fix it, they can repeat the steps of the failed `Upload dimtool` stage and the underlying ci shared library `Artifactory.copyArtifact`, authenticating with `arm-eea-eceaart-api-token` Jenkins credential to the ARM.

### Failed stage: Submit documentation changes

#### Failure

Due to the `catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE')`, if `Submit documentation changes` stage fails, only the stage will fail, the pipeline will continue execution.
If the documentation rewivew/submit fails for some reason, the documentation needs to be reviewed and submitted manually.

##### Action

In the earlier Spinnaker stage `CPI Build`, where eea-application-staging-documentation-build job ran, an artifact.properties file was created with a `DOC_COMMIT_ID` property, that gets read in this stage. To recover from this failed stage, we have to review and submit the commit denoted with this id manually in gerrit. It needs `verified +1`, `code-review +2` and `submit`.

### Failed stage: Generate and Publish Documentation Helm Chart version

#### Failure

Due to the `catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE')`, if `Generate and Publish Documentation Helm Chart version` stage fails, only the stage will fail, the pipeline will continue execution, but this case the documentation helm chart won't be published to ARM.
If this stage failed, it **must be fixed** so that it won't break any Product CI pipelines.

##### Action

We have to publish a new documentation helm chart manually from the previously built documentation.
To do this, find the previous `CPI build` stage In Spinnaker, which runs `eea-application-staging-documentation-build` Jenkins job. The output of this jenkins job is an `artifact.properties` file with the `DOC_BUILD_NUMBER` and `DOC_COMMIT_ID`. eg:

```
DOC_BUILD_NUMBER=3030
DOC_COMMIT_ID=2105eb177778558940452f21e5a74ed4ae8e6f97
```

A helm chart must be built and published for the commit with this `DOC_COMMIT_ID`.

For this, [documentation_publish](https://seliius27190.seli.gic.ericsson.se:8443/job/documentation_publish/build?delay=0sec) has a recovery option to handle this situation. Parameters should be used to recover: MANUAL_RECOVER_AFTER_FAILED_PUBLISH checked, DOC_BUILD_JOBNAME is selected to `eea-application-staging-documentation-build`.

The job can generate and upload the helm chart and can be started manually in these cases, so no further manual steps needed.

Former manual steps according to the stage:

* checkout the documentation repository - if the previous `Submit documentation changes` succeeded, master can be checked out. However, check whether master HEAD is at `DOC_COMMIT_ID`, if new commits were merged, we need to check out the commit with `DOC_COMMIT_ID`!
* calculate new doc version: `bob/bob -r bob-rulesets/documentation_publish.yaml generate-version`
* publish helm chart: `bob/bob -r bob-rulesets/documentation_publish.yaml publish-helm-chart`
* publish the zipped documentation: `./bob/bob -r bob-rulesets/documentation_publish.yaml publish-docs`

### Failed stage: Create Git Tag in Documentation Repo

#### Failure

Due to the `catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE')`, if `Create Git Tag in Documentation Repo` stage fails, only the stage will fail, the pipeline will continue execution, however, the git tag might not get pushed to the remote repository.

##### Action

A git tag, with the `env.DOC_VERSION` value (calculated in the previous `Generate and Publish Documentation Helm Chart version`) must be created manually. This can be done in the Gerrit UI.

The documentation version can be seen in the log in `Generate and Publish Documentation Helm Chart version` step:

```
10:55:48  Publish Helm Chart
10:55:48  [Pipeline] script
10:55:48  [Pipeline] {
10:55:48  [Pipeline] readFile
10:55:48  [Pipeline] echo
10:55:48  4.6.2-91
```

We need to create a git tag in Gerrit UI for this version, where according to the `bob-rulesets/documentation_publish.yaml create-git-tag` rule,

* the tag is the version generated in the previous step (in the example 4.6.2-91)
* and the message consists of the doc chart name (eg: eric-eea-documentation-helm-chart-ci-4.6.2-91) and version.

### Failed stage: Init dashboard execution

#### Failure

Due to the `catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE')`, if `Init dashboard execution` stage fails, only the stage will fail, the pipeline will continue execution, but data for the baseline publish won't make it into the dashboard.

##### Action

* There is an external [job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-dashboard-manager/build?delay=0sec) to send individual runs to dashboard. This should be used to send the missing publish baseline data.
  * Todo: job to be updated in ticket: <https://eteamproject.internal.ericsson.com/browse/EEAEPP-90265>

### Further fixes in case of eea-application-staging-publish-baseline job result: FAILURE

#### Failure

**Important**! A failed eea-application-staging-publish-baseline job (when the whole job result is FAILURE, not just some stages) stops the Spinnaker pipeline, so the next pipelines **triggered by this job will not be executed, therefore a manual fix is needed** to make sure that the change will be merged into meta as well.

##### Action

After the publish stage [eea-metabaseline-product-and-cpi-version-change](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions/configure/0284e512-72b3-4738-9540-e2ad5f6ec41d) pipeline should have been called. If it was not triggered due to a publish failure, we have to manually do the steps normally done in the `Batching CPI and product version` stage ([eea-product-ci-meta-baseline-loop-merge](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-ci-meta-baseline-loop-merge/) jenkins job).

Here we have to create a manual commit where we raise the product and the documentation version in the `project-meta-baseline` repo, `eric-eea-ci-meta-helm-chart/Chart.yaml` to the values of the

* DOC_VERSION
* INT_CHART_VERSION

parameters, that were written to the `artifact.properties` file by the [publish job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-publish-baseline).

* Example commit in gerrit: [Chart.yaml](https://gerrit.ericsson.se/#/c/16177325/3/eric-eea-ci-meta-helm-chart/Chart.yaml)

* For now such commits can only be merged into the `project-meta-baseline` with **+2**.

* todo: solution to be implemented in ticket: <https://eteamproject.internal.ericsson.com/browse/EEAEPP-90266>
  * for now we can't start an execution of documentation cpi version change pipeline, because of the evaluation stage
  * we should create a modification so that we can start this batching stage manually (by giving the version number) so that the last stages of product-and-cpi-version-change pipeline can run after it
  * this probably requires refactoring of meta-baseline-loop-merge job

## Failure in eea-product-ci-meta-baseline-loop-publish job

### Failed stage: Initial stages

#### Failure

If for some reason (eg. network issues) the initial stages (`Checkout, Prepare, Init`) fail, the whole Spinnaker pipeline can be rerun.

##### Action

How to the `eea-product-ci-meta-baseline-loop` Spinnaker pipeline can be restarted depends on the parent trigger.

### Failed stage: Publish Helm Chart

If Publish Helm Chart stage failes, it raises an error and the pipeline fails.
When this stage fails, the action needed depends on which part of the publish rule (which part of `ihc_auto publish`) failed.

#### Failure after the chart upload, before git push

If a failure happened **after the chart version was uploaded, but before the commit with the updated Chart.yaml was pushed to git**, restarting the Spinnaker pipeline cause the eea-application-staging-publish-baseline job to throw the exception:

`ERROR: Next calculated version \<version_number\> is already uploaded. Make sure version in Chart.yaml is correctly stepped`

This is because [ihc-auto script](https://gerrit.ericsson.se/plugins/gitiles/adp-cicd/adp-int-helm-chart-auto/+/master/src/python3/bin/ihc-auto) calculates the next version to be published from the helm chart Chart.yaml file downloaded to the workspace from git. It also checks whether the next version is already present in the arm with `_get_new_version` function. If for some reason (eg: some previous pipeline run was interruppted) the the new version was already uploaded to the arm, but the updated Chart.yaml file didn't get commited and merged into git, this error is raised.

##### Action

* The **easiest, preferred** solution to this is to delete the problematic version from the ARM.
  * For now this should be done by someone who has the right permissions to do this.
  * In the future this can be done in an automated way: A post action stage can check if publish helm chart failed at this part of the stage. If it is the case, it runs the automatic job, that cleans up the problematic package from arm.
    * todo: to be implemented in ticket: <https://eteamproject.internal.ericsson.com/browse/EEAEPP-90262>
* When the change is in, the Spinnaker pipeline can be restarted.

* *As a sidenote: If for some reason the preferred solution is not applicable, the other option we have is to make sure that the problematic version (which is already uploaded to arm, but not present in the Chart.yaml file) is reflected in Chart.yaml file as well. This can be done by raising the version in Chart.yaml file in a manual commit, and the commit must be approved with* **CR +2**. *This case the pipeline cannot be restarted, we have to finish the remaining steps manually*.

#### Faliure after the chart upload and git push, before git tag

If the failure happened when `ihc-auto` script pushed the new git commit already, but pushing the git tag failed, the python script raises a `Git tag failed` exception.

##### Action

This case we have to manually create and push (with eceagit service user) the git tag to gerrit with the chart version calculated by ihc-auto. This can be done in the gerrit GUI, under Projects / selected project / Tags menu.

The version to be tagged can be seen in the job log:

The version can be seen in the log:

```
17:15:58  2023-09-21 15:15:57,860 [ihc-auto][INFO] Stepped version from 4.6.2-220 to 4.6.2-221
```

We have to create a tag in gerrit, where:

* the tag is the version (like in the log)
* the tag message is the same as the commit message

* When the fix is done, the Spinnaker pipeline can be restarted.

### Failed stage: Init dashboard execution

#### Failure

Due to the `catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE')`, if `Init dashboard execution` stage fails, only the stage will fail, the pipeline will continue execution, but data for the baseline publish won't make it into the dashboard.

##### Action

* There is an external [job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-dashboard-manager/build?delay=0sec) to send individual runs to dashboard. This should be used to send the missing publish baseline data.
  * Todo: job to be updated in ticket: <https://eteamproject.internal.ericsson.com/browse/EEAEPP-90265>
