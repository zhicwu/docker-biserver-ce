#!/bin/bash
[[ "$TRACE" ]] && set -x

log() {
  [[ "$2" ]] && echo "[`date +'%Y-%m-%d %H:%M:%S.%N'`] - $1 - $2"
}

log "INFO" "Removing temporary files that have not been accessed within one day under $BISERVER_HOME/tomcat/temp directory..."
find $BISERVER_HOME/tomcat/temp/* -maxdepth 0 -name "*.*" -atime +1 | xargs rm -f
log "INFO" "Removing log files created 21 days ago under /tmp/kettle directory..."
find /tmp/kettle -name "*.log" -mtime +21 | xargs rm -f
log "INFO" "Done"
