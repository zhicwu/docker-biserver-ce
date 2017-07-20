#
# Docker image for Pentaho Server Community Edition.
#

# Pull base image
FROM zhicwu/biserver-ce:7.1-base

# Set maintainer
MAINTAINER Zhichun Wu <zhicwu@gmail.com>

# Set environment variables
ENV POSTGRESQL_DRIVER_VERSION=42.1.3 MYSQL_DRIVER_VERSION=5.1.42 \
	JTDS_VERSION=1.3.1 CASSANDRA_DRIVER_VERSION=0.6.4 \
	H2DB_VERSION=1.4.196 HSQLDB_VERSION=2.4.0 XMLA_PROVIDER_VERSION=1.0.0.103 \
	JMX_EXPORTER_VERSION=0.7 BISERVER_USER=pentaho

# Add latest JDBC drivers and XMLA connector
RUN echo "Download and install JDBC drivers..." \
	&& wget --progress=dot:giga https://jdbc.postgresql.org/download/postgresql-${POSTGRESQL_DRIVER_VERSION}.jar \
			http://central.maven.org/maven2/mysql/mysql-connector-java/${MYSQL_DRIVER_VERSION}/mysql-connector-java-${MYSQL_DRIVER_VERSION}.jar \
			http://central.maven.org/maven2/net/sourceforge/jtds/jtds/${JTDS_VERSION}/jtds-${JTDS_VERSION}.jar \
			http://central.maven.org/maven2/com/github/zhicwu/cassandra-jdbc-driver/${CASSANDRA_DRIVER_VERSION}/cassandra-jdbc-driver-${CASSANDRA_DRIVER_VERSION}-shaded.jar \
			http://central.maven.org/maven2/com/h2database/h2/${H2DB_VERSION}/h2-${H2DB_VERSION}.jar \
			http://central.maven.org/maven2/org/hsqldb/hsqldb/${HSQLDB_VERSION}/hsqldb-${HSQLDB_VERSION}.jar \
	&& wget --progress=dot:giga -O tomcat/webapps/pentaho/docs/xmla-connector.exe https://sourceforge.net/projects/xmlaconnect/files/XMLA_Provider_v${XMLA_PROVIDER_VERSION}.exe/download \
	&& rm -f tomcat/lib/postgre*.jar tomcat/lib/mysql*.jar tomcat/lib/jtds*.jar tomcat/lib/h2*.jar tomcat/lib/hsqldb*.jar \
	&& mv *.jar tomcat/lib/. \
	&& wget --progress=dot:giga -O tomcat/bin/jmx-exporter.jar http://central.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/${JMX_EXPORTER_VERSION}/jmx_prometheus_javaagent-${JMX_EXPORTER_VERSION}.jar

# Install plugins
RUN echo "Download plugins..." \
	&& wget -O btable.zip https://sourceforge.net/projects/btable/files/Version3.0-3.6/BTable-pentaho7-3.6-STABLE.zip/download \
	&& wget -O saiku-chart-plus.zip http://sourceforge.net/projects/saikuchartplus/files/SaikuChartPlus3/saiku-chart-plus-vSaiku3-plugin-pentaho.zip/download \
	&& wget --progress=dot:giga  http://meteorite.bi/downloads/saiku-plugin-p7-3.14.zip \
			https://github.com/zhicwu/cte/releases/download/7.1-SNAPSHOT/cte-7.1-SNAPSHOT.zip \
			http://ctools.pentaho.com/files/d3ComponentLibrary/14.06.18/d3ComponentLibrary-14.06.18.zip \
			https://github.com/rpbouman/pash/raw/master/bin/pash.zip \
	&& echo "Installing plugins..." \
		&& for i in *.zip; do echo "Unpacking $i..." && unzip -q -d pentaho-solutions/system $i && rm -f $i; done

# Add entry point, tempaltes and cron jobs
COPY docker-entrypoint.sh $BISERVER_HOME/docker-entrypoint.sh
COPY repository.xml.template $BISERVER_HOME/pentaho-solutions/system/jackrabbit/repository.xml.template
COPY purge-old-files.sh /usr/local/bin/purge-old-files.sh

