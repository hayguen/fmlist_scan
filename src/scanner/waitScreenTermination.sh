#!/bin/bash

SCR_SESSION="$1"
TIMEOUT="$2"

if [ -z "${SCR_SESSION}" ] ; then
  echo "usage: $0 <session_name> <timeout>"
  exit 10
fi

N="0"
while screen -list | grep -q "${SCR_SESSION}" ; do
  echo "screen '${SCR_SESSION}' is running. wait 1 sec .."
  sleep 1
  N=$[ $N + 1 ]
  if [ ! -z "${TIMEOUT}" ] ; then
    if [ ${N} -ge ${TIMEOUT} ]; then
      echo "timeout over .. screen session still running!"
      exit 10
    fi
  fi
done
echo "screen '${SCR_SESSION}' is finished"
exit 0
