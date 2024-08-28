# Triggering tenable security scan on RV cluster

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Description

Jenkins pipeline eea-tenable-test runs RV Tenable.Sc tests. The Jenkins job result SUCCESS, if the scan successfully triggered,  and the generated reports saved.

EEA_RV_Security (<PDLEEARVSE@pdl.internal.ericsson.com>) should be notified via email of the result.
Reports uploaded to <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-reports-generic-local/eea4/>

## Jenkins job

Job name: eea-tenable-test

Trigger : @midnight every night or manually

Parameters :

* INT_CHART_NAME description: 'The Product CI Chart Name', defaultValue: 'eric-eea-int-helm-chart'
* INT_CHART_REPO, description: 'Repo of the chart ', defaultValue: <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-helm>
* INT_CHART_VERSION, description: 'The Product CI version want to deploy', defaultValue: 'latest'
* NESSUS_NAME description:'The name of the scan' defaultValue: 'eea4_tenable_scan'
* NESSUS_POLICY description:'This policy will be used' defaultValue: 'EEA4_advanced'
* NESSUS_TARGET_COLLECT: description:'List of the microservices, to be scanned separated by |' defaultValue: 'eric-eea-fm-eric-data-message-bus-kf|kvdb-ag-locator|eric-data-message-bus-kf|schema-registry'

Job stages:

* Checkout SCM
* Params DryRun check
* Checkout product repo
* Prepare bob
* Checkout inv_test - to get the product install custom yaml file : inv_test/eea4/cluster_inventories/custom_values_4.0.yml
* Checkout technicals - to get technicals/pythonscripts/nessus.py and technicals/nessus-sc.conf
* Checkout tenable  - to get adp-test-java/src/main/resources/nessus-custom-repo-structure.conf
* Init latest product version of eric-eea-int-helm-chart - if the version parameter equals 'lates' the job will parse the version from the Chart.yaml
* Resource locking - utf deploy and Product Install - label 'rv-CL411'
* log lock - prints out the locked cluster
* init vars
* UTF and data loader deploy - the latest from the meta baseline
* Product Install - it will install what given in version parameter
* Trigger tenable - run nessus.py
* Post stage - upload report to <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-reports-generic-local/eea4/> and send result in email

<https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/pipelines/eea_security_loop/eea_tenable_test.Jenkinsfile>
<https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/jobs/eea_security_loop/eea_security_loop_test.groovy>

## Triggering tenable

The Tenable.sc install and scan triggering documentation: <https://confluence.lmera.ericsson.se/display/ACD/Tenable.sc+scanning>

The downloaded nessus.py and nessus-sc.conf from adp-cicd/adp-test repository needs further configuration and bug-fixes, thats why the proper files saved to under adp-app-staging/technicals and the job use them from there.

Parameters:

* '-t', '--target', help='Target IP (SUT Pod IP)', required=True) - we collect it with a bob rule collect-nessus-target
* '-n', '--name', help='SUT name', required=True) - params.NESSUS_NAME
* '-v', '--version', help='SUT version', required=True) - env.INT_CHART_VERSION
* '-arm', '--artifactory', help='Artfactory Manager Server', required=True) - arm.seli.gic.ericsson.se/artifactory/proj-eea-reports-generic-local
* '-at', '--armtoken', help='Artfactory Manager Token', required=True) - not used
* '-p', '--policy', default='ADP_NESSUS_POLICY', help='Scan Policy, prerequisite on the Tenable.sc') - params.NESSUS_POLICY
* '-c', '--configfile', default='nessus.conf', help='Configuration file') - nessus-sc.conf downloaded from adp-app-staging/technicals
* '-o', '--outputdir', default='/proj/adpci/results/nessus/reports', help='Output Dirctory for Scanning Results') - /home/eceabuild/seliius27190/nessus_scan_reports/\<cluster\>
* '-su', '--skipupload', help='Skip upload of scan reports to Artifactory', action='store_true')
* '-pnum', '--productnumber', default='ADP123456', help='Number from PRIM structure, e.g. the FGM for commercial offerings.') - parsed from product helm values.yaml
* '-pn', '--productname', default='Application Development Platform', help='The full product name, same as "Functional Designation" in PRIM, e.g. the name that is commonly recognized.') - parsed from product helm values.yaml
* '-sd', '--serverdetails', help='Scan server details', required=True) - Jenkins file credential: 'tenablesc-secrets'
* '-tsc', '--tenablesc', action='store_true')

