#!/bin/bash

source $HOME/.config/fmlist_scan/config
if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

cd ${FMLIST_SCAN_RAM_DIR}


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
    if [ ${FMLIST_SCAN_SAVE_RAW} -eq 0 ]; then
      rm -f "$d/A.raw" "$d/B.raw"
    fi
    if [ $(echo "$d" |grep -c "_FM\$") -ne 0 ]; then
      if [ ${FMLIST_SCAN_DEBUG_CHK_SPECTRUM} -eq 0 ]; then
        echo "saveScanResults.sh: deleting $d/det*.csv and .txt" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
        rm -f $d/det*.csv
        rm -f $d/det*.txt
      fi
      if [ ${FMLIST_SCAN_DEBUG_REDSEA} -eq 0 ]; then
        echo "saveScanResults.sh: deleting $d/redsea.*.txt" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
        rm -f $d/redsea.*.txt
      fi

      pushd $d
      rm -f ${FMLIST_SCAN_RAM_DIR}/fm_carrier.csv
      rm -f ${FMLIST_SCAN_RAM_DIR}/fm_rds.csv
      for res in $(ls -1 fm_carrier.*.csv) ; do
        cat "$res" >>${FMLIST_SCAN_RAM_DIR}/fm_carrier.csv
      done
      for res in $(ls -1 fm_rds.*.csv) ; do
        cat "$res" >>${FMLIST_SCAN_RAM_DIR}/fm_rds.csv
      done
      TMIN=$( cat ${FMLIST_SCAN_RAM_DIR}/fm_carrier.csv ${FMLIST_SCAN_RAM_DIR}/fm_rds.csv | sort -n | head -n 1 | awk -F ',' '{ print $1; }' )
      echo "${TMIN},$(cat ${FMLIST_SCAN_RAM_DIR}/fm_carrier.csv |wc -l),$(cat ${FMLIST_SCAN_RAM_DIR}/fm_rds.csv |wc -l)" >${FMLIST_SCAN_RAM_DIR}/fm_count.csv

      popd
    elif [ $(echo "$d" |grep -c "_DAB\$") -ne 0 ]; then
      pushd $d
      rm -f ${FMLIST_SCAN_RAM_DIR}/dab_audio.csv
      rm -f ${FMLIST_SCAN_RAM_DIR}/dab_ensemble.csv
      rm -f ${FMLIST_SCAN_RAM_DIR}/dab_gps.csv
      rm -f ${FMLIST_SCAN_RAM_DIR}/dab_packet.csv
      cp dab_audio.csv     ${FMLIST_SCAN_RAM_DIR}/dab_audio.csv
      cp dab_ensemble.csv  ${FMLIST_SCAN_RAM_DIR}/dab_ensemble.csv
      cp dab_gps.csv       ${FMLIST_SCAN_RAM_DIR}/dab_gps.csv
      cp dab_packet.csv    ${FMLIST_SCAN_RAM_DIR}/dab_packet.csv
      TMIN=$( cat ${FMLIST_SCAN_RAM_DIR}/ensemble.csv ${FMLIST_SCAN_RAM_DIR}/dab_audio.csv | sort -n | head -n 1 | awk -F ',' '{ print $1; }' )
      echo "${TMIN},$(cat ${FMLIST_SCAN_RAM_DIR}/dab_ensemble.csv |wc -l),$(cat ${FMLIST_SCAN_RAM_DIR}/dab_audio.csv |wc -l),$(cat ${FMLIST_SCAN_RAM_DIR}/dab_packet.csv |wc -l)" >${FMLIST_SCAN_RAM_DIR}/dab_count.csv

      popd
    fi

    zip -r "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/$S/$d.zip" "$d"
    rm -rf "$d"
  fi
done

