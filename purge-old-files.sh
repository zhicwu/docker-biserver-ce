#!/bin/bash
[ "$TRACE" ] && set -x

: ${BISERVER_HOME:="/biserver-ce"}

_LOG_FILE=$BISERVER_HOME/tomcat/logs/purge.log

[ -f ${_LOG_FILE}.old ] && rm -f ${_LOG_FILE}.old
[ -f ${_LOG_FILE} ] && mv $_LOG_FILE ${_LOG_FILE}.old

log() {
  [ "$2" ] && echo "[`date +'%Y-%m-%d %H:%M:%S.%N'`] - $1 - $2" >> $_LOG_FILE
}

log "INFO" "Removing temporary files modified and read two days ago(or older) under $BISERVER_HOME/tomcat/temp directory..."
find $BISERVER_HOME/tomcat/temp/ -maxdepth 1 -type f -atime +2 -a -mtime +2 | xargs rm -fv >> $_LOG_FILE
log "INFO" "Removing log files modified 14 days ago(or older) under /tmp/kettle and $BISERVER_HOME/tomcat/logs directories..."
find /tmp/kettle/ $BISERVER_HOME/tomcat/logs/ -mtime +14 | xargs rm -rfv >> $_LOG_FILE
log "INFO" "Done"