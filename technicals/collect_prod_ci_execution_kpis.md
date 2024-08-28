# Product CI KPIs report

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Purpose

The [collect-prod-ci-execution-kpis](https://seliius27190.seli.gic.ericsson.se:8443/job/collect-prod-ci-execution-kpis/) and [eea-application-staging-post-activities](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-application-staging-post-activities/) Jenkins jobs collects KPIs for a given Product CI pipeline execution.
It is meant to be triggered from Spinnaker pipelines:

* [eea-staging-post-actions](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?q=post&pipeline=eea-staging-post-actions)
* [eea-staging-non-pra-post-actions](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?q=post&pipeline=eea-staging-non-pra-post-actions)
* [eea-adp-staging-post-actions](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?q=post&pipeline=eea-adp-staging-post-actions)

## Parameters collect-prod-ci-execution-kpis

* `PIPELINE_NAME` is the name of the given Spinnaker pipeline
* `PIPELINE_EXEC_ID` is the execution ID of the given Spinnaker pipeline

## Output

The following data is collected and sent to the Application Dashboard as JSON to [this](http://eea4-application-dashboard.seli.gic.ericsson.se:61616/api/v1/stages/executions/kpi) endpoint.

* pipeline name (actual execution)
* pipeline execution ID (actual execution)
* pipeline result (actual execution)
* start time (actual execution)
* end time (actual execution)
* build duration (calculated): time between the initiation and the completion of the given pipeline execution
* lead time (calculated): time between the initiation of the first parent pipeline (within 'eea' application) and the completion of the given pipeline execution
* queue length (calculated): number of NOT_STARTED executions of the given pipeline in the queue
* queue waiting time (calculated): time that oldest pipeline execution currently waits for in the queue

## Explanation

The querying of Spinnaker is done via Spin CLI, which is a command-line tool that is deployed on Product CI Jenkins slaves already. This produces the information in JSON, which is then processed in the Groovy code of the job further, and only the necessary information is extracted.
