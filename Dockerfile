#
# Docker image for Pentaho BA server community edition.
#

# Pull base image
FROM zhicwu/java:8

# Set maintainer
MAINTAINER Zhichun Wu <zhicwu@gmail.com>

# Set environment variables
ENV BISERVER_VERSION=7.0 BISERVER_BUILD=7.0.0.0-25 PDI_PATCH=7.0.0.0.3 \
	BISERVER_HOME=/biserver-ce BISERVER_USER=pentaho \
	KETTLE_HOME=/biserver-ce/pentaho-solutions/system/kettle \
	JNA_VERSION=4.2.2 OSHI_VERSION=3.2 POSTGRESQL_DRIVER_VERSION=9.4.1212 \
	MYSQL_DRIVER_VERSION=5.1.41 JTDS_VERSION=1.3.1 CASSANDRA_DRIVER_VERSION=0.6.3 \
	H2DB_VERSION=1.4.193 HSQLDB_VERSION=2.3.4 XMLA_PROVIDER_VERSION=1.0.0.103

# Set label
LABEL java_server="Pentaho BA Server $BISERVER_VERSION Community Edition"

# Install vanilla Pentaho server along with minor changes to configuration
RUN echo "Download and unpack Pentaho server..." \
	&& wget --progress=dot:giga http://downloads.sourceforge.net/project/pentaho/Business%20Intelligence%20Server/${BISERVER_VERSION}/pentaho-server-ce-${BISERVER_BUILD}.zip \
	&& unzip -q *.zip \
	&& rm -f *.zip \
	&& mv /pentaho-server $BISERVER_HOME \
	&& ln -s $BISERVER_HOME /pentaho-server \
	&& find $BISERVER_HOME -name "*.bat" -delete \
	&& find $BISERVER_HOME -name "*.exe" -delete \
	&& mkdir -p $BISERVER_HOME/data/.hsqldb \
	&& /bin/cp -rf $BISERVER_HOME/data/hsqldb/* $BISERVER_HOME/data/.hsqldb/. \
	&& echo "Install APR for Tomcat..." \
		&& tar zxf $BISERVER_HOME/tomcat/bin/tomcat-native.tar.gz \
		&& cd tomcat-native*/native \
		&& apt-get update \
		&& apt-get install -y libjna-java libapr1-dev gcc make \
		&& ./configure --with-apr=/usr/bin/apr-config --disable-openssl --with-java-home=$JAVA_HOME --prefix=$BISERVER_HOME/tomcat \
		&& make \
		&& make install \
		&& sed -i -e 's|\(SSLEngine="\).*\("\)|\1off\2|' $BISERVER_HOME/tomcat/conf/server.xml \
		&& cd / \
		&& rm -rf tomcat-native* $BISERVER_HOME/tomcat/bin/tomcat-native.tar.gz \
		&& apt-get autoremove -y libapr1-dev gcc make \
		&& apt-get clean \
		&& rm -rf /var/lib/apt/lists/* \
	&& echo "Update server configuration..." \
		&& cd $BISERVER_HOME \
		&& sed -i -e 's/\(exec ".*"\) start/\1 run/' tomcat/bin/startup.sh \
		&& rm -f promptuser.* pentaho-solutions/system/default-content/* \
		&& sed -i -e 's|\(      <MimeTypeDefinition mimeType="application/vnd.ms-excel">\)|      <MimeTypeDefinition mimeType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet">\n        <extension>xlsx</extension>\n      </MimeTypeDefinition>\n\1|' pentaho-solutions/system/ImportHandlerMimeTypeDefinitions.xml \
		&& sed -i -e 's|\(      <MimeTypeDefinition mimeType="application/vnd.ms-excel">\)|      <MimeTypeDefinition mimeType="application/vnd.openxmlformats-officedocument.spreadsheetml.template">\n        <extension>xltx</extension>\n      </MimeTypeDefinition>\n\1|' pentaho-solutions/system/ImportHandlerMimeTypeDefinitions.xml \
		&& sed -i -e 's|\(      <MimeTypeDefinition mimeType="application/vnd.ms-excel">\)|      <MimeTypeDefinition mimeType="application/vnd.ms-excel.sheet.macroEnabled.12">\n        <extension>xlsm</extension>\n      </MimeTypeDefinition>\n\1|' pentaho-solutions/system/ImportHandlerMimeTypeDefinitions.xml \
		&& sed -i -e 's|\(      <MimeTypeDefinition mimeType="application/vnd.ms-excel">\)|      <MimeTypeDefinition mimeType="application/vnd.ms-excel.template.macroEnabled.12">\n        <extension>xltm</extension>\n      </MimeTypeDefinition>\n\1|' pentaho-solutions/system/ImportHandlerMimeTypeDefinitions.xml \
		&& sed -i -e 's|\(      <MimeTypeDefinition mimeType="application/vnd.ms-excel">\)|      <MimeTypeDefinition mimeType="application/vnd.ms-excel.addin.macroEnabled.12">\n        <extension>xlam</extension>\n      </MimeTypeDefinition>\n\1|' pentaho-solutions/system/ImportHandlerMimeTypeDefinitions.xml \
		&& sed -i -e 's|\(      <MimeTypeDefinition mimeType="application/vnd.ms-excel">\)|      <MimeTypeDefinition mimeType="application/vnd.ms-excel.sheet.binary.macroEnabled.12">\n        <extension>xlsb</extension>\n      </MimeTypeDefinition>\n\1|' pentaho-solutions/system/ImportHandlerMimeTypeDefinitions.xml \
		&& sed -i -e 's|\(        <extension>xls</extension>\)|\1\n        <extension>xlt</extension>\n        <extension>xla</extension>|' pentaho-solutions/system/ImportHandlerMimeTypeDefinitions.xml \
		&& sed -i -e 's|\(        <extension>sql</extension>\)|\1\n        <extension>txt</extension>\n        <extension>csv</extension>|' pentaho-solutions/system/ImportHandlerMimeTypeDefinitions.xml \
		&& sed -i -e 's|\(,csv,\)|\1sql,|' pentaho-solutions/system/*.xml \
		&& sed -i -e 's|\(,xlsx,\)|\1xltx,xlsm,xltm,xlam,xlsb,|' pentaho-solutions/system/*.xml \
	&& echo "Add Pentaho user..." \
		&& useradd -md $BISERVER_HOME -s /bin/bash $BISERVER_USER

# Change work directory
WORKDIR $BISERVER_HOME

# Add latest JDBC drivers and XMLA connector
RUN echo "Download and install JDBC drivers..." \
	&& wget --progress=dot:giga https://jdbc.postgresql.org/download/postgresql-${POSTGRESQL_DRIVER_VERSION}.jar \
			http://central.maven.org/maven2/mysql/mysql-connector-java/${MYSQL_DRIVER_VERSION}/mysql-connector-java-${MYSQL_DRIVER_VERSION}.jar \
			http://central.maven.org/maven2/net/sourceforge/jtds/jtds/${JTDS_VERSION}/jtds-${JTDS_VERSION}.jar \
			http://central.maven.org/maven2/com/github/zhicwu/cassandra-jdbc-driver/${CASSANDRA_DRIVER_VERSION}/cassandra-jdbc-driver-${CASSANDRA_DRIVER_VERSION}-shaded.jar \
			http://central.maven.org/maven2/com/h2database/h2/${H2DB_VERSION}/h2-${H2DB_VERSION}.jar \
			http://central.maven.org/maven2/org/hsqldb/hsqldb/${HSQLDB_VERSION}/hsqldb-${HSQLDB_VERSION}.jar \
	&& wget --progress=dot:giga  -O tomcat/webapps/pentaho/docs/xmla-connector.exe https://sourceforge.net/projects/xmlaconnect/files/XMLA_Provider_v${XMLA_PROVIDER_VERSION}.exe/download \
	&& sed -i -e 's|\( class="bannercontent">.*\)\(<br /></td>\)|\1<br />To access OLAP cube via Excel/SharePoint, please install <a href="xmla-connector.exe">XMLA Connector</a> from <a href="http://www.arquery.com">Arquery</a>.\2|' tomcat/webapps/pentaho/docs/InformationMap.jsp \
	&& rm -f tomcat/lib/postgre*.jar tomcat/lib/mysql*.jar tomcat/lib/jtds*.jar tomcat/lib/h2*.jar tomcat/lib/hsqldb*.jar \
	&& mv *.jar $BISERVER_HOME/tomcat/lib/.

# Install plugins
RUN echo "Download plugins..." \
	&& wget -P $BISERVER_HOME/tomcat/webapps/pentaho/WEB-INF/lib https://github.com/zhicwu/saiku/releases/download/3.8.8-SNAPSHOT/saiku-olap-util-3.8.8.jar \
	&& wget -O btable.zip https://sourceforge.net/projects/btable/files/Version3.0-3.6/BTable-pentaho7-3.6-STABLE.zip/download \
	&& wget -O saiku-chart-plus.zip http://sourceforge.net/projects/saikuchartplus/files/SaikuChartPlus3/saiku-chart-plus-vSaiku3-plugin-pentaho.zip/download \
	&& wget -O jamon.zip https://sourceforge.net/projects/jamonapi/files/jamonapi/v2_81/jamonall-2.81.zip/download \
	&& wget --progress=dot:giga https://github.com/zhicwu/saiku/releases/download/3.8.8-SNAPSHOT/saiku-plugin-p6-3.8.8.zip \
			https://github.com/zhicwu/cte/releases/download/7.0-SNAPSHOT/cte-7.0-snapshot.zip \
			http://ctools.pentaho.com/files/d3ComponentLibrary/14.06.18/d3ComponentLibrary-14.06.18.zip \
			https://github.com/rpbouman/pash/raw/master/bin/pash.zip \
	&& echo "Installing plugins..." \
		&& for i in *.zip; do echo "Unpacking $i..." && unzip -q -d pentaho-solutions/system $i && rm -f $i; done \
		&& rm -f pentaho-solutions/system/BTable/resources/datasources/*.cda \
	&& echo "Update configuration..." \
		&& sed -i -e 's|\(<entry key="jpeg" value-ref="streamConverter"/>\)|\1<entry key="saiku" value-ref="streamConverter"/>|' pentaho-solutions/system/importExport.xml \
		&& sed -i -e 's|\(<value>.xcdf</value>\)|\1<value>.saiku</value>|' pentaho-solutions/system/importExport.xml \
		&& sed -i -e 's|\(<value>xcdf</value>\)|\1<value>saiku</value>|' pentaho-solutions/system/importExport.xml \
		&& sed -i -e 's|\(<extension>xcdf</extension>\)|\1<extension>saiku</extension>|' pentaho-solutions/system/ImportHandlerMimeTypeDefinitions.xml \
		&& touch pentaho-solutions/system/saiku/ui/js/saiku/plugins/CCC_Chart/cdo.js \
		&& wget -P pentaho-solutions/system/saiku/components/saikuWidget https://github.com/OSBI/saiku/raw/release-3.8/saiku-bi-platform-plugin-p5/src/main/plugin/components/saikuWidget/SaikuWidgetComponent.js \
		&& sed -i -e "s|\(: data.query.queryModel.axes.FILTER\)\(.*\)|\1 == undefined ? [] \1\2|" pentaho-solutions/system/saiku/ui/js/saiku/embed/SaikuEmbed.js \
		&& sed -i -e "s|\(: data.query.queryModel.axes.COLUMNS\)\(.*\)|\1 == undefined ? [] \1\2|" pentaho-solutions/system/saiku/ui/js/saiku/embed/SaikuEmbed.js \
		&& sed -i -e "s|\(: data.query.queryModel.axes.ROWS\)\(.*\)|\1 == undefined ? [] \1\2|" pentaho-solutions/system/saiku/ui/js/saiku/embed/SaikuEmbed.js \
		&& sed -i -e 's|\(var query = Saiku.tabs._tabs\[0\].content.query;\)|\1\nif (query == undefined ) query = Saiku.tabs._tabs[1].content.query;|' pentaho-solutions/system/saiku/ui/js/saiku/plugins/BIServer/plugin.js \
		&& sed -i -e 's|self.template()|"Error!"|' pentaho-solutions/system/saiku/ui/saiku.min.js \
		&& sed -i -e 's|http://meteorite.bi/|/|' pentaho-solutions/system/saiku/ui/saiku.min.js \
		&& sed -i -e "s|\(request.setRequestHeader('Authorization', auth);\)|// \1|" pentaho-solutions/system/saiku/ui/js/saiku/embed/SaikuEmbed.js \
	&& echo "Enable JAMon API..." \
		&& mv pentaho-solutions/system/jamonall-2.81/jamon-2.81.jar tomcat/lib/. \
		&& unzip -q -d tomcat/webapps/jamon pentaho-solutions/system/jamonall-2.81/jamon.war \
		&& rm -rf pentaho-solutions/system/__MACOSX tomcat/webapps/jamon/WEB-INF/lib/hsqldb.jar *.zip \
		&& rm -rf pentaho-solutions/system/jamonall* \
		&& sed -i -e 's|\(<Engine name="Catalina" defaultHost="localhost">\)|\1\n      <Valve className="com.jamonapi.http.JAMonTomcatValve"/>|' tomcat/conf/server.xml

# Download patches and dependencies
RUN echo "Download patches and dependencies..." \
	&& wget https://maven.java.net/content/repositories/releases/net/java/dev/jna/jna/$JNA_VERSION/jna-$JNA_VERSION.jar \
			https://maven.java.net/content/repositories/releases/net/java/dev/jna/jna-platform/$JNA_VERSION/jna-platform-$JNA_VERSION.jar \
			http://central.maven.org/maven2/com/github/dblock/oshi-core/$OSHI_VERSION/oshi-core-$OSHI_VERSION.jar \
	&& mv *.jar tomcat/webapps/pentaho/WEB-INF/lib/. \
	&& wget --progress=dot:giga https://github.com/zhicwu/pdi-cluster/releases/download/${PDI_PATCH}/pentaho-kettle-${PDI_PATCH}.jar \
			https://github.com/zhicwu/pdi-cluster/releases/download/${PDI_PATCH}/pentaho-platform-${PDI_PATCH}.jar

# Add entry point, tempaltes and cron jobs
COPY docker-entrypoint.sh $BISERVER_HOME/docker-entrypoint.sh
COPY repository.xml.template $BISERVER_HOME/pentaho-solutions/system/jackrabbit/repository.xml.template
COPY purge-old-files.sh /etc/cron.hourly/purge-old-files

# Post configuration
RUN echo "Post configuration..." \
	&& chmod 0700 /etc/cron.hourly/* \
	&& chmod +x $BISERVER_HOME/*.sh

ENTRYPOINT ["/sbin/my_init", "--", "./docker-entrypoint.sh"]

#VOLUME ["$BISERVER_HOME/.pentaho", "$BISERVER_HOME/data/hsqldb", "$BISERVER_HOME/tomcat/logs", "$BISERVER_HOME/pentaho-solutions/system/jackrabbit/repository", "$BISERVER_HOME/tmp"]

#  8080 - HTTP
#  8009 - AJP
# 11098 - JMX RMI Registry
# 44444 - RMI Server
#EXPOSE 8080 8009 11098 44444

#CMD ["biserver"]
