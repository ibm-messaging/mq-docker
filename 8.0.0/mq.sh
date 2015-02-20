#!/bin/bash
# -*- mode: sh -*-
# © Copyright IBM Corporation 2015.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html


set -e

stop()
{
	endmqm $MQ_QMGR_NAME
}

config()
{
	: ${MQ_QMGR_NAME?"ERROR: You need to set the MQ_QMGR_NAME environment variable"}
	source /opt/mqm/bin/setmqenv -s
	echo "----------------------------------------"
	dspmqver
	echo "----------------------------------------"
	mqconfig || (echo -e "\nERROR: mqconfig returned a non-zero return code" 1>&2 ; exit 1)
	echo "----------------------------------------"

	QMGR_EXISTS=`dspmq | grep ${MQ_QMGR_NAME} > /dev/null ; echo $?`
	if [ ${QMGR_EXISTS} -ne 0 ]; then
		echo "Checking filesystem..."
		amqmfsck /var/mqm
		echo "----------------------------------------"
		crtmqm -q ${MQ_QMGR_NAME} || true
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
   dspmq -n | grep ${MQ_QMGR_NAME} | cut -f3 -d"("
}

monitor()
{
	# Loop until "dspmq" says the queue manager is running
	until [ "`state`" == "RUNNING)" ]; do
		sleep 1
	done
	dspmq

	# Loop until "dspmq" says the queue manager is not running any more
	until [ "`state`" != "RUNNING)" ]; do
		sleep 5
	done

	until [[ "`state`" =~ ".*(ENDED.*" ]]; do
		sleep 1
	done
	dspmq
}

mq-license-check.sh
# If /var/mqm is empty (because it's mounted from a new host volume), then populate it
if [ ! "$(ls -A /var/mqm)" ]; then
	/opt/mqm/bin/amqicdir -i -f
fi
config
trap stop SIGTERM SIGINT
monitor
