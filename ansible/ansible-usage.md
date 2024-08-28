# Ansible usage in Product CI

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Technical details of Ansible server

Ansible server in CI environment: seliics03093e01.seli.gic.ericsson.se

Ansible playbooks in **adp-app-staging** repo are in ansible/ dir.

* Create a folder (maybe with your signum as name) under the /home/eceabuild folder. Switch to the newly created folder.
* Checkout the latest version of Ansible playbooks with the following command:

```
git archive --remote=ssh://eceagit@gerritmirror-ha.lmera.ericsson.se:29418/EEA/adp-app-staging HEAD:ansible | tar -x
```

* Note: /root/.vault_pass.txt shall contain the usual E\*\*\*1 password.

* Any change you make to the playbook here can be tried on the ansible controller, but when you are finished, make a commit of the changes and push it to master.

## Product CI Reinstall Jenkins Build nodes

* Detailed documentation about installing Jenkins Build nodes can be found [here](https://eteamspace.internal.ericsson.com/display/ECISE/EEA4+Product+CI+Reinstall+Jenkins+Build+nodes+hosted+in+VMware+Vcloud)

## ELK stack deployment

To deploy a single-node ELK cluster without TLS or authentication in place:

* Run the following command:

```
ansible-playbook elk.yml -i elk.ini --vault-password-file=~/.vault_pass.txt --limit=[your host fqdn]
```

To secure this single-node ELK cluster:

* Run the following command:

```
ansible-playbook playbooks/elk_hardening/harden.yml -i elk.ini --vault-password-file=~/.vault_pass.txt --limit=[your host fqdn]
```

## KaaS worker node configuration

To configure alerting and access:

* Run the following command:

```
ansible-playbook kaas-workers.yml -i kaas.ini --vault-password-file=~/.vault_pass.txt --limit=[your host fqdn]
```

## NFS server configuration

To create and configure NFS server and exports:

* Edit the file `roles/nfs-server/vars/main.yml`
* Run the following command:

```
ansible-playbook nfs.yml -i elk.ini --vault-password-file=~/.vault_pass.txt --limit=[your host fqdn]
```

## Monitor the physical state of the hardware

CPU, memory, disk latency, network link usage monitoring will be available after a day run - on the [Zabbix server](http://dl380x4226e01.seli.gic.ericsson.se/zabbix/zabbix.php?action=dashboard.list)
