#!/bin/bash

export DOMAIN_NAME=localhost
export SECRET_KEY_BASE=localhost
HOMEDIR="$PWD"
RUNDIR="$HOMEDIR"
DAEMON="thin"
CONFIG=" -d -e production"

(                                                                                                                       
  cd $RUNDIR
  case $1 in
    start)
      exec $DAEMON $CONFIG start
      ;;
    stop)
      exec $DAEMON $CONFIG stop 2>/dev/null
      ;;
    restart)
      $DAEMON $CONFIG stop 2>/dev/null
      sleep 1
      exec $DAEMON $CONFIG start
      ;;
    *)
      echo "Usage: run.sh start/stop/restart"
      ;;
  esac
)
