#!/bin/bash

source $HOME/.config/fmlist_scan/config
if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

export LC_ALL=C
cd "${FMLIST_SCAN_RAM_DIR}"

while /bin/true; do
  clear
  echo ""
  cat gpscoor.log
  echo -en "\nLast found station: "
  cat LAST

  CURR="$(date -u +%s)"
  LAST="$(stat -c %Y ${FMLIST_SCAN_RAM_DIR}/LAST)"
  D=$[ $CURR - $LAST ]
  echo "Delta from LAST to CURR = $D secs"

  echo ""
  tail -n 10 checkBgScanLoop.log | grep -v "Delta from LAST to CURR"
  sleep 2
done
