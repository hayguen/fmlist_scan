#!/bin/bash

export LC_ALL=C
if [ ! -f $HOME/ram/scanLoopBgRunning ]; then
  echo "scan Loop not running -> no check"
  exit 0
fi

CURR="$(date -u +%s)"
LAST="$(stat -c %Y $HOME/ram/LAST)"
D=$[ $CURR - $LAST ]
echo "Delta from LAST to CURR = $D secs"
if [ $D -ge 600 ]; then
  DTF="$(date -u "+%Y-%m-%dT%T Z")"
  echo "${DTF}: No stations in last $D seconds!"
  echo "${DTF}: checkBgScanLoop.sh: Error: No stations in last $D seconds!" >>$HOME/ram/scanner.log

  if [ "$1" == "reboot" ]; then
    echo "going for reboot"
    echo "${DTF}: checkBgScanLoop.sh: saving results, then rebooting .." >>$HOME/ram/scanner.log
    saveScanResults.sh savelog
    sudo reboot now
  else
    SSESSION="$( screen -ls | grep scanLoopBg )"
    if [ -z "$SSESSION" ]; then
      echo "scanLoopBg screen session is not running! saving results, then restarting scanLoop .."
      echo "${DTF}: checkBgScanLoop.sh: scanLoopBg screen session is not running! saving results, then restarting scanLoop .." >>$HOME/ram/scanner.log
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
      echo "${DTF}: checkBgScanLoop.sh: scanLoopBg screen session is hanging! killing session, saving results, then restarting scanLoop .." >>$HOME/ram/scanner.log
      stopScanLoop.sh
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

