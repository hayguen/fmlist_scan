#!/bin/bash

source $HOME/.config/fmlist_scan/config

MNTC=$( mount | grep -c /mnt/sda1 )
if [ $MNTC -eq 0 ] && [ ${FMLIST_SCAN_MOUNT} -eq 1 ]; then

  mount /mnt/sda1

  MNTC=$( mount | grep -c /mnt/sda1 )
  if [ $MNTC -eq 0 ]; then
    echo "Error: USB stick is not available on /mnt/sda1 !"
    exit 0
  fi
fi

if [ ! -d "${FMLIST_SCAN_RESULT_DIR}" ]; then
  echo "error"
  exit 10
fi

cd "${FMLIST_SCAN_RESULT_DIR}"

if [ ! -d "uploaded" ]; then
  mkdir "uploaded"
fi

if [ ! -d "uploads" ]; then
  mkdir "uploads"
fi

GREPOPT="$(date -u "+%Y-%m-%d")"
if [ "$1" = "all" ]; then
  GREPOPT="ignore"
fi

ls -1 |egrep "^[0-9]{4}-[0-9]{2}-[0-9]{2}\$" |grep -v "${GREPOPT}" |while read d ; do
  echo "compressing $d .."
  concatScanResults.sh cputemp    "${d}" |gzip -c >uploads/${d}_cputemp.csv.gz
  echo "  cputemp finished."
  concatScanResults.sh gpscoor    "${d}" |gzip -c >uploads/${d}_gpscoor.csv.gz
  echo "  gpscoor finished."
  concatScanResults.sh fm_carrier "${d}" |gzip -c >uploads/${d}_fm_carrier.csv.gz
  echo "  fm_carrier finished."
  concatScanResults.sh fm_rds     "${d}" |gzip -c >uploads/${d}_fm_rds.csv.gz
  echo "  fm_rds finished."
  concatScanResults.sh fm_count   "${d}" |gzip -c >uploads/${d}_fm_count.csv.gz
  echo "  fm_count finished."

  concatScanResults.sh dab_ensemble "${d}" |gzip -c >uploads/${d}_dab_ensemble.csv.gz
  echo "  dab_ensemble finished."
  concatScanResults.sh dab_gps      "${d}" |gzip -c >uploads/${d}_dab_gps.csv.gz
  echo "  dab_gps finished."
  concatScanResults.sh dab_audio    "${d}" |gzip -c >uploads/${d}_dab_audio.csv.gz
  echo "  dab_audio finished."
  concatScanResults.sh dab_packet   "${d}" |gzip -c >uploads/${d}_dab_packet.csv.gz
  echo "  dab_packet finished."
  concatScanResults.sh dab_count    "${d}" |gzip -c >uploads/${d}_dab_count.csv.gz
  echo "  dab_count finished."

  mv "$d" "uploaded/"

done
