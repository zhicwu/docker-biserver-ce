# docker-biserver-ce
Pentaho BI server(community edition) docker image. https://hub.docker.com/r/zhicwu/biserver-ce/

## What's inside
```
ubuntu:14.04
 |
 |--- zhicwu/java:8
       |
       |--- zhicwu/biserver-ce:7.0
```
* Official Ubuntu Trusty(14.04) docker image
* Oracle JDK 8 latest release
* [Pentaho BI Server Community Edition](http://community.pentaho.com/) 7.0.0.0-25 with plugins and patches:
 * [BTable](https://sourceforge.net/projects/btable/)
 * [Community Text Editor](http://www.webdetails.pt/ctools/cte/)
 * [D3 Component Library](https://github.com/webdetails/d3ComponentLibrary)
 * Up-to-date JDBC drivers: [MySQL Connector/J](http://dev.mysql.com/downloads/connector/j/) 5.1.40, [jTDS](https://sourceforge.net/projects/jtds/) 1.3.1 and [Cassandra JDBC Driver](https://github.com/zhicwu/cassandra-jdbc-driver) 0.6.1
 * [Saiku](http://community.meteorite.bi/) - enabled SaikuWidgetComponent in CDE
 * [XMLA Provider](https://sourceforge.net/projects/xmlaconnect/) 1.0.0.103 - download from Help -> Document popup and install on your windows box

## Known issue
- Not able to import mondrian schema in console, you may have to use schema workbench to publish schema to BI server

## How to use
- Clone git repository
```
# git clone https://github.com/zhicwu/docker-biserver-ce.git
# cd docker-biserver-ce
```
- Edit .env and/or docker-compose.yml based on your needs, put your Pentaho configuration files under ext directory if necessary
- Start BI Server
```
# docker-compose up -d
# docker logs -f bi
```
You can now use admin/password to access the BI server at http://localhost:8080.
- To use MySQL instead of HSQL
Assuming you have pbi_repository, pbi_quartz and pdi_jcr 3 databases created, change docker-compose.yml to set STORAGE_TYPE to mysql5, and then mount volume ./secret.env:/biserver-ce/data/secret.env:rw: with the following content:
```
SERVER_PASSWD=password
DB_HOST=xxx
DB_PORT=3306
DB_USER=xxx
DB_PASSWD=xxx
```

## How to build
```
# git clone https://github.com/zhicwu/docker-biserver-ce.git
# cd docker-biserver-ce
# chmod +x *.sh
# docker build -t zhicwu/biserver-ce .
```
