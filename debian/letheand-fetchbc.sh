#!/bin/sh

. /etc/default/lethean-daemon

if [ "$(whoami)" != "lthn" ]; then
  echo "This script must be run as lthn user."
  exit 3
fi

if [ -z "${LETHEAND_LMDB}" ] || [ -z "${ZSYNC_URL}" ]; then
  echo $0 [force] >&2
  echo This script will fetch BC data using zsync from remote url ZSYNC_URL=${ZSYNC_URL} into LETHEAND_LMDB=${LETHEAND_LMDB}. If force is set, it will remove local BC data and refetch. >&2
  exit
fi

download(){
  if ! fuser -s ${LETHEAND_LMDB}/data.mdb; then
    echo "Downloading blockchain data. It can take long time. Be patient.." >&2
    mkdir -p ${LETHEAND_LMDB} \
    && cd ${LETHEAND_LMDB} \
    && rm -f data.mdb.zsync && \
    wget "$ZSYNC_URL" && zsync data.mdb.zsync;
  else
    echo "${LETHEAND_LMDB}/data.mdb in use by "$(fuser -v ${LETHEAND_LMDB}/data.mdb) '! Not downloading.' >&2
  fi
}

if [ -f ${LETHEAND_LMDB}/data.mdb ] && [ "$1" = "force" ] ; then \
  echo "Downloading new blockchain data from ${ZSYNC_URL}"
  shift
  download
else
  if ! [ -f ${LETHEAND_LMDB}/data.mdb ]; then
    echo "Downloading blockchain data from ${ZSYNC_URL}" >&2
    download
  else
    echo "Not touching blockchain data. use $0 force to redownload." >&2
  fi
fi

if [ "$1" = "run" ]; then
  shift
  exec "$@"
fi
