#
# Docker image for Pentaho BA server community edition.
#

# Pull base image
FROM zhicwu/biserver-ce:7.1-full

# Set maintainer
MAINTAINER Zhichun Wu <zhicwu@gmail.com>

# Set environment variables
ENV BISERVER_USER=pentaho PDI_PATCH=7.1.0.5 JMX_EXPORTER_VERSION=0.10

# Update server configuration
RUN echo "Update server configuration..." \
		&& mkdir -p $BISERVER_HOME/data/.hsqldb \
		&& /bin/cp -rf $BISERVER_HOME/data/hsqldb/* $BISERVER_HOME/data/.hsqldb/. \
		&& rm -f pentaho-solutions/system/BTable/resources/datasources/*.cda pentaho-solutions/system/default-content/* \
		&& sed -i -e 's|\(<entry key="jpeg" value-ref="streamConverter"/>\)|\1<entry key="saiku" value-ref="streamConverter"/>|' \
			-e 's|\(<value>.xcdf</value>\)|\1<value>.saiku</value>|' \
			-e 's|\(<value>xcdf</value>\)|\1<value>saiku</value>|' pentaho-solutions/system/importExport.xml \
		&& sed -i -e 's|\(<!-- Insert system-listeners -->\)|\1\n        <bean id="repositoryCleanerSystemListener" class="org.pentaho.platform.plugin.services.repository.RepositoryCleanerSystemListener">\n          <property name="gcEnabled" value="true"/>\n          <property name="execute" value="now"/><!-- jcr-gc-freq -->\n        </bean>|' \
			pentaho-solutions/system/systemListeners.xml \
		&& touch pentaho-solutions/system/saiku/ui/js/saiku/plugins/CCC_Chart/cdo.js \
		&& wget -P pentaho-solutions/system/saiku/components/saikuWidget https://github.com/OSBI/saiku/raw/tag-3.15/saiku-bi-platform-plugin-p7.1/src/main/plugin/components/saikuWidget/SaikuWidgetComponent.js \
		&& sed -i -e "s|\(: data.query.queryModel.axes.FILTER\)\(.*\)|\1 == undefined ? [] \1\2|" \
			-e "s|\(: data.query.queryModel.axes.COLUMNS\)\(.*\)|\1 == undefined ? [] \1\2|" \
			-e "s|\(: data.query.queryModel.axes.ROWS\)\(.*\)|\1 == undefined ? [] \1\2|" \
			-e "s|\(request.setRequestHeader('Authorization', auth);\)|// \1|" pentaho-solutions/system/saiku/ui/js/saiku/embed/SaikuEmbed.js \
		&& sed -i -e 's|\(var query = Saiku.tabs._tabs\[0\].content.query;\)|\1\nif (query == undefined ) query = Saiku.tabs._tabs[1].content.query;|' pentaho-solutions/system/saiku/ui/js/saiku/plugins/BIServer/plugin.js \
		&& sed -i -e 's|self.template()|"Error!"|' \
			-e 's|http://meteorite.bi/|/|' pentaho-solutions/system/saiku/ui/saiku.min.js \
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
		&& sed -i -e 's|\(.upgradeheader {\).*|\1 display: none;|' pentaho-solutions/system/saiku/ui/css/saiku/src/styles.css \
		&& sed -i -e 's/\(requestParameterAuthenticationEnabled=\).*/\1true/' $BISERVER_HOME/pentaho-solutions/system/security.properties \
		&& sed -i -e 's|\(<bean id="IAuditEntry" class="\).*|\1org.pentaho.platform.engine.core.audit.NullAuditEntry" scope="singleton" />|' pentaho-solutions/system/pentahoObjects.spring.xml \
		&& sed -i -e 's|\(<log-level>\).*\(</log-level>\)|\1INFO\2|' \
			-e 's|\(<max-act-conn>\).*\(</max-act-conn>\)|\150\2|' \
			-e 's|\(<sampledata-datasource>\).*|<!-- \1|' \
			-e 's|\(</sampledata-datasource>\).*|\1 -->|' \
			-e 's|\(<login-show-users-list>\).*\(</login-show-users-list>\)|\1false\2|' \
			-e 's|\(<login-show-sample-users-hint>\).*\(</login-show-sample-users-hint>\)|\1false\2|' \
			-e 's|\(<filebased-solution-cache>\).*\(</filebased-solution-cache>\)| -->\1true\2<!-- |' pentaho-solutions/system/pentaho.xml \
		&& sed -i -e '/^#/! s/\(.*\)/#\1/g' pentaho-solutions/system/simple-jndi/jdbc.properties \
		&& sed -i -e 's|\(\A/logout.*\Z=Anonymous\)|\1\n\\A/kettle/add.*\\Z=Admin\n\\A/kettle/allocate.*\\Z=Admin\n\\A/kettle/cleanup.*\\Z=Admin\n\\A/kettle/execute.*\\Z=Admin\n\\A/kettle/getslave.*\\Z=Admin\n\\A/kettle/next.*\\Z=Admin\n\\A/kettle/pause.*\\Z=Admin\n\\A/kettle/prepare.*\\Z=Admin\n\\A/kettle/register.*\\Z=Admin\n\\A/kettle/remove.*\\Z=Admin\n\\A/kettle/run.*\\Z=Admin\n\\A/kettle/start.*\\Z=Admin\n\\A/kettle/stop.*\\Z=Admin\n\\A/plugin/cda/api/clearCache.*\\Z=Admin\n\\A/plugin/saiku/api/admin/discover/refresh.*\\Z=Admin|' pentaho-solutions/system/applicationContext-spring-security.xml \
		&& sed -i -e 's|\(<import resource="GettingStartedDB-spring.xml" />\).*|<!-- \1 -->|' pentaho-solutions/system/pentaho-spring-beans.xml \
		&& sed -i -e "s|<script language='JavaScript' type='text/javascript' src='.*brightcove.com.*'></script>||" tomcat/webapps/pentaho/mantle/home/index.jsp \
		&& sed -i -e "s|script.src = '.*brightcove.*';||" tomcat/webapps/pentaho/mantle/home/content/getting_started_launch.html \
		&& sed -i -e 's|"<script.*brightcove.*script>";|"";|' tomcat/webapps/pentaho/mantle/home/js/gettingStarted.js \
		&& sed -i -e 's|\(<util:list id="powerUser">\)|<util:list id="admin">\n\t\t<value>org.pentaho.security.administerSecurity</value>\n\t\t<value>org.pentaho.scheduler.manage</value>\n\t\t<value>org.pentaho.repository.read</value>\n\t\t<value>org.pentaho.repository.create</value>\n\t\t<value>org.pentaho.security.publish</value>\n\t\t</util:list>\n\t\1|' \
			-e 's|\(<util:map id="role-mappings">\)|\1\n\t\t<entry key="Admin" value-ref="admin" />|' \
			-e 's|\(<util:map id="defaultUserRoleMappings">\)|\1\n\t\t<entry key="viewer">\n\t\t\t<util:list><ref bean="singleTenantAuthenticatedAuthorityName"/></util:list>\n\t\t</entry>\n\t\t<!-- |' \
			-e 's|\(<entry key-ref="singleTenantAdminUserName">\)| -->\n\t\t\1|' \
			-e 's|\(<ref bean="singleTenantAdminAuthorityName"/>\)|\1\n\t\t\t\t<value>Admin</value>|' pentaho-solutions/system/defaultUser.spring.xml \
		&& find . -name "*.css"  -type f | xargs sed -i -e 's|http.*googleusercontent\.com||' \
		&& find . -name "*ga.js" -type f | xargs sed -i -e 's|//www\.google\-analytics\.com||' \
		&& find . -name "*ga.js" -type f | xargs sed -i -e 's|\?"https\://ssl"\:"http\://www"|?"/":"/"|' \
		&& sed -i -e 's|\(            var xhr = text.createXhr(), header;\)|            url = url.replace(/https:\&name=\\/.*\\/pentaho\\/content\\/([a-zA-Z0-9\\-_]+)\\//mg, "\\$1\&name=");\n\1|' \
			pentaho-solutions/system/common-ui/resources/web/util/require-text/text.js \
			pentaho-solutions/system/pentaho-cdf/js/lib/require-text/text.js \
		&& sed -i -e 's|\(        localRequire(\)|        bundleUrl = bundleUrl.replace(/https:\&name=\\/.*\\/pentaho\\/content\\/([a-zA-Z0-9\\-_]+)\\//mg, "\\$1\&name=");\n\1|' \
			pentaho-solutions/system/common-ui/resources/web/pentaho/i18n.js \
		&& find . -name "jquery.dataTables.js" -type f | xargs sed -i -e 's|\(s.nTHead.parentNode == this\)|(s.nTHead \&\& \1)|' \
	&& echo "Add Pentaho user..." \
		&& useradd -Md $BISERVER_HOME -s /bin/bash $BISERVER_USER

# Download patches and dependencies
RUN echo "Download patches and dependencies..." \
		&& wget -P /usr/local/bin/ https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh \
		&& wget -O tomcat/bin/jmx-exporter.jar http://central.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/${JMX_EXPORTER_VERSION}/jmx_prometheus_javaagent-${JMX_EXPORTER_VERSION}.jar \
		&& wget --progress=dot:giga https://github.com/zhicwu/pdi-cluster/releases/download/${PDI_PATCH}/pentaho-kettle-${PDI_PATCH}.jar \
			https://github.com/zhicwu/pdi-cluster/releases/download/${PDI_PATCH}/pentaho-platform-${PDI_PATCH}.jar \
			https://github.com/zhicwu/pdi-cluster/releases/download/${PDI_PATCH}/mondrian-${PDI_PATCH}.jar \
		&& wget -P pentaho-solutions/system/saiku/lib/ http://central.maven.org/maven2/com/fasterxml/jackson/module/jackson-module-jaxb-annotations/2.5.1/jackson-module-jaxb-annotations-2.5.1.jar \
		&& chmod +x /usr/local/bin/*.sh \
	&& echo "Applying patches..." \
		&& find pentaho-solutions/system/d3ComponentLibrary pentaho-solutions/system/BTable pentaho-solutions/system/saiku \
			-name component.xml | xargs sed -i -e 's|<Implementation>|<Implementation supportsLegacy="true" supportsAMD="true">|' \
		&& sed -i -e 's|\(<Dependencies>\)|\1\n\t\t<Dependency src="../../ui/js/saiku/Settings.js">saikusettings</Dependency>|' \
			pentaho-solutions/system/saiku/components/saikuWidget/component.xml \
		&& rm -f pentaho-solutions/system/saiku/lib/cpf-*.jar \
		&& cp pentaho-solutions/system/sparkl/lib/cpf-*.jar pentaho-solutions/system/saiku/lib/. \
		&& mv pentaho-solutions/system/saiku/lib/mondrian*.jar pentaho-solutions/system/saiku/lib/mondrian.jar.disabled \
		&& ln -s $BISERVER_HOME/tomcat/webapps/pentaho/WEB-INF/lib/mondrian*.jar pentaho-solutions/system/saiku/lib/mondrian.jar \
		&& mkdir -p patches \
		&& unzip -q mondrian*.jar -d patches \
		&& unzip -oq pentaho-kettle*.jar -d patches \
		&& unzip -oq pentaho-platform*.jar -d patches \
		&& cd patches \
		&& $JAVA_HOME/bin/jar uf ../tomcat/webapps/pentaho/WEB-INF/lib/mondrian-*.jar META-INF/services \
		&& $JAVA_HOME/bin/jar uf ../tomcat/webapps/pentaho/WEB-INF/lib/mondrian-*.jar mondrian \
		&& rm -rf META-INF/services mondrian \
		&& $JAVA_HOME/bin/jar uf ../pentaho-solutions/system/pentaho-pdi-platform-plugin/lib/DIS-${BISERVER_VERSION}.jar org/pentaho/platform/plugin/kettle \
		&& rm -rf org/pentaho/platform/plugin/kettle \
		&& $JAVA_HOME/bin/jar uf ../tomcat/webapps/pentaho/WEB-INF/lib/pdi-pur-plugin-${BISERVER_VERSION}.jar org/pentaho/di/repository/pur/LazyUnifiedRepositoryDirectory.class \
		&& $JAVA_HOME/bin/jar uf ../pentaho-solutions/system/kettle/plugins/pdi-pur-plugin/lib/pdi-pur-plugin-${BISERVER_VERSION}.jar org/pentaho/di/repository/pur/LazyUnifiedRepositoryDirectory.class \
		&& $JAVA_HOME/bin/jar uf ../pentaho-solutions/system/kettle/plugins/pdi-pur-plugin/pdi-pur-plugin-${BISERVER_VERSION}.jar org/pentaho/di/repository/pur/LazyUnifiedRepositoryDirectory.class \
		&& $JAVA_HOME/bin/jar uf ../pentaho-solutions/system/pdi-pur-plugin/lib/pdi-pur-plugin-${BISERVER_VERSION}.jar org/pentaho/di/repository/pur/LazyUnifiedRepositoryDirectory.class \
		&& $JAVA_HOME/bin/jar uf ../pentaho-solutions/system/pdi-pur-plugin/pdi-pur-plugin-${BISERVER_VERSION}.jar org/pentaho/di/repository/pur/LazyUnifiedRepositoryDirectory.class \
		&& rm -rf org/pentaho/di/repository/pur \
		&& $JAVA_HOME/bin/jar uf ../tomcat/webapps/pentaho/WEB-INF/lib/kettle-engine-${BISERVER_VERSION}.jar org/pentaho/di/repository \
		&& rm -rf org/pentaho/di/repository \
		&& $JAVA_HOME/bin/jar uf ../tomcat/webapps/pentaho/WEB-INF/lib/kettle-core-${BISERVER_VERSION}.jar org/pentaho/di/core/database \
		&& $JAVA_HOME/bin/jar uf ../tomcat/webapps/pentaho/WEB-INF/lib/kettle-core-${BISERVER_VERSION}.jar org/pentaho/di/core/row \
		&& $JAVA_HOME/bin/jar uf ../tomcat/webapps/pentaho/WEB-INF/lib/kettle-core-${BISERVER_VERSION}.jar org/pentaho/di/cluster/SlaveConnectionManager*.class \
		&& rm -rf org/pentaho/di/core/database org/pentaho/di/core/row org/pentaho/di/cluster/SlaveConnectionManager*.class \
		&& $JAVA_HOME/bin/jar uf ../tomcat/webapps/pentaho/WEB-INF/lib/kettle-engine-${BISERVER_VERSION}.jar kettle-servlets.xml \
		&& $JAVA_HOME/bin/jar uf ../tomcat/webapps/pentaho/WEB-INF/lib/kettle-engine-${BISERVER_VERSION}.jar org/pentaho/di \
		&& rm -rf org/pentaho/di \
		&& $JAVA_HOME/bin/jar uf ../tomcat/webapps/pentaho/WEB-INF/lib/pentaho-platform-scheduler-${BISERVER_VERSION}.jar org/pentaho/platform/scheduler2/quartz \
		&& $JAVA_HOME/bin/jar uf ../tomcat/webapps/pentaho/WEB-INF/lib/classic-core-platform-plugin-${BISERVER_VERSION}.jar org/pentaho/reporting/platform/plugin/connection \
		&& $JAVA_HOME/bin/jar uf ../tomcat/webapps/pentaho/WEB-INF/lib/pentaho-platform-core-${BISERVER_VERSION}.jar org/pentaho/platform/engine/services \
		&& cd - \
		&& rm -rf patches *.jar

# Add entry point, tempaltes and cron jobs
COPY docker-entrypoint.sh $BISERVER_HOME/docker-entrypoint.sh
COPY repository.xml.template $BISERVER_HOME/pentaho-solutions/system/jackrabbit/repository.xml.template
COPY purge-old-files.sh /usr/local/bin/purge-old-files.sh

# Post configuration
# if you prefer the old theme try:
# sed -i -e 's|\(.*<default-theme>\).*\(</default-theme>\)|\1crystal\2|' pentaho-solutions/system/pentaho.xml
RUN echo "Post configuration..." \
	&& echo "11 * * * * /usr/local/bin/purge-old-files.sh 2>>/var/log/cron.log" > /var/spool/cron/crontabs/root \
	&& chmod 0600 /var/spool/cron/crontabs/root \
	&& chmod +x *.sh /usr/local/bin/*.sh

ENTRYPOINT ["/sbin/my_init", "--", "./docker-entrypoint.sh"]

#VOLUME ["$BISERVER_HOME/.pentaho", "$BISERVER_HOME/data/hsqldb", "$BISERVER_HOME/tomcat/logs", "$BISERVER_HOME/pentaho-solutions/system/jackrabbit/repository", "$BISERVER_HOME/tmp"]

#  1234 - JMX Exporter(for Prometheus)
#  8080 - HTTP
#  8009 - AJP
# 11098 - JMX RMI Registry
# 44444 - RMI Server
EXPOSE 1234 8080

CMD ["biserver"]
