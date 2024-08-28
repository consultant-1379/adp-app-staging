# Update refresh tokens job

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Jenkins job

[update-refresh-token](https://seliius27190.seli.gic.ericsson.se:8443/job/update-refresh-token/) is to refresh and store different type (for now mimer, in the future scas and possibly others) of authentication tokens as jenkins credentials in both Prod- and Test- Jenkins master nodes.

### Trigger

```
triggers { cron('0 0 1 * *') }
```

The job runs scheduled both on test and master jenkins on the first day of every month.

**TODO**: When this job gets updated with the scas token implementation, a wrapper job with cron trigger should be created, which will start this job with the proper parameters for each tokens.

### Parameters

* **JENKINS_CREDENTIAL**: choice parameter - the jenkins credential to update. Current options: `['eea-mimer-user-token', 'scasuser-token']`
  * **TODO**: scas token flow is not implemented yet, if the job is started with the script raises Not iplemented error.

### Steps

* Params DryRun check
* Set build description
* Refresh Token
* Update credentials

  > If params.JENKINS_CREDENTIAL == `eea-mimer-user-token`, the `mimer-token-production` credential will be updated with the same value, which was used for the `eea-mimer-user-token`

* Post
  * cleanWs()
