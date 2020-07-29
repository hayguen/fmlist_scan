#!/bin/bash

if [ -z "${FMLIST_SCAN_RAM_DIR}" ]; then
  source $HOME/.config/fmlist_scan/config
  if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
    mkdir -p "${FMLIST_SCAN_RAM_DIR}"
  fi
fi

export LC_ALL=C
cd "${FMLIST_SCAN_RAM_DIR}"

  cat gpscoor.log
  if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    echo -e "Temperature: $(cat /sys/class/thermal/thermal_zone0/temp | sed -e 's/\([0-9][0-9][0-9]\)$/.\1/g' ) deg"
  fi
  if [ -f LAST ]; then
    echo -en "\nLast found station: "
    sed -e 's/0000$//g' -e 's/\([0-9][0-9]\)$/.\1 MHz/g' LAST

    CURR="$(date -u +%s)"
    LAST="$(stat -c %Y ${FMLIST_SCAN_RAM_DIR}/LAST)"
    D=$[ $CURR - $LAST ]
    echo "Delta from LAST to CURR = $D secs"
  else
    echo "Scanner should not run. No Last found station."
  fi
  echo "Scanner scanLoop is$( screen -ls |grep -c 'scanLoopBg' | sed 's/^0$/ NOT/g' |sed 's/^1$//g' ) running in screen."
  echo ""
  tail -n 10 checkBgScanLoop.log | grep -v "Delta from LAST to CURR"
