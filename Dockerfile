#
# This docker image is just for development and testing purpose - please do NOT use on production
#

# Pull Base Image
FROM zhicwu/java:8

# Set Maintainer Details
MAINTAINER Zhichun Wu <zhicwu@gmail.com>

# Set Environment Variables
ENV BISERVER_VERSION=6.1 BISERVER_BUILD=6.1.0.1-196 BISERVER_HOME=/biserver-ce \
	APACHE_BASE_URL=http://www.apache.org/dyn/closer.lua?action=download&filename= \
	MAVEN_BASE_URL=http://central.maven.org/maven2 \
	MYSQL_DRIVER_VERSION=5.1.39 PRESTO_DRIVER_VERSION=0.148 \
	DRILL_DIRVER_VERSION=1.6.0 JTDS_VERSION=1.3.1 \
	CASSANDRA_DRIVER_VERSION=0.6.1 XMLA_PROVIDER_VERSION=1.0.0.103

# Download Pentaho BI Server Community Edition
RUN wget --progress=dot:giga http://downloads.sourceforge.net/project/pentaho/Business%20Intelligence%20Server/${BISERVER_VERSION}/biserver-ce-${BISERVER_BUILD}.zip

# Unpack BI Server 
RUN unzip -q *.zip && rm -f *.zip

# Download Patches / Plugins
# Audit: https://github.com/it4biz/pentaho-ce-audit/releases/download/2016.05.19/pentaho-ce-audit-2016.05.19.zip \
# CLP: http://www.webdetails.pt/ficheiros/CLP/CLP-15.10.21.zip \
# CST: http://ctools.pentaho.com/files/cst/16.04.06/cst-16.04.06.zip \
# FusionCharts: http://www.xpand-it.com/images/files/fusioncharts/fusion_plugin-4.1.1.zip \
# Performance: http://downloads.sourceforge.net/project/pentaho-performance-monitoring/1.0/pentaho-performance-monitoring-2015.02.06-TRUNK.zip
# Pivot4J: http://ci.greencatsoft.com/job/Pivot4J/397/artifact/pivot4j-pentaho/target/pivot4j-pentaho-1.0-SNAPSHOT-plugin.zip \
# Repo Sync: http://ctools.pentaho.com/files/repositorySynchronizer/15.10.21/repositorySynchronizer-15.10.21.zip \
# Tapa: https://github.com/marpontes/tapa/releases/download/v0.3.1/tapa-0.3.1-pentaho6.zip \
# WAQR: http://ci.pentaho.com/job/WAQR-Plugin/lastSuccessfulBuild/artifact/dist/waqr-plugin-package-TRUNK-SNAPSHOT.zip \
RUN wget -P $BISERVER_HOME/tomcat/webapps/pentaho/WEB-INF/lib http://meteorite.bi/downloads/saiku-olap-util-3.7-SNAPSHOT.jar \
	&& wget -O btable.zip http://sourceforge.net/projects/btable/files/Version2.1/BTable-pentaho5-STABLE-2.1.zip/download \
	&& wget -O saiku-chart-plus.zip http://sourceforge.net/projects/saikuchartplus/files/SaikuChartPlus3/saiku-chart-plus-vSaiku3-plugin-pentaho.zip/download \
	&& wget --progress=dot:giga http://meteorite.bi/downloads/saiku-plugin-p6-3.8.8.zip \
		http://ci.pentaho.com/job/webdetails-cte/lastSuccessfulBuild/artifact/dist/cte-6.0-SNAPSHOT.zip \
		http://ctools.pentaho.com/files/d3ComponentLibrary/14.06.18/d3ComponentLibrary-14.06.18.zip \
		https://github.com/rpbouman/pash/raw/master/bin/pash.zip

WORKDIR $BISERVER_HOME

