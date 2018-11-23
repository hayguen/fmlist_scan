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


echo -n "" >${FMLIST_SCAN_RESULT_DIR}/atx-knob.log

R="$( screen -ls |grep -c scanLoopBg )"
echo "scanLoop running: $R"
while [ $R -ne 0 ]; do
  stopBgScanLoop.sh
  echo "waiting for termination of scanLoop .."
  echo "waiting for termination of scanLoop .." >>${FMLIST_SCAN_RESULT_DIR}/atx-knob.log
  sleep 1
  screen -ls
  R="$( screen -ls |grep -c scanLoopBg )"
  echo "scanLoop running: $R"
done

echo "scanLoop terminated."
echo "scanLoop terminated." >>atx-knob.log

echo "prepareScanResultsForUpload.sh all .."
echo "prepareScanResultsForUpload.sh all .." >>${FMLIST_SCAN_RESULT_DIR}/atx-knob.log
prepareScanResultsForUpload.sh all

echo "ploadScanResults.sh .."
echo "ploadScanResults.sh .." >>${FMLIST_SCAN_RESULT_DIR}/atx-knob.log
uploadScanResults.sh

echo "finished"
echo "finished" >>${FMLIST_SCAN_RESULT_DIR}/atx-knob.log
sync
scanToneFeedback.sh final

