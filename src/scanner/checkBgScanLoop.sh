#!/bin/bash

export LC_ALL=C
source $HOME/.config/fmlist_scan/config
if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

DTF="$(date -u "+%Y-%m-%dT%T Z")"
echo "checkBgScanLoop.sh: last start at ${DTF}" >${FMLIST_SCAN_RAM_DIR}/checkBgScanLoop.log

if screen -list |grep -q "scanLoopBg" ; then
  echo "scan Loop is running -> continue check"
  echo "scan Loop is running -> continue check" >>${FMLIST_SCAN_RAM_DIR}/checkBgScanLoop.log
else
  echo "scan Loop not running -> no check"
  echo "scan Loop not running -> no check" >>${FMLIST_SCAN_RAM_DIR}/checkBgScanLoop.log
  exit 0
fi


CURR="$(date -u +%s)"
if [ -f "${FMLIST_SCAN_RAM_DIR}/LAST" ]; then
  LAST="$(stat -c %Y ${FMLIST_SCAN_RAM_DIR}/LAST)"
else
  LAST=$[ $CURR - ${FMLIST_SCAN_DEAD_TIME} -1 ]
  echo "No LAST scan results. Setting to CURR - FMLIST_SCAN_DEAD_TIME"
  echo "No LAST scan results. Setting to CURR - FMLIST_SCAN_DEAD_TIME" >>${FMLIST_SCAN_RAM_DIR}/checkBgScanLoop.log
fi
D=$[ $CURR - $LAST ]

echo "Delta from LAST to CURR = $D secs"
echo "Delta from LAST to CURR = $D secs" >>${FMLIST_SCAN_RAM_DIR}/checkBgScanLoop.log

if [ $D -ge 60 ]; then
  DTF="$(date -u "+%Y-%m-%dT%T Z")"
  echo "${DTF}: checkBgScanLoop.sh: Error: No stations in last $D seconds!" >>${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/checkBgScanLoop.log
fi

if [ $D -ge ${FMLIST_SCAN_DEAD_TIME} ]; then
  DTF="$(date -u "+%Y-%m-%dT%T Z")"
  echo "${DTF}: No stations in last $D seconds!"
  echo "${DTF}: checkBgScanLoop.sh: Error: No stations in last $D seconds!" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
  echo "${DTF}: checkBgScanLoop.sh: Error: No stations in last $D seconds!" >>${FMLIST_SCAN_RAM_DIR}/checkBgScanLoop.log
  echo "${DTF}: checkBgScanLoop.sh: Error: No stations in last $D seconds!" >>${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/checkBgScanLoop.log

  if [ ${FMLIST_SCAN_DEAD_REBOOT} -ne 0 ]; then
    NSSH=$(sudo netstat -tpn |grep '^tcp' |grep ESTABLISHED |awk '{ print $7; }' |grep -c '/sshd')
    if [ ${NSSH} -eq 0 ]; then
      echo "going for reboot. reboot is activated in $HOME/.config/fmlist_scan/config"
      echo "${DTF}: checkBgScanLoop.sh: after $D seconds: saving results, then rebooting .." >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      echo "${DTF}: checkBgScanLoop.sh: after $D seconds: saving results, then rebooting .." >>${FMLIST_SCAN_RAM_DIR}/checkBgScanLoop.log
      echo "${DTF}: checkBgScanLoop.sh: after $D seconds: saving results, then rebooting .." >>${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/checkBgScanLoop.log
      saveScanResults.sh savelog
      echo "${DTF}: checkBgScanLoop.sh: after $D seconds: rebooting!" >>${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/checkBgScanLoop.log
      sudo reboot now >>${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/checkBgScanLoop.log
    else
      echo "would go for reboot .. but there are active ssh sessions"
      echo "${DTF}: checkBgScanLoop.sh: after $D seconds: would go for reboot - but there are active ssh sessions" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
      echo "${DTF}: checkBgScanLoop.sh: after $D seconds: would go for reboot - but there are active ssh sessions" >>${FMLIST_SCAN_RAM_DIR}/checkBgScanLoop.log
      echo "${DTF}: checkBgScanLoop.sh: after $D seconds: would go for reboot - but there are active ssh sessions" >>${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/checkBgScanLoop.log
      saveScanResults.sh savelog
      wall "checkBgScanLoop.sh: Error: No stations in last $D seconds! Would go for reboot - but there are active ssh sessions!"
    fi
  else
    SSESSION="$( screen -ls | grep scanLoopBg )"
    if [ -z "$SSESSION" ]; then
      echo "scanLoopBg screen session is not running! saving results, then restarting scanLoop .."
    else
      echo "scanLoopBg screen session is hanging! killing session, saving results, then restarting scanLoop .."
    fi
    echo "${DTF}: checkBgScanLoop.sh: after $D seconds: scanLoopBg screen session is hanging! killing session, repowering dongle, saving results, then restarting .." >>${FMLIST_SCAN_RAM_DIR}/scanner.log
    echo "${DTF}: checkBgScanLoop.sh: after $D seconds: scanLoopBg screen session is hanging! killing session, repowering dongle, saving results, then restarting .." >>${FMLIST_SCAN_RAM_DIR}/checkBgScanLoop.log
    echo "${DTF}: checkBgScanLoop.sh: after $D seconds: scanLoopBg screen session is hanging! killing session, repowering dongle, saving results, then restarting .." >>${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/checkBgScanLoop.log

    echo "${DTF}: PATH=${PATH}" >>${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/checkBgScanLoop.log

    stopBgScanLoop.sh

    pkill scanLoop.sh
    pkill scanFM.sh
    pkill scanDAB.sh
    pkill -9 dab-rtlsdr
    pkill -9 rtl_test
    pkill -9 rtl_sdr
    pkill redsea
    pkill csdr
    pkill pipwm
    pkill checkSpectrumForCarrier
    pkill -9 prescanDAB

    sleep 2

    # resetScanDevice.sh all power 2>&1 |tee -a ${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/checkBgScanLoop.log
    resetScanDevice.sh fm  power 2>&1 |tee -a ${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/checkBgScanLoop.log
    resetScanDevice.sh dab power 2>&1 |tee -a ${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/checkBgScanLoop.log

    pkill scanLoop.sh
    pkill scanFM.sh
    pkill scanDAB.sh
    pkill -9 dab-rtlsdr
    pkill -9 rtl_test
    pkill -9 rtl_sdr
    pkill redsea
    pkill csdr
    pkill pipwm
    pkill checkSpectrumForCarrier
    pkill -9 prescanDAB

    saveScanResults.sh savelog
    startBgScanLoop.sh
  fi
fi

