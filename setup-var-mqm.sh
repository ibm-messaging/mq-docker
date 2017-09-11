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
#
# First we check whether the directory /var/mqm exists. If it does, we do nothing
# Then we check whether /var/mqm is a symlink. If it is we don't do anything
# If /var/mqm does not exist then we try to find the default Bluemix mount and
# mount it. Otherwise we give up and just create /var/mqm
if [ -d "/var/mqm/qmgrs" ]; then
  # User is probably following old instructions to mount a volume into /var/mqm
  echo "Using existing MQ Data under /var/mqm"
  /opt/mqm/bin/crtmqdir -a -f
else
  if [ -L "/var/mqm" ]; then
    echo "/var/mqm is already a symlink."
    /opt/mqm/bin/crtmqdir -a -f
  else
    if [ -d "/mnt/mqm/" ]; then
      DATA_DIR=/mnt/mqm/data
      MOUNT_DIR=/mnt/mqm
      echo "Symlinking /var/mqm to $DATA_DIR"

      # Add mqm to the root user group and add group permissions to mount directory
      usermod -aG root mqm
      chmod 775 ${MOUNT_DIR}

      if [ ! -e ${DATA_DIR} ]; then
        mkdir -p ${DATA_DIR}
        chown mqm:mqm ${DATA_DIR}
        chmod 775 ${DATA_DIR}
      fi

      /opt/mqm/bin/crtmqdir -a -f
      su -c "cp -RTnv /var/mqm /mnt/mqm/data" -l mqm

      # Remove /var/mqm and replace with a symlink
      rm -rf /var/mqm
      ln -s ${DATA_DIR} /var/mqm
      chown -h mqm:mqm /var/mqm
    else
      # Create the MQ data Directory
      /opt/mqm/bin/crtmqdir -a -f
    fi
  fi
fi
