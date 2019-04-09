#!/bin/sh

. /etc/default/lethean-daemon

if [ "$(whoami)" != "lthn" ]; then
  echo "This script must be run as lthn user."
  exit 3
fi

if [ -z "${LETHEAND_LMDB}" ] || [ -z "${ZSYNC_URL}" ]; then
  echo $0 [force]
  echo This script will fetch BC data using zsync from remote url ZSYNC_URL=${ZSYNC_URL} into LETHEAND_LMDB=${LETHEAND_LMDB}. If force is set, it will remove local BC data and refetch.
  exit 2
fi

download(){
  if ! fuser -s ${LETHEAND_LMDB}/data.mdb; then
    mkdir -p ${LETHEAND_LMDB} \
    && cd ${LETHEAND_LMDB} \
    && rm -f data.mdb.zsync && \
    wget "$ZSYNC_URL" && zsync data.mdb.zsync && zsync data.mdb.zsync;
  else
    echo "${LETHEAND_LMDB}/data.mdb in use by "$(fuser -v ${LETHEAND_LMDB}/data.mdb) '! Not downloading.'
  fi
}

if [ -f ${LETHEAND_LMDB}/data.mdb ] && [ "$1" = "force" ] ; then \
  echo "Downloading new blockchain data from ${ZSYNC_URL}"
  download
else
  if ! [ -f ${LETHEAND_LMDB}/data.mdb ]; then
    echo "Downloading blockchain data from ${ZSYNC_URL}"
    download
  else
    echo "Not touching blockchain data. use $0 force to redownload."
  fi
fi

if [ "$1" = "run" ]; then
  shift
  exec "$@"
fi
