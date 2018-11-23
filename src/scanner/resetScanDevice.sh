#!/bin/bash

source "$HOME/.config/fmlist_scan/config"
if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

type="$1"

if [ "${type}" = "fm" ]; then
  if [ -z "${FMLIST_FM_RTLSDR_DEV}" ]; then
    echo "reset requires config entry 'FMLIST_FM_RTLSDR_DEV' with the serial number of the device!"
    exit 10
  fi
  powerOff_rtl_by_serial.sh scanDAB "${FMLIST_FM_RTLSDR_DEV}"
  sleep 1
  powerOn_rtl_by_serial.sh scanDAB
  exit 0

elif [ "${type}" = "dab" ]; then
  if [ -z "${FMLIST_DAB_RTLSDR_DEV}" ]; then
    echo "reset requires config entry 'FMLIST_DAB_RTLSDR_DEV' with the serial number of the device!"
    exit 10
  fi
  powerOff_rtl_by_serial.sh scanDAB "${FMLIST_DAB_RTLSDR_DEV}"
  sleep 1
  powerOn_rtl_by_serial.sh scanDAB
  exit 0

else
  echo "usage: $0 fm|dab"
  exit 10
fi

