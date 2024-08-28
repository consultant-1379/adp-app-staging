# Verify Code-review and patchset changes in Product CI pipelines

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

Some of the Product CI pieplines where the pipelines validating manual changes we are validating the latest patchset through the whole staging.

* eea-application-staging
* eea-product-ci-code-loop
* eea-product-ci-meta-baseline-loop
* eea-product-ci-shared-libraries-validate-and-publish

## Basic workflow for the patchset validation

* In prepare jobs checked if a newer patchset was uploaded by a non technical user (ECEAGIT):
  * in shared library function we get all pathset from gerrit, and geting the latest patchset uploaded by non technical user.
  * validate this patchset if has al necessary review. If not prepare should FAIL, because the newer patset must have CR*1 again.
  * save the latest (patchset uploaded by any user) as REFSPEC_TO_VALIDATE in artifact.properties to be able to load in Spinnaker
* Spinnaker will pass the REFSPEC_TO_VALIDATE as GERRIT_REFSPEC if exists

```
${#stage('PrepareBaseline')['context']['REFSPEC_TO_VALIDATE']?:parameters['GERRIT_REFSPEC']}
```

* All validation jobs and the publish in pipelines checks if a newer patchset was uploaded by any user (technical or other):
  * if newer patchset exists we have to terminate validation

## eea-application-staging

[spinnaker pipeline](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-application-staging)

In cnint repository there are changes from not just Product Ci Team developers
To be able to validate the reviewers we have a [configuration file](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/technicals/cnint_reviewers.yaml)

### Validaton at CR+1

[job eea_app_baseline_manual_flow_verify_cr](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/documentation/cnintReviewProcess.md#eea_app_baseline_manual_flow_verify_cr-description)

Validation a job triggered by gerrit plugin
The job get the file list and reviewers list of the last patchset and check if patchset has all necessary review according to the reviewers config file

### Validation in prepare

In prepare we validate that the latest uploaded patch set uploaded by non-technical user has all necessary review. In this validation enabled to have new patchset with rebase by technical user after Code-Review.

### Validation in latest stages

We validate the patchset parameter ( GERRIT_REFSPEC) still the latest pathset of the change. Not allowed any new patchset, not even from technical user.

* eea-application-staging-batch
* eea-application-staging-product-upgrade
* eea-application-staging-publish-baseline

## eea-product-ci-code-loop

### Validation in prepare

In prepare we validate that the latest uploaded patch set uploaded by non-technical user has all necessary review. In this validation enabled to have new patchset with rebase by technical user after Code-Review.
Reviewers config file : [adp_app_staging_reviewers.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/technicals/adp_app_staging_reviewers.yaml)

### Validation in latest stages

We validate the patchset parameter ( GERRIT_REFSPEC) still the latest pathset of the change. Here not allowed any new patchset not even from technical user.

* functional-test-loop
* eea-product-ci-code-loop-publish

### eea-product-ci-meta-baseline-loop

### Validation in prepare

In prepare we validate that the latest uploaded patch set uploaded by non-technical user has all necessary review. In this validation enabled to have new patchset with rebase by technical user after Code-Review.
Reviewers config file : [meta_reviewers.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/technicals/meta_reviewers.yaml)

### Validation latest stages

We validate the patchset parameter ( GERRIT_REFSPEC) still the latest pathset of the change. Here not allowed any new patchset not even from technical user.

* eea-product-ci-meta-baseline-loop-test
* eea-product-ci-meta-baseline-loop-upgrade
* eea-product-ci-meta-baseline-loop-publish

### eea-product-ci-shared-libraries-validate-and-publish

Ci shared library loop contains only one job, so in this job only validate the Code review
Reviewers config file : [ci_shared_lib_reviewers.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/technicals/ci_shared_lib_reviewers.yaml)
