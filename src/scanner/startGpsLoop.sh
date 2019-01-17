#!/bin/bash

export LC_ALL=C
source $HOME/.config/fmlist_scan/config
if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi


rm -f "${FMLIST_SCAN_RAM_DIR}/stopGps"
rm -f "${FMLIST_SCAN_RAM_DIR}/gpscoor.log"
echo "FMLIST_SCAN_SETUP_GPS = ${FMLIST_SCAN_SETUP_GPS}" >${FMLIST_SCAN_RAM_DIR}/gpstime.log
if [ "${FMLIST_SCAN_SETUP_GPS}" = "1" ] || [ "${FMLIST_SCAN_GPS_ALL_TIME}" = "1" ]; then
  echo "check for already running screen session .."
  GSESSION="$( screen -ls | grep gpsLoopBg )"
  if [ -z "$GSESSION" ]; then
    echo "starting gpstime.sh in background with log to ${FMLIST_SCAN_RAM_DIR}/gpstime.log"
    echo "starting gpstime.sh in background with log to ${FMLIST_SCAN_RAM_DIR}/gpstime.log" >>${FMLIST_SCAN_RAM_DIR}/gpstime.log
    screen -d -m -S gpsLoopBg nice -n 15 "$HOME/bin/gpstime.sh"
    sleep 2
    GSESSION="$( screen -ls | grep gpsLoopBg )"
    if [ -z "$GSESSION" ]; then
      echo "Error starting screen session"
      exit 10
    fi
  else
    echo "screen session with gpstime.sh already running"
    echo "screen session with gpstime.sh already running" >>${FMLIST_SCAN_RAM_DIR}/gpstime.log
  fi
else
  echo "NOT starting gpstime.sh in background with log to ${FMLIST_SCAN_RAM_DIR}/gpstime.log"
  echo "NOT starting gpstime.sh in background with log to ${FMLIST_SCAN_RAM_DIR}/gpstime.log" >>${FMLIST_SCAN_RAM_DIR}/gpstime.log
fi


