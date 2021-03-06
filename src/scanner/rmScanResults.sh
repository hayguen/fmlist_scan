#!/bin/bash

source $HOME/.config/fmlist_scan/config
if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

cd ${FMLIST_SCAN_RAM_DIR}

source /home/${FMLIST_SCAN_USER}/bin/scanner_mount_result_dir.sh.inc

if [ ${FMLIST_SCAN_MOUNT} -eq 1 ]; then
  FM=$( df -h -m ${FMLIST_SCAN_RESULT_DEV} | tail -n 1 | awk '{ print $4; }' )
  if [ $FM -le 5 ]; then
    echo "Error: not enough space on USB stick ${FMLIST_SCAN_RESULT_DEV} !"
    exit 0
  fi
fi

S="$(date -u "+%Y-%m-%d")"
if [ ! -d "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/$S" ]; then
  mkdir -p "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/$S"
fi

cd ${FMLIST_SCAN_RAM_DIR}


ls -1 | grep ^scan_ | while read d ; do
  if [ -d "$d" ]; then
    echo $d
    rm -rf "$d"
  fi
done
