# CPI ARM uploader

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Purpose

The job was created for the CPI team to upload their artifacts to the ARM

## Jenkins job

Job name: [cpi-arm-uploader](https://seliius27190.seli.gic.ericsson.se:8443/job/cpi-arm-uploader)

## Parameters

+ `SOURCE_FILE_URL` - Link to file to be uploaded to Arm
+ `ARM_UPLOAD_URL` - Arm URL for file upload
+ `ARM_UPLOAD_PATH` - Target Arm path for file upload
+ `ARM_UPLOAD_FILE` - The name with which the file will be uploaded to ARM

## Steps

1. Get file from the specified source

    Downloads the source file from the specified source to upload it into ARM in the next steps

1. Upload to artifactory

    Uploads artifact from the previos step to the specified path in the ARM

## Post steps

1. Success

    Add a link to the file added to the ARM
