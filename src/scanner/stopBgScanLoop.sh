#!/bin/bash

source $HOME/.config/fmlist_scan/config
if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

# new desired state
rm -f ${FMLIST_SCAN_RAM_DIR}/scanLoopBgRunning

if [ ! -z "$1" ] && [ ! "$1" = "abort" ] && [ ! "$1" = "wait" ]; then
  echo "unrecognized option '$1': expected 'abort' or 'wait'"
fi

if [ "$1" = "abort" ]; then
  shift
  touch "${FMLIST_SCAN_RAM_DIR}/abortScanLoop"
fi

touch "${FMLIST_SCAN_RAM_DIR}/stopScanLoop"


stopGpsLoop.sh silent

if [ "$1" = "wait" ]; then
  shift
  waitScreenTermination.sh scanLoopBg "$@"
fi

