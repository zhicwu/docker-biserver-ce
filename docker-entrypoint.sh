#!/bin/bash
set -e

: ${EXT_DIR:="/bi-ext"}

: ${BI_JAVA_OPTS:='-Djava.security.egd=file:/dev/./urandom -Xms4096m -Xmx4096m -XX:+UseG1GC -XX:+UseStringDeduplication -XX:+PreserveFramePointer -Djava.awt.headless=true -Dpentaho.karaf.root.transient=true -XX:+HeapDumpOnOutOfMemoryError -XX:ErrorFile=../logs/jvm_error.log -XX:HeapDumpPath=../logs/ -verbose:gc -Xloggc:../logs/gc.log -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintHeapAtGC -XX:+PrintStringDeduplicationStatistics -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=2 -XX:GCLogFileSize=64M -XX:OnOutOfMemoryError=/usr/bin/oom_killer -Dsun.rmi.dgc.client.gcInterval=3600000 -Dsun.rmi.dgc.server.gcInterval=3600000 -Dfile.encoding=utf8 -DDI_HOME=\"$DI_HOME\"'}

: ${PDI_HADOOP_CONFIG:="hdp25"}

: ${PDI_MAX_LOG_LINES:="10000"}
: ${PDI_MAX_LOG_TIMEOUT:="1440"}
: ${PDI_MAX_OBJ_TIMEOUT:="240"}

: ${SERVER_NAME:="bi-server"}
: ${SERVER_HOST:="`hostname`"}
: ${SERVER_PORT:="443"}
: ${SERVER_URL:="https://${SERVER_HOST}/pentaho/"}
: ${LOCALE_LANGUAGE:="en"}
: ${LOCALE_COUNTRY:="US"}

: ${HOST_USER_ID:=""}

: ${STORAGE_TYPE:=""}

