# Functional tests - Spinnaker - Jenkins connection test

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Spinnaker - Jenkins connection test

This test's scope is to validate the connection between the ADP Spinnaker (<https://spinnaker.rnd.gic.ericsson.se/>) and our Jenkins instance.
The test can be part of an automated flow, time-triggered, but also can used manually e.g. after a Jenkins upgrade. The target Jenkins can be selected as a parameter.

### Elements of this test flow

+ functional-test-spinnaker-job Jenkins job this triggering the whole flow
  + source

            technicals/functional_test/tests/functional_test_spinnaker_jenkins.groovy
            technicals/functional_test/tests/functional_test_spinnaker_jenkins.Jenkinsfile
    + parameters:
      + JENKINS_URL choice parameter for master or test jenkins
      + credential id for the master or the test Jenkins API token
    + triggers: manually

+ functional-test-spinnaker-drop Jenkins job for triggering the Spinnaker pipeline
  + source

            technicals/functional_test/tests/functional_test_spinnaker_jenkins_drop.groovy
            technicals/functional_test/tests/functional_test_spinnaker_jenkins_drop.Jenkinsfile
    + parameters: -
    + artifacts : artifact.properties

            CHART_NAME=test
+ eea-spinnaker-functional-test-loop Spinnaker pipeline
<https://spinnaker.rnd.gic.ericsson.se/?#/applications/eea/executions/configure/942723de-1539-43e6-91dd-7ccd51adf90e>
  + triggered: by functional-test-spinnaker-drop Jenkins job
  + parameters: artifact.properties
  + stages: "Jenkins-job"
+ functional-test-spinnaker-stage Jenkins job
  + Source
            technicals/functional_test/tests/functional_test_spinnaker_stage.groovy
            technicals/functional_test/tests/functional_test_spinnaker_stage.Jenkinsfile
    + parameters:
      + TEST_STRING this parameter should be the CHART_NAME value from the drop job artifact.properties

### Test steps

1. Triggering the build functional-test-spinnaker-drop through api on the target Jenkins URL
2. Polling Spinnaker until the eea-spinnaker-functional-test-loop pipeline started
3. Polling the functional-test-spinnaker-stage Jenkins job on the target Jenkins and check if it's SUCCESSFUL
4. Polling Spinnaker until the eea-spinnaker-functional-test-loop pipeline and validate if SUCCEDED
