# Common EEA4 CI data loading

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## 1. EEA4 CI data loading

Data loading is driven by UTF with dedicated step for starting the data loading using data-loader service and another fo stopping the data.

+ Data loader service is deployed from metabaseline chart
+ Rule used for data loader start at cnint ruleset2.0.yaml file: start_data_loading
+ Rule used for data loader stop at cnint ruleset2.0.yaml file: stop_data_loading
+ Data loaded (PCAP files) from central NFS: seliics00309.ete.ka.sw.ericsson.se:/data/nfs/input-files

## 2. EEA4 CI [Reference data](http://seliics00348.seli.gic.ericsson.se:5001/eea4/PRODUCT/1.0.0-276/Reference_Data_Description/Reference_Data_Description.html) loading

[Reference Data Description on CPI Build server](http://seliics00348.seli.gic.ericsson.se:5001/eea4/PRODUCT/1.0.0-276/Reference_Data_Description/Reference_Data_Description.html)

[CPI Store Reference Data Description](https://calstore.internal.ericsson.com/elex?LI=EN/LZN7030318*&FN=1_22102-ava90159uen.*.html)

Reference data loading was integrated to UTF4 test executions. When [dataSet](https://eteamspace.internal.ericsson.com/display/EInVAut/DataSets) unique ID is passed to the UTF API, [refdata loading](https://eteamspace.internal.ericsson.com/display/EInVAut/Reference+Data+Loading) starts automatically.

### 2.1 We have keywords for different reference data types loading:

+ [crm](http://seliics00348.seli.gic.ericsson.se:5001/eea4/PRODUCT/1.0.0-276/Reference_Data_Description/Reference_Data_Description.html#crm_custgbhbfgfgfgrrjhynrtomer_device_info)
+ [node](http://seliics00348.seli.gic.ericsson.se:5001/eea4/PRODUCT/1.0.0-276/Reference_Data_Description/Reference_Data_Description.html#noddfbvdfvdfe_address)
+ [device](http://seliics00348.seli.gic.ericsson.se:5001/eea4/PRODUCT/1.0.0-276/Reference_Data_Description/Reference_Data_Description.html#tafgbnfgnyjtc_table)
+ [cell](http://seliics00348.seli.gic.ericsson.se:5001/eea4/PRODUCT/1.0.0-276/Reference_Data_Description/Reference_Data_Description.html#fgnhfgmkgthcell_location)

These keywords are using in [--input-files](https://gerrit.ericsson.se/plugins/gitiles/EEA/cnint/+/master/ruleset2.0.yaml#691) parameter, e.g:

  ```
  --input-files crm=${ref-data-path}/incident_crm_customer_device_info.json node=${ref-data-path}/node_address.json device=${ref-data-path}/tac_eea.json cell=${ref-data-path}/cell_location.json
  ```

#### 2.1.1 If we have a separate file from on type for example tac, then we can merge those with this solution:

  ```
  jq --slurpfile in <(jq '.data[]' <5g_tac_eea.json) '.data |= .+ $in' <4g_tac_eea.json >tac_eea.json
  jq '.data | length' tac_eea.json
  837
  jq '.data | length' 5g_tac_eea.json
  81
  jq '.data | length' 4g_tac_eea.json
  756
  ```

### 2.2 Product CI Reference data storage solution

[We stored the Reference data in Product CI NFS server](https://gerrit.ericsson.se/plugins/gitiles/EEA/adp-app-staging/+/master/eea4_ci_file_storage.md#1_1_Stored-data)

Basically the Teams are upload files into Enviroment Team NFS server and we will download from there into our date-versioned subdirectory, this solution has two benefit:

+ we can avoid unintended Reference data owerwriting, becase just EEA4 Product CI members has rights for data upload
+ we stored two places the same datas and we can avoid the data loss issue

### 2.3 CLI solutions for Reference data loading

If it is necessary for debug purpose we can follow the RV documentations which are contains the CLI steps:

+ [How to upload reference data via Reference Data Provisioner (Internal)](https://eteamspace.internal.ericsson.com/pages/viewpage.action?pageId=99197906)
+ [How to upload reference data via Reference Data Provisioner (External)](https://eteamspace.internal.ericsson.com/pages/viewpage.action?pageId=99201524)

## 3. Storage for UTF at Product CI NFS

UTF uses the following path (/data/nfs/commonci/utf4) to store htlm reports about utf4 test executions and some files generated dinamically durint test runs used by the framework.

TO DO: Cleanup will be introduced for this folder in a further ticket.
