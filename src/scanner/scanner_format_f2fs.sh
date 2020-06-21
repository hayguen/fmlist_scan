#!/bin/bash

source $HOME/.config/fmlist_scan/config

if [ ${FMLIST_SCAN_MOUNT} -eq 0 ]; then
  echo "Error: FMLIST_SCAN_MOUNT is '${FMLIST_SCAN_MOUNT} ', thus deactivated"
  exit 1
fi

echo "stopping scanner .."
stopBgScanLoop.sh wait

MNTC=$( mount | grep -c ${FMLIST_SCAN_RESULT_DIR} )
if [ $MNTC -gt 0 ]; then
  umount ${FMLIST_SCAN_RESULT_DIR}
fi
MNTC=$( mount | grep -c ${FMLIST_SCAN_RESULT_DIR} )
if [ $MNTC -gt 0 ]; then
  echo "Error: could not unmount ${FMLIST_SCAN_RESULT_DIR}"
  exit 1
fi

echo "checking disk identifier first .."
scanner_fix-uuid.sh check
if [ $? -ne 0 ]; then
  echo "aborted format."
  exit 1
fi

if [ "$1" = "format" ]; then
  echo "starting format with f2fs (flash friendly file system) on device ${FMLIST_SCAN_RESULT_DEV} .."
  sleep 5
  sudo mkfs.f2fs -f ${FMLIST_SCAN_RESULT_DEV}

  echo -e "\n\n"
  echo "mounting device ${FMLIST_SCAN_RESULT_DEV} to ${FMLIST_SCAN_RESULT_DIR}"
  mount ${FMLIST_SCAN_RESULT_DIR}
  sudo chown ${FMLIST_SCAN_USER}:${FMLIST_SCAN_USER} "${FMLIST_SCAN_RESULT_DIR}"
else
  echo "restart scanner_format_f2fs with option format: 'scanner_format_f2fs.sh format', if you are sure to format/delete ${FMLIST_SCAN_RESULT_DEV}"
fi
