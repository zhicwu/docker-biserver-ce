#
# Docker image for Pentaho Server Community Edition.
#

# Pull base image
FROM zhicwu/java:8

# Set maintainer
MAINTAINER Zhichun Wu <zhicwu@gmail.com>

# Set environment variables
ENV BISERVER_VERSION=7.1 BISERVER_BUILD=7.1.0.0-12 BISERVER_HOME=/biserver-ce \
	KETTLE_HOME=/biserver-ce/pentaho-solutions/system/kettle

# Set label
LABEL java_server="Pentaho Server $BISERVER_VERSION Community Edition"

# Install vanilla Pentaho server along with minor changes to configuration
# FIXME: use multi-stage once https://github.com/docker/hub-feedback/issues/1039 is resolved
RUN echo "Download and unpack Pentaho server..." \
		&& wget --progress=dot:giga http://downloads.sourceforge.net/project/pentaho/Business%20Intelligence%20Server/${BISERVER_VERSION}/pentaho-server-ce-${BISERVER_BUILD}.zip \
		&& unzip -q *.zip \
		&& rm -f *.zip \
		&& mv /pentaho-server $BISERVER_HOME \
		&& ln -s $BISERVER_HOME /pentaho-server \
		&& find $BISERVER_HOME -name "*.bat" -delete \
		&& find $BISERVER_HOME -name "*.exe" -delete \
		&& chmod +x $BISERVER_HOME/*.sh \
	&& echo "Install APR for Tomcat..." \
		&& mkdir /build \
		&& cd /build \
		&& tar zxf $BISERVER_HOME/tomcat/bin/tomcat-native.tar.gz \
		&& cd tomcat-native*/native \
		&& apt-get update \
		&& apt-get install -y xvfb libapr1-dev gcc make \
		&& ./configure --with-apr=/usr/bin/apr-config --disable-openssl --with-java-home=$JAVA_HOME --prefix=$BISERVER_HOME/tomcat \
		&& make \
		&& make install \
		&& sed -i -e 's|\(SSLEngine="\).*\("\)|\1off\2|' \
			-e 's|\(<Engine name="Catalina" defaultHost="localhost">\)|\1\n      <Valve className="org.apache.catalina.valves.RemoteIpValve" internalProxies=".*" remoteIpHeader="x-forwarded-for" remoteIpProxiesHeader="x-forwarded-by" protocolHeader="x-forwarded-proto" />|' $BISERVER_HOME/tomcat/conf/server.xml \
		&& cd / \
		&& rm -rf build $BISERVER_HOME/tomcat/bin/tomcat-native.tar.gz \
		&& apt-get autoremove -y gcc make \
		&& apt-get clean \
		&& rm -rf /var/lib/apt/lists/* \
	&& echo "Update server configuration..." \
		&& cd $BISERVER_HOME \
		&& sed -i -e 's|\(exec ".*"\) start|export LD_LIBRARY_PATH=$BISERVER_HOME/tomcat/lib:$LD_LIBRARY_PATH\n\n\1 run|' tomcat/bin/startup.sh \
		&& rm -f promptuser.*

# Change work directory
WORKDIR $BISERVER_HOME

#EXPOSE 8080

CMD ["/sbin/my_init", "--", "./start-pentaho.sh"]
