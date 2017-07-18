# docker-biserver-ce
Base docker image of Pentaho Server(community edition). https://hub.docker.com/r/zhicwu/biserver-ce/

## Hierarchy
```
ubuntu:16.04
 |- phusion/baseimage:0.9.22
    |- zhicwu/java:8
       |- zhicwu/biserver-ce:7.1-base
```
* Official Ubuntu 16.04 LTS docker image
* [Phusion Base Image](https://github.com/phusion/baseimage-docker) 0.9.22
* Oracle JDK 8 latest release
* [Pentaho BI Server Community Edition](http://community.pentaho.com/) 7.1.0.0-12 with APR

## Quick Start
```
$ docker run --name bi -p 8080:8080 -d zhicwu/biserver-ce:7.1-base
$ docker logs -f bi
```
Now you should be able to access Pentaho Server at http://localhost:8080

## How to Build
```
$ git clone https://github.com/zhicwu/docker-biserver-ce.git -b 7.1-base --single-branch
$ cd docker-biserver-ce
$ docker build -t my/biserver:7.1 .
```