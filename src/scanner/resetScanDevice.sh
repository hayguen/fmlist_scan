#!/bin/bash

source "$HOME/.config/fmlist_scan/config"
if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

type="$1"

if [ "${type}" = "all" ]; then
  for N in $(echo "1 2 3 4") ; do
    SN=$(rtl_test 2>&1 |grep Realtek |head -n $N |nl |tail -n 1 |sed "s/^\s*${N}\s*/MATCHED_RTL/g" |grep "^MATCHED_RTL" |sed 's/.*SN: //g')
    if [ -z "${SN}" ]; then
      exit 0
    fi
    echo "resetting device $N with serial ${SN}"
    powerOff_rtl_by_serial.sh scanDAB "${SN}"
    sleep 1
    powerOn_rtl_by_serial.sh scanDAB
    sleep 0.5
  done
  echo "for finished"
  exit 0

elif [ "${type}" = "fm" ]; then
  SN="${FMLIST_FM_RTLSDR_DEV}"
  if [ -z "${SN}" ]; then
    echo "reset requires config entry 'FMLIST_FM_RTLSDR_DEV' with the serial number of the device!"
    exit 10
  fi
  powerOff_rtl_by_serial.sh scanDAB "${SN}"
  sleep 1
  powerOn_rtl_by_serial.sh scanDAB
  exit 0

elif [ "${type}" = "dab" ]; then
  SN="${FMLIST_DAB_RTLSDR_DEV}"
  if [ -z "${SN}" ]; then
    echo "reset requires config entry 'FMLIST_DAB_RTLSDR_DEV' with the serial number of the device!"
    exit 10
  fi
  powerOff_rtl_by_serial.sh scanDAB "${SN}"
  sleep 1
  powerOn_rtl_by_serial.sh scanDAB
  exit 0

else
  echo "usage: $0 fm|dab|all"
  exit 10
fi

