# EEA4 Product CI Shared Libraries release new version

For releasing a new CI Shared Libraries version this job should be used: <https://seliius27190.seli.gic.ericsson.se:8443/job/eea-product-ci-shared-libraries-release-new-version>

This job has to be started manually whenever a new minor, major or patch version is to be released.

The job will raise one value in the `ci_shared_libraries/VERSION_PREFIX` file, creates a commit and pushes the changes directly to master branch (*not to a refspec for review!*).

After that using the new value of the VERSION_PREFIX, the job will package and upload a new helm package to <https://arm.seli.gic.ericsson.se//artifactory/proj-eea-drop-helm-local/eea-internal/>

The job will run this [version-handler python script](https://gerrit.ericsson.se/plugins/gitiles/adp-cicd/bob-adp-release-auto/+/master/utils/version-handler)

The ruleset for running the version-handler script is located in the [ci_shared_libraries](https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master/ruleset2.0.yaml) repository.

## Workflow

The necessity of a version increase **should be decided during the grooming of the tickets that require modifications in the ci shared libraries**.
When we groom a ticket about CI Shared libraries, we should add an AC note to the ticket that after finishing the development, we need to increase a minor/major/patch version.
Increasing the version is the responsibility of the assignee of the ticket; they have to run the version release job after their CI Shared Libraries changes got merged successfully to master.

### Parameters:

* `DRY_RUN`: dry run only
* `VERSION_TYPE` (choice): can be `MAJOR`, `MINOR` or `PATCH`
* `PUBLISH_DRY_RUN`: for testing - runs the version increase script locally, but no commit is being pushed into the remote origin.
