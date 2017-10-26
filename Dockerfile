#
# Docker image for Pentaho Server Community Edition.
#

# Pull base image
FROM zhicwu/biserver-ce:8.0-base

# Set maintainer
MAINTAINER Zhichun Wu <zhicwu@gmail.com>

# Set environment variables
ENV POSTGRESQL_DRIVER_VERSION=42.1.4 MYSQL_DRIVER_VERSION=5.1.44 \
	JTDS_VERSION=1.3.1 CASSANDRA_DRIVER_VERSION=0.6.4 \
	H2DB_VERSION=1.4.196 HSQLDB_VERSION=2.4.0 XMLA_PROVIDER_VERSION=1.0.0.103

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
	&& mv *.jar tomcat/lib/.

# Install plugins
RUN echo "Download plugins..." \
	&& wget -O btable.zip https://sourceforge.net/projects/btable/files/Version3.0-3.6/BTable-pentaho7-3.6-STABLE.zip/download \
	&& wget -O saiku-chart-plus.zip http://sourceforge.net/projects/saikuchartplus/files/SaikuChartPlus3/saiku-chart-plus-vSaiku3-plugin-pentaho.zip/download \
	&& wget --progress=dot:giga  http://meteorite.bi/downloads/saiku-plugin-p7.1-3.15.zip \
			https://github.com/zhicwu/cte/releases/download/8.0-SNAPSHOT/cte-8.0-SNAPSHOT.zip \
			http://ctools.pentaho.com/files/d3ComponentLibrary/17.07.24/d3ComponentLibrary-17.07.24.zip \
			https://github.com/rpbouman/pash/raw/master/bin/pash.zip \
			https://github.com/rpbouman/phase/raw/master/dist/phase.zip \
			http://ctools.pentaho.com/files/cdv/17.05.12/7.x/cdv-7.1-17.05.12.zip \
	&& echo "Installing plugins..." \
		&& for i in *.zip; do echo "Unpacking $i..." && unzip -q -d pentaho-solutions/system $i && rm -f $i; done

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=2m --retries=3 \
	CMD curl -qsf http://localhost:8080/pentaho/js/themes.js | grep active_theme || exit 1