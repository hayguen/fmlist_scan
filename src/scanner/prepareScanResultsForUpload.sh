#!/bin/bash

# usage: $0 [all|random]

source $HOME/.config/fmlist_scan/config
if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

MNTC=$( mount | grep -c "${FMLIST_SCAN_RESULT_DIR}" )
if [ $MNTC -eq 0 ] && [ ${FMLIST_SCAN_MOUNT} -eq 1 ]; then
  mount "${FMLIST_SCAN_RESULT_DIR}"
  MNTC=$( mount | grep -c "${FMLIST_SCAN_RESULT_DIR}" )
  if [ $MNTC -eq 0 ]; then
    echo "Error: USB stick is not available on ${FMLIST_SCAN_RESULT_DIR} !"
    exit 0
  fi
fi

if [ ! -d "${FMLIST_SCAN_RESULT_DIR}" ]; then
  echo "error: ${FMLIST_SCAN_RESULT_DIR} not a directory!"
  exit 10
fi

if [ ! -d "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner" ]; then
  mkdir -p "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner"
fi

cd "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner"

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

if [ "$1" = "random" ]; then
  MAX_MINUTES="$2"
  if [ -z "$MAX_MINUTES" ]; then
    MAX_MINUTES="240"  # = 4 h
  fi
  WAITSEC=$[ $RANDOM % ( 60 * ${MAX_MINUTES} ) ]
  echo "detected option 'random': waiting up to ${MAX_MINUTES} minutes: $[ ${WAITSEC} / 60 ] min $[ ${WAITSEC} % 60 ] sec"
  sleep ${WAITSEC}
fi

#t="$(date -u "+%Y-%m-%dT%Hh%Mm%SZ")"
t="$(date -u "+%Hh%Mm%SZ")"

GREPOPT="$(date -u "+%Y-%m-%d")"
if [ "$1" = "all" ]; then
  echo "detected option 'all': going to prepare ALL data"
  GREPOPT="ignore"
else
  echo "option 'all' not used: going to prepare data - up to yesterday"
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
  echo "12,\"${FMLIST_UP_COMMENT}\""                   >>${TF}
  echo "13,\"${FMLIST_UP_PERMISSION}\",\"${FMLIST_UP_RESTRICT_USERS}\"" >>${TF}
  echo "14,\"${FMLIST_UP_POSITION}\""                  >>${TF}
  createFMoverview.py --nowrite summaries/${d}_${t}_fm_rds.csv | grep "^15," >>${TF}

  sed 's/^/20,/' summaries/${d}_${t}_dab_ensemble.csv  >>${TF}
  sed 's/^/21,/' summaries/${d}_${t}_dab_audio.csv     >>${TF}
  sed 's/^/22,/' summaries/${d}_${t}_dab_packet.csv    >>${TF}
  sed 's/^/30,/' summaries/${d}_${t}_fm_rds.csv        >>${TF}
  sed 's/^/31,/' summaries/${d}_${t}_fm_carrier.csv    >>${TF}

  echo "compressing to ${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/up_outbox/${d}_${t}_upload.csv.gz"
  cat ${TF} |gzip -c >up_outbox/${d}_${t}_upload.csv.gz
  mv "$d" "processed/${d}_${t}"
  rm ${TF}

done

