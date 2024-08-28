# Docker cleanup on Jenkins build nodes

## Background

Docker volumes on Product CI build nodes got cleaned up periodically.

Currently our Jenkins build nodes use 2 disks for docker:

* one disk with LV partitions (here `sdb`) - this is a docker volume, currently handled by device mapper - **docker images** are stored here)
* one disk (here `sdc`) mounted under `/var/lib/docker/volumes` - this is a simple filesystem mount, **docker container data** is stored here.

```
selieea0045:~ # lsblk
NAME                             MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
fd0                                2:0    1     4K  0 disk 
sda                                8:0    0   256G  0 disk 
├─sda1                             8:1    0   512M  0 part /boot/efi
├─sda2                             8:2    0   100G  0 part /var
│                                                          /usr/local
│                                                          /tmp
│                                                          /srv
│                                                          /root
│                                                          /opt
│                                                          /boot/grub2/x86_64-efi
│                                                          /boot/grub2/i386-pc
│                                                          /.snapshots
│                                                          /
├─sda3                             8:3    0   122G  0 part /home
└─sda4                             8:4    0  33,5G  0 part [SWAP]
sdb                                8:16   0   512G  0 disk 
└─sdb1                             8:17   0   512G  0 part 
  ├─VolDocker-docker--pool_tmeta 254:0    0   5,1G  0 lvm  
  │ └─VolDocker-docker--pool     254:2    0 486,4G  0 lvm  
  └─VolDocker-docker--pool_tdata 254:1    0 486,4G  0 lvm  
    └─VolDocker-docker--pool     254:2    0 486,4G  0 lvm  
sdc                                8:32   0   256G  0 disk 
└─sdc1                             8:33   0   256G  0 part /var/lib/docker/volumes
sr0                               11:0    1  12,1G  0 rom  

```

Currently the disk containing the docker images is the one that fills up the most easily. This case we got errors like:

```
docker: Error response from daemon: devmapper: Thin Pool has 24898 free data blocks which is less than minimum required 24902 free data blocks. Create more free space in thin pool or use dm.min_free_space option to change behavior. 
```

When such error is encountered, we need to cleanup the docker volumes on host. To avoid these, we run scheduled cleanups.

**TODO** - In the future LV docker volumes will be replaced by overlayfs. After that we will have to change the current disk usage query commands in `CommonUtils.getDockerVolumesDiskUsageReport`.

## Jobs

Our docker cleanup jobs handle cleaning up these partitions, based on the disk usage of the build nodes.
There are 2 jobs: docker-cleanup-scheduler that runs via cron, checks and prioritizes build nodes by their disk usage, and starts a given number of individual cleanup build jobs (docker-cleanup-node job) at a time.

### docker-cleanup-scheduler job

#### Params

* the job has a parameter `MAX_NODES_UNDER_CLEANUP`, that holds the number of build nodes can be taken offline at a time for cleanup
* `MIN_PROD_CI_NODES_ONLINE` for the minimum required numbers of online build with the specified label (label specified with `CLEANUP_NODES_WITH_LABEL` param, default: productci. If teams other than ProductCI intend to use these jobs, they have to change this to their label) - if its reached, notification is sent and no more node can be removed.
* there is a threshold parameter `DISK_USAGE_TRESHOLD`, that tells the script that only hosts **above this percent should be cleaned up** (eg. disk usage over 50%) to avoid unnecessary cleanups
* `MAINTENANCE_LABEL` param specifies what special label the job should give to the hosts under cleanup maintenance - If teams other than ProductCI intend to use this job, they have to choose a distinctive label (to avoid handling our and their nodes under maintenance together when determining the number of hosts with a specified label that can be taken offline).
* `NOTIFICATION_EMAIL` tells where to send notification emails in case of problems
* Cleanup requires to put build nodes to offline status for Jenkins and wait until all executions finish on the hosts before starting the cleanup. Since it can take long for some jobs, `WAIT_FOR_NODE_IDLE_TIMEOUT` param sets a timeout - when it's reached, the job puts back the hosts to the pool without cleanup (*except when the host has reached a critically high disk usage*) and tries to remove it at the next job run.

#### Steps

* docker-cleanup-scheduler job runs every 4 hours (tough it can be started manually for an on-demand cleanup as well) and decides which host(s) should be cleaned up next
* The job runs only on production jenkins (not on test), and only on master node
* The job first checks params and sets build description to the label we are running the job against (`CLEANUP_NODES_WITH_LABEL` param)
* The job checks if there are enough online hosts with the specified label - if not, notifies & exits
* The job checks the number of nodes that are currently under cleanup maintenance by an earlier run of the job. If there are already too many nodes under maintenance, it exits. Otherwise determines the "n" number of hosts that are still safe to take offline (calculates from the minimum number of online hosts needed and the maximum number of hosts that can be under maintenance).
* After this the job queries the docker disk usage on the build nodes via ssh, and orders the hosts by disk usage (currently sorts by docker LV data partition size, since currently this disk is the most likely to fill up - this may change in the future.)
* If no host has high disk usage (above the specified `DISK_USAGE_TRESHOLD`), no cleanup will start
* After this it takes "n" hosts with highest disk usage, and in a parallel fashion calls `docker-cleanup-node` job on them.
* The main job waits for the result from all parallel child jobs and sets its build result to success or failure according to these.
* For this scheduler job parallel runs are allowed: if the previous build hasn't finished when a new build starts from cron, the new job checks again whether it is possible to remove other hosts for cleanup - if not, it exists, otherwise it starts the required number of cleanup jobs according to the logic above.

### docker-cleanup-node job

This job is called by docker-cleanup-scheduler job to clean up one build node (specified by name). It can also be used to manually clean up a specified node.

#### Params

`NODE_NAME` - Name of the Jenkins build node to be cleaned up
`WAIT_FOR_NODE_IDLE_TIMEOUT` - Wait for node to finish executions before timeout (hours)
`MAINTENANCE_LABEL` - This label is set on hosts during docker cleanup maintenance. Change this from the default if the job is run on non-productci nodes!
`EMERGENCY_DISK_FULL_TRESHOLD` - If any docker volume is above this percentage, the script won't move the host back to pool in case cleanup failed with timeout. It also sends a warning in email that the host should be handled manually.
`NOTIFICATION_EMAIL` - E-mail address for notifications. Change this when run on non-productci nodes!

#### Steps

* The job checks params and sets build description to the name of the build node currently handled
* Then marks the build node offline
* Then waits until all the jobs are finished running on the host
  * If the running jobs are not finished within the given timeout, it decides whether the host can be taken back to pool by checking the disk usage
    * If the disk usage on any docker volume is greater than the given threshold, it won't put the node back to the pool, but sends email notification to warn about the host
    * If disk usage is under the threshold, it puts back node to online and exits
* Only when all executions are finished can the cleanup be started
* The job saves the old labels on the host (since it waited for all jobs to finish, no job labels will be present on the node, only prodci and manually set labels, if any.)
* Changes the node label to the specified `MAINTENANCE_LABEL`
* Executes the cleanup
* Removes the maintenance label and moves back the saved previous labels
* Sets the node online and waits until it is online
* In case of failures, sends email to the specified address
