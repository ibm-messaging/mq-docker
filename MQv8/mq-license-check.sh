#!/bin/bash
# -*- mode: sh -*-
# © Copyright IBM Corporation 2015.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html


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
