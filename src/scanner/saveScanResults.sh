#!/bin/bash

source $HOME/.config/fmlist_scan/config

cd $HOME/ram

MNTC=$( mount | grep -c /mnt/sda1 )
if [ $MNTC -eq 0 ] && [ ${FMLIST_SCAN_MOUNT} -eq 1 ]; then

  mount /mnt/sda1

  MNTC=$( mount | grep -c /mnt/sda1 )
  if [ $MNTC -eq 0 ]; then
    echo "Error: USB stick is not available on /mnt/sda1 !"
    exit 0
  fi
fi

if [ ${FMLIST_SCAN_MOUNT} -eq 1 ]; then
  FM=$( df -h -m /dev/sda1 | tail -n 1 | awk '{ print $4; }' )
  if [ $FM -le 5 ]; then
    echo "Error: not enough space on USB stick /dev/sda1 !"
    exit 0
  fi
fi

S="$(date -u "+%Y-%m-%d")"
if [ ! -d "${FMLIST_SCAN_RESULT_DIR}/$S" ]; then
  mkdir "${FMLIST_SCAN_RESULT_DIR}/$S"
fi

cd $HOME/ram


if [ "$1" = "savelog" ]; then
  DTF="$(date -u "+%Y-%m-%dT%T Z")"
  DTFREC="$(date -u "+%Y-%m-%dT%H%M%S")"
  if [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
    echo -e "\\n${DTF}: Temperature at saveScanResults.sh: $(cat /sys/class/thermal/thermal_zone0/temp)" >>$HOME/ram/scanner.log
  fi
  cp $HOME/ram/scanner.log ${FMLIST_SCAN_RESULT_DIR}/$S/scan_${DTFREC}_scanner.log
  # do NOT remove file - just truncate
  echo "" >$HOME/ram/scanner.log
else
  echo -e "\\n******* saveScanResults.sh without 'savelog'\\n" >>$HOME/ram/scanner.log
fi

ls -1 | grep ^scan_ | while read d ; do
  if [ -d "$d" ]; then
    echo $d
    if [ ${FMLIST_SCAN_SAVE_RAW} -eq 0 ]; then
      rm -f "$d/A.raw" "$d/B.raw"
    fi
    zip -r "${FMLIST_SCAN_RESULT_DIR}/$S/$d.zip" "$d"
    rm -rf "$d"
  fi
done

#sync -f "${FMLIST_SCAN_RESULT_DIR}/$S"
sync

if [ ${FMLIST_SCAN_SAVE_RAW} -gt 0 ]; then
  # see https://unix.stackexchange.com/questions/87908/how-do-you-empty-the-buffers-and-cache-on-a-linux-system
  sudo sh -c 'echo 3 >/proc/sys/vm/drop_caches'
fi

