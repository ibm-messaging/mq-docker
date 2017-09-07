#!/bin/bash
# -*- mode: sh -*-
# © Copyright IBM Corporation 2017
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

configure_server_xml()
{
  local -r OUT=/tmp/webTemp/mqwebuser.xml
  echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > $OUT
  echo "<server>" >> $OUT
  echo "    <featureManager>" >> $OUT
  echo "        <feature>appSecurity-2.0</feature>" >> $OUT
  echo "        <feature>basicAuthenticationMQ-1.0</feature>" >> $OUT
  echo "    </featureManager>" >> $OUT
  echo "    <enterpriseApplication id=\"com.ibm.mq.console\">" >> $OUT
  echo "        <application-bnd>" >> $OUT
  echo "            <security-role name=\"MQWebAdmin\">" >> $OUT
  echo "                <group name=\"MQWebUI\" realm=\"defaultRealm\"/>" >> $OUT
  echo "            </security-role>" >> $OUT
  echo "        </application-bnd>" >> $OUT
  echo "    </enterpriseApplication>" >> $OUT
  echo "    <enterpriseApplication id=\"com.ibm.mq.rest\">" >> $OUT
  echo "        <application-bnd>" >> $OUT
  echo "            <security-role name=\"MQWebAdmin\">" >> $OUT
  echo "                <group name=\"MQWebUI\" realm=\"defaultRealm\"/>" >> $OUT
  echo "            </security-role>" >> $OUT
  echo "        </application-bnd>" >> $OUT
  echo "    </enterpriseApplication>" >> $OUT
  echo "    <basicRegistry id=\"basic\" realm=\"defaultRealm\">" >> $OUT
  echo "        <user name=\"${MQ_ADMIN_NAME}\" password=\"${MQ_ADMIN_PASSWORD}\"/>" >> $OUT
  echo "        <group name=\"MQWebUI\">" >>$OUT
  echo "            <member name=\"${MQ_ADMIN_NAME}\"/>" >>$OUT
  echo "        </group>" >> $OUT
  echo "    </basicRegistry>" >> $OUT
  echo "    <variable name=\"httpHost\" value=\"*\"/>" >> $OUT
  echo "    <httpDispatcher enableWelcomePage=\"false\" appOrContextRootMissingMessage='Redirecting to console.&lt;script&gt;document.location.href=\"/ibmmq/console\";&lt;/script&gt;' />" >> $OUT
  if [ ! -z ${MQ_TLS_KEYSTORE+x} ]; then
    #Need to grab the TLS keystore and sort it out...
    if [ ! -e ${MQ_TLS_KEYSTORE} ]; then
      echo "Error: The keystore '${MQ_TLS_KEYSTORE}' referenced in MQ_TLS_KEYSTORE does not exist"
      exit 1
    fi

    #create keystore
    if [ ! -e "/tmp/webTemp/key.jks" ]; then
      #Keystore does not exists
      runmqckm -keydb -create -db /tmp/webTemp/key.jks -type jks -pw ${MQ_TLS_PASSPHRASE}
    fi

    #create trust store
    if [ ! -e "/tmp/webTemp/trust.jks" ]; then
      #Keystore does not exists
      runmqckm -keydb -create -db /tmp/webTemp/trust.jks -type jks -pw ${MQ_TLS_PASSPHRASE}
    fi

    #Find certificate to rename it to something MQ can use
    CERT=`runmqakm -cert -list -db "${MQ_TLS_KEYSTORE}" -pw "${MQ_TLS_PASSPHRASE}" | egrep -m 1 "^\\**-"`
    CERTL=`echo ${CERT} | sed -e s/^\\**-//`
    CERTL=${CERTL:1}

    echo "We will use certificate with label '${CERTL}' for the Web Server"

    runmqakm -keydb -create -db "/tmp/webTemp/key.kdb" -type cms -pw ${MQ_TLS_PASSPHRASE}
    runmqakm -cert -import -file "${MQ_TLS_KEYSTORE}" -pw "${MQ_TLS_PASSPHRASE}" -target "/tmp/webTemp/key.kdb" -target_pw ${MQ_TLS_PASSPHRASE}
    runmqakm -cert -rename -db "/tmp/webTemp/key.kdb" -pw ${MQ_TLS_PASSPHRASE} -label ${CERTL} -new_label webcert

    #Import certificate
    runmqckm -cert -import -db "/tmp/webTemp/key.kdb" -pw "${MQ_TLS_PASSPHRASE}" -target "/tmp/webTemp/key.jks" -target_pw ${MQ_TLS_PASSPHRASE}

    runmqckm -cert -list -db "/tmp/webTemp/key.jks" -pw "${MQ_TLS_PASSPHRASE}"

    echo "<keyStore id=\"MQWebKeyStore\" location=\"${DATA_PATH}/web/installations/${MQ_INSTALLATION}/servers/mqweb/key.jks\" type=\"JKS\" password=\"${MQ_TLS_PASSPHRASE}\"/>" >> $OUT
    echo "<keyStore id=\"MQWebTrustStore\" location=\"${DATA_PATH}/web/installations/${MQ_INSTALLATION}/servers/mqweb/trust.jks\" type=\"JKS\" password=\"${MQ_TLS_PASSPHRASE}\"/>" >> $OUT
    echo "<ssl id=\"thisSSLConfig\" clientAuthenticationSupported=\"true\" keyStoreRef=\"MQWebKeyStore\" trustStoreRef=\"MQWebTrustStore\" sslProtocol=\"TLSv1.2\" serverKeyAlias=\"webcert\"/>" >> $OUT
    echo "<sslDefault sslRef=\"thisSSLConfig\"/>" >> $OUT
  else
    echo "    <sslDefault sslRef=\"mqDefaultSSLConfig\"/>" >> $OUT
  fi
  echo "</server>" >> $OUT

  # Now actually copy the file(s) over
  chown -R mqm:mqm /tmp/webTemp
  su -c "cp -PTv /tmp/webTemp/mqwebuser.xml ${DATA_PATH}/web/installations/${MQ_INSTALLATION}/servers/mqweb/mqwebuser.xml" -l mqm

  if [ ! -z ${MQ_TLS_KEYSTORE+x} ]; then
    chmod 640 /tmp/webTemp/key.*
    chmod 640 /tmp/webTemp/trust.*
    su -c "cp -PTv /tmp/webTemp/key.jks ${DATA_PATH}/web/installations/${MQ_INSTALLATION}/servers/mqweb/key.jks" -l mqm
    su -c "cp -PTv /tmp/webTemp/trust.jks ${DATA_PATH}/web/installations/${MQ_INSTALLATION}/servers/mqweb/trust.jks" -l mqm
  fi

}

