# Tests

The tests are run in a Docker image, by using the `run.sh` script, passing in the label for the Docker image to test.  For example:

```
run.sh ibmcom/mq
```

The `run.sh` script creates a Docker network, then runs a test container on that network.  The test container has the Docker socket shared with it, so that it can create containers on the host.  It uses this ability to create queue manager containers on the host which are part of the same Docker network. 

NOTE: The volume-based tests do not work on Docker for Mac, due to filesystem incompatibilities within the xhyve virtual machine.