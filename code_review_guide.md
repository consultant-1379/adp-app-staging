# Code review and coding style guide for Product CI Repositories

## Do-s and don't do-s

A commit author should make sure to follow the guidelines below when sending a commit to review. A reviewer should check if the commit fulfills these requirements (where applicable).

### In general

* **Make sure that the afterlife of the commit can be monitored**: Adding CR to commits outside of working hours is risky! Don't add CR when the commit cannot be monitored and reverted or fixed if needed (eg: don't CR on Friday evenings).

* **Check documentation**: Always check if proper documentation was added. Purpose of the documentation is not to document the trivial stuff (eg: stage names, which are the first thing that we see when we look at a job in Jenkins), but to document the why-s and the how-s of these stages.

* **Check AC in the ticket**: During the groomings the most important test cases must be agreed upon. The reviewer must check if these were tested, and the tests were passed.

### Jenkins pipeline changes checks

* **Check if test groovy job was deleted from commit**: Check if the [test job groovy file](https://eteamspace.internal.ericsson.com/pages/viewpage.action?pageId=1468597495#DevelopingProductCItestjobs/pipelines-1.a.CreateagroovyDSLjobinadp-appstagingtestdirectory) was removed from the commit.

* **Check naming conventions**: Check if the basename of the Jenkinsfile and the job groovy file is the same (eg: eea_product_prepare_upgrade.Jenkinsfile and eea_product_prepare_upgrade.groovy), and check if these contains only underscores (`_`) not hyphens (`-`). Also check that the name of the *generated Jenkins job* is formed from these, replacing the underscores with hyphens (eg: `eea-product-prepare-upgrade`).

* **Check if all (corner-)cases were tested**: When a new logic is being introduced, check if all possible outcomes were tested. Also the author of the commit should make sure to include a detailed list of the test cases (and explain which case tests what exactly) in their review request!

* **Check if commit is "method too large proof"**: In case of already long pipeline codes we may face method too large errors, try to act proactively to avoid these errors. The best practice is to encapsulate more complex pipeline logics to functions outside the pipeline code, or even to separate pipelines. There are several examples for these in our code: pipeline logic organized to functions: <https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master/jenkins/pipelines/functional_test_shared_lib_gitscm.Jenkinsfile#>, organized to separate jobs: <https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master/jenkins/pipelines/functional_test_shared_lib.Jenkinsfile>

* **Check for unnecessary shell codes**: Check if the code contains unnecessary shell codes (eg: grep, sed, etc which have native groovy code equivalents) as these are hard to unit test. Use groovy as much as possible where it makes sense.

* **Check for overuse of bob**: Check that simple shell commands - that are not using any docker image, therefore can be run from the Jenkins build nodes - are not executed via bob.

* **Check env variable- and param references** - Check that whenever possible, environment variables are referenced with "env" prefix, and parameters with "params" to distinguish between them. Eg: `env.CUSTOM_CLUSTER_LABEL` `params.INT_CHART_NAME`. While environment variables *could* be referenced without the env prefix; and for every parameter (parameters are immutable) an environment variable (mutable) is automatically created by Jenkins, so *params notation could be omitted as well*, these can lead to serious confusions and/or unexpected variable behaviour. But it's also good to know that sometimes we deliberately utilize this mechanism in some jobs, where we need to override a GERRIT_REFSPEC (eg. after a rebase) that was given as parameter - but since parameters cannot be overridden - we override the environment variable. So while this is not a strict rule, we should try to be consistent with the env/param notations!

* **Check if dry-run functionality was added** - Where possible we should make sure to implement "dry-run" solutions to our codes, so that we can test specific parts without using expensive resources unnecessarily.

* **Check CMA/HELM scenarios** - During the HELM/CMA transition period some changes may need to be testable with both Helm and CMA configuration. If a certain Jenkinsfile change involves stages where the `params.HELM_AND_CMA_VALIDATION_MODE` is used, it means that the change must work with both Helm and Helm+CMA mode, therefore it needs to be tested **both** ways. (If the commit doesn't involve a stage where params.HELM_AND_CMA_VALIDATION_MODE is used, Helm+CMA mode testing is enough.) For example, in the below change both scenario must be tested:

```
stage('Load config json to CM-Analytics') {
    when {
        expression { params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE__HELM_VALUES_AND_CMA_CONF || params.HELM_AND_CMA_VALIDATION_MODE == CMA_MODE_IS_HELM_AND_CMA }
    }
    steps {
        loggedStage() {
            load_config_json_to_CMAnalytics(stageResults)
        }
    }
}
```

* **TODO**: in the future, we should implement the following solution to CR process according to the above logic: we need to be able to add the following comments during the review: `SKIP_TESTING_INSTALL`, `SKIP_TESTING_UPGRADE`, `SKIP_TESTING_INSTALL_WITH_HELM_CONFIG`, `SKIP_TESTING_UPGRADE_WITH_HELM_CONFIG` to trigger the necessary functional test scenario(s) for a certain commit.

* **Don't waste resources for unnecessary tests**: Only test what is *really* necessary. Don't run the whole pipeline when you have to change only a small part of it, and that small part is testable separately. Avoid cluster usage where it's not necessary. Always try to think over what steps are necessary to run in your tests, what steps shouldn't run (eg.: uploading, publishing, git commiting, starting other long running jobs, sending e-mails, etc.) to avoid expensive steps and unnecessary resource locking!

### Shared library changes

* **Check all occurrences**: In case of a shared library class/method change check if all occurrences, where that class/method is used was updated in all of our repositories:
  * adp-app-staging
  * ci_shared_libraries
  * cnint
  * deployer
  * eea4-ci-config
  * eea4_documentation
  * jenkins-docker
  * project-meta-baseline

* **Check if incompatible changes were communicated**: In case of a shared library commit that introduces some incompatible changes that would affect other Teams, a deprecation period needs to be communicated at CI CoP! (eg: GitScm is used extensively by other teams!)

* **Check that no pipeline specific logic was added**: Shared library classes are for library functionality only. Check that no pipeline specific code was added to shared library classes. Simple, reusable steps should go under `vars` directory!

* **Check that no bob calls were added to shared lib commit**: Bob calls should not be added to shared library classes, unless its unavoidable (This case these calls should go to `vars`! (TODO: during the unified install implementation check that k8s-test calls are removed from the shared library!)

* **Check if functional test cases were added for classes**: For every shared library class - that was created or changed in the commit - check if the necessary functional tests were added. If several methods were changed or added, make sure that all of them has their respective test cases. If a method can have several outcomes (eg. multiple constructors, etc), test all of them! Also, every class must have their own functional test job under `ci_shared_libraries/jenkins/pipelines`!

* **Check if functional test cases were added for vars** - changes under `vars` should be tested as well! In general all vars should be tested in the `jenkins/pipelines/functional_test_shared_lib_vars.Jenkinsfile`. For vars that are calling a specific shared library class, should also be tested in the class-specific job (*this means these should be tested at both places*)!

* **Check if only the relevant test cases run** - **TODO**: automatic solution to test only parts of the shared library that changed should be implemented in [EEAEPP-100828](https://eteamproject.internal.ericsson.com/browse/EEAEPP-100828)

### Spinnaker testing

* **Check if Spinnaker expressions were tested**: Spinnaker expressions must be tested on an `Evaluate variables` stage by creating **new variables**. With these variables all of the possible outcomes should be tested - however, a limitation is *we can only test with input values that have already been seen in previous runs* - but with the use of default values other scenarios can be tested as well. Know that you mustn't save a variable until it has syntax error, as this can fail the pipeline.

* **Check if variables are used instead of copy-paste**: On the `Evaluate variables` page variables should be created, and in the following stages the variables themselves should be used. It means that if a variable was created, one must't copy-paste the expression of the variable and use the copy-pasted value in the upcoming stages - reviewer must check if the variable itself is used and no redundancy was created!

* **Check if a change is backwards-compatible**: If we introduce a new expression (eg. a new field to be extracted from an artifact.properties file), make sure to handle the case (with default value) when the field we are looking for is not present. Using a default value is generally considered a good practice!

* **Spinnaker changes should be made together with the reviewer**: Since we currently configure Spinnaker from the GUI, and don't (yet) have proper testing workflow for Spinnaker changes, it is agreed that Spinnaker changes should be made together with the reviewer (four-eyes principle)! **TODO**: ticket will be created for a Spinnaker testing workflow!

## Suggested CR template

According to the above guides, a checklist for reviewers. Check these where applicable, if one guideline cannot be followed, explain.

General:

* The commit can be monitored
* Documentation done
* AC is fulfilled

Pipeline changes:

* Test job deleted from commit
* Naming conventions checked
* Commit is "method too large proof"
* All (corner-) cases were tested
* No unnecessary shell codes
* No unnecessary bob usage
* Correct env variable- and params usage
* dry-run functionality
* CMA/HELM scenarios tested

Shared library changes:

* All occurrences checked
* Incompatible changes deprecation communicated
* No pipeline-specific logic added
* No bob-calls added
* Necessary functional test cases for classes added
* Necessary functional test cases for vars added

Spinnaker testing

* Spinnaker expressions tested
* Variable usage
* Change is backwards-compatible
* Changes made together with the reviewer
