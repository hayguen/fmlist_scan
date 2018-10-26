#!/bin/bash

source $HOME/.config/fmlist_scan/config
if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

touch "${FMLIST_SCAN_RAM_DIR}/stopScanLoop"
rm -f ${FMLIST_SCAN_RAM_DIR}/scanLoopBgRunning

