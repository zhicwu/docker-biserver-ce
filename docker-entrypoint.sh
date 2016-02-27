#!/bin/bash
set -e

# first arg is `-f` or `--some-option`
if [ "${1:0:1}" = '-' ]; then
	set -- biserver "$@"
fi

if [ "$1" = 'biserver' ]; then
	# you can mount a volume pointing to /biserver/ext for customization
	if [ -d ext ]; then
		# if you have custom scripts to run, let's do it
		if [ -f ext/custom_install.sh ]; then
			. ext/custom_install.sh
		# otherwise, simply override files based what we have under ext directory
		else
			/bin/cp -rf ext/* .
		fi
	fi

	# update configuration based on environment variables
	sed -i -e 's|\(fully-qualified-server-url=\).*|\1'"$BISERVER_URL"'|' pentaho-solutions/system/server.properties
	sed -i -e 's|\(locale-language=\).*|\1'"$LOCAL_LANGUAGE"'|' pentaho-solutions/system/server.properties
	sed -i -e 's|\(locale-country=\).*|\1'"$LOCAL_COUNTRY"'|' pentaho-solutions/system/server.properties

	# now start the bi server
	./start-pentaho.sh
fi

exec "$@"
