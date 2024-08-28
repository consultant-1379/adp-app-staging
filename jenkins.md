# EEA 4 Product CI Jenkins and Test-Jenkins

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## EEA 4 product CI Jenkins and Test-Jenkins

+ Access Jenkins at the following link: <https://seliius27190.seli.gic.ericsson.se:8443/>
+ Permissions for users are limited to avoid accidental crashes and version mismatches, with the following rights:
  + Job create, configure
  + Every right authenticated users have
+ Authenticated users can:
  + Overall : Read
  + Credentials : View
  + Build Failure Analyzer : Update Causes
  + Agent : Build, Disconnect
  + Job : Build, Cancel, Read, Workspace
  + Run : Update
  + View : Read
  + Lockable Resources : View
+ Permissions for the EEA4 Product CI team:
  + Overall : Administer
+ Access Test-Jenkins at the following link: <https://seliius27102.seli.gic.ericsson.se:8443/>

## CI config files

+ NFS is accessible from the jenkins build nodes at ```/data/nfs/productci``` directory
+ Default CI config file is placed in adp-app-staging repository under /technicals folder, names ci_config_default, this will be loaded in Jenkins Pipelines
  + Usage:
    + config files should look like ```PROPERTY=VALUE``` , because these will be used by jenkins as environment variables
    + variables defined in both will be used from the custom, since that will be loaded later, overwriting values from the default config
+ Location of the config.xml for all-jobs-seed and all-jobs-seed-shared-lib: [EEA/adp-app-staging](https://gerrit.ericsson.se/#/admin/projects/EEA/adp-app-staging) repo, PATH: [config_all_seed_jobs/](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/config_all_seed_jobs/)
  + The content of [config_all_seed_jobs](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/config_all_seed_jobs/) must be synced with Test-Jenkins (seliius27102)
    + [all_jobs_seed_config.xml](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/config_all_seed_jobs/all_jobs_seed_config.xml) --> seliius27102:/local/jenkins-home/jobs/all-jobs-seed/config.xml
    + [all_jobs_seed_shared_lib__config.xml](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/config_all_seed_jobs/all_jobs_seed_shared_lib__config.xml) --> seliius27102:/local/jenkins-home/jobs/all-jobs-seed-shared-lib/config.xml

## Backup and restore Jenkins

Backup and restore works the same way on both Jenkins and the script  is in the same place:
```/proj/cea/tools/environments/env-<server-name>/jenkins/eea_jenkins_backup.sh```

**JENKINS_HOME** and **DEV_HOME** enviroment variables makes the difference
These are set up by setup_env.sh script.
Documentation details: [eea_jenkins_backup.md](eea_jenkins_backup.md)

### Backup

Backup is created every Monday at 02:00.

+ JENKINS_HOME:```/local/jenkins-home/```
+ DEV_HOME:```/proj/cea/tools/environments/env-<server-name>```

Location of the backup:
```proj/cea/tools/environments/env-<server-name>/jenkins/backup/```

Backup script in SCM: ```https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/technicals/shellscripts/eea_jenkins_backup.sh```

#### Implementation

Following lines are added to crontab:

```
0 2 * * 1 /proj/cea/tools/environments/env-$HOSTNAME/jenkins/eea_jenkins_backup.sh --host $HOSTNAME > /proj/cea/tools/environments/env-$HOSTNAME/jenkins/jenkins.dump.log 2>&1
```

Excluded folders or files from the backup:

```
/workspace
/fingerprints
```

### Restore

From daily save restore:

```
tar xjf jenkins.home.local_jenkins-home.<date>_<time>.tar.bz2 -C <folder_for_restore>
```

## Automatic cleanup of unused docker containers and images from slaves

There is a Jenkins pipeline which is scheduled to run hourly (at a randomized minute value), which collects all Jenkins slaves with the label 'productci' and deletes containers and images that are more than 48 hours old and not used by other containers. The commands this process uses are:

```
ssh eceabuild@<slave> docker container prune --filter until=48h --force
ssh eceabuild@<slave> docker image prune -a --filter until=48h --force
```

More information at [official docker documentation](https://docs.docker.com/config/pruning/).