# Update configuration
RUN echo "Update configuration..." \
	&& echo "11 * * * * /usr/local/bin/purge-old-files.sh 2>>/var/log/cron.log" > /var/spool/cron/crontabs/root \
	&& chmod 0600 /var/spool/cron/crontabs/root \
	&& wget -P /usr/local/bin/ https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh \
	&& chmod +x /usr/local/bin/*.sh \
	&& sed -i -e 's|\(<entry key="jpeg" value-ref="streamConverter"/>\)|\1<entry key="saiku" value-ref="streamConverter"/>|' \
			-e 's|\(<value>.xcdf</value>\)|\1<value>.saiku</value>|' \
			-e 's|\(<value>xcdf</value>\)|\1<value>saiku</value>|' pentaho-solutions/system/importExport.xml \
	&& sed -i -e 's|\(      <MimeTypeDefinition mimeType="application/vnd.ms-excel">\)|      <MimeTypeDefinition mimeType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet">\n        <extension>xlsx</extension>\n      </MimeTypeDefinition>\n\1|' \
			-e 's|\(      <MimeTypeDefinition mimeType="application/vnd.ms-excel">\)|      <MimeTypeDefinition mimeType="application/vnd.openxmlformats-officedocument.spreadsheetml.template">\n        <extension>xltx</extension>\n      </MimeTypeDefinition>\n\1|' \
			-e 's|\(      <MimeTypeDefinition mimeType="application/vnd.ms-excel">\)|      <MimeTypeDefinition mimeType="application/vnd.ms-excel.sheet.macroEnabled.12">\n        <extension>xlsm</extension>\n      </MimeTypeDefinition>\n\1|' \
			-e 's|\(      <MimeTypeDefinition mimeType="application/vnd.ms-excel">\)|      <MimeTypeDefinition mimeType="application/vnd.ms-excel.template.macroEnabled.12">\n        <extension>xltm</extension>\n      </MimeTypeDefinition>\n\1|' \
			-e 's|\(      <MimeTypeDefinition mimeType="application/vnd.ms-excel">\)|      <MimeTypeDefinition mimeType="application/vnd.ms-excel.addin.macroEnabled.12">\n        <extension>xlam</extension>\n      </MimeTypeDefinition>\n\1|' \
			-e 's|\(      <MimeTypeDefinition mimeType="application/vnd.ms-excel">\)|      <MimeTypeDefinition mimeType="application/vnd.ms-excel.sheet.binary.macroEnabled.12">\n        <extension>xlsb</extension>\n      </MimeTypeDefinition>\n\1|' \
			-e 's|\(        <extension>xls</extension>\)|\1\n        <extension>xlt</extension>\n        <extension>xla</extension>|' \
			-e 's|\(        <extension>sql</extension>\)|\1\n        <extension>txt</extension>\n        <extension>csv</extension>|' \
			-e 's|\(<extension>xcdf</extension>\)|\1<extension>saiku</extension>|' pentaho-solutions/system/ImportHandlerMimeTypeDefinitions.xml \
		&& sed -i -e 's|\(,csv,\)|\1sql,|' pentaho-solutions/system/*.xml \
		&& sed -i -e 's|\(,xlsx,\)|\1xltx,xlsm,xltm,xlam,xlsb,|' pentaho-solutions/system/*.xml \
	&& echo "Add Pentaho user..." \
		&& useradd -md $BISERVER_HOME -s /bin/bash $BISERVER_USER

ENTRYPOINT ["/sbin/my_init", "--", "./docker-entrypoint.sh"]

CMD ["biserver"]
#VOLUME ["$BISERVER_HOME/.pentaho", "$BISERVER_HOME/data/hsqldb", "$BISERVER_HOME/tomcat/logs", "$BISERVER_HOME/pentaho-solutions/system/jackrabbit/repository", "$BISERVER_HOME/tmp"]

#  1234 - JMX Exporter(for Prometheus)
#  8080 - HTTP
#  8009 - AJP
# 11098 - JMX RMI Registry
# 44444 - RMI Server
#EXPOSE 1234 8080 8009 11098 44444

#CMD ["biserver"]