fix_permission() {
	# only change when HOST_USER_ID is not empty(and not root)
	if [ "$HOST_USER_ID" != "" ] && [ $HOST_USER_ID != 0 ]; then
		echo "Fixing permissions..."
		
		# based on https://github.com/schmidigital/permission-fix/blob/master/tools/permission_fix
		UNUSED_USER_ID=21338

		# Setting User Permissions
		DOCKER_USER_CURRENT_ID=`id -u $BISERVER_USER`

		if [ "$DOCKER_USER_CURRENT_ID" != "$HOST_USER_ID" ]; then
			DOCKER_USER_OLD=`getent passwd $HOST_USER_ID | cut -d: -f1`

			if [ ! -z "$DOCKER_USER_OLD" ]; then
				usermod -o -u $UNUSED_USER_ID $DOCKER_USER_OLD
			fi

			usermod -o -u $HOST_USER_ID $BISERVER_USER || true
		fi
		
		# all sub-directories
		find $BISERVER_HOME -type d -print0 | xargs -0 chown $BISERVER_USER
		# and then work directories and files underneath
		for d in "$BISERVER_HOME/.pentaho" "$BISERVER_HOME/data/hsqldb" "$BISERVER_HOME/biserver-ce/tomcat/logs" \
			"$BISERVER_HOME/pentaho-solutions/system/jackrabbit/repository" "$BISERVER_HOME/tmp"; do
			[ -d $d ] && chown -Rf $BISERVER_USER $d/* || true
		done
	fi
}

update_db() {
	: ${DATABASE_DIALECT:="org.hibernate.dialect.MySQL5InnoDBDialect"}
	: ${DATABASE_DRIVER:="com.mysql.jdbc.Driver"}
	: ${DATABASE_HOST:="localhost"}
	: ${DATABASE_PORT:="3306"}
	: ${DATABASE_USER:="$BISERVER_USER"}
	: ${DATABASE_PASSWD:="$BISERVER_USER"}
	: ${DATABASE_HIBERNATE:="pbi_hibernate"}
	: ${DATABASE_HIBERNATE_URL:="jdbc:mysql://$DATABASE_HOST:DATABASE_PORT/$DATABASE_HIBERNATE"}
	: ${DATABASE_QUARTZ:="pbi_quartz"}
	: ${DATABASE_QUARTZ_URL:="jdbc:mysql://$DATABASE_HOST:DATABASE_PORT/$DATABASE_QUARTZ"}
	: ${DATABASE_REPOSITORY:="pbi_jackrabbit"}
	: ${DATABASE_REPOSITORY_URL:="jdbc:mysql://$DATABASE_HOST:DATABASE_PORT/$DATABASE_REPOSITORY"}
	: ${DATABASE_VALIDATION_QUERY:="SELECT 1"}
	: ${DATABASE_TYPE:="mysql"}
	
	/bin/cp -f $BISERVER_HOME/pentaho-solutions/system/jackrabbit/repository.xml.template $BISERVER_HOME/pentaho-solutions/system/jackrabbit/repository.xml \
		&& sed -i -e 's|\(jdbc.driver=\).*|\1'"$DATABASE_DRIVER"'|' pentaho-solutions/system/applicationContext-spring-security-hibernate.properties \
		&& sed -i -e 's|\(jdbc.url=\).*|\1'"$DATABASE_HIBERNATE_URL"'|' pentaho-solutions/system/applicationContext-spring-security-hibernate.properties \
		&& sed -i -e 's|\(jdbc.username=\).*|\1'"$DATABASE_USER"'|' pentaho-solutions/system/applicationContext-spring-security-hibernate.properties \
		&& sed -i -e 's|\(jdbc.password=\).*|\1'"$DATABASE_PASSWD"'|' pentaho-solutions/system/applicationContext-spring-security-hibernate.properties \
		&& sed -i -e 's|\(hibernate.dialect=\).*|\1'"$DATABASE_DIALECT"'|' pentaho-solutions/system/applicationContext-spring-security-hibernate.properties \
		&& sed -i -e 's|\(datasource.driver.classname=\).*|\1'"$DATABASE_DRIVER"'|' pentaho-solutions/system/applicationContext-spring-security-jdbc.properties \
		&& sed -i -e 's|\(datasource.url=\).*|\1'"$DATABASE_HIBERNATE_URL"'|' pentaho-solutions/system/applicationContext-spring-security-jdbc.properties \
		&& sed -i -e 's|\(datasource.username=\).*|\1'"$DATABASE_USER"'|' pentaho-solutions/system/applicationContext-spring-security-jdbc.properties \
		&& sed -i -e 's|\(datasource.password=\).*|\1'"$DATABASE_PASSWD"'|' pentaho-solutions/system/applicationContext-spring-security-jdbc.properties \
		&& sed -i -e 's|\(datasource.validation.query=\).*|\1'"$DATABASE_VALIDATION_QUERY"'|' pentaho-solutions/system/applicationContext-spring-security-jdbc.properties \
		&& sed -i -e 's|\(<config-file>\).*\(</config-file>\)|\1system/hibernate/'"$STORAGE_TYPE"'.hibernate.cfg.xml\2|' pentaho-solutions/system/hibernate/hibernate-settings.xml \
		&& sed -i -e 's|\(<property name="connection.driver_class">\).*\(</property>\)|\1'"$DATABASE_DRIVER"'\2|' pentaho-solutions/system/hibernate/${STORAGE_TYPE}.hibernate.cfg.xml \
		&& sed -i -e 's|\(<property name="connection.url">\).*\(</property>\)|\1'"$DATABASE_HIBERNATE_URL"'\2|' pentaho-solutions/system/hibernate/${STORAGE_TYPE}.hibernate.cfg.xml \
		&& sed -i -e 's|\(<property name="dialect">\).*\(</property>\)|\1'"$DATABASE_DIALECT"'\2|' pentaho-solutions/system/hibernate/${STORAGE_TYPE}.hibernate.cfg.xml \
		&& sed -i -e 's|\(<property name="connection.username">\).*\(</property>\)|\1'"$DATABASE_USER"'\2|' pentaho-solutions/system/hibernate/${STORAGE_TYPE}.hibernate.cfg.xml \
		&& sed -i -e 's|\(<property name="connection.password">\).*\(</property>\)|\1'"$DATABASE_PASSWD"'\2|' pentaho-solutions/system/hibernate/${STORAGE_TYPE}.hibernate.cfg.xml \
		&& sed -i -e 's|\(org.quartz.jobStore.driverDelegateClass\).*|\1 = org.quartz.impl.jdbcjobstore.StdJDBCDelegate|' pentaho-solutions/system/quartz/quartz.properties \
		&& sed -i -e 's|@@DRIVER@@|'"$DATABASE_DRIVER"'|' pentaho-solutions/system/jackrabbit/repository.xml \
		&& sed -i -e 's|@@URL@@|'"$DATABASE_REPOSITORY_URL"'|' pentaho-solutions/system/jackrabbit/repository.xml \
		&& sed -i -e 's|@@USER@@|'"$DATABASE_USER"'|' pentaho-solutions/system/jackrabbit/repository.xml \
		&& sed -i -e 's|@@PASSWD@@|'"$DATABASE_PASSWD"'|' pentaho-solutions/system/jackrabbit/repository.xml \
		&& sed -i -e 's|@@DB_TYPE@@|'"$DATABASE_TYPE"'|' pentaho-solutions/system/jackrabbit/repository.xml \
		&& cat <<< "<?xml version='1.0' encoding='UTF-8'?>
<Context path='/pentaho' docbase='webapps/pentaho/'>
	<Resource name='jdbc/Hibernate' auth='Container' type='javax.sql.DataSource'
		factory='org.apache.commons.dbcp.BasicDataSourceFactory' maxActive='20' maxIdle='5'
		maxWait='10000' username='${DATABASE_USER}' password='${DATABASE_PASSWD}'
		driverClassName='${DATABASE_DRIVER}' url='${DATABASE_HIBERNATE_URL}'
		validationQuery='${DATABASE_VALIDATION_QUERY}' />
		
	<Resource name='jdbc/Quartz' auth='Container' type='javax.sql.DataSource'
		factory='org.apache.commons.dbcp.BasicDataSourceFactory' maxActive='20' maxIdle='5'
		maxWait='10000' username='${DATABASE_USER}' password='${DATABASE_PASSWD}'
		driverClassName='${DATABASE_DRIVER}' url='${DATABASE_QUARTZ_URL}'
		validationQuery='${DATABASE_VALIDATION_QUERY}' />
</Context>" > tomcat/webapps/pentaho/META-INF/context.xml

	/usr/local/bin/wait-for-it.sh -t 0 $DATABASE_HOST:$DATABASE_PORT -- echo Database is UP
}

init_biserver() {
	if [ ! -f $BISERVER_HOME/.initialized ]; then
		echo "Initializing BI server..."
		rm -rf .pentaho/* tmp/* pentaho-solutions/system/jackrabbit/repository/* /tmp/kettle tomcat/temp tomcat/work \
			&& mkdir -p tmp/kettle tmp/osgi/cache tmp/osgi/data/log tmp/osgi/data/tmp tmp/tomcat/temp tmp/tomcat/work \
				tomcat/logs/audit pentaho-solutions/system/logs \
			&& ln -s $BISERVER_HOME/tmp/kettle /tmp/kettle \
			&& ln -s $BISERVER_HOME/tmp/tomcat/temp tomcat/temp \
			&& ln -s $BISERVER_HOME/tmp/tomcat/work tomcat/work \
			&& ln -s $BISERVER_HOME/tomcat/logs/audit $BISERVER_HOME/pentaho-solutions/system/logs/audit \
			&& ln -s $BISERVER_HOME/tmp/osgi/cache $BISERVER_HOME/pentaho-solutions/system/karaf/caches \
			&& ln -s $BISERVER_HOME/tmp/osgi/data $BISERVER_HOME/pentaho-solutions/system/karaf/data \
			&& sed -i -e 's|\(CATALINA_OPTS=\)\(.*\)|# http://wiki.apache.org/tomcat/HowTo/FasterStartUp#Entropy_Source\n  \1" -DKETTLE_HOME='"$KETTLE_HOME $BI_JAVA_OPTS"'"|' start-pentaho.sh \
			&& sed -i -e 's|\(fully-qualified-server-url=\).*|\1'"$SERVER_URL"'|' pentaho-solutions/system/server.properties \
			&& sed -i -e 's|\(locale-language=\).*|\1'"$LOCALE_LANGUAGE"'|' pentaho-solutions/system/server.properties \
			&& sed -i -e 's|\(locale-country=\).*|\1'"$LOCALE_COUNTRY"'|' pentaho-solutions/system/server.properties \
			&& sed -i -e 's|\(<value>\)false\(</value>\)|\1true\2|' pentaho-solutions/system/systemListeners.xml \
			&& sed -i 's/^\(active.hadoop.configuration=\).*/\1'"$PDI_HADOOP_CONFIG"'/' $KETTLE_HOME/plugins/pentaho-big-data-plugin/plugin.properties \
			&& find $BISERVER_HOME -type d -print0 | xargs -0 chown $BISERVER_USER \
			&& touch $BISERVER_HOME/.initialized
			#&& sed -i -e 's|\(,mvn:pentaho-karaf-features/pentaho-big-data-plugin-osgi/6.1.0.1-196/xml/features\)||' pentaho-solutions/system/karaf/etc/org.apache.karaf.features.cfg \
			#&& sed -i -e 's|\(respectStartLvlDuringFeatureStartup=\).*|\1true|' pentaho-solutions/system/karaf/etc/org.apache.karaf.features.cfg \
			#&& sed -i -e 's|\(featuresBootAsynchronous=\).*|\1false|' pentaho-solutions/system/karaf/etc/org.apache.karaf.features.cfg \
			#&& sed -i -e 's|\(,pdi-dataservice,pentaho-marketplace\)||' pentaho-solutions/system/karaf/etc/org.apache.karaf.features.cfg \
	fi
}

