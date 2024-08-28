# Test report generation workflow

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Architecture

### Product CI pipelines

Product CI pipelines execute E2E tests with UTF, so we store test data using UTF framework. Data for mapping test results with Product CI runs sent to UTF via CI payload in json format. (Jenkins build number, Spinnaker ID, IHC version, CSAR package version, metabaseline version)

e.g. from eea_application_staging_batch.Jenkinsfile

```
stage('init UTF Test Variables') {
    steps {
        script {
            utf.initMapJenkins(env.JOB_NAME,env.BUILD_NUMBER)
            utf.initMapTestExecData("${params.SPINNAKER_ID}","${env.system}",vars.productNamespace)
            def data = readYaml file: "${WORKSPACE}/.bob/chart/eric-eea-int-helm-chart/Chart.yaml"
            utf.initProductChart( data.name, data.version)
            utf.initCsarPackage( "csar-package", data.version)
            data.dependencies.each {dependency ->
                utf.appendMsList(dependency.name,dependency.version)
            }
            utf.initMetaChart( env.META_BASELINE_NAME, env.META_BASELINE_VERSION )

            env.UTF_CI_PAYLOAD = utf.jsonAsString()
        }
    }
}
```

Spinnaker ID is used to connect separate Jenkins runs for the same microservice drop, this is used later to filter for all the test results from Product CI loops.

### UTF and Central ELK

