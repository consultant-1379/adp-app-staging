# Jenkins upgrade procedure for EEA4 Product CI

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Updating Test Jenkins at <https://seliius27102.seli.gic.ericsson.se:8443/>

1. Please ask for a maintenance timeframe from Product CI team to update the test Jenkins.
2. Before starting the upgrade process check that the latest backup for the test Jenkins is not older than 1 day. [backup/restore procedure](https://eteamspace.internal.ericsson.com/display/ECISE/EEA+Jenkins+backup)
3. At [test Jenkins management page](https://seliius27102.seli.gic.ericsson.se:8443/manage) select the auto update of Jenkins core to the latest stable version and wait till Jenkins restarts.
4. Create a dummy change for adp-app-staging repo updating at least one jobDSL file and one Jenkinsfile for testing the pipelines. Do not update any functional parts in this commit! Example: [https://gerrit.ericsson.se/#/c/8179665/](https://gerrit.ericsson.se/#/c/8179665/)
5. Review the plugin issues listed in the Jenkins uplift ticket before proceeding with any updates or plugin! It is indicated there if a plugin version had issues and needed to be reverted. It is necessary to verify whether the earlier issues have been fixed before the upgrade.
6. Check the gerrit trigger. Add +1 by "Reply" to your commit and the functional test loop will be run automatically.
7. If the functional loop passes go to the plugin management page and select plugins to update. As there can be many it's better not to select all together, in case of error it would be easier to rollback and find the root cause with less changes.
8. After plugins are selected for update click Download and install after restart button, on the opening page select the restart option to ensure that Jenkins will restart.
9. When Jenkins is restarted repeat steps from d to f till all the plugins gets updated.
***NOTE:*** During last upgrade Jenkins to 2.401.2 version there was a problem with connectivity to Gerrit 2.14. As Gerrit required stronger algorithm for private public key pair. See [https://issues.jenkins.io/browse/JENKINS-71273](https://issues.jenkins.io/browse/JENKINS-71273). As a result a new keys pair was generated and placed on Test Jenkins. Also, were added new JAVA options in a start-jenkins.sh shell script
   > JAVA_OPTS='-Xms12g -Xmx16g -Dfile.encoding=UTF8 -Djsch.client_pubkey=ssh-ed25519,ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521,rsa-sha2-512,rsa-sha2-256,ssh-rsa -Djsch.server_host_key=ssh-ed25519,ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521,rsa-sha2-512,rsa-sha2-256,ssh-rsa'

## Deactivate main pipelines in Spinnaker before starting the Live Jenkins

To avoid problems with labelling you should disable the following pipelines in [Spinnaker](https://spinnaker.rnd.gic.ericsson.se/#/applications/eea/executions?pipeline=eea-adp-staging,eea-app-baseline-manual-flow,eea-application-dashboard-manual-flow,eea-application-dashboard-release,eea-application-dashboard-staging,eea-application-staging,eea-application-staging-non-pra,eea-application-staging-wrapper,eea-deployer-drop,eea-manual-config-testing,eea-product-ci-code-loop,eea-product-ci-code-manual-flow,eea-product-ci-meta-baseline-loop,eea4-documentation).

```
eea-adp-staging
eea-app-baseline-manual-flow
eea-application-dashboard-manual-flow
eea-application-dashboard-release
eea-application-dashboard-staging
eea-application-staging
eea-application-staging-non-pra
eea-application-staging-wrapper
eea-deployer-drop
eea-manual-config-testing
eea-product-ci-code-loop
eea-product-ci-code-manual-flow
eea-product-ci-meta-baseline-loop
eea4-documentation
```

## Updating the Live Jenkins instance (<https://seliius27190.seli.gic.ericsson.se:8443>)

1. If functional loop passes after the last plugin update schedule a timeframe with Product CI team and EEA4 CI CoP for the live Jenkins update. As new plugin versions are released quite often this shouldn't be too far from the test Jenkins update. (max 1-days…)
2. Before starting the upgrade please check the backups for live Jenkins, latest one can't be older than 1 day. [backup/restore procedure](https://eteamspace.internal.ericsson.com/display/ECISE/EEA+Jenkins+backup)
3. In the maintenance timeframe update the Jenkins core at the [live Jenkins](https://seliius27190.seli.gic.ericsson.se:8443/manage)
4. After Jenkins core update go to plugin manager and update the plugins. As it's described for the test Jenkins upgrade please do not upgrade too many plugins once, select some of them, click Download and install and restart Jenkins. When it's done continue similarly till all the plugins will be upgraded.
5. When update is done inform CI CoP via MS Teams.
6. After Live Jenkins update, update for the dockerized jenkins is  mandatory.

## Updating versions in the EEA/jenkins-docker repository

1. Run [eea-jenkins-docker-version-uplift](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-jenkins-docker-version-uplift/) Jenkins job
    > If some new plugin needs to be added to jenkins-docker, it must be selected in the PLUGINS_TO_ADD parameter before starting the build (multiple plugins can be selected)
1. After the build is completed, a new commit will be created with version changes (the commit will also be sent to the Driver channel for review)
    > During the build, the version of Jenkins in jenkins-docker:bob-rulesets/rulesets2.0.yaml will be updated to the current version of Live Jenkins. The plugins contained in jenkins-docker:docker/plugins.txt will also be updated.
1. When the commit is approved, the new version of the jenkins-docker will be validated according to the [automated validation flow](https://eteamspace.internal.ericsson.com/display/ECISE/EEA+Jenkins+Docker+in+Product+CI) for the EEA/jenkins-docker repository
1. After these changes are merged a JIRA ticket has to be opened for the CPI team to update CPI description of Jenkins requirements at EEA upgrade guide.
    > [Template ticket](https://eteamproject.internal.ericsson.com/browse/EEAEPP-95874) to be cloned.
    > Please update at the new ticket the required Jenkins version and the required Jenkins plugin list. Changes should be highlighted.
    > Sources for this:
        > [Jenkins version](https://gerrit.ericsson.se/plugins/gitiles/EEA/jenkins-docker/+/master/bob-rulesets/ruleset2.0.yaml#9)
        > [Plugin list](https://gerrit.ericsson.se/plugins/gitiles/EEA/jenkins-docker/+/master/docker/plugins.txt)
    > When ticket is ready send an email to [Gergely Halmai](mailto:gergely.halmai.ext@ericsson.com) (in CC [CPI team](mailto:PDLCEASEMC@ericsson.com)) about the new task.

## Updating all-jobs-seed content in the EEA/adp-app-staging repository

After updating plugins in the Jenkins, the stored all-jobs-seed sources also have to be updated because of the used plugin versions.
Without this step, it will not work when you have to restore all-jobs-seed from the git sources and the installed plugin versions are different from the versions stored in the config files!

You have to create a patchset where:

* content of [all-jobs-seed/config.xml](https://seliius27102.seli.gic.ericsson.se:8443/job/all-jobs-seed/config.xml) should be updated to [all_jobs_seed_config.xml](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/config_all_seed_jobs/all_jobs_seed_config.xml)
* content of [all-jobs-seed-shared-lib/config.xml](https://seliius27102.seli.gic.ericsson.se:8443/job/all-jobs-seed-shared-lib/config.xml) should be updated to [all_jobs_seed_shared_lib__config.xml](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/config_all_seed_jobs/all_jobs_seed_shared_lib__config.xml)

## Troubleshooting

1. In case of any issues during the upgrade process you can restore Jenkins from a backup following the Back and restore guide. [backup/restore procedure](https://eteamspace.internal.ericsson.com/display/ECISE/EEA+Jenkins+backup)
2. Restoring the previous Jenkins core version is possible at the GUI as well at the Manage Jenkins page.
3. Restore of the plugins is possible at the Jenkins Plugin Manager one-by-one to the previously installed version. Please do NOT restore multiple plugins during one restart!

## Good to know

1. Login into Jenkins server.Use SSH command

   ```sh
   ssh eceaproj@seliius27190.seli.gic.ericsson.se
   ```

2. Jenkins is executed by the `eceaproj` user on our Jenkins hosts. For each host, we have a dedicated script to set up the environment for Jenkins and other required tools. This is available at:

    ```sh
    /proj/cea/tools/environments/env-<host_name>
    ```

   For example:

   ```sh
   /proj/cea/tools/environments/env-seliius27190
   ```

3. To start/stop Jenkins from CLI you need to login to the host as the `eceaproj` user and execute the relevant script:

  ```sh
   /proj/cea/tools/environments/env-<host name>/jenkins/start-jenkins.sh
   /proj/cea/tools/environments/env-<host name>/jenkins/stop-jenkins.sh
  ```
