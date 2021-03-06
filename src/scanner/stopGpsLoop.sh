#!/bin/bash

export LC_ALL=C
source $HOME/.config/fmlist_scan/config
if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

if [ ! "${FMLIST_SCAN_GPS_ALL_TIME}" = "1" ] || [ "$1" = "force" ] ; then
  touch "${FMLIST_SCAN_RAM_DIR}/stopGps"
  rm -f "${FMLIST_SCAN_RAM_DIR}/gpscoor.log"
elif [ "$1" = "silent" ]; then
  echo "" >/dev/null
else
  echo "usage: $0 [force|silent]"
fi