UTF send test results together with the input CI payload data to Central ELK via logstash to store Product CI test results permanently to utf-logs-* indices. Further description about the ELK data sources available [here](https://eteamspace.internal.ericsson.com/display/ECISE/ELK+%28aka+Elastic+stack%29+for+EEA4+CI).

### Grafana dashboard

Visualization of test data is at Central ELK is done with [Grafana dashboard](http://seliics00310.ete.ka.sw.ericsson.se:3000/d/ZQ3FtMW7k/annotations-and-alerts-copy?orgId=1&from=now-2d&to=now&var-spinnaker_id=All&var-cluster=All&var-logtype=All&var-story=All&var-scenario=All&var-step=All&var-result=All&var-story_name=All&var-story_id=All&var-scenario_name=All&var-scenario_id=All&var-step_name=All&var-step_id=All&var-datasource=Elasticsearch&refresh=5m&var-ShowScenarios=PASSED&var-ShowScenarios=FAILED&var-ShowScenarios=UNDEFINED). This dashboard is created by RV to show all the data needed for a test report from the information stored at Central ELK. In order to access Grafana dashboard tunnel may prove necessary depending on the client's network location.

At this dashboard test result can be filtered for a selected time period, Spinnaker ID, and test scenario result at the moment.

### ARM

In case of a successful test run in EEA Application Staging pipeline a new IHC version is created and the test report page filtered for the Spinnaker ID of these pipeline runs is saved to [ARM](https://arm.seli.gic.ericsson.se/artifactory/proj-eea-reports-generic-local/eea4/) in pdf format. Test report name contains the IHC version, so it's easy to find a test report later in ARM even if Spinnaker and Jenkins runs are not available anymore. (e.g. [test_run_result-4.2.0-53.pdf](https://arm.seli.gic.ericsson.se/artifactory/proj-eea-reports-generic-local/eea4/test_run_result-4.2.0-53.pdf))

For pdf generation we use a url2pdf tool developed by AS team.

The upload can fail in the publish pipeline, and we do not want to fail the whole test run because of this issue.

```
07:09:16  ❌ Error: waiting for selector `.react-grid-layout` failed: timeout 8000ms exceeded
07:09:16  { TimeoutError: waiting for selector `.react-grid-layout` failed: timeout 8000ms exceeded
07:09:16      at new WaitTask (/app/node_modules/puppeteer/lib/cjs/puppeteer/common/DOMWorld.js:505:34)
07:09:16      at DOMWorld.waitForSelectorInPage (/app/node_modules/puppeteer/lib/cjs/puppeteer/common/DOMWorld.js:416:26)
07:09:16      at Object.internalHandler.waitFor (/app/node_modules/puppeteer/lib/cjs/puppeteer/common/QueryHandler.js:31:77)
07:09:16      at DOMWorld.waitForSelector (/app/node_modules/puppeteer/lib/cjs/puppeteer/common/DOMWorld.js:312:29)
07:09:16      at Frame.waitForSelector (/app/node_modules/puppeteer/lib/cjs/puppeteer/common/FrameManager.js:842:51)
07:09:16      at Page.waitForSelector (/app/node_modules/puppeteer/lib/cjs/puppeteer/common/Page.js:1285:33)
07:09:16      at _getUrlPageHeight (/app/src/htmlHandler.js:62:20)
07:09:16      at processTicksAndRejections (internal/process/task_queues.js:86:5) name: 'TimeoutError' }
```

However, the test report is still needed in the release mail. There are 2 methods that can work

* There is a url in the publish pipeline (eea-application-staging-publish-baseline) console output, which points to the correct grafana page, this can be exported manually to pdf, and uploaded to the correct [arm path](https://arm.seli.gic.ericsson.se/artifactory/proj-eea-reports-generic-local/eea4/) with the needed version.

* Re-run the publish (eea-application-staging-publish-baseline) with the failed integration helm chart version with replay, but only with the following stages :
  * Checkout
  * Prepare
  * Init
  * post success
  * post cleanup

* post success stage should look something like this (keep in mind, this code can change if the publish pipelines changes in the meanwhile) :

```
post {
    success {
      script {
        if (params.SKIP_TESTING != 'true') {
          // download and archive test report
          echo "Saving test results"
          try {
            def time_range = "from=now-30d&to=now"
            env. URL_TO_CAPTURE = "http://10.61.197.97:3000/d/ZQ3FtMW7k/annotations-and-alerts-copy?orgId=1&${time_range}&var-spinnaker_id=${params.SPINNAKER_ID}&var-cluster=All&var-logtype=All&var-story=All&var-scenario=All&var-step=All&var-result=All&var-story_name=All&var-story_id=All&var-scenario_name=All&var-scenario_id=All&var-step_name=All&var-step_id=All"
            withCredentials([usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD'),
              usernamePassword(credentialsId: 'arm-eceaart-user-pass', usernameVariable: 'USER_ARM', passwordVariable: 'API_TOKEN_EEA')]) {
              sh 'bob/bob -r bob-rulesets/technical_ruleset.yaml url2pdf-bob'
            }
            archiveArtifacts artifacts: "out/test_run_result.pdf", allowEmptyArchive: true            // Upload the PDF to the drop repository
            withCredentials([string(credentialsId: 'arm-eea-eceaart-api-token', variable: 'API_TOKEN_EEA')]) {
              arm.setUrl("https://arm.seli.gic.ericsson.se/", "$API_TOKEN_EEA")
              arm.setRepo('proj-eea-reports-generic-local/eea4')
              arm.deployArtifact( 'out/test_run_result.pdf', 'test_run_result-${INT_CHART_VERSION}.pdf')
            }
          }
          catch (err) {
            echo "Caught: ${err}"
          }
        }
      }
    }
```

* this uploads the pdf to arm, but with the hash after the integration chart version, like this :test_run_result-4.7.1-77-h7d7f811.pdf , see example picture below

![Screenshot: Uploaded pdf and Copy button](https://eteamspace.internal.ericsson.com/download/attachments/1373121525/Test_report_copy.png)

* this can be copied and moved to it's final place after logging in to arm, see example picture below

![Screenshot: Copy and Rename](https://eteamspace.internal.ericsson.com/download/attachments/1373121525/Test_report_rename.png)

## Responsibilities

* Product CI team maintains the CI pipelines, Central ELK and Grafana beside overall ownership of this feature.
* Automation Services team is responsible for test data loading to ELK via UTF, and for the pdf generator tool.
