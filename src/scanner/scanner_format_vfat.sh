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
  echo "starting format with vfat (Windows compatible file system) on device ${FMLIST_SCAN_RESULT_DEV} in 5 secs .."
  shift
  sleep 5
  echo -e "\n\n"
  echo "starting sudo mkfs.vfat $@ ${FMLIST_SCAN_RESULT_DEV}"
  sudo mkfs.vfat "$@" ${FMLIST_SCAN_RESULT_DEV}

  echo -e "\n\n"
  echo "mounting device ${FMLIST_SCAN_RESULT_DEV} to ${FMLIST_SCAN_RESULT_DIR}"
  mount ${FMLIST_SCAN_RESULT_DIR}
  sudo chown ${FMLIST_SCAN_USER}:${FMLIST_SCAN_USER} "${FMLIST_SCAN_RESULT_DIR}"
else
  echo "restart scanner_format_vfat with option format: 'scanner_format_vfat.sh format <options>',"
  echo "  if you are sure to format/delete ${FMLIST_SCAN_RESULT_DEV}"
  echo "  additional option to mkfs.vfat, e.g. '-f', can be passed after the 'format' argument"
fi
