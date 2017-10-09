#
# Docker image for Pentaho Server Community Edition.
#

#
# Stage 1/2: Build BI Server
#
FROM maven:3.5.0-jdk-8 as builder

ENV BISERVER_RELEASE=7.1.0.5 BISERVER_HOME=/pentaho-server

RUN apt-get update \
	&& apt-get install -y libapr1 libaprutil1 libapr1-dev libssl-dev gcc make \
	&& mkdir -p ~/.m2 \
	&& wget --progress=dot:giga -P /root/.m2/ https://raw.githubusercontent.com/pentaho/maven-parent-poms/master/maven-support-files/settings.xml \
	&& wget --progress=dot:giga https://github.com/pentaho/pentaho-platform/archive/$BISERVER_RELEASE-R.tar.gz \
	&& tar zxf $BISERVER_RELEASE-R.tar.gz \
	&& cd pentaho-platform-$BISERVER_RELEASE-R \
	&& sed -i -e 's|<tomcat.version>.*</tomcat.version>|<tomcat.version>8.0.47</tomcat.version>|' \
		-e 's|<artifactId>tomcat-windows-x64</artifactId>|<artifactId>tomcat</artifactId>|' assemblies/pentaho-server/pom.xml \
	&& mvn -DskipTests install \
	&& cd - \
	&& unzip pentaho-platform-$BISERVER_RELEASE-R/assemblies/pentaho-server/target/pentaho-server-ce-$BISERVER_RELEASE*.zip \
	&& find $BISERVER_HOME -name "*.bat" -delete \
	&& find $BISERVER_HOME -name "*.exe" -delete \
	&& rm -f $BISERVER_HOME/promptuser.* \
	&& chmod +x $BISERVER_HOME/*.sh \
	&& sed -i -e 's|\(<Engine name="Catalina" defaultHost="localhost">\)|\1\n      <Valve className="org.apache.catalina.valves.RemoteIpValve" internalProxies=".*" remoteIpHeader="x-forwarded-for" remoteIpProxiesHeader="x-forwarded-by" protocolHeader="x-forwarded-proto" />|' $BISERVER_HOME/tomcat/conf/server.xml \
	&& sed -i -e 's|\(exec ".*"\) start|export LD_LIBRARY_PATH=$BISERVER_HOME/tomcat/lib:$LD_LIBRARY_PATH\n\n\1 run|' $BISERVER_HOME/tomcat/bin/startup.sh \
	&& mkdir -p /tmp/build \
	&& cd /tmp/build \
	&& tar zxf $BISERVER_HOME/tomcat/bin/tomcat-native.tar.gz \
	&& cd tomcat-native*/native \
	&& ./configure --prefix=$BISERVER_HOME/tomcat \
	&& make \
	&& make install \
	&& rm -f $BISERVER_HOME/tomcat/bin/tomcat-native.tar.gz


#
# Stage 2/2: Install BI Server
#
FROM zhicwu/java:8

# Set maintainer
MAINTAINER Zhichun Wu <zhicwu@gmail.com>

# Set environment variables
ENV BISERVER_VERSION=7.1.0.5 BISERVER_HOME=/biserver-ce \
	KETTLE_HOME=/biserver-ce/pentaho-solutions/system/kettle

# Set label
LABEL java_server="Pentaho Server $BISERVER_VERSION Community Edition"

# Update system and install dependencies
RUN apt-get update \
	&& apt-get install -y libapr1 libaprutil1 libssl1.0.0 \
	&& mkdir -p $BISERVER_HOME \
	&& ln -s $BISERVER_HOME /pentaho-server \
	&& apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy Pentaho server files
COPY --from=builder /pentaho-server $BISERVER_HOME

# Change work directory
WORKDIR $BISERVER_HOME

#EXPOSE 8080

CMD ["/sbin/my_init", "--", "./start-pentaho.sh"]
