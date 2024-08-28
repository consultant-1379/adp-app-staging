# Spotfire asset install

Spotfire asset is basically container images and Helm chart, that contains
the Spotfire images & required 3PPs (e.g. HAPRoxy, PostgresDB),
so Spotfire can run in k8s environment in a separate namespace, called ```spotfire-platform```.
Dedicated Spotfire Virtual machine(s) are not needed anymore.

## How to install it in EEA test environments

The sequence of installation of Spotfire and EEA is important.

Order is:

1. Install Spotfire Platform. It will be deployed in ```spotfire-platform``` namespace.

    Job: [spotfire-asset-install](https://seliius27190.seli.gic.ericsson.se:8443/job/spotfire-asset-install)

    Mandatory parameters to change:
    - CLUSTER_NAME: select proper cluster
    - INSTALL_SPOTFIRE_PLATFORM: tick the checkbox
    - DEPLOY_STATIC_CONTENT: tick the checkbox
    - STATIC_CONTENT_PKG: Update version if needed

    **Important:** After the install is finished, note down the job BUILD number, e.g. 245

2. Install EEA

    - option A: Manually installing EEA

      **Important** to set the following parameters at EEA installation as follows:

        1. Spotfire psql user (called ```tss_psql_user``` in install guide): ```spotfire```

        2. In environment-values.yaml file:
        ```eric-eea-analysis-system-overview-install.configuration.database.host=eric-ts-platform-data-document-database-pg.spotfire-platform.svc.cluster.local```

    - option B: If using [TnT job](https://seliius27190.seli.gic.ericsson.se:8443/job/rv-eea4-and-tools-and-traffic)
      The above-mentioned values are set properly if changing the **SPOTFIRE_SERVER** value to
      ```eric-ts-platform-data-document-database-pg.spotfire-platform.svc.cluster.local```

3. Load certificates into EEA

    Job: e.g. [TnT](https://seliius27190.seli.gic.ericsson.se:8443/job/rv-eea4-and-tools-and-traffic)
    LOAD_CERTIFICATES stage, or manual certificate loading method

4. Integrate Spotfire with EEA

    Job: [spotfire-asset-install](https://seliius27190.seli.gic.ericsson.se:8443/job/spotfire-asset-install)

    Mandatory parameters to change:
    - CLUSTER_NAME: select proper cluster
    - SETUP_TLS_AND_SSO: tick the checkbox
    - ENABLE_CAPACITY_REPORTER: tick the checkbox
    - PREVIOUS_JOB_BUILD_ID: put here the job ID of SF installation job, that was performed in step 1, e.g. 245

## How to access Spotfire GUI

Once both the EEA and Spotfire system is installed and integrated:

1. List the coreDNS config on the cluster:

    ```
    # kubectl get cm coredns -n kube-system -oyaml
    ...
    ...
        hosts {
        10.196.1.130 iam.eea.company-domain.com
        10.196.1.18  privacy-service-converter.eea.company-domain.com
        10.196.1.130 authproxy.eea.company-domain.com
        10.196.1.18  spotfire-manager.eea.company-domain.com
        10.196.1.129 spotfire.eea.company-domain.com
    ...
    ...
    ```

2. From the ```hosts``` entry part put the above ```IP <-> FQDN``` pairs into your laptops hosts file.
   In Windows server path to hosts file is ```c:\Windows\System32\drivers\etc\hosts```.

3. Open any browser in your laptop and open Spotfire URL, that is: ```https://spotfire.eea.company-domain.com```

4. Two login credentials are defined by default by job:

- ```admin-sf / Adm1ni$tRat0r!```
- ```nonadmin / EEAuSeR4Pa$$w0rd!```

## Cleanup Spotfire from cluster

Job: [spotfire-asset-install](https://seliius27190.seli.gic.ericsson.se:8443/job/spotfire-asset-install)

Mandatory parameters to change:

- CLUSTER_NAME: select proper cluster
- CLEANUP_SPOTFIRE: tick the checkbox

## Spotfire platform asset package data uploader

Spotfire platform asset packages are built by SD organisation and used by EEA deployments from NFS as primary source to speed up pipelines.
These packages can be validated and uploaded to the EEA4 CI NFS server by the [spotfire-platform-asset-uploader](https://seliius27190.seli.gic.ericsson.se:8443/job/spotfire-platform-asset-uploader) Jenkins job.

For more info see the [Spotfire Platform Asset Uploader docs](https://eteamspace.internal.ericsson.com/display/ECISE/Spotfire+Platform+Asset+Uploader).
