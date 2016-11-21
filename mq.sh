#!/bin/bash
# -*- mode: sh -*-
# © Copyright IBM Corporation 2015, 2016
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

config()
{
  : ${MQ_QMGR_NAME?"ERROR: You need to set the MQ_QMGR_NAME environment variable"}
  # Populate and update the contents of /var/mqm - this is needed for
	# bind-mounted volumes, and also to migrate data from previous versions of MQ
  /opt/mqm/bin/amqicdir -i -f
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
    crtmqm -q ${MQ_QMGR_NAME} || true
    if [ ${MQ_QMGR_CMDLEVEL+x} ]; then
      # Enables the specified command level, then stops the queue manager
      strmqm -e CMDLEVEL=${MQ_QMGR_CMDLEVEL} || true
    fi
    echo "----------------------------------------"
  fi
  strmqm ${MQ_QMGR_NAME}
  if [ ${QMGR_EXISTS} -ne 0 ]; then
    echo "----------------------------------------"
    if [ -f /etc/mqm/listener.mqsc ]; then
      runmqsc ${MQ_QMGR_NAME} < /etc/mqm/listener.mqsc
    fi
    if [ -f /etc/mqm/config.mqsc ]; then
      runmqsc ${MQ_QMGR_NAME} < /etc/mqm/config.mqsc
    fi
  fi
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
config
trap stop SIGTERM SIGINT
monitor
