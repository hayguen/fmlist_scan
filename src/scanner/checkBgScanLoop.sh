#!/bin/bash

export LC_ALL=C
source $HOME/.config/fmlist_scan/config
if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

DTF="$(date -u "+%Y-%m-%dT%T Z")"
echo "checkBgScanLoop.sh: last start at ${DTF}" >${FMLIST_SCAN_RAM_DIR}/checkBgScanLoop.log

if [ ! -f ${FMLIST_SCAN_RAM_DIR}/scanLoopBgRunning ]; then
  echo "scan Loop not running -> no check"
  echo "scan Loop not running -> no check" >>${FMLIST_SCAN_RAM_DIR}/checkBgScanLoop.log
  exit 0
fi


CURR="$(date -u +%s)"
LAST="$(stat -c %Y ${FMLIST_SCAN_RAM_DIR}/LAST)"
D=$[ $CURR - $LAST ]

echo "Delta from LAST to CURR = $D secs"
echo "Delta from LAST to CURR = $D secs" >>${FMLIST_SCAN_RAM_DIR}/checkBgScanLoop.log

if [ $D -ge ${FMLIST_SCAN_DEAD_TIME} ]; then
  DTF="$(date -u "+%Y-%m-%dT%T Z")"
  echo "${DTF}: No stations in last $D seconds!"
  echo "${DTF}: checkBgScanLoop.sh: Error: No stations in last $D seconds!" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
  echo "${DTF}: checkBgScanLoop.sh: Error: No stations in last $D seconds!" >>${FMLIST_SCAN_RAM_DIR}/checkBgScanLoop.log

  if [ ${FMLIST_SCAN_DEAD_REBOOT} -ne 0 ]; then
    echo "going for reboot. reboot is activated in $HOME/.config/fmlist_scan/config"
    echo "${DTF}: checkBgScanLoop.sh: saving results, then rebooting .." >>${FMLIST_SCAN_RAM_DIR}/scanner.log
    echo "${DTF}: checkBgScanLoop.sh: saving results, then rebooting .." >>${FMLIST_SCAN_RAM_DIR}/checkBgScanLoop.log
    saveScanResults.sh savelog
    sudo reboot now
  else
    SSESSION="$( screen -ls | grep scanLoopBg )"
    if [ -z "$SSESSION" ]; then
      echo "scanLoopBg screen session is not running! saving results, then restarting scanLoop .."
      echo "${DTF}: checkBgScanLoop.sh: scanLoopBg screen session is not running! saving results, then restarting scanLoop .." >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      echo "${DTF}: checkBgScanLoop.sh: scanLoopBg screen session is not running! saving results, then restarting scanLoop .." >>${FMLIST_SCAN_RAM_DIR}/checkBgScanLoop.log
      saveScanResults.sh savelog
      pkill scanFM.sh
      pkill scanDAB.sh
      pkill dab-rtlsdr
      pkill rtl_sdr
      pkill redsea
      pkill csdr
      pkill pipwm
      pkill checkSpectrumForCarrier
      pkill prescanDAB
      startBgScanLoop.sh
    else
      echo "scanLoopBg screen session is hanging! killing session, saving results, then restarting scanLoop .."
      echo "${DTF}: checkBgScanLoop.sh: scanLoopBg screen session is hanging! killing session, saving results, then restarting scanLoop .." >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      echo "${DTF}: checkBgScanLoop.sh: scanLoopBg screen session is hanging! killing session, saving results, then restarting scanLoop .." >>${FMLIST_SCAN_RAM_DIR}/checkBgScanLoop.log
      stopBgScanLoop.sh
      pkill scanLoop.sh
      pkill scanFM.sh
      pkill scanDAB.sh
      pkill dab-rtlsdr
      pkill rtl_sdr
      pkill redsea
      pkill csdr
      pkill pipwm
      pkill checkSpectrumForCarrier
      pkill prescanDAB
      saveScanResults.sh savelog
      startBgScanLoop.sh
    fi
  fi
fi

