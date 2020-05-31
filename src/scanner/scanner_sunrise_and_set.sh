#!/bin/bash

source $HOME/.config/fmlist_scan/config
# FMLIST_SUNRISE_TIME="0326"   # sunrise in 4 digit format 'HHMM'
# FMLIST_SUNSET_TIME="1919"    # sunset  in 4 digit format 'HHMM'

if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

if [ -z "${FMLIST_SUNRISE_TIME}" ] || [ -z "${FMLIST_SUNSET_TIME}" ]; then
  echo "Error: FMLIST_SUNRISE_TIME or FMLIST_SUNSET_TIME not set"
  echo "assume night"
  exit 1
fi

CURTIME=$(date +%H%M)

echo "${FMLIST_SUNRISE_TIME}"
echo "${FMLIST_SUNSET_TIME}"
echo "${CURTIME}"

if [ ${FMLIST_SUNRISE_TIME} -lt ${FMLIST_SUNSET_TIME} ]; then
  if [ ${CURTIME} -lt ${FMLIST_SUNRISE_TIME} ]; then
    echo "night"
  elif [ ${CURTIME} -gt ${FMLIST_SUNSET_TIME} ]; then
    echo "night"
  else
    echo "daylight"
  fi
else
  if [ ${CURTIME} -gt ${FMLIST_SUNRISE_TIME} ]; then
    echo "daylight"
  elif [ ${CURTIME} -lt ${FMLIST_SUNSET_TIME} ]; then
    echo "daylight"
  else
    echo "night"
  fi
fi

