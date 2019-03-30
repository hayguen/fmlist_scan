#!/bin/bash

source $HOME/.config/fmlist_scan/config
if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

if [ "$1" = "abort" ]; then
  shift
  touch "${FMLIST_SCAN_RAM_DIR}/abortScanLoop"
fi

touch "${FMLIST_SCAN_RAM_DIR}/stopScanLoop"
rm -f ${FMLIST_SCAN_RAM_DIR}/scanLoopBgRunning

stopGpsLoop.sh silent

if [ "$1" = "wait" ]; then
  shift
  waitScreenTermination.sh scanLoopBg "$@"
fi

