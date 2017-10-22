#
# Docker image for Pentaho Server Community Edition.
#

#
# Stage 1/2: Build BI Server
#
FROM maven:3.5.0-jdk-8 as builder

ENV BISERVER_RELEASE=8.0.0.0 BISERVER_BUILD=1 BISERVER_HOME=/pentaho-server \
	ECLIPSE_SWT_VERSION=4.6 SYSLOG4J_VERSION=0.9.46
ENV BISERVER_VERSION=$BISERVER_RELEASE-$BISERVER_BUILD

RUN apt-get update \
	&& apt-get install -y libapr1 libaprutil1 libapr1-dev libssl-dev gcc make \
	&& mkdir -p ~/.m2 \
	&& wget --progress=dot:giga -P /root/.m2/ https://raw.githubusercontent.com/pentaho/maven-parent-poms/master/maven-support-files/settings.xml \
	&& wget --progress=dot:giga https://github.com/pentaho/pentaho-platform/archive/$BISERVER_RELEASE-R.tar.gz \
		https://github.com/maven-eclipse/maven-eclipse.github.io/raw/master/maven/org/eclipse/swt/org.eclipse.swt.gtk.linux.x86_64/$ECLIPSE_SWT_VERSION/org.eclipse.swt.gtk.linux.x86_64-$ECLIPSE_SWT_VERSION.jar \
		http://clojars.org/repo/org/syslog4j/syslog4j/$SYSLOG4J_VERSION/syslog4j-$SYSLOG4J_VERSION.jar \
	&& wget --timeout=5 --waitretry=2 --tries=50 --retry-connrefused --progress=dot:giga https://public.nexus.pentaho.org/content/groups/omni/pentaho/pentaho-karaf-assembly/$BISERVER_VERSION/pentaho-karaf-assembly-$BISERVER_VERSION-client.zip \
		https://public.nexus.pentaho.org/content/groups/omni/pentaho/pentaho-big-data-plugin/$BISERVER_VERSION/pentaho-big-data-plugin-$BISERVER_VERSION.zip \
	&& mvn install:install-file -Dfile=pentaho-big-data-plugin-$BISERVER_VERSION.zip -DgroupId=pentaho -DartifactId=pentaho-big-data-plugin -Dversion=$BISERVER_VERSION -Dpackaging=zip \
	&& mvn install:install-file -Dfile=pentaho-karaf-assembly-$BISERVER_VERSION-client.zip -DgroupId=pentaho -DartifactId=pentaho-karaf-assembly -Dversion=$BISERVER_VERSION -Dpackaging=zip \
	&& mvn install:install-file -Dfile=org.eclipse.swt.gtk.linux.x86_64-$ECLIPSE_SWT_VERSION.jar -DgroupId=org.eclipse.swt -DartifactId=org.eclipse.swt.gtk.linux.x86_64 -Dversion=$ECLIPSE_SWT_VERSION -Dpackaging=jar \
	&& mvn install:install-file -Dfile=syslog4j-$SYSLOG4J_VERSION.jar -DgroupId=org.syslog4j -DartifactId=syslog4j -Dversion=$SYSLOG4J_VERSION -Dpackaging=jar \
	&& sed -i -e 's|\(/packaging>\)|\1\n  <classifier>client</classifier>|' /root/.m2/repository/pentaho/pentaho-karaf-assembly/$BISERVER_VERSION/pentaho-karaf-assembly-$BISERVER_VERSION.pom \
	&& tar zxf $BISERVER_RELEASE-R.tar.gz \
	&& cd pentaho-platform-$BISERVER_RELEASE-R \
	&& sed -i -e 's|<artifactId>tomcat-windows-x64</artifactId>|<artifactId>tomcat</artifactId>|' assemblies/pentaho-server/pom.xml \
	&& mvn --quiet -DskipTests install \
	&& cd - \
	&& unzip pentaho-platform-$BISERVER_RELEASE-R/assemblies/pentaho-server/target/pentaho-server-ce-$BISERVER_RELEASE*.zip \
	&& find $BISERVER_HOME -name "*.bat" -delete \
	&& find $BISERVER_HOME -name "*.exe" -delete \
	&& rm -f $BISERVER_HOME/promptuser.* \
	&& chmod +x $BISERVER_HOME/*.sh \
	&& sed -i -e 's|-XX:MaxPermSize=256m|-XX:MaxMetaspaceSize=256m -Djava.security.egd=file:/dev/./urandom|' $BISERVER_HOME/start-pentaho.sh \
	&& sed -i -e 's|\(<Engine name="Catalina" defaultHost="localhost">\)|\1\n      <Valve className="org.apache.catalina.valves.RemoteIpValve" internalProxies=".*" remoteIpHeader="x-forwarded-for" proxiesHeader="x-forwarded-by" protocolHeader="x-forwarded-proto" />|' $BISERVER_HOME/tomcat/conf/server.xml \
	&& sed -i -e 's|\(exec ".*"\) start|export LD_LIBRARY_PATH=$BISERVER_HOME/tomcat/lib:$LD_LIBRARY_PATH\n\n\1 run|' $BISERVER_HOME/tomcat/bin/startup.sh \
	&& mkdir -p /tmp/build \
	&& cd /tmp/build \
	&& tar zxf $BISERVER_HOME/tomcat/bin/tomcat-native.tar.gz \
	&& cd tomcat-native*/native \
	&& ./configure --prefix=$BISERVER_HOME/tomcat \
	&& make \
	&& make install \
	&& rm -f $BISERVER_HOME/tomcat/bin/tomcat-native.tar.gz \
	&& cd /tmp/build \
	&& wget https://www.openssl.org/source/openssl-1.1.0f.tar.gz \
	&& tar zxf openssl-1.1*.tar.gz \
	&& cd openssl-1.1* \
	&& ./config -Wl,--enable-new-dtags,-rpath,'$(LIBRPATH)' \
	&& make \
	&& mv lib*.so.1.1 $BISERVER_HOME/tomcat/lib/.


#
# Stage 2/2: Install BI Server
#
FROM zhicwu/java:8

# Set maintainer
MAINTAINER Zhichun Wu <zhicwu@gmail.com>

# Set environment variables
ENV BISERVER_VERSION=8.0.0.0-1 \
	BISERVER_HOME=/biserver-ce KETTLE_HOME=/biserver-ce/pentaho-solutions/system/kettle

# Set label
LABEL java_server="Pentaho Server $BISERVER_VERSION Community Edition"

# Update system and install dependencies
RUN apt-get update \
	&& apt-get install -y libapr1 libaprutil1 libssl1.0.0 xvfb \
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
