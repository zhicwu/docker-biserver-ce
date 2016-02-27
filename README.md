# docker-biserver-ce
Pentaho BI server(community edition) docker image for development and testing purposes. https://hub.docker.com/r/zhicwu/biserver-ce/

## What's inside
```
ubuntu:14.04
 |
 |--- zhicwu/java:8
       |
       |--- zhicwu/biserver:latest
```
* Official Ubuntu Trusty(14.04) docker image
* Oracle JDK 8 latest release
* [Pentaho BI Server Community Editionl](http://community.pentaho.com/) 6.0.1.0-386 with plugins and patches:
 * [BTable](https://sourceforge.net/projects/btable/)
 * [Community Startup Tabs](http://www.webdetails.pt/ctools/cst/)
 * [Community Text Editor](http://www.webdetails.pt/ctools/cte/)
 * [D3 Component Library](https://github.com/webdetails/d3ComponentLibrary)
 * [FusionCharts](http://www.xpand-it.com/en/solutions-en/pentaho-fusioncharts-plugin-en) - registration required
 * Up-to-date JDBC drivers including: Apache Drill, MySQL, jTDS (Sybase / SQL Server) and Presto
 * [Pivot4J](http://www.pivot4j.org/)
 * [Saiku](http://community.meteorite.bi/) - enabled SaikuWidgetComponent in CDE
 * [WAQR](http://ci.pentaho.com/job/WAQR-Plugin/)

## Known issues
* You need to patch Presto's JDBC driver so that it works with PDI and Mondiran

## How to use
- Pull the image
```
# docker pull zhicwu/biserver-ce
```
- Setup scripts
```
# git clone https://github.com/zhicwu/docker-biserver-ce.git
# cd docker-biserver-ce
# chmod +x *.sh
```
- Edit biserver-env.sh and/or put your Pentaho configuration files under ext directory
- Start BI Server
```
# ./start-biserver.sh
# docker logs -f bi
```
You can now access the web UI via http://localhost:8080.

## How to build
```
# git clone https://github.com/zhicwu/docker-biserver-ce.git
# cd docker-biserver-ce
# chmod +x *.sh
# docker build -t zhicwu/biserver-ce .
```
