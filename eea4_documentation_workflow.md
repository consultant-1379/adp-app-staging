# EEA4 documentation workflow

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## [documentation-verify-job](https://seliius27190.seli.gic.ericsson.se:8443/view/all/job/documentation-verify-job/)

This job verifies the documentation, when a commit published on gerrit for review.

[EEA4 Documentation ruleset](https://gerrit.ericsson.se/plugins/gitiles/EEA/product_documentation_baseline/+/master/document_builder.yaml)

Rules validated: lint - documentation-verify-job

Validation steps:

* Params DryRun check
* Prepare
* Checkout - adp-app-staging
* Checkout - eea4_documentation
* Check unmerged parents (check if specified refspec has any unmerged parents)
* Rulesets DryRun
* Rulesets Validations
* Get helm chart version
* Documentation building
* cleanup

## [documentation-preview](https://seliius27190.seli.gic.ericsson.se:8443/view/all/job/documentation-preview/)

This job generates and stores the preview package to the preview server, when a commit merged on gerrit for EEA/eea4_documentation repo.

Steps:

* Params DryRun check
* Checkout - eea4_documentation
* Prepare
* Build preview package
  * This will execute 'build-preview-package' rule from the [ruleset file](https://gerrit.ericsson.se/plugins/gitiles/EEA/eea4_documentation/+/master/bob-rulesets/documentation_preview.yaml)
* cleanup

## resource and release lock

The documentation build and publish happens in separate jobs, so between a documentation build and publish shouldn't be other documentation published. That's why we need a lockable resource.
The resource is locked when the documentation build starting and released if the build failed or after the publish.
Resource name: "doc-build"

1. First step the resource is locked as usual
2. Note added with the

    * in case of docreviewOK-job: \<job name\> - \<build number\>
    * in case od documentation_build: \<job name\> - \<build number\>
    * in case of Product CI build: \<pipeline name\> - \<pipeline execution id\>

3. As we have the build and a publish in different jenkins jobs called from Spinnaker, we can't keep the resorce locked, that will released at the and of the job, so before relase lock we put the resource to reserved state for the sedond part of the workflow
4. We will clean the note and  unreserve the resource at once if the documentation build failed
5. After the [eea4-documentation pipeline](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?q=eea4&pipeline=eea4-documentation) or [eea-application-staging pipeline](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-application-staging) the resorce will unReserved regardless the state of the publish in [cleanup-for-doc-build-lock pipeline](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=cleanup-for-doc-build-lock)

If the resource stucked by any reason, it can be relased easily on the Jenkins [Lockable Resources page](https://seliius27190.seli.gic.ericsson.se:8443/lockable-resources/) with the "unReserve" button.

## [docreviewOK-job](https://seliius27190.seli.gic.ericsson.se:8443/view/all/job/docreviewOK-job/)

The commit needs to be in review state. (Draft state is not supported by docreviewOk-job.)

Manual submit has been disabled for non Product CI members in eea4_documantation repository

This job is triggered after the manual doc review by a "MERGE" command in Gerrit and

* builds the documentation dxp files
* submits the commit in eea4_documentation repo
* archives the documentation files as Jenkins artifact for 3 days

## [documentation_publish](https://seliius27190.seli.gic.ericsson.se:8443/view/all/job/documentation_publish/)

This job is triggered by Spinnaker when the docreviewOK-job has sucessfully finished.
The number of the docreviewOK_job has been handed over as an input parameter by Spinakker as well.

This job

* takes the Jenkins archive from the dockreviewOK_job and extracts that
* generates the version of eric-eea-documentation-helm-chart-ci in eea4_documentation repo
* packages the eric-eea-documentation-helm-chart-ci-\<version\>.tgz and publishes it to <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/eric-eea-documentation-helm-chart-ci/>
* publishes the documentation to <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-docs-drop-generic-local/product-level-docs/>

## [eea-application-staging-documentation-build job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-documentation-build/)

Triggers : [eea-application-staging pipeline](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-application-staging) - the Product CI loop

* 2 hours wait added before this job in Spinnaker to avoid locking doc-build resource in Jenkins too long, with this we can run more product level documentation build for manual documentation updates in parallel with the application staging pipeline runs which can run in huge queue around EEA releases, and documentation deliveries are frequent during these periods as well
* builds the documentation dxp files
* create a change in the eea4_documentation repo with a comment of the product version information
* archives the documentation files as Jenkins artifact for 3 days

## [eea-application-staging-publish-baseline job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-publish-baseline/)

* publish the new EEA4 product baseline
* takes the Jenkins archive from the dockreviewOK_job and extracts that
* submits the commit in eea4_documentation repo
* generates the version of eric-eea-documentation-helm-chart-ci in eea4_documentation repo
* packages the eric-eea-documentation-helm-chart-ci-\<version\>.tgz and publishes it to <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/eric-eea-documentation-helm-chart-ci/>
* publishes the documentation to <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-docs-drop-generic-local/product-level-docs/>

## [eea-metabaseline-product-and-cpi-version-change](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?q=cpi&pipeline=cleanup-for-doc-build-lock,eea-metabaseline-product-and-cpi-version-change)

This pipeline is triggered by Spinnaker when the documentation_publish job or the eea-application-staging-publish-baseline has sucessfully finished.

This job

* updates the version of eric-eea-documentation-helm-chart-ci in project-meta-baseline\eric-eea-ci-meta-helm-chart in case of  the trigger was documentation_publish
* if the trigger was the product baseline publish, then create a meta baseline change with the product and documentation version change together

## [documentation-release](https://seliius27190.seli.gic.ericsson.se:8443/view/all/job/documentation-release/)

This job is triggered manually or by the product release job.

This job

* copies the documentation artifacts to the <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-docs-released-generic-local/> arm repo
* creates "+" version of eric-eea-documentation-helm-chart-ci and publish it to the <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-released-helm/> arm repo
* creates PRA git tag in eea4_documentation git repo

## [cleanup-for-doc-build-lock pipeline](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=cleanup-for-doc-build-lock)

This pipeline triggered by

* eea-application-staging pipeline any result
* eea4-documentation pipeline any result

Stages:

* evaluate the pipeline name and id
* triggers the eea-application-staging-lock-cleanup job with the calculated parameters

## [eea-application-staging-lock-cleanup job](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-lock-cleanup/150/)

This job triggered by the cleanup-for-doc-build-lock pipeline

Steps:

* find the locked resource
* delete the note of the resource
* unReserve the resource
* after eea-application-staging run abandone the change if the documentation wasn't published
