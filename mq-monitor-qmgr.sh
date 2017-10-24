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

MQ_QMGR_NAME=$1

state()
{
  dspmq -n -m ${MQ_QMGR_NAME} | awk -F '[()]' '{ print $4 }'
}

trap "source mq-stop-container.sh" SIGTERM SIGINT

echo "Monitoring Queue Manager ${MQ_QMGR_NAME}"

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

# Check that dspmq did actually work in case something has gone seriously wrong.
dspmq > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Error: dspmq finished with a non-zero return code"
  exit 1
fi

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
