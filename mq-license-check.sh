#!/bin/bash
# -*- mode: sh -*-
# © Copyright IBM Corporation 2015, 2016
#
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

if [ "$LICENSE" = "accept" ]; then
  exit 0
elif [ "$LICENSE" = "view" ]; then
  case "$LANG" in
    zh_TW*) LICENSE_FILE=Chinese_TW.txt ;;
    zh*) LICENSE_FILE=Chinese.txt ;;
    cs*) LICENSE_FILE=Czech.txt ;;
    en*) LICENSE_FILE=English.txt ;;
    fr*) LICENSE_FILE=French.txt ;;
    de*) LICENSE_FILE=German.txt ;;
    el*) LICENSE_FILE=Greek.txt ;;
    id*) LICENSE_FILE=Indonesian.txt ;;
    it*) LICENSE_FILE=Italian.txt ;;
    ja*) LICENSE_FILE=Japanese.txt ;;
    ko*) LICENSE_FILE=Korean.txt ;;
    lt*) LICENSE_FILE=Lithuanian.txt ;;
    pl*) LICENSE_FILE=Polish.txt ;;
    pt*) LICENSE_FILE=Portuguese.txt ;;
    ru*) LICENSE_FILE=Russian.txt ;;
    sl*) LICENSE_FILE=Slovenian.txt ;;
    es*) LICENSE_FILE=Spanish.txt ;;
    tr*) LICENSE_FILE=Turkish.txt ;;
    *) LICENSE_FILE=English.txt ;;
  esac
  cat /opt/mqm/licenses/$LICENSE_FILE
  exit 1
else
  echo -e "Set environment variable LICENSE=accept to indicate acceptance of license terms and conditions.\n\nLicense agreements and information can be viewed by running this image with the environment variable LICENSE=view.  You can also set the LANG environment variable to view the license in a different language."
  exit 1
fi
