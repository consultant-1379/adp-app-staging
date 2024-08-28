# Upgrading ELK

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

When a new version is available for download on the [official page](https://www.elastic.co/downloads/), consider upgrading the stack.

## Download the appropriate rpms

+ Elastic:

```
elasticsearch-<elasticsearch_version>-x86_64.rpm
```

+ Logstash:

```
logstash-<logstash_version>.rpm
```

+ Kibana:

```
kibana-<kibana_version>-x86_64.rpm
```

## Deploy the downloaded packages to the artifactory

url: <https://arm.seli.gic.ericsson.se>
repo: proj-cea-external-local
path:

+ Elastic:

```
/ci/3pp/elasticsearch/<elasticsearch_version>/elasticsearch-<elasticsearch_version>-x86_64.rpm
```

+ Kibana:

```
/ci/3pp/kibana/<kibana_version>/kibana-<kibana_version>-x86_64.rpm
```

+ Logstash:

```
/ci/3pp/logstash/<logstash_version>/logstash-<logstash_version>.rpm
```

## Update the ansible playbook

Edit the file in the adp-app-staging repository: /ansible/roles/elk/defaults/main.yml
Update the logstash, kibana and elasticsearch version numbers to the new one.

## Upgrade the ELK stack

Run the ansible playbook named 'elk' according to the Ansible usage document in [**confluence**](https://eteamspace.internal.ericsson.com/display/ECISE/Ansible+usage+in+Product+CI) or in [**gitiles**](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/ansible/ansible-usage.md)
