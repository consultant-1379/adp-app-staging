# Spotfire Platform Asset Uploader

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Purpose

Spotfire platform asset package is built by SD organisation at the moment and this job is intended to validate and upload the package to the ARM repo and as a cache to Prod CI NFS.
EEA deployments will use NFS as primary source to speed up pipelines, release pipelines will use ARM only as source.

* ARM server: <https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-generic-local/sf-platform-asset/>
* NFS server: `seliics00309.ete.ka.sw.ericsson.se`
* NFS path: `/data/nfs/product_ci/spotfire_cn`
* Jenkins build nodes mounted NFS path: `/data/nfs/spotfire_cn`

## Jenkins job

Job name: [spotfire-platform-asset-uploader](https://seliius27190.seli.gic.ericsson.se:8443/job/spotfire-platform-asset-uploader)

## Parameters

* SPOTFIRE_PLATFORM_ASSET_FILE - Spotfire asset package file must be selected to from the local machine
  * accepted filename convention: spotfire-platform-asset-[SF platform version]-[asset build version].zip
  * e.g. spotfire-platform-asset-12.5.0-1.5.0.zip
* SHA256SUM - sha256sum hash value of the package
  * Need to specify the sha256sum checksum value of the asset package file.
  * It will be valitaded on the build node after the upload
* SEND_EMAIL_NOTIFICATION - Send email notification if true
  * After the job is finished (even for success or fail results) a notification email will be sent to the EEA4 Product CI Team and to the specified people in SD orinization.

## Steps

* Checkout - scripts
  * Checkout some helper function
* Preparation
  * Checks if all mandatory parameter is set
  * Prepares the uploaded file
  * Generates sha256 hash for the uploaded file and verifies it with the input hash value
* Check uploaded filename
  * Checks the format of the input file name and aborts execution if it does not conform to the accepted convention
* Set build description
  * Creates build description to the Jenkins job with the following info:
    * Version
    * ARM url
    * NFS path
* Check file in arm
  * Checks that the package has been uploaded earlier ot not to [arm repo](https://arm.seli.gic.ericsson.se/artifactory/proj-eea-drop-generic-local/sf-platform-asset/)
  * If it exists there aborts the execution at this point
* Unzip file
  * Tries to extract the zip file on the build node
* Check zip structure
  * Checks that a subdir equal to the filename (without `.zip`) is exist in the compressed file or not
  * If not exists there aborts the execution at this point
* Upload to arm
  * Uploads the input zip file to the ARM artifactory server
* Verify arm checksum
  * Downloads the automatically generated arm hash from artifactory and verifies it with the input hash value
* Upload to nfs
  * Uploads the extracted zip file content to the NFS server using sftp command.
  * It authenticates using the user/password from  Jenkins credentials `hub-eceabuild-user`
  * The user must be in the `sftprestricted-spotfire` group which has write permission to the `/data/nfs/product_ci/spotfire_cn` directory.
* Verify nfs checksum
  * Generates sha256 hashes for directories containing locally extracted zip file content and uploaded nfs files
  * Verifies those directory hashes

## Necessary Jenkins plugin

The job uses the external [File Parameter](https://plugins.jenkins.io/file-parameters/) Jenkins plugin to upload the input spotfire asset package to the build node.
