# EEA Jenkins backup

## Description

eea_jenkins_backup.sh script is used to create Jenkins home folder file system backup. Since jenkins home folder
might be huge, some folders are excluded from backup.
The Script is configured to exclude the following folders:

* "${JENKINS_HOME_DIR}/workspace"
* "${JENKINS_HOME_DIR}/fingerprints"
* archive (from jobs folder)
* htmlreports (from jobs folder)

Backups is stored in the folder defined with JENKINS_HOME_DIR_BACKUP parameter.
The backup file has the following format:

```bash
jenkins.home.local_jenkins-home.<date>_<time>.tar.bz2
```

Script is using the following variables defined in /proj/cea/tools/environments/env-$HOST/setup-env.sh script:

* JENKINS_HOME
* DEV_HOME

This is proposed configuration for Jenkins master:

* script folder: /proj/cea/tools/environments/env-seliius27113
* backup folder: /proj/cea/tools/environments/env-seliius27113/jenkins/backup

### Usage

```bash
/proj/cea/tools/environments/env-seliius27113/jenkins/eea_jenkins_backup.sh --host <host>
```

### Example for Jenkins master

```bash
/proj/cea/tools/environments/env-seliius27113/jenkins/eea_jenkins_backup.sh --host seliius27113
```

## Configuration parameters

* Parameter name: BACKUP_FILES_KEEP_NUMBER
* Description: Number of backups that will be kept
* Proposed value: 7

* Parameter name: DEBUG
* Description: Is debug mode enabled, 0 - disabled 1 -enabled
* Proposed value: 0

* Parameter name: LOG_ENABLED
* Description: Is logging enabled, 0 - disabled 1 -enabled
* Proposed value: 1

* Parameter name: LOG_FILE_SIZE_BYTES
* Description: Log file size in bytes
* Proposed value: 10485760

* Parameter name: LOG_FILE_NUMBERS
* Description: number of log files
* Proposed value: 5

* Parameter name: JENKINS_HOME_DIR_EXCLUDE
* Description: folders excluded from backup
* Proposed value: "${JENKINS_HOME_DIR}/workspace"
                  "${JENKINS_HOME_DIR}/fingerprints"

* Parameter name: JENKINS_HOME_DIR_BACKUP
* Description: folder where backup file is stored
* Proposed value: ${DEV_HOME}/jenkins/backup

## Crontab

The script is scheduled to run every day except Sunday, at 2 AM

```bash
0 2 * * 1-6 /proj/cea/tools/environments/env-$HOSTNAME/jenkins/eea_jenkins_backup.sh --host $HOSTNAME > /proj/cea/tools/environments/env-$HOSTNAME/jenkins/jenkins.dump.log 2>&1
```

## Restore

To restore data from backup unpack backup file to desired folder. Use command like this one:

```bash
tar xjf jenkins.home.local_jenkins-home.<date>_<time>.tar.bz2 -C <folder_for_restore>
```

Once when command is finished (takes cca 2 hours ) copy corrupted files and folders to jenkins folder.
If it is required whole jenkins folder can be replaced with data from backup.
