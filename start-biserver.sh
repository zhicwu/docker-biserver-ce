#!/bin/bash
DOCKER_IMAGE="zhicwu/biserver-ce"
DOCKER_ALIAS="bi"
DOCKER_TAG="latest"

ENV_CONF_FILE="biserver-env.sh"

cdir="`dirname "$0"`"
cdir="`cd "$cdir"; pwd`"

[[ "$TRACE" ]] && set -x

_log() {
  [[ "$2" ]] && echo "[`date +'%Y-%m-%d %H:%M:%S.%N'`] - $1 - $2"
}

info() {
  [[ "$1" ]] && _log "INFO" "$1"
}

warn() {
  [[ "$1" ]] && _log "WARN" "$1"
}

load_conf() {
  info "Load environment variables from $cdir/$ENV_CONF_FILE..."
  if [ -f $cdir/$ENV_CONF_FILE ]
  then
    . "$cdir/$ENV_CONF_FILE"
  else
    warn "Skip $ENV_CONF_FILE as it does not exist"
  fi
}

setup_env() {
  # check environment variables and set defaults as required
  : ${EXT_DIR:="$cdir/ext"}
  : ${LOG_DIR:="$cdir/log"}

  : ${BISERVER_URL:="http://localhost:8080/pentaho/"}
  : ${LOCALE_LANGUAGE:="en"}
  : ${LOCALE_COUNTRY:="US"}

  info "Loaded environment variables:"
  info "	EXT_DIR = $EXT_DIR"
  info "	LOG_DIR = $LOG_DIR"
  info "	BISERVER_URL    = $BISERVER_URL"
  info "	LOCALE_LANGUAGE = $LOCALE_LANGUAGE"
  info "	LOCALE_COUNTRY  = $LOCALE_COUNTRY"
}

setup_dir() {
  for i in $EXTDIR $LOGDIR; do
    if [ -d $i ]; then
      info "Reuse existing directory: $i"
    else
      info "Creating directory: $i"
      mkdir -p $i
    fi
  done
}

start_container() {
  info "Stop and remove \"$DOCKER_ALIAS\" if it exists and start new one"
  # stop and remove the container if it exists
  docker stop "$DOCKER_ALIAS" >/dev/null 2>&1 && docker rm "$DOCKER_ALIAS" >/dev/null 2>&1

  # use --privileged=true has the potential risk of causing clock drift
  # references: http://stackoverflow.com/questions/24288616/permission-denied-on-accessing-host-directory-in-docker
  docker run -d --name="$DOCKER_ALIAS" --net=host --restart=always \
    -e BISERVER_URL="$BISERVER_URL" -e LOCALE_LANGUAGE="$LOCALE_LANGUAGE" -e LOCALE_COUNTRY="$LOCALE_COUNTRY" \
    -v $EXT_DIR:/biserver-ce/ext:Z -v $LOG_DIR:/biserver-ce/tomcat/logs:Z \
    $DOCKER_IMAGE:$DOCKER_TAG

  info "Try 'docker logs -f \"$DOCKER_ALIAS\"' to see if this works"
}

main() {
  load_conf
  setup_env
  setup_dir
  start_container
}

main "$@"
