# docker-biserver-ce
Pentaho BI server(community edition) docker image. https://hub.docker.com/r/zhicwu/biserver-ce/

## What's inside
```
ubuntu:16.04
 |
 |-- phusion/baseimage:0.9.22
      |
      |-- zhicwu/java:8
           |
           |-- zhicwu/biserver-ce:8.0-base
                |
                |-- zhicwu/biserver-ce:8.0-full
                    |
                    |-- zhicwu/biserver-ce:8.0
```
* Official Ubuntu 16.04 LTS docker image
* [Phusion Base Image](https://github.com/phusion/baseimage-docker) 0.9.22
* Oracle JDK 8 latest release
* [Pentaho BI Server Community Edition](http://community.pentaho.com/) 8.0.0.0-1 with plugins and patches
    * [BTable](https://sourceforge.net/projects/btable/)
    * [Community Text Editor](http://www.webdetails.pt/ctools/cte/)
    * [D3 Component Library](https://github.com/webdetails/d3ComponentLibrary)
    * Up-to-date JDBC drivers:
        * [PostgreSQL JDBC Driver](https://jdbc.postgresql.org/) 42.1.4
        * [MySQL Connector/J](http://dev.mysql.com/downloads/connector/j/) 5.1.44
        * [jTDS](https://sourceforge.net/projects/jtds/) 1.3.1
        * [H2DB](http://www.h2database.com) 1.4.196
        * [HSQLDB](http://hsqldb.org/) 2.4.0
        * [Cassandra JDBC Driver](https://github.com/zhicwu/cassandra-jdbc-driver) 0.6.4
    * [Saiku](http://community.meteorite.bi/) - enabled SaikuWidgetComponent in CDE
    * [XMLA Provider](https://sourceforge.net/projects/xmlaconnect/) 1.0.0.103 - download from Help -> Document popup and install on your windows box

## Get started
- Run vanilla Pentaho server
```
$ docker run --name bi -p 8080:8080 -p 12345:1234 -d zhicwu/biserver-ce:8.0
$ docker logs -f bi
```
- Run patched Pentaho server
```
$ docker run --name bi -e APPLY_PATCHES=Y -p 8080:8080 -p 12345:1234 -d zhicwu/biserver-ce:8.0
$ docker logs -f bi
```
- Use docker-compose (Recommended)
```
$ git clone https://github.com/zhicwu/docker-biserver-ce.git -b 8.0 --single-branch
$ cd docker-biserver-ce
... edit .env and/or docker-compose.yml based on your needs, put your Pentaho configuration files under ext directory if necessary ...
$ docker-compose up -d
$ docker-compose logs -f
```
Regardless which approach you took, after server started, you should be able to access [Pentaho Server](http://localhost:8080)(admin/password) and [monitor metrics](http://localhost:12345/metrics) using [Prometheus](https://prometheus.io/) and [Grafana](https://grafana.com/).

## How to use external database
Taking MySQL 5.x as an example. Assuming you have pbi_repository, pbi_quartz and pdi_jcr 3 databases created, change docker-compose.yml to set STORAGE_TYPE to mysql5, and then mount volume `./database.env:/biserver-ce/data/database.env` with the following content:
```
SERVER_PASSWD=password
DB_HOST=xxx
DB_PORT=3306
DB_USER=xxx
DB_PASSWD=xxx
```

## How to build
```
$ git clone https://github.com/zhicwu/docker-biserver-ce.git -b 8.0 --single-branch
$ cd docker-biserver-ce
$ docker build -t my/biserver:7.1 .
```