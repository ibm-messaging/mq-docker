#!/bin/bash
# -*- mode: sh -*-
# © Copyright IBM Corporation 2015, 2017
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

stop()
{
  endmqm $MQ_QMGR_NAME
}

parameterCheck()
{
  : ${MQ_QMGR_NAME?"ERROR: You need to set the MQ_QMGR_NAME environment variable"}

  # We want to do parameter checking early as then we can stop and error early before it looks
  # like everything is going to be ok (when it won't)
  if [ ! -z ${MQ_TLS_KEYSTORE+x} ]; then
    if [ -z ${MQ_TLS_PASSPHRASE+x} ]; then
      echo "Error: If you supply MQ_TLS_KEYSTORE, you must supply MQ_TLS_PASSPHRASE"
      exit 1;
    fi
  fi
}

config()
{
  # Populate and update the contents of /var/mqm - this is needed for
	# bind-mounted volumes, and also to migrate data from previous versions of MQ

  setup-var-mqm.sh

  if [ -z "${MQ_DISABLE_WEB_CONSOLE}" ]; then
    echo $MQ_ADMIN_PASSWORD
    # Start the web console, if it's been installed
    which strmqweb && setup-mqm-web.sh
  fi

  ls -l /var/mqm
  source /opt/mqm/bin/setmqenv -s
  echo "----------------------------------------"
  dspmqver
  echo "----------------------------------------"

  QMGR_EXISTS=`dspmq | grep ${MQ_QMGR_NAME} > /dev/null ; echo $?`
  if [ ${QMGR_EXISTS} -ne 0 ]; then
    echo "Checking filesystem..."
    amqmfsck /var/mqm
    echo "----------------------------------------"
    MQ_DEV=${MQ_DEV:-"true"}
    if [ "${MQ_DEV}" == "true" ]; then
      # Turns on early adopt if we're using Developer defaults
      export AMQ_EXTRA_QM_STANZAS=Channels:ChlauthEarlyAdopt=Y
    fi
    crtmqm -q ${MQ_QMGR_NAME} || true
    if [ ${MQ_QMGR_CMDLEVEL+x} ]; then
      # Enables the specified command level, then stops the queue manager
      strmqm -e CMDLEVEL=${MQ_QMGR_CMDLEVEL} || true
    fi
    echo "----------------------------------------"
  fi
  strmqm ${MQ_QMGR_NAME}

  # Turn off script failing here because of listeners failing the script
  set +e
  for MQSC_FILE in $(ls -v /etc/mqm/*.mqsc); do
    runmqsc ${MQ_QMGR_NAME} < ${MQSC_FILE}
  done
  set -e

  echo "----------------------------------------"
  mq-dev-config.sh ${MQ_QMGR_NAME}
  echo "----------------------------------------"
}

state()
{
  dspmq -n -m ${MQ_QMGR_NAME} | awk -F '[()]' '{ print $4 }'
}

monitor()
{
  # Loop until "dspmq" says the queue manager is running
  until [ "`state`" == "RUNNING" ]; do
    sleep 1
  done
  dspmq

  echo "IBM MQ Queue Manager ${MQ_QMGR_NAME} is now fully running"

  # Loop until "dspmq" says the queue manager is not running any more
  until [ "`state`" != "RUNNING" ]; do
    sleep 5
  done

  # Wait until queue manager has ended before exiting
  while true; do
    STATE=`state`
    case "$STATE" in
      ENDED*) break;;
      *) ;;
    esac
    sleep 1
  done
  dspmq
}

mq-license-check.sh
parameterCheck
config
trap stop SIGTERM SIGINT
monitor
