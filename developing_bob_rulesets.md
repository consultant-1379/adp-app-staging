# Developing bob rulesetes

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Bob documentation

[USER_GUIDE_2.0](https://gerrit.ericsson.se/plugins/gitiles/adp-cicd/bob/+/master/USER_GUIDE_2.0.md)

## Teams channel

In case of issue you can ask help at the guardian team channel:
[CICD - Bob Framework and Builders](https://teams.microsoft.com/l/channel/19%3a333b862ff4e64327bf7804f945f2fe00%40thread.skype/CICD%2520-%2520Bob%2520Framework%2520and%2520Builders?groupId=f7576b61-67d8-4483-afea-3f6e754486ed&tenantId=92e84ceb-fbfd-47ab-be52-080c6b87953f)
You can also find WIKI page on the channel, where you can find how to create Jira ticket for them.

## Bob desingn rules and validations

We collected the the design rules and the process of the validation on this page:
[Product Ci Bob rulesets](https://eteamspace.internal.ericsson.com/display/ECISE/Product+CI+bob+rulesets)

## Trigger bob rule from Jenkins

### Get bob submodule

[see documentation](https://gerrit.ericsson.se/plugins/gitiles/adp-cicd/bob/+/HEAD/USER_GUIDE_2.0.md#Quick-Start)
In product CI pipelines and rulesets always use specific version, not latest, for other teams we also suggest to do so. Many times we faced, that a new bob version change was not compatible or had bugs, and broke our workflow.

Example from [CI shared lib](https://gerrit.ericsson.se/plugins/gitiles/EEA/ci_shared_libraries/+/master/src/com/ericsson/eea4/ci/GitScm.groovy#562):

```
    script.sh 'git clean -xdff'
    script.sh 'git submodule sync'
    script.sh 'git submodule update --init --recursive'
    script.sh 'git submodule foreach --recursive git pull origin '+revision
    script.sh 'bob/bob --version'
```

### How to run ruleset

See [bob documentiation](https://gerrit.ericsson.se/plugins/gitiles/adp-cicd/bob/+/HEAD/USER_GUIDE_2.0.md#Create-the-first-ruleset-file), but in Product Ci should always use
Always use -r or --ruleset option, even if the default rulesets

Examples:

```
 sh 'bob/bob -r ruleset2.0.yaml prepare-without-upload'
```

### Shell commands in bob rulesets

Example

```
 - task: enable-eric-eea-analysis-system-overview-install
      cmd:
        - sed -i '/^eric-eea-analysis-system-overview-install:/{n;s/enabled:.*/'enabled:' true/;}' helm-values/custom_deployment_values.yaml
```

If you want to run multiple commands see [documentation](https://gerrit.ericsson.se/plugins/gitiles/adp-cicd/bob/+/HEAD/USER_GUIDE_2.0.md#Running-a-sequence-of-commands-in-a-container), but for more than 3 shell commands, external .sh script file should be used.

Examples:

```
cmd:
  - >
    /bin/bash -c '''
      if [ $(kubectl get httpproxies.projectcontour.io -n ${env.K8_NAMESPACE} eric-pm-server-ingress-httpproxy -ojsonpath='{.spec.virtualhost.fqdn}') ]; then
          kubectl get httpproxies.projectcontour.io -n ${env.K8_NAMESPACE} eric-pm-server-ingress-httpproxy -ojsonpath='{.spec.virtualhost.fqdn}' > .bob/var.pm-server-ingress-hostname;
      else
          echo ${dummy-fqdn} > .bob/var.pm-server-ingress-hostname;
      fi
    '''
```

```
cmd:
  - kubectl get crds -n eric-crd-ns --no-headers=true | awk '{print $1}' > crd.list
  - helm list -n eric-crd-ns -q > helm.list
  - >
    bash -c '
      while IFS= read -r chart_name; do
      echo "Uninstall Chart name: $chart_name"
      helm uninstall $chart_name  -n eric-crd-ns
      done < helm.list
    '
```

Example for escape in sed characters in ruleset sh command:

```
cmd:
        - >
          bash -c '
          kubectl -n utf-service logs eric-eea-utf-docker-${env.UTF_TEST_EXECUTION_ID} >> ${env.UTF_TEST_LOGNAME};
          DEBUG_LOGNAME=$(echo ${env.UTF_TEST_LOGNAME} | sed -e "s/\.log$/-debug.log/");
          kubectl -n utf-service describe pod eric-eea-utf-docker-${env.UTF_TEST_EXECUTION_ID} >> $DEBUG_LOGNAME;
          kubectl -n utf-service delete pod eric-eea-utf-docker-${env.UTF_TEST_EXECUTION_ID} >> $DEBUG_LOGNAME'
```

### Results of bob command

If a bob command failing, that sh step will return same status code. Any nonzero status code will cause the step to fail with an exception.
If you want to prevent the whole pipeline failing use one of the error handling methods

Examples:
Using try-cath

```
script {
    try {
        sh './bob/bob check-namespaces-not-exist > check-namespaces-not-exist.log'
    }catch (err) {
        ...
    }
}
```

or Jenkins catchError

```
stage('Load config cubes json to CM-Analytics') {
    steps {
        catchError(stageResult: 'FAILURE', buildResult: 'SUCCESS') {
            sh './bob/bob -r ruleset2.0.yaml load-cm-analytics-config-cubes-into-eea'
        }
    }
}
```

### Timeout

You can either use wrap Jenkins timeout step or timeout in shell command. Note that if you use timeout in a shell command inside of a docker image, and the image does not return, Jenkins will wait. To avoid that you should use timeout in Jenkins also.

Example in Jenkins:

```
timeout(time: 10, unit: 'HOURS') {
    sh 'bob/bob  ...'
}
```

Example in rule:

```
     cmd:
        - >-
          timeout ${env.HELM_SERVICE_UPGRADE_TIMEOUT} bash -c '''
          (set -o pipefail && helm upgrade --install
          ${helm-release-name}
          .bob/${env.INT_CHART_NAME}-internal/${helm-chart-file-name}
          --namespace=${env.NAMESPACE}
          --reset-values
          --values ${var.service-upgrade-helm-values-list}
          --debug
          --timeout=${env.HELM_TIMEOUT}s
          --wait
          --set ${var.helm-vars} 2>&1 | ts -m "%F %.T %Z"); '''
```

### Using timestamp

Bob adding timestamps to log steps, but some other tools triggered by bob don't have timestamp in their output. (helm)

In these cases you can use ts command (when the moreutils package and Time::HiRes perl module are already in the docker image). But same as in the example "set -o pipefail"  should be used or the result will always success (status 0)

Example bash command in ruleset:

```
bash -c '''
    (set -o pipefail && helm upgrade --install ${helm-release-name} .bob/${env.INT_CHART_NAME}-internal/${helm-chart-file-name}
        --namespace=${env.NAMESPACE}
        --reset-values
        --values ${var.service-upgrade-helm-values-list}
        --debug
        --timeout=${env.HELM_TIMEOUT}s
        --wait
        --set ${var.helm-vars} 2>&1 | ts -m "%F %.T %Z"); '''

```

### A way how to pass to docker image the time-zone information:

You can check like these the time-zone on your Linux environment

```
eceabuild@selieea0046:~> ls -la /etc/localtime
lrwxrwxrwx 1 root root 36 Mar 12 07:44 /etc/localtime -> /usr/share/zoneinfo/Europe/Stockholm
eceabuild@selieea0046:~> date +"%Z %z"
CET +0100
```

In this case you can mount the host localtime file to the container, which will override the container default time-zone file.
With this we can guarantee that the container time-zone will be consistent with Jenkins node time-zone.

```
    - "--volume /etc/localtime:/etc/localtime:ro"
```

One more example where you can see this in the bob rule

```
rules:
  check-pods-state-with-wait:
    - task: wait-for-pods
      docker-image: eea4-utils-ci
      docker-flags:
        - "--env KUBECONFIG=${env.KUBECONFIG}"
        - "--volume ${env.KUBECONFIG}:${env.KUBECONFIG}:ro"
        - "--volume ${env.PWD}:${env.PWD}"
        - "--volume /etc/localtime:/etc/localtime:ro"
        - "--workdir ${env.PWD}"
      cmd:
        - >-
          /local/bin/eea_healthcheck.py --namespace ${env.NAMESPACE} -r ${env.EEA_HEALTHCHECK_CHECK_CLASSES} -v --wait --timeout ${env.WAIT_FOR_PODS} --exclude-warnings;
```

### Saving the output

#### Forward into file in the sh script:

```
sh './bob/bob init dimtool-trigger > dimtool-trigger.log'
```

#### Use bob built in logging function:

If BOB_LOG_PATH variable not null, then bob will save the output to that path.
Sadly at this moment the file name couldn't be set, just the path.

Example:

```
withEnv(["BOB_LOG_PATH=validate-properties/${rulesetName}"]) {
    try {
        sh ( script: "bob/bob --ruleset ${rulesetFile} --validate-properties", returnStdout: true)
    }
    catch (err) {
        result = false
        resultStr = sh ( script: "grep -ri ERROR validate-properties/${rulesetName}/", returnStdout: true)
        sendMessageToGerrit(params.GERRIT_REFSPEC, "validate-properties failed for ${rulesetFile} with ${resultStr}")
        echo "validate-properties failed for ${rulesetFile} with ${resultStr}"
    }
}

```

[Documentation of execution logging](https://gerrit.ericsson.se/plugins/gitiles/adp-cicd/bob/+/HEAD/USER_GUIDE_2.0.md#Bob-execution-logging)

#### Using file descriptors:

[Documentation](https://gerrit.ericsson.se/plugins/gitiles/adp-cicd/bob/+/master/USER_GUIDE_2.0.md#Using-file-descriptors)

[Example](https://gerrit.ericsson.se/plugins/gitiles/adp-cicd/bob/+/master/bob2.0/test/scripts/test_file_descriptors.sh)
