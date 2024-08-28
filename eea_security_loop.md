# Information about eea_security_loop in Product CI

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## 1. Description

Purpose of EEA Security Loop is to run offline or security test after a new microservice reached the product baseline
The loop time triggered daily at midnight  or can be start manually

## 2. Jenkins Jobs

### 2.1 The Security Loop

+ Name : eea-security-loop-test
+ Trigger : @midnight every night or manually
+ Parameters :
  + INT_CHART_NAME description: 'The Product CI Chart Name', defaultValue: 'eric-eea-int-helm-chart'
  + INT_CHART_REPO, description: 'Repo of the chart ', defaultValue: <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm>
  + INT_CHART_VERSION, description: 'The Product CI version want to deploy', defaultValue: 'latest'
+ Files
  + <https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/jobs/eea_security_loop/eea_security_loop_test.groovy>
  + <https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/pipelines/eea_security_loop/eea_security_loop_test.Jenkinsfile>
+ [Used test data in validation](https://eteamspace.internal.ericsson.com/display/ECISE/Common+EEA4+CI+data+loading)
+ Stages:
  + Params DryRun check
  + Checkout product repo
  + Prepare bob
  + Init latest product version of eric-eea-int-helm-chart  : If the version parameter equals 'latest',  we use the version number from the product repo's Chart.yaml
  + Resource locking - utf deploy and Product Install : a resource with 'rv-CL411' will be locked
  + log lock : print out the locked resource name
  + init vars : init the repositories.yaml from Jenkins Credentials
  + UTF and data loader deploy : call eea-product-ci-meta-baseline-loop-utf-and-data-loader-deploy job to deploy on the locked cluster
  + Product Install : istall crd-s and the product on the clsuter
  + Offline UTF Test : runs UTF tests with meta-filter: 'groovy:offline'
  + Decisive Nx1 ADP UTF Test : run UTF tests with meta-filter : 'groovy:decisive&&nx1&&adp&&!tc_under_development'
  + Decisive Batch ADP UTF Test : run UTF tests with meta-filter : 'groovy:decisive&&slow&&adp&&!tc_under_development'
  + Decisive Nx1 Staging UTF Test : run UTF tests with meta-filter : 'groovy:decisive&&nx1&&staging&&!tc_under_development'
q
  + Decisive Batch Staging UTF Test : run UTF tests with meta-filter : 'groovy:decisive&&slow&&staging&&!tc_under_development'
  + NonDecisive Nx1 ADP UTF Test : run UTF tests with meta-filter : 'groovy:non_decisive&&nx1&&adp&&!tc_under_development'
  + NonDecisive Batch ADP UTF Test : run UTF tests with meta-filter : 'groovy:non_decisive&&slow&&adp&&!tc_under_development'
  + NonDecisive Nx1 Staging UTF Test : run UTF tests with meta-filter : 'groovy:non_decisive&&nx1&&staging&&!tc_under_development'
  + NonDecisive Batch Staging UTF Test : run UTF tests with meta-filter : 'groovy:non_decisive&&slow&&staging&&!tc_under_development'
  + Under Development UTF Test: run UTF tests with meta-filter : 'groovy:tc_under_development'

### 2.2 The seed

+ Name: eea-security-loop-seed-job
+ Trigger: Change merge on jobs/eea_security_loop
+ Files:
  + <https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/technicals/eea_security_loop_seed.groovy>
  + <https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/technicals/eea_security_loop_seed.Jenkinsfile>
