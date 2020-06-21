#!/bin/bash

source $HOME/.config/fmlist_scan/config

if [ ${FMLIST_SCAN_MOUNT} -eq 0 ]; then
  echo "Error: FMLIST_SCAN_MOUNT is '${FMLIST_SCAN_MOUNT} ', thus deactivated"
  exit 1
fi

if [ -z "${FMLIST_SCAN_RESULT_DSK}" ]; then
  echo "Error: FMLIST_SCAN_RESULT_DSK is not set in scanner config file"
  exit 1
fi

echo "stopping scanner .."
stopBgScanLoop.sh wait

BOOTUUID=$(sudo fdisk -l /dev/mmcblk0              |grep "^Disk identifier" |cut -d ' ' -f 3 |grep "^0x" |sed 's/0x//g')
DATAUUID=$(sudo fdisk -l ${FMLIST_SCAN_RESULT_DSK} |grep "^Disk identifier" |cut -d ' ' -f 3 |grep "^0x" |sed 's/0x//g')

if [ -z "${BOOTUUID}" ]; then
  echo "warning: could not determine UUID of internal boot SDcard /dev/mmcblk0"
fi

if [ -z "${DATAUUID}" ]; then
  echo "warning: could not determine UUID of data device ${FMLIST_SCAN_RESULT_DSK}"
fi

if [ "${BOOTUUID}" = "${DATAUUID}" ]; then
  echo "warning: UUID of internal boot SDcard /dev/mmcblk0 and ${FMLIST_SCAN_RESULT_DSK} do match."
  if [ "$1" = "check" ]; then
    echo "you should change UUID of ${FMLIST_SCAN_RESULT_DSK} with command 'scanner_fix-uuid.sh'"
    exit 2
  else
    echo "going to change UUID of ${FMLIST_SCAN_RESULT_DSK} .."
  fi
else
  echo "UUID of internal boot SDcard /dev/mmcblk0 and ${FMLIST_SCAN_RESULT_DSK} are different."
  echo "everything is fine. no need to change disk identifier."
  exit 0
fi

if [ "$1" = "check" ]; then
  exit 0
fi

while /bin/true; do
  PTUUID=$(uuidcdef -tu |cut -c-8)
  PTUUID="$(tr [A-Z] [a-z] <<< "${PTUUID}")"
  if [[ ! "${PTUUID}" =~ ^[[:xdigit:]]{8}$ ]]; then
    echo "created invalid UUID ${PTUUID}. trying again .."
    sleep 1
    continue
  fi
  if [ "${BOOTUUID}" = "${PTUUID}" ]; then
    echo "created UUID is identical to BOOTUUID of /dev/mmcblk0. trying again .."
    sleep 1
    continue
  fi
  #PTUUID="${BOOTUUID}"  # test code
  break
done

echo "setting DiskID to ${PTUUID} on ${FMLIST_SCAN_RESULT_DSK} .. "
sleep 5

sudo -E fdisk ${FMLIST_SCAN_RESULT_DSK} <<EOF > /dev/null
p
x
i
0x${PTUUID}
r
p
w
EOF
sync

exit 0
