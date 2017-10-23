# docker-biserver-ce
Pentaho BI server(community edition) docker image. https://hub.docker.com/r/zhicwu/biserver-ce/

## Hierarchy
```
ubuntu:16.04
  |
  |--- phusion/baseimage:0.9.22
    |
    |--- zhicwu/java:8
      |
      |--- zhicwu/biserver-ce:8.0-base
        |
        |--- zhicwu/biserver-ce:8.0-full
```
* Official Ubuntu 16.04 LTS docker image
* [Phusion Base Image](https://github.com/phusion/baseimage-docker) 0.9.22
* Oracle JDK 8u144
* [Pentaho BI Server Community Edition](http://community.pentaho.com/) 8.0.0.0-1 with plugins and patches
    * [BTable](https://sourceforge.net/projects/btable/)
    * [Community Text Editor](http://www.webdetails.pt/ctools/cte/)
    * [Community Data Validation](http://www.webdetails.pt/ctools/cdv/)
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

## Quick Start
```
$ docker run --name bi -p 8080:8080 -d zhicwu/biserver-ce:8.0-full
$ docker logs -f bi
```
Now you should be able to access Pentaho Server at http://localhost:8080

## How to Build
```
$ git clone https://github.com/zhicwu/docker-biserver-ce.git -b 8.0-full --single-branch
$ cd docker-biserver-ce
$ docker build -t my/biserver:8.0 .
```