### collect-nessus-target bob rule

in cnint ruleset2.0.yaml where NESSUS_TARGET_COLLECT incoming parameter of the job

```
  collect-nessus-target:
    - task: collect
      docker-image: k8-test
      docker-flags:
        - "--env KUBECONFIG=${env.KUBECONFIG}"
        - "--volume ${env.KUBECONFIG}:${env.KUBECONFIG}:ro"
      cmd:
        - "kubectl get pods -n eric-eea-ns -o wide | grep 'Running' | egrep -v '${env.NESSUS_TARGET_COLLECT}' | awk '{print $3 \"\t\" $6}' | awk '{print $2}' | sort | tr '\n' ',' > nessus_targets.txt ; cat nessus_targets.txt"
```

## build node configuration

### filebeat configuration

Filebeat config file should be renamed from filebeat.yaml to filebeat
Important!
This config uses not the default port '5044', but '5041' !

```
# ============================== Filebeat inputs ===============================

filebeat.inputs:

# Each - is an input. Most options can be set at the input level, so
# you can use different inputs for various configurations.
# Below are the input specific configurations.

- type: log

  # Change to true to enable this input configuration.
  enabled: true
  paths:
    - /home/eceabuild/seliius27190/nessus_scan_reports/rv-CL411/eea4_tenable_scan/*.csv
  exclude_lines: ['^"Plugin","Plugin Name".*']
  fields:
    cluster_name: rv-CL411
    log_tag: TENABLE_RIPORT_CSV
    fields_under_root: true


# ------------------------------ Logstash Output -------------------------------
output.logstash:
  # The Logstash hosts
  #hosts: ["localhost:5044"]
  #hosts: ["10.223.227.26:5044"]
  hosts: ["10.61.197.98:5041"]
  # Optional SSL. By default is off.
  # List of root certificates for HTTPS server verifications
  #ssl.certificate_authorities: ["/etc/pki/root/ca.pem"]

  # Certificate for SSL client authentication
  #ssl.certificate: "/etc/pki/client/cert.pem"

  # Client Certificate Key
  #ssl.key: "/etc/pki/client/cert.key"
```

### logstash configuration

Since, one filebeat already were configured with ssl on the central logstash so we configured this filebeat to new prt, not the default.

Config file: /etc/logstash/conf.d/beats_to_elastic_nossl.conf

```
input {
  beats {
    port => 5041
  }
}

filter {
  if [fields][log_tag] == "TENABLE_RIPORT_CSV" {
    grok {
      keep_empty_captures => true
      match => { "message" => ["(\"%{NUMBER:Plugin}\",\"%{DATA:PluginName}\",\"%{DATA:Family}\",\"%{DATA:Severity}\",\"(?<VPR>()|(%{NUMBER}))\",\"%{DATA:IP Address}\",\"(?<NetBIOSName>()|(%{DATA}))\",\"%{DATA:DNSName}\",\"(?<MACAddress>()|(%{DATA}))\",\"(?<AgentID>()|(%{DATA}))\",\"%{DATA:Repository}\")"]
      }
    }
  }
}


output {
  if [fields][log_tag] == "TENABLE_RIPORT_CSV" {
    elasticsearch {
      hosts => ["https://seliics00309.ete.ka.sw.ericsson.se:9200", "https://seliics00310.ete.ka.sw.ericsson.se:9200", "https://seliics00311.ete.ka.sw.ericsson.se:9200"]
      cacert => "/etc/logstash/tls/certs/ca-bundle-ericsson-internal.crt"
      user => "logstash_writer"
      password => "ssXeICh3Z5WxcrKh"
      index => "rv-security-tenable-riport-%{+YYYY.MM.dd}"
    }
  }
  file { path => "/data/logstash/logs/logstash-to-file.log" }
  stdout { codec => rubydebug }
}
```
