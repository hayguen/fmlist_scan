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

if [ ! -d "up_sent" ]; then
  mkdir "up_sent"
fi

cd "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/up_outbox"

ls -1 |egrep "^.*\.gz\$" |while read f ; do
  echo "trying to upload $f .."
  response="$( curl -F "mfile=@${f}" https://www.fmlist.org/urds/csvup.php )"
  #echo "output of curl is '${response}'"
  if [ "${response}" = "Thank you!" ]; then
    echo " => success. moving to ${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/up_sent/".
    mv "${f}" "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/up_sent/"
  else
    echo " => fail! keeping file for later upload."
  fi
  echo ""

done

