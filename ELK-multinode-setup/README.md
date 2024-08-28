# ELK Multinode Setup

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Roles

These roles provided to help automate ELK installation on the clusters.
Please, remember to fill ip addreses to hosts in vars.

These roles include:

1. Elasticsearch master server configuration with empty blank
2. Elasticsearch slave servers configuration with empty blank
3. Logstash installation (servers can be chosen in vars file)
4. Kibana installation on each host with elasticsearch
5. Filebeat installation for self-monitoring nodes
6. Metricbeat installation for self-monitoring nodes
7. Host prepare with required libs and dependencies
8. ELK hardening setup

To use it ansible =>2.8 version required.
All destination host should be updated in vars file

Example: ansible-playbook elk-setup.yml -i ./inventory
Also, they can be used separately.
