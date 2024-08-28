# Jenkins views in Product CI

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Changing the Jenkins view structure

When a change is needed in the Jenkins view structure, edit the [./create_views.groovy](./create_views.groovy) file.
For every view, a new "categorizedJobsView" block must be created. For particular sections, please refer to the [https://jenkinsci.github.io/job-dsl-plugin/#path/categorizedJobsView](JobDSL categorizedJobsView) documentation. The jobs can be added by using a regex.
For every view, name it as "Something View", to exclude it from the groovy content check