gen_kettle_config() {
	if [ ! -f $KETTLE_HOME/.kettle/kettle.properties ]; then
		echo "Generating kettle.properties..."
		mkdir -p $KETTLE_HOME/.kettle
		cat <<< "# This file was generated by Pentaho Data Integration.
#
# Here are a few examples of variables to set:
#
# PRODUCTION_SERVER = hercules
# TEST_SERVER = zeus
# DEVELOPMENT_SERVER = thor
#
# Note: lines like these with a # in front of it are comments
#
# Read more at https://github.com/pentaho/pentaho-kettle/blob/6.1.0.1-R/engine/src/kettle-variables.xml
KETTLE_EMPTY_STRING_DIFFERS_FROM_NULL=Y
KETTLE_FORCED_SSL=Y

# Less memory consumption, hopefully
KETTLE_STEP_PERFORMANCE_SNAPSHOT_LIMIT=1

# Master Detector ( start in 1 second, and repeat detection every 10 seconds)
#KETTLE_MASTER_DETECTOR_INITIAL_DELAY=1000
#KETTLE_MASTER_DETECTOR_REFRESH_INTERVAL=10000

KETTLE_DISABLE_CONSOLE_LOGGING=Y
#KETTLE_REDIRECT_STDERR=Y
#KETTLE_REDIRECT_STDOUT=Y
#KETTLE_SYSTEM_HOSTNAME=${SERVER_HOST}

# Tracing
#KETTLE_TRACING_ENABLED=Y
#KETTLE_TRACING_HTTP_URL=http://localhost:9411

KETTLE_CARTE_RETRIES=3
" > $KETTLE_HOME/.kettle/kettle.properties
	fi

	if [ ! -f $KETTLE_HOME/slave-server-config.xml ]; then
		echo "Generating master server configuration..."
		cat <<< "<slave_config>
        <slaveserver>
            <name>${SERVER_NAME}</name>
            <hostname>${SERVER_HOST}</hostname>
            <port>${SERVER_PORT}</port>
            <webAppName>pentaho</webAppName>
            <master>Y</master>
            <sslMode>Y</sslMode>
        </slaveserver>

        <max_log_lines>${PDI_MAX_LOG_LINES}</max_log_lines>
        <max_log_timeout_minutes>${PDI_MAX_LOG_TIMEOUT}</max_log_timeout_minutes>
        <object_timeout_minutes>${PDI_MAX_OBJ_TIMEOUT}</object_timeout_minutes>
</slave_config>" > $KETTLE_HOME/slave-server-config.xml
	fi
}

