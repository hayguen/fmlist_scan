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

if [ ! -d "up_outbox" ]; then
  mkdir "up_outbox"
fi

if [ ! -d "up_sent" ]; then
  mkdir "up_sent"
fi

cd "${FMLIST_SCAN_RESULT_DIR}/up_outbox"

ls -1 |egrep "^.*\.gz\$" |while read f ; do
  echo "trying to upload $f .."
  response="$( curl -F "mfile=@${f}" https://www.fmlist.org/urds/csvup.php )"
  #echo "output of curl is '${response}'"
  if [ "${response}" = "Thank you!" ]; then
    echo " => success. moving to ${FMLIST_SCAN_RESULT_DIR}/up_sent/".
    mv "${f}" "${FMLIST_SCAN_RESULT_DIR}/up_sent/"
  else
    echo " => fail! keeping file for later upload."
  fi
  echo ""

done