if [ "$1" = "savelog" ]; then
  DTF="$(date -u "+%Y-%m-%dT%T Z")"
  DTFREC="$(date -u "+%Y-%m-%dT%H%M%S")"
  if [ ${FMLIST_SCAN_RASPI} -ne 0 ]; then
    echo -e "\\n${DTF}: Temperature at saveScanResults.sh: $(cat /sys/class/thermal/thermal_zone0/temp)" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
    echo "$(date -u +%s), $(cat /sys/class/thermal/thermal_zone0/temp)" >>${FMLIST_SCAN_RAM_DIR}/cputemp.csv
  fi
  if [ -f ${FMLIST_SCAN_RAM_DIR}/cputemp.csv ]; then
    cp ${FMLIST_SCAN_RAM_DIR}/cputemp.csv ${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/$S/scan_${DTFREC}_cputemp.csv
    rm ${FMLIST_SCAN_RAM_DIR}/cputemp.csv
  fi
  if [ -f ${FMLIST_SCAN_RAM_DIR}/gpscoor.csv ]; then
    COOR=$( ( flock -x 213 ; cat ${FMLIST_SCAN_RAM_DIR}/gpscoor.csv 2>/dev/null ; rm -f ${FMLIST_SCAN_RAM_DIR}/gpscoor.csv 2>/dev/null ) 213>${FMLIST_SCAN_RAM_DIR}/gps.lock )
    echo "$COOR" >${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/$S/scan_${DTFREC}_gpscoor.csv
  fi

  if [ -f ${FMLIST_SCAN_RAM_DIR}/fm_carrier.csv ]; then
    cp ${FMLIST_SCAN_RAM_DIR}/fm_carrier.csv ${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/$S/scan_${DTFREC}_fm_carrier.csv
    rm ${FMLIST_SCAN_RAM_DIR}/fm_carrier.csv
  fi
  if [ -f ${FMLIST_SCAN_RAM_DIR}/fm_rds.csv ]; then
    cp ${FMLIST_SCAN_RAM_DIR}/fm_rds.csv ${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/$S/scan_${DTFREC}_fm_rds.csv
    rm ${FMLIST_SCAN_RAM_DIR}/fm_rds.csv
  fi
  if [ -f ${FMLIST_SCAN_RAM_DIR}/fm_count.csv ]; then
    cp ${FMLIST_SCAN_RAM_DIR}/fm_count.csv ${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/$S/scan_${DTFREC}_fm_count.csv
    rm ${FMLIST_SCAN_RAM_DIR}/fm_count.csv
  fi

  if [ -f ${FMLIST_SCAN_RAM_DIR}/dab_ensemble.csv ]; then
    cp ${FMLIST_SCAN_RAM_DIR}/dab_ensemble.csv ${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/$S/scan_${DTFREC}_dab_ensemble.csv
    rm ${FMLIST_SCAN_RAM_DIR}/dab_ensemble.csv
  fi
  if [ -f ${FMLIST_SCAN_RAM_DIR}/dab_gps.csv ]; then
    cp ${FMLIST_SCAN_RAM_DIR}/dab_gps.csv ${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/$S/scan_${DTFREC}_dab_gps.csv
    rm ${FMLIST_SCAN_RAM_DIR}/dab_gps.csv
  fi
  if [ -f ${FMLIST_SCAN_RAM_DIR}/dab_audio.csv ]; then
    cp ${FMLIST_SCAN_RAM_DIR}/dab_audio.csv ${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/$S/scan_${DTFREC}_dab_audio.csv
    rm ${FMLIST_SCAN_RAM_DIR}/dab_audio.csv
  fi
  if [ -f ${FMLIST_SCAN_RAM_DIR}/dab_packet.csv ]; then
    cp ${FMLIST_SCAN_RAM_DIR}/dab_packet.csv ${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/$S/scan_${DTFREC}_dab_packet.csv
    rm ${FMLIST_SCAN_RAM_DIR}/dab_packet.csv
  fi
  if [ -f ${FMLIST_SCAN_RAM_DIR}/dab_count.csv ]; then
    cp ${FMLIST_SCAN_RAM_DIR}/dab_count.csv ${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/$S/scan_${DTFREC}_dab_count.csv
    rm ${FMLIST_SCAN_RAM_DIR}/dab_count.csv
  fi

  #cp ${FMLIST_SCAN_RAM_DIR}/scanner.log ${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/$S/scan_${DTFREC}_scanner.log
  gzip -kc ${FMLIST_SCAN_RAM_DIR}/scanner.log >${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/$S/scan_${DTFREC}_scanner.log.gz
  # do NOT remove file - just truncate
  echo "" >${FMLIST_SCAN_RAM_DIR}/scanner.log
else
  echo -e "\\n******* saveScanResults.sh without 'savelog'\\n" >>${FMLIST_SCAN_RAM_DIR}/scanner.log
fi



#sync -f "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/$S"
sync

if [ ${FMLIST_SCAN_SAVE_RAW} -gt 0 ]; then
  # see https://unix.stackexchange.com/questions/87908/how-do-you-empty-the-buffers-and-cache-on-a-linux-system
  sudo sh -c 'echo 3 >/proc/sys/vm/drop_caches'
fi

