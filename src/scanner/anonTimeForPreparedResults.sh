#!/bin/bash

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

if [ ! -d "up_outbox" ]; then
  mkdir "up_outbox"
fi

if [ ! -d "up_anon" ]; then
  mkdir "up_anon"
fi


if [ -z "$1" ]; then
  echo "usage: anonTimeForPreparedResults.sh <iso-date>"
  echo "  iso-date in format like '2020-01-01'"
  echo ""
  echo "anonymizes all date/timestamps in all '${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/up_outbox/' files"
  echo "call after prepareScanResultsForUpload.sh - before uploadScanResults.sh"
  exit 0
else
  ND="$1"
fi

cd "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/up_outbox"

echo -n "" >"/dev/shm/${ND}_00h00m00Z_upload_anon_temp.csv"

ls -1 |egrep "^.*_upload\.csv\.gz\$" |while read f ; do

  echo "unpack $f .."
  gunzip -c "$f" >>"/dev/shm/${ND}_00h00m00Z_upload_anon_temp.csv"
  mv "$f" "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/up_anon/"

done

INP="/dev/shm/${ND}_00h00m00Z_upload_anon_temp.csv"
TMP="/dev/shm/${ND}_00h00m00Z_upload_anon.csv"
OUT="${ND}_00h00m00Z_upload_anon.csv"
DT="${ND}"

UT="$(date -d "${DT}" -u +%s)"
DTF="$(date -d "@${UT}" -u "+%Y-%m-%dT%T")"
#echo "UT:  '${UT}'"
#echo "DTF: '${DTF}'"

echo -n "" >${TMP}

for LID in $( awk -F "," '{ print $1; }' "${INP}" |sort |uniq ) ; do  echo "found line ID ${LID}" ; done

#for LID in $( echo "30 31" ) ; do
for LID in $( awk -F "," '{ print $1; }' "${INP}" |sort |uniq ) ; do
  case "${LID}" in
    1?)
      echo "processing line id ${LID}"
      grep "^${LID}," "${INP}" |head -n 1 >>"${TMP}"
      ;;
    2?)
      echo "processing line id ${LID}"
      grep "^${LID}," "${INP}" \
        | awk -F "," "{OFS=\",\"; \$2=\"${UT}\"; print }" \
        | awk -F "," "{OFS=\",\"; \$7=\"${DTF}.000Z\"; print }" \
        >>"${TMP}"
      ;;
    3?)
      echo "processing line id ${LID}"
      grep "^${LID}," "${INP}" \
        | awk -F "," "{OFS=\",\"; \$2=\"${UT}\"; print }" \
        | awk -F "," "{OFS=\",\"; \$8=\"${DTF}.000 Z\"; print }" \
        | awk -F "," "{OFS=\",\"; \$13=\"${DTF}.000Z\"; print }" \
        >>"${TMP}"
      ;;
    *)
      echo "ignoring line id ${LID}"
      ;;
  esac

done

gzip "${TMP}"
cp "${TMP}.gz" "${OUT}.gz"
rm "${INP}"
rm "${TMP}"
