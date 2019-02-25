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

if [ $D -ge 60 ]; then
  DTF="$(date -u "+%Y-%m-%dT%T Z")"
  echo "${DTF}: checkBgScanLoop.sh: Error: No stations in last $D seconds!" >>${FMLIST_SCAN_RESULT_DIR}/checkBgScanLoop.log
fi

if [ $D -ge ${FMLIST_SCAN_DEAD_TIME} ]; then
  DTF="$(date -u "+%Y-%m-%dT%T Z")"
  echo "${DTF}: No stations in last $D seconds!"
  echo "${DTF}: checkBgScanLoop.sh: Error: No stations in last $D seconds!" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
  echo "${DTF}: checkBgScanLoop.sh: Error: No stations in last $D seconds!" >>${FMLIST_SCAN_RAM_DIR}/checkBgScanLoop.log
  echo "${DTF}: checkBgScanLoop.sh: Error: No stations in last $D seconds!" >>${FMLIST_SCAN_RESULT_DIR}/checkBgScanLoop.log

  if [ ${FMLIST_SCAN_DEAD_REBOOT} -ne 0 ]; then
    NSSH=$(sudo netstat -tpn |grep '^tcp' |grep ESTABLISHED |awk '{ print $7; }' |grep -c '/sshd')
    if [ ${NSSH} -eq 0 ]; then
      echo "going for reboot. reboot is activated in $HOME/.config/fmlist_scan/config"
      echo "${DTF}: checkBgScanLoop.sh: after $D seconds: saving results, then rebooting .." >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      echo "${DTF}: checkBgScanLoop.sh: after $D seconds: saving results, then rebooting .." >>${FMLIST_SCAN_RAM_DIR}/checkBgScanLoop.log
      echo "${DTF}: checkBgScanLoop.sh: after $D seconds: saving results, then rebooting .." >>${FMLIST_SCAN_RESULT_DIR}/checkBgScanLoop.log
      saveScanResults.sh savelog
      echo "${DTF}: checkBgScanLoop.sh: after $D seconds: rebooting!" >>${FMLIST_SCAN_RESULT_DIR}/checkBgScanLoop.log
      sudo reboot now >>${FMLIST_SCAN_RESULT_DIR}/checkBgScanLoop.log
    else
      echo "would go for reboot .. but there are active ssh sessions"
      echo "${DTF}: checkBgScanLoop.sh: after $D seconds: would go for reboot - but there are active ssh sessions" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      echo "${DTF}: checkBgScanLoop.sh: after $D seconds: would go for reboot - but there are active ssh sessions" >>${FMLIST_SCAN_RAM_DIR}/checkBgScanLoop.log
      echo "${DTF}: checkBgScanLoop.sh: after $D seconds: would go for reboot - but there are active ssh sessions" >>${FMLIST_SCAN_RESULT_DIR}/checkBgScanLoop.log
      saveScanResults.sh savelog
      wall "checkBgScanLoop.sh: Error: No stations in last $D seconds! Would go for reboot - but there are active ssh sessions!"
    fi
  else
    SSESSION="$( screen -ls | grep scanLoopBg )"
    if [ -z "$SSESSION" ]; then
      echo "scanLoopBg screen session is not running! saving results, then restarting scanLoop .."
      echo "${DTF}: checkBgScanLoop.sh: after $D seconds: scanLoopBg screen session is not running! saving results, then restarting scanLoop .." >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      echo "${DTF}: checkBgScanLoop.sh: after $D seconds: scanLoopBg screen session is not running! saving results, then restarting scanLoop .." >>${FMLIST_SCAN_RAM_DIR}/checkBgScanLoop.log
      echo "${DTF}: checkBgScanLoop.sh: after $D seconds: scanLoopBg screen session is not running! saving results, then restarting scanLoop .." >>${FMLIST_SCAN_RESULT_DIR}/checkBgScanLoop.log
      saveScanResults.sh savelog
      resetScanDevice.sh all
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
      echo "${DTF}: checkBgScanLoop.sh: after $D seconds: scanLoopBg screen session is hanging! killing session, saving results, then restarting scanLoop .." >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      echo "${DTF}: checkBgScanLoop.sh: after $D seconds: scanLoopBg screen session is hanging! killing session, saving results, then restarting scanLoop .." >>${FMLIST_SCAN_RAM_DIR}/checkBgScanLoop.log
      echo "${DTF}: checkBgScanLoop.sh: after $D seconds: scanLoopBg screen session is hanging! killing session, saving results, then restarting scanLoop .." >>${FMLIST_SCAN_RESULT_DIR}/checkBgScanLoop.log
      stopBgScanLoop.sh
      resetScanDevice.sh all
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