# Add More JDBC Drivers and XMLA Connector
RUN wget --progress=dot:giga http://central.maven.org/maven2/com/facebook/presto/presto-jdbc/${PRESTO_DRIVER_VERSION}/presto-jdbc-${PRESTO_DRIVER_VERSION}.jar \
		http://central.maven.org/maven2/mysql/mysql-connector-java/${MYSQL_DRIVER_VERSION}/mysql-connector-java-${MYSQL_DRIVER_VERSION}.jar \
		http://central.maven.org/maven2/net/sourceforge/jtds/jtds/${JTDS_VERSION}/jtds-${JTDS_VERSION}.jar \
		http://central.maven.org/maven2/com/github/zhicwu/cassandra-jdbc-driver/${CASSANDRA_DRIVER_VERSION}/cassandra-jdbc-driver-${CASSANDRA_DRIVER_VERSION}-shaded.jar \
		"http://www.apache.org/dyn/closer.lua?action=download&filename=/drill/drill-${DRILL_DIRVER_VERSION}/apache-drill-${DRILL_DIRVER_VERSION}.tar.gz" \
	&& wget --progress=dot:giga -O tomcat/webapps/pentaho/docs/xmla-connector.exe https://sourceforge.net/projects/xmlaconnect/files/XMLA_Provider_v${XMLA_PROVIDER_VERSION}.exe/download \
	&& rm -f tomcat/lib/mysql*.jar tomcat/lib/jtds*.jar \
	&& tar zxf *.tar.gz \
	&& mv *.jar apache-drill*/jars/jdbc-driver/*.jar tomcat/lib/. \
	&& rm -rf apache-drill* *.tar.gz

# Configure BI Server, Remove External References and Patch Saiku Plugin
RUN find $BISERVER_HOME -name "*.bat" -delete && mkdir -p ext \
	&& for i in /*.zip; do echo "Unpacking $i..." && unzip -q -d pentaho-solutions/system $i && rm -f $i; done \
	&& sed -i -e 's|\( class="bannercontent">.*\)\(<br /></td>\)|\1<br />To access OLAP cube via Excel/SharePoint, please install <a href="xmla-connector.exe">XMLA Connector</a> from <a href="http://www.arquery.com">Arquery</a>.\2|' tomcat/webapps/pentaho/docs/InformationMap.jsp \
	&& touch pentaho-solutions/system/saiku/ui/js/saiku/plugins/CCC_Chart/cdo.js \
	&& wget -P pentaho-solutions/system/saiku/components/saikuWidget https://github.com/OSBI/saiku/raw/release-3.8/saiku-bi-platform-plugin-p5/src/main/plugin/components/saikuWidget/SaikuWidgetComponent.js \
	&& sed -i -e "s|\(: data.query.queryModel.axes.FILTER\)\(.*\)|\1 == undefined ? [] \1\2|" pentaho-solutions/system/saiku/ui/js/saiku/embed/SaikuEmbed.js \
	&& sed -i -e "s|\(: data.query.queryModel.axes.COLUMNS\)\(.*\)|\1 == undefined ? [] \1\2|" pentaho-solutions/system/saiku/ui/js/saiku/embed/SaikuEmbed.js \
	&& sed -i -e "s|\(: data.query.queryModel.axes.ROWS\)\(.*\)|\1 == undefined ? [] \1\2|" pentaho-solutions/system/saiku/ui/js/saiku/embed/SaikuEmbed.js \
	&& sed -i -e 's|\(var query = Saiku.tabs._tabs\[0\].content.query;\)|\1\nif (query == undefined ) query = Saiku.tabs._tabs[1].content.query;|' pentaho-solutions/system/saiku/ui/js/saiku/plugins/BIServer/plugin.js \
	&& sed -i -e 's|\(CATALINA_OPTS="\)\(.*\)|# http://wiki.apache.org/tomcat/HowTo/FasterStartUp#Entropy_Source\n\1-Djava.security.egd=file:/dev/./urandom \2|' start-pentaho.sh \
	&& sed -i -e 's/\(exec ".*"\) start/\1 run/' tomcat/bin/startup.sh \
	&& rm -f promptuser.* *.zip.* pentaho-solutions/system/default-content/* \
	&& sed -i -e 's|\(<max-act-conn>\).*\(</max-act-conn>\)|\150\2|' pentaho-solutions/system/pentaho.xml \
	&& sed -i -e 's|\(<login-show-users-list>\).*\(</login-show-users-list>\)|\1false\2|' pentaho-solutions/system/pentaho.xml \
	&& sed -i -e 's|\(<login-show-sample-users-hint>\).*\(</login-show-sample-users-hint>\)|\1false\2|' pentaho-solutions/system/pentaho.xml \
	&& sed -i -e 's|\(<filebased-solution-cache>\).*\(</filebased-solution-cache>\)| -->\1true\2<!-- |' pentaho-solutions/system/pentaho.xml \
	&& sed -i -e 's|\(<entry key="jpeg" value-ref="streamConverter"/>\)|\1<entry key="saiku" value-ref="streamConverter"/>|' pentaho-solutions/system/importExport.xml \
	&& sed -i -e 's|\(<value>.xcdf</value>\)|\1<value>.saiku</value>|' pentaho-solutions/system/importExport.xml \
	&& sed -i -e 's|\(<value>xcdf</value>\)|\1<value>saiku</value>|' pentaho-solutions/system/importExport.xml \
	&& sed -i -e 's|\(<extension>xcdf</extension>\)|\1<extension>saiku</extension>|' pentaho-solutions/system/ImportHandlerMimeTypeDefinitions.xml \
	&& sed -i -e 's|\(\A/logout.*\Z=Anonymous\)|\1\n\A/plugin/cda/api/clearCache.*\Z=Authenticated\n\\A/plugin/saiku/api/admin/discover/refresh.*\\Z=Authenticated|' pentaho-solutions/system/applicationContext-spring-security.xml \
	&& sed -i -e 's|\(<import resource="GettingStartedDB-spring.xml" />\).*|<!-- \1 -->|' pentaho-solutions/system/pentaho-spring-beans.xml \
	&& sed -i -e "s|<script language='JavaScript' type='text/javascript' src='.*brightcove.com.*'></script>||" tomcat/webapps/pentaho/mantle/home/index.jsp \
	&& sed -i -e "s|script.src = '.*brightcove.*';||" tomcat/webapps/pentaho/mantle/home/content/getting_started_launch.html \
	&& sed -i -e 's|"<script.*brightcove.*script>";|"";|' tomcat/webapps/pentaho/mantle/home/js/gettingStarted.js \
	&& sed -i -e 's|\(<util:map id="defaultUserRoleMappings">\)|\1<!-- |' pentaho-solutions/system/defaultUser.spring.xml \
	&& sed -i -e 's|\(<entry key-ref="singleTenantAdminUserName">\)| -->\1|' pentaho-solutions/system/defaultUser.spring.xml \
	&& find . -name "*.css" | xargs sed -i -e 's|http.*googleusercontent\.com||' \
	&& rm -f pentaho-solutions/system/BTable/resources/datasources/*.cda \
	&& find . -name *ga.js | xargs sed -i -e 's|//www\.google\-analytics\.com||' \
	&& find . -name *ga.js | xargs sed -i -e 's|\?"https\://ssl"\:"http\://www"|?"/":"/"|' \
	&& sed -i -e 's|self.template()|"Error!"|' pentaho-solutions/system/saiku/ui/saiku.min.js \
	&& sed -i -e 's|http://meteorite.bi/|/|' pentaho-solutions/system/saiku/ui/saiku.min.js

# Compile and Install Tomcat Native Lib
RUN apt-get update \
	&& apt-get install -y libapr1-dev libssl-dev gcc make \
	&& tar zxvf tomcat/bin/tomcat-native.tar.gz \
	&& cd tomcat-native*/native \
	&& ./configure --with-apr=/usr/bin/apr-config --disable-openssl --with-java-home=$JAVA_HOME --prefix=$BISERVER_HOME/tomcat \
	&& make \
	&& make install \
	&& cd ../.. \
	&& rm -rf tomcat-native* \
	&& rm -rf /var/lib/apt/lists/*

VOLUME ["$BISERVER_HOME/ext", "$BISERVER_HOME/tomcat/logs"]

COPY docker-entrypoint.sh $BISERVER_HOME/docker-entrypoint.sh
RUN chmod +x *.sh
ENTRYPOINT ["./docker-entrypoint.sh"]

#  8080 - HTTP
#  8009 - AJP
# 11098 - JMX RMI Registry
# 44444 - RMI Server
EXPOSE 8080 8009 11098 44444

CMD ["biserver"]
