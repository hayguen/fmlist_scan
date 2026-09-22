#!/bin/bash
clear

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

watch -t -n "$SLEEPDUR" 'echo ""; statusBgScanLoop.sh; echo ""; get_throttled.sh'
