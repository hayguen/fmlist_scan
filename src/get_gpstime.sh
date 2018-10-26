#!/bin/bash

source $HOME/.config/fmlist_scan/config
if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

cd ${FMLIST_SCAN_RAM_DIR}
COOR=$( ( flock -x 213 ; cat gpscoor.log 2>/dev/null ) 213>gps.lock )
if [ -z "$COOR" ]; then
  COOR="NO-GPS_SYSTIME $(date -u "+%Y-%m-%dT%T.%NZ")"
fi
echo "$COOR"

