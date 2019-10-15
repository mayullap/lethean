#!/bin/sh

# Letheand wrapper script for debian

. /etc/default/lethean-daemon

case $1 in
start)
  shift
  if [ "$(whoami)" = "root" ]; then
    mkdir -p /var/run/lthn
    chown lthn:lthn /var/run/lthn -R
    chmod 770 /var/run/lthn
    echo "Switching to lthn user." >&2
    sleep 1
    exec su -s /bin/sh lthn $0 start2
  else
    exec $0 start2
  fi
  ;;
start2)
  shift
  if ! [ -w "${LETHEAND_DATA}" ]; then
    echo "You need write permissions to /var/lib/lthn ! Exiting."
    exit 2
  fi
  ZSYNCPID=$(pidof zsync)
  if [ -n "$ZSYNCPID" ]; then
    $0 status
    exit 2 
  fi
  if ! [ -f "${LETHEAND_LMDB}/data.mdb" ]; then
    /usr/lib/lthn/letheand-fetchbc.sh
  fi
  exec /usr/bin/letheand.bin --non-interactive --standard-json --config-file ${LETHEAND_CONFIG} --pidfile ${LETHEAND_PID} --log-file ${LETHEAND_LOG} --data-dir ${LETHEAND_DATA} "$@"
  ;;
status)
  shift
  ZSYNCPID=$(pidof zsync)
  DAEMONPID=$(pidof letheand.bin)
  BCSIZE=$(du -h ${LETHEAND_LMDB})
  echo
  if [ -n "$ZSYNCPID" ]; then
    echo "!! We are fast syncing blockchain now. Please wait until synced."
    echo "Pid of sync process: $ZSYNCPID"
    echo
  fi
  if [ -n "$DEAMONPID" ]; then
    echo "* Blockchain daemon is running with Pid $DAEMONPID"
    echo "You can see more info in /var/log/lthn directory."
  else
    echo "** Blockchain daemon is not running"
  fi
  echo "* Blockchain data:"
  ls -lah ${LETHEAND_LMDB}
  echo
  ;;
stop)
  shift
  systemctl stop lethean-daemon
  ;;
fetchbc)
  shift
  $0 stop
  exec /usr/lib/lthn/letheand-fetchbc.sh force
  ;;
cleanbc)
  shift
  $0 stop
  if [ -n "${LETHEAND_LMDB}" ]; then
    rm ${LETHEAND_LMDB}/*
  fi
  ;;
*)
  echo "Letheand wrapper script for debian."
  echo "Use $0 start|stop|status|fetchbc|cleanbc"
  echo "Exiting"
  exit 2
  ;;
esac