if [ -z ${MQ_DISABLE_WEB_CONSOLE+x} ]; then
  echo "Starting MQ Console"

  MQ_INSTALLATION=`dspmqver -b -f 512`
  DATA_PATH=`dspmqver -b -f 4096`
  MQ_ADMIN_NAME="admin"
  MQ_ADMIN_PASSWORD=${MQ_ADMIN_PASSWORD:-"passw0rd"}

  if [ ! -e "/tmp/webTemp" ]; then
    mkdir -p /tmp/webTemp
    chown mqm:mqm /tmp/webTemp

    configure_server_xml
  else
    echo "Using existing Web Server configuration."
  fi

  if [ ! -e "${DATA_PATH}/web/installations/${MQ_INSTALLATION}/angular.persistence/admin.json" ]; then
    sed -i "s/<QM>/${MQ_QMGR_NAME}/g" /etc/mqm/admin.json
    chown mqm:mqm /etc/mqm/admin.json
    chmod 640 /etc/mqm/admin.json
    su -c "mkdir -p ${DATA_PATH}/web/installations/${MQ_INSTALLATION}/angular.persistence" -l mqm
    su -c "cp -PTv /etc/mqm/admin.json ${DATA_PATH}/web/installations/${MQ_INSTALLATION}/angular.persistence/admin.json" -l mqm
  fi

  #Run the server as mqm
  su -l mqm -c "bash strmqweb &"
  echo "MQ Console started"

  # Print out the connection info
  IPADDR="$(hostname -I | sed -e 's/[[:space:]]*$//')"
  echo connect to \"https://$IPADDR:9443/ibmmq/console/\"
else
  # don't do anything
  echo Skipping Web Console startup due to MQ_DISABLE_WEB_CONSOLE environment variable
fi
