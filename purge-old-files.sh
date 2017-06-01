#!/bin/bash
[[ "$TRACE" ]] && set -x

log() {
  [[ "$2" ]] && echo "[`date +'%Y-%m-%d %H:%M:%S.%N'`] - $1 - $2"
}

log "INFO" "Removing temporary files that have not been modified within one day under $BISERVER_HOME/tomcat/temp directory..."
find $BISERVER_HOME/tomcat/temp/* -maxdepth 0 -type f -name "*.*" -mtime +1 | xargs rm -f
log "INFO" "Removing log files created 21 days ago under /tmp/kettle and $BISERVER_HOME/tomcat/logs directories..."
find /tmp/kettle $BISERVER_HOME/tomcat/logs -type f -iname "*.log" -o -iname "*.txt" -mtime +21 | xargs rm -f
log "INFO" "Done"
