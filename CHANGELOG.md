# Change log

## 2.0.0 (unreleased)
### Action required
* Ensure that you use the `REPLACE` keyword in all of your `DEFINE` MQSC statements.  With this chance, any supplied MQSC files are run *every* time the queue manager runs.  This allows you to update the MQSC file, re-build the image, and then have the changes applied when you start a container based on that new image.
* Code has been re-structured to use git branches for older versions of MQ.

### Other notable changes
* Update to MQ V9.0.1, adding the web console on port 9443.
* Update base image to Ubuntu 16.04
* Set version number in command prompt dynamically
* Bluemix Volume support added. (See: `setup-var-mqm.sh`)
* Added MQ Developer Defaults

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
