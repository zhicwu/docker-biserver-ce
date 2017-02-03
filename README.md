# docker-biserver-ce
Pentaho BI server(community edition) docker image for development and testing purposes. https://hub.docker.com/r/zhicwu/biserver-ce/

## What's inside
```
ubuntu:16.04
 |
 |-- phusion/baseimage:latest
      |
      |-- zhicwu/java:8
           |
           |-- zhicwu/biserver-ce:6.1
```
* Official Ubuntu 16.04 LTS docker image
* Latest [Phusion Base Image](https://github.com/phusion/baseimage-docker)
* Oracle JDK 8 latest release
* [Pentaho BI Server Community Edition](http://community.pentaho.com/) 6.1.0.1-196 with plugins and patches:
 * [BTable](https://sourceforge.net/projects/btable/)
 * [Community Text Editor](http://www.webdetails.pt/ctools/cte/)
 * [D3 Component Library](https://github.com/webdetails/d3ComponentLibrary)
 * Up-to-date JDBC drivers: [MySQL Connector/J](http://dev.mysql.com/downloads/connector/j/) 5.1.40, [jTDS](https://sourceforge.net/projects/jtds/) 1.3.1 and [Cassandra JDBC Driver](https://github.com/zhicwu/cassandra-jdbc-driver) 0.6.1
 * [Saiku](http://community.meteorite.bi/) - enabled SaikuWidgetComponent in CDE
 * [XMLA Provider](https://sourceforge.net/projects/xmlaconnect/) 1.0.0.103 - download from Help -> Document popup and install on your windows box

## How to use
- Run vanilla Pentaho server
```
$ docker run --name bi -p 28080:8080 -d zhicwu/biserver-ce:6.1 biserver
$ docker logs -f bi
```
- Run patched Pentaho server
```
$ docker run --name bi -e APPLY_PATCHES=Y -p 28080:8080 -d zhicwu/biserver-ce:6.1 biserver
$ docker logs -f bi
```
- Use docker-compose(Recommended)
```
$ git clone https://github.com/zhicwu/docker-biserver-ce.git -b 6.1 --single-branch
$ cd docker-biserver-ce
... make changes to .env and docker-compose.yml as needed ...
$ docker-compose up -d
$ docker-compose logs -f
```

Regardless which approach you took, after server started, you should be able to access [http://localhost:28080](http://localhost:28080) using admin/password.

## How to build
```
$ git clone https://github.com/zhicwu/docker-biserver-ce.git -b 6.1 --single-branch
$ cd docker-biserver-ce
$ docker build -t my/biserver:6.1 .
```
