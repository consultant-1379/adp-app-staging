# WoW for manually fix the microservice versions

**Table of contents:**
<!-- START doctoc
...
END doctoc -->

## Activities that can cause trouble

* NEVER do revert in git - version in artifactory will conflict with the version in repository - send fix as new change
* NEVER submit change manually. If it's happened, don't revert it -  send content as a new change again correctly
* DO NOT try to edit your helm version in Chart.yaml , ihc-auto version increase can conflict with

## How to raise or downgrade manually a microservice version

How to raise or downgrade manually a microservice version if it cause issue even it has passed the whole EEA App Staging loop and it's part of the baseline already.

1. create a change and in the dependency set the required version . In helm 3 in file Chart.yaml

        dependencies:
        ...
          name: eric-pm-server
          repository: https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-adp-gs-all-helm
          version: 2.4.0+22
        ...
1. push the fixes as a new change, after review let ihc-auto raise version and publish
1. REMEMBER that the next PRA version from that microservice will trigger the loop, and without proper tests, your dependency will be overwritten, with potentially wrong version again.

## How to fix version step issue

If you got this error message:

    [ihc-auto][ERROR] Next calculated version 0.0.0-100 is already uploaded. Make sure version in Chart.yaml is correctly stepped

you can try to rebase in gerrit, or push a new change after rebased locally. DO NOT change version manually
