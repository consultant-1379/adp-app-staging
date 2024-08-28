[//]:# (confluence:no)

# This playbook is capable of deploying and configuring an NFS server on RHEL 7 and compatibles.

## Configuration

Via variables defined in *roles/nfs-server/vars/main.yml*. Example:

```yaml
data_device: /dev/sdb
data_vg: nfs
data_volumes:
  - name: misc
    size: 100g
    fs: ext4
    mountpoint: /data/nfs/misc
    nfs:
      export: yes
      clients:
        - host: '*'
          options:
            - rw
```

This ensures an LVM LV named "misc" exists in a VG named "nfs" on a PV on the device "sdb1", is formatted with "ext4", mounted under "/data/nfs/misc" and exported to all hosts in a writeable manner.

## Notes

- tested on RHEL 7.6
- depends on the role *elk*, re-using two of its tasks for package manager and storage configuration
