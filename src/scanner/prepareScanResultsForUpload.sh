#!/bin/bash

# usage: $0 [all|random]

source $HOME/.config/fmlist_scan/config
if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

source /home/${FMLIST_SCAN_USER}/bin/scanner_mount_result_dir.sh.inc


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

#t="$(date -u "+%Y-%m-%dT%Hh%Mm%SZ")"
#t="$(date -u "+%Hh%Mm%SZ")"

GREPOPT="$(date -u "+%Y-%m-%d")"
if [ "$1" = "all" ]; then
  echo "detected option 'all': going to prepare ALL data"
  GREPOPT="ignore"
else
  echo "option 'all' not used: going to prepare data - up to yesterday"
fi

ls -1 |egrep "^[0-9]{4}-[0-9]{2}-[0-9]{2}\$" |grep -v "${GREPOPT}" |sort |while read d ; do
  #DTF="${d}-${t}"
  #DTF="${d}__$(date -u "+%Y-%m-%d_%Hh%Mm%SZ")"
  DTF="$(date -u "+%Y-%m-%d_%Hh%Mm%SZ")"

  echo "processing $d to summaries/"
  concatScanResults.sh cputemp      "${d}" >summaries/${DTF}_cputemp.csv
  echo "  cputemp finished."
  concatScanResults.sh gpscoor      "${d}" >summaries/${DTF}_gpscoor.csv
  echo "  gpscoor finished."
  concatScanResults.sh fm_carrier   "${d}" >summaries/${DTF}_fm_carrier.csv
  echo "  fm_carrier finished."
  concatScanResults.sh fm_rds       "${d}" >summaries/${DTF}_fm_rds.csv
  echo "  fm_rds finished."
  concatScanResults.sh fm_count     "${d}" >summaries/${DTF}_fm_count.csv
  echo "  fm_count finished."

  concatScanResults.sh dab_ensemble "${d}" >summaries/${DTF}_dab_ensemble.csv
  echo "  dab_ensemble finished."
  concatScanResults.sh dab_gps      "${d}" >summaries/${DTF}_dab_gps.csv
  echo "  dab_gps finished."
  concatScanResults.sh dab_audio    "${d}" >summaries/${DTF}_dab_audio.csv
  echo "  dab_audio finished."
  concatScanResults.sh dab_packet   "${d}" >summaries/${DTF}_dab_packet.csv
  echo "  dab_packet finished."
  concatScanResults.sh dab_count    "${d}" >summaries/${DTF}_dab_count.csv
  echo "  dab_count finished."

  TF="${FMLIST_SCAN_RAM_DIR}/${DTF}_upload.csv"

  echo "10,\"${FMLIST_USER}\""                          >${TF}
  echo "11,\"${FMLIST_OM_ID}\",\"${FMLIST_RASPI_ID}\"" >>${TF}
  echo "12,\"${FMLIST_UP_COMMENT}\""                   >>${TF}
  echo "13,\"${FMLIST_UP_PERMISSION}\",\"${FMLIST_UP_RESTRICT_USERS}\"" >>${TF}
  echo "14,\"${FMLIST_UP_POSITION}\""                  >>${TF}

  (
  LNID="100"
  scanner_versions.sh | head -n 50 | while read line ; do
    echo "$LNID, \"${line}\""
    LNID=$[ $LNID + 1 ]
  done
  ) >>${TF}

  createFMoverview.py --nowrite summaries/${DTF}_fm_rds.csv | grep "^15," >>${TF}

  sed 's/^/20,/' summaries/${DTF}_dab_ensemble.csv  >>${TF}
  sed 's/^/21,/' summaries/${DTF}_dab_audio.csv     >>${TF}
  sed 's/^/22,/' summaries/${DTF}_dab_packet.csv    >>${TF}
  sed 's/^/30,/' summaries/${DTF}_fm_rds.csv        >>${TF}
  sed 's/^/31,/' summaries/${DTF}_fm_carrier.csv    >>${TF}

  scanEvalSummary.sh "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/${d}" >>${TF}

  echo "compressing to ${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/up_outbox/${DTF}_upload.csv.gz"
  cat ${TF} |gzip -c >up_outbox/${DTF}_upload.csv.gz
  mv "$d" "processed/${DTF}"
  rm ${TF}

done


if [ "$1" = "random" ]; then
  MAX_MINUTES="$2"
  if [ -z "$MAX_MINUTES" ]; then
    MAX_MINUTES="240"  # = 4 h
  fi
  WAITSEC=$[ $RANDOM % ( 60 * ${MAX_MINUTES} ) ]
  echo "detected option 'random': waiting up to ${MAX_MINUTES} minutes: $[ ${WAITSEC} / 60 ] min $[ ${WAITSEC} % 60 ] sec"
  sleep ${WAITSEC}
fi

