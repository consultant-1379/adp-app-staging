# Jira Component Validator

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Purpose

This job was created to validate all Jira components and send notifications to ScM community (EEA Scrum - ETH Scrum masters <PDLASCRUME@pdl.internal.ericsson.com>) in case of errors

*Note* More information can be found [here](https://gerrit.ericsson.se/plugins/gitiles/EEA/eea4-bbt/+/master/helper_scripts/scripts/jira_component_validator/README.md)

Jenkins job: [jira-component-validator](https://seliius27190.seli.gic.ericsson.se:8443/job/jira-component-validator)

## Triggers

The Jira Component Validator jobs is run automatically by Jenkins crontab from Monday to Friday at 4 am

## Steps

1. Checkout adp-app-staging

    Checks out the adp-app-staging repository from master branch

2. Run Jira component validator

    Execute a run-jira-component-validator bob-rule from the ruleset2.0.yaml ruleset (this rule calls a jira_component_validator/app.py script from AS-toolbox with --verbose option)
    Also, there is generated a jira_component_validator.log logfile to observe components with error status. If components with errors exist, a notification email will be sent to Eva Varkonyi <eva.varkonyi@ericsson.com> at first
    After a preliminary verification Eva will send notification manually to Scrum community on her own

## Post steps

1. Always

    Archiving the jira_component_validator.log artifact

2. Failure

    If something fails and doesn't relate to the components itself, a notification will be sent to [Jenkins alerts](https://teams.microsoft.com/l/channel/19%3ace00451d0db54ed7bc0f985a2bb8e61e%40thread.tacv2/Jenkins%2520alerts?groupId=bc9ea19b-97da-479d-903f-9b003bcba6a4&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f) MS Teams channel to analyze by Product CI team
