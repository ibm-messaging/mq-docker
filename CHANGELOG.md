# Change log

## 3.1.0 (2017-11-21)
* Updated to MQ V9.0.4
* Changed `mqm` user and group from 999 to 1000.  This is to ensure that the "system" pool of users is used, so it's less likely to clash with a real user on the host.  All files under `/mnt`, `/var`, and `/etc` will be migrated at runtime (see `setup-var-mqm.sh`)
* Removed packages `curl`, `ca-certificates`, and their dependencies, which were only used at build time

## 3.0.0 (2017-06-08)
### Action required
* Updated to install Ubuntu `.deb` files - Any changes to the `MQ_PACKAGES` variable will now need to use the new package names (for example, "ibmmq-web" instead of "MQSeriesWeb")

### Other notable changes
* Updated to MQ V9.0.3
* Migrated from `amqicdir` to new official `crtmqdir` utility
* Restructured startup scripts
* Removed fixed UID numbers for developer config
* Use HTTPS for MQ installer download
* Reduced image size by purging 32-bit libraries

## 2.0.0 (2017-03-11)
### Action required
* Ensure that you use the `REPLACE` keyword in all of your `DEFINE` MQSC statements.  With this change, any supplied MQSC files are run *every* time the queue manager runs.  This allows you to update the MQSC file, re-build the image, and then have the changes applied when you start a container based on that new image.
* Code has been re-structured to use git branches for older versions of MQ.

### Other notable changes
* Updated to MQ V9.0.1, adding the web console on port 9443.
* Updated base image to Ubuntu 16.04
* Set version number in command prompt dynamically
* NFS and Bluemix Volume support added. (See: `setup-var-mqm.sh`).  Note that it is now recommended to mount volumes into `/mnt/mqm` instead of `/var/mqm`.
* Added MQ Developer Defaults, to provide better defaults for security, as well as queues and topics useful for development

## 1.0.2 (2016-11-02)
* Add MQ V9
* Don't apply CMDLEVEL unless specifically requested
* Always call `amqicdir` to set up `/var/mqm`
* Reduce image size by cleaning up temporary files
* Add regression tests
* Configure URL and packages with a build argument

## 1.0.1 (2015-12-01)
* Update to Apache license, for consistency with other similar offerings
* Updates to troubleshooting section in README

## 1.0.0 (2015-12-01)
Initial supported version.
