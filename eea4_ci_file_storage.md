# Common EEA4 CI file storage

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## 1. Common EEA4 CI file storage

For the purposes of storing binary logs and core dumps an NFS v4 export has been made available here with 5TB redundant, local storage space provisioned and 25% of the array capacity retained for future expansion.
**Important: currently no backups are taken, nor are access restrictions of any kind in place.**

### 1.1. Stored data:

+ Input test data for EEA4 Product CI: /data/nfs/input-files
  + RV NFS is also mounted to this server to be able to synch data used at RV NFS to this Common EEA4 CI file storage at the following path: /data/nfs/datastore_02
+ Reference data:
  + stored on seliius27190.seli.gic.ericsson.se (EEA4 CI NFS server) in  /data/nfs/commonci/data/input-files/ref_data/ directory with date versioned subdirectory e.g. 06222021
  + nfs mounted into Jenkins build nodes
    + /etc/fstab entry:
      + seliics00309.ete.ka.sw.ericsson.se:/data/nfs/commonci /data/nfs/productci nfs rw,soft,bg,nfsvers=3 0 0
    + /data/nfs/productci/data/input-files/ref_data/
  + If we have more files in one type, we can merge it those with this solution (becase the reference_data_loader.py support just one file upload from one type reference data):

      ```
      jq --slurpfile in <(jq '.data[]' <5g_tac_eea.json) '.data |= .+ $in' <4g_tac_eea.json >tac_eea.json
      jq '.data | length' tac_eea.json
      837
      jq '.data | length' 5g_tac_eea.json
      81
      jq '.data | length' 4g_tac_eea.json
      756
      ```

### 1.2 New data set structure

+ Data set structure is being updated, new pcap and reference data files are stored here at the same NFS but not used yet in our pipelines: /data/nfs/input-files
+ Each pcap type has its own directory which contains the versioned pcap files (naming conventions: < networkFunctionType_source_yyyy_mm_dd_eventSpecVersion_contentDescription > e.g., amf_paco_2021_12_06_F4I131_mikulas.pcap )
+ Metadata file for pcap is stored at [Git](https://gerrit.ericsson.se/plugins/gitiles/EEA/eea4-bbt/+/master/unified-test-framework/utf-plugins-parent/utf-plugin-config-loader/src/main/resources/configs/pcap_metadata.yml), this contains information about all the PCAP files at our NFS.
+ Data set descriptors for our datasets used at Product CI is available here: <https://gerrit.ericsson.se/plugins/gitiles/EEA/eea4-bbt/+/master/unified-test-framework/utf-plugins-parent/utf-plugin-config-loader/src/main/resources/configs/data_sets.yml>
+ Reference data is in a dedicated directory at the NFS under /data/nfs/input-files, each dataset has a dedicated directory where all the refdata files for the dataset are available.
+ Details about handling datasets are described [here](https://eteamspace.internal.ericsson.com/display/ECISE/How+to+introduce+new+PCAP+file+and+Data+Set+to+Product+CI), including WoW for storing new datasets.

+ NFS Usage example:

    ```
    mount -o rw seliics00309.ete.ka.sw.ericsson.se:/data/nfs/commonci /mnt
    ```

### 1.3 SFTP access to NFS server

+ In order to upload files to NFS server without getting root access, the internal SFTP access was set up
  + As internal SFTP is a part of the SSH daemon were added extra directives to the /etc/ssh/sshd_config configuration file

  ```
  # override default of no subsystems
  #Subsystem sftp /usr/libexec/openssh/sftp-server
  Subsystem       sftp    internal-sftp

  #SFTP Chroot Jail
  Match Group sftprestricted
  ChrootDirectory %h
  ForceCommand internal-sftp -d /RV_input_files -u 022
  PasswordAuthentication yes
  PubkeyAuthentication no
  PermitTunnel no
  AllowAgentForwarding no
  AllowTcpForwarding no
  X11Forwarding no
  ```

  + A sftprestricted group with 1001 id was created

  ```
  groupadd sftprestricted
  ```

  + Users were created

  ```
  useradd -g sftprestricted -d /data/nfs/input-files -s /sbin/nologin new_user
  passwd new_user

  [root@seliics00309 RV_input_files]# cat /etc/passwd |tail -n7
  ethbsii:x:1001:1001::/data/nfs/input-files:/sbin/nologin
  esndmih:x:1002:1001::/data/nfs/input-files:/sbin/nologin
  ezdobar:x:1003:1001::/data/nfs/input-files:/sbin/nologin
  eszagyo:x:1004:1001::/data/nfs/input-files:/sbin/nologin
  ekovzso:x:1005:1001::/data/nfs/input-files:/sbin/nologin
  eattilo:x:1006:1001::/data/nfs/input-files:/sbin/nologin
  enorbdm:x:1007:1001::/data/nfs/input-files:/sbin/nologin
  ```

***Note: If user cannot log in to NFS server it's needed to restart SSH daemon. systemctl restart sshd***

### 1.4. Spotfire platform asset package data

Spotfire platform asset packages are built by SD organisation and used by EEA deployments from NFS as primary source to speed up pipelines.
These packages can be validated and uploaded to the EEA4 CI NFS server by the [spotfire-platform-asset-uploader](https://seliius27190.seli.gic.ericsson.se:8443/job/spotfire-platform-asset-uploader) Jenkins job.
These data can be accessed read only from all the Jenkins build nodes on path: `/data/nfs/spotfire_cn` which points to `seliics00309.ete.ka.sw.ericsson.se:/data/nfs/product_ci/spotfire_cn`.
The NFS mount configuration is stored [here](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/ansible/roles/jenkins_slave/tasks/main.yml#262)

For more info see the [Spotfire Platform Asset Uploader docs](https://eteamspace.internal.ericsson.com/display/ECISE/Spotfire+Platform+Asset+Uploader).