apply_patches() {
	if [ "$APPLY_PATCHES" != "" ] && [ -f pentaho-kettle*.jar ] && [ -f pentaho-platform*.jar ]; then
		echo "Applying patches..." \
			&& mkdir -p patches \
			&& unzip -q pentaho-kettle*.jar -d patches \
			&& unzip -oq pentaho-platform*.jar -d patches \
			&& cd patches \
			&& $JAVA_HOME/bin/jar uf ../tomcat/webapps/pentaho/WEB-INF/lib/pdi-pur-plugin-${BISERVER_BUILD}.jar org/pentaho/di/repository/pur/LazyUnifiedRepositoryDirectory.class \
			&& $JAVA_HOME/bin/jar uf ../pentaho-solutions/system/kettle/plugins/pdi-pur-plugin/lib/pdi-pur-plugin-${BISERVER_BUILD}.jar org/pentaho/di/repository/pur/LazyUnifiedRepositoryDirectory.class \
			&& $JAVA_HOME/bin/jar uf ../pentaho-solutions/system/kettle/plugins/pdi-pur-plugin/pdi-pur-plugin-${BISERVER_BUILD}.jar org/pentaho/di/repository/pur/LazyUnifiedRepositoryDirectory.class \
			&& $JAVA_HOME/bin/jar uf ../pentaho-solutions/system/pdi-pur-plugin/lib/pdi-pur-plugin-${BISERVER_BUILD}.jar org/pentaho/di/repository/pur/LazyUnifiedRepositoryDirectory.class \
			&& $JAVA_HOME/bin/jar uf ../pentaho-solutions/system/pdi-pur-plugin/pdi-pur-plugin-${BISERVER_BUILD}.jar org/pentaho/di/repository/pur/LazyUnifiedRepositoryDirectory.class \
			&& rm -rf org/pentaho/di/repository \
			&& $JAVA_HOME/bin/jar uf ../tomcat/webapps/pentaho/WEB-INF/lib/kettle-core-${BISERVER_BUILD}.jar org/pentaho/di/core/database \
			&& $JAVA_HOME/bin/jar uf ../tomcat/webapps/pentaho/WEB-INF/lib/kettle-core-${BISERVER_BUILD}.jar org/pentaho/di/core/row \
			&& $JAVA_HOME/bin/jar uf ../tomcat/webapps/pentaho/WEB-INF/lib/kettle-core-${BISERVER_BUILD}.jar org/pentaho/di/cluster/SlaveConnectionManager*.class \
			&& rm -rf org/pentaho/di/core/database org/pentaho/di/core/row org/pentaho/di/cluster/SlaveConnectionManager*.class \
			&& $JAVA_HOME/bin/jar uf ../tomcat/webapps/pentaho/WEB-INF/lib/kettle-engine-${BISERVER_BUILD}.jar kettle-servlets.xml \
			&& $JAVA_HOME/bin/jar uf ../tomcat/webapps/pentaho/WEB-INF/lib/kettle-engine-${BISERVER_BUILD}.jar org/pentaho/di \
			&& rm -rf org/pentaho/di \
			&& $JAVA_HOME/bin/jar uf ../tomcat/webapps/pentaho/WEB-INF/lib/pentaho-platform-scheduler-${BISERVER_BUILD}.jar org/pentaho/platform/scheduler2/quartz \
			&& $JAVA_HOME/bin/jar uf ../tomcat/webapps/pentaho/WEB-INF/lib/classic-core-platform-plugin-${BISERVER_BUILD}.jar org/pentaho/reporting/platform/plugin/connection \
			&& $JAVA_HOME/bin/jar uf ../tomcat/webapps/pentaho/WEB-INF/lib/pentaho-platform-core-${BISERVER_BUILD}.jar org/pentaho/platform/engine/services \
			&& cd - \
			&& rm -rf patches *.jar
		
		rm -f pentaho-solutions/system/kettle/slave-server-config.xml \
			&& gen_kettle_config
		
		echo "Updating configuration..." \
			&& sed -i -e 's|\(<bean id="IAuditEntry" class="\).*|\1org.pentaho.platform.engine.core.audit.NullAuditEntry" scope="singleton" />|' pentaho-solutions/system/pentahoObjects.spring.xml \
			&& sed -i -e 's|\(.*<default-theme>\).*\(</default-theme>\)|\1crystal\2|' pentaho-solutions/system/pentaho.xml \
			&& sed -i -e 's|\(<log-level>\).*\(</log-level>\)|\1INFO\2|' pentaho-solutions/system/pentaho.xml \
			&& sed -i -e 's|\(<max-act-conn>\).*\(</max-act-conn>\)|\150\2|' pentaho-solutions/system/pentaho.xml \
			&& sed -i -e 's|\(<sampledata-datasource>\).*|<!-- \1|' pentaho-solutions/system/pentaho.xml \
			&& sed -i -e 's|\(</sampledata-datasource>\).*|\1 -->|' pentaho-solutions/system/pentaho.xml \
			&& sed -i -e 's|\(<login-show-users-list>\).*\(</login-show-users-list>\)|\1false\2|' pentaho-solutions/system/pentaho.xml \
			&& sed -i -e 's|\(<login-show-sample-users-hint>\).*\(</login-show-sample-users-hint>\)|\1false\2|' pentaho-solutions/system/pentaho.xml \
			&& sed -i -e 's|\(<filebased-solution-cache>\).*\(</filebased-solution-cache>\)| -->\1true\2<!-- |' pentaho-solutions/system/pentaho.xml \
			&& sed -i -e '/^#/! s/\(.*\)/#\1/g' pentaho-solutions/system/simple-jndi/jdbc.properties \
			&& sed -i -e 's|\(\A/logout.*\Z=Anonymous\)|\1\n\\A/kettle/add.*\\Z=Admin\n\\A/kettle/allocate.*\\Z=Admin\n\\A/kettle/cleanup.*\\Z=Admin\n\\A/kettle/execute.*\\Z=Admin\n\\A/kettle/getslave.*\\Z=Admin\n\\A/kettle/next.*\\Z=Admin\n\\A/kettle/pause.*\\Z=Admin\n\\A/kettle/prepare.*\\Z=Admin\n\\A/kettle/register.*\\Z=Admin\n\\A/kettle/remove.*\\Z=Admin\n\\A/kettle/run.*\\Z=Admin\n\\A/kettle/start.*\\Z=Admin\n\\A/kettle/stop.*\\Z=Admin\n\\A/plugin/cda/api/clearCache.*\\Z=Authenticated\n\\A/plugin/saiku/api/admin/discover/refresh.*\\Z=Authenticated|' pentaho-solutions/system/applicationContext-spring-security.xml \
			&& sed -i -e 's|\(<import resource="GettingStartedDB-spring.xml" />\).*|<!-- \1 -->|' pentaho-solutions/system/pentaho-spring-beans.xml \
			&& sed -i -e "s|<script language='JavaScript' type='text/javascript' src='.*brightcove.com.*'></script>||" tomcat/webapps/pentaho/mantle/home/index.jsp \
			&& sed -i -e "s|script.src = '.*brightcove.*';||" tomcat/webapps/pentaho/mantle/home/content/getting_started_launch.html \
			&& sed -i -e 's|"<script.*brightcove.*script>";|"";|' tomcat/webapps/pentaho/mantle/home/js/gettingStarted.js \
			&& sed -i -e 's|\(<util:list id="powerUser">\)|<util:list id="admin">\n\t\t<value>org.pentaho.security.administerSecurity</value>\n\t\t<value>org.pentaho.scheduler.manage</value>\n\t\t<value>org.pentaho.repository.read</value>\n\t\t<value>org.pentaho.repository.create</value>\n\t\t<value>org.pentaho.security.publish</value>\n\t\t</util:list>\n\t\1|' pentaho-solutions/system/defaultUser.spring.xml \
			&& sed -i -e 's|\(<util:map id="role-mappings">\)|\1\n\t\t<entry key="Admin" value-ref="admin" />|' pentaho-solutions/system/defaultUser.spring.xml \
			&& sed -i -e 's|\(<util:map id="defaultUserRoleMappings">\)|\1\n\t\t<entry key="viewer">\n\t\t\t<util:list><ref bean="singleTenantAuthenticatedAuthorityName"/></util:list>\n\t\t</entry>\n\t\t<!-- |' pentaho-solutions/system/defaultUser.spring.xml \
			&& sed -i -e 's|\(<entry key-ref="singleTenantAdminUserName">\)| -->\n\t\t\1|' pentaho-solutions/system/defaultUser.spring.xml \
			&& sed -i -e 's|\(<ref bean="singleTenantAdminAuthorityName"/>\)|\1\n\t\t\t\t<value>Admin</value>|' pentaho-solutions/system/defaultUser.spring.xml \
			&& find . -name "*.css" | xargs sed -i -e 's|http.*googleusercontent\.com||' \
			&& find . -name *ga.js | xargs sed -i -e 's|//www\.google\-analytics\.com||' \
			&& find . -name *ga.js | xargs sed -i -e 's|\?"https\://ssl"\:"http\://www"|?"/":"/"|'
	fi
}

