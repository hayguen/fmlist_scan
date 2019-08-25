#!/bin/bash

# required for sudo
export PATH="$HOME/bin:$PATH"
source $HOME/.config/fmlist_scan/config

MNTC=$( mount | grep -c ${FMLIST_SCAN_RESULT_DIR} )
if [ $MNTC -eq 0 ] && [ ${FMLIST_SCAN_MOUNT} -eq 1 ]; then
  mount ${FMLIST_SCAN_RESULT_DIR}
  MNTC=$( mount | grep -c ${FMLIST_SCAN_RESULT_DIR} )
  if [ $MNTC -eq 0 ]; then
    echo "Error: Device (USB memory stick) is not available on ${FMLIST_SCAN_RESULT_DIR} !"
    exit 0
  fi
fi

if [ ! -d "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner" ]; then
  mkdir -p "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner"
fi

echo -n "" >${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/atx-knob.log

if /bin/true; then

  # Taster  A           B
  # 1x:    Shutdown    Upload scan results

  case "$1" in
    A1)
      echo "pressed A1: shutdown" >>${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/atx-knob.log
      stopBgScanLoop.sh wait &
      wall "atx-knob.sh: $1 Key pressed => Shutdown in 5 seconds!"
      sleep 5
      sudo /sbin/shutdown -P now
      ;;
    B1)
      echo "pressed B1: upload scan results" >>${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/atx-knob.log
      R="$( screen -ls |grep -c scanLoopBg )"
      echo "scanLoop state running: $R" >>${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/atx-knob.log
      stopBgScanLoop.sh wait
      echo "prepareScanResultsForUpload.sh all .." >>${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/atx-knob.log
      prepareScanResultsForUpload.sh all
      echo "uploadScanResults.sh .." >>${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/atx-knob.log
      uploadScanResults.sh
      echo "finished"
      echo "finished" >>${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/atx-knob.log
      sync
      scanToneFeedback.sh final
      if [ $R -ne 0 ]; then
        sleep 5
        echo "restarting scanLoop" >>${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/atx-knob.log
        startBgScanLoop.sh
      fi
      ;;
    *)
      echo "pressed $1 , but key is not handled in atx-knob.sh" >>${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/atx-knob.log
      ;;
  esac

else

  # Taster  A           B
  # 1x:    Info/Status Upload scan results
  # 2x:    Start/Stop  Switch UKW/DAB
  # 3x:    Shutdown    Switch Autostart
  # 4x:    Reboot      Switch LPIE
  # 5x:                Switch Speaker?

  case "$1" in
    A1)
      echo "pressed A1: info/status" >>${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/atx-knob.log
      T=$( echo "     Key  A           B" ; \
           echo "1x:  Info/Status Upload scan results" ; \
           echo "2x:  Start/Stop  Switch UKW/DAB" ; \
           echo "3x:  Shutdown    Switch Autostart" ; \
           echo "4x:  Reboot      Switch LPIE" ; \
           echo "5x:              Switch Speaker?" )
      echo "$T" >>${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/atx-knob.log
      ;;
    A2)
      echo "pressed A2: start/stop" >>${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/atx-knob.log
      ;;
    A3)
      echo "pressed A3: shutdown" >>${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/atx-knob.log
      sleep 2
      sudo /sbin/shutdown -P now
      ;;
    A4)
      echo "pressed A4: reboot" >>${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/atx-knob.log
      sleep 2
      sudo /sbin/reboot now
      ;;
    A5)
      echo "pressed A5: no function" >>${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/atx-knob.log
      ;;
    A6)
      echo "pressed A6: no function" >>${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/atx-knob.log
      ;;
    B1)
      echo "pressed B1: upload scan results" >>${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/atx-knob.log
      ;;
    B2)
      echo "pressed B2: switch ukw/dab" >>${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/atx-knob.log
      ;;
    B3)
      echo "pressed B3: switch autostart" >>${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/atx-knob.log
      ;;
    B4)
      echo "pressed B4: switch LPIE" >>${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/atx-knob.log
      ;;
    B5)
      echo "pressed B5: switch text-to-speech" >>${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/atx-knob.log
      ;;
    B6)
      echo "pressed B6: no function" >>${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/atx-knob.log
      ;;
    *)
      echo "pressed $1 , but key is not handled in atx-knob.sh" >>${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/atx-knob.log
      ;;
  esac

fi

