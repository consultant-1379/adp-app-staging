# Spinnaker Report

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Purpose

The spinnaker-report job provides failure rates for each stage in certain Product CI loops in Spinnaker, and also calculates the average loop length for successful executions.

## Explanation

The querying of Spinnaker is done via Spin CLI, which is a command-line tool that is deployed on Product CI Jenkins slaves already. This produces the information in JSON, which is then processed in the Groovy code of the job further, and only the necessary information is extracted.
The job then iterates over a set of Spinnaker pipelines (hardcoded in the job) and creates a table from each pipeline execution list.
The report format is html, and saved as an artifact.
