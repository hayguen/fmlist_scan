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


ls -1 | grep ^scan_ | while read d ; do
  if [ -d "$d" ]; then
    echo $d
    if [ ${FMLIST_SCAN_SAVE_RAW} -eq 0 ]; then
      rm -f "$d/A.raw" "$d/B.raw"
    fi
    if [ $(echo "$d" |grep -c "_FM\$") -ne 0 ]; then
      if [ ${FMLIST_SCAN_DEBUG_CHK_SPECTRUM} -eq 0 ]; then
        echo "saveScanResults.sh: deleting $d/det*.csv and .txt" >>$HOME/ram/scanner.log
        rm -f $d/det*.csv
        rm -f $d/det*.txt
      fi
      if [ ${FMLIST_SCAN_DEBUG_REDSEA} -eq 0 ]; then
        echo "saveScanResults.sh: deleting $d/redsea.*.txt" >>$HOME/ram/scanner.log
        rm -f $d/redsea.*.txt
      fi

      pushd $d
      rm -f $HOME/ram/fm_carrier.csv
      rm -f $HOME/ram/fm_rds.csv
      for res in $(ls -1 fm_carrier.*.csv) ; do
        cat "$res" >>$HOME/ram/fm_carrier.csv
      done
      for res in $(ls -1 fm_rds.*.csv) ; do
        cat "$res" >>$HOME/ram/fm_rds.csv
      done
      TMIN=$( cat $HOME/ram/fm_carrier.csv $HOME/ram/fm_rds.csv | sort -n | head -n 1 | awk -F ',' '{ print $1; }' )
      echo "${TMIN},$(cat $HOME/ram/fm_carrier.csv |wc -l),$(cat $HOME/ram/fm_rds.csv |wc -l)" >$HOME/ram/fm_count.csv

      popd
    fi

    zip -r "${FMLIST_SCAN_RESULT_DIR}/$S/$d.zip" "$d"
    rm -rf "$d"
  fi
done

if [ "$1" = "savelog" ]; then
  DTF="$(date -u "+%Y-%m-%dT%T Z")"
  DTFREC="$(date -u "+%Y-%m-%dT%H%M%S")"
  if [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
    echo -e "\\n${DTF}: Temperature at saveScanResults.sh: $(cat /sys/class/thermal/thermal_zone0/temp)" >>$HOME/ram/scanner.log
    echo "$(date -u +%s), $(cat /sys/class/thermal/thermal_zone0/temp)" >>$HOME/ram/cputemp.csv
  fi
  if [ -f $HOME/ram/cputemp.csv ]; then
    cp $HOME/ram/cputemp.csv ${FMLIST_SCAN_RESULT_DIR}/$S/scan_${DTFREC}_cputemp.csv
    rm $HOME/ram/cputemp.csv
  fi
  if [ -f $HOME/ram/gpscoor.csv ]; then
    COOR=$( ( flock -x 213 ; cat $HOME/ram/gpscoor.csv 2>/dev/null ; rm -f $HOME/ram/gpscoor.csv 2>/dev/null ) 213>$HOME/ram/gps.lock )
    echo "$COOR" >${FMLIST_SCAN_RESULT_DIR}/$S/scan_${DTFREC}_gpscoor.csv
  fi
  if [ -f $HOME/ram/fm_carrier.csv ]; then
    cp $HOME/ram/fm_carrier.csv ${FMLIST_SCAN_RESULT_DIR}/$S/scan_${DTFREC}_fm_carrier.csv
    rm $HOME/ram/fm_carrier.csv
  fi
  if [ -f $HOME/ram/fm_rds.csv ]; then
    cp $HOME/ram/fm_rds.csv ${FMLIST_SCAN_RESULT_DIR}/$S/scan_${DTFREC}_fm_rds.csv
    rm $HOME/ram/fm_rds.csv
  fi
  if [ -f $HOME/ram/fm_count.csv ]; then
    cp $HOME/ram/fm_count.csv ${FMLIST_SCAN_RESULT_DIR}/$S/scan_${DTFREC}_fm_count.csv
    rm $HOME/ram/fm_count.csv
  fi

  #cp $HOME/ram/scanner.log ${FMLIST_SCAN_RESULT_DIR}/$S/scan_${DTFREC}_scanner.log
  gzip -kc $HOME/ram/scanner.log >${FMLIST_SCAN_RESULT_DIR}/$S/scan_${DTFREC}_scanner.log.gz
  # do NOT remove file - just truncate
  echo "" >$HOME/ram/scanner.log
else
  echo -e "\\n******* saveScanResults.sh without 'savelog'\\n" >>$HOME/ram/scanner.log
fi



#sync -f "${FMLIST_SCAN_RESULT_DIR}/$S"
sync

if [ ${FMLIST_SCAN_SAVE_RAW} -gt 0 ]; then
  # see https://unix.stackexchange.com/questions/87908/how-do-you-empty-the-buffers-and-cache-on-a-linux-system
  sudo sh -c 'echo 3 >/proc/sys/vm/drop_caches'
fi

