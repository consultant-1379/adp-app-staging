# EEA4 Product CI Reinstall Jenkins Build nodes hosted in VMware Vcloud

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Description

This topic is about how can you manually reinstall a Jenkins Build node used by Product CI hosted in VMware Vcloud.
The nodes and their **direct links** to the VMware Vcloud can be found on:

* WIKI Inventory Page: <https://eteamspace.internal.ericsson.com/display/ECISE/EEA4+Product+CI+Inventory#EEA4ProductCIInventory-Jenkinsbuildnodes>
* Grouped by Jenkins with label `productci`: <https://seliius27190.seli.gic.ericsson.se:8443/label/productci/>

### Disable build node from Jenkins

Before any modification on the host you have to disable the selected build node from the Jenkins:

* On the [Jenkins Nodes page](https://seliius27190.seli.gic.ericsson.se:8443/computer/) search for the host
  * e.g.: <https://seliius27190.seli.gic.ericsson.se:8443/computer/selieea0069/>
* Here you need 3 different task to do
  * Mark this node temporarily offline
    * Click on the "Mark this node temporarily offline" label, then you have to wite the reason to the text box, e.g. you can add the ticket number to there
  * Rename its label in the `Configure` menu
    * Please edit `Labels` property and rename from `productci` to `maintenance`
  * Disconnect the computer from Jenkins in the `Disconnect` menu
    * When all running jobs have been terminated on this node, you have to disconnect it
    * Please add the ticket number to the text box, because you should explain why you are taking this node offline, so that others can see why

### Backup build node's ip and default route

To restore networks configuration settings while installing OS you need to back up those data before reinstall.

### Get IP data

```bash
ip a
```

Example:

```bash
selieea0069:~ # ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:50:56:07:fa:d3 brd ff:ff:ff:ff:ff:ff
    altname enp11s0
    altname ens192
    inet 10.223.227.72/24 brd 10.223.227.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::250:56ff:fe07:fad3/64 scope link
       valid_lft forever preferred_lft forever
```

### Get DNS data

```bash
cat /etc/resolv.conf
```

Example:

```bash
selieea0069:~ # cat /etc/resolv.conf
search seli.gic.ericsson.se
nameserver 150.132.95.20
nameserver 150.132.95.40
```

#### Get routing data

```bash
ip r
```

Example:

```bash
    selieea0069:~ # ip r
    default via 10.223.227.1 dev eth0
    10.223.227.0/24 dev eth0 proto kernel scope link src 10.223.227.72
    172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1
    172.19.0.0/16 dev br-65e09558e87a proto kernel scope link src 172.19.0.1
```

## Reinstall build node in VMware Vcloud

* All build nodes are hosted in VMware Vcloud
* You can reach them via vcloud direct links stored in the [Product CI Inventory](https://eteamspace.internal.ericsson.com/display/ECISE/EEA4+Product+CI+Inventory#EEA4ProductCIInventory-Jenkinsbuildnodes) Page
* Check and set Removable Media for OS install
  * Check `Hardware -> Removable Media - CD/DVD drive`: if it has the necessary image already, it's ok.
  * Otherwise, need to `Insert Media` in the menu: `ALL ACTIONS - Meida - Insert Media`
    * `Catalog` column can be filtered for "EEA"
    * Select the required image from the list, currently the latest: `SLE-15-SP5-Full-x86_64-GM-Media1.iso`
    * If the required image is missing from the list, need to send a request to the ENV Team to upload the necessary missing image
    * If the image has more than 1 media, it can be enough to load only `media 1` of the image
* Reboot the system to install the OS from the mounted media.

### OS Install (SUSE)

* LAUNCH WEB CONSOLE
* After reboot, please choose `Install` from the Media boot menu
  * When the Vcloud host settings in `General - Boot Firmware` has the `BIOS` value, you will reach this `Install` option directly.
  * BUT When the Vcloud host settings in `General - Boot Firmware` has the `EFI` value, first you have to choose `UEFI Firmware Settings` then `EFI VMware Virtual IDE CDROM Drive` from the Boot screen and finally `Install` option
* Set `English (US)` for `Language` and `Keyboard`
* Select `SUSE Linux Enterprise Server 15 SP5` for `Product to Install`
* Setup will continue with subpages configuration

*Note* At the moment two Jenkins build nodes (selieea0045 and selieea0046) have the EFI value so the `UEFI Firmware Settings` menu item should be chosen

#### Networks settings

* The host should be the same as it is in the backup
* On the `Overwiew` tab press `Edit`
  * On the `Network Card Setup` page, `Address` tab
    * Select `Statically Assigned IP Address` item then fill in required data:
      * IP Address (e.g. `10.223.227.72`)
      * Subnet Mask (e.g. `/24`)
      * Hostname (not fqdn, e.g. `selieea0069`)
      * Then `Next`
* On the `Hostname/DNS` tab
  * fill `Static Hostname`  as previously
  * fill dns servers in `Name Server 1` and `Name Server 2` with values:
    * 150.132.95.20
    * 150.132.95.40
  * fill `Domain search` with value `seli.gic.ericsson.se`
  * Then go to the `Routing` tab
* On the `Routing` tab:
  * `Enable IPv4 Forwarding` should be unchecked
  * `Enable IPv6 Forwarding` should be unchecked
  * Add new `Routing Table` item
    * set `Gateway` (set this based on the backup values - `ip r`, e.g `10.223.227.1`
    * set `Device` (set this based on the backup values - `ip r`, e.g `eth0`
    * Then `Next`

#### Register system (RMT)

* On the `Registration` page:
  * Select `Skip Registration` item

#### Extension and Module Selection

* On the `Available Extensions and Modules` page:
  * `Hide Development Version` if present, should be unchecked (the following items appear only after the box is unchecked!!)
  * `Basesystem Module` should be checked
  * `Server Apllications Module ...` should be unchecked
  * `Containers Module ...` should be checked

#### Add On Product Installation

* Select `Next`

#### System Role

* Select `Minimal` item

#### Suggested Partitioning

* Select `Expert partitioner`
* Select `Start with Current Proposal`

* Disk requirements:
  * **sda** (for system) with at least **256GB** size or more
    * The existing build nodes can have either EFI or legacy BIOS boot type which we cannot change. Depending on the bios type the partitioning will be different.
      * BIOS: sda1 8MiB   BIOS Boot Partition   mount point: empty
      * EFI:  sda1 0.5GiB EFI System Partition  mount point: /boot/efi - filesystem: FAT
    * sda2 with at least 100GB for / (it is necessary because docker process makes files there as well, and sometimes they can be huge)
    * sda3 with at least 32GB for SWAP
    * sda4 with at least 100GB for /home (it is necessary for Jenkins workspace, it's recommended to use "Maximum Size" in the partitioner which will allocate the remaining disk space)
    * CAUTION! OS install must go to sda, because [Jenkins build node ansible playbook installer](https://eteamspace.internal.ericsson.com/display/ECISE/Ansible+usage+in+Product+CI)work only if the OS is installed to sda)
  * **sdb** with at least **512GB size** or more (docker process will put images there - on this disk an lvm volume will be created and managed *solely by docker*, no manual configuration will be needed!)
    * CAUTION! sdb must not contain any partition, ansible will create it
  * **sdc** with at least **256GB** size or more (docker process will put container volumes to there, will be mounted to /var/lib/docker/volumes)
    * CAUTION! sdc must not contain any partition, ansible will create it

The final partition configuration should look like this:

```bash
Device     Size   Type                        Mount Point
/dev/sda   256GiB VWware-VWware Virtual disk
├─sda1       8MiB BIOS Boot Partition
├─sda2     100GiB Btrfs Partition             /
├─sda3      32GiB Swap Partition              swap
└─sda4     124GiB Btrfs Partition             /home
/dev/sdb   512GiB VWware-VWware Virtual disk
/dev/sdc   256GiB VWware-VWware Virtual disk
```

The final disk setup after os install should look like this:

```bash
selieea0069:~ # lsblk
    NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
    fd0      2:0    1    4K  0 disk
    sda      8:0    0  256G  0 disk
    ├─sda1   8:1    0    8M  0 part
    ├─sda2   8:2    0  100G  0 part /
    ├─sda3   8:3    0   32G  0 part [SWAP]
    └─sda4   8:4    0  124G  0 part /home
    sdb      8:16   0  512G  0 disk
    sdc      8:32   0  256G  0 disk
    sr0     11:0    1 1024M  0 rom
```

#### Time zone

* Select `Sweeden`

#### Other Settings page

* `Synchronize with NTP Server`
  * Set `Source Type` to value `Server`
  * Set `NTP Server Address` to value `150.132.95.20`
  * `run NTP as daemon` is checked

#### Local users - User creation

* Select `Skip User creation`

#### root passw

* As usual

#### Installation Settings: Summary at the end

* In the `Security` section `* Firewall will be enabled` --> click on `(disable)`.

### Create & Remove snapshot

Right after OS install you need to clean up the existing snapshots.
First need to remove then create a new one.

* Remove snapshot in the menu: `ALL ACTIONS - Snapshot - Remove Snapshot`
  * CAUTION! This can be very long. It can last even more than 1 hour!
* Create snapshot in the menu: `ALL ACTIONS - Snapshot - Create Snapshot`
  * CAUTION! This must be done when the host is `Powered off`.
* Start the host again: `ALL ACTIONS - Power - Power On`

### Execute ansible playbook for the automated configuartion

From the [ansible server](https://eteamspace.internal.ericsson.com/display/ECISE/EEA4+Product+CI+Inventory#EEA4ProductCIInventory-EEA4Adminnode/Ansibleserver) you need to execute the following command:

```
ansible-playbook jenkins_slave.yaml -i clusters.ini --vault-password-file=~/.vault_pass.txt --limit=[your host fqdn]
```

For more info on how to run playbooks from the ansible server, check [Technical details of Ansible server](https://eteamspace.internal.ericsson.com/display/ECISE/Ansible+usage+in+Product+CI#AnsibleusageinProductCI-TechnicaldetailsofAnsibleserver)

### Shellcheck version changes in ansible

**Important** changing shellcheck version turned out to be risky, as between versions 0.7 and 0.8 we experienced major changes that broke some of our pipelines.

If shellcheck version needs to be updated in the ansible role, make sure to test the new version thoroughly.

This can be done by downloading the target version (here 0.8.0) to a temporary directory, and checking sh files in the deployer repo:

```
efikgyo@elx720903xs:~$ cd /tmp/
efikgyo@elx720903xs:/tmp$ wget https://github.com/koalaman/shellcheck/releases/download/v0.8.0/shellcheck-v0.8.0.linux.x86_64.tar.xz
efikgyo@elx720903xs:/tmp$ tar -xJf shellcheck-v0.8.0.linux.x86_64.tar.xz shellcheck-v0.8.0/
efikgyo@elx720903xs:/tmp$ ls
shellcheck-v0.8.0  shellcheck-v0.8.0.linux.x86_64.tar.xz
efikgyo@elx720903xs:/tmp$ cd shellcheck-v0.8.0/
# check with sh scripts from the EEA/deployer repo
efikgyo@elx720903xs:/tmp/shellcheck-v0.8.0$ ./shellcheck ~/SOURCE/deployer/product/source/pipeline_package/eea-deployer/product/scripts/deploy.sh
# !!! If the exit code is not 0, it can cause existing pipelines to fail
efikgyo@elx720903xs:/tmp/shellcheck-v0.8.0$ echo $?
0
# same for upgrade.sh
efikgyo@elx720903xs:/tmp/shellcheck-v0.8.0$ ./shellcheck ~/SOURCE/deployer/product/source/pipeline_package/eea-deployer/product/scripts/upgrade.sh
efikgyo@elx720903xs:/tmp/shellcheck-v0.8.0$ echo $?
0
```

If exit codes are not 0, it means that the changes in the new shellcheck version are not backwards compatible.

### Check docker functionality

In order to avoid pipeline failures because of docker socket permission errors like this (these can happen after reinstall, because the docker group permissions don't get loaded immediately for the eceabuild user):

```
Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Post "http://%2Fvar%2Frun%2Fdocker.sock/v1.24/images/create?fromImage=armdocker.rnd.ericsson.se%2Fproj-adp-cicd-drop%2Fadp-int-helm-chart-auto&tag=0.15.0-1": dial unix /var/run/docker.sock: connect: permission denied
```

The host gets restarted after docker install from ansible.
However, it's worth to **check if docker works for eceabuild user with a docker pull**:

```
# selieea0045:~ #
su - eceabuild
# eceabuild@selieea0045:~>
docker pull armdocker.rnd.ericsson.se/proj-adp-cicd-drop/adp-int-helm-chart-auto:latest
```

If it succeeded, continue and reconfigure the build node.

### Check network connection between Jenkins node and any Product CI cluster kubernetes control plane node.

Connect to freshly reinstalled Jenkins node with ssh and try from there the ssh connection to any Product CI cluster kubernetes control plane node.

```
[ezdobar@seliius27190 ~]$ ssh eceabuild@selieea0025
Password:
Last login: Tue Jan  2 10:41:19 2024 from 10.210.50.91
eceabuild@selieea0025:~> ssh root@seliics04535e01
Password:
Last failed login: Tue Jan  2 15:42:34 CET 2024 from 10.223.227.28 on ssh:notty
There was 1 failed login attempt since the last successful login.
Last login: Tue Jan  2 10:48:23 2024 from 10.223.227.96
seliics04535e01:~ #
```

If we don't experience any problem during the connection we have to check then the network configuration is proper.

#### Hint(s) when you have connection issue

* Please check the search giving in /etc/resolv.conf, the correct value is seli.gic.ericsson.se

## Reconfigure build node on Jenkins

* On the [Jenkins Nodes page](https://seliius27190.seli.gic.ericsson.se:8443/computer/) search for the host
  * e.g.: <https://seliius27190.seli.gic.ericsson.se:8443/computer/selieea0069/>
* Update `Description` in the `Configure` menu
  * Please edit `Description` property if OS changed, e.g. `SLES 15 SP5`
* Rename its label in the `Configure` menu
  * Please edit `Labels` property and rename from `maintenance` back to `productci`
* Lockable resource for the Jenkins build node
  * In case of new Jenkins build node check if a lockable resource exists on the Jenkins as the following: `[build node Hostname]-port-reservation`(e.g: selieea0013-port-reservation)
* Bring this node back online
  * Click on the "Bring this node back online" label
* Last check
  * Check if any Jenkins job can be started here and monitor their running results.

## Monitor the physical state of the hardware

CPU, memory, disk latency, network link usage monitoring will be available after a day on the [Zabbix server](http://dl380x4226e01.seli.gic.ericsson.se/zabbix/zabbix.php?action=dashboard.list)

## Increase a number of total concurrent builds for the spotfire-asset-install pipeline in case of a new build node

At this moment there are 8 Jenkins build nodes that are able to serve [spotfire-asset-install](https://seliius27190.seli.gic.ericsson.se:8443/job/spotfire-asset-install/) pipeline.
In case of adding a new Jenkins build node it's needed to increase the [maxConcurrentTotal](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/technicals/rv_spotfire_asset_install.Jenkinsfile#87) parameter as we use a `Throttle Concurrent Builds` plugin for above pipeline.
During build nodes' maintenance when we remove one node and more from the pool, it's not mandatory to decrease `maxConcurrentTotal` parameter as there is a logic to handle only one build per node thus new runs of the spotfire-asset-install job will wait in the queue.
