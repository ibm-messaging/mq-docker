# Change log

## 3.0.0 (2017-xx-xx)
### Action required
None

### Other notable changes
* Updated to MQ V9.0.3
* Restructured startup scripts
* Removed fixed UID numbers

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
