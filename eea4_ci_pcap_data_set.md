# How to introduce new PCAP file and Data Set to Product CI

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## New dataset introduction

From 2021 December the following WoW is established.

In case someone gets hold of a new PCAP file that he wants to use in a cluster or Product CI with the UTF data loading machinery, he should follow the below steps.

1. The new PCAP should have a uniq name, which should follow the naming conventions:

    ```
    <networkFunctionType_source_yyyy_mm_dd_eventSpecVersion_contentDescription>
    e.g., amf_paco_2021_12_06_F4I131_mikulas.pcap
    ```

2. The new PCAP should be copied to the Product CI NFS storage as before. This is Product CI team responsibility. Please request copy in e-mail.

3. The pcap_metadata.yml file should be updated with information about the new pcap file:

    [Info page about pcap file in DataSets and Data Loading](https://eteamspace.internal.ericsson.com/pages/viewpage.action?spaceKey=EInVAut&pageId=1152471759#DataSetsandDataLoading-pcap_metadata.yml)

    ```
    amf_paco_2021_12_06_F4I131_mikulas: # this is the <pcap uniqID>

     pcapFilePath: amf_ebm/amf_paco_2021_12_06_F4I131_mikulas.pcap # NFS relative path to the .pcap file from /data/nfs/input-files/
     fileType: ebm
     eventSpecDir:
     eventSpecVersion: F4I149
     dateYyyyMmDd: 20210502
     durationSec: 6254
     eventInputRateMbps: 1.57
     inputPerDayGb: 132.5
     eventRatePerSec: 385.3
     incidentRatePerSec: 18.85
     totalNumberOfSubscribers: 508359
     networkFunctionType:

    - AMF
     rat:
    - 4G
    - 5G
     eventList:
       AMF_DEREGISTRATION: 138930
       AMF_HANDOVER: 818575
       AMF_INITIAL_REGISTRATION: 661533
       AMF_PAGING:   5896
       AMF_PDU_SESSION_ESTABLISHMENT: 784519
       AMF_SERVICE_REQUEST:    210
     incidentList:
       AMF_HANDOVER: 41262
       AMF_INITIAL_REGISTRATION: 17852
       AMF_PAGING:  5686
       AMF_PDU_SESSION_ESTABLISHMENT: 53113
        ...

    ```

4. A new Data Set should be created in the data_set.yml file

    [Info page about DataSets and Data Loading](https://eteamspace.internal.ericsson.com/pages/viewpage.action?spaceKey=EInVAut&pageId=1152471759#DataSetsandDataLoading-data_sets.yml)

   **Important:** Never change an existing data set. Always create new one!

    ```
    dataSets:
    PROD_CI_2021_11_09_v1: # this is the <data set uniqID>
    ...
    PROD_CI_2021_12_06_v1:
    amf_paco_2021_12_06_F4I131_mikulas: # refer here to the new pcap file with <pcap uniqID>
      throttle: 1
      repeat: -1
      repeatMode: 3
    ...
    ```

5. Consider update other config files based on this list:

    [Configs list from info page about DataSets and Data Loading](https://eteamspace.internal.ericsson.com/pages/viewpage.action?spaceKey=EInVAut&pageId=1152471759#DataSetsandDataLoading-Configs)

6. The refData for this new data set needs to be copied to the NFS under a new folder named refData/\<data set uniqID\>
   Only one file of each type is allowed. This is Product CI team responsibility. Please request copy in e-mail.

7. Once the yml file edits are ready, you should commit your changes and go through the gerrit review and the final submit.

8. After this the new UTF drop containing the previous commit should reach the metabaseline of Product CI in order to be able to use the new dataSet uniqId.

## RefData schema change process

Before refdata schema can be changed at the EEA product configuration at cnint repo (e.g cnint/dataflow-configuration/all-VPs-configuration/refdata-values.yaml) the new schema file has to be stored at central NFS. (e.g /data/input-files_CI/refData/RV_48_20231025/reference-data-3.0.0.yml)

*Important note* New schema file has to be a new file every time, existing files at NFS can't be modified or removed!

Related pages:

- [UTF4 page about Data Sets and Data Loading by Istvan Kishonti](https://eteamspace.internal.ericsson.com/pages/viewpage.action?spaceKey=EInVAut&pageId=1152471759)
- [RV page about extracting dimensioning information from PCAPs](https://eteamspace.internal.ericsson.com/pages/viewpage.action?spaceKey=EInVAut&pageId=1100718617)
