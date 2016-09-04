#!/bin/bash
#
# This is a sample script demonstrating how to perform custom operations before each time BI server started.
#
echo "* Installing additional files..."
/bin/cp -rf $EXT_DIR/* $BISERVER_HOME/.

echo "* Enabling URL-based authentication...\(i.e. ...?userid=admin&password=password\)"
sed -i -e 's/\(requestParameterAuthenticationEnabled=\).*/\1true/' $BISERVER_HOME/pentaho-solutions/system/security.properties

#echo "* Removing external URL references..."
#find $BISERVER_HOME -name "*.js" | xargs sed -i -e "s|loadJS('https://www.google.com/jsapi');||"
#find $BISERVER_HOME -name "*.js" | xargs sed -i -e 's|loadJS("../saiku-chart-plus/js/google.js");||'
#find $BISERVER_HOME -name "*.js" | xargs sed -i -e "s|loadJS('http://code.highcharts.com/modules/exporting.js');||"
#find $BISERVER_HOME -name "*.html" | xargs sed -i -e 's|http://fonts.googleapis.com/|/|' || echo ""
#find $BISERVER_HOME -name "*.cdfde" | xargs sed -i -e 's|http://fonts.googleapis.com/|/|'

echo "* Setup environments..."
sed -i -e 's|\(.upgradeheader {\).*|\1 display: none;|' pentaho-solutions/system/saiku/ui/css/saiku/src/styles.css
sed -i -e 's|\( SSLEngine="\).*" |\1off" |' tomcat/conf/server.xml
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$BISERVER_HOME/tomcat/lib
export LD_LIBRARY_PATH
