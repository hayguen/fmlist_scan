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

if [ ! -d "up_sent" ]; then
  mkdir "up_sent"
fi


if [ "$1" = "random" ]; then
  MAX_MINUTES="$2"
  if [ -z "$MAX_MINUTES" ]; then
    MAX_MINUTES="30"
  fi
  WAITSEC=$[ $RANDOM % ( 60 * ${MAX_MINUTES} ) ]
  echo "detected option 'random': waiting up to ${MAX_MINUTES} minutes: $[ ${WAITSEC} / 60 ] min $[ ${WAITSEC} % 60 ] sec"
  sleep ${WAITSEC}
fi


cd "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/up_outbox"

NUP=$( ls -1 |egrep "^.*\.gz\$" |wc -l )
echo "found ${NUP} files to upload."

ls -1 |egrep "^.*\.gz\$" |while read f ; do
  echo "trying to upload $f .."
  response="$( curl -F "mfile=@${f}" https://www.fmlist.org/urds/csvup.php )"
  #echo "output of curl is '${response}'"
  if [ "${response}" = "Thank you!" ]; then
    echo " => success. moving to ${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/up_sent/".
    mv "${f}" "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/up_sent/"
    pushd "${FMLIST_SCAN_RESULT_DIR}/fmlist_scanner/up_sent/" &>/dev/null
    createFMoverview.py "${f}"
    popd &>/dev/null
  else
    echo " => fail! keeping file for later upload."
  fi
  echo ""

done

