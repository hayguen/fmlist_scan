#!/bin/bash

source $HOME/.config/fmlist_scan/config
if [ ! -d "${FMLIST_SCAN_RAM_DIR}" ]; then
  mkdir -p "${FMLIST_SCAN_RAM_DIR}"
fi

source /home/${FMLIST_SCAN_USER}/bin/scanner_mount_result_dir.sh.inc

cd "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner"

if [ ! -d "up_outbox" ]; then
  mkdir "up_outbox"
fi

if [ ! -d "up_anon" ]; then
  mkdir "up_anon"
fi


if [ -z "$1" ]; then
  echo "usage: anonTimeForPreparedResults.sh <iso-date>"
  echo "  iso-date in format like '2020-01-01' or '2020-01-01T00:00'"
  echo ""
  echo "anonymizes all date/timestamps in all '${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/up_outbox/' files"
  echo "call after prepareScanResultsForUpload.sh - before uploadScanResults.sh"
  exit 0
else
  ND="$1"
fi

cd "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/up_outbox"

UT="$(date -d "${ND}" -u +%s)"
DTF="$(date -d "@${UT}" -u "+%Y-%m-%dT%T")"
DTU="$(date -d "@${UT}" -u "+%Y-%m-%d_%Hh%Mm%SZ")"
echo "UT:  '${UT}'"
echo "DTF: '${DTF}'"
echo "DTU: '${DTU}'"

INP="/dev/shm/${DTU}_upload_temp.csv"
TMP="/dev/shm/${DTU}_upload.csv"
OUT="${DTU}_upload.csv"

echo "INP: ${INP}"
echo "TMP: ${TMP}"
echo "OUT: ${OUT}"

echo -n "" >"${INP}"

ls -1 |egrep "^.*_upload\.csv\.gz\$" |while read f ; do

  echo "unpack $f .."
  gunzip -c "$f" >>"${INP}"
  mv "$f" "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/up_anon/"

done


for LID in $( awk -F "," '{ print $1; }' "${INP}" |sort |uniq ) ; do  echo "found line ID ${LID}" ; done

echo -e "\nreorder all lineIDs"
echo -n "" >"${TMP}"
for LID in $( awk -F "," '{ print $1; }' "${INP}" |sort -n |uniq ) ; do
  case "${LID}" in
    1?)
      echo "processing line id ${LID}"
      grep "^${LID}," "${INP}" >>"${TMP}"
      ;;
    *)
      echo "processing line id ${LID}"
      grep "^${LID}," "${INP}" >>"${TMP}"
      ;;
  esac
done
# replace input with temp
rm "${INP}"
mv "${TMP}" "${INP}"
# cp "${INP}" "${INP}_"

echo -e "\nreplace all unix timestamps"
awk -F "," "BEGIN { CTR=${UT}; OFS=\",\"; } /.*/ { if (\$1 >= 20) { \$2=CTR; ++CTR; }; print }" "${INP}" >"${TMP}"
# replace input with temp
rm "${INP}"
mv "${TMP}" "${INP}"
# cp "${INP}" "${INP}__"


echo -e "\nreplace 'readable' timestamps"
echo -n "" >"${TMP}"
for LID in $( awk -F "," '{ print $1; }' "${INP}" |sort -n |uniq ) ; do
  case "${LID}" in
    1?)
      echo "processing line id ${LID}"
      grep "^${LID}," "${INP}" |head -n 1 >>"${TMP}"
      ;;
    2?)
      echo "processing line id ${LID}"
      grep "^${LID}," "${INP}" \
        | awk -F "," "{OFS=\",\"; \$7=\"${DTF}.000Z\"; print }" \
        >>"${TMP}"
      ;;
    3?)
      echo "processing line id ${LID}"
      grep "^${LID}," "${INP}" \
        | awk -F "," "{OFS=\",\"; \$8=\"${DTF}.000 Z\"; print }" \
        | awk -F "," "{OFS=\",\"; \$13=\"${DTF}.000Z\"; print }" \
        >>"${TMP}"
      ;;
    *)
      echo "warning: ignoring line id ${LID}"
      ;;
  esac

done

gzip "${TMP}"
cp "${TMP}.gz" "${OUT}.gz"
rm "${INP}"
rm "${TMP}.gz"

