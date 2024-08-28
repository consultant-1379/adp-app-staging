# RV weekly validation tagging and dashboard

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Jenkins jobs

To be able to see the RV weekly loops on [Application Dashboard](https://eteamspace.internal.ericsson.com/display/ECISE/Application+Dashboard+in+Product+CI) we need created Jenkins jobs to start and finish the execution
These jobs also can do other things needed like creating or moving git tag.

### Start execution

 '[rv-weekly-verification-start](https://seliius27190.seli.gic.ericsson.se:8443/job/rv-weekly-verification-start/)' can be triggered manually to start execution and create new weekly tag and move latest weekly tag

Parameters:

+ CHART_NAME: Chart name e.g.:eric-eea-int-helm-chart Default value: eric-eea-int-helm-chart
+ CHART_REPO: Chart repo e.g.: <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/> Default value: <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/>
+ CHART_VERSION: Chart version e.g.: 1.0.0-1
+ WEEKLY_DROP_TAG: weekly drop e.g. weekly_drop_2023_w7
+ WEEKLY_DROP_TAG_MSG: comment for git tag
+ TAG_LATEST: move latest_weekly_drop tag Default value: true

### Finish execution

 '[rv-weekly-verification-stop](https://seliius27190.seli.gic.ericsson.se:8443/job/rv-weekly-verification-stop/)' can be triggered manually to finish execution and set the result

Parameters:

+ CHART_NAME: Chart name e.g.:eric-eea-int-helm-chart Default value: eric-eea-int-helm-chart
+ CHART_REPO: Chart repo e.g.: <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/> Default value: <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm/>
+ CHART_VERSION: Chart version e.g.: 1.0.0-1
+ WEEKLY_DROP_TAG: weekly drop what is need to be closed e.g. weekly_drop_2023_w7
+ RESULT: weekly drop test result Choises: PASSED or FAILED Default value: PASSED
