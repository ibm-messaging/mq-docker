[![Build Status](https://travis-ci.org/ibm-messaging/mq-docker.svg?branch=master)](https://travis-ci.org/ibm-messaging/mq-docker)

# Contents
* [Overview](#overview)
* [Docker Hub](#docker-hub)
* [Docker Store](#docker-store)
* [IBM Cloud Container Service](#ibm-cloud-container-service)
* [Build](#build)
* [Usage](#usage)
    * [Running with the default configuration](#running-with-the-default-configuration)
    * [Running with the default configuration and a volume](#running-with-the-default-configuration-and-a-volume)
    * [Customizing the queue manager configuration](#customizing-the-queue-manager-configuration)
    * [Running MQ commands](#running-mq-commands)
    * [Installed components](#installed-components)
    * [MQ developer defaults](#mq-developer-defaults)
    * [Customizing MQ developer defaults](#customizing-mq-developer-defaults)
    * [Web console](#web-console)
    * [List of all environment variables supported by this image](#list-of-all-environment-variables-supported-by-this-image)
* [Troubleshooting](#troubleshooting)
    * [Container command not found or does not exist](#container-command-not-found-or-does-not-exist)
    * [AMQ7017: Log not available](#amq7017-log-not-available)
* [Issues and contributions](#issues-and-contributions)
* [License](#license)

# Important
This repository is deprecated.  There is a [new code base](https://github.com/ibm-messaging/mq-container) for running MQ in containers.  It is highly recommended that you use this new code base if possible.  The new code base is where active development is happening, and is more robust, with better tests.

# Overview

Run [IBM® MQ](http://www-03.ibm.com/software/products/en/ibm-mq) in a Docker container.  By default, the supplied Dockerfile runs [IBM MQ for Developers](http://www-03.ibm.com/software/products/en/ibm-mq-advanced-for-developers), but also works for IBM MQ.  The source can be found on the [ibm-messaging GitHub](http://github.com/ibm-messaging/mq-docker).  There's also a short [demo video](https://www.youtube.com/watch?v=BoomAVqk0cI) available.

# Docker Hub
A pre-built version of this image is available on Docker Hub as [`ibmcom/mq`](https://hub.docker.com/r/ibmcom/mq/) with the following tags:

  * `cd`, `9-cd`, `9`, `latest` ([Dockerfile](https://github.com/ibm-messaging/mq-docker/blob/master/Dockerfile))
  * `lts`, `9-lts` ([Dockerfile](https://github.com/ibm-messaging/mq-docker/blob/mq-9-lts/Dockerfile))
  * `8` ([Dockerfile](https://github.com/ibm-messaging/mq-docker/blob/mq-8/Dockerfile))

# Docker Store
A pre-built version of this image is available on [Docker Store](https://store.docker.com/images/ibm-mq-advanced).

# IBM Cloud Container Service
A pre-built version of this image is available on the IBM Cloud Container Registry, as an [IBM Public Repository](https://console.bluemix.net/containers-kubernetes/home/registryPublicImages).

# Build
After extracting the code from this repository, you can build an image with the latest version of MQ using the following command:

```
docker build --tag mq .
```

# Usage
In order to use the image, it is necessary to accept the terms of the IBM MQ license.  This is achieved by specifying the environment variable `LICENSE` equal to `accept` when running the image.  You can also view the license terms by setting this variable to `view`. Failure to set the variable will result in the termination of the container with a usage statement.  You can view the license in a different language by also setting the `LANG` environment variable.

## Running with the default configuration
You can run a queue manager with the default configuration and a listener on port 1414 using the following command.  For example, the following command creates and starts a queue manager called `QM1`, and maps port 1414 on the host to the MQ listener on port 1414 inside the container, as well as port 9443 on the host to the web console on port 9443 inside the container:

```
docker run \
  --env LICENSE=accept \
  --env MQ_QMGR_NAME=QM1 \
  --publish 1414:1414 \
  --publish 9443:9443 \
  --detach \
  ibmcom/mq
```

## Running with the default configuration and a volume
The above example will not persist any configuration data or messages across container runs.  In order to do this, you need to use a [volume](https://docs.docker.com/engine/admin/volumes/volumes/).  For example, you can create a volume with the following command:

```
docker volume create qm1data
```

You can then run a queue manager using this volume as follows:

```
docker run \
  --env LICENSE=accept \
  --env MQ_QMGR_NAME=QM1 \
  --publish 1414:1414 \
  --publish 9443:9443 \
  --detach \
  --volume qm1data:/mnt/mqm \
  ibmcom/mq
```

The Docker image always uses `/mnt/mqm` for MQ data, which is correctly linked for you under `/var/mqm` at runtime.  This is to handle problems with file permissions on some platforms.

## Customizing the queue manager configuration
You can customize the configuration in several ways:

1. By creating your own image and adding your own MQSC file into the `/etc/mqm` directory on the image.  This file will be run when your queue manager is created.
2. By using [remote MQ administration](http://www-01.ibm.com/support/knowledgecenter/SSFKSJ_9.0.0/com.ibm.mq.adm.doc/q021090_.htm), via an MQ command server, the MQ HTTP APIs, or using a tool such as the MQ web console or MQ Explorer.

Note that a listener is always created on port 1414 inside the container.  This port can be mapped to any port on the Docker host.

The following is an *example* `Dockerfile` for creating your own pre-configured image, which adds a custom `config.mqsc` and an administrative user `alice`.  Note that it is not normally recommended to include passwords in this way:

```dockerfile
FROM ibmcom/mq
RUN useradd alice -G mqm && \
    echo alice:passw0rd | chpasswd
COPY 20-config.mqsc /etc/mqm/
```

Here is an example corresponding `20-config.mqsc` script from the [mqdev blog](https://www.ibm.com/developerworks/community/blogs/messaging/entry/getting_going_without_turning_off_mq_security?lang=en), which allows users with passwords to connect on the `PASSWORD.SVRCONN` channel:

```
DEFINE CHANNEL(PASSWORD.SVRCONN) CHLTYPE(SVRCONN) REPLACE
SET CHLAUTH(PASSWORD.SVRCONN) TYPE(BLOCKUSER) USERLIST('nobody') DESCR('Allow privileged users on this channel')
SET CHLAUTH('*') TYPE(ADDRESSMAP) ADDRESS('*') USERSRC(NOACCESS) DESCR('BackStop rule')
SET CHLAUTH(PASSWORD.SVRCONN) TYPE(ADDRESSMAP) ADDRESS('*') USERSRC(CHANNEL) CHCKCLNT(REQUIRED)
ALTER AUTHINFO(SYSTEM.DEFAULT.AUTHINFO.IDPWOS) AUTHTYPE(IDPWOS) ADOPTCTX(YES)
REFRESH SECURITY TYPE(CONNAUTH)
```

## Running MQ commands
It is recommended that you configure MQ in your own custom image.  However, you may need to run MQ commands directly inside the process space of the container.  To run a command against a running queue manager, you can use `docker exec`, for example:

```
docker exec \
  --tty \
  --interactive \
  ${CONTAINER_ID} \
  dspmq
```

Using this technique, you can have full control over all aspects of the MQ installation.  Note that if you use this technique to make changes to the filesystem, then those changes would be lost if you re-created your container unless you make those changes in volumes.


## Installed components

This image includes the core MQ server, Java, language packs, and GSKit.  This can be configured by setting the `MQ_PACKAGES` [Docker build argument](https://docs.docker.com/engine/reference/commandline/build/#set-build-time-variables-build-arg).

## MQ Developer Defaults

This image includes the MQ Developer defaults scripts which are automatically run during Queue Manager startup. This configures your Queue Manager with a set of default objects that you can use to quickly get started developing with IBM MQ. If you do not want the default objects to be created you can set the `MQ_DEV` environment variable to `false`.

#### Users
**Userid:**   admin
**Groups:**   mqm
**Password:** passw0rd

**Userid:**   app
**Groups:**   mqclient
**Password:**

#### Queues
* DEV.QUEUE.1
* DEV.QUEUE.2
* DEV.QUEUE.3
* DEV.DEAD.LETTER.QUEUE - Set as the Queue Manager's Dead Letter Queue.

#### Channels
* DEV.ADMIN.SVRCONN - Set to only allow the `admin` user to connect into it and a Userid + Password must be supplied.
* DEV.APP.SVRCONN - Does not allow Administrator users to connect.

#### Listener
* DEV.LISTENER.TCP - Listening on Port 1414.

#### Topic
DEV.BASE.TOPIC - With a topic string of `dev/`.

#### Authentication information
* DEV.AUTHINFO - Set to use OS as the user repository and adopt supplied users for authorization checks

#### Authority records
* Users in `mqclient` group have been given access connect to all Queues and topics starting with `DEV.**` and have `put` `get` `pub` and `sub` permissions.

## Customizing MQ Developer Defaults

The MQ Developer Defaults supports some customization options, these are all controlled using environment variables:

* **MQ_DEV** - Set this to `false` to stop the Default objects being created.
* **MQ_ADMIN_PASSWORD** - Changes the password of the `admin` user. Must be at least 8 characters long.
* **MQ_APP_PASSWORD** - Changes the password of the app user. If set, this will cause the `DEV.APP.SVRCONN` channel to become secured and only allow connections that supply a valid userid and password. Must be at least 8 characters long.
* **MQ_TLS_KEYSTORE** - Allows you to supply the location of a PKCS#12 keystore containing a single certificate which you want to use in both the web console and the queue manager. Requires `MQ_TLS_PASSPHRASE`. When enabled the channels created will be secured using the `TLS_RSA_WITH_AES_256_GCM_SHA384` CipherSpec. *Note*: you will need to make the keystore available inside your container, this can be done by mounting a volume to your container.
* **MQ_TLS_PASSPHRASE** - Passphrase for the keystore referenced in `MQ_TLS_KEYSTORE`.

## Web Console

By default the image will start the IBM MQ Web Console that allows you to administer your Queue Manager running on your container. When the web console has been started, you can access it by opening a web browser and navigating to https://<Container IP>:9443/ibmmq/console. Where <Container IP> is replaced by the IP address of your running container.

When you navigate to this page you may be presented with a security exception warning. This happens because, by default, the web console creates a self-signed certificate to use for the HTTPS operations. This certificate is not trusted by your browser and has an incorrect distinguished name.

If you choose to accept the security warning, you will be presented with the login menu for the IBM MQ Web Console. The default login for the console is:

* **User:** admin
* **Password:** passw0rd

If you wish to change the password for the admin user, this can be done using the `MQ_ADMIN_PASSWORD` environment variable. If you supply a PKCS#12 keystore using the `MQ_TLS_KEYSTORE` environment variable, then the web console will be configured to use the certificate inside the keystore for HTTPS operations.

If you do not wish the web console to run, you can disable it by setting the environment variable `MQ_DISABLE_WEB_CONSOLE` to `true`.

## List of all Environment variables supported by this image

* **LICENSE** - Set this to `accept` to agree to the MQ Advanced for Developers license. If you wish to see the license you can set this to `view`.
* **LANG** - Set this to the language you would like the license to be printed in.
* **MQ_QMGR_NAME** - Set this to the name you want your Queue Manager to be created with.
* **MQ_QMGR_CMDLEVEL** - Set this to the `CMDLEVEL` you wish your Queue Manager to be started with.
* **MQ_DEV** - Set this to `false` to stop the Default objects being created.
* **MQ_ADMIN_PASSWORD** - Changes the password of the `admin` user. Must be at least 8 characters long.
* **MQ_APP_PASSWORD** - Changes the password of the app user. If set, this will cause the `DEV.APP.SVRCONN` channel to become secured and only allow connections that supply a valid userid and password. Must be at least 8 characters long.
* **MQ_TLS_KEYSTORE** - Allows you to supply the location of a PKCS#12 keystore containing a single certificate which you want to use in both the web console and the queue manager. Requires `MQ_TLS_PASSPHRASE`. When enabled the channels created will be secured using the `TLS_RSA_WITH_AES_256_GCM_SHA384` CipherSpec. *Note*: you will need to make the keystore available inside your container, this can be done by mounting a volume to your container.
* **MQ_TLS_PASSPHRASE** - Passphrase for the keystore referenced in `MQ_TLS_KEYSTORE`.
* **MQ_DISABLE_WEB_CONSOLE** - Set this to `true` if you want to disable the Web Console from being started.


# Troubleshooting

## Container command not found or does not exist
This message also appears as "System error: no such file or directory" in some versions of Docker.  This can happen using Docker Toolbox on Windows, and is related to line-ending characters.  When you clone the Git repository on Windows, Git is often configured to convert any UNIX-style LF line-endings to Windows-style CRLF line-endings.  Files with these line-endings end up in the built Docker image, and cause the container to fail at start-up.  One solution to this problem is to stop Git from converting the line-ending characters, with the following command:

```
git config --global core.autocrlf input
```

## AMQ7017: Log not available
If you see this message in the container logs, it means that the directory being used for the container's volume doesn't use a filesystem supported by IBM MQ.  This often happens when using Docker Toolbox or boot2docker, which use `tmpfs` for the `/var` directory.  To solve this, you need to make sure the container's `/var/mqm` volume is put on a supported filesystem.  For example, with Docker Toolbox try using a directory under `/mnt/sda1`.  You can list filesystem types using the command `df -T`

## Older Linux kernel versions
MQ works best if you have a Linux kernel version of V3.16 or higher (run `uname -r` to check).

If you have an older version, you might need to add the [`--ipc host`](https://docs.docker.com/engine/reference/run/#ipc-settings-ipc) option when you run an MQ container.  The reason for this is that IBM MQ uses shared memory, and on Linux kernels prior to V3.16, containers are usually limited to 32 MB of shared memory.  In a [change](https://git.kernel.org/cgit/linux/kernel/git/mhocko/mm.git/commit/include/uapi/linux/shm.h?id=060028bac94bf60a65415d1d55a359c3a17d5c31
) to Linux kernel V3.16, the hard-coded limit is greatly increased.  This kernel version is available in Ubuntu 14.04.2 onwards, Fedora V20 onwards, and boot2docker V1.2 onwards.  Some Linux distributions, like Red Hat Enterprise Linux, patch older kernel versions, so you might find that the patch has been applied already, even if you see a lower kernel version number.  If you are using a host with an older kernel version, then you can still run MQ, but you have to give it access to the host's IPC namespace using the [`--ipc host`](https://docs.docker.com/engine/reference/run/#ipc-settings-ipc) option on `docker run`.  Note that this reduces the security isolation of your container.

# Issues and contributions

For issues relating specifically to this Docker image, please use the [GitHub issue tracker](https://github.com/ibm-messaging/mq-docker/issues). For more general issues relating to IBM MQ or to discuss the Docker technical preview, please use the [messaging community](https://developer.ibm.com/answers/?community=messaging). If you do submit a Pull Request related to this Docker image, please indicate in the Pull Request that you accept and agree to be bound by the terms of the [IBM Contributor License Agreement](CLA.md).

# License

The Dockerfiles and associated scripts are licensed under the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0.html).
Licenses for the products installed within the images are as follows:

 - [IBM MQ Advanced for Developers](http://www14.software.ibm.com/cgi-bin/weblap/lap.pl?la_formnum=Z125-3301-14&li_formnum=L-APIG-AKHJY4) (International License Agreement for Non-Warranted Programs). This license may be viewed from the image using the `LICENSE=view` environment variable as described above or by following the link above.
 - License information for Ubuntu packages may be found in `/usr/share/doc/${package}/copyright`

Note: The IBM MQ Advanced for Developers license does not permit further distribution and the terms restrict usage to a developer machine.