apply_changes() {
	apply_patches
	
	# you can mount a volume pointing to /pdi-ext for customization
	if [ -d $EXT_DIR ]; then
		# if you have custom scripts to run, let's do it
		if [ -f $EXT_DIR/custom_install.sh ]; then
			echo "Running custom installation script..."
			. $EXT_DIR/custom_install.sh
		# otherwise, simply override files based what we have under ext directory
		elif [ "$(ls -A $EXT_DIR)" ]; then
			echo "Copying files from $EXT_DIR to $BISERVER_HOME..."
			/bin/cp -Rf $EXT_DIR/* .
		fi
	fi
	
	# update database configuration as required
	if [ "$STORAGE_TYPE" != "" ] && [ -f pentaho-solutions/system/hibernate/${STORAGE_TYPE}.hibernate.cfg.xml ]; then
		sed -i -e 's|\(<!-- \[BEGIN HSQLDB DATABASES\]\).*|\1|' tomcat/webapps/pentaho/WEB-INF/web.xml \
			&& sed -i -e 's|.*\(\[END HSQLDB DATABASES\] -->\)|\1|' tomcat/webapps/pentaho/WEB-INF/web.xml \
			&& sed -i -e 's|\(<!-- \[BEGIN HSQLDB STARTER\]\).*|\1|' tomcat/webapps/pentaho/WEB-INF/web.xml \
			&& sed -i -e 's|.*\(\[END HSQLDB STARTER\] -->\)|\1|' tomcat/webapps/pentaho/WEB-INF/web.xml
		
		if [ -f database.env ]; then
			echo "Updating database configuration..."
			. database.env
			
			update_db
		else
			echo "Skip database configuration as database.env is not available"
		fi
	else
		# only useful for testing / development purpose
		# on production, you'll need to use external database like MySQL
		if [ ! -f data/hsqldb/hibernate.properties ]; then
			mkdir -p data/hsqldb && /bin/cp -rf data/.hsqldb/* data/hsqldb/.
		fi
	fi
}

# start BI server
if [ "$1" = 'biserver' ]; then
	init_biserver
	apply_changes
	fix_permission
	
	# update configuration based on environment variables
	# send log output to stdout
	#sed -i 's/^\(.*rootLogger.*\), *out *,/\1, stdout,/' system/karaf/etc/org.ops4j.pax.logging.cfg
	#sed -i -e 's|.*\(runtimeFeatures=\).*|\1'"ssh,http,war,kar,cxf"'|' system/karaf/etc-carte/org.pentaho.features.cfg 

	# now start the bi server
	exec /sbin/setuser $BISERVER_USER $BISERVER_HOME/start-pentaho.sh
fi

exec "$@"
