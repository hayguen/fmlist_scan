#!/bin/bash

source $HOME/.config/fmlist_scan/config
if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi


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

if [ ! -d "summaries" ]; then
  mkdir "summaries"
fi

if [ ! -d "processed" ]; then
  mkdir "processed"
fi

if [ ! -d "up_outbox" ]; then
  mkdir "up_outbox"
fi

if [ ! -d "up_sent" ]; then
  mkdir "up_sent"
fi

#t="$(date -u "+%Y-%m-%dT%Hh%Mm%SZ")"
t="$(date -u "+%Hh%Mm%SZ")"

GREPOPT="$(date -u "+%Y-%m-%d")"
if [ "$1" = "all" ]; then
  GREPOPT="ignore"
fi

ls -1 |egrep "^[0-9]{4}-[0-9]{2}-[0-9]{2}\$" |grep -v "${GREPOPT}" |while read d ; do
  echo "processing $d to summaries/"
  concatScanResults.sh cputemp      "${d}" >summaries/${d}_${t}_cputemp.csv
  echo "  cputemp finished."
  concatScanResults.sh gpscoor      "${d}" >summaries/${d}_${t}_gpscoor.csv
  echo "  gpscoor finished."
  concatScanResults.sh fm_carrier   "${d}" >summaries/${d}_${t}_fm_carrier.csv
  echo "  fm_carrier finished."
  concatScanResults.sh fm_rds       "${d}" >summaries/${d}_${t}_fm_rds.csv
  echo "  fm_rds finished."
  concatScanResults.sh fm_count     "${d}" >summaries/${d}_${t}_fm_count.csv
  echo "  fm_count finished."

  concatScanResults.sh dab_ensemble "${d}" >summaries/${d}_${t}_dab_ensemble.csv
  echo "  dab_ensemble finished."
  concatScanResults.sh dab_gps      "${d}" >summaries/${d}_${t}_dab_gps.csv
  echo "  dab_gps finished."
  concatScanResults.sh dab_audio    "${d}" >summaries/${d}_${t}_dab_audio.csv
  echo "  dab_audio finished."
  concatScanResults.sh dab_packet   "${d}" >summaries/${d}_${t}_dab_packet.csv
  echo "  dab_packet finished."
  concatScanResults.sh dab_count    "${d}" >summaries/${d}_${t}_dab_count.csv
  echo "  dab_count finished."

  TF="${FMLIST_SCAN_RAM_DIR}/${d}-${t}_upload.csv"

  echo "10,\"${FMLIST_USER}\""                          >${TF}
  echo "11,\"${FMLIST_OM_ID}\""                        >>${TF}
  sed 's/^/20,/' summaries/${d}_${t}_dab_ensemble.csv  >>${TF}
  sed 's/^/21,/' summaries/${d}_${t}_dab_audio.csv     >>${TF}
  sed 's/^/22,/' summaries/${d}_${t}_dab_packet.csv    >>${TF}
  sed 's/^/30,/' summaries/${d}_${t}_fm_rds.csv        >>${TF}
  sed 's/^/31,/' summaries/${d}_${t}_fm_carrier.csv    >>${TF}

  echo "compressing to ${FMLIST_SCAN_RESULT_DIR}/up_outbox/${d}_${t}_upload.csv.gz"
  cat ${TF} |gzip -c >up_outbox/${d}_${t}_upload.csv.gz
  mv "$d" "processed/${d}_${t}"
  rm ${TF}

done

