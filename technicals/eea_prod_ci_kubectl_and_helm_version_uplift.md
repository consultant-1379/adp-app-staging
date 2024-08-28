# Uplift Kubectl and helm versions in Product CI repos

## Background

According to the [CCD new version testing documentation](https://eteamspace.internal.ericsson.com/display/ECISE/Test+new+version+of+CCD+pipeline), Helm-, Kubectl-, and kubernetes python package versions used in Product CI should be inline with the ones set in the CCD version. To be able to follow these versions in any repositories/images/etc, it was necessary to introduce a general update mechanism that can easily be adapted to any arbitrary use cases (eg: ansible files, docker files, etc.).

## eea-prod-ci-kubectl-and-helm-version-uplift job

[eea-prod-ci-kubectl-and-helm-version-uplift](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-prod-ci-kubectl-and-helm-version-uplift/) job aims to solve this task.
The job can update the Helm-, Kubectl-, and python kubernetes package versions - and if more than one helm/kubectl versions are tracked, the list of helm/kubectl versions - in any arbitrary yaml files. The job iterates over the preconfigured repositories and updates the necessary fields with the new versions provided as input parameters.

To be able to utilize this job to uplift versions in any arbitrary repos, the only prerequisite is that the repo should store the corresponding versions in a yaml file. Addig new repositories can be configured with a new record in the [kubectl_helm_uplift.json](https://gerrit.ericsson.se/plugins/gitiles/EEA/eea4-ci-config/+/master/config/kubectl_helm_uplift.json) file in the eea4-ci-config repository.

### Configuration file

[kubectl_helm_uplift.json](https://gerrit.ericsson.se/plugins/gitiles/EEA/eea4-ci-config/+/master/config/kubectl_helm_uplift.json) in the eea4-ci-config repository is used for configuring the eea-prod-ci-kubectl-and-helm-version-uplift job.

```
{ "projects":
    [
        {
            "repo": "EEA/eea4-prod-ci-helper",
            "file_path": "bob-rulesets/ruleset2.0.yaml",
            "properties": {
                "kubectl_default_version": ".properties[] | select(.kubectl-default-version) | .kubectl-default-version",
                "helm_default_version": ".properties[] | select(.helm-default-version) | .helm-default-version",
                "kubectl_versions": ".properties[] | select(.kubectl_versions) | .kubectl_versions",
                "helm_versions": ".properties[] | select(.helm_versions) | .helm_versions"
            },
            "notification_email": "517d5a14.ericsson.onmicrosoft.com@emea.teams.ms",
            "merge": true
        },
        {
            "repo": "EEA/adp-app-staging",
            "file_path": "ansible/roles/jenkins_slave/vars/versions.yml",
            "properties": {
                "helm_default_version": ".helm_version",
                "python_kubernetes_version": ".python_kubernetes_version"
            },
            "notification_email": "517d5a14.ericsson.onmicrosoft.com@emea.teams.ms"
        }
    ]
}
```

For any project (repo) to be handled by the uplift job, the followings are **mandatory** be specified:

* `repo` - gerrit repo
* `file_path` - the yaml file where helm/kubectl versions are stored for the project
* `properties` - here we can specify which keys/values should be tracked and updated for this particular repository. As all repositories might store their helm, kubect, etc.. versions under different variable names in their yaml files, for every version type a **yq path specifies** where to find that particular value which needs to be updated in the yaml file.
Possible keys (only 1 per repository is mandatory):
  * `kubectl_default_version` - yq path to the Kubectl version used by this project (if more than one kubectl versions used, this is the default)
  * `helm_default_version` - yq path to the Helm version used by this project (if more than one helm versions used, this is the default)
  * `kubectl_versions` - yq path to a list of the kubectl versions used for this project (eg: "1.17.3 1.21.1 1.25.3")
  * `helm_versions` - yq path to a list of the the helm versions used for this project (eg: "3.2.4 3.4.2 3.5.2 3.6.2 3.8.1 3.9.3 3.10.3 3.11.3")
  * `python_kubernetes_version` - yq path to the version of the python3 kubernetes package

The yq query for each key must be formed so that it returns the current *value* of the key/value pair to be updated, without the "v" prefix, eg:

`.properties[] | select(.kubectl-default-version) | .kubectl-default-version`

when run with yq should return:

```
efikgyo@elx720903xs:~$ yq eval '.properties[] | select(.kubectl-default-version) | .kubectl-default-version' bob-rulesets/ruleset2.0.yaml

# output:
1.28.6
```

Non-mandatory fields:

* notification_email: If given, after a successful or failed uplift, the job sends notification to this address. (When the repo was skipped - eg. was already up-to-date -, no notification is sent.)
* merge (default: false): If given, merges commit with `--verified +1 --code-review +2 --submit`. NOT RECOMMENDED - as this skips validations.

The schema for this json file can be found [here](https://gerrit.ericsson.se/plugins/gitiles/EEA/eea4-ci-config/+/master/schema/kubectl_helm_uplift.schema.json). The [eea-ci-config-precodereview](https://seliius27190.seli.gic.ericsson.se:8443/job/eea-ci-config-precodereview/) job validates changes in this file against the schema.

### Parameters

* `KUBECTL_VERSION` - update files with this kubectl version
* `HELM_VERSION` - update files with this helm version
* `PYTHON_KUBERNETES_VERSION` - update files with this python kubernetes package version
* `DUMMY_RUN` - replace the values in files, but skip commit/push/notification email
* `CONFIG_REFSPEC` - FOR TESTING - use a specific refspec of the eea4-ci-config repository for configuring the job

### Stages

* `Params DryRun check`
* `Get params` - logs params
* `Initial cleanup`
* `Checkout config` - checks out eea4-ci-config repo for configuring the job
* `Read uplift config` - Reads `kubectl_helm_uplift.json`. This file tells the job which repos (and which values in which files) to update.
* `Process repos` - iterates over the projects found in kubectl_helm_uplift.json, and updates the versions (which were configured in the config file)
  * if no update was needed (version already the highest) or DUMMY_RUN is true, skips the commit/push, otherwise creates a commit, which needs to be reviewed by repo admins
  * if "merge": true was specified in the config, automatically merges the commit
  * as a per repo post action, if DUMMY_RUN is false and notification_email was given in config, and the uplift succeeded or failed, sends a notification email to the configured email address.
* `Post` - cleans up workspace

## Further improvements

**TODO** In the future this job should be automatically triggered whenever a kubectl/helm version change happens in the CCD.
