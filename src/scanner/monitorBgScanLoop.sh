#!/bin/bash

source $HOME/.config/fmlist_scan/config
if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

if [ -z "$1" ]; then
  SLEEPDUR="2"
else
  SLEEPDUR="$1"
fi

export LC_ALL=C
cd "${FMLIST_SCAN_RAM_DIR}"

while /bin/true; do
  clear
  echo ""
  statusBgScanLoop.sh
  sleep "${SLEEPDUR}"
done
