# eric-eea-prod-ci-helper docker image drop

eric-eea-prod-ci helper docker image is an alpine Linux based image containing simple utilities, and is maintained by Product CI.

## Usage

See [README](https://gerrit.ericsson.se/plugins/gitiles/EEA/eea4-prod-ci-helper) of the docker image repo.

## Pipelines

### eea-prod-ci-helper-precodereview

The [eea-prod-ci-helper-precodereview](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-prod-ci-helper-precodereview/) job is started by a Gerrit trigger whenever a new patchset is uploaded to the [eea4-prod-ci-helper](https://gerrit.ericsson.se/plugins/gitiles/EEA/eea4-prod-ci-helper) repository.

The job checks the changed files, and runs

* Jenkins patchset hooks
* if any markdown files changed, runs a markdown lint
* if the Dockerfile changes, starts a local docker build, and starts a docker container from the newly built image and tests if kubectl and helm commands work.

If no stages failed, the commit gets Verified +1.

### eea-prod-ci-helper-validate-and-publish

After CR +1 on an eea4-prod-ci-helper commit, a Gerrit trigger starts the [eea-prod-ci-helper-validate-and-publish](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-prod-ci-helper-validate-and-publish/) job. This job builds and publishes the new docker image version with the following steps:

* Rebases the commit
* Validates the patchset (if it has the necessary reviews)
* Checks out the latest refspec (after the rebase)
* Generates a new version with bob-adp-release-auto [version-handler.py](https://gerrit.ericsson.se/plugins/gitiles/adp-cicd/bob-adp-release-auto/+/HEAD/utils/README.md#version_handler), builds the docker image and tags with the new version number.
* Starts a container from the newly built image, and validates if kubectl and helm commands work
* If the previous steps succeeded, it merges the changes to the master
* pushes the new docker image to the [proj-eea-drop](https://armdocker.rnd.ericsson.se/artifactory/docker-v2-global-local/proj-eea-drop/eric-eea-prod-ci-helper/) docker registry
* Creates and pushes a git tag with the new version number

## Uplifting kubectl- and helm version for eric-eea-prod-ci-helper docker image

The docker image is build with kubectl- and helm versions specified as a build argument (ARG in Dockerfile.) The precodereview and publish pipeline build the image with the kubectl- and helm versions provided in [ruleset2.0.yaml](https://gerrit.ericsson.se/plugins/gitiles/EEA/eea4-prod-ci-helper/+/master/bob-rulesets/ruleset2.0.yaml) - `kubectl-default-version` and `helm-default-version` properties.

In case a new image needs to be built with updated versions, these values need to be changed in a commit. Upon CR +1, the new image gets built.

*Note*: the new kubectl- and helm binaries must be present in <https://arm.seli.gic.ericsson.se/artifactory/proj-cea-external-local/ci/3pp/kubectl/> and
<https://arm.seli.gic.ericsson.se/artifactory/proj-cea-external-local/ci/3pp/helm/> repositories respectively.

```
properties:
  (...)
  - kubectl-default-version: 1.28.6
  - helm-default-version: 3.14.1
```

**TODO**: when implemented, add details of the new pipeline capable of uplifting the versions
