# Credentials update

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Purpose

The job is designed for teams that use the CI team cluster. Using this job, teams can update credentials with the type "Secret file" without the help of CI team members.

## Parameters

1. `MASTER_IP` - the parameter is used to specify the Virtual IP address of the master node from which the job will get kubeconfig
1. `CREDENTIAL_ID` - the parameter is used to specify the credential ID from the Global Credentials page that needs to be updated
    > The choices for this parameter are generated using the Active Choice Parameters plugin. Only credentials with type "Secret file" are listed here.
1. `JENKINS_CREDENTIAL` - when true, 'kubernetes-admin' credential (`client-*-data:`) in kubeconfig is replaced with 'jenkins' token (this is used by 'cluster-reinstall' job)

## Credentials update restrictions

To restrict the ability to update credentials, a check was created for the user who started the job.

The users can only update the selected credentials if they are a member of one of the Gerrit groups added in the credential description.

Each of the credentials belongs to a team. Each team has its own group in Gerrit.
In the description of the credential, we must indicate the name of the Gerrit group, whose members can update the credential.

So, the CI team once adds the Gerrit group to the description of the credential, and then the teams will be able to control the members who are allowed access to update their credentials

Gerrit groups can be found at [this link](https://gerrit.ericsson.se/#/admin/groups/)

## Steps

1. Check if verify parameters required

    * If the credential update and it's upstream jobs started by cron trigger (user='timer') and the uptream job is one of 'cluster-reinstall' or 'rv-helm-configuration-upgrade-test-job' then parameter verification is not required. Because the user for checking real persmissons are not available in these cases.

1. Verify parameters
    * Executed depending on the previous stage result
    * Check if a credential has a description
    * IP address format check
    * Check if the user running the job is a member of one of the Gerrit groups specified in the description of the credential

1. Get kubeconfig from the master

    * Get a kubeconfig from the master node
    * Update `nodelocal-api.eccd.local` (default server address after CCD install) with MASTER_IP parameter
    * Replace 'kubernetes-admin' credential with 'jenkin' token if JENKINS_CREDENTIAL parameter is true

1. Update credentials

    * Read and encode kubeconfig from the previous step
    * Update credential with new kubeconfig file